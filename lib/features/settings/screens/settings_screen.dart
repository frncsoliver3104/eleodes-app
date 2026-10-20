import 'package:flutter/material.dart';
import 'about_screen.dart';
import 'package:ELEODES/core/settings/app_settings.dart';
import 'package:ELEODES/features/settings/widgets/settings_card.dart';
import 'package:ELEODES/features/settings/widgets/settings_tile.dart';
import 'package:ELEODES/features/guide/screens/beginner_guide_screen.dart';
import 'package:ELEODES/shared/widgets/tab_header.dart';
import 'package:ELEODES/features/legal/screens/privacy_policy_screen.dart';
import 'package:ELEODES/features/legal/screens/terms_of_use_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _settings = AppSettings.instance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _settings.initialize();
  }

  Future<void> _save(String key, bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _settings.setValue(key, value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the setting. Please retry.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _switch(String title, String key) => SettingsTile(
    title: title,
    value: _settings.value(key),
    onChanged: (value) => _save(key, value),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TabTitle('Settings'),
              const SizedBox(height: 19),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AbsorbPointer(
                        absorbing: _saving,
                        child: SettingsCard(
                          children: [
                            _switch('Notification', 'notification'),
                            _switch('Sound', 'sound'),
                            _switch('Vibration', 'vibration'),
                            _switch('Dark mode', 'darkMode'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        child: Text(
                          'Turn on Notification to receive alerts and pop-up notifications.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SettingsCard(
                        children: [
                          SettingsTile(
                            title: 'Guide',
                            showArrow: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BeginnerGuideScreen(),
                                ),
                              );
                            },
                          ),
                          SettingsTile(
                            title: 'About',
                            showArrow: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AboutScreen(),
                                ),
                              );
                            },
                          ),
                          SettingsTile(
                            title: 'Privacy Policy',
                            showArrow: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                          SettingsTile(
                            title: 'Terms of Use',
                            showArrow: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsOfUseScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
