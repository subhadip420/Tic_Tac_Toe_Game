// import 'package:flutter/material.dart';
//
// class LoadingDialog {
//
//   static void show(BuildContext context, {String message = "Loading..."}) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withValues(alpha:0.5),
//
//       builder: (context) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           insetPadding: const EdgeInsets.symmetric(horizontal: 40),
//
//           child: SafeArea(
//             child: IntrinsicHeight(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 25, vertical: 20),
//
//                 decoration: BoxDecoration(
//                   color: isDark
//                       ? const Color(0xFF1E293B)
//                       : Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//
//                     CircularProgressIndicator(
//                       strokeWidth: 3,
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         isDark ? Colors.white : Colors.blue,
//                       ),
//                     ),
//
//                     const SizedBox(height: 15),
//
//                     // 🔥 FINAL FIXED TEXT
//                     Flexible(
//                       child: Text(
//                         message,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: isDark
//                               ? Colors.white70
//                               : Colors.black87,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   static void hide(BuildContext context) {
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context);
//     }
//   }
// }


import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingDialog {

  static void show(
      BuildContext context, {
        String message = "Loading...",
      }) async {

    /// 🔥 CUSTOM THEME
    final prefs = await SharedPreferences.getInstance();

    bool isDark = prefs.getBool("theme_dark") ?? true;

    showDialog(
      context: context,

      barrierDismissible: false,

      //barrierColor: Colors.black.withValues(alpha: 0.45),
      barrierColor: Colors.transparent,
      builder: (_) {

        return Dialog(
          backgroundColor: Colors.transparent,

          insetPadding: const EdgeInsets.symmetric(horizontal: 00),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),

            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 8,
                sigmaY: 8,
              ),

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 05,
                  vertical: 05,
                ),

                decoration: BoxDecoration(

                  /// 🔥 GLASS EFFECT
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,

                    colors: isDark
                        ? [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                        : [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.14),
                    ],
                  ),

                  borderRadius: BorderRadius.circular(28),

                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: isDark ? 0.18 : 0.35,
                    ),
                    width: 1.5,
                  ),

                  boxShadow: [

                    BoxShadow(
                      color: Colors.cyanAccent.withValues(
                        alpha: isDark ? 0.10 : 0.06,
                      ),

                      blurRadius: 24,
                      spreadRadius: 2,
                    ),

                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.08,
                      ),

                      offset: const Offset(0, 8),
                      blurRadius: 18,
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// 🔥 LOTTIE ANIMATION
                    // SizedBox(
                    //   width: 160,
                    //   height: 150,
                    //
                    //   // child: Lottie.asset(
                    //   //   "assets/lottie/material_wave_loading.json",
                    //   //
                    //   //   fit: BoxFit.contain,
                    //   //
                    //   //   repeat: true,
                    //   // ),
                    //
                    // ),

                    /// 🔥 LOTTIE ANIMATION
                    SizedBox(
                      width: 160,
                      height: 100,

                      child: Transform.scale(
                        scale: 2,

                        child: Lottie.asset(
                          "assets/lottie/material_wave_loading.json",
                          //"assets/lottie/loading_animation_blue.json",

                          fit: BoxFit.contain,

                          repeat: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 0),

                    /// 🔥 MESSAGE
                    Text(
                      message,

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,

                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}