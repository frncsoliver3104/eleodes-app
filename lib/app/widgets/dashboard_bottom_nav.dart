import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DashboardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Center(
            heightFactor: 1,
            child: FractionallySizedBox(
              widthFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context, const Color(0xFFC4C4C4)),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Row(
                    children: [
                      _navButton(
                        context,
                        0,
                        'assets/images/Water.png',
                        'Dashboard',
                      ),
                      _navButton(
                        context,
                        1,
                        'assets/images/devices.png',
                        'Device list',
                      ),
                      _navButton(
                        context,
                        2,
                        'assets/images/Settings.png',
                        'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(
    BuildContext context,
    int index,
    String asset,
    String label,
  ) {
    final selected = currentIndex == index;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: IconButton(
          tooltip: label,
          onPressed: () => onTap(index),
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 48 : 42,
            height: selected ? 48 : 42,
            padding: EdgeInsets.all(selected ? 12 : 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2ED7A2) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2ED7A2).withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Image.asset(
              asset,
              color: selected
                  ? const Color(0xFF10261C)
                  : AppTheme.muted(context, Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }
}
