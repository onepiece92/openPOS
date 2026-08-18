import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

/// Settings hub. Each section (and the sheet it opens) lives in
/// `widgets/<name>_section.dart`; this file only lays them out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          SettingsSectionHeader('Store Profile'),
          StoreProfileSection(),
          SettingsSectionHeader('Currency'),
          CurrencySection(),
          SettingsSectionHeader('Tax'),
          TaxSection(),
          SettingsSectionHeader('Inventory'),
          InventorySection(),
          SettingsSectionHeader('Loyalty'),
          LoyaltySection(),
          SettingsSectionHeader('Appearance'),
          AppearanceSection(),
          SettingsSectionHeader('Hardware'),
          PrinterSection(),
          SettingsSectionHeader('Data Management'),
          BackupSection(),
          SettingsSectionHeader('Danger Zone'),
          DangerSection(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
