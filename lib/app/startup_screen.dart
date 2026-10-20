import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ELEODES/core/settings/app_settings.dart';
import 'package:ELEODES/features/legal/screens/terms_agreement_screen.dart';
import 'package:ELEODES/app/main_screen.dart';
import 'package:ELEODES/features/guide/screens/beginner_guide_screen.dart';
import 'package:ELEODES/features/devices/services/device_auth_service.dart';
import 'package:ELEODES/features/devices/services/device_pairing_store.dart';
import 'package:ELEODES/features/notifications/services/notification_service.dart';
import 'package:ELEODES/firebase_options.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  static const _background = Color(0xFFD4FFED);
  static const _mint = Color(0xFF1DE3AB);
  static const _minimumSplashDuration = Duration(milliseconds: 700);

  String _message = '';
  bool _loadingFailed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    if (_isLoading) return;
    _isLoading = true;
    final startedAt = DateTime.now();
    setState(() {
      _loadingFailed = false;
      _message = '';
    });
    try {
      await Future.wait([
        AppSettings.instance.initialize(),
        DevicePairingStore.instance.initialize(),
      ]);

      final prefs = await SharedPreferences.getInstance();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      DevicePairingStore.instance.beforeForget =
          DeviceAuthService.instance.signOut;
      unawaited(_initializeNotifications());

      final termsAccepted = prefs.getBool('termsAccepted') ?? false;

      if (!termsAccepted) {
        _openScreen(const TermsScreen());
        return;
      }

      final guideCompleted = prefs.getBool('beginnerGuideCompleted') ?? false;
      if (!guideCompleted) {
        _openScreen(const BeginnerGuideScreen(firstLaunch: true));
        return;
      }

      final remaining =
          _minimumSplashDuration - DateTime.now().difference(startedAt);
      if (remaining > Duration.zero) await Future.delayed(remaining);

      if (!mounted) return;

      _openScreen(const MainScreen());
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingFailed = true;
        _message = error is TimeoutException
            ? 'Could not reach Firebase. Check your internet and retry.'
            : 'Could not load your setup. Please try again.';
      });
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
    } catch (error) {
      debugPrint('Notification initialization failed: $error');
    }
  }

  void _openScreen(Widget screen) {
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('ele', style: _wordmarkStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 36,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Text('des', style: _wordmarkStyle),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '“Every Drop Matters”',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (!_loadingFailed) ...[
                    const SizedBox(height: 38),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_mint),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ],
                  if (_loadingFailed) ...[
                    const SizedBox(height: 24),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _startLoading,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _wordmarkStyle = TextStyle(
    color: Colors.black,
    fontSize: 52,
    height: 1,
    letterSpacing: -2.5,
    fontWeight: FontWeight.w400,
  );
}
