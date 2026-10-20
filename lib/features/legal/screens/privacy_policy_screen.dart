import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          "Privacy Policy",
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
                heading(context, "Privacy Policy"),

                body(context, "Effective Date: July 24, 2026"),

                body(
                  context,
                  "Welcome to Eleodes. Your privacy is important to us. This Privacy Policy explains how the application collects, uses, and protects your information.",
                ),

                heading(context, "Information We Collect"),

                body(
                  context,
                  "The application collects only the data necessary to monitor the Atmospheric Water Generation System, including:",
                ),

                body(
                  context,
                  "• Humidity Level\n"
                  "• Temperature\n"
                  "• Water Level\n"
                  "• pH Level\n"
                  "• System Status",
                ),

                heading(context, "How We Use Your Information"),

                body(context, "The collected data is used to:"),

                body(
                  context,
                  "• Monitor the AWG system in real time.\n"
                  "• Display sensor readings in the application.\n"
                  "• Send notifications and alerts.\n"
                  "• Improve the performance of the system.",
                ),

                heading(context, "Data Protection"),

                body(
                  context,
                  "We take reasonable measures to protect the collected data from unauthorized access, misuse, or loss.",
                ),

                heading(context, "Data Sharing"),

                body(
                  context,
                  "The application does not sell, rent, or share your personal information with third parties unless required by law.",
                ),

                heading(context, "Internet Connection"),

                body(
                  context,
                  "A stable internet connection is required for real-time monitoring, notifications, and remote system control.",
                ),

                heading(context, "User Responsibility"),

                body(
                  context,
                  "Users are responsible for protecting their account and ensuring the proper use of the application and the AWG system.",
                ),

                heading(context, "Updates to This Policy"),

                body(
                  context,
                  "This Privacy Policy may be updated to improve the application or comply with future requirements. Any changes will be reflected within the application.",
                ),

                heading(context, "Contact Us"),

                body(
                  context,
                  "If you have any questions or concerns about this Privacy Policy, please contact the Eleodes development team.",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
