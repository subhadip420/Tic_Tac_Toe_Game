import 'package:flutter/material.dart';

class CustomToast {
  static void show({
    required BuildContext context,

    required String message,

    required bool isDark,

    IconData? icon,

    Color? color,

    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,

        behavior: SnackBarBehavior.floating,

        backgroundColor: Colors.transparent,

        elevation: 0,

        //margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

        //content: Container(
        content: Center(
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),

                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [Colors.white, const Color(0xFFF3F6FB)],
                ),

                border: Border.all(
                  color: isDark
                      ? Colors.cyanAccent.withValues(alpha: 0.25)
                      : Colors.blueAccent.withValues(alpha: 0.25),
                ),

                boxShadow: [
                  BoxShadow(
                    color: (color ?? Colors.blueAccent).withValues(alpha: 0.25),

                    blurRadius: 14,

                    spreadRadius: 1,

                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 34,
                      height: 34,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        gradient: LinearGradient(
                          colors: [
                            color ?? Colors.blueAccent,

                            color ?? Colors.cyanAccent,
                          ],
                        ),
                      ),

                      child: Icon(
                        icon,

                        color: Colors.white,

                        size: 15,
                      ),
                    ),

                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,

                        fontSize: 14,

                        fontWeight: FontWeight.w600,
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
}
