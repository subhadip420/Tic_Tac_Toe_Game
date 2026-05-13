import 'package:flutter/material.dart';

class NeonGlowingButton extends StatelessWidget {

  final String text;

  final IconData icon;

  final VoidCallback onTap;

  final bool isDark;

  final AnimationController glowController;

  final Animation<double> glowAnimation;

  const NeonGlowingButton({
    super.key,

    required this.text,

    required this.icon,

    required this.onTap,

    required this.isDark,

    required this.glowController,

    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {

    List<Color> colors = isDark

        ? [
      Colors.blueAccent,
      Colors.cyanAccent,
    ]

        : [
      Colors.blueAccent,
      Colors.blueAccent,
    ];

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        borderRadius:
        BorderRadius.circular(16),

        child: AnimatedBuilder(

          animation: glowController,

          builder: (context, child) {

            return Container(

              padding:
              const EdgeInsets.all(1),

              decoration: BoxDecoration(

                borderRadius:
                BorderRadius.circular(16),

                gradient: LinearGradient(
                  colors: colors,
                ),

                boxShadow: [

                  BoxShadow(

                    color: colors.first
                        .withValues(
                      alpha:
                      glowAnimation.value,
                    ),

                    blurRadius:
                    20 *
                        glowAnimation.value,
                  ),
                ],
              ),

              child: Container(

                padding:
                const EdgeInsets.symmetric(

                  horizontal: 20,

                  vertical: 10,
                ),

                decoration: BoxDecoration(

                  color: isDark

                      ? const Color(
                    0xFF2B3A5A,
                  )

                      : Colors.white,

                  borderRadius:
                  BorderRadius.circular(14),
                ),

                child: Row(

                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    Icon(
                      icon,

                      color: colors.first,
                    ),

                    const SizedBox(width: 6),

                    Text(

                      text,

                      style: TextStyle(

                        fontSize: 16,

                        fontWeight:
                        FontWeight.bold,

                        color: isDark

                            ? Colors.white

                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}