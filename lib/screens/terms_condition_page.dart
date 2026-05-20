import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/build_circle_icon_button.dart';

class TermsConditionPage extends StatefulWidget {
  const TermsConditionPage({super.key});

  @override
  State<TermsConditionPage> createState() =>
      _TermsConditionPageState();
}

class _TermsConditionPageState
    extends State<TermsConditionPage> {


  bool isDark = true;
  @override
  void initState() {
    super.initState();

    loadTheme();
  }


  Future<void> loadTheme() async {

    SharedPreferences prefs =
    await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {

      isDark =
          prefs.getBool("theme_dark") ?? true;
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
            color: isDark
                ? Colors.white24
                : Colors.black12,
          ),
        ),

        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,

        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),

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
          "Terms & Conditions",

          style: TextStyle(
            color: isDark
                ? Colors.cyanAccent
                : Colors.blue,

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
              child: build3DIconButton(icon:Icons.arrow_back,isDark: isDark),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.fromLTRB(
              10,
              kToolbarHeight +
                  MediaQuery.of(context).padding.top +
                  10,
              10,
              10,
            ),

        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.all(10),

          child: Container(
            width: double.infinity,

            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white,

              borderRadius: BorderRadius.circular(25),

              border: Border.all(
                color: isDark
                    ? Colors.blueAccent
                    : Colors.blue,

                width: 1.2,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.5 : 0.12,
                  ),

                  blurRadius: 12,

                  offset: const Offset(0, 6),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                buildSection(
                  isDark,
                  "1. Fair Play",
                  "Players must play fairly and should not use cheats, hacks, bugs, or modified versions of the game.",
                ),

                buildSection(
                  isDark,
                  "2. Online Match Rules",
                  "Intentionally disconnecting, disturbing gameplay, spamming rooms, or ruining the multiplayer experience may result in temporary restrictions.",
                ),

                buildSection(
                  isDark,
                  "3. User Responsibility",
                  "You are responsible for your nickname, room codes, gameplay activity, and device security while using the app.",
                ),

                buildSection(
                  isDark,
                  "4. Internet Connection",
                  "A stable internet connection is required for smooth online multiplayer gameplay. Network issues may cause delays or disconnections.",
                ),

                buildSection(
                  isDark,
                  "5. Temporary Online Data",
                  "During online gameplay, temporary match-related data may be synchronized through cloud services for room connectivity and multiplayer functionality.",
                ),

                buildSection(
                  isDark,
                  "6. Local Device Storage",
                  "Basic user preferences such as nickname, settings, and game preferences may be stored locally on your device for a better gameplay experience.",
                ),

                buildSection(
                  isDark,
                  "7. Privacy",
                  "We do not collect sensitive personal information from users. Personal gameplay preferences are primarily stored locally on the user's device.",
                ),

                buildSection(
                  isDark,
                  "8. Server & Connectivity",
                  "Online services may occasionally become unavailable due to maintenance, technical issues, or internet-related problems.",
                ),

                buildSection(
                  isDark,
                  "9. App Updates",
                  "Game features, design, multiplayer systems, rewards, advertisements, or gameplay mechanics may change in future updates without prior notice.",
                ),

                buildSection(
                  isDark,
                  "10. Prohibited Activities",
                  "Users must not exploit bugs, impersonate other players, attempt unauthorized server/database access, or disrupt normal gameplay.",
                ),

                buildSection(
                  isDark,
                  "11. Match Interruption",
                  "Unexpected app closures, internet failures, or device-related problems may interrupt online matches. The app is not responsible for gameplay losses caused by such issues.",
                ),

                buildSection(
                  isDark,
                  "12. Acceptance",
                  "By downloading or using this application, you agree to these terms and conditions.",
                ),

                const SizedBox(height: 10),


                Center(
                  child: Text(
                    "Powered by SP Tech Studios",

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 13,

                      letterSpacing: 1,

                      color: isDark
                          ? Colors.white54
                          : Colors.black54,
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

  Widget buildSection(
      bool isDark,
      String title,
      String description,
      ) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            title,

            style: TextStyle(
              fontSize: 18,

              fontWeight: FontWeight.bold,

              color: isDark
                  ? Colors.cyanAccent
                  : Colors.blue,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            description,

            style: TextStyle(
              fontSize: 15,

              height: 1.5,

              color: isDark
                  ? Colors.white70
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}