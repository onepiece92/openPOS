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
            onTap: () => launchUrl(
              Uri.parse('mailto:support@rebuzzpos.com'),
            ),
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
            onTap: () => launchUrl(
              Uri.parse(
                'mailto:support@rebuzzpos.com?subject=${Uri.encodeComponent('openPOS Bug')}',
              ),
            ),
          ),
          _SupportTile(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Request a Feature',
            subtitle: 'Suggest improvements',
            cs: cs,
            tt: tt,
            onTap: () => launchUrl(
              Uri.parse(
                'mailto:support@rebuzzpos.com?subject=${Uri.encodeComponent('openPOS Feature Request')}',
              ),
            ),
          ),
          _SupportTile(
            icon: Icons.article_outlined,
            title: 'Documentation',
            subtitle: 'Full product docs & guides',
            cs: cs,
            tt: tt,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Documentation coming soon')),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Upgrade POS', tt, cs),
          _UpgradeCard(
            icon: Icons.rocket_launch_rounded,
            title: 'RebuzzPOS',
            subtitle: 'Online POS with 40+ additional features',
            gradient: const [Color(0xFF6B68FF), Color(0xFF00B8C8)],
            cs: cs,
            tt: tt,
            onTap: () => launchUrl(
              Uri.parse('https://rebuzzpos.com'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 8),
          _UpgradeCard(
            icon: Icons.phone_iphone_rounded,
            title: 'Ordering App',
            subtitle:
                'Get your own online ordering mobile app for your business',
            gradient: const [Color(0xFFE01E6A), Color(0xFFFF8C42)],
            cs: cs,
            tt: tt,
            onTap: () => launchUrl(
              Uri.parse('https://rebuzzpos.com'),
              mode: LaunchMode.externalApplication,
            ),
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

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.cs,
    required this.tt,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = cs.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    gradient[0].withValues(alpha: 0.25),
                    gradient[1].withValues(alpha: 0.12),
                  ]
                : [
                    gradient[0].withValues(alpha: 0.10),
                    gradient[1].withValues(alpha: 0.06),
                  ],
          ),
          border: Border.all(
            color: dark
                ? gradient[0].withValues(alpha: 0.30)
                : gradient[0].withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: gradient[0],
              size: 20,
            ),
          ],
        ),
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
