import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tic_tac_toe/screens/info_page.dart';
import 'screens/how_to_play_page.dart';
import 'screens/play_solo_board_page.dart';
import 'package:vibration/vibration.dart';
import 'screens/two_player_board_page.dart';
import 'screens/play_online_start_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const TicTacToeApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  isDark = prefs.getBool("theme_dark") ?? true;

  runApp(const TicTacToeApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool isDark = true;

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Tic Tac Toe",

      //themeMode: ThemeMode.system,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      // LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),

      // DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),

      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    //loadTheme();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    animation = Tween<double>(
      begin: 0.85,
      end: 1.1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    controller.repeat(reverse: true);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   checkUser();
    // });

    _appLinks = AppLinks();
    initDeepLinks();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Future<void> loadTheme() async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   if (!mounted) return;
  //
  //   setState(() {
  //     isDark = prefs.getBool("theme_dark") ?? true;
  //   });
  // }
  @override
  Widget build(BuildContext context) {
    // final isDark = Theme
    //     .of(context)
    //     .brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FB),

      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated XO Logo
                    // AnimatedBuilder(
                    //   animation: controller,
                    //   builder: (context, child) {
                    //     final glow = (controller.value * 12) + 6;
                    //
                    //     return Container(
                    //       height: 100,
                    //       width: 100,
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(24),
                    //         color: Colors.white.withValues(alpha: 0.08),
                    //         boxShadow: [
                    //           // BLUE GLOW
                    //           BoxShadow(
                    //             color: Colors.blue.withValues(alpha: 0.7),
                    //             blurRadius: glow,
                    //             spreadRadius: 3,
                    //           ),
                    //
                    //           // PINK GLOW
                    //           BoxShadow(
                    //             color: Colors.pink.withValues(alpha: 0.6),
                    //             blurRadius: glow,
                    //             spreadRadius: 1,
                    //           ),
                    //         ],
                    //       ),
                    //       child: const Center(
                    //         child: Text(
                    //           "XO",
                    //           style: TextStyle(
                    //             fontSize: 38,
                    //             fontWeight: FontWeight.bold,
                    //             letterSpacing: 2,
                    //             color: Colors.white,
                    //           ),
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),



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

                    // TITLE
                    // Text(
                    //   "Tic - Tac - Toe",
                    //   style: TextStyle(
                    //     fontSize: 26,
                    //     fontWeight: FontWeight.bold,
                    //     color: isDark ? Colors.white : Colors.black87,
                    //   ),
                    // ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),

                        boxShadow: [

                          /// 🔥 BACK GLOW
                          BoxShadow(
                            color: (isDark
                                ? Colors.blue
                                : Colors.cyanAccent)
                                .withValues(alpha: 0.5),

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

                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

// SUBTITLE
                    Text(
                      "Powered by SP Tech Studios",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                        color: isDark
                            ? Colors.white60
                            : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 35),

                    // PLAY SOLO
                    buildButton(
                      context,
                      Icons.smart_toy,
                      "Play Solo",
                      "Play against AI",
                    ),

                    const SizedBox(height: 15),

                    // PLAY WITH FRIEND
                    buildButton(
                      context,
                      Icons.group,
                      "Play with Friend",
                      "Two players on same device",
                    ),

                    const SizedBox(height: 15),

                    // PLAY ONLINE
                    buildButton(
                      context,
                      Icons.public,
                      "Play Online",
                      "Play with friends online",
                    ),

                    // ElevatedButton(
                    //   onPressed: () async {
                    //     Vibration.vibrate(duration: 200);
                    //   },
                    //   child: const Text("Test Vibration"),
                    // ),/// vibration test
                    // const SizedBox(height: 30),
                    //
                    // // HOW TO PLAY
                    // TextButton(
                    //   onPressed: () {
                    //     //Vibration.vibrate(duration: 150);
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const HowToPlayPage(),
                    //       ),
                    //     );
                    //   },
                    //   child: Text(
                    //     "How to Play ?",
                    //     style: TextStyle(
                    //       fontSize: 16,
                    //       color: isDark ? Colors.white70 : Colors.blue,
                    //     ),
                    //   ),
                    // ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        /// 🔹 HOW TO PLAY
                        TextButton(
                          onPressed: () {

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) =>
                                const HowToPlayPage(),
                              ),
                            );
                          },

                          child: Text(
                            "Guide",

                            style: TextStyle(
                              fontSize: 16,

                              color: isDark
                                  ? Colors.white70
                                  : Colors.blue,
                            ),
                          ),
                        ),

                        /// 🔥 DIVIDER
                        Container(
                          width: 1,
                          height: 18,

                          color: isDark
                              ? Colors.white24
                              : Colors.black26,
                        ),

                        /// 🔹 About
                        TextButton(
                          onPressed: () {

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) =>
                                const InfoPage(),
                              ),
                            );
                          },

                          child: Text(
                            "Info",

                            style: TextStyle(
                              fontSize: 16,

                              color: isDark
                                  ? Colors.white70
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    // final isDark = Theme
    //     .of(context)
    //     .brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (title == "Play Solo") {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => const GameBoardPage()),
          );
        }

        if (title == "Play with Friend") {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => const TwoPlayerBoardPage()),
          );
        }

        if (title == "Play Online") {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const PlayOnlineStartPage(),
            ),
          );
        }
      },

      child: Container(
        padding: const EdgeInsets.all(1.5), // 🔥 border thickness

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),

          /// 🔥 Gradient Border
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.cyanAccent],
          ),

          /// 🔥 Glow
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha:0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),

        child: Container(
          padding: const EdgeInsets.all(18),

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

          child: Row(
            children: [
              Icon(
                icon,
                size: 30,
                color: isDark ? Colors.cyanAccent : Colors.blue,
              ),

              const SizedBox(width: 15),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.cyanAccent : Colors.blue,
                    ),
                  ),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.cyanAccent : Colors.blue,
                    ),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  bool _handledInitialLink = false; // 🔥 global variable

  void initDeepLinks() async {
    // 🔹 COLD START (App closed)
    try {
      final uri = await _appLinks.getInitialLink();

      print("🔥 INITIAL LINK: $uri");

      if (!_handledInitialLink && uri != null) {
        _handledInitialLink = true;
        handleIncomingLink(uri);
      }
    } catch (e) {
      print("🔥 INITIAL ERROR: $e");
    }

    // 🔹 WARM START (App running / background)
    _appLinks.uriLinkStream.listen(
      (uri) {
        print("🔥 STREAM LINK: $uri");

        if (uri != null) {
          handleIncomingLink(uri);
        }
      },
      onError: (err) {
        print("🔥 LINK ERROR: $err");
      },
    );
  }

  void handleIncomingLink(Uri uri) {
    print("🔥 FULL URI: $uri");
    print("🔥 HOST: ${uri.host}");
    print("🔥 PATH: ${uri.path}");

    if (uri.host == "join" || uri.path.contains("join")) {
      String? code = uri.queryParameters['code'];

      if (code != null && code.isNotEmpty) {
        print("🔥 Deep link received: $code");

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
