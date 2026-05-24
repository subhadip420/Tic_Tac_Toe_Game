import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';
import 'package:tic_tac_toe/screens/info_page.dart';
import 'screens/how_to_play_page.dart';
import 'screens/play_solo_board_page.dart';

import 'screens/two_player_board_page.dart';
import 'screens/play_online_start_page.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
/// APP START
void main() async {
  /// REQUIRED FOR ASYNC BEFORE runApp()
  WidgetsFlutterBinding.ensureInitialized();

  /// FIREBASE INITIALIZE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // final prefs = await SharedPreferences.getInstance();
  //
  // isDark = prefs.getBool("theme_dark") ?? true;

  /// START APP
  runApp(const TicTacToeApp());
}

/// GLOBAL NAVIGATOR KEY
/// USED FOR NAVIGATION WITHOUT CONTEXT
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//bool isDark = true;


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
      //themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

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
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    //loadTheme();
    // controller = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 2),
    // );
    //
    // animation = Tween<double>(
    //   begin: 0.85,
    //   end: 1.1,
    // ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    //
    // controller.repeat(reverse: true);

    /// START LISTENING LINKS
    _appLinks = AppLinks();
    initDeepLinks();
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
                      "Fast • Fun • Multiplayer",
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
                    buildButton(
                      context,
                      Icons.group,
                      "Play with Friend",
                      "Two players on same device",
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

        /// TWO PLAYER PAGE
        if (title == "Play with Friend") {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => const TwoPlayerBoardPage()),
          );
        }

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
          padding: const EdgeInsets.all(18),

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
                size: 30,
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

  /// PREVENT MULTIPLE INITIAL LINK HANDLING
  bool _handledInitialLink = false;

  /// INITIALIZE DEEP LINKS
  void initDeepLinks() async {
    /// COLD START
    /// APP CLOSED -> OPEN FROM LINK
    try {
      final uri = await _appLinks.getInitialLink();

      print(" INITIAL LINK: $uri");

      if (!_handledInitialLink && uri != null) {
        _handledInitialLink = true;
        handleIncomingLink(uri);
      }
    } catch (e) {
      print(" INITIAL ERROR: $e");
    }

    /// WARM START
    /// APP RUNNING / BACKGROUND
    _appLinks.uriLinkStream.listen(
      (uri) {
        print(" STREAM LINK: $uri");

        //if (uri != null) {
        handleIncomingLink(uri);
        //}
      },
      onError: (err) {
        print(" LINK ERROR: $err");
      },
    );
  }


  /// HANDLE RECEIVED DEEP LINK
  void handleIncomingLink(Uri uri) {
    print(" FULL URI: $uri");
    print(" HOST: ${uri.host}");
    print(" PATH: ${uri.path}");


    /// CHECK JOIN ROOM LINK
    if (uri.host == "join" || uri.path.contains("join")) {
      /// GET ROOM CODE
      String? code = uri.queryParameters['code'];

      /// VALID ROOM CODE
      if (code != null && code.isNotEmpty) {
        print(" Deep link received: $code");

        /// SMALL DELAY FOR SAFE NAVIGATION
        Future.delayed(const Duration(milliseconds: 200), () {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => PlayOnlineStartPage(initialCode: code),
              settings: const RouteSettings(name: "/playOnline"),
            ),
            (route) => false,
          );
        });
      }
    }
  }
}
