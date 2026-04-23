import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/utils/currency_formatter.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/receipts/domain/receipt_text.dart';
import 'package:pos_app/features/receipts/presentation/receipt_body.dart';

final _receiptProvider =
    FutureProvider.family<ReceiptBodyData, int>((ref, orderId) async {
  final db = ref.read(databaseProvider);
  final box = ref.read(settingsBoxProvider);
  final order = await db.ordersDao.getById(orderId);
  if (order == null) throw Exception('Order #$orderId not found');
  final items = await db.ordersDao.getItems(orderId);
  final taxes = await db.ordersDao.getTaxBreakdown(orderId);
  final businessName =
      box.get('business_name', defaultValue: 'My Store') as String;
  Customer? customer;
  if (order.customerId != null) {
    customer = await db.customersDao.getById(order.customerId!);
  }
  return ReceiptBodyData(
    order: order,
    items: items,
    taxes: taxes,
    businessName: businessName,
    customer: customer,
  );
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(_receiptProvider(orderId));
    final fmt = ref.watch(currencyFormatterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        automaticallyImplyLeading: false,
        actions: [
          receiptAsync.maybeWhen(
            data: (data) => _ShareMenu(data: data, fmt: fmt),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: const _NewSaleBar(),
      body: receiptAsync.when(
        data: (data) => ReceiptBody(data: data, fmt: fmt),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── Share menu ───────────────────────────────────────────────────────────────

enum _ShareAction { sms, email, copy }

class _ShareMenu extends StatelessWidget {
  const _ShareMenu({required this.data, required this.fmt});
  final ReceiptBodyData data;
  final CurrencyFormatter fmt;

  Future<void> _handle(BuildContext context, _ShareAction action) async {
    final text = buildReceiptText(data, fmt);
    switch (action) {
      case _ShareAction.copy:
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt copied')),
          );
        }
      case _ShareAction.sms:
        final phone = await _resolveContact(
          context,
          existing: data.customer?.phone,
          label: 'Phone number',
          hint: '+977…',
          keyboard: TextInputType.phone,
        );
        if (phone == null || !context.mounted) return;
        final uri = Uri(
          scheme: 'sms',
          path: phone,
          queryParameters: {'body': text},
        );
        await _launch(context, uri, fallbackText: text);
      case _ShareAction.email:
        final addr = await _resolveContact(
          context,
          existing: data.customer?.email,
          label: 'Email address',
          hint: 'name@example.com',
          keyboard: TextInputType.emailAddress,
        );
        if (addr == null || !context.mounted) return;
        final uri = Uri(
          scheme: 'mailto',
          path: addr,
          queryParameters: {
            'subject': '${data.businessName} — Receipt #${data.order.id}',
            'body': text,
          },
        );
        await _launch(context, uri, fallbackText: text);
    }
  }

  Future<void> _launch(BuildContext context, Uri uri,
      {required String fallbackText}) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No app found — receipt copied to clipboard'),
        ),
      );
    }
  }

  Future<String?> _resolveContact(
    BuildContext context, {
    required String? existing,
    required String label,
    required String hint,
    required TextInputType keyboard,
  }) async {
    final controller = TextEditingController(text: existing ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send to'),
        content: TextField(
          controller: controller,
          keyboardType: keyboard,
          autofocus: true,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ShareAction>(
      icon: const Icon(Icons.ios_share_rounded),
      tooltip: 'Send receipt',
      onSelected: (a) => _handle(context, a),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ShareAction.sms,
          child: ListTile(
            leading: Icon(Icons.sms_outlined),
            title: Text('Send by SMS'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ShareAction.email,
          child: ListTile(
            leading: Icon(Icons.mail_outline_rounded),
            title: Text('Send by Email'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ShareAction.copy,
          child: ListTile(
            leading: Icon(Icons.copy_rounded),
            title: Text('Copy text'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

// ─── New sale bar ─────────────────────────────────────────────────────────────

class _NewSaleBar extends StatelessWidget {
  const _NewSaleBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Material(
      color: cs.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Sale'),
            onPressed: () => context.go('/pos'),
            style: AppTheme.ctaButtonStyle(cs),
          ),
        ),
      ),
    );
  }
}
