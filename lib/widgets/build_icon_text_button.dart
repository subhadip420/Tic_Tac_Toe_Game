import 'package:flutter/material.dart';

class BuildIconTextButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const BuildIconTextButton({
    super.key,
    required this.icon,
    required this.text,
    required this.isDark,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.5),

      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(18),

        /// Gradient Border
        gradient: isDark
            ? const LinearGradient(
                colors: [Colors.blueAccent, Colors.cyanAccent],
              )
            : LinearGradient(colors: [Color(0xFF194B9B), Color(0xFF1F5CC0)]),

        /// Outer glow
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.5),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),

        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.blue,
          borderRadius: borderRadius ?? BorderRadius.circular(18),
          boxShadow: boxShadow,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, color: isDark ? Colors.cyanAccent : Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.cyanAccent : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
