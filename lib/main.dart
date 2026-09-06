import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:lottie/lottie.dart';
import 'package:tic_tac_toe/screens/pro_match_page.dart';
import 'package:tic_tac_toe/screens/info_page.dart';
import 'screens/how_to_play_page.dart';
import 'screens/play_solo_board_page.dart';

import 'screens/two_player_board_page.dart';
import 'screens/play_online_start_page.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'package:flutter/foundation.dart';
//import 'package:app_links/app_links.dart';

/// APP START
void main() async {
  /// REQUIRED FOR ASYNC BEFORE runApp()
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  /// FIREBASE INITIALIZE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// No screen rotation allow
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  /// START APP
  runApp(const TicTacToeApp());
}

/// GLOBAL NAVIGATOR KEY
/// USED FOR NAVIGATION WITHOUT CONTEXT
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// MAIN APP
class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Tic Tac Toe",

      /// SYSTEM THEME AUTO DETECT
      themeMode: ThemeMode.system,

      /// LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),

      /// DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),

      /// FIRST SCREEN
      home: const HomePage(),
    );
  }
}

/// HOME PAGE
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  /// LOGO ANIMATION CONTROLLER
  late AnimationController controller;

  /// SCALE ANIMATION
  late Animation<double> animation;

  /// DEEP LINK INSTANCE
  //late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();

    /// START LISTENING LINKS
    // _appLinks = AppLinks();
    // initDeepLinks();
  }

  @override
  void dispose() {
    /// DISPOSE ANIMATION
    controller.dispose();
    super.dispose();
  }

  /// HOME PAGE UI
  @override
  Widget build(BuildContext context) {
    /// CURRENT THEME MODE
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      /// PAGE BACKGROUND
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FB),

      /// KEYBOARD SAFE RESIZE
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: ConstrainedBox(
              /// FULL SCREEN HEIGHT
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// ANIMATION
                    SizedBox(
                      height: 150,
                      width: 150,

                      child: Lottie.asset(
                        isDark
                            ? "assets/lottie/tic_tac_toe_dark.json"
                            : "assets/lottie/tic_tac_toe_light.json",

                        height: 150,
                        width: 150,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// APP TITLE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),

                        boxShadow: [
                          /// BACK GLOW
                          BoxShadow(
                            color: (isDark ? Colors.blue : Colors.cyanAccent)
                                .withValues(alpha: 0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),

                      child: Text(
                        "Tic - Tac - Toe",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    /// SUBTITLE
                    Text(
                      "Train Your Brain",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 35),

                    /// PLAY SOLO BUTTON
                    buildButton(
                      context,
                      Icons.smart_toy,
                      "Play Solo",
                      "Play against AI",
                    ),

                    const SizedBox(height: 15),

                    /// PLAY WITH FRIEND
                    // buildButton(
                    //   context,
                    //   Icons.group,
                    //   "Play with Friend",
                    //   "Two players on same device",
                    // ),

                    /// 2. TWO HALF-WIDTH BUTTONS (Row)
                    Row(
                      children: [
                        /// LEFT CARD: PLAY WITH FRIEND
                        Expanded(
                          child: buildSmallButton(
                            context,
                            Icons.group,
                            "Local Match", // Naam thoda chota kiya taaki fit ho
                                () {
                              navigatorKey.currentState?.push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const TwoPlayerBoardPage()),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 15), // Beech ka gap

                        /// RIGHT CARD: NEW OPTION
                        Expanded(
                          child: buildSmallButton(
                            context,
                            Icons.psychology_rounded, // Aap iska icon change kar sakte hain
                            "Pro Match", // Iska naam apne hisaab se rakh lein
                                () {
                                  navigatorKey.currentState?.push(
                                    MaterialPageRoute(
                                      builder: (context) => const InfinityModePage(),
                                    ),
                                  );
                              print("New Card Clicked!");
                            },
                            showBadge: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    /// PLAY ONLINE
                    buildButton(
                      context,
                      Icons.public,
                      "Play Online",
                      "Play with friends online",
                    ),

                    const SizedBox(height: 30),

                    /// BOTTOM ACTION BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        /// GUIDE
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) => const HowToPlayPage(),
                              ),
                            );
                          },

                          icon: Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.blue,
                          ),

                          label: Text(
                            "Guide",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.blue,
                            ),
                          ),
                        ),

                        /// DIVIDER
                        Container(
                          width: 1,
                          height: 18,

                          color: isDark ? Colors.white24 : Colors.black26,
                        ),

                        /// INFO BUTTON
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) => const InfoPage(),
                              ),
                            );
                          },

                          icon: Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.blue,
                          ),

                          label: Text(
                            "Info",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.blue,
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
      ),
    );
  }

  /// HOME BUTTON
  Widget buildButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    /// CURRENT THEME
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      /// BUTTON CLICK
      onTap: () {
        /// PLAY SOLO PAGE
        if (title == "Play Solo") {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => const GameBoardPage()),
          );
        }

        // /// TWO PLAYER PAGE
        // if (title == "Play with Friend") {
        //   navigatorKey.currentState?.push(
        //     MaterialPageRoute(builder: (context) => const TwoPlayerBoardPage()),
        //   );
        // }

        /// ONLINE PAGE
        if (title == "Play Online") {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const PlayOnlineStartPage(),
            ),
          );
        }
      },

      child: Container(
        /// OUTER BORDER PADDING
        padding: const EdgeInsets.all(1.5),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),

          ///  Gradient Border
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.cyanAccent],
          ),

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
          /// INNER PADDING
          padding: const EdgeInsets.fromLTRB(20,10,0,10),

          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),

            /// CARD SHADOW
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.black12,
                blurRadius: 8,
              ),
            ],
          ),

          child: Row(
            children: [
              /// BUTTON ICON
              Icon(
                icon,
                size: 25,
                color: isDark ? Colors.cyanAccent : Colors.blue,
              ),

              const SizedBox(width: 15),

              /// TITLE + SUBTITLE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    /// BUTTON TITLE
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.cyanAccent : Colors.blue,
                    ),
                  ),

                  /// BUTTON SUBTITLE
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.cyanAccent : Colors.blue,
                    ),
                  ),
                ],
              ),

              /// KEYBOARD SPACE
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  /// NEW: HALF-WIDTH SQUARE BUTTON (Card View with Optional Badge)
  Widget buildSmallButton(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool showBadge = false, /// Naya parameter badge ke liye
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none, /// Badge ko border ke thoda bahar nikalne ke liye
        children: [
          /// MAIN BUTTON CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.cyanAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 25,
                    color: isDark ? Colors.cyanAccent : Colors.blue,
                  ),
                  const SizedBox(height: 0),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.cyanAccent : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 'NEW' BADGE (Condition: Sirf tab dikhega jab showBadge true ho)
          if (showBadge)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Text(
                  "NEW",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}//end HomePageState classs
