import 'package:flutter/material.dart';

class OnboardingNavBar extends StatelessWidget {
  const OnboardingNavBar({
    super.key,
    required this.step,
    required this.saving,
    required this.canNext,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool saving;
  final bool canNext;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Row(
        children: [
          if (step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: canNext && !saving ? onNext : null,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(step < 3 ? 'Continue' : 'Finish Setup'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 0: Business Name ────────────────────────────────────────────────────
