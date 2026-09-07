import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/build_circle_icon_button.dart';

/// INFO PAGE
class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _TermsConditionPageState();
}

class _TermsConditionPageState extends State<InfoPage> {
  /// THEME MODE
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    /// LOAD SAVED THEME
    loadTheme();
  }

  /// LOAD THEME
  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF3F7FF),

      appBar: AppBar(
        /// STATUS BAR STYLE
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // transparent status bar
          statusBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark, // Android
          statusBarBrightness: isDark
              ? Brightness.dark
              : Brightness.light, // iOS
        ),

        /// APPBAR BOTTOM BORDER
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ),

        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,

        /// GLASS EFFECT
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),

        /// PAGE TITLE
        title: Text(
          "Info Center",
          style: TextStyle(
            fontSize: 20,
            color: isDark ? Colors.cyanAccent : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),

        /// BACK BUTTON
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Tooltip(
            message: "Back",
            child: GestureDetector(
              onTap: () async {
                /// CLOSE PAGE
                Navigator.pop(context);
              },
              child: build3DIconButton(icon: Icons.arrow_back, isDark: isDark),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  15, // Slightly increased side padding for cards
                  kToolbarHeight + MediaQuery.of(context).padding.top + 20,
                  15,
                  20,
                ),
                child: Column(
                  children: [

                    /// -----------------------------------
                    /// SHARE APP CARD
                    /// -----------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  Icons.share_outlined,
                                  color: isDark ? Colors.cyanAccent : Colors.blue,
                                  size: 28
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Share App",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Enjoying Tic-Tac-Toe? Share it with your friends and play together!",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          GestureDetector(
                            onTap: () {
                              /// SHARE LOGIC FIX
                              SharePlus.instance.share(
                                ShareParams(
                                  text: 'Play Tic-Tac-Toe with me! Download the app here: https://play.google.com/store/apps/details?id=com.sptechstudios.tictactoe',
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.ios_share, color: Colors.blueAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Share Now",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// -----------------------------------
                    /// RATE & REVIEW CARD
                    /// -----------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  Icons.star_rate_rounded,
                                  color: isDark ? Colors.cyanAccent : Colors.orangeAccent,
                                  size: 28
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Rate & Review",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Love playing Tic-Tac-Toe? Please take a moment to rate us on the Play Store. Your feedback helps us grow!",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          GestureDetector(
                            onTap: () async {
                              /// PLAY STORE LINK LOGIC
                              final Uri playStoreUrl = Uri.parse(
                                  'https://play.google.com/store/apps/details?id=com.sptechstudios.tictactoe');

                              if (await canLaunchUrl(playStoreUrl)) {
                                await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.thumb_up_alt_outlined, color: Colors.blueAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Rate on Play Store",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Container(
                    //   width: double.infinity,
                    //   padding: const EdgeInsets.all(20),
                    //   decoration: BoxDecoration(
                    //     color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    //     borderRadius: BorderRadius.circular(16),
                    //     boxShadow: [
                    //       if (!isDark)
                    //         const BoxShadow(
                    //           color: Colors.black12,
                    //           blurRadius: 10,
                    //           offset: Offset(0, 4),
                    //         ),
                    //     ],
                    //   ),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Row(
                    //         children: [
                    //           Icon(
                    //               Icons.star_rate_rounded,
                    //               color: isDark ? Colors.cyanAccent : Colors.orangeAccent,
                    //               size: 28
                    //           ),
                    //           const SizedBox(width: 10),
                    //           Text(
                    //             "Rate & Review",
                    //             style: TextStyle(
                    //               fontSize: 20,
                    //               fontWeight: FontWeight.bold,
                    //               color: isDark ? Colors.white : Colors.black87,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       const SizedBox(height: 15),
                    //       Text(
                    //         "Love playing Tic-Tac-Toe? Please take a moment to rate us on the Play Store. Your feedback helps us grow!",
                    //         style: TextStyle(
                    //           fontSize: 15,
                    //           height: 1.5,
                    //           color: isDark ? Colors.white70 : Colors.black87,
                    //         ),
                    //       ),
                    //       const SizedBox(height: 15),
                    //       GestureDetector(
                    //         onTap: () async {
                    //           /// IN-APP REVIEW LOGIC
                    //           final InAppReview inAppReview = InAppReview.instance;
                    //
                    //           if (await inAppReview.isAvailable()) {
                    //             /// Direct app ke andar popup layega
                    //             await inAppReview.requestReview();
                    //           } else {
                    //             /// Fallback: Play Store open kar dega agar popup available na ho
                    //             await inAppReview.openStoreListing(
                    //               appStoreId: 'com.sptechstudios.tictactoe',
                    //             );
                    //           }
                    //         },
                    //         child: Row(
                    //           children: [
                    //             const Icon(Icons.thumb_up_alt_outlined, color: Colors.blueAccent, size: 20),
                    //             const SizedBox(width: 8),
                    //             Text(
                    //               "Rate on Play Store",
                    //               style: TextStyle(
                    //                 fontSize: 16,
                    //                 color: Colors.blueAccent,
                    //                 fontWeight: FontWeight.w600,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    const SizedBox(height: 10),

                    /// -----------------------------------
                    /// POLICIES & TERMS CARD
                    /// -----------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  Icons.policy_outlined,
                                  color: isDark ? Colors.cyanAccent : Colors.blue,
                                  size: 28
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Policies & Terms",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          GestureDetector(
                            onTap: () async {
                              final Uri url = Uri.parse(
                                  'https://subhadip420.github.io/tic-tac-toe-privacy-policy/');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Text(
                              "Read our full Privacy Policy & Terms and Conditions",
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blueAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10), // Space between cards

                    /// -----------------------------------
                    /// SUPPORT CARD
                    /// -----------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  Icons.support_agent_outlined,
                                  color: isDark ? Colors.cyanAccent : Colors.blue,
                                  size: 28
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Support",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "For support, bug reports, feedback, or business inquiries, contact us at:",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          GestureDetector(
                            onTap: () async {
                              final Uri emailUri = Uri(
                                scheme: 'mailto',
                                path: 'support.sptechstudios@gmail.com',
                              );
                              await launchUrl(emailUri);
                            },
                            child: Text(
                              "support.sptechstudios@gmail.com",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blueAccent,
                                fontWeight: FontWeight.w500,
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
          ),

          /// FIXED BOTTOM BAR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// APP VERSION
                Text(
                  "Version 1.2.0",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                /// COMPANY NAME
                Text(
                  "Powered by SP Tech Studios",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}