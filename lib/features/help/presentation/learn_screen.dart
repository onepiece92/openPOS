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
  const _Article(
    category: 'Getting Started',
    title: 'Setting up your store',
    description:
        'Set your store name, currency, and tax.',
    readTime: '2 min',
    icon: Icons.store_outlined,
    sections: [
      ArticleSection(
        heading: 'Open Store Settings',
        steps: [
          'Tap the ☰ menu in the top-left corner to open the sidebar.',
          'Select "Settings" from the navigation drawer.',
          'Tap the "Store Profile" card to open your store details.',
        ],
      ),
      ArticleSection(
        heading: 'Configure Your Store',
        steps: [
          'Enter your business name — this appears on receipts.',
          'Optionally add a tagline, tax registration number, phone and address, then tap "Save Profile".',
          'Back in Settings, tap "Currency" in the Currency section and pick your currency. All prices and totals show in your currency.',
        ],
        tip:
            'You can change these details any time from Settings.',
      ),
      ArticleSection(
        heading: 'Set Your Tax Rates',
        steps: [
          'Taxes must be on (turn on Taxes in Features).',
          'The country you chose during setup gives you a starting tax name and rate. Change it to match your local tax.',
          'Open "Tax" from the sidebar to see your tax rates. Tap "+" to add one, or a rate\'s ⋮ menu to edit it or set it as the default.',
          'Choose the "Inclusion type" from the dropdown: Exclusive (added on top) or Inclusive (embedded in price).',
          'You can keep several rates, but a sale uses one rate for the whole cart. Pick it on the Cart screen with "+ Add Tax" or "Change Tax".',
          'You can also choose the default rate in Settings → Tax → "Default Tax Rate".',
        ],
        tip:
            'Only products with "Apply tax" switched on are taxed at checkout.',
      ),
    ],
  ),
  const _Article(
    category: 'Getting Started',
    title: 'Turning features on or off',
    description:
        'Switch off the parts of the app your shop doesn\'t use.',
    readTime: '1 min',
    icon: Icons.toggle_on_outlined,
    sections: [
      ArticleSection(
        heading: 'The Features Screen',
        steps: [
          'Open the sidebar and tap "Features" (under System).',
          'Each feature has its own switch. A switched-off feature hides its buttons, fields and sidebar items.',
          'Switching a feature off never deletes data. Switch it back on and your data is still there.',
          'Some features need another one. While the parent is off, the feature shows "Needs <parent>" (for example, Tables needs Held tickets).',
          'Turning Taxes off asks you to confirm first.',
        ],
      ),
    ],
  ),
  const _Article(
    category: 'Getting Started',
    title: 'Adding your first product',
    description:
        'Create products with a price, category, tax, stock and units.',
    readTime: '3 min',
    icon: Icons.inventory_2_outlined,
    sections: [
      ArticleSection(
        heading: 'Create a Product',
        steps: [
          'Go to Products from the sidebar menu.',
          'Tap the "Add Product" button.',
          'Enter the product name and selling price.',
          'Optionally add a SKU / Barcode. One is generated for you if you leave it blank.',
          'Choose a category to organise your catalog (e.g. Beverages, Food, Retail). Create categories from Categories in the sidebar.',
          'Tap "Add Product" at the bottom to save.',
        ],
      ),
      ArticleSection(
        heading: 'Tax, Cost & Stock',
        steps: [
          'Switch on "Apply tax" to include the product in tax calculations (turn on Taxes in Features).',
          'Enter a "Purchase price" to see cost of goods and profit in Reports (turn on Cost and profit in Features).',
          'In the "Inventory" section, switch on "Track stock" and enter the stock quantity (turn on Stock tracking in Features).',
          'The stock count automatically decreases with each sale.',
        ],
      ),
      ArticleSection(
        heading: 'Units',
        steps: [
          'Every product has a main unit (e.g. pcs). Stock and price are per main unit.',
          'To also sell in bulk, add a secondary unit (e.g. box, dozen) and its conversion (turn on Units in Features).',
        ],
        tip:
            'Switch on "Hide in POS" to keep a product off the POS screen while still using it as a bundle component.',
      ),
    ],
  ),
  const _Article(
    category: 'Sales',
    title: 'Making a sale',
    description:
        'Walk through a complete sale: add to cart, apply a discount, collect payment.',
    readTime: '3 min',
    icon: Icons.point_of_sale_outlined,
    sections: [
      ArticleSection(
        heading: 'Add Items to Cart',
        steps: [
          'From the POS screen, browse the product catalog or use the search bar.',
          'Tap a product to add it to the cart. Tap again to increase quantity.',
          'For a product with a second unit, long-press it and pick the unit (turn on Units in Features).',
        ],
      ),
      ArticleSection(
        heading: 'Apply a Discount',
        steps: [
          'Open the Cart screen and tap "+ Add Discount" (turn on Discounts in Features).',
          'Choose "Flat amount" or "Percentage (%)", enter the value, and tap "Apply".',
          'The discount applies to the whole order.',
        ],
      ),
      ArticleSection(
        heading: 'Checkout & Payment',
        steps: [
          'Tap the cart button (cart icon and item count) in the bottom bar to open the Cart screen.',
          'Review the order summary: items, subtotal, discount, tax, and total.',
          'Tap "Checkout • <total>" at the bottom.',
          'Select a payment method: Cash or Card.',
          'For cash payments, enter the amount received — the change is calculated automatically.',
          'To add a tip, pick a percentage or enter an amount; it is kept apart from the sale in reports (turn on Tips in Features).',
          'Tap "Confirm & Charge <total>" to complete the sale.',
        ],
      ),
      ArticleSection(
        heading: 'After the Sale',
        steps: [
          'A digital receipt is shown on screen after each sale.',
          'If a printer is saved in Settings → Hardware, the receipt prints automatically (turn on Auto-print receipts in Features).',
          'The sale is recorded in your order history and reflected in reports immediately.',
        ],
        tip:
            'All sales are stored locally on your device. No internet connection is needed at any point.',
      ),
    ],
  ),
  const _Article(
    category: 'Sales',
    title: 'Held tickets',
    description:
        'Park a sale and come back to it later without losing items.',
    readTime: '2 min',
    icon: Icons.bookmark_border_rounded,
    sections: [
      ArticleSection(
        heading: 'Save a Ticket',
        steps: [
          'Held tickets must be on (turn on Held tickets in Features).',
          'Add items to the cart as usual.',
          'Tap "Save" (pause icon) in the bottom bar.',
          'The cart is saved as a ticket, named after the customer or "Ticket N", and a fresh, empty cart is ready for the next customer.',
        ],
        tip:
            'You can hold multiple tickets at the same time — useful for restaurants or busy counters.',
      ),
      ArticleSection(
        heading: 'Resume a Ticket',
        steps: [
          'Tap the banner above the bottom bar ("N held tickets — Tap to resume").',
          'A list of active tickets appears with their names, item counts and totals.',
          'Tap a ticket to load it back into the cart. If the cart already has items, you can save them as a ticket first or discard them.',
        ],
      ),
      ArticleSection(
        heading: 'Archive & Delete Tickets',
        steps: [
          'Tap the archive icon on an active ticket, or "Archive all tickets", to move tickets to the Archived tab.',
          'In the Archived tab, restore a ticket, or delete it (or "Delete all archived") after confirming.',
        ],
        tip:
            'Held tickets stay even if you close and reopen the app. They are stored safely on your device.',
      ),
    ],
  ),
  const _Article(
    category: 'Inventory',
    title: 'Stock tracking',
    description:
        'Set stock levels, adjust them, and spot low stock.',
    readTime: '3 min',
    icon: Icons.warehouse_outlined,
    sections: [
      ArticleSection(
        heading: 'Enable Stock Tracking',
        steps: [
          'Stock tracking must be on (turn on Stock tracking in Features).',
          'Open any product and scroll to the "Inventory" section.',
          'Switch on "Track stock" and enter the stock quantity (e.g. 50 units).',
          'Save the product — stock tracking is now active for this item.',
        ],
      ),
      ArticleSection(
        heading: 'How Stock Decreases',
        steps: [
          'Every time this product is sold, the stock count is reduced automatically.',
          'If a sale is voided, or refunded with "Restock items" switched on, the stock it took is added back.',
          'A product with "Track stock" switched off isn\'t restocked by a void or refund; its stock can be corrected in Inventory.',
        ],
      ),
      ArticleSection(
        heading: 'Adjust Stock Manually',
        steps: [
          'Go to Inventory from the sidebar.',
          'Use the − / + buttons on a product card to change its stock by one.',
          'Or tap the quantity, type a new stock quantity, and tap "Set".',
          'The ⋮ menu on a card can mark a product out of stock, back in stock, or stop tracking it.',
        ],
      ),
      ArticleSection(
        heading: 'Low-Stock Alerts',
        steps: [
          'Set one shop-wide "Low Stock Threshold" in Settings → Inventory (e.g. 5 units).',
          'When a product\'s stock is at or below the threshold, a low-stock badge appears on it.',
          'Use the "Low" and "Out" filters on the Inventory screen to see those products.',
        ],
      ),
    ],
  ),
  const _Article(
    category: 'Inventory',
    title: 'Composite / bundle products',
    description:
        'Build product bundles that deduct stock from multiple components.',
    readTime: '2 min',
    icon: Icons.workspaces_outlined,
    sections: [
      ArticleSection(
        heading: 'What Are Bundles?',
        steps: [
          'A bundle is a single product made up of multiple component items (turn on Bundles in Features; it needs Stock tracking).',
          'Example: A "Breakfast Combo" might include 1× Coffee, 1× Sandwich, and 1× Juice.',
          'When the bundle is sold, stock is deducted from each component automatically.',
        ],
      ),
      ArticleSection(
        heading: 'Create a Bundle Product',
        steps: [
          'Go to Products → tap "Add Product".',
          'Switch on "Composite / Bundle".',
          'Tap "Add component", pick a product, and enter its quantity per bundle.',
          'Set the bundle selling price — this can be different from the sum of component prices.',
          'Save the product. It now appears in your catalog like any regular item.',
        ],
        tip:
            'Bundle pricing lets you offer discounts on combos while still tracking each component\'s stock accurately.',
      ),
      ArticleSection(
        heading: 'How Bundle Stock Works',
        steps: [
          'The bundle itself doesn\'t track its own stock.',
          'When the bundle is sold, each component\'s stock is deducted at checkout.',
        ],
      ),
    ],
  ),
  const _Article(
    category: 'Reports',
    title: 'Understanding your reports',
    description:
        'Revenue, tax, profit, and top-selling products at a glance.',
    readTime: '2 min',
    icon: Icons.bar_chart_rounded,
    sections: [
      ArticleSection(
        heading: 'Choose a Period',
        steps: [
          'Open Reports from the sidebar menu.',
          'Choose Today, Week, Month or Year, or tap the calendar icon for a custom date range.',
        ],
      ),
      ArticleSection(
        heading: 'Summary Cards',
        steps: [
          'Revenue, Tax Collected (shown with your shop\'s tax name) and the number of Orders.',
          'Cost of Goods and Net Profit (turn on Cost and profit in Features). Net profit is sales without tax, minus cost of goods and expenses.',
          'Expenses (turn on Expenses in Features). Record expenses on the Expenses screen.',
          'The Summary also shows the average order value.',
        ],
        tip:
            'Set a purchase price on your products so cost of goods and profit stay accurate.',
      ),
      ArticleSection(
        heading: 'Chart, Payment Mix & Top Products',
        steps: [
          'Turn on Dashboard extras in Features to see these.',
          'The sales chart shows sales over the selected period.',
          'The payment mix shows the orders and amount paid by cash and by card.',
          'Top products are ranked by units sold.',
        ],
      ),
      ArticleSection(
        heading: 'Export Your Data',
        steps: [
          'Go to Settings → Backup & Restore.',
          'Export products, customers, expenses or order history as CSV files (turn on CSV import and export in Features).',
          'Or back up everything into one .zip file.',
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
