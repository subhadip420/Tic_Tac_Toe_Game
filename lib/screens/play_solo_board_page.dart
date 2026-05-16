import 'package:flutter/material.dart';
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
import '../widgets/custom_toast.dart';
import '../widgets/glass_settings_menu.dart';
import '../widgets/loading_dialog_with_button.dart';
import '../widgets/neon_glowing_button.dart';

class GameBoardPage extends StatefulWidget {
  const GameBoardPage({super.key});

  @override
  State<GameBoardPage> createState() => _GameBoardPageState();
}

late AnimationController lineController;
late Animation<double> lineAnimation;

class _GameBoardPageState extends State<GameBoardPage>
    with TickerProviderStateMixin {
  //final AudioPlayer player = AudioPlayer();
  final AudioPlayer xPlayer = AudioPlayer();
  final AudioPlayer oPlayer = AudioPlayer();
  final AudioPlayer winPlayer = AudioPlayer();
  final AudioPlayer losePlayer = AudioPlayer();
  final AudioPlayer drawPlayer = AudioPlayer();

  late AnimationController glowController;
  late Animation<double> glowAnimation;

  bool resetPressed = false;

  late ConfettiController confettiController;
  String gameMessage = "";

  String playerSymbol = "X";
  String botSymbol = "O";

  String difficulty = "Easy";

  int playerScore = 0;
  int aiScore = 0;

  bool isDark = true; // default dark
  bool soundOn = true; // default sound on
  bool vibrationOn = true;

  bool gameOver = false;

  int pressedIndex = -1;

  List<String> board = List.filled(9, "");
  int lastMove = -1;
  bool playerTurn = true;
  List<int>? winningLine;

  @override
  void initState() {
    super.initState();

    lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    lineAnimation = CurvedAnimation(
      parent: lineController,
      curve: Curves.easeInOut,
    );

    loadSettings();

    Future.delayed(Duration.zero, () {
      chooseSymbolDialog();
    });

    confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    glowController.dispose();
    confettiController.dispose();
    lineController.dispose();
    super.dispose();
  }

  Future loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      soundOn = prefs.getBool("sound_on") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
    });
  }

  ///new
  void chooseSymbolDialog() {
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
            //             colors: [Colors.blue, Colors.orange],
            //           ),
            //   ),
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
                        "Choose Your Symbol",
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
                              //playVibration(120);
                              if (vibrationOn) {HapticFeedback.mediumImpact();}
                              setState(() {
                                playerSymbol = "X";
                                botSymbol = "O";
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
                              //playVibration(120);
                              if (vibrationOn) {HapticFeedback.mediumImpact();}
                              setState(() {
                                playerSymbol = "O";
                                botSymbol = "X";
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

  ///old
  // void chooseSymbolDialog() {
  //
  //   showGeneralDialog(
  //
  //     context: context,
  //
  //     barrierDismissible: false,
  //
  //     barrierLabel: "Symbol",
  //
  //     barrierColor: Colors.black.withOpacity(0.5),
  //
  //     transitionDuration: const Duration(milliseconds: 250),
  //
  //     pageBuilder: (
  //         context,
  //         animation,
  //         secondaryAnimation,
  //         ) {
  //
  //       return Center(
  //
  //         child: Material(
  //
  //           color: Colors.transparent,
  //
  //           child: Container(
  //
  //             padding: const EdgeInsets.all(1.5),
  //
  //             decoration: BoxDecoration(
  //
  //               borderRadius: BorderRadius.circular(28),
  //
  //               /// 🔥 OUTER GRADIENT BORDER
  //               gradient: const LinearGradient(
  //                 colors: [
  //                   Colors.transparent,
  //                   Colors.transparent,
  //                 ],
  //               ),
  //
  //               /// 🔥 OUTER GLOW
  //               boxShadow: [
  //
  //                 BoxShadow(
  //                   color: Colors.cyanAccent.withOpacity(0.25),
  //                   blurRadius: 20,
  //                   spreadRadius: 1,
  //                 ),
  //
  //                 BoxShadow(
  //                   color: Colors.orangeAccent.withOpacity(0.15),
  //                   blurRadius: 20,
  //                   spreadRadius: 1,
  //                 ),
  //               ],
  //             ),
  //
  //             child: ClipRRect(
  //
  //               borderRadius: BorderRadius.circular(28),
  //
  //               child: BackdropFilter(
  //
  //                 filter: ImageFilter.blur(
  //                   sigmaX: 5,
  //                   sigmaY: 5,
  //                 ),
  //
  //                 child: Container(
  //
  //                   width: 300,
  //                   height: 220,
  //
  //                   padding: const EdgeInsets.all(20),
  //
  //                   decoration: BoxDecoration(
  //
  //                     /// 🔥 GLASS EFFECT
  //                     gradient: LinearGradient(
  //                       begin: Alignment.topLeft,
  //                       end: Alignment.bottomRight,
  //
  //                       colors: isDark
  //                           ? [
  //                         Colors.white.withOpacity(0.14),
  //                         Colors.white.withOpacity(0.05),
  //                       ]
  //                           : [
  //                         Colors.white.withOpacity(0.35),
  //                         Colors.white.withOpacity(0.12),
  //                       ],
  //                     ),
  //
  //                     borderRadius: BorderRadius.circular(28),
  //
  //                     /// 🔥 GLASS BORDER
  //                     border: Border.all(
  //                       color: Colors.white.withOpacity(
  //                         isDark ? 0.18 : 0.35,
  //                       ),
  //                       width: 1.5,
  //                     ),
  //
  //                     /// 🔥 SHADOW
  //                     boxShadow: [
  //
  //                       BoxShadow(
  //                         color: Colors.cyanAccent.withOpacity(
  //                           isDark ? 0.10 : 0.06,
  //                         ),
  //                         blurRadius: 24,
  //                         spreadRadius: 2,
  //                       ),
  //
  //                       BoxShadow(
  //                         color: Colors.black.withOpacity(
  //                           isDark ? 0.25 : 0.08,
  //                         ),
  //                         offset: const Offset(0, 8),
  //                         blurRadius: 18,
  //                       ),
  //                     ],
  //                   ),
  //
  //                   child: Column(
  //
  //                     mainAxisSize: MainAxisSize.min,
  //
  //                     children: [
  //
  //                       /// 🔥 TITLE
  //                       Text(
  //                         "Choose Your Symbol",
  //
  //                         style: TextStyle(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.bold,
  //
  //                           color: isDark
  //                               ? Colors.white
  //                               : Colors.black,
  //                         ),
  //                       ),
  //
  //                       const SizedBox(height: 35),
  //
  //                       /// 🔥 BUTTONS
  //                       Row(
  //
  //                         mainAxisAlignment:
  //                         MainAxisAlignment.spaceEvenly,
  //
  //                         children: [
  //
  //                           /// 🔥 X BUTTON
  //                           GestureDetector(
  //
  //                             onTap: () {
  //
  //                               playVibration(120);
  //
  //                               setState(() {
  //
  //                                 playerSymbol = "X";
  //                                 botSymbol = "O";
  //                               });
  //
  //                               Navigator.pop(context);
  //                             },
  //
  //                             child: Container(
  //
  //                               width: 90,
  //                               height: 90,
  //
  //                               decoration: BoxDecoration(
  //
  //                                 /// 🔥 MINI GLASS EFFECT
  //                                 gradient: LinearGradient(
  //                                   begin: Alignment.topLeft,
  //                                   end: Alignment.bottomRight,
  //
  //                                   colors: isDark
  //                                       ? [
  //                                     Colors.white.withOpacity(0.10),
  //                                     Colors.white.withOpacity(0.04),
  //                                   ]
  //                                       : [
  //                                     Colors.white.withOpacity(0.45),
  //                                     Colors.white.withOpacity(0.18),
  //                                   ],
  //                                 ),
  //
  //                                 borderRadius:
  //                                 BorderRadius.circular(18),
  //
  //                                 border: Border.all(
  //                                   color: Colors.blueAccent
  //                                       .withOpacity(0.7),
  //                                   width: 1.5,
  //                                 ),
  //
  //                                 boxShadow: [
  //
  //                                   BoxShadow(
  //                                     color: Colors.blueAccent
  //                                         .withOpacity(0.18),
  //                                     blurRadius: 12,
  //                                     spreadRadius: 1,
  //                                   ),
  //
  //                                   BoxShadow(
  //                                     color: Colors.black
  //                                         .withOpacity(0.18),
  //                                     offset: const Offset(0, 5),
  //                                     blurRadius: 10,
  //                                   ),
  //                                 ],
  //                               ),
  //
  //                               child: const Center(
  //                                 child: GameX(),
  //                               ),
  //                             ),
  //                           ),
  //
  //                           /// 🔥 O BUTTON
  //                           GestureDetector(
  //
  //                             onTap: () {
  //
  //                               playVibration(120);
  //
  //                               setState(() {
  //
  //                                 playerSymbol = "O";
  //                                 botSymbol = "X";
  //                               });
  //
  //                               Navigator.pop(context);
  //                             },
  //
  //                             child: Container(
  //
  //                               width: 90,
  //                               height: 90,
  //
  //                               decoration: BoxDecoration(
  //
  //                                 /// 🔥 MINI GLASS EFFECT
  //                                 gradient: LinearGradient(
  //                                   begin: Alignment.topLeft,
  //                                   end: Alignment.bottomRight,
  //
  //                                   colors: isDark
  //                                       ? [
  //                                     Colors.white.withOpacity(0.10),
  //                                     Colors.white.withOpacity(0.04),
  //                                   ]
  //                                       : [
  //                                     Colors.white.withOpacity(0.45),
  //                                     Colors.white.withOpacity(0.18),
  //                                   ],
  //                                 ),
  //
  //                                 borderRadius:
  //                                 BorderRadius.circular(18),
  //
  //                                 border: Border.all(
  //                                   color: Colors.orangeAccent
  //                                       .withOpacity(0.7),
  //                                   width: 1.5,
  //                                 ),
  //
  //                                 boxShadow: [
  //
  //                                   BoxShadow(
  //                                     color: Colors.orangeAccent
  //                                         .withOpacity(0.18),
  //                                     blurRadius: 12,
  //                                     spreadRadius: 1,
  //                                   ),
  //
  //                                   BoxShadow(
  //                                     color: Colors.black
  //                                         .withOpacity(0.18),
  //                                     offset: const Offset(0, 5),
  //                                     blurRadius: 10,
  //                                   ),
  //                                 ],
  //                               ),
  //
  //                               child: const Center(
  //                                 child: GameO(),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //
  //     transitionBuilder: (
  //         context,
  //         animation,
  //         secondaryAnimation,
  //         child,
  //         ) {
  //
  //       final curvedValue =
  //       Curves.easeOutBack.transform(animation.value);
  //
  //       return Transform.scale(
  //
  //         scale: curvedValue,
  //
  //         child: Opacity(
  //           opacity: animation.value,
  //           child: child,
  //         ),
  //       );
  //     },
  //   );
  // }

  void handleTap(int index) {
    if (board[index] != "" || !playerTurn || gameOver) return;

    setState(() {
      pressedIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      setState(() {
        pressedIndex = -1;
        board[index] = playerSymbol;
        lastMove = index;
        playerTurn = false;
      });

      // PLAYER SOUND
      if (playerSymbol == "X") {
        playXSound();
        //playVibration(110);
        if (vibrationOn) {HapticFeedback.lightImpact();}
      } else {
        playOSound();
        //playVibration(110);
        if (vibrationOn) {HapticFeedback.lightImpact();}
      }

      checkWinner();

      if (!gameOver) {
        Future.delayed(const Duration(milliseconds: 500), aiMove);
      }
    });
  }

  Future<void> playXSound() async {
    if (!soundOn) return;

    await xPlayer.stop();
    await xPlayer.play(AssetSource("audio/o.mp3"));
  }

  Future<void> playOSound() async {
    if (!soundOn) return;

    await oPlayer.stop();
    await oPlayer.play(AssetSource("audio/o.mp3"));
  }

  Future playWinSound() async {
    if (!soundOn) return;

    await winPlayer.stop();
    await winPlayer.play(AssetSource("audio/win.mp3"));
  }

  Future playLoseSound() async {
    if (!soundOn) return;

    await losePlayer.stop();
    await losePlayer.play(AssetSource("audio/lose.mp3"));
  }

  Future playDrawSound() async {
    if (!soundOn) return;

    await drawPlayer.stop();
    await drawPlayer.play(AssetSource("audio/draw.mp3"));
  }

  Future playVibration(int duration) async {
    if (!vibrationOn) return;

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration);
    }
  }

  // void showToast(String message) {
  //   Fluttertoast.showToast(
  //     msg: message,
  //     toastLength: Toast.LENGTH_LONG,
  //     gravity: ToastGravity.CENTER,
  //     timeInSecForIosWeb: 2,
  //
  //     backgroundColor: isDark ? const Color(0xFF2B3A5A) : Colors.black87,
  //
  //     textColor: Colors.white,
  //     fontSize: 14,
  //   );
  // }

  void aiMove() {
    if (gameOver) return;

    int move;

    if (difficulty == "Easy") {
      move = getRandomMove();
    } else if (difficulty == "Medium") {
      if (Random().nextBool()) {
        move = getBestMove();
      } else {
        move = getRandomMove();
      }
    } else {
      move = getBestMove();
    }

    setState(() {
      board[move] = botSymbol;
      lastMove = move;
      playerTurn = true;
    });

    if (botSymbol == "X") {
      playXSound();
      //playVibration(110);
      if (vibrationOn) {HapticFeedback.lightImpact();}
    } else {
      playOSound();
      //playVibration(110);
      if (vibrationOn) {HapticFeedback.lightImpact();}
    }

    checkWinner();
  }

  void checkWinner() {
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

        // start winning line animation
        lineController.reset();
        lineController.forward();

        Future.delayed(const Duration(milliseconds: 900), () {
          if (board[combo[0]] == playerSymbol) {
            playerScore++;
            showResult(true);
          } else {
            aiScore++;
            showResult(false);
          }
        });

        return;
      }
    }

    // DRAW condition
    if (!board.contains("") && winningLine == null) {
      gameOver = true;

      Future.delayed(const Duration(milliseconds: 400), () {
        showResult(null);
      });
    }
  }

  void showResult(bool? playerWin) {
    setState(() {
      if (playerWin == true) {
        gameMessage = " YOU WIN ";
        playWinSound();
        playVibration(200);
        confettiController.play();
      } else if (playerWin == false) {
        gameMessage = " YOU LOSE ";
        playLoseSound();
        playVibration(180);
      } else {
        gameMessage = " DRAW ";
        playDrawSound();
        playVibration(150);
      }
    });
  }

  bool get gameStarted {
    return board.contains("X") || board.contains("O");
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
        if (vibrationOn) {HapticFeedback.lightImpact();}
        resetGame();
      },

      onNegative: () {
        if (vibrationOn) {HapticFeedback.lightImpact();}
        // dialog auto close
      },
    );
  }

  void resetGame() {
    //playVibration(120);
    setState(() {
      board = List.filled(9, "");
      winningLine = null;
      lastMove = -1;
      playerTurn = true;
      gameOver = false;
      gameMessage = "";
    });

    lineController.reset();
  }

  int getRandomMove() {
    List<int> empty = [];

    for (int i = 0; i < 9; i++) {
      if (board[i] == "") empty.add(i);
    }

    empty.shuffle();

    return empty.first;
  }

  int getBestMove() {
    int bestScore = -1000;
    int move = -1;

    for (int i = 0; i < 9; i++) {
      if (board[i] == "") {
        board[i] = botSymbol;

        int score = minimax(board, 0, false);

        board[i] = "";

        if (score > bestScore) {
          bestScore = score;
          move = i;
        }
      }
    }

    return move;
  }

  int minimax(List<String> newBoard, int depth, bool isMaximizing) {
    String? result = checkWinnerForAI(newBoard);

    if (result != null) {
      if (result == botSymbol) return 10 - depth;
      if (result == playerSymbol) return depth - 10;

      return 0;
    }

    if (isMaximizing) {
      int bestScore = -1000;

      for (int i = 0; i < 9; i++) {
        if (newBoard[i] == "") {
          newBoard[i] = botSymbol;

          int score = minimax(newBoard, depth + 1, false);

          newBoard[i] = "";

          bestScore = max(score, bestScore);
        }
      }

      return bestScore;
    } else {
      int bestScore = 1000;

      for (int i = 0; i < 9; i++) {
        if (newBoard[i] == "") {
          newBoard[i] = playerSymbol;

          int score = minimax(newBoard, depth + 1, true);

          newBoard[i] = "";

          bestScore = min(score, bestScore);
        }
      }

      return bestScore;
    }
  }

  String? checkWinnerForAI(List<String> b) {
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
      if (b[combo[0]] != "" &&
          b[combo[0]] == b[combo[1]] &&
          b[combo[1]] == b[combo[2]]) {
        return b[combo[0]];
      }
    }

    if (!b.contains("")) return "draw";

    return null;
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDark ? const Color(0xFF1F2A44) : const Color(0xFFF5F5F5);
    Color boardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;
    Color cellColor = isDark
        ? const Color(0xFF1F2A44)
        : const Color(0xFFF0F0F0);
    Color textColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      canPop: (gameOver || !board.any((e) => e != "")),

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        /// 🔥 MATCH RUNNING
        if (!gameOver && board.any((e) => e != "")) {
          if (vibrationOn) {HapticFeedback.lightImpact();}
          await showExitDialog();

        } else {
          /// 🔥 DIRECT BACK
          //playVibration(120);
          if (vibrationOn) {HapticFeedback.lightImpact();}

          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },

      child: Scaffold(
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
                // onTap: () async {
                //   await showExitDialog();
                //   // playVibration(120);
                //   // Navigator.pop(context);
                // },
                onTap: () async {
                  /// 🔥 MATCH RUNNING
                  if (!gameOver && board.any((e) => e != "")) {
                    if (vibrationOn) {HapticFeedback.lightImpact();}
                    await showExitDialog();

                  } else {
                    /// 🔥 DIRECT BACK
                    //playVibration(120);
                    if (vibrationOn) {HapticFeedback.lightImpact();}
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

          title: GestureDetector(
            onTap: () {
              if (gameStarted && !gameOver) {
                //showToast("Finish the match before changing difficulty.");
                CustomToast.show(
                  context: context,
                  message: "Finish Match First",
                  isDark: isDark,
                  //icon: Icons.lock_clock_rounded,
                  color: Colors.orange,
                );
                //playVibration(150);
                if (vibrationOn) {HapticFeedback.mediumImpact();}
                return;
              }

              showDifficultyMenu();
              if (vibrationOn) {HapticFeedback.mediumImpact();}
              //playVibration(130);
            },

            child: Container(
              padding: const EdgeInsets.all(1.5), // 🔥 border thickness

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                /// 🔥 Gradient Border
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

                  /// 🔥 Inner Background
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Color(0xFF2B3A5A), Color(0xFF2B3A5A)]
                        : [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
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
                      difficulty,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
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
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: "Settings",
                child: GestureDetector(
                  onTap: () {
                    if (vibrationOn) {HapticFeedback.mediumImpact();}
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
                          scoreBox("You", playerSymbol, boardColor, textColor),

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
                              "$playerScore - $aiScore",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          scoreBox("AI", botSymbol, boardColor, textColor),
                        ],
                      ),

                      const SizedBox(height: 40),

                      if (!gameOver)
                        Text(
                          playerTurn ? "Your Turn" : "AI Turn",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      const SizedBox(height: 00),

                      if (gameMessage != "")
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 450),
                          tween: Tween<double>(begin: 0.85, end: 1),
                          curve: Curves.easeOutBack,
                          builder: (context, double scale, child) {
                            Color cardColor = isDark
                                ? const Color(0xFF2B3A5A)
                                : Colors.white;

                            List<Color> gradientColors;

                            if (gameMessage.contains("WIN")) {
                              gradientColors = [
                                Colors.greenAccent,
                                Colors.blueAccent,
                              ];
                            } else if (gameMessage.contains("LOSE")) {
                              gradientColors = [
                                Colors.redAccent,
                                Colors.orange,
                              ];
                            } else {
                              gradientColors = [
                                Colors.orangeAccent,
                                Colors.yellow,
                              ];
                            }

                            return AnimatedBuilder(
                              animation: glowAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(2),

                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: gradientColors,
                                      ),
                                      borderRadius: BorderRadius.circular(20),

                                      boxShadow: [
                                        BoxShadow(
                                          color: gradientColors.first
                                              .withValues(
                                                alpha: glowAnimation.value,
                                              ),
                                          blurRadius: 25 * glowAnimation.value,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),

                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(18),
                                      ),

                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // GRADIENT TEXT BORDER
                                          ShaderMask(
                                            shaderCallback: (rect) {
                                              return LinearGradient(
                                                colors: gradientColors,
                                              ).createShader(rect);
                                            },
                                            child: Text(
                                              gameMessage,
                                              style: TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                                foreground: Paint()
                                                  ..style = PaintingStyle.stroke
                                                  ..strokeWidth = 3
                                                  ..color = Colors.white,
                                              ),
                                            ),
                                          ),

                                          // MAIN WHITE TEXT
                                          Text(
                                            gameMessage,
                                            style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                              color: Colors.white,

                                              shadows: [
                                                Shadow(
                                                  color: gradientColors.first
                                                      .withValues(
                                                        alpha:
                                                            glowAnimation.value,
                                                      ),
                                                  blurRadius:
                                                      20 * glowAnimation.value,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 20),

                      /// GAME BOARD (CENTERED)
                      // Expanded(
                      //   child: Align(
                      SizedBox(
                        height: 320,

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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                          scale: pressedIndex == index
                                              ? 0.92
                                              : 1,
                                          duration: const Duration(
                                            milliseconds: 120,
                                          ),

                                          child: Container(
                                            margin: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: cellColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),

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
                              NeonGlowingButton(
                                text: "Home",
                                icon: Icons.home,
                                onTap: () {
                                  //playVibration(120);
                                  if (vibrationOn) {HapticFeedback.heavyImpact();}
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
                                  //playVibration(120);
                                  if (vibrationOn) {HapticFeedback.mediumImpact();}
                                  resetGame();
                                },

                                isDark: isDark,

                                glowController: glowController,

                                glowAnimation: glowAnimation,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 60),

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
                      //         padding: const EdgeInsets.all(1.5),
                      //
                      //         decoration: BoxDecoration(
                      //           borderRadius: BorderRadius.circular(14),
                      //
                      //           gradient: LinearGradient(
                      //             colors: isDark
                      //                 ? [
                      //                     Colors.pinkAccent,
                      //                     Colors.orangeAccent,
                      //                     Colors.pinkAccent,
                      //                   ]
                      //                 : [
                      //                     Colors.blueAccent,
                      //                     Colors.cyanAccent,
                      //                     Colors.blueAccent,
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
                            if (vibrationOn) {HapticFeedback.lightImpact();}
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

                      const SizedBox(height: 30),
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

  ///old showSettingsMenu
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
  //                 ],
  //               );
  //             },
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget settingsTile({
  //   required IconData icon,
  //   required String title,
  //   required bool value,
  //   required Function(bool) onChanged,
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

  ///new showSettingsMenu
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

            //playVibration(130);
            if (vibrationOn) {HapticFeedback.lightImpact();}
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

            //playVibration(130);
            if (vibrationOn) {HapticFeedback.lightImpact();}
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
      ],
    );
  }

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
        if (vibrationOn) {HapticFeedback.lightImpact();}
        // 🔥 nothing needed
      },

      onPositive: () async {
        //playVibration(120);
        if (vibrationOn) {HapticFeedback.mediumImpact();}
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
  //       ? [Colors.blueAccent, Colors.cyanAccent]
  //       : [Colors.blueAccent, Colors.blueAccent];
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
    bool isPlayer = player == "You";

    bool isActive =
        !gameOver && ((playerTurn && isPlayer) || (!playerTurn && !isPlayer));

    List<Color> gradientColors = symbol == "X"
        ? [Colors.blueAccent, Colors.cyanAccent]
        : [Colors.orangeAccent, Colors.deepOrange];

    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        double glowValue = isActive ? glowAnimation.value : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),

            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: glowValue),
                      blurRadius: 16 * glowValue,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),

          child: Row(
            children: [
              // GRADIENT SYMBOL
              ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    colors: gradientColors,
                  ).createShader(rect);
                },

                child: Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                player,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  ///old
  // void showDifficultyMenu() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: isDark ? const Color(0xFF2B3A5A) : Colors.white,
  //
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //
  //     builder: (context) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //
  //         children: [
  //           const SizedBox(height: 16),
  //
  //           Text(
  //             "Select Difficulty",
  //             style: TextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //               color: isDark ? Colors.white : Colors.black,
  //             ),
  //           ),
  //
  //           const SizedBox(height: 10),
  //
  //           difficultyOption("Easy"),
  //           difficultyOption("Medium"),
  //           difficultyOption("Hard"),
  //
  //           const SizedBox(height: 20),
  //         ],
  //       );
  //     },
  //   );
  // }
  //
  Widget difficultyOption(String level) {
    return ListTile(
      leading: RadioGroup<String>(
        groupValue: difficulty,
        onChanged: (value) {
          setState(() {
            difficulty = value!;
          });

          Navigator.pop(context);
        },

        child: Radio<String>(
          value: level,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.green;
            }

            return isDark ? Colors.white : Colors.black;
          }),
        ),
      ),

      title: Text(
        level,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),

      onTap: () {
        setState(() {
          difficulty = level;
        });
        //playVibration(130);
        if (vibrationOn) {HapticFeedback.lightImpact();}
        Navigator.pop(context);
      },
    );
  }

  ///new
  void showDifficultyMenu() {
    showMenu(
      context: context,

      //position: const RelativeRect.fromLTRB(140, 85, 20, 0),
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2 - 110,

        85,

        MediaQuery.of(context).size.width / 2 - 110,

        0,
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
                  width: 200,

                  padding: const EdgeInsets.all(14),

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

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      buildDifficultyTile("Easy"),

                      const SizedBox(height: 10),

                      buildDifficultyTile("Medium"),

                      const SizedBox(height: 10),

                      buildDifficultyTile("Hard"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDifficultyTile(String level) {
    bool selected = difficulty == level;

    List<Color> glowColors;

    if (level == "Easy") {
      glowColors = [Colors.greenAccent, Colors.green];
    } else if (level == "Medium") {
      glowColors = [Colors.orangeAccent, Colors.deepOrange];
    } else {
      glowColors = [Colors.redAccent, Colors.pinkAccent];
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          difficulty = level;
        });

        //playVibration(130);
        if (vibrationOn) {HapticFeedback.lightImpact();}
        Navigator.pop(context);
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),

          gradient: selected ? LinearGradient(colors: glowColors) : null,

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
                    color: glowColors.first.withValues(alpha: 0.45),

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
                level,

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

                color: selected ? Colors.white : Colors.transparent,

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
                  ? Icon(Icons.check, size: 16, color: glowColors.first)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// end main class

///
// class WinLinePainter extends CustomPainter {
//   final List<int> line;
//   final double progress;
//
//   WinLinePainter(this.line, this.progress);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double cell = size.width / 3;
//
//     Map<int, Offset> positions = {
//       0: Offset(cell * 0.5, cell * 0.5),
//       1: Offset(cell * 1.5, cell * 0.5),
//       2: Offset(cell * 2.5, cell * 0.5),
//       3: Offset(cell * 0.5, cell * 1.5),
//       4: Offset(cell * 1.5, cell * 1.5),
//       5: Offset(cell * 2.5, cell * 1.5),
//       6: Offset(cell * 0.5, cell * 2.5),
//       7: Offset(cell * 1.5, cell * 2.5),
//       8: Offset(cell * 2.5, cell * 2.5),
//     };
//
//     Offset start = positions[line[0]]!;
//     Offset end = positions[line[2]]!;
//     Offset current = Offset.lerp(start, end, progress)!;
//
//     // GLOW PAINT
//     final glowPaint = Paint()
//       ..color = Colors.greenAccent.withValues(alpha: 0.7)
//       ..strokeWidth = 14
//       ..strokeCap = StrokeCap.round
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
//
//     // MAIN LINE
//     final linePaint = Paint()
//       ..color = Colors.greenAccent
//       ..strokeWidth = 6
//       ..strokeCap = StrokeCap.round;
//
//     // DRAW GLOW
//     canvas.drawLine(start, current, glowPaint);
//
//     // DRAW MAIN LINE
//     canvas.drawLine(start, current, linePaint);
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }

// class GameX extends StatelessWidget {
//   const GameX({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 40,
//       height: 40,
//       child: CustomPaint(painter: XPainter()),
//     );
//   }
// }

// Widget build3DIconButton(IconData icon, bool isDark) {
//   return Container(
//     padding: const EdgeInsets.all(10),
//     decoration: BoxDecoration(
//       color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF3F8),
//       shape: BoxShape.circle,
//       boxShadow: [
//         // light shadow
//         BoxShadow(
//           color: Colors.white.withOpacity(isDark ? 0.05 : 0.9),
//           offset: const Offset(-3, -3),
//           blurRadius: 6,
//         ),
//         // dark shadow
//         BoxShadow(
//           color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
//           offset: const Offset(3, 3),
//           blurRadius: 6,
//         ),
//       ],
//     ),
//     child: Icon(icon, color: Colors.blue, size: 20),
//   );
// }

///old
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
//           color: Colors.blueAccent.withValues(alpha: 0.4),
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
//             color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.9),
//             offset: const Offset(-3, -3),
//             blurRadius: 6,
//           ),
//           BoxShadow(
//             color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
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
