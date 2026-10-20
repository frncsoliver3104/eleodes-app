import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;

  final bool? value;

  final ValueChanged<bool>? onChanged;

  final VoidCallback? onTap;

  final bool showArrow;

  const SettingsTile({
    super.key,
    required this.title,
    this.value,
    this.onChanged,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      child: SizedBox(
        height: 30,

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Expanded(
                child: Text(
                  title,

                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.text(context, Colors.black),
                  ),
                ),
              ),

              if (value != null && onChanged != null)
                GestureDetector(
                  onTap: () {
                    onChanged!(!value!);
                  },

                  child: AnimatedContainer(
                    curve: Curves.easeInOutCubic,
                    duration: const Duration(milliseconds: 180),

                    width: 32,
                    height: 20,

                    padding: const EdgeInsets.all(1),

                    decoration: BoxDecoration(
                      color: value!
                          ? const Color(0xFF30F8B0)
                          : Theme.of(context).colorScheme.outline,

                      borderRadius: BorderRadius.circular(10),

                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),

                          offset: Offset(0, 2),

                          blurRadius: 2,
                        ),
                      ],
                    ),

                    child: AnimatedAlign(
                      curve: Curves.easeInOutCubic,
                      duration: const Duration(milliseconds: 180),

                      alignment: value!
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: Container(
                        width: 18,
                        height: 18,

                        decoration: BoxDecoration(
                          color: Colors.white,

                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: Color(0x40000000),

                              offset: Offset(0, 2),

                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: AppTheme.text(context, Colors.black),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
