import 'package:ELEODES/core/theme/app_theme.dart';

import 'package:flutter/material.dart';

class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),

      child: Container(
        width: double.infinity,

        decoration: BoxDecoration(
          color: AppTheme.surface(
            context,
            const Color(0xFFB8B8B8).withValues(alpha: 0.25),
          ),

          borderRadius: BorderRadius.circular(25),
        ),

        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 9),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
