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
import '../widgets/build_circle_icon_button.dart';
import '../widgets/build_icon_text_button.dart';
import '../widgets/glass_settings_menu.dart';
import '../widgets/loading_dialog_with_button.dart';
import '../widgets/neon_glowing_button.dart';
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
  bool hasGameStarted = false;
  bool get isGameRunning {
    return board.any((e) => e != "") && !gameOver;
  }

  int boardSize = 3;

  final List<int> availableBoardSizes = [3, 4, 5, 6, 7, 8, 9];

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

    // if (timerEnabled) {
    //   startTurnTimer();
    // }
  }

  @override
  void dispose() {
    turnTimer?.cancel();
    confettiController.dispose();
    glowController.dispose();
    lineController.dispose();
    timerController.dispose();
    stopTickingSound();
    super.dispose();
  }

  Future loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedSize =
        prefs.getInt("board_size") ?? 3;

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      soundOn = prefs.getBool("sound_on") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
      timerEnabled = prefs.getBool("timer_enabled") ?? true;
      boardSize = savedSize;

      board = List.filled(boardSize * boardSize, "",);
    });
  }

  void stopTickingSound() {
    clockSoundPlayer.stop();

    lastAlertSecond = -1;
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
    stopTickingSound(); // 🔥 ADD
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

    /// 🔥 FIRST MOVE
    if (!hasGameStarted) {

      hasGameStarted = true;

      if (timerEnabled) {
        startTurnTimer();
      }
    }

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
        stopTickingSound();
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
                              Colors.white.withValues(alpha: 0.14),
                              Colors.white.withValues(alpha: 0.05),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.35),
                              Colors.white.withValues(alpha: 0.12),
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
                        color: Colors.transparent.withValues(
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

  ///old checkWinner
  // void checkWinner() {
  //   setState(() {
  //     isTimeUp = false; // 🔥 reset
  //   });
  //
  //   List<List<int>> wins = [
  //     [0, 1, 2],
  //     [3, 4, 5],
  //     [6, 7, 8],
  //     [0, 3, 6],
  //     [1, 4, 7],
  //     [2, 5, 8],
  //     [0, 4, 8],
  //     [2, 4, 6],
  //   ];
  //
  //   for (var combo in wins) {
  //     if (board[combo[0]] != "" &&
  //         board[combo[0]] == board[combo[1]] &&
  //         board[combo[1]] == board[combo[2]]) {
  //       stopTickingSound();
  //       setState(() {
  //         winningLine = combo;
  //         gameOver = true;
  //       });
  //
  //       // ⭐ start winning line animation
  //       lineController.reset();
  //       lineController.forward();
  //
  //       // update score
  //       if (board[combo[0]] == player1Symbol) {
  //         player1Score++;
  //       } else {
  //         player2Score++;
  //       }
  //
  //       // delay result to allow animation
  //       Future.delayed(const Duration(milliseconds: 900), () {
  //         showResult(board[combo[0]] == player1Symbol);
  //       });
  //
  //       return;
  //     }
  //   }
  //
  //   // DRAW
  //   if (!board.contains("")) {
  //     stopTickingSound();
  //     setState(() {
  //       gameOver = true;
  //     });
  //
  //     Future.delayed(const Duration(milliseconds: 400), () {
  //       showResult(null);
  //     });
  //   }
  // }

  ///new checkWinner
  void checkWinner() {
    int winLength;

    if (boardSize <= 4) {
      winLength = boardSize;
    } else if (boardSize <= 6) {
      winLength = 4;
    } else {
      winLength = 5;
    }

    //String currentPlayer = player1Turn ? "X" : "O";
    String currentPlayer =
    player1Turn
        ? player1Symbol
        : player2Symbol;
    /// 🔥 CHECK ALL CELLS
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        int index = row * boardSize + col;

        if (board[index] != currentPlayer) {
          continue;
        }

        /// ✅ HORIZONTAL
        if (_checkDirection(row, col, 0, 1, currentPlayer, winLength)) {
          return;
        }

        /// ✅ VERTICAL
        if (_checkDirection(row, col, 1, 0, currentPlayer, winLength)) {
          return;
        }

        /// ✅ DIAGONAL ↘
        if (_checkDirection(row, col, 1, 1, currentPlayer, winLength)) {
          return;
        }

        /// ✅ DIAGONAL ↙
        if (_checkDirection(row, col, 1, -1, currentPlayer, winLength)) {
          return;
        }
      }
    }

    /// 🔥 DRAW
    // if (!board.contains("")) {
    //
    //   stopTickingSound();
    //
    //   setState(() {
    //
    //     gameOver = true;
    //
    //     gameMessage = "It's a Draw!";
    //   });
    // }
    if (!board.contains("")) {
      stopTickingSound();

      setState(() {
        gameOver = true;
      });

      Future.delayed(const Duration(milliseconds: 400), () {
        showResult(null);
      });
    }
  }

  bool _checkDirection(

    int row,
    int col,

    int rowDir,
    int colDir,

    String player,

    int winLength,
  ) {
    if (gameOver) return true;
    List<int> matched = [];

    for (int i = 0; i < winLength; i++) {
      int newRow = row + rowDir * i;

      int newCol = col + colDir * i;

      /// 🔥 OUTSIDE BOARD
      if (newRow < 0 ||
          newRow >= boardSize ||
          newCol < 0 ||
          newCol >= boardSize) {
        return false;
      }

      int index = newRow * boardSize + newCol;

      if (board[index] != player) {
        return false;
      }

      matched.add(index);
    }

    /// 🔥 WIN FOUND
    stopTickingSound();

    setState(() {
      //winningLine = matched;

      gameOver = true;
      winningLine = List<int>.from(matched);
    });

    /// 🔥 WIN LINE ANIMATION
    lineController.reset();

    lineController.forward();

    /// 🔥 SCORE
    if (player == player1Symbol) {
      player1Score++;
    } else {
      player2Score++;
    }

    /// 🔥 RESULT MESSAGE
    Future.delayed(const Duration(milliseconds: 900), () {
      showResult(player == player1Symbol);
    });

    return true;
  }

  Future<void> showResetGameDialog() async {
    await showAppDialog(
      context: context,

      title: "RESET GAME",

      message: "Are you sure you want to reset the current match?",

      positiveText: "RESET",

      negativeText: "CANCEL",

      barrierDismissible: true,
      canPop: true,
      onPositive: () async {
        resetGame();
      },

      onNegative: () {
        // dialog auto close
      },
    );
  }

  void resetGame() {
    playVibration(120);
    stopTickingSound();
    setState(() {
      hasGameStarted = false;
      timerController.reset();
      isTimeUp = false;
      currentTime = 30;
      // 🔁 alternate first player
      isPlayer1First = !isPlayer1First;

      player1Turn = isPlayer1First;

      //board = List.filled(9, "");
      board = List.filled(boardSize * boardSize, "");
      winningLine = null;
      lastMove = -1;
      gameOver = false;
      gameMessage = "";
    });

    lineController.reset();

    turnTimer?.cancel();

    // if (timerEnabled) {
    //   startTurnTimer();
    // }
  }

  // void showSettingsMenu() {
  //   showMenu(
  //     context: context,
  //     position: const RelativeRect.fromLTRB(1000, 80, 20, 0),
  //
  //     color: isDark ? const Color(0xFF344364) : Colors.white,
  //
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  //
  //     items: [
  //       PopupMenuItem(
  //         enabled: false,
  //         child: SizedBox(
  //           width: 200,
  //           child: StatefulBuilder(
  //             builder: (context, setStateMenu) {
  //               return Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   // 🌙 THEME
  //                   settingsTile(
  //                     icon: isDark ? Icons.dark_mode : Icons.light_mode,
  //                     title: "Dark Theme",
  //                     value: isDark,
  //                     onChanged: (value) async {
  //                       SharedPreferences prefs =
  //                           await SharedPreferences.getInstance();
  //                       Navigator.pop(context);
  //                       playVibration(130);
  //
  //                       setState(() {
  //                         isDark = value;
  //                       });
  //
  //                       setStateMenu(() {});
  //
  //                       prefs.setBool("theme_dark", isDark);
  //                     },
  //                   ),
  //
  //                   // 🔊 SOUND
  //                   settingsTile(
  //                     icon: soundOn ? Icons.volume_up : Icons.volume_off,
  //                     title: "Sound",
  //                     value: soundOn,
  //                     onChanged: (value) async {
  //                       SharedPreferences prefs =
  //                           await SharedPreferences.getInstance();
  //
  //                       playVibration(130);
  //
  //                       setState(() {
  //                         soundOn = value;
  //                       });
  //
  //                       setStateMenu(() {});
  //
  //                       prefs.setBool("sound_on", soundOn);
  //                     },
  //                   ),
  //
  //                   // 📳 VIBRATION
  //                   settingsTile(
  //                     icon: vibrationOn
  //                         ? Icons.vibration
  //                         : Icons.phonelink_erase,
  //                     title: "Vibration",
  //                     value: vibrationOn,
  //                     onChanged: (value) async {
  //                       SharedPreferences prefs =
  //                           await SharedPreferences.getInstance();
  //
  //                       setState(() {
  //                         vibrationOn = value;
  //                       });
  //
  //                       setStateMenu(() {});
  //
  //                       prefs.setBool("vibration_on", vibrationOn);
  //                     },
  //                   ),
  //
  //                   //const Divider(height: 10, thickness: 0.6),
  //
  //                   // 🕒 TIMER OPTION
  //                   // settingsTile(
  //                   //   icon: timerEnabled
  //                   //       ? Icons.timer
  //                   //       : Icons.timer_off, // 🔥 clock icon
  //                   //   title: "Timer",
  //                   //   value: timerEnabled,
  //                   //   onChanged: (value) async {
  //                   //
  //                   //     SharedPreferences prefs =
  //                   //     await SharedPreferences.getInstance();
  //                   //
  //                   //     setState(() {
  //                   //       timerEnabled = value;
  //                   //     });
  //                   //
  //                   //     setStateMenu(() {}); // 🔥 update menu UI
  //                   //
  //                   //     prefs.setBool("timer_enabled", timerEnabled); // save
  //                   //
  //                   //   },
  //                   // ),
  //                   settingsTile(
  //                     icon: timerEnabled ? Icons.timer : Icons.timer_off,
  //                     title: "Timer",
  //                     value: timerEnabled,
  //
  //                     onChanged: (value) async {
  //                       /// 🔥 LOCK CONDITION
  //                       if (isGameRunning) {
  //                         Fluttertoast.showToast(
  //                           msg: "Can't change during game",
  //                           toastLength: Toast.LENGTH_SHORT,
  //                         );
  //                         return;
  //                       }
  //
  //                       SharedPreferences prefs =
  //                           await SharedPreferences.getInstance();
  //
  //                       setState(() {
  //                         timerEnabled = value;
  //                       });
  //
  //                       setStateMenu(() {});
  //                       prefs.setBool("timer_enabled", timerEnabled);
  //                     },
  //                   ),
  //                 ],
  //               );
  //             },
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // Widget settingsTile({
  //   required IconData icon,
  //   required String title,
  //   required bool value,
  //   ValueChanged<bool>? onChanged,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 1),
  //     child: Row(
  //       children: [
  //         Icon(icon, size: 20, color: Colors.blueAccent),
  //         const SizedBox(width: 8),
  //
  //         Expanded(
  //           child: Text(
  //             title,
  //             style: TextStyle(
  //               color: isDark ? Colors.white : Colors.black,
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
  //             onChanged: onChanged,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void showSettingsMenu() {
    showGlassSettingsMenu(
      context: context,

      isDark: isDark,

      items: [
        /// 🌙 THEME
        SettingsMenuItem(
          affectsTheme: true,

          iconBuilder: (value) {
            return value ? Icons.dark_mode : Icons.light_mode;
          },

          title: "Dark Theme",

          value: isDark,

          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            playVibration(130);

            setState(() {
              isDark = value;
            });

            await prefs.setBool("theme_dark", isDark);
          },
        ),

        /// 🔊 SOUND
        SettingsMenuItem(
          iconBuilder: (value) {
            return value ? Icons.volume_up : Icons.volume_off;
          },

          title: "Sound",

          value: soundOn,

          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            playVibration(130);

            setState(() {
              soundOn = value;
            });

            await prefs.setBool("sound_on", soundOn);
          },
        ),

        /// 📳 VIBRATION
        SettingsMenuItem(
          iconBuilder: (value) {
            return value ? Icons.vibration : Icons.phonelink_erase;
          },

          title: "Vibration",

          value: vibrationOn,

          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            setState(() {
              vibrationOn = value;
            });

            await prefs.setBool("vibration_on", vibrationOn);
          },
        ),

        /// ⏱ TIMER
        /// ⏱ TIMER
        SettingsMenuItem(
          iconBuilder: (value) {
            return value ? Icons.timer : Icons.timer_off;
          },

          title: "Timer",

          value: timerEnabled,

          /// 🔥 PREVENT CHANGE
          canChange: (value) {
            if (isGameRunning) {
              Fluttertoast.showToast(
                msg: "Can't change during game",

                toastLength: Toast.LENGTH_SHORT,
              );

              return false;
            }

            return true;
          },

          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            setState(() {
              timerEnabled = value;
            });

            await prefs.setBool("timer_enabled", timerEnabled);
          },
        ),
      ],
    );
  }

  void showBoardSizeMenu() {
    /// 🔥 BLOCK DURING MATCH
    if (isGameRunning) {
      Fluttertoast.showToast(
        msg: "Can't change during match",

        toastLength: Toast.LENGTH_SHORT,
      );

      return;
    }

    showMenu(
      context: context,

      //position: const RelativeRect.fromLTRB(0, 90, 10, 0),
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2 - 75, 85,
        MediaQuery.of(context).size.width / 2 - 75, 0,
      ),
      color: Colors.transparent,

      elevation: 0,

      items: [
        PopupMenuItem(
          enabled: false,

          padding: EdgeInsets.zero,

          child: Material(
            color: Colors.transparent,

            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),

              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),

                child: Container(
                  width: 150,

                  //padding: const EdgeInsets.all(5),
                  //padding: const EdgeInsets.symmetric(vertical: 5),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),

                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,

                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.10),

                              Colors.white.withValues(alpha: 0.04),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.45),

                              Colors.white.withValues(alpha: 0.18),
                            ],
                    ),

                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.20 : 0.08,
                        ),

                        blurRadius: 24,

                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),


                  ///old
                  // child: Column(
                  //   mainAxisSize: MainAxisSize.min,
                  //
                  //   children: availableBoardSizes.map((size) {
                  //     bool selected = boardSize == size;
                  //
                  //     return GestureDetector(
                  //       onTap: () {
                  //         playVibration(120);
                  //
                  //         setState(() {
                  //           boardSize = size;
                  //           board = List.filled(size * size, "");
                  //           player1Turn = true;
                  //           gameOver = false;
                  //           winningLine = null;
                  //           gameMessage = "";
                  //           lastMove = -1;
                  //           pressedIndex = -1;
                  //           isTimeUp = false;
                  //         });
                  //
                  //         Navigator.pop(context);
                  //       },
                  //
                  //       child: AnimatedContainer(
                  //         duration: const Duration(milliseconds: 180),
                  //
                  //         margin: const EdgeInsets.only(bottom: 10),
                  //
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 14,
                  //           vertical: 14,
                  //         ),
                  //
                  //         decoration: BoxDecoration(
                  //           borderRadius: BorderRadius.circular(18),
                  //
                  //           gradient: selected
                  //               ? const LinearGradient(
                  //                   colors: [
                  //                     Colors.blueAccent,
                  //
                  //                     Colors.cyanAccent,
                  //                   ],
                  //                 )
                  //               : null,
                  //
                  //           color: selected
                  //               ? null
                  //               : isDark
                  //               ? Colors.white.withValues(alpha: 0.05)
                  //               : Colors.white.withValues(alpha: 0.55),
                  //
                  //           border: Border.all(
                  //             color: selected
                  //                 ? Colors.transparent
                  //                 : isDark
                  //                 ? Colors.white.withValues(alpha: 0.08)
                  //                 : Colors.black.withValues(alpha: 0.06),
                  //           ),
                  //
                  //           boxShadow: selected
                  //               ? [
                  //                   BoxShadow(
                  //                     color: Colors.blueAccent.withValues(
                  //                       alpha: 0.45,
                  //                     ),
                  //
                  //                     blurRadius: 18,
                  //
                  //                     spreadRadius: 1,
                  //                   ),
                  //                 ]
                  //               : [],
                  //         ),
                  //
                  //         child: Row(
                  //           children: [
                  //             Expanded(
                  //               child: Text(
                  //                 "${size}x$size",
                  //
                  //                 style: TextStyle(
                  //                   fontSize: 15,
                  //
                  //                   fontWeight: FontWeight.bold,
                  //
                  //                   color: selected
                  //                       ? Colors.white
                  //                       : isDark
                  //                       ? Colors.white
                  //                       : Colors.black87,
                  //                 ),
                  //               ),
                  //             ),
                  //
                  //             AnimatedContainer(
                  //               duration: const Duration(milliseconds: 180),
                  //
                  //               width: 26,
                  //               height: 26,
                  //
                  //               decoration: BoxDecoration(
                  //                 shape: BoxShape.circle,
                  //
                  //                 color: selected
                  //                     ? Colors.white
                  //                     : Colors.transparent,
                  //
                  //                 border: Border.all(
                  //                   color: selected
                  //                       ? Colors.white
                  //                       : isDark
                  //                       ? Colors.white54
                  //                       : Colors.black45,
                  //
                  //                   width: 2,
                  //                 ),
                  //               ),
                  //
                  //               child: selected
                  //                   ? const Icon(
                  //                       Icons.check,
                  //
                  //                       size: 16,
                  //
                  //                       color: Colors.blue,
                  //                     )
                  //                   : null,
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     );
                  //   }).toList(),
                  // ),



                  ///new
                  child: SizedBox(
                    height: 210, // 🔥 ONLY 3 ITEMS VISIBLE

                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 6,
                      ),
                      controller: ScrollController(
                        /// 🔥 SELECTED ITEM CENTER
                        //initialScrollOffset: ((boardSize - 3) * 72).toDouble(),
                        initialScrollOffset:

                        (
                            ((boardSize - 3) * 58) - 58
                        ).clamp(
                          0,
                          double.infinity,
                        ).toDouble(),
                      ),

                      physics: const BouncingScrollPhysics(),

                      itemCount: availableBoardSizes.length,

                      itemBuilder: (context, index) {
                        int size = availableBoardSizes[index];

                        bool selected = boardSize == size;

                        return GestureDetector(
                          onTap: () {
                            playVibration(120);

                            /// 🔥 TIMER RESET
                            hasGameStarted = false;

                            turnTimer?.cancel();

                            timerController.reset();

                            stopTickingSound();

                            SharedPreferences.getInstance()
                                .then((prefs) {

                              prefs.setInt(
                                "board_size",
                                size,
                              );
                            });

                            setState(() {
                              boardSize = size;

                              board = List.filled(size * size, "");

                              player1Turn = true;

                              gameOver = false;

                              winningLine = null;

                              gameMessage = "";

                              lastMove = -1;

                              pressedIndex = -1;

                              isTimeUp = false;
                            });

                            Navigator.pop(context);
                          },

                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),

                            margin: const EdgeInsets.only(bottom: 5),

                            padding: const EdgeInsets.only(left: 10, right: 5, top: 5, bottom: 5),


                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),

                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [
                                        Colors.blueAccent,

                                        Colors.cyanAccent,
                                      ],
                                    )
                                  : null,

                              color: selected
                                  ? null
                                  : isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.55),

                              border: Border.all(
                                color: selected
                                    ? Colors.transparent
                                    : isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),

                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Colors.blueAccent.withValues(
                                          alpha: 0.45,
                                        ),

                                        blurRadius: 18,

                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),

                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${size}x$size",

                                    style: TextStyle(
                                      fontSize: 15,

                                      fontWeight: FontWeight.bold,

                                      color: selected
                                          ? Colors.white
                                          : isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),

                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),

                                  width: 26,
                                  height: 26,

                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,

                                    color: selected
                                        ? Colors.white
                                        : Colors.transparent,

                                    border: Border.all(
                                      color: selected
                                          ? Colors.white
                                          : isDark
                                          ? Colors.white54
                                          : Colors.black45,

                                      width: 2,
                                    ),
                                  ),

                                  child: selected
                                      ? const Icon(
                                          Icons.check,

                                          size: 16,

                                          color: Colors.blue,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //Color bgColor = isDark ? const Color(0xFF1F2A44) : const Color(0xFFF5F5F5);
    Color boardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;
    Color cellColor = isDark
        ? const Color(0xFF1F2A44)
        : const Color(0xFFF0F0F0);
    Color textColor = isDark ? Colors.white : Colors.black87;
    double boardPixelSize = boardSize <= 3
        ? 280
        : boardSize == 4
        ? 320
        : boardSize == 5
        ? 340
        : boardSize == 6
        ? 360
        : boardSize == 7
        ? 380
        : boardSize == 8
        ? 400
        : 420;
    return PopScope(
      canPop: (gameOver || !board.any((e) => e != "")),

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        /// 🔥 MATCH RUNNING
        if (!gameOver && board.any((e) => e != "")) {
          await showExitDialog();
        } else {
          /// 🔥 DIRECT BACK
          playVibration(120);

          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },

      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          //leadingWidth: 120,
          // 🔥 ADD HERE
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
                // onTap: () async {
                //   await showExitDialog();
                //   // playVibration(120);
                //   // Navigator.pop(context);
                // },
                onTap: () async {
                  /// 🔥 MATCH RUNNING
                  if (!gameOver && board.any((e) => e != "")) {
                    await showExitDialog();
                  } else {
                    /// 🔥 DIRECT BACK
                    playVibration(120);

                    Navigator.pop(context);
                  }
                },
                child: build3DIconButton(
                  icon: Icons.arrow_back,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          // leading: Row(
          //   children: [
          //     const SizedBox(width: 10),
          //
          //     /// 🔙 BACK
          //     Tooltip(
          //       message: "Back",
          //
          //       child: GestureDetector(
          //         onTap: () async {
          //           if (!gameOver && board.any((e) => e != "")) {
          //             await showExitDialog();
          //           } else {
          //             playVibration(120);
          //
          //             Navigator.pop(context);
          //           }
          //         },
          //
          //         child: build3DIconButton(
          //           icon: Icons.arrow_back,
          //
          //           isDark: isDark,
          //         ),
          //       ),
          //     ),
          //
          //     const SizedBox(width: 10),
          //
          //     /// 🎮 BOARD SIZE
          //     Tooltip(
          //       message: "Board Size",
          //
          //       child: GestureDetector(
          //         onTap: showBoardSizeMenu,
          //
          //         child: build3DIconButton(
          //           icon: Icons.grid_view_rounded,
          //
          //           isDark: isDark,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          //
          //
          // title: Transform.translate(
          //   offset: const Offset(0, 0),
          //
          //   child: Text(
          //     "Play With \n Friends",
          //
          //     textAlign: TextAlign.center,
          //
          //     style: TextStyle(
          //       color: isDark ? Colors.cyanAccent : Colors.blue,
          //
          //       fontSize: 15,
          //
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
          //
          // centerTitle: true,

          // /// 🔙 BACK BUTTON
          // leading: Padding(
          //
          //   padding: const EdgeInsets.only(
          //     left: 10,
          //   ),
          //
          //   child: Tooltip(
          //
          //     message: "Back",
          //
          //     child: GestureDetector(
          //
          //       onTap: () async {
          //
          //         /// 🔥 MATCH RUNNING
          //         if (!gameOver &&
          //             board.any((e) => e != "")) {
          //
          //           await showExitDialog();
          //
          //         } else {
          //
          //           playVibration(120);
          //
          //           Navigator.pop(context);
          //         }
          //       },
          //
          //       child: build3DIconButton(
          //
          //         icon: Icons.arrow_back,
          //
          //         isDark: isDark,
          //       ),
          //     ),
          //   ),
          // ),

          /// 🎮 BOARD SIZE SELECT
          title: GestureDetector(
            onTap: () {
              // if (!gameOver &&
              //     board.any((e) => e != "")) {
              //
              //   showToast(
              //     "Finish the match before changing board size.",
              //   );
              //
              //   playVibration(150);
              //
              //   return;
              // }

              showBoardSizeMenu();

              playVibration(130);
            },

            child: Container(
              padding: const EdgeInsets.all(1.5),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                gradient: isDark
                    ? const LinearGradient(
                        colors: [Colors.blueAccent, Colors.cyanAccent],
                      )
                    : const LinearGradient(
                        colors: [Colors.blue, Colors.indigo],
                      ),
              ),

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,

                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2B3A5A), const Color(0xFF2B3A5A)]
                        : [Colors.white, Colors.white],
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.4),

                      blurRadius: 8,

                      spreadRadius: 1,
                    ),
                  ],
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Text(
                      "${boardSize} x ${boardSize}",

                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,

                        fontSize: 15,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 4),

                    Icon(
                      Icons.expand_more,

                      color: isDark ? Colors.white : Colors.black,

                      size: 18,
                    ),
                  ],
                ),
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
                  child: build3DIconButton(icon: Icons.gesture, isDark: isDark),
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
                  child: build3DIconButton(
                    icon: Icons.settings,
                    isDark: isDark,
                  ),
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
                      ? [
                          Color(0xFF1F2A44),
                          Color(0xFF111827),
                          Color(0xFF0B132B),
                        ]
                      : [
                          Color(0xFFEAEAEA),
                          Color(0xFFEEF8F7),
                          Color(0xFFEAEAEA),
                        ],
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

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // SCORE SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          scoreBox(
                            "Player 1",
                            player1Symbol,
                            boardColor,
                            textColor,
                          ),

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

                          scoreBox(
                            "Player 2",
                            player2Symbol,
                            boardColor,
                            textColor,
                          ),
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
                              color: currentTime <= 5
                                  ? Colors.red
                                  : Colors.green,
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

                            List<Color> gradientColors =
                                gameMessage.contains("WIN")
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
                                      scale: 0.95 + (0.05 * value),

                                      // slight pop
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(2),

                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: gradientColors,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),

                                          boxShadow: [
                                            BoxShadow(
                                              color: gradientColors.first
                                                  .withValues(
                                                    alpha: glowAnimation.value,
                                                  ),
                                              blurRadius:
                                                  12 * glowAnimation.value,
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
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
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
                                                      ..style =
                                                          PaintingStyle.stroke
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
                                                      color: gradientColors
                                                          .first
                                                          .withValues(
                                                            alpha: glowAnimation
                                                                .value,
                                                          ),
                                                      blurRadius:
                                                          10 *
                                                          glowAnimation.value,
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

                      const SizedBox(height: 020),

                      /// GAME BOARD (CENTERED)
                      // Expanded(
                      SizedBox(
                        height: 320,
                        //height: boardPixelSize + 40,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 320,
                            height: 320,
                            // width: boardPixelSize,
                            // height: boardPixelSize,
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
                              //padding: const EdgeInsets.all(8),
                              padding: EdgeInsets.all(boardSize <= 5 ? 8 : 5),
                              decoration: BoxDecoration(
                                color: boardColor,
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Stack(
                                children: [
                                  GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    //itemCount: 9,
                                    itemCount: board.length,
                                    gridDelegate:
                                        // const SliverGridDelegateWithFixedCrossAxisCount(
                                        //   crossAxisCount: 3,
                                        // ),
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: boardSize,

                                          childAspectRatio: 1,
                                        ),

                                    itemBuilder: (context, index) {
                                      bool highlight = index == lastMove;
                                      bool win =
                                          winningLine != null &&
                                          winningLine!.contains(index);

                                      return GestureDetector(
                                        onTap: () => handleTap(index),

                                        child: AnimatedScale(
                                          scale: pressedIndex == index
                                              ? 0.92
                                              : 1,
                                          duration: const Duration(
                                            milliseconds: 120,
                                          ),

                                          child: Container(
                                            //margin: const EdgeInsets.all(6),
                                            margin: EdgeInsets.all(
                                              boardSize <= 4
                                                  ? 6
                                                  : boardSize <= 6
                                                  ? 4
                                                  : 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cellColor,
                                              //borderRadius: BorderRadius.circular(12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    boardSize <= 5 ? 12 : 8,
                                                  ),
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
                                                  //? const GameX()
                                                  // ? GameX(
                                                  //     size: boardSize <= 3
                                                  //         ? 40
                                                  //         : boardSize <= 5
                                                  //         ? 32
                                                  //         : boardSize <= 7
                                                  //         ? 24
                                                  //         : 18,
                                                  //   )
                                                  ? GameX(
                                                      size: boardSize <= 3
                                                          ? 40
                                                          : boardSize <= 5
                                                          ? 26
                                                          : boardSize <= 7
                                                          ? 18
                                                          : 12,
                                                    )
                                                  : board[index] == "O"
                                                  //? const GameO()
                                                  // ? GameO(
                                                  //     size: boardSize <= 3
                                                  //         ? 40
                                                  //         : boardSize <= 5
                                                  //         ? 32
                                                  //         : boardSize <= 7
                                                  //         ? 24
                                                  //         : 18,
                                                  //   )
                                                  ? GameO(
                                                      size: boardSize <= 3
                                                          ? 40
                                                          : boardSize <= 5
                                                          ? 26
                                                          : boardSize <= 7
                                                          ? 18
                                                          : 12,
                                                    )
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
                                          size: Size(
                                            320 - (boardSize <= 5 ? 16 : 10),

                                            320 - (boardSize <= 5 ? 16 : 10),
                                          ),
                                          //size: const Size(260, 260),
                                          painter: WinLinePainter(
                                            // winningLine!,
                                            // lineAnimation.value,
                                            // 3,
                                            winningLine!,
                                            lineAnimation.value,
                                            boardSize,
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
                              NeonGlowingButton(
                                text: "Home",
                                icon: Icons.home,
                                onTap: () {
                                  playVibration(120);
                                  Navigator.pop(context);
                                },
                                isDark: isDark,

                                glowController: glowController,

                                glowAnimation: glowAnimation,
                              ),

                              NeonGlowingButton(
                                text: "Replay",
                                icon: Icons.refresh,
                                onTap: () {
                                  //playXSound();   // replay sound
                                  playVibration(120);
                                  resetGame();
                                },
                                isDark: isDark,

                                glowController: glowController,

                                glowAnimation: glowAnimation,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 80),

                      // if (!gameOver)
                      //   GestureDetector(
                      //     onTapDown: (_) {
                      //       setState(() {
                      //         resetPressed = true;
                      //       });
                      //     },
                      //
                      //     onTapUp: (_) {
                      //       setState(() {
                      //         resetPressed = false;
                      //       });
                      //       resetGame();
                      //     },
                      //
                      //     onTapCancel: () {
                      //       setState(() {
                      //         resetPressed = false;
                      //       });
                      //     },
                      //
                      //     child: AnimatedScale(
                      //       scale: resetPressed ? 0.92 : 1,
                      //       duration: const Duration(milliseconds: 120),
                      //
                      //       child: Container(
                      //         width: double.infinity,
                      //         height: 50,
                      //         padding: const EdgeInsets.all(1),
                      //
                      //         decoration: BoxDecoration(
                      //           borderRadius: BorderRadius.circular(14),
                      //
                      //           gradient: LinearGradient(
                      //             colors: isDark
                      //                 ? [
                      //               Colors.pinkAccent,
                      //               Colors.orangeAccent,
                      //               Colors.pinkAccent,
                      //
                      //                   ]
                      //                 : [
                      //               Colors.blueAccent,
                      //               Colors.cyanAccent,
                      //               Colors.blueAccent,
                      //                   ],
                      //           ),
                      //         ),
                      //
                      //         child: Container(
                      //           decoration: BoxDecoration(
                      //             color: boardColor,
                      //             borderRadius: BorderRadius.circular(12),
                      //           ),
                      //
                      //           child: Center(
                      //             child: Text(
                      //               "Reset Game",
                      //               style: TextStyle(
                      //                 color: textColor,
                      //                 fontSize: 16,
                      //                 fontWeight: FontWeight.bold,
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      if (!gameOver && board.any((e) => e != ""))
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

                            //resetGame();
                            showResetGameDialog();
                          },

                          onTapCancel: () {
                            setState(() {
                              resetPressed = false;
                            });
                          },

                          child: AnimatedScale(
                            scale: resetPressed ? 0.92 : 1,

                            duration: const Duration(milliseconds: 120),

                            child: SizedBox(
                              width: double.infinity,

                              child: BuildIconTextButton(
                                icon: Icons.refresh,

                                text: "Reset Game",

                                isDark: isDark,

                                borderRadius: BorderRadius.circular(14),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.4 : 0.15,
                                    ),

                                    offset: const Offset(2, 2),

                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
      ),
    );
  } // end widget build

  Future<void> showExitDialog() async {
    await showAppDialog(
      context: context,

      title: "EXIT MATCH",

      message: "Exit and end the match?",

      positiveText: "EXIT",
      negativeText: "CANCEL",

      barrierDismissible: true,
      canPop: true,

      onNegative: () {
        // 🔥 nothing needed
      },

      onPositive: () async {
        playVibration(120);
        stopTickingSound();
        Navigator.pop(context);
      },
    );
  }

  // Widget neonButton({
  //   required String text,
  //   required IconData icon,
  //   required VoidCallback onTap,
  // }) {
  //   List<Color> colors = isDark
  //       ? [Colors.blueAccent, Colors.purpleAccent]
  //       : [Colors.orangeAccent, Colors.pinkAccent];
  //
  //   return Material(
  //     color: Colors.transparent,
  //
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(16),
  //
  //       child: AnimatedBuilder(
  //         animation: glowController,
  //
  //         builder: (context, child) {
  //           return Container(
  //             padding: const EdgeInsets.all(1),
  //
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(16),
  //               gradient: LinearGradient(colors: colors),
  //
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: colors.first.withValues(alpha: glowAnimation.value),
  //                   blurRadius: 20 * glowAnimation.value,
  //                 ),
  //               ],
  //             ),
  //
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 20,
  //                 vertical: 10,
  //               ),
  //
  //               decoration: BoxDecoration(
  //                 color: isDark ? const Color(0xFF2B3A5A) : Colors.white,
  //
  //                 borderRadius: BorderRadius.circular(14),
  //               ),
  //
  //               child: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Icon(icon, color: colors.first),
  //
  //                   const SizedBox(width: 6),
  //
  //                   Text(
  //                     text,
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: isDark ? Colors.white : Colors.black87,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

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
  final double size;

  const GameX({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,

      height: size,

      child: CustomPaint(painter: XPainter()),
    );
  }
}

///old icon button
// Widget build3DIconButton(IconData icon, bool isDark) {
//   return Container(
//     width: 44,
//     height: 44,
//     alignment: Alignment.center,
//
//     // 🔥 FIX
//     padding: const EdgeInsets.all(1.5),
//
//     // 🔥 border thickness
//     decoration: BoxDecoration(
//       shape: BoxShape.circle,
//
//       /// 🔥 Gradient Border
//       gradient: isDark
//           ? const LinearGradient(colors: [Colors.blueAccent, Colors.cyanAccent])
//           : const LinearGradient(colors: [Colors.blue, Colors.indigo]),
//
//       /// 🔥 Glow
//       boxShadow: [
//         BoxShadow(
//           color: Colors.blueAccent.withValues(alpha:0.4),
//           blurRadius: 10,
//           spreadRadius: 1,
//         ),
//       ],
//     ),
//
//     child: Container(
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF3F8),
//         shape: BoxShape.circle,
//
//         boxShadow: [
//           BoxShadow(
//             color: Colors.white.withValues(alpha:isDark ? 0.05 : 0.9),
//             offset: const Offset(-3, -3),
//             blurRadius: 6,
//           ),
//           BoxShadow(
//             color: Colors.black.withValues(alpha:isDark ? 0.6 : 0.2),
//             offset: const Offset(3, 3),
//             blurRadius: 6,
//           ),
//         ],
//       ),
//
//       child: Icon(
//         icon,
//         color: isDark ? Colors.cyanAccent : Colors.blue,
//         size: 20,
//       ),
//     ),
//   );
// }

///new icon button
// Widget build3DIconButton({
//   IconData? icon,
//   String? text,
//   required bool isDark,
// }) {
//   return SizedBox(
//     width: 44,
//     height: 44,
//
//     child: Container(
//       padding: const EdgeInsets.all(1.5),
//
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: isDark
//             ? const LinearGradient(
//           colors: [Colors.blueAccent, Colors.cyanAccent],
//         )
//             : const LinearGradient(colors: [Colors.blue, Colors.indigo]),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blueAccent.withValues(alpha:0.4),
//             blurRadius: 10,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//
//       child: Container(
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF3F8),
//         ),
//
//         child: icon != null
//             ? Icon(
//           icon,
//           size: 20, // 🔥 fixed icon size
//           color: isDark ? Colors.cyanAccent : Colors.blue,
//         )
//             : Text(
//           text ?? "",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 20, // 🔥 CONTROL TEXT SIZE
//             color: isDark ? Colors.cyanAccent : Colors.blue,
//           ),
//         ),
//       ),
//     ),
//   );
// }

// class WinLinePainter extends CustomPainter {
//
//   final List<int> winningLine;
//
//   final double animationValue;
//
//   final int boardSize;
//
//   WinLinePainter(
//       this.winningLine,
//       this.animationValue,
//       this.boardSize,
//       );
//
//   @override
//   void paint(Canvas canvas, Size size) {
//
//     if (winningLine.length < 2) return;
//
//     final paint = Paint()
//
//       ..color = Colors.greenAccent
//
//       ..strokeWidth = boardSize <= 5 ? 8 : 5
//
//       ..strokeCap = StrokeCap.round
//
//       ..style = PaintingStyle.stroke;
//
//     double cellSize = size.width / boardSize;
//
//     /// 🔥 FIRST CELL
//     int first = winningLine.first;
//
//     int firstRow = first ~/ boardSize;
//
//     int firstCol = first % boardSize;
//
//     /// 🔥 LAST CELL
//     int last = winningLine.last;
//
//     int lastRow = last ~/ boardSize;
//
//     int lastCol = last % boardSize;
//
//     /// 🔥 CENTER POSITION
//     Offset start = Offset(
//       firstCol * cellSize + cellSize / 2,
//       firstRow * cellSize + cellSize / 2,
//     );
//
//     Offset end = Offset(
//       lastCol * cellSize + cellSize / 2,
//       lastRow * cellSize + cellSize / 2,
//     );
//
//     /// 🔥 ANIMATION
//     Offset animatedEnd = Offset.lerp(
//       start,
//       end,
//       animationValue,
//     )!;
//
//     /// 🔥 DRAW
//     canvas.drawLine(
//       start,
//       animatedEnd,
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant WinLinePainter oldDelegate) {
//
//     return oldDelegate.animationValue != animationValue ||
//         oldDelegate.winningLine != winningLine;
//   }
// }
