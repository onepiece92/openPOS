import 'package:flutter/material.dart';

/// A simple detail screen that renders a learn article with structured steps.
class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({
    super.key,
    required this.category,
    required this.title,
    required this.icon,
    required this.readTime,
    required this.sections,
  });

  final String category;
  final String title;
  final IconData icon;
  final String readTime;

  /// Each section is a map with `heading` (String) and `steps` (List<String>).
  final List<ArticleSection> sections;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Hero header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.5),
                  cs.primaryContainer.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: cs.onPrimary, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '$readTime read',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Article sections ─────────────────────────────────────────
          for (int i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 20),
            Text(
              sections[i].heading,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            for (int j = 0; j < sections[i].steps.length; j++)
              _StepTile(
                stepNumber: j + 1,
                text: sections[i].steps[j],
                cs: cs,
                tt: tt,
              ),
            if (sections[i].tip != null) ...[
              const SizedBox(height: 8),
              _TipBox(tip: sections[i].tip!, cs: cs, tt: tt),
            ],
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class ArticleSection {
  const ArticleSection({
    required this.heading,
    required this.steps,
    this.tip,
  });
  final String heading;
  final List<String> steps;
  final String? tip;
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.stepNumber,
    required this.text,
    required this.cs,
    required this.tt,
  });
  final int stepNumber;
  final String text;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$stepNumber',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  const _TipBox({
    required this.tip,
    required this.cs,
    required this.tt,
  });
  final String tip;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final dark = cs.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: dark
            ? cs.secondary.withValues(alpha: 0.10)
            : cs.secondary.withValues(alpha: 0.08),
        border: Border.all(
          color: cs.secondary.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, size: 18, color: cs.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
