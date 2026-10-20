import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ELEODES/features/guide/screens/beginner_guide_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool accepted = false;

  Future<void> continueApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("termsAccepted", true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const BeginnerGuideScreen(firstLaunch: true),
      ),
    );
  }

  Widget heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.accentText(context, const Color(0xFF1B5E20)),
        ),
      ),
    );
  }

  Widget body(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppTheme.text(context, Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context, const Color(0xFFC8F7E6)),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
        title: const Text(
          "Terms & Agreement",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context, Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
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
                      heading("Terms and Conditions"),

                      body(
                        "Welcome to Eleodes. By using this application, you agree to the following Terms and Conditions.",
                      ),

                      heading("Monitoring and Control"),

                      body(
                        "This application is used to monitor the IoT-Based Atmospheric Water Generation (AWG) System, view real-time sensor data, receive notifications, and remotely turn the system on or off.",
                      ),

                      heading("User Responsibility"),

                      body(
                        "Users are responsible for the proper use and maintenance of the AWG device and its components.",
                      ),

                      heading("Data Accuracy"),

                      body(
                        "Sensor readings (humidity, temperature, water level, and pH) depend on the condition of the sensors and internet connection. Temporary delays or inaccuracies may occur.",
                      ),

                      heading("Internet Connection"),

                      body(
                        "A stable Wi-Fi connection is required for real-time monitoring and receiving notifications.",
                      ),

                      heading("Notifications"),

                      body(
                        "The application provides alerts based on sensor readings. Users should regularly check the system to ensure proper operation.",
                      ),

                      heading("Privacy"),

                      body(
                        "The application only collects system monitoring data necessary for the operation of the AWG. Personal information is not shared with third parties.",
                      ),

                      heading("System Maintenance"),

                      body(
                        "Users should regularly clean and maintain the AWG system, including its filters and sensors, to ensure safe and reliable performance.",
                      ),

                      heading("Limitation of Liability"),

                      body(
                        "The developers are not responsible for damages, data loss, or system failures caused by misuse, improper installation, power interruptions, or internet connectivity issues.",
                      ),

                      heading("Updates"),

                      body(
                        "The application may receive updates to improve performance, fix issues, or add new features.",
                      ),

                      heading("Acceptance"),

                      body(
                        "By using this application, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.",
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Material(
              color: AppTheme.surface(context, Colors.white),
              borderRadius: BorderRadius.circular(15),
              child: CheckboxListTile(
                value: accepted,
                activeColor: Colors.green,
                title: const Text(
                  "I have read and agree to the Privacy Policy and Terms of Use.",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onChanged: (value) {
                  setState(() {
                    accepted = value ?? false;
                  });
                },
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: accepted ? continueApp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
