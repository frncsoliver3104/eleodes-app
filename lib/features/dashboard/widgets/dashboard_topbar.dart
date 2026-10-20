import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:ELEODES/features/notifications/screens/notification_screen.dart';
import 'package:ELEODES/features/notifications/services/notification_service.dart';

class DashboardTopBar extends StatelessWidget {
  final VoidCallback? onProfile;
  final VoidCallback? onNotification;

  static final NotificationService _notificationService = NotificationService();
  static final Stream<int> _unreadCount = _notificationService.unreadCount;

  const DashboardTopBar({super.key, this.onProfile, this.onNotification});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ELEODES LOGO
          GestureDetector(
            onTap: onProfile,
            child: Row(
              children: [
                Text(
                  "ele",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.text(context, Colors.black),
                  ),
                ),
                Image.asset(
                  "assets/images/app_icon.png",
                  width: 22,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                Text(
                  "des",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.text(context, Colors.black),
                  ),
                ),
              ],
            ),
          ),

          // NOTIFICATION BUTTON
          StreamBuilder<int>(
            stream: _unreadCount,
            initialData: 0,
            builder: (context, snapshot) {
              final hasUnreadNotifications = (snapshot.data ?? 0) > 0;

              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  if (onNotification != null) {
                    onNotification!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  }
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Image.asset(
                          'assets/images/Notification.png',
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 24,
                          height: 21,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    if (hasUnreadNotifications)
                      Positioned(
                        top: -1,
                        right: -2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: AppTheme.surface(context, Colors.white),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: SizedBox(width: 10, height: 10),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
