import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> showAppDialog({
  required BuildContext context,
  Function(BuildContext dialogContext)? onDialogCreated,
  required String title,
  required String message,

  String positiveText = "OK",
  String negativeText = "CANCEL",

  Future<void> Function()? onPositive,
  VoidCallback? onNegative,

  bool barrierDismissible = false,
  bool showContentLoading = false, //in dialog loading circle
  bool showLoadingOnPositive = false, // 🔥 ADD
  bool canPop = false,

}) async {
  bool isLoading = false;
  final prefs = await SharedPreferences.getInstance();

  bool isDark = prefs.getBool("theme_dark") ?? true;

  await showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      onDialogCreated?.call(dialogContext);

      //final isDark = Theme.of(context).brightness == Brightness.dark;

      return PopScope(
        canPop: canPop,

        child: StatefulBuilder(
          builder: (context, setState) {
            return TweenAnimationBuilder(
              duration: const Duration(milliseconds: 450),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              curve: Curves.easeOutBack,

              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,

                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24),

                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,

                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 20),

                          /// 🔥 MAIN GLASS CARD
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),

                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),

                              child: Container(
                                //margin: const EdgeInsets.only(top: 30),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  55,
                                  20,
                                  20,
                                ),

                                decoration: BoxDecoration(
                                  /// 🔥 GLASS EFFECT
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,

                                    colors: isDark
                                        ? [
                                            Colors.white.withValues(
                                              alpha: 0.14,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                          ]
                                        : [
                                            Colors.white.withValues(
                                              alpha: 0.35,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                          ],
                                  ),

                                  borderRadius: BorderRadius.circular(28),

                                  /// 🔥 NEON BORDER
                                  // border: Border.all(
                                  //   color: Colors.white.withOpacity(0.2),
                                  //   width: 2.5,
                                  // ),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: isDark ? 0.18 : 0.35,
                                    ),
                                    width: 1.5,
                                  ),

                                  /// 🔥 GLOW
                                  // boxShadow: [
                                  //   BoxShadow(
                                  //     color: Colors.white.withOpacity(0.15),
                                  //     blurRadius: 18,
                                  //     spreadRadius: 1,
                                  //   ),
                                  // ],
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
                                    /// 🔥 MESSAGE
                                    /// 🔥 LOADING + MESSAGE
                                    showContentLoading
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 26,
                                                height: 26,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              ),

                                              const SizedBox(height: 10),

                                              Text(
                                                message,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            message,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              height: 1.4,
                                            ),
                                          ),

                                    const SizedBox(height: 24),

                                    /// 🔥 BUTTONS
                                    Row(
                                      children: [
                                        /// NEGATIVE
                                        if (negativeText.isNotEmpty)
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: isLoading
                                                  ? null
                                                  : () {
                                                      // if (Navigator.canPop(dialogContext)) {
                                                      //   Navigator.pop(dialogContext);
                                                      // }

                                                      if (Navigator.of(
                                                        dialogContext,
                                                        rootNavigator: true,
                                                      ).canPop()) {
                                                        Navigator.of(
                                                          dialogContext,
                                                          rootNavigator: true,
                                                        ).pop();
                                                      }

                                                      onNegative?.call();
                                                    },

                                              child: buildGamingButton(
                                                text: negativeText,

                                                backgroundColor: isDark
                                                    ? Color(0xFF2A1A1A)
                                                    : Colors.redAccent,

                                                borderColor: isDark
                                                    ? Colors.redAccent
                                                    : Colors.white,

                                                textColor: isDark
                                                    ? Colors.redAccent
                                                    : Colors.white,

                                                loadingColor: isDark
                                                    ? Colors.redAccent
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),

                                        if (positiveText.isNotEmpty &&
                                            negativeText.isNotEmpty)
                                          const SizedBox(width: 12),

                                        /// POSITIVE
                                        if (positiveText.isNotEmpty)
                                          Expanded(
                                            child: GestureDetector(
                                              // onTap: isLoading
                                              //     ? null
                                              //     : () async {
                                              //         if (showLoadingOnPositive) {
                                              //           setState(
                                              //             () => isLoading = true,
                                              //           );
                                              //         }
                                              //
                                              //         try {
                                              //           // if (onPositive != null) {
                                              //           //   await onPositive();
                                              //           // }
                                              //
                                              //           if (Navigator.canPop(dialogContext)) {
                                              //             Navigator.pop(dialogContext);
                                              //           }
                                              //
                                              //           if (onPositive != null) {
                                              //             await onPositive();
                                              //           }
                                              //
                                              //           Navigator.pop(
                                              //             dialogContext,
                                              //           );
                                              //         } catch (e) {
                                              //           setState(
                                              //             () => isLoading = false,
                                              //           );
                                              //         }
                                              //       },
                                              onTap: isLoading
                                                  ? null
                                                  : () async {
                                                      if (showLoadingOnPositive) {
                                                        setState(
                                                          () =>
                                                              isLoading = true,
                                                        );
                                                      }

                                                      try {
                                                        /// 🔥 CLOSE ONLY DIALOG
                                                        if (Navigator.of(
                                                          dialogContext,
                                                          rootNavigator: true,
                                                        ).canPop()) {
                                                          Navigator.of(
                                                            dialogContext,
                                                            rootNavigator: true,
                                                          ).pop();
                                                        }

                                                        /// 🔥 RUN FUNCTION
                                                        if (onPositive !=
                                                            null) {
                                                          await onPositive();
                                                        }
                                                      } catch (e) {
                                                        setState(
                                                          () =>
                                                              isLoading = false,
                                                        );
                                                      }
                                                    },

                                              child: buildGamingButton(
                                                text: positiveText,

                                                backgroundColor: isDark
                                                    ? Color(0xFF162033)
                                                    : Colors.blue,

                                                borderColor: isDark
                                                    ? Colors.cyanAccent
                                                    : Colors.white,

                                                textColor: isDark
                                                    ? Colors.cyanAccent
                                                    : Colors.white,

                                                loadingColor: isDark
                                                    ? Colors.cyanAccent
                                                    : Colors.white,

                                                isLoading: isLoading,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// 🔥 FLOATING HEADER
                        Positioned(
                          top: 0,

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 10,
                            ),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),

                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.blue.withValues(alpha: 0.5),
                                width: 2,
                              ),

                              gradient: LinearGradient(
                                //colors: const [Colors.blueGrey, Colors.blueGrey],
                                colors: isDark
                                    ? [Color(0xFF1E293B), Color(0xFF1E293B)]
                                    : [Colors.white, Colors.white],
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.blue.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),

                            child: Text(
                              title.toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        /// 🔥 CLOSE BUTTON
                        // Positioned(
                        //   top: 10,
                        //   right: -5,
                        //
                        //   child: GestureDetector(
                        //     onTap: () {
                        //       Navigator.pop(dialogContext);
                        //     },
                        //
                        //     child: Container(
                        //       width: 36,
                        //       height: 36,
                        //
                        //       decoration: BoxDecoration(
                        //         shape: BoxShape.circle,
                        //
                        //         gradient: const LinearGradient(
                        //           colors: [Colors.redAccent, Colors.deepOrange],
                        //         ),
                        //
                        //         border: Border.all(color: Colors.white, width: 2),
                        //
                        //         boxShadow: [
                        //           BoxShadow(
                        //             color: Colors.redAccent.withOpacity(0.4),
                        //             blurRadius: 10,
                        //           ),
                        //         ],
                        //       ),
                        //
                        //       child: const Icon(
                        //         Icons.close,
                        //         color: Colors.white,
                        //         size: 20,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}

Widget buildGamingButton({
  required String text,

  /// 🔥 BUTTON COLORS
  required Color backgroundColor,
  required Color borderColor,
  required Color textColor,
  required Color loadingColor,

  bool isLoading = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14),

    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),

      /// 🔥 BUTTON BG
      color: backgroundColor,

      /// 🔥 BORDER
      border: Border.all(color: borderColor, width: 1.2),

      /// 🔥 SHADOW
      boxShadow: [
        BoxShadow(
          color: backgroundColor.withValues(alpha: 0.35),
          blurRadius: 10,
        ),
      ],
    ),

    alignment: Alignment.center,

    child: isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: loadingColor,
            ),
          )
        : Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
  );
}

// Future<void> showAppDialog({
//   required BuildContext context, // 🔥 ADD THIS
//   required String title,
//   required String message,
//
//   String positiveText = "OK",
//   String negativeText = "CANCEL",
//
//   Future<void> Function()? onPositive,
//   VoidCallback? onNegative,
//
//   bool barrierDismissible = true,
//   bool showLoadingOnPositive = false,
// }) async {
//
//   bool isLoading = false;
//
//   await showDialog(
//     context: context, // ✅ now valid
//     barrierDismissible: barrierDismissible,
//     builder: (dialogContext) {
//
//       return StatefulBuilder(
//         builder: (context, setState) {
//
//           return AlertDialog(
//             title: Text(title),
//             content: Text(message),
//
//             actions: [
//
//               // 🔹 NEGATIVE BUTTON
//               if (negativeText.isNotEmpty)
//                 TextButton(
//                   onPressed: isLoading
//                       ? null
//                       : () {
//                     Navigator.pop(dialogContext);
//                     onNegative?.call();
//                   },
//                   child: Text(negativeText),
//                 ),
//
//               // 🔹 POSITIVE BUTTON
//               if (positiveText.isNotEmpty)
//                 TextButton(
//                   onPressed: isLoading
//                       ? null
//                       : () async {
//
//                     if (showLoadingOnPositive) {
//                       setState(() => isLoading = true);
//                     }
//
//                     try {
//                       if (onPositive != null) {
//                         await onPositive();
//                       }
//
//                       Navigator.pop(dialogContext);
//
//                     } catch (e) {
//                       setState(() => isLoading = false);
//                     }
//                   },
//
//                   child: isLoading
//                       ? const SizedBox(
//                     width: 18,
//                     height: 18,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                       : Text(positiveText),
//                 ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }
