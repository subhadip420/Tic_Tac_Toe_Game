import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/build_circle_icon_button.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _TermsConditionPageState();
}

class _TermsConditionPageState extends State<InfoPage> {
  bool isDark = true;

  @override
  void initState() {
    super.initState();

    loadTheme();
  }

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final bool isDark =
    //     Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,

      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF3F7FF),

      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // transparent status bar
          statusBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark, // Android
          statusBarBrightness: isDark
              ? Brightness.dark
              : Brightness.light, // iOS
        ),

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

        title: Text(
          "Info Center",

          style: TextStyle(
            fontSize: 20,
            color: isDark ? Colors.cyanAccent : Colors.blue,

            fontWeight: FontWeight.bold,
          ),
        ),

        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Tooltip(
            message: "Back",
            child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
              },
              child: build3DIconButton(icon: Icons.arrow_back, isDark: isDark),
            ),
          ),
        ),
      ),

      // body: SingleChildScrollView(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10,
                  kToolbarHeight + MediaQuery.of(context).padding.top + 10,
                  10,
                  10,
                ),

                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),

                  padding: const EdgeInsets.all(10),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      /// TERMS & CONDITIONS
                      Text(
                        "Terms & Conditions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 02),

                      Container(
                        width: 185,
                        height: 2,
                        color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                      ),

                      const SizedBox(height: 18),

                      Text(
                        "• Players must play fairly and should not use cheats, hacks, bugs, or modified versions of the game.\n\n"
                        "• A stable internet connection is required for smooth online multiplayer gameplay.\n\n"
                        "• Online rooms, gameplay synchronization, and multiplayer functionality may occasionally be affected by internet or server-related issues.\n\n"
                        "• Users must not exploit bugs, spam rooms, disturb gameplay, or attempt unauthorized access to online services.\n\n"
                        "• Game features, systems, advertisements, or gameplay mechanics may change in future updates without prior notice.\n\n"
                        "• By downloading or using this application, you agree to these terms and conditions.",

                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 35),

                      /// PRIVACY POLICY
                      Text(
                        "Privacy Policy",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 02),

                      Container(
                        width: 130,
                        height: 2,
                        color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                      ),

                      const SizedBox(height: 18),

                      Text(
                        "• We do not collect sensitive personal information from users.\n\n"
                        "• Basic game preferences such as nickname, settings, and gameplay preferences may be stored locally on the user's device.\n\n"
                        "• During online gameplay, temporary match-related data may be synchronized through cloud services for multiplayer functionality.\n\n"
                        "• Personal gameplay preferences are primarily stored locally and are not shared publicly.",

                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 35),

                      /// SUPPORT
                      Text(
                        "Support",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 02),

                      Container(
                        width: 75,
                        height: 2,
                        color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                      ),

                      const SizedBox(height: 18),

                      Text(
                        "For support, bug reports, feedback, or business inquiries, contact us at:",
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

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
                            fontSize: 15,
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blueAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),


                    ],
                  ),
                ),
              ),
            ),
          ),

          /// FIXED BOTTOM BAR
          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(vertical: 5),

            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827)
                  : Colors.white,

              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white24
                      : Colors.black12,
                ),
              ),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white60
                        : Colors.black54,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  "Powered by SP Tech Studios",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white54
                        : Colors.black54,
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

/// end main class
