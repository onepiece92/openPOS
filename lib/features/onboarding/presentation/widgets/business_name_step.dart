import 'package:flutter/material.dart';

class BusinessNameStep extends StatelessWidget {
  const BusinessNameStep({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.storefront_rounded,
                size: 44,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'What\'s your business called?',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This will appear on receipts and reports.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Business name',
              hintText: 'e.g. Rebuzz Store',
              prefixIcon: Icon(Icons.business_rounded),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Country ──────────────────────────────────────────────────────────
