import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

import 'package:pos_app/features/settings/presentation/widgets/appearance_section.dart';
import 'package:pos_app/features/settings/presentation/widgets/backup_section.dart';
import 'package:pos_app/features/settings/presentation/widgets/currency_section.dart';
import 'package:pos_app/features/settings/presentation/widgets/danger_section.dart';
import 'package:pos_app/features/settings/presentation/widgets/inventory_section.dart';
import 'package:pos_app/features/settings/presentation/widgets/loyalty_section.dart';
import 'package:pos_app/features/settings/presentation/widgets/printer_section.dart';
import 'package:pos_app/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:pos_app/features/settings/presentation/widgets/store_profile_section.dart';
import 'package:pos_app/features/settings/presentation/widgets/tax_section.dart';
import 'package:pos_app/features/tips/tips_section.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

/// Settings hub. Each section (and the sheet it opens) lives in
/// `widgets/<name>_section.dart`; this file only lays them out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sections of switched-off features are not built.
    final stock = ref.watch(featureOnProvider(Feature.stockTracking));
    final customers = ref.watch(featureOnProvider(Feature.customers));
    final taxes = ref.watch(featureOnProvider(Feature.taxes));
    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Store Profile'),
          const StoreProfileSection(),
          const SettingsSectionHeader('Currency'),
          const CurrencySection(),
          if (taxes) ...const [
            SettingsSectionHeader('Tax'),
            TaxSection(),
          ],
          const SettingsSectionHeader('Invoices'),
          const InvoiceSection(),
          if (stock) ...const [
            SettingsSectionHeader('Inventory'),
            InventorySection(),
          ],
          // Its switch is the Loyalty points feature, which needs Customers.
          if (customers) ...const [
            SettingsSectionHeader('Loyalty'),
            LoyaltySection(),
          ],
          const SettingsSectionHeader('Tips'),
          const TipsSection(),
          const SettingsSectionHeader('Appearance'),
          const AppearanceSection(),
          const SettingsSectionHeader('Hardware'),
          const PrinterSection(),
          const SettingsSectionHeader('Data Management'),
          const BackupSection(),
          const SettingsSectionHeader('Danger Zone'),
          const DangerSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
