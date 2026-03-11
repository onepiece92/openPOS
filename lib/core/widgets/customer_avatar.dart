import 'package:flutter/material.dart';

import 'package:pos_app/core/utils/string_utils.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({
    super.key,
    this.name,
    this.fallbackIcon = Icons.person_rounded,
    this.radius,
  });

  final String? name;
  final IconData fallbackIcon;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letters = initials(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          letters != null ? cs.primaryContainer : cs.secondaryContainer,
      child: letters != null
          ? Text(letters,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ))
          : Icon(fallbackIcon,
              size: 18, color: cs.onSecondaryContainer),
    );
  }
}
