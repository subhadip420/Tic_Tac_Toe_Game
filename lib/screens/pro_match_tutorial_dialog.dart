import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SHOW PRO MATCH TUTORIAL DIALOG
Future<void> showProMatchTutorialDialog({
  required BuildContext context,
  required bool isDark,
  required bool vibrationOn,
}) async {
  PageController pageController = PageController();
  int currentPage = 0;

  /// Tutorial Slide UI Helper (Ab ye Icon aur Image dono support karega)
  Widget buildTutorialSlide({IconData? icon, String? imagePath, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Agar image path diya hai toh Image dikhayega
          if (imagePath != null)
            Image.asset(
              imagePath,
              height: 100, // Image ki height apne hisaab se adjust kar sakte ho
              fit: BoxFit.contain,
            )
          /// Warna agar Icon diya hai toh Icon dikhayega
          else if (icon != null)
            Icon(icon, size: 80, color: Colors.cyanAccent),

          const SizedBox(height: 20),

          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: "Tutorial",
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 320,
                    height: 380,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)]
                            : [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.5)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: pageController,
                            onPageChanged: (index) {
                              setDialogState(() {
                                currentPage = index;
                              });
                            },
                            children: [
                              /// SLIDE 1: Yahan Icon rakha hai
                              buildTutorialSlide(
                                icon: Icons.psychology_rounded,
                                title: "Pro Match",
                                description: "Welcome to the ultimate Tic-Tac-Toe! This mode requires pure strategy.",
                              ),

                              /// SLIDE 2: Yahan Image add ki hai
                              buildTutorialSlide(
                                imagePath: "assets/images/tutorial_2.png", // Apni image ka path yahan daalein
                                title: "Only 3 Pieces",
                                description: "You can only place a maximum of 3 pieces on the board at a time.",
                              ),

                              /// SLIDE 3: Yahan Image add ki hai
                              buildTutorialSlide(
                                imagePath: "assets/images/tutorial_3.png", // Apni image ka path yahan daalein
                                title: "Select & Move",
                                description:
                                    "When you have 3 pieces, TAP your own piece to select it, then TAP an empty box to move it. Connect 3 to win!",
                              ),
                            ],
                          ),
                        ),

                        /// Bottom Controls (Dots & Button)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(3, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(right: 5),
                                    height: 8,
                                    width: currentPage == index ? 20 : 8,
                                    decoration: BoxDecoration(
                                      color: currentPage == index
                                          ? Colors.cyanAccent
                                          : (isDark ? Colors.white30 : Colors.black26),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (vibrationOn) HapticFeedback.lightImpact();
                                  if (currentPage < 2) {
                                    pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  } else {
                                    Navigator.pop(context); // Close tutorial
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.cyanAccent]),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 8),
                                    ],
                                  ),
                                  child: Text(
                                    currentPage == 2 ? "LET'S PLAY" : "NEXT",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(animation.value),
        child: Opacity(opacity: animation.value, child: child),
      );
    },
  );
}
