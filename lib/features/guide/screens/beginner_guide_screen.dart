import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ELEODES/app/main_screen.dart';
import 'package:ELEODES/core/theme/app_theme.dart';

class BeginnerGuideScreen extends StatefulWidget {
  const BeginnerGuideScreen({super.key, this.firstLaunch = false});

  final bool firstLaunch;

  @override
  State<BeginnerGuideScreen> createState() => _BeginnerGuideScreenState();
}

class _BeginnerGuideScreenState extends State<BeginnerGuideScreen> {
  static const _pages = <_GuidePage>[
    _GuidePage(
      title: 'Welcome to ELEODES',
      description:
          'This short guide shows you how to monitor and control your atmospheric water generator. Swipe through or use Next and Back.',
      illustration: _GuideIllustration.welcome,
      tips: ['You can reopen this guide anytime from Settings.'],
    ),
    _GuidePage(
      title: 'Your Dashboard',
      description:
          'The Dashboard is the main screen. It shows live information when your AWG is connected to the internet.',
      illustration: _GuideIllustration.dashboard,
      tips: [
        'Check device status and uptime.',
        'Review temperature, humidity, water level, pH, water production, and harvesting status.',
      ],
    ),
    _GuidePage(
      title: 'pH Level Guide',
      description:
          'The Dashboard pH reading uses a scale from 0 to 14 to describe how acidic or alkaline the water reading is.',
      illustration: _GuideIllustration.phScale,
      tips: [
        'Below 7 is acidic, 7 is neutral, and above 7 is alkaline.',
        'ELEODES uses 6.5–8.5 as its suggested pH reference range. Readings below 6.5 or above 8.5 are outside that range.',
        'Find the current pH reading in the pH Level card on the Dashboard.',
      ],
    ),
    _GuidePage(
      title: 'Readings and system control',
      description:
          'Use the Dashboard to monitor the AWG and operate its system control.',
      illustration: _GuideIllustration.controls,
      tips: [
        'Turn the system ON to start it, then check the harvesting status.',
        'Turn the system OFF when you want to stop it.',
        'HARVESTING means water is being generated. NOT HARVESTING means it is not.',
        'ONLINE means the device is sending data. OFFLINE means the app is not receiving updates.',
      ],
    ),
    _GuidePage(
      title: 'Daily & Weekly Production',
      description:
          'Scroll down the Dashboard to review recorded water production. The history shows each day’s water yield and weather information.',
      illustration: _GuideIllustration.production,
      tips: [
        'Last 7 days summarizes recorded production for the current rolling seven-day period.',
        'Previous 7 days shows the period before that. When both periods have complete records, the app also shows the production difference.',
        'The table lists each date, day and weather, water yield, and weather status. A dash means there is no production record for that day.',
        'Set AWG location saves your phone’s location as the AWG site. Use it only while near the device. Refresh weather manually to get Open-Meteo data for that saved site; the app will not update it automatically when you move.',
      ],
    ),
    _GuidePage(
      title: 'Water Usage',
      description:
          'The Water Usage card on the Dashboard helps you track recorded water consumption separately from water production.',
      illustration: _GuideIllustration.usage,
      tips: [
        'Today shows the water usage recorded for today.',
        'This week totals recorded usage from Monday through today.',
        'A dash means there is no recorded usage value for that period. The current week can be partial.',
      ],
    ),
    _GuidePage(
      title: 'Devices',
      description:
          'Open Devices from the bottom navigation to view your connected AWG device.',
      illustration: _GuideIllustration.devices,
      tips: [
        'Check the device name and connection status.',
        'If no device appears, tap Add Device and follow the setup instructions.',
      ],
    ),
    _GuidePage(
      title: 'Notifications',
      description:
          'Notifications contain recent messages and alerts from your AWG system.',
      illustration: _GuideIllustration.notifications,
      tips: [
        'Check notifications regularly for important device information.',
        'Use the Filter menu to view all alerts or filter by Critical, Warnings, or Info.',
      ],
    ),
    _GuidePage(
      title: 'Settings and quick guide',
      description:
          'Open Settings from the bottom navigation to change app preferences or return to this guide.',
      illustration: _GuideIllustration.settings,
      tips: [
        'Quick guide: Open ELEODES → Check device status → Turn the system on → Monitor readings → Review notifications → Turn the system off when finished.',
      ],
    ),
  ];

  PageController? _pageController;
  PageController get _controller => _pageController ??= PageController();
  int _pageIndex = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _finishGuide() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('beginnerGuideCompleted', true);
    } catch (_) {
      // Let the user continue even if preferences are temporarily unavailable.
    }
    if (!mounted) return;
    if (widget.firstLaunch) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = _pageIndex == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background(context, const Color(0xFFD4FFED)),
      appBar: AppBar(
        title: Semantics(
          label: 'ELEODES Guide',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ELE'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
              const Text('DES Guide'),
            ],
          ),
        ),
        automaticallyImplyLeading: !widget.firstLaunch,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_pageIndex + 1) / _pages.length,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_pageIndex + 1} of ${_pages.length}'),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_pageIndex > 0)
                    OutlinedButton.icon(
                      onPressed: () => _goToPage(_pageIndex - 1),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 88),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _finishing
                        ? null
                        : lastPage
                        ? _finishGuide
                        : () => _goToPage(_pageIndex + 1),
                    icon: Icon(
                      lastPage ? Icons.check : Icons.arrow_forward,
                    ),
                    label: Text(
                      lastPage
                          ? (widget.firstLaunch ? 'Get started' : 'Done')
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_GuidePage page) {
    final textColor = AppTheme.text(context, Colors.black87);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.description,
            style: TextStyle(color: textColor, height: 1.45),
          ),
          const SizedBox(height: 18),
          _AppScreenPreview(type: page.illustration),
          const SizedBox(height: 16),
          for (final tip in page.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(color: textColor, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GuidePage {
  const _GuidePage({
    required this.title,
    required this.description,
    required this.illustration,
    required this.tips,
  });

  final String title;
  final String description;
  final _GuideIllustration illustration;
  final List<String> tips;
}

enum _GuideIllustration {
  welcome,
  dashboard,
  phScale,
  controls,
  production,
  usage,
  devices,
  notifications,
  settings,
}

class _AppScreenPreview extends StatelessWidget {
  const _AppScreenPreview({required this.type});

  final _GuideIllustration type;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppTheme.surface(context, Colors.white);
    final textColor = AppTheme.text(context, Colors.black87);
    final label = switch (type) {
      _GuideIllustration.welcome => 'ELEODES',
      _GuideIllustration.dashboard => 'Dashboard preview',
      _GuideIllustration.phScale => 'pH level guide',
      _GuideIllustration.controls => 'System controls preview',
      _GuideIllustration.production => 'Daily & Weekly Production preview',
      _GuideIllustration.usage => 'Water Usage preview',
      _GuideIllustration.devices => 'Devices preview',
      _GuideIllustration.notifications => 'Notifications preview',
      _GuideIllustration.settings => 'Settings preview',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.12 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.wifi, color: Colors.green, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          _previewContent(context, textColor),
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewContent(BuildContext context, Color textColor) {
    switch (type) {
      case _GuideIllustration.welcome:
        return Center(
          child: Column(
            children: [
              Icon(
                Icons.water_drop,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text('Every drop matters', style: TextStyle(color: textColor)),
            ],
          ),
        );
      case _GuideIllustration.dashboard:
        return Column(
          children: [
            Row(
              children: [
                _metric(context, 'Temperature', '29°C'),
                const SizedBox(width: 8),
                _metric(context, 'Humidity', '62%'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metric(context, 'Water level', '76%'),
                const SizedBox(width: 8),
                _metric(context, 'pH level', '7.2'),
              ],
            ),
          ],
        );
      case _GuideIllustration.phScale:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD32F2F),
                    Color(0xFFFF9800),
                    Color(0xFFFDD835),
                    Color(0xFF43A047),
                    Color(0xFF26C6DA),
                    Color(0xFF3949AB),
                    Color(0xFF8E24AA),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var level = 0; level <= 14; level++)
                  Expanded(
                    child: Text(
                      '$level',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Acidic       Neutral       Alkaline',
              textAlign: TextAlign.center,
            ),
          ],
        );
      case _GuideIllustration.controls:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewRow(context, Icons.power_settings_new, 'AWG system', 'ON'),
            _previewRow(context, Icons.water, 'Harvesting status', 'HARVESTING'),
            _previewRow(context, Icons.timer_outlined, 'Device uptime', '02:18:40'),
          ],
        );
      case _GuideIllustration.production:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewRow(context, Icons.water_drop_outlined, 'Last 7 days', '18.4 L'),
            _previewRow(context, Icons.history, 'Previous 7 days', '16.2 L'),
            const Divider(height: 12),
            _previewRow(context, Icons.calendar_today_outlined, 'Date · Weather · Yield', 'Today  3.2 L'),
            _previewRow(context, Icons.cloud_outlined, 'Daily records', 'View below'),
          ],
        );
      case _GuideIllustration.usage:
        return Row(
          children: [
            _usagePreviewTile(context, 'Today', '2.4 L', Icons.today),
            const SizedBox(width: 10),
            _usagePreviewTile(context, 'This week', '11.8 L', Icons.date_range),
          ],
        );
      case _GuideIllustration.devices:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewRow(context, Icons.memory, 'AWG Device', 'ONLINE'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.add),
              label: const Text('Add Device'),
            ),
          ],
        );
      case _GuideIllustration.notifications:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewRow(context, Icons.filter_list, 'Filter', 'ALL'),
            _previewRow(context, Icons.warning_amber, 'Water Tank Nearly Full', 'Warning'),
            _previewRow(context, Icons.info_outline, 'Water Tank Full', 'Info'),
          ],
        );
      case _GuideIllustration.settings:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewRow(context, Icons.notifications_outlined, 'Notification', 'ON'),
            _previewRow(context, Icons.volume_up_outlined, 'Sound', 'ON'),
            _previewRow(context, Icons.menu_book_outlined, 'Guide', 'OPEN'),
          ],
        );
    }
  }

  Widget _metric(BuildContext context, String name, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _usagePreviewTile(
    BuildContext context,
    String label,
    String amount,
    IconData icon,
  ) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _previewRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
