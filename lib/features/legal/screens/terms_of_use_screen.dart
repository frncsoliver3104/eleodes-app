import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  Widget heading(BuildContext context, String text) {
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

  Widget body(BuildContext context, String text) {
    return Padding(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context, const Color(0xFFC8F7E6)),

      appBar: AppBar(
        backgroundColor: AppTheme.background(context, const Color(0xFFC8F7E6)),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Terms and Conditions",
          style: TextStyle(
            color: AppTheme.text(context, Colors.black87),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
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
                heading(context, "Terms and Conditions"),

                body(
                  context,
                  "Welcome to Eleodes. By using this application, you agree to the following Terms and Conditions.",
                ),

                heading(context, "Monitoring and Control"),

                body(
                  context,
                  "This application is used to monitor the IoT-Based Atmospheric Water Generation System, view real-time sensor data, receive notifications, and remotely turn the system on or off.",
                ),

                heading(context, "User Responsibility"),

                body(
                  context,
                  "Users are responsible for the proper use and maintenance of the AWG device and its components.",
                ),

                heading(context, "Data Accuracy"),

                body(
                  context,
                  "Sensor readings (humidity, temperature, water level, and pH) depend on the condition of the sensors and internet connection. Temporary delays or inaccuracies may occur.",
                ),

                heading(context, "Internet Connection"),

                body(
                  context,
                  "A stable Wi-Fi connection is required for real-time monitoring and receiving notifications.",
                ),

                heading(context, "Notifications"),

                body(
                  context,
                  "The application provides alerts based on sensor readings. Users should regularly check the system to ensure proper operation.",
                ),

                heading(context, "Privacy"),

                body(
                  context,
                  "The application only collects system monitoring data necessary for the operation of the AWG. Personal information is not shared with third parties.",
                ),

                heading(context, "System Maintenance"),

                body(
                  context,
                  "Users should regularly clean and maintain the AWG system, including its filters and sensors, to ensure safe and reliable performance.",
                ),

                heading(context, "Limitation of Liability"),

                body(
                  context,
                  "The developers are not responsible for damages, data loss, or system failures caused by misuse, improper installation, power interruptions, or internet connectivity issues.",
                ),

                heading(context, "Updates"),

                body(
                  context,
                  "The application may receive updates to improve performance, fix issues, or add new features.",
                ),

                heading(context, "Acceptance"),

                body(
                  context,
                  "By using this application, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
