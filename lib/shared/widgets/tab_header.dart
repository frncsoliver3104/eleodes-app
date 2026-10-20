import 'package:flutter/material.dart';

/// Shared title position for the three main tabs.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: SizedBox(
        height: 48,
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }
}

class TabTitle extends StatelessWidget {
  const TabTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return TabHeader(
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 30,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
