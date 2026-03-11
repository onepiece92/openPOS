import 'package:flutter/material.dart';
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
          _ArticleCard(
            category: 'Getting Started',
            title: 'Setting up your store',
            description: 'Configure your store name, currency, and basic settings.',
            readTime: '2 min',
            icon: Icons.store_outlined,
            cs: cs,
            tt: tt,
          ),
          _ArticleCard(
            category: 'Getting Started',
            title: 'Adding your first product',
            description: 'Learn how to create products with variants, bundles, and tax rates.',
            readTime: '3 min',
            icon: Icons.inventory_2_outlined,
            cs: cs,
            tt: tt,
          ),
          _ArticleCard(
            category: 'Sales',
            title: 'Making a sale',
            description: 'Walk through a complete sale: add to cart, apply discounts, collect payment.',
            readTime: '4 min',
            icon: Icons.point_of_sale_outlined,
            cs: cs,
            tt: tt,
          ),
          _ArticleCard(
            category: 'Sales',
            title: 'Held tickets',
            description: 'Park a sale and come back to it later without losing items.',
            readTime: '2 min',
            icon: Icons.bookmark_border_rounded,
            cs: cs,
            tt: tt,
          ),
          _ArticleCard(
            category: 'Inventory',
            title: 'Stock tracking',
            description: 'Set stock levels, get low-stock alerts, and audit stock adjustments.',
            readTime: '3 min',
            icon: Icons.warehouse_outlined,
            cs: cs,
            tt: tt,
          ),
          _ArticleCard(
            category: 'Inventory',
            title: 'Composite / bundle products',
            description: 'Build product bundles that deduct stock from multiple components.',
            readTime: '3 min',
            icon: Icons.workspaces_outlined,
            cs: cs,
            tt: tt,
          ),
          _ArticleCard(
            category: 'Reports',
            title: 'Understanding your reports',
            description: 'Revenue, expenses, and top-selling products at a glance.',
            readTime: '2 min',
            icon: Icons.bar_chart_rounded,
            cs: cs,
            tt: tt,
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.category,
    required this.title,
    required this.description,
    required this.readTime,
    required this.icon,
    required this.cs,
    required this.tt,
  });
  final String category;
  final String title;
  final String description;
  final String readTime;
  final IconData icon;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
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
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '$readTime read',
                            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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
