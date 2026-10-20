import 'package:flutter/material.dart';
import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:ELEODES/features/dashboard/screens/dashboard_screen.dart';
import 'package:ELEODES/features/devices/screens/devices_list_screen.dart';
import 'package:ELEODES/features/devices/screens/device_setup_screen.dart';
import 'package:ELEODES/features/settings/screens/settings_screen.dart';
import 'package:ELEODES/app/widgets/dashboard_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  void _changePage(int index) {
    if (!mounted || index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.background(context, const Color(0xFFD4FFED)),

      body: SafeArea(
        bottom: false,

        child: PageView(
          controller: _pageController,

          // Disable horizontal swiping.
          physics: const NeverScrollableScrollPhysics(),

          onPageChanged: (index) {
            if (!mounted || index == _currentIndex) return;

            setState(() {
              _currentIndex = index;
            });
          },

          children: [
            DashboardScreen(
              onProceedToDevice: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ESP32ConfigurationScreen(),
                  ),
                );
              },
            ),

            const DevicesListScreen(),

            const SettingsScreen(),
          ],
        ),
      ),

      bottomNavigationBar: DashboardBottomNav(
        currentIndex: _currentIndex,
        onTap: _changePage,
      ),
    );
  }
}
