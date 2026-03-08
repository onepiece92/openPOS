import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';

class StoreProfileEditScreen extends ConsumerStatefulWidget {
  const StoreProfileEditScreen({super.key});

  @override
  ConsumerState<StoreProfileEditScreen> createState() =>
      _StoreProfileEditScreenState();
}

class _StoreProfileEditScreenState
    extends ConsumerState<StoreProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  bool _initialised = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _nameCtrl.text = ref.read(businessNameProvider);
      _taglineCtrl.text = ref.read(businessTaglineProvider);
      _phoneCtrl.text = ref.read(businessPhoneProvider);
      _addressCtrl.text = ref.read(businessAddressProvider);
      _panCtrl.text = ref.read(businessPanProvider);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final box = ref.read(settingsBoxProvider);
    await saveBusinessName(box, _nameCtrl.text.trim());
    await saveBusinessTagline(box, _taglineCtrl.text.trim());
    await saveBusinessPhone(box, _phoneCtrl.text.trim());
    await saveBusinessAddress(box, _addressCtrl.text.trim());
    await saveBusinessPan(box, _panCtrl.text.trim());
    ref.invalidate(businessNameProvider);
    ref.invalidate(businessTaglineProvider);
    ref.invalidate(businessPhoneProvider);
    ref.invalidate(businessAddressProvider);
    ref.invalidate(businessPanProvider);
    if (mounted) {
      setState(() => _loading = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Store Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ── Business ──────────────────────────────────────────────────
          _label('Business', tt, cs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      prefixIcon: Icon(Icons.storefront_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _taglineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tagline',
                      hintText: 'e.g. Fresh & Fast',
                      prefixIcon: Icon(Icons.short_text_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _panCtrl,
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PAN / Tax Registration No.',
                      hintText: 'e.g. 123456789',
                      prefixIcon: Icon(Icons.numbers_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Contact ───────────────────────────────────────────────────
          _label('Contact', tt, cs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s\+\-\(\)]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: 'e.g. +977-9800000000',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'e.g. 123 Main St, Kathmandu',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              style: AppTheme.ctaButtonStyle(cs),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Profile'),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _label(String text, TextTheme tt, ColorScheme cs) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
