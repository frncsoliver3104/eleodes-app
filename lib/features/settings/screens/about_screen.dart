import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ELEODES/core/theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.accentText(context, const Color(0xFF1B5E20)),
      ),
    ),
  );

  Widget _body(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: AppTheme.text(context, Colors.black87),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background(context, const Color(0xFFC8F7E6)),
    appBar: AppBar(
      backgroundColor: AppTheme.background(context, const Color(0xFFC8F7E6)),
      elevation: 0,
      centerTitle: true,
      title: Text(
        'About ELEODES',
        style: TextStyle(
          color: AppTheme.text(context, Colors.black87),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading('About ELEODES'),
                _body(
                  'ELEODES is a mobile application designed to connect with and monitor the ELEODES IoT Atmospheric Water Generation (AWG) System. It provides real-time information on temperature, humidity, water level, pH level, and system status when the device is connected.',
                ),
                _heading('Main App Functions'),
                _body(
                  'The application allows users to start and stop the system remotely, monitor production rate, and receive notifications and system alerts through a Wi-Fi connection. The system also automatically stops water generation when the water tank reaches its full level.',
                ),
                _body(
                  'Users can review daily and weekly water collection, track recorded water usage, and compare production with weather conditions at the saved AWG location.',
                ),
                _heading('App Version'),
                FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final version = info == null
                        ? null
                        : '${info.version}${info.buildNumber.isEmpty ? '' : ' (build ${info.buildNumber})'}';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _body(
                          version == null
                              ? snapshot.hasError
                                    ? 'Version unavailable'
                                    : 'Loading version…'
                              : 'Version $version',
                        ),
                        _heading('Licenses & Credits'),
                        _body(
                          'ELEODES uses third-party software. View the license notices supplied with those libraries below.',
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('View Licenses'),
                          onPressed: () => showLicensePage(
                            context: context,
                            applicationName: 'ELEODES',
                            applicationVersion: version,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                _heading('Weather Data'),
                _body(
                  'Weather data provided by Open-Meteo under the Creative Commons Attribution 4.0 International license (CC BY 4.0). ELEODES summarizes hourly data for daily weather history.',
                ),
                SelectableText(
                  'https://open-meteo.com/\nhttps://creativecommons.org/licenses/by/4.0/',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppTheme.accentText(
                      context,
                      const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
