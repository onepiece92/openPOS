import 'package:flutter/material.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Contact', tt, cs),
          _SupportTile(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@rebuzzpos.com',
            cs: cs,
            tt: tt,
            onTap: () {},
          ),
          _SupportTile(
            icon: Icons.chat_rounded,
            title: 'WhatsApp Chat',
            subtitle: '+977 982-6189697',
            cs: cs,
            tt: tt,
            onTap: () async {
              final native = Uri.parse('whatsapp://send?phone=9779826189697');
              final web = Uri.parse('https://wa.me/9779826189697');
              if (await canLaunchUrl(native)) {
                await launchUrl(native, mode: LaunchMode.externalApplication);
              } else {
                await launchUrl(web, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 20),
          _SectionHeader('Resources', tt, cs),
          _SupportTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Let us know what went wrong',
            cs: cs,
            tt: tt,
            onTap: () {},
          ),
          _SupportTile(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Request a Feature',
            subtitle: 'Suggest improvements',
            cs: cs,
            tt: tt,
            onTap: () {},
          ),
          _SupportTile(
            icon: Icons.article_outlined,
            title: 'Documentation',
            subtitle: 'Full product docs & guides',
            cs: cs,
            tt: tt,
            onTap: () {},
          ),
          const SizedBox(height: 20),
          _SectionHeader('App Info', tt, cs),
          _InfoRow(label: 'Version', value: '1.0.0', cs: cs, tt: tt),
          _InfoRow(label: 'Build', value: '2026.03', cs: cs, tt: tt),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, this.tt, this.cs);
  final String text;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text.toUpperCase(),
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      );
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
    required this.tt,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, color: cs.primary),
          title: Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          onTap: onTap,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const Spacer(),
            Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
