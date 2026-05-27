import 'package:flutter/material.dart';

/// 3D GLOWING ICON BUTTON
Widget build3DIconButton({IconData? icon, String? text, required bool isDark}) {
  return SizedBox(
    width: 44,
    height: 44,

    child: Container(
      padding: const EdgeInsets.all(1.5),

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        /// OUTER GRADIENT
        gradient: isDark
            ? const LinearGradient(
                colors: [Colors.blueAccent, Colors.cyanAccent],
              )
            : const LinearGradient(colors: [Colors.blue, Colors.indigo]),

        /// OUTER GLOW
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),

      child: Container(
        alignment: Alignment.center,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF3F8),
        ),

        child: icon != null
            /// ICON MODE
            ? Icon(
                icon,
                size: 20,
                color: isDark ? Colors.cyanAccent : Colors.blue,
              )
            /// TEXT MODE
            : Text(
                text ?? "",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.cyanAccent : Colors.blue,
                ),
              ),
      ),
    ),
  );
}
