import 'dart:async';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:vibration/vibration.dart';
import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/game_symbols.dart';
import '../widgets/loading_dialog_with_button.dart';
import 'two_player_draw_board_page.dart';

class TwoPlayerBoardPage extends StatefulWidget {
  const TwoPlayerBoardPage({super.key});

  @override
  State<TwoPlayerBoardPage> createState() => _TwoPlayerBoardPageState();
}

class _TwoPlayerBoardPageState extends State<TwoPlayerBoardPage>
    with TickerProviderStateMixin {
  late ConfettiController confettiController;
  late AnimationController glowController;
  late Animation<double> glowAnimation;
  late AnimationController lineController;
  late Animation<double> lineAnimation;
  late AnimationController timerController;

  String player1Symbol = "X";
  String player2Symbol = "O";

  String gameMessage = "";

  bool player1Turn = true;
  bool isPlayer1First = true;

  bool isDark = true; // default dark
  bool soundOn = true; // default sound on
  bool vibrationOn = true;
  bool resetPressed = false;

  List<String> board = List.filled(9, "");

  bool gameOver = false;
  int lastMove = -1;
  int pressedIndex = -1;

  List<int>? winningLine;

  int player1Score = 0;
  int player2Score = 0;

  bool timerEnabled = false; // 🔥 default OFF
  int turnTime = 30;
  int currentTime = 30;
  late double progress = 1 - timerController.value; // 🔥 reverse
  bool isTimeUp = false;
  Timer? turnTimer;
  int lastAlertSecond = -1;

  bool get isGameRunning {
    return board.any((e) => e != "") && !gameOver;
  }

  final AudioPlayer xPlayer = AudioPlayer();
  final AudioPlayer oPlayer = AudioPlayer();
  final AudioPlayer winPlayer = AudioPlayer();
  final AudioPlayer clockSoundPlayer = AudioPlayer();
  final AudioPlayer losePlayer = AudioPlayer();
  final AudioPlayer drawPlayer = AudioPlayer();

  String getTurnText() {
    if (gameOver) return "";

    return player1Turn ? "Player 1 Turn" : "Player 2 Turn";
  }

  @override
  void initState() {
    super.initState();

    timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: turnTime),
    );

    lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    lineAnimation = CurvedAnimation(
      parent: lineController,
      curve: Curves.easeInOut,
    );

    Future.delayed(Duration.zero, () {
      choosePlayerDialog();
    });

    confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));

    loadSettings();

    player1Turn = true; // first game always Player 1

    if (timerEnabled) {
      startTurnTimer();
    }

  }

  @override
  void dispose() {
    turnTimer?.cancel();
    confettiController.dispose();
    glowController.dispose();
    lineController.dispose();
    timerController.dispose();
    super.dispose();
  }

  Future loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      soundOn = prefs.getBool("sound_on") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
      timerEnabled = prefs.getBool("timer_enabled") ?? true;
    });
  }

  int getTimeLeft() {
    return (turnTime * (1 - timerController.value)).ceil();
  }

  void startTurnTimer() {
    turnTimer?.cancel();
    lastAlertSecond = -1;

    setState(() {
      currentTime = turnTime;
    });

    timerController.reset();
    timerController.forward();

    turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentTime > 0) {
        setState(() {
          currentTime--;
        });
      } else {
        timer.cancel();
        onTimeUp(); // 🔥 important
      }
    });
  }

  void onTimeUp() {
    if (gameOver) return;

    setState(() {
      gameOver = true;
      isTimeUp = true;

      /// 🔥 opponent wins
      if (player1Turn) {
        player2Score++;
        gameMessage = "PLAYER 2 WINS";
      } else {
        player1Score++;
        gameMessage = "PLAYER 1 WINS";
      }
    });

    playWinSound();
    playVibration(150);
    confettiController.play();
  }

  Future<void> playXSound() async {
    if (!soundOn) return;

    await xPlayer.stop();
    await xPlayer.play(AssetSource("audio/tum_dum.mp3"));
  }

  Future<void> playOSound() async {
    if (!soundOn) return;

    await oPlayer.stop();
    await oPlayer.play(AssetSource("audio/tedau.mp3"));
  }

  Future<void> playWinSound() async {
    if (!soundOn) return;

    await winPlayer.stop();
    await winPlayer.play(AssetSource("audio/win.mp3"));
  }

  Future<void> playDrawSound() async {
    if (!soundOn) return;

    await drawPlayer.stop();
    await drawPlayer.play(AssetSource("audio/draw.mp3"));
  }

  Future<void> playVibration(int duration) async {
    if (!vibrationOn) return;

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration);
    }
  }

  void handleTap(int index) {
    if (board[index] != "" || gameOver) return;

    setState(() {
      pressedIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      setState(() {
        pressedIndex = -1;

        if (player1Turn) {
          board[index] = player1Symbol;
        } else {
          board[index] = player2Symbol;
        }

        lastMove = index;
      });

      // SOUND
      if (board[index] == "X") {
        playXSound();
        playVibration(110);
      } else {
        playOSound();
        playVibration(110);
      }

      checkWinner();

      if (!gameOver) {
        setState(() {
          player1Turn = !player1Turn;
        });

        if (timerEnabled) {
          startTurnTimer(); // 🔥 RESET TIMER
        }
      }
    });
  }

  void choosePlayerDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Symbol",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),

      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,

            // child: Container(
            //   padding: const EdgeInsets.all(1.5), // 🔥 border thickness
            //
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(20),
            //
            //     /// 🔥 Gradient Border
            //     gradient: isDark
            //         ? const LinearGradient(colors: [Colors.blue, Colors.orange])
            //         : const LinearGradient(
            //             colors: [Colors.blue, Colors.indigo],
            //           ),
            //   ),
            //   child: Container(
            //     width: 300,
            //     height: 200,
            //     padding: const EdgeInsets.all(20),
            //
            //     decoration: BoxDecoration(
            //       color: isDark ? const Color(0xFF2B3A5A) : Colors.white,
            //       borderRadius: BorderRadius.circular(20),
            //
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black.withValues(alpha: 0.3),
            //           blurRadius: 20,
            //         ),
            //       ],
            //     ),

            child: ClipRRect(
            borderRadius: BorderRadius.circular(28),

        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),

        child: Container(
        width: 300,
        height: 200,
        padding: const EdgeInsets.all(20),


        decoration: BoxDecoration(

        /// 🔥 GLASS EFFECT
        gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,

        colors: isDark
        ? [
        Colors.white.withOpacity(0.14),
        Colors.white.withOpacity(0.05),
        ]
            : [
        Colors.white.withOpacity(0.35),
        Colors.white.withOpacity(0.12),
        ],
        ),

        borderRadius: BorderRadius.circular(28),

        border: Border.all(
        color: Colors.white.withOpacity(
        isDark ? 0.18 : 0.35,
        ),
        width: 1.5,
        ),

        boxShadow: [
        BoxShadow(
        color: Colors.transparent.withOpacity(
        isDark ? 0.10 : 0.06,
        ),
        blurRadius: 24,
        spreadRadius: 2,
        ),

        BoxShadow(
        color: Colors.black.withOpacity(
        isDark ? 0.25 : 0.08,
        ),
        offset: const Offset(0, 8),
        blurRadius: 18,
        ),
        ],
        ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Choose Player 1 Symbol", // ⭐ changed
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // X BUTTON
                        GestureDetector(
                          onTap: () {
                            playVibration(120);

                            setState(() {
                              player1Symbol = "X";
                              player2Symbol = "O"; // ⭐ important
                            });

                            Navigator.pop(context);
                          },

                          child: Container(
                            width: 90,
                            height: 90,

                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2A44)
                                  : const Color(0xFFF0F0F0),

                              borderRadius: BorderRadius.circular(18),

                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 1.5,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),

                            child: const Center(child: GameX()),
                          ),
                        ),

                        // O BUTTON
                        GestureDetector(
                          onTap: () {
                            playVibration(120);

                            setState(() {
                              player1Symbol = "O";
                              player2Symbol = "X"; // ⭐ important
                            });

                            Navigator.pop(context);
                          },

                          child: Container(
                            width: 90,
                            height: 90,

                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2A44)
                                  : const Color(0xFFF0F0F0),

                              borderRadius: BorderRadius.circular(18),

                              border: Border.all(
                                color: Colors.orangeAccent,
                                width: 1.5,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),

                            child: const Center(child: GameO()),
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
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(animation.value);

        return Transform.scale(
          scale: curvedValue,
          child: Opacity(opacity: animation.value, child: child),
        );
      },
    );
  }

  void showResult(bool? player1Win) {
    if (player1Win == true) {
      setState(() {
        gameMessage = "PLAYER 1 WINS";
      });

      playWinSound();
      playVibration(150);
      confettiController.play();
    } else if (player1Win == false) {
      setState(() {
        gameMessage = "PLAYER 2 WINS";
      });

      playWinSound();
      playVibration(150);
      confettiController.play();
    } else {
      setState(() {
        gameMessage = "DRAW";
      });

      playDrawSound();
      playVibration(150);
    }
  }

  void checkWinner() {
    setState(() {
      isTimeUp = false; // 🔥 reset
    });

    List<List<int>> wins = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combo in wins) {
      if (board[combo[0]] != "" &&
          board[combo[0]] == board[combo[1]] &&
          board[combo[1]] == board[combo[2]]) {
        setState(() {
          winningLine = combo;
          gameOver = true;
        });

        // ⭐ start winning line animation
        lineController.reset();
        lineController.forward();

        // update score
        if (board[combo[0]] == player1Symbol) {
          player1Score++;
        } else {
          player2Score++;
        }

        // delay result to allow animation
        Future.delayed(const Duration(milliseconds: 900), () {
          showResult(board[combo[0]] == player1Symbol);
        });

        return;
      }
    }

    // DRAW
    if (!board.contains("")) {
      setState(() {
        gameOver = true;
      });

      Future.delayed(const Duration(milliseconds: 400), () {
        showResult(null);
      });
    }
  }

  void resetGame() {
    playVibration(120);

    setState(() {
      isTimeUp = false;
      // 🔁 alternate first player
      isPlayer1First = !isPlayer1First;

      player1Turn = isPlayer1First;

      board = List.filled(9, "");
      winningLine = null;
      lastMove = -1;
      gameOver = false;
      gameMessage = "";
    });

    lineController.reset();

    turnTimer?.cancel();

    if (timerEnabled) {
      startTurnTimer();
    }
  }

  void showSettingsMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 20, 0),

      color: isDark ? const Color(0xFF344364) : Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      items: [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 200,
            child: StatefulBuilder(
              builder: (context, setStateMenu) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🌙 THEME
                    settingsTile(
                      icon: isDark ? Icons.dark_mode : Icons.light_mode,
                      title: "Dark Theme",
                      value: isDark,
                      onChanged: (value) async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        Navigator.pop(context);
                        playVibration(130);

                        setState(() {
                          isDark = value;
                        });

                        setStateMenu(() {});

                        prefs.setBool("theme_dark", isDark);
                      },
                    ),

                    // 🔊 SOUND
                    settingsTile(
                      icon: soundOn ? Icons.volume_up : Icons.volume_off,
                      title: "Sound",
                      value: soundOn,
                      onChanged: (value) async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();

                        playVibration(130);

                        setState(() {
                          soundOn = value;
                        });

                        setStateMenu(() {});

                        prefs.setBool("sound_on", soundOn);
                      },
                    ),

                    // 📳 VIBRATION
                    settingsTile(
                      icon: vibrationOn
                          ? Icons.vibration
                          : Icons.phonelink_erase,
                      title: "Vibration",
                      value: vibrationOn,
                      onChanged: (value) async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();

                        setState(() {
                          vibrationOn = value;
                        });

                        setStateMenu(() {});

                        prefs.setBool("vibration_on", vibrationOn);
                      },
                    ),

                    //const Divider(height: 10, thickness: 0.6),

                    // 🕒 TIMER OPTION
                    // settingsTile(
                    //   icon: timerEnabled
                    //       ? Icons.timer
                    //       : Icons.timer_off, // 🔥 clock icon
                    //   title: "Timer",
                    //   value: timerEnabled,
                    //   onChanged: (value) async {
                    //
                    //     SharedPreferences prefs =
                    //     await SharedPreferences.getInstance();
                    //
                    //     setState(() {
                    //       timerEnabled = value;
                    //     });
                    //
                    //     setStateMenu(() {}); // 🔥 update menu UI
                    //
                    //     prefs.setBool("timer_enabled", timerEnabled); // save
                    //
                    //   },
                    // ),
                    settingsTile(
                      icon: timerEnabled ? Icons.timer : Icons.timer_off,
                      title: "Timer",
                      value: timerEnabled,

                      onChanged: (value) async {

                        /// 🔥 LOCK CONDITION
                        if (isGameRunning) {
                          Fluttertoast.showToast(
                            msg: "Can't change during game",
                            toastLength: Toast.LENGTH_SHORT,
                          );
                          return;
                        }

                        SharedPreferences prefs =
                        await SharedPreferences.getInstance();

                        setState(() {
                          timerEnabled = value;
                        });

                        setStateMenu(() {});
                        prefs.setBool("timer_enabled", timerEnabled);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Widget settingsTile({
  //   required IconData icon,
  //   required String title,
  //   required bool value,
  //   //required Function(bool) onChanged,
  //   ValueChanged<bool>? onChanged,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 1),
  //     child: Row(
  //       children: [
  //         Icon(
  //           icon,
  //           size: 20,
  //           color: isGameRunning
  //               ? Colors.grey
  //               : Colors.blueAccent,
  //         ),
  //         const SizedBox(width: 8),
  //
  //         Expanded(
  //           child: Text(
  //             title,
  //             style: TextStyle(
  //               color: isGameRunning
  //                   ? Colors.grey
  //                   : (isDark ? Colors.white : Colors.black),
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ),
  //
  //         Transform.scale(
  //           scale: 0.8,
  //           child: Switch(
  //             value: value,
  //             activeThumbColor: Colors.blueAccent,
  //
  //             /// 🔥 disable UI
  //             onChanged: isGameRunning ? null : onChanged,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget settingsTile({
    required IconData icon,
    required String title,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blueAccent,
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              activeThumbColor: Colors.blueAccent,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDark ? const Color(0xFF1F2A44) : const Color(0xFFF5F5F5);
    Color boardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;
    Color cellColor = isDark
        ? const Color(0xFF1F2A44)
        : const Color(0xFFF0F0F0);
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF2B3A5A) : Color(0xFFF5F5F0),
        //backgroundColor: Colors.transparent,
        elevation: 0,

        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF111827), const Color(0xFF1F2A44)]
                  : [const Color(0xFFF5F5F0), const Color(0xFFF5F5F0)],
            ),
          ),
        ),

        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: textColor),
        //   onPressed: () {
        //     playVibration(120);
        //     Navigator.pop(context);
        //   },
        // ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Tooltip(
            message: "Back",
            child: GestureDetector(
              onTap: () async {
                await showExitDialog();
                // playVibration(120);
                // Navigator.pop(context);
              },
              child: build3DIconButton(Icons.arrow_back, isDark),
            ),
          ),
        ),

        title: GestureDetector(
          
          child: Text(
            "Play With Friends", // changed
            style: TextStyle(
              color: isDark ? Colors.cyanAccent : Colors.blue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        centerTitle: true,

        actions: [
          /// 🔹 DRAW BUTTON
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: "Draw Board", // 🔥 long press tooltip
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DrawBoardPage()),
                  );
                },
                child: build3DIconButton(Icons.gesture, isDark),
              ),
            ),
          ),

          /// 🔹 SETTINGS BUTTON
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: "Settings", // 🔥 tooltip
              child: GestureDetector(
                onTap: () {
                  showSettingsMenu();
                },
                child: build3DIconButton(Icons.settings, isDark),
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // BACKGROUND GRADIENT
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Color(0xFF1F2A44), Color(0xFF111827), Color(0xFF0B132B)]
                    : [Color(0xFFEAEAEA), Color(0xFFEEF8F7), Color(0xFFEAEAEA)],
              ),
            ),
          ),

          // CONFETTI
          ConfettiWidget(
            confettiController: confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // SCORE SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    scoreBox("Player 1", player1Symbol, boardColor, textColor),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: boardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$player1Score - $player2Score",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    scoreBox("Player 2", player2Symbol, boardColor, textColor),
                  ],
                ),

                const SizedBox(height: 20),

                if (timerEnabled && !gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "$currentTime s",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentTime <= 5 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),

                if (timerEnabled && gameOver && isTimeUp)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Time's Up ⚠️",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),

                const SizedBox(height: 00),

                if (!gameOver)
                  Text(
                    player1Turn ? "Player 1 Turn" : "Player 2 Turn",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 20),

                if (gameMessage != "")
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween<double>(begin: 0, end: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, double value, child) {
                      Color cardColor = isDark
                          ? const Color(0xFF2B3A5A)
                          : Colors.white;

                      List<Color> gradientColors = gameMessage.contains("WIN")
                          ? [Colors.greenAccent, Colors.blueAccent]
                          : [Colors.orangeAccent, Colors.yellow];

                      return AnimatedBuilder(
                        animation: glowAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: value, // fade

                            child: Transform.translate(
                              offset: Offset(0, -40 * (1 - value)),

                              // slide from top
                              child: Transform.scale(
                                scale: 0.95 + (0.05 * value), // slight pop

                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(2),

                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(16),

                                    boxShadow: [
                                      BoxShadow(
                                        color: gradientColors.first.withValues(
                                          alpha: glowAnimation.value,
                                        ),
                                        blurRadius: 12 * glowAnimation.value,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),

                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),

                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // OUTLINE TEXT
                                        ShaderMask(
                                          shaderCallback: (rect) {
                                            return LinearGradient(
                                              colors: gradientColors,
                                            ).createShader(rect);
                                          },
                                          child: Text(
                                            gameMessage,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = 2.2
                                                ..color = Colors.white,
                                            ),
                                          ),
                                        ),

                                        // MAIN TEXT
                                        Text(
                                          gameMessage,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: gradientColors.first
                                                    .withValues(
                                                      alpha:
                                                          glowAnimation.value,
                                                    ),
                                                blurRadius:
                                                    10 * glowAnimation.value,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                const SizedBox(height: 00),

                // GAME BOARD (CENTERED)
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 280,
                      height: 280,
                      padding: const EdgeInsets.all(1.5),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),

                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.blueAccent,
                                  Colors.purpleAccent,
                                  Colors.blueAccent,
                                ]
                              : [
                                  Colors.orangeAccent,
                                  Colors.pinkAccent,
                                  Colors.orangeAccent,
                                ],
                        ),

                        boxShadow: [
                          // outer glow
                          BoxShadow(
                            color:
                                (isDark
                                        ? Colors.blueAccent
                                        : Colors.orangeAccent)
                                    .withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),

                          // 3D depth
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            offset: const Offset(4, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),

                      child: Container(
                        padding: const EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: boardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Stack(
                          children: [
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 9,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                  ),

                              itemBuilder: (context, index) {
                                bool highlight = index == lastMove;
                                bool win =
                                    winningLine != null &&
                                    winningLine!.contains(index);

                                return GestureDetector(
                                  onTap: () => handleTap(index),

                                  child: AnimatedScale(
                                    scale: pressedIndex == index ? 0.92 : 1,
                                    duration: const Duration(milliseconds: 120),

                                    child: Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        borderRadius: BorderRadius.circular(12),

                                        border: board[index] != ""
                                            ? Border.all(
                                                color: isDark
                                                    ? Color(0xFF47798A)
                                                    : Color(0xFF9ED3E8),
                                                width: 1,
                                              )
                                            : null,

                                        boxShadow: [
                                          if (highlight)
                                            const BoxShadow(
                                              color: Colors.blueAccent,
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),

                                          if (win)
                                            const BoxShadow(
                                              color: Colors.green,
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                        ],
                                      ),

                                      child: Center(
                                        child: board[index] == "X"
                                            ? const GameX()
                                            : board[index] == "O"
                                            ? const GameO()
                                            : const SizedBox(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // WINNING LINE DRAW
                            if (winningLine != null)
                              AnimatedBuilder(
                                animation: lineAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: const Size(260, 260),
                                    painter: WinLinePainter(
                                      winningLine!,
                                      lineAnimation.value,
                                      3,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        neonButton(
                          text: "Home",
                          icon: Icons.home,
                          onTap: () {
                            playVibration(120);
                            Navigator.pop(context);
                          },
                        ),

                        neonButton(
                          text: "Replay",
                          icon: Icons.refresh,
                          onTap: () {
                            //playXSound();   // replay sound
                            playVibration(120);
                            resetGame();
                          },
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 60),

                if (!gameOver)
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        resetPressed = true;
                      });
                    },

                    onTapUp: (_) {
                      setState(() {
                        resetPressed = false;
                      });
                      resetGame();
                    },

                    onTapCancel: () {
                      setState(() {
                        resetPressed = false;
                      });
                    },

                    child: AnimatedScale(
                      scale: resetPressed ? 0.92 : 1,
                      duration: const Duration(milliseconds: 120),

                      child: Container(
                        width: double.infinity,
                        height: 50,
                        padding: const EdgeInsets.all(1),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),

                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                              Colors.pinkAccent,
                              Colors.orangeAccent,
                              Colors.pinkAccent,

                                  ]
                                : [
                              Colors.blueAccent,
                              Colors.cyanAccent,
                              Colors.blueAccent,
                                  ],
                          ),
                        ),

                        child: Container(
                          decoration: BoxDecoration(
                            color: boardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Center(
                            child: Text(
                              "Reset Game",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // CONFETTI (FRONT LAYER)
          IgnorePointer(
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  } // end widget build

  Future<void> showExitDialog() async {

    await showAppDialog(
      context: context,

      title: "EXIT MATCH",

      message:
      "Exit and end the match?",

      positiveText: "EXIT",
      negativeText: "CANCEL",

      barrierDismissible: false,

      onNegative: () {
        // 🔥 nothing needed
      },

      onPositive: () async {

        playVibration(120);
        Navigator.pop(context);
      },
    );
  }

  Widget neonButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    List<Color> colors = isDark
        ? [Colors.blueAccent, Colors.purpleAccent]
        : [Colors.orangeAccent, Colors.pinkAccent];

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),

        child: AnimatedBuilder(
          animation: glowController,

          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(1),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: colors),

                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: glowAnimation.value),
                    blurRadius: 20 * glowAnimation.value,
                  ),
                ],
              ),

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B3A5A) : Colors.white,

                  borderRadius: BorderRadius.circular(14),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: colors.first),

                    const SizedBox(width: 6),

                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
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

  Widget scoreBox(String player, String symbol, Color bg, Color textColor) {


    Color borderColor = symbol == "X" ? Colors.blueAccent : Colors.orangeAccent;

    bool isPlayer1 = player == "Player 1";

    bool isActive =
        !gameOver &&
        ((player1Turn && isPlayer1) || (!player1Turn && !isPlayer1));

    List<Color> gradientColors = symbol == "X"
        ? [Colors.blueAccent, Colors.cyanAccent]
        : [Colors.orangeAccent, Colors.deepOrange];

    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        double glowValue = isActive ? glowAnimation.value : 0;

        return Stack(
          children: [
            /// 🔥 MAIN BOX
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: gradientColors.first.withValues(
                            alpha: glowValue,
                          ),
                          blurRadius: 16 * glowValue,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        colors: gradientColors,
                      ).createShader(rect);
                    },
                    child: Text(
                      symbol,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 0),

                  Text(
                    player,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔥 TIMER BORDER (ONLY ACTIVE PLAYER)

            if (isActive && timerEnabled)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: timerController,
                  builder: (context, child) {
                    int timeLeft = getTimeLeft();

                    if (timeLeft <= 5 && timeLeft > 0) {
                      if (timeLeft != lastAlertSecond) {
                        lastAlertSecond = timeLeft;

                        /// 🔊 SOUND
                        if (soundOn) {
                          clockSoundPlayer.stop(); // 🔥 avoid overlap
                          clockSoundPlayer.play(AssetSource("audio/tick.mp3"));
                        }

                        /// 📳 VIBRATION
                        if (vibrationOn) {
                          // playVibration(120);
                          HapticFeedback.mediumImpact();
                        }
                      }
                    }

                    return CustomPaint(
                      painter: TimerBorderPainter(
                        1 - timerController.value, // 🔥 smooth reverse
                        borderColor,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class TimerBorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  TimerBorderPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));

    final metric = path.computeMetrics().first;

    final extractPath = metric.extractPath(0, metric.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant TimerBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class GameX extends StatelessWidget {
  const GameX({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: XPainter()),
    );
  }
}

Widget build3DIconButton(IconData icon, bool isDark) {
  return Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,

    // 🔥 FIX
    padding: const EdgeInsets.all(1.5),

    // 🔥 border thickness
    decoration: BoxDecoration(
      shape: BoxShape.circle,

      /// 🔥 Gradient Border
      gradient: isDark
          ? const LinearGradient(colors: [Colors.blueAccent, Colors.cyanAccent])
          : const LinearGradient(colors: [Colors.blue, Colors.indigo]),

      /// 🔥 Glow
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.4),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    ),

    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF3F8),
        shape: BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.05 : 0.9),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
        ],
      ),

      child: Icon(
        icon,
        color: isDark ? Colors.cyanAccent : Colors.blue,
        size: 20,
      ),
    ),
  );
}
