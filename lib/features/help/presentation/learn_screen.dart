import 'package:flutter/material.dart';
import 'package:pos_app/features/help/presentation/article_detail_screen.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final a in _articles)
            _ArticleCard(
              category: a.category,
              title: a.title,
              description: a.description,
              readTime: a.readTime,
              icon: a.icon,
              cs: cs,
              tt: tt,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(
                    category: a.category,
                    title: a.title,
                    icon: a.icon,
                    readTime: a.readTime,
                    sections: a.sections,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Article data ──────────────────────────────────────────────────────────────

class _Article {
  const _Article({
    required this.category,
    required this.title,
    required this.description,
    required this.readTime,
    required this.icon,
    required this.sections,
  });
  final String category;
  final String title;
  final String description;
  final String readTime;
  final IconData icon;
  final List<ArticleSection> sections;
}

final _articles = <_Article>[
  _Article(
    category: 'Getting Started',
    title: 'Setting up your store',
    description:
        'Configure your store name, currency, and basic settings.',
    readTime: '2 min',
    icon: Icons.store_outlined,
    sections: [
      ArticleSection(
        heading: 'Open Store Settings',
        steps: [
          'Tap the ☰ menu in the top-left corner to open the sidebar.',
          'Select "Settings" from the navigation drawer.',
          'Tap "Store Profile" to open your store details.',
        ],
      ),
      ArticleSection(
        heading: 'Configure Your Store',
        steps: [
          'Enter your business name — this appears on receipts and reports.',
          'Choose your currency (e.g. NPR, USD, INR). All prices and totals will display in this format.',
          'Set your timezone so that sales timestamps and daily reports are accurate.',
          'Add your store address and phone number for receipt printing.',
        ],
        tip:
            'You can update these details anytime from Settings → Store Profile. Changes take effect immediately.',
      ),
      ArticleSection(
        heading: 'Set Your Default Tax Rate',
        steps: [
          'Go to Settings → Tax Rates.',
          'A default tax rate (e.g. 13% VAT) is pre-configured. Edit it to match your local tax.',
          'Toggle between "Inclusive" (tax is part of the price) or "Exclusive" (tax added on top).',
          'You can create multiple tax rates if your products have different tax categories.',
        ],
        tip:
            'Products marked as "Taxable" will automatically use the assigned tax rate at checkout.',
      ),
    ],
  ),
  _Article(
    category: 'Getting Started',
    title: 'Adding your first product',
    description:
        'Learn how to create products with variants, bundles, and tax rates.',
    readTime: '3 min',
    icon: Icons.inventory_2_outlined,
    sections: [
      ArticleSection(
        heading: 'Create a Product',
        steps: [
          'Go to Products from the sidebar menu.',
          'Tap the "+" button in the bottom-right corner.',
          'Enter the product name and selling price.',
          'Optionally add a SKU (barcode number) — you can also scan it using the camera.',
          'Choose a category to organise your catalog (e.g. Beverages, Food, Retail).',
        ],
      ),
      ArticleSection(
        heading: 'Add Variants & Modifiers',
        steps: [
          'Scroll down to the "Variants" section on the product form.',
          'Add variants like Size (Small, Medium, Large) with optional price adjustments.',
          'Add modifiers for optional add-ons (e.g. Extra Cheese +₹20).',
          'Each variant can have its own stock quantity for precise tracking.',
        ],
        tip:
            'Variants are great for the same product in different sizes or flavours. Modifiers work best for optional extras the customer can choose.',
      ),
      ArticleSection(
        heading: 'Set Tax & Stock',
        steps: [
          'Enable the "Taxable" toggle to apply your store\'s default tax rate.',
          'To assign a specific tax rate, tap "Tax Rate" and pick one.',
          'Enter the current stock quantity if you want stock tracking enabled.',
          'The stock count automatically decreases with each sale.',
        ],
      ),
    ],
  ),
  _Article(
    category: 'Sales',
    title: 'Making a sale',
    description:
        'Walk through a complete sale: add to cart, apply discounts, collect payment.',
    readTime: '4 min',
    icon: Icons.point_of_sale_outlined,
    sections: [
      ArticleSection(
        heading: 'Add Items to Cart',
        steps: [
          'From the home screen, browse the product catalog or use the search bar.',
          'Tap a product to add it to the cart. Tap again to increase quantity.',
          'If the product has variants, a selector will appear — pick the right option.',
          'You can also scan a barcode using the scanner icon to quickly add items.',
        ],
      ),
      ArticleSection(
        heading: 'Apply Discounts',
        steps: [
          'Tap an item in the cart to open its line options.',
          'Select "Discount" and enter a percentage or fixed amount.',
          'The discount is applied per line item and reflected in the subtotal.',
        ],
        tip:
            'For a store-wide discount, apply it at checkout before confirming the payment.',
      ),
      ArticleSection(
        heading: 'Checkout & Payment',
        steps: [
          'Tap the "Checkout" button at the bottom of the cart.',
          'Review the order summary: items, subtotal, tax breakdown, and total.',
          'Select a payment method — Cash is the default for offline POS.',
          'For cash payments, enter the tendered amount — change due is calculated automatically.',
          'Tap "Confirm Payment" to complete the sale.',
        ],
      ),
      ArticleSection(
        heading: 'After the Sale',
        steps: [
          'A digital receipt is shown on screen after each sale.',
          'If a thermal printer is connected, the receipt prints automatically.',
          'The sale is recorded in your order history and reflected in reports immediately.',
        ],
        tip:
            'All sales are stored locally on your device. No internet connection is needed at any point.',
      ),
    ],
  ),
  _Article(
    category: 'Sales',
    title: 'Held tickets',
    description:
        'Park a sale and come back to it later without losing items.',
    readTime: '2 min',
    icon: Icons.bookmark_border_rounded,
    sections: [
      ArticleSection(
        heading: 'Hold an Order',
        steps: [
          'Add items to the cart as usual.',
          'Tap the "Hold" button (bookmark icon) in the cart area.',
          'Give the held order a name or note (e.g. "Table 3" or "John\'s order").',
          'The current cart is saved and a fresh, empty cart is ready for the next customer.',
        ],
        tip:
            'You can hold multiple orders at the same time — useful for restaurants or busy retail counters.',
      ),
      ArticleSection(
        heading: 'Resume a Held Order',
        steps: [
          'Tap the held-orders icon in the top bar or home screen.',
          'A list of all parked orders appears with their names and item counts.',
          'Tap on any held order to load it back into the active cart.',
          'Continue editing, add more items, or proceed straight to checkout.',
        ],
      ),
      ArticleSection(
        heading: 'Delete a Held Order',
        steps: [
          'Swipe left on a held order in the list, or tap the delete icon.',
          'Confirm deletion — the items are discarded and the order is removed.',
        ],
        tip:
            'Held orders persist even if you close and reopen the app. They are stored safely on your device.',
      ),
    ],
  ),
  _Article(
    category: 'Inventory',
    title: 'Stock tracking',
    description:
        'Set stock levels, get low-stock alerts, and audit stock adjustments.',
    readTime: '3 min',
    icon: Icons.warehouse_outlined,
    sections: [
      ArticleSection(
        heading: 'Enable Stock Tracking',
        steps: [
          'Open any product and scroll to the "Stock" section.',
          'Enter the current stock quantity (e.g. 50 units).',
          'Save the product — stock tracking is now active for this item.',
        ],
      ),
      ArticleSection(
        heading: 'How Stock Decreases',
        steps: [
          'Every time this product is sold, the stock count is reduced automatically.',
          'If a sale is refunded with the "Restock" option, the quantity is added back.',
          'Stock changes are recorded in the audit log with timestamps.',
        ],
      ),
      ArticleSection(
        heading: 'Adjust Stock Manually',
        steps: [
          'Go to Inventory from the sidebar.',
          'Find the product and tap "Adjust Stock".',
          'Enter the adjustment amount (positive to add, negative to remove).',
          'Select a reason code (e.g. "Received shipment", "Damaged", "Correction").',
          'The adjustment is logged in the audit trail for accountability.',
        ],
        tip:
            'Set a low-stock threshold per product. You\'ll get a notification when stock falls below that level.',
      ),
      ArticleSection(
        heading: 'Low-Stock Alerts',
        steps: [
          'In the product settings, set a "Low Stock Alert" threshold (e.g. 5 units).',
          'When stock reaches the threshold, a warning badge appears on the product.',
          'You can view all low-stock items from the Inventory screen filter.',
        ],
      ),
    ],
  ),
  _Article(
    category: 'Inventory',
    title: 'Composite / bundle products',
    description:
        'Build product bundles that deduct stock from multiple components.',
    readTime: '3 min',
    icon: Icons.workspaces_outlined,
    sections: [
      ArticleSection(
        heading: 'What Are Bundles?',
        steps: [
          'A bundle is a single product made up of multiple component items.',
          'Example: A "Breakfast Combo" might include 1× Coffee, 1× Sandwich, and 1× Juice.',
          'When the bundle is sold, stock is deducted from each component automatically.',
        ],
      ),
      ArticleSection(
        heading: 'Create a Bundle Product',
        steps: [
          'Go to Products → tap "+" to add a new product.',
          'Toggle the "Composite / Bundle" option on.',
          'Search and add component products with their required quantities.',
          'Set the bundle selling price — this can be different from the sum of component prices.',
          'Save the product. It now appears in your catalog like any regular item.',
        ],
        tip:
            'Bundle pricing lets you offer discounts on combos while still tracking each component\'s stock accurately.',
      ),
      ArticleSection(
        heading: 'How Bundle Stock Works',
        steps: [
          'The bundle itself doesn\'t hold stock — its availability depends on its components.',
          'If any component runs out of stock, the bundle becomes unavailable.',
          'Stock deductions happen per-component when the bundle is sold at checkout.',
        ],
      ),
    ],
  ),
  _Article(
    category: 'Reports',
    title: 'Understanding your reports',
    description:
        'Revenue, expenses, and top-selling products at a glance.',
    readTime: '2 min',
    icon: Icons.bar_chart_rounded,
    sections: [
      ArticleSection(
        heading: 'Sales Summary Dashboard',
        steps: [
          'Open Reports from the sidebar menu.',
          'The dashboard shows today\'s total sales, number of transactions, and average order value.',
          'Toggle between Today, This Week, and This Month for different time ranges.',
          'Top-selling products are ranked by units sold or revenue generated.',
        ],
      ),
      ArticleSection(
        heading: 'Expense vs Revenue (P&L)',
        steps: [
          'Scroll to the Profit & Loss section in Reports.',
          'See your total revenue, total expenses, and net profit for the selected period.',
          'Expenses are categorised (Rent, Supplies, Wages, etc.) for easy review.',
        ],
        tip:
            'Add expenses regularly through the Expenses screen so your P&L report stays accurate.',
      ),
      ArticleSection(
        heading: 'Tax Report',
        steps: [
          'The Tax Report shows total tax collected, broken down by each tax rate.',
          'Useful for filing VAT or sales tax returns with your local tax authority.',
          'Export the report as CSV for your accountant or records.',
        ],
      ),
      ArticleSection(
        heading: 'Export Reports',
        steps: [
          'Tap the share/export icon on any report screen.',
          'Choose CSV for spreadsheet-friendly data, or PDF for a formatted summary.',
          'Share the file via email, messaging apps, or save it to your device.',
        ],
        tip:
            'All reports are generated from your local data — no internet required. Data never leaves your device.',
      ),
    ],
  ),
];

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.category,
    required this.title,
    required this.description,
    required this.readTime,
    required this.icon,
    required this.cs,
    required this.tt,
    required this.onTap,
  });
  final String category;
  final String title;
  final String description;
  final String readTime;
  final IconData icon;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '$readTime read',
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
