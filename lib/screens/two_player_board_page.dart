import 'dart:async';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:ui';
import '../../widgets/game_symbols.dart';
import '../widgets/build_circle_icon_button.dart';
import '../widgets/build_icon_text_button.dart';
import '../widgets/custom_toast.dart';
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
  /// Confetti animation controller
  late ConfettiController confettiController;

  /// Glow animation controller
  late AnimationController glowController;

  /// Glow animation value
  late Animation<double> glowAnimation;

  /// Winning line animation controller
  late AnimationController lineController;

  /// Winning line animation
  late Animation<double> lineAnimation;

  /// Turn timer animation controller
  late AnimationController timerController;

  /// Player 1 symbol
  String player1Symbol = "X";

  /// Player 2 symbol
  String player2Symbol = "O";

  /// Game result message
  String gameMessage = "";

  /// Current player turn
  bool player1Turn = true;

  /// Track first turn player
  bool isPlayer1First = true;

  /// Theme mode setting
  bool isDark = true;

  /// Sound setting
  bool soundOn = true;

  /// Vibration setting
  bool vibrationOn = true;

  /// Reset button press animation state
  bool resetPressed = false;

  /// Game board data
  List<String> board = List.filled(9, "");

  /// Game over state
  bool gameOver = false;

  /// Last played move index
  int lastMove = -1;

  /// Pressed cell index
  int pressedIndex = -1;

  /// Winning line indexes
  List<int>? winningLine;

  /// Player 1 score
  int player1Score = 0;

  /// Player 2 score
  int player2Score = 0;

  /// Turn timer enabled state
  bool timerEnabled = false;

  /// Turn timer duration
  int turnTime = 30;

  /// Current remaining time
  int currentTime = 30;

  /// Timer progress value
  late double progress = 1 - timerController.value;

  /// Time up state
  bool isTimeUp = false;

  /// Turn countdown timer
  Timer? turnTimer;

  /// Last timer alert second
  int lastAlertSecond = -1;

  /// Game started state
  bool hasGameStarted = false;

  /// Check game running state
  bool get isGameRunning {
    return board.any((e) => e != "") && !gameOver;
  }

  /// Current board size
  int boardSize = 3;

  /// Available board sizes
  final List<int> availableBoardSizes = [3, 4, 5, 6, 7, 8, 9];

  /// X sound player
  final AudioPlayer xPlayer = AudioPlayer();

  /// O sound player
  final AudioPlayer oPlayer = AudioPlayer();

  /// Winning sound player
  final AudioPlayer winPlayer = AudioPlayer();

  /// Clock ticking sound player
  final AudioPlayer clockSoundPlayer = AudioPlayer();

  /// Losing sound player
  final AudioPlayer losePlayer = AudioPlayer();

  /// Draw sound player
  final AudioPlayer drawPlayer = AudioPlayer();

  /// Get current turn text
  String getTurnText() {
    /// Return empty if game over
    if (gameOver) return "";

    /// Current player turn text
    return player1Turn ? "Player 1 Turn" : "Player 2 Turn";
  }

  @override
  void initState() {
    super.initState();

    /// Turn timer animation controller
    timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: turnTime),
    );

    /// Winning line animation controller
    lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    /// Winning line curve animation
    lineAnimation = CurvedAnimation(
      parent: lineController,
      curve: Curves.easeInOut,
    );

    /// Show player symbol selection dialog
    Future.delayed(Duration.zero, () {
      choosePlayerDialog();
    });

    /// Confetti animation controller
    confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    /// Glow animation controller
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    /// Glow animation value
    glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));

    /// Load saved settings
    loadSettings();

    /// First game starts with Player 1
    player1Turn = true; // first game always Player 1
  }

  @override
  void dispose() {
    /// Cancel turn timer
    turnTimer?.cancel();

    /// Dispose confetti controller
    confettiController.dispose();

    /// Dispose glow controller
    glowController.dispose();

    /// Dispose line controller
    lineController.dispose();

    /// Dispose timer controller
    timerController.dispose();

    /// Stop ticking sound
    stopTickingSound();
    super.dispose();
  }

  /// Load saved game settings
  Future loadSettings() async {
    /// Get SharedPreferences instance
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedSize = prefs.getInt("board_size") ?? 3;

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      soundOn = prefs.getBool("sound_on") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
      timerEnabled = prefs.getBool("timer_enabled") ?? true;
      boardSize = savedSize;

      /// Create board based on size
      board = List.filled(boardSize * boardSize, "");
    });
  }

  /// Stop timer ticking sound
  void stopTickingSound() {
    clockSoundPlayer.stop();
    lastAlertSecond = -1;
  }

  /// Get remaining timer seconds
  int getTimeLeft() {
    return (turnTime * (1 - timerController.value)).ceil();
  }

  /// Start turn countdown timer
  void startTurnTimer() {
    /// Cancel previous timer
    turnTimer?.cancel();
    lastAlertSecond = -1;
    setState(() {
      currentTime = turnTime;
    });

    timerController.reset();
    timerController.forward();

    /// Countdown timer
    turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentTime > 0) {
        setState(() {
          currentTime--;
        });
      } else {
        /// Time up condition
        timer.cancel();
        onTimeUp(); //  important
      }
    });
  }

  /// Handle player timeout
  void onTimeUp() {
    if (gameOver) return;
    stopTickingSound(); // ADD
    setState(() {
      gameOver = true;
      isTimeUp = true;

      /// Opponent wins on timeout
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

  /// Play X tap sound
  Future<void> playXSound() async {
    if (!soundOn) return;
    await xPlayer.stop();
    await xPlayer.play(AssetSource("audio/tap.mp3"));
  }

  /// Play O tap sound
  Future<void> playOSound() async {
    if (!soundOn) return;
    await oPlayer.stop();
    await oPlayer.play(AssetSource("audio/tap.mp3"));
  }

  /// Play winning sound
  Future<void> playWinSound() async {
    if (!soundOn) return;
    await winPlayer.stop();
    await winPlayer.play(AssetSource("audio/win.mp3"));
  }

  /// Play draw sound
  Future<void> playDrawSound() async {
    if (!soundOn) return;
    await drawPlayer.stop();
    await drawPlayer.play(AssetSource("audio/draw.mp3"));
  }

  /// Trigger device vibration
  Future<void> playVibration(int duration) async {
    if (!vibrationOn) return;

    /// Check vibration support
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: duration);
    }
  }

  /// Handle board cell tap
  void handleTap(int index) {
    /// Handle board cell tap
    if (board[index] != "" || gameOver) return;

    /// Start timer on first move
    if (!hasGameStarted) {
      hasGameStarted = true;

      if (timerEnabled) {
        startTurnTimer();
      }
    }

    /// Start press animation
    setState(() {
      pressedIndex = index;
    });

    /// Small delay for tap animation
    Future.delayed(const Duration(milliseconds: 120), () {
      setState(() {
        /// Reset pressed animation
        pressedIndex = -1;

        /// Place current player symbol
        if (player1Turn) {
          board[index] = player1Symbol;
        } else {
          board[index] = player2Symbol;
        }

        /// Store last move index
        lastMove = index;
      });

      /// Play X sound
      if (board[index] == "X") {
        playXSound();
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// Play O sound
      } else {
        playOSound();
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
      }

      /// Check game winner
      checkWinner();

      /// Switch player turn
      if (!gameOver) {
        setState(() {
          player1Turn = !player1Turn;
        });
        stopTickingSound();

        /// Restart timer for next turn
        if (timerEnabled) {
          startTurnTimer();
        }
      }
    });
  }

  /// Show player symbol selection dialog
  void choosePlayerDialog() {
    showGeneralDialog(
      context: context,

      /// Prevent outside tap close
      barrierDismissible: false,
      barrierLabel: "Symbol",

      /// Background overlay color
      barrierColor: Colors.black.withValues(alpha: 0.5),

      /// Dialog animation duration
      transitionDuration: const Duration(milliseconds: 250),

      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,

            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),

              child: BackdropFilter(
                /// Glass blur effect
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),

                child: Container(
                  width: 300,
                  height: 200,

                  /// Dialog padding
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    /// Glass gradient background
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

                    /// Shadow effects
                    boxShadow: [
                      /// Soft glow shadow
                      BoxShadow(
                        color: Colors.transparent.withValues(
                          alpha: isDark ? 0.10 : 0.06,
                        ),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),

                      /// Main depth shadow
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
                      /// Dialog title
                      Text(
                        "Choose Player 1 Symbol", // changed
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
                          /// X symbol button
                          GestureDetector(
                            onTap: () {
                              /// Light vibration feedback
                              if (vibrationOn) {
                                HapticFeedback.lightImpact();
                              }

                              /// Assign player symbols
                              setState(() {
                                player1Symbol = "X";
                                player2Symbol = "O";
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

                                /// X button border
                                border: Border.all(
                                  color: Colors.blueAccent,
                                  width: 1.5,
                                ),

                                /// Button shadow
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),

                              /// X symbol widget
                              child: const Center(child: GameX()),
                            ),
                          ),

                          /// O symbol button
                          GestureDetector(
                            onTap: () {
                              /// Light vibration feedback
                              if (vibrationOn) {
                                HapticFeedback.lightImpact();
                              }

                              /// Assign player symbols
                              setState(() {
                                player1Symbol = "O";
                                player2Symbol = "X";
                              });

                              /// Close dialog
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

                                /// O button border
                                border: Border.all(
                                  color: Colors.orangeAccent,
                                  width: 1.5,
                                ),

                                /// Button shadow
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),

                              /// O symbol widget
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

      /// Dialog opening animation
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(animation.value);

        return Transform.scale(
          scale: curvedValue,
          child: Opacity(opacity: animation.value, child: child),
        );
      },
    );
  }

  /// Show game result
  void showResult(bool? player1Win) {
    /// Player 1 win
    if (player1Win == true) {
      setState(() {
        gameMessage = "PLAYER 1 WINS";
      });

      playWinSound();
      playVibration(150);
      confettiController.play();

      /// Player 2 win
    } else if (player1Win == false) {
      setState(() {
        gameMessage = "PLAYER 2 WINS";
      });

      playWinSound();
      playVibration(150);
      confettiController.play();

      /// Draw match
    } else {
      setState(() {
        gameMessage = "DRAW";
      });

      playDrawSound();
      playVibration(150);
    }
  }

  /// Check game winner
  void checkWinner() {
    int winLength;

    /// Set required win length
    if (boardSize <= 4) {
      winLength = boardSize;
    } else if (boardSize <= 6) {
      winLength = 4;
    } else {
      winLength = 5;
    }

    /// Current player symbol
    String currentPlayer = player1Turn ? player1Symbol : player2Symbol;

    /// Check all board cells
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        int index = row * boardSize + col;

        /// Skip unmatched cells
        if (board[index] != currentPlayer) {
          continue;
        }

        /// Horizontal check
        if (_checkDirection(row, col, 0, 1, currentPlayer, winLength)) {
          return;
        }

        /// Vertical check
        if (_checkDirection(row, col, 1, 0, currentPlayer, winLength)) {
          return;
        }

        /// Diagonal check
        if (_checkDirection(row, col, 1, 1, currentPlayer, winLength)) {
          return;
        }

        /// Reverse diagonal check
        if (_checkDirection(row, col, 1, -1, currentPlayer, winLength)) {
          return;
        }
      }
    }

    /// Draw condition
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

  /// Check winning direction
  bool _checkDirection(
    int row,
    int col,

    int rowDir,
    int colDir,

    String player,

    int winLength,
  ) {
    if (gameOver) return true;

    /// Store matched cells
    List<int> matched = [];

    for (int i = 0; i < winLength; i++) {
      int newRow = row + rowDir * i;

      int newCol = col + colDir * i;

      /// Check board boundary
      if (newRow < 0 ||
          newRow >= boardSize ||
          newCol < 0 ||
          newCol >= boardSize) {
        return false;
      }

      int index = newRow * boardSize + newCol;

      /// Stop if symbol mismatch
      if (board[index] != player) {
        return false;
      }

      matched.add(index);
    }

    /// Winning condition found
    stopTickingSound();

    setState(() {
      gameOver = true;

      /// Store winning cells
      winningLine = List<int>.from(matched);
    });

    /// Start winning line animation
    lineController.reset();
    lineController.forward();

    /// Update player score
    if (player == player1Symbol) {
      player1Score++;
    } else {
      player2Score++;
    }

    /// Show result after animation
    Future.delayed(const Duration(milliseconds: 900), () {
      showResult(player == player1Symbol);
    });

    return true;
  }

  /// Show reset confirmation dialog
  Future<void> showResetGameDialog() async {
    await showAppDialog(
      context: context,
      title: "RESET GAME",
      message: "Are you sure you want to reset the current match?",
      positiveText: "RESET",
      negativeText: "CANCEL",
      barrierDismissible: true,
      canPop: true,

      /// Reset button action
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.heavyImpact();
        }
        resetGame();
      },

      /// Cancel button action
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// dialog auto close
      },
    );
  }

  /// Reset current game
  void resetGame() {
    /// Stop timer sound
    stopTickingSound();
    setState(() {
      /// Reset timer states
      hasGameStarted = false;
      timerController.reset();
      isTimeUp = false;
      currentTime = 30;

      /// Alternate first player
      isPlayer1First = !isPlayer1First;
      player1Turn = isPlayer1First;

      /// Reset board data
      board = List.filled(boardSize * boardSize, "");
      winningLine = null;
      lastMove = -1;
      gameOver = false;
      gameMessage = "";
    });

    /// Reset line animation
    lineController.reset();

    /// Cancel running timer
    turnTimer?.cancel();
  }

  /// Show settings menu
  void showSettingsMenu() {
    showGlassSettingsMenu(
      context: context,
      isDark: isDark,
      items: [
        /// Theme setting
        SettingsMenuItem(
          affectsTheme: true,
          iconBuilder: (value) {
            return value ? Icons.dark_mode : Icons.light_mode;
          },
          title: "Dark Theme",
          value: isDark,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            if (vibrationOn) {
              HapticFeedback.lightImpact();
            }
            setState(() {
              isDark = value;
            });

            await prefs.setBool("theme_dark", isDark);
          },
        ),

        /// Sound setting
        SettingsMenuItem(
          iconBuilder: (value) {
            return value ? Icons.volume_up : Icons.volume_off;
          },
          title: "Sound",
          value: soundOn,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (vibrationOn) {
              HapticFeedback.lightImpact();
            }
            setState(() {
              soundOn = value;
            });
            await prefs.setBool("sound_on", soundOn);
          },
        ),

        /// Vibration setting
        SettingsMenuItem(
          iconBuilder: (value) {
            return value ? Icons.vibration : Icons.phonelink_erase;
          },
          title: "Vibration",
          value: vibrationOn,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (!vibrationOn) {
              HapticFeedback.lightImpact();
            }
            setState(() {
              vibrationOn = value;
            });
            await prefs.setBool("vibration_on", vibrationOn);
          },
        ),

        /// Timer setting
        SettingsMenuItem(
          iconBuilder: (value) {
            return value ? Icons.timer : Icons.timer_off;
          },
          title: "Timer",
          value: timerEnabled,

          /// Prevent timer change during game
          canChange: (value) {
            if (isGameRunning) {
              CustomToast.show(
                context: context,
                message: "Can't change during game.",
                isDark: isDark,
                icon: Icons.block_rounded,
                color: Colors.orange,
              );
              return false;
            }
            return true;
          },

          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (vibrationOn) {
              HapticFeedback.lightImpact();
            }
            setState(() {
              timerEnabled = value;
            });
            await prefs.setBool("timer_enabled", timerEnabled);
          },
        ),
      ],
    );
  }

  /// Show board size selection menu
  void showBoardSizeMenu() {
    /// Prevent size change during match
    if (isGameRunning) {
      CustomToast.show(
        context: context,
        message: "Can't change during match.",
        isDark: isDark,
        icon: Icons.block_rounded,
        color: Colors.orange,
      );

      return;
    }

    showMenu(
      context: context,

      /// Popup menu position
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2 - 75,
        85,
        MediaQuery.of(context).size.width / 2 - 75,
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
              /// Rounded popup corners
              borderRadius: BorderRadius.circular(22),

              child: BackdropFilter(
                /// Glass blur effect
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),

                child: Container(
                  width: 150,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),

                    /// Glass gradient background
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

                    /// Popup border
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),

                    /// Popup shadow
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

                  child: SizedBox(
                    height: 210,

                    /// Board size list
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 6,
                      ),

                      /// Auto scroll selected size
                      controller: ScrollController(
                        initialScrollOffset: (((boardSize - 3) * 58) - 58)
                            .clamp(0, double.infinity)
                            .toDouble(),
                      ),

                      physics: const BouncingScrollPhysics(),
                      itemCount: availableBoardSizes.length,
                      itemBuilder: (context, index) {
                        int size = availableBoardSizes[index];
                        bool selected = boardSize == size;

                        return GestureDetector(
                          /// Handle board size selection
                          onTap: () {
                            if (vibrationOn) {
                              HapticFeedback.lightImpact();
                            }

                            /// Reset timer states
                            hasGameStarted = false;
                            turnTimer?.cancel();
                            timerController.reset();
                            stopTickingSound();

                            /// Save board size
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setInt("board_size", size);
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

                            /// Close popup menu
                            Navigator.pop(context);
                          },

                          child: AnimatedContainer(
                            /// Selection animation
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 5),
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 5,
                              top: 5,
                              bottom: 5,
                            ),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),

                              /// Selected gradient
                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [
                                        Colors.blueAccent,
                                        Colors.cyanAccent,
                                      ],
                                    )
                                  : null,

                              /// Default background
                              color: selected
                                  ? null
                                  : isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.55),

                              /// Border style
                              border: Border.all(
                                color: selected
                                    ? Colors.transparent
                                    : isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),

                              /// Selected glow effect
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
                                /// Board size text
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

                                /// Selected indicator
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

                                  /// Check icon
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
    /// Board background color
    Color boardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;

    /// Cell background color
    Color cellColor = isDark
        ? const Color(0xFF1F2A44)
        : const Color(0xFFF0F0F0);

    /// Main text color
    Color textColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      /// Allow back only if game not running
      canPop: (gameOver || !board.any((e) => e != "")),

      /// Handle system back press
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        /// Show exit dialog during match
        if (!gameOver && board.any((e) => e != "")) {
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }
          await showExitDialog();
        } else {
          /// Direct back action
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },

      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          /// AppBar background color
          backgroundColor: isDark ? Color(0xFF2B3A5A) : Color(0xFFF5F5F0),
          elevation: 0,

          flexibleSpace: Container(
            /// AppBar gradient background
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

          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Tooltip(
              message: "Back",
              child: GestureDetector(
                /// Handle back button tap
                onTap: () async {
                  /// Show exit dialog during match
                  if (!gameOver && board.any((e) => e != "")) {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }
                    await showExitDialog();
                  } else {
                    /// Direct back action
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }

                    /// Custom back button
                    Navigator.pop(context);
                  }
                },

                /// Custom back button
                child: build3DIconButton(
                  icon: Icons.arrow_back,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          /// Board size selector
          title: GestureDetector(
            /// Open board size menu
            onTap: () {
              showBoardSizeMenu();
              if (vibrationOn) {
                HapticFeedback.mediumImpact();
              }
            },

            child: Container(
              padding: const EdgeInsets.all(1.5),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                /// Gradient border
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Colors.blueAccent, Colors.cyanAccent],
                      )
                    : const LinearGradient(
                        colors: [Colors.blue, Colors.indigo],
                      ),
              ),

              child: Container(
                /// Inner button padding
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  /// Inner background
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2B3A5A), const Color(0xFF2B3A5A)]
                        : [Colors.white, Colors.white],
                  ),

                  /// Glow shadow
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
                    /// Current board size text
                    Text(
                      "$boardSize x $boardSize",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 4),

                    /// Dropdown icon
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
            /// Draw board button
            Padding(
              padding: const EdgeInsets.only(right: 8),

              /// long press tooltip
              child: Tooltip(
                message: "Draw Board",

                child: GestureDetector(
                  /// Open draw board screen
                  onTap: () {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DrawBoardPage()),
                    );
                  },
                  child: build3DIconButton(icon: Icons.gesture, isDark: isDark),
                ),
              ),
            ),

            /// Settings button
            Padding(
              /// Open settings menu
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: "Settings",
                child: GestureDetector(
                  onTap: () {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }
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
            /// Background gradient
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

            /// Confetti animation
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
                  /// Main screen padding
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      /// Score section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// Player 1 score
                          scoreBox(
                            "Player 1",
                            player1Symbol,
                            boardColor,
                            textColor,
                          ),

                          /// Center score card
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

                          /// Player 2 score
                          scoreBox(
                            "Player 2",
                            player2Symbol,
                            boardColor,
                            textColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Timer countdown text
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

                      /// Time up message
                      if (timerEnabled && gameOver && isTimeUp)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Time's Up!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),

                      const SizedBox(height: 00),

                      /// Current player turn text
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

                      /// Result message animation
                      if (gameMessage != "")
                        TweenAnimationBuilder(
                          /// Result animation duration
                          duration: const Duration(milliseconds: 500),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, double value, child) {
                            /// Result card color
                            Color cardColor = isDark
                                ? const Color(0xFF2B3A5A)
                                : Colors.white;

                            /// Result gradient colors
                            List<Color> gradientColors =
                                gameMessage.contains("WIN")
                                ? [Colors.greenAccent, Colors.blueAccent]
                                : [Colors.orangeAccent, Colors.yellow];

                            return AnimatedBuilder(
                              /// Glow animation listener
                              animation: glowAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  /// Fade animation
                                  opacity: value,

                                  child: Transform.translate(
                                    /// Slide from top animation
                                    offset: Offset(0, -40 * (1 - value)),

                                    /// slide from top
                                    child: Transform.scale(
                                      /// Pop animation effect
                                      scale: 0.95 + (0.05 * value),

                                      /// slight pop
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(2),

                                        decoration: BoxDecoration(
                                          /// Gradient border
                                          gradient: LinearGradient(
                                            colors: gradientColors,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),

                                          /// Glow shadow effect
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
                                              /// Outline gradient text
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

                                              /// Main glowing text
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

                      /// Game board section
                      SizedBox(
                        height: 320,
                        //height: boardPixelSize + 40,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 320,
                            height: 320,

                            /// Outer border padding
                            padding: const EdgeInsets.all(1.5),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),

                              /// Board gradient border
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.blueAccent,
                                        Colors.deepOrangeAccent,
                                        Colors.blueAccent,
                                      ]
                                    : [
                                        Colors.blueAccent,
                                        Colors.deepOrangeAccent,
                                        Colors.blueAccent,
                                      ],
                              ),

                              boxShadow: [
                                /// Outer glow effect
                                BoxShadow(
                                  color:
                                      (isDark
                                              ? Colors.blueAccent
                                              : Colors.blueAccent)
                                          .withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),

                                /// 3D depth shadow
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: const Offset(4, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),

                            child: Container(
                              /// Inner board padding
                              padding: EdgeInsets.all(boardSize <= 5 ? 8 : 5),
                              decoration: BoxDecoration(
                                color: boardColor,
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Stack(
                                children: [
                                  /// Dynamic game grid
                                  GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: board.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          /// Grid size based on board size
                                          crossAxisCount: boardSize,

                                          childAspectRatio: 1,
                                        ),

                                    itemBuilder: (context, index) {
                                      /// Highlight last move
                                      bool highlight = index == lastMove;

                                      /// Highlight winning cells
                                      bool win =
                                          winningLine != null &&
                                          winningLine!.contains(index);

                                      return GestureDetector(
                                        /// Handle cell tap
                                        onTap: () => handleTap(index),

                                        child: AnimatedScale(
                                          /// Press animation effect
                                          scale: pressedIndex == index
                                              ? 0.92
                                              : 1,
                                          duration: const Duration(
                                            milliseconds: 120,
                                          ),

                                          child: Container(
                                            /// Dynamic cell spacing
                                            margin: EdgeInsets.all(
                                              boardSize <= 4
                                                  ? 6
                                                  : boardSize <= 6
                                                  ? 4
                                                  : 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cellColor,

                                              /// Dynamic corner radius
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    boardSize <= 5 ? 12 : 8,
                                                  ),

                                              /// Cell border
                                              border: board[index] != ""
                                                  ? Border.all(
                                                      color: isDark
                                                          ? Color(0xFF47798A)
                                                          : Color(0xFF9ED3E8),
                                                      width: 1,
                                                    )
                                                  : null,

                                              /// Highlight shadows
                                              boxShadow: [
                                                /// Last move glow
                                                if (highlight)
                                                  const BoxShadow(
                                                    color: Colors.blueAccent,
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),

                                                /// Winning glow
                                                if (win)
                                                  const BoxShadow(
                                                    color: Colors.green,
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                              ],
                                            ),

                                            child: Center(
                                              /// Show X or O symbol
                                              child: board[index] == "X"
                                                  ? GameX(
                                                      /// Dynamic X size
                                                      size: boardSize <= 3
                                                          ? 40
                                                          : boardSize <= 5
                                                          ? 26
                                                          : boardSize <= 7
                                                          ? 18
                                                          : 12,
                                                    )
                                                  : board[index] == "O"
                                                  ? GameO(
                                                      /// Dynamic O size
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

                                  /// Winning line animation
                                  if (winningLine != null)
                                    AnimatedBuilder(
                                      animation: lineAnimation,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          /// Dynamic paint area size
                                          size: Size(
                                            320 - (boardSize <= 5 ? 16 : 10),

                                            320 - (boardSize <= 5 ? 16 : 10),
                                          ),

                                          /// Draw winning line
                                          painter: WinLinePainter(
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

                      /// Game over action buttons
                      if (gameOver)
                        Padding(
                          /// Top spacing for buttons
                          padding: const EdgeInsets.only(top: 20),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              /// Home button
                              NeonGlowingButton(
                                text: "Home",
                                icon: Icons.home,
                                onTap: () {
                                  /// Medium vibration feedback
                                  if (vibrationOn) {
                                    HapticFeedback.mediumImpact();
                                  }

                                  /// Back to previous screen
                                  Navigator.pop(context);
                                },
                                isDark: isDark,

                                glowController: glowController,
                                glowAnimation: glowAnimation,
                              ),

                              /// Replay button
                              NeonGlowingButton(
                                text: "Replay",
                                icon: Icons.refresh,
                                onTap: () {
                                  /// Medium vibration feedback
                                  if (vibrationOn) {
                                    HapticFeedback.mediumImpact();
                                  }

                                  /// Restart current match
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

                      /// Reset game button
                      if (!gameOver && board.any((e) => e != ""))
                        GestureDetector(
                          /// Start press animation
                          onTapDown: (_) {
                            setState(() {
                              resetPressed = true;
                            });
                          },

                          /// Handle reset button tap
                          onTapUp: (_) {
                            setState(() {
                              resetPressed = false;
                            });

                            /// Show reset confirmation dialog
                            showResetGameDialog();

                            /// Light vibration feedback
                            if (vibrationOn) {
                              HapticFeedback.lightImpact();
                            }
                          },

                          /// Reset press animation state
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

                              /// Custom reset button
                              child: BuildIconTextButton(
                                icon: Icons.refresh,
                                text: "Reset Game",
                                isDark: isDark,
                                borderRadius: BorderRadius.circular(14),

                                /// Button shadow
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

            /// Front layer confetti
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

  /// Show exit confirmation dialog
  Future<void> showExitDialog() async {
    await showAppDialog(
      context: context,
      title: "EXIT MATCH",
      message: "Exit and end the match?",
      positiveText: "EXIT",
      negativeText: "CANCEL",
      barrierDismissible: true,
      canPop: true,

      /// Cancel button action
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        // nothing needed
      },

      /// Exit button action
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }

        /// Stop timer sound
        stopTickingSound();

        /// Close current screen
        Navigator.pop(context);
      },
    );
  }

  /// Player score widget
  Widget scoreBox(String player, String symbol, Color bg, Color textColor) {
    /// Border color based on symbol
    Color borderColor = symbol == "X" ? Colors.blueAccent : Colors.orangeAccent;

    /// Check player type
    bool isPlayer1 = player == "Player 1";

    /// Active player condition
    bool isActive =
        !gameOver &&
        ((player1Turn && isPlayer1) || (!player1Turn && !isPlayer1));

    /// Symbol gradient colors
    List<Color> gradientColors = symbol == "X"
        ? [Colors.blueAccent, Colors.cyanAccent]
        : [Colors.orangeAccent, Colors.deepOrange];

    return AnimatedBuilder(
      /// Glow animation listener
      animation: glowAnimation,
      builder: (context, child) {
        /// Active glow value
        double glowValue = isActive ? glowAnimation.value : 0;

        return Stack(
          children: [
            /// Main score box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),

                /// Active glow effect
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
                  /// Gradient symbol text
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

                  /// Player name text
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

            /// Timer border animation
            if (isActive && timerEnabled)
              Positioned.fill(
                child: AnimatedBuilder(
                  /// Timer animation listener
                  animation: timerController,
                  builder: (context, child) {
                    int timeLeft = getTimeLeft();

                    /// Last 5 second alert
                    if (timeLeft <= 5 && timeLeft > 0) {
                      if (timeLeft != lastAlertSecond) {
                        lastAlertSecond = timeLeft;

                        /// Tick sound effect
                        if (soundOn) {
                          clockSoundPlayer.stop(); // avoid overlap
                          clockSoundPlayer.play(AssetSource("audio/tick.mp3"));
                        }

                        /// Timer vibration alert
                        if (vibrationOn) {
                          HapticFeedback.mediumImpact();
                        }
                      }
                    }

                    return CustomPaint(
                      /// Animated timer border
                      painter: TimerBorderPainter(
                        /// Reverse progress animation
                        1 - timerController.value, // smooth reverse
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
  /// Timer progress value
  final double progress;

  /// Border color
  final Color color;

  TimerBorderPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    /// Border drawing area
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    /// Border paint style
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    /// Rounded border path
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));

    /// Extract animated border path
    final metric = path.computeMetrics().first;
    final extractPath = metric.extractPath(0, metric.length * progress);

    /// Draw animated timer border
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant TimerBorderPainter oldDelegate) {
    /// Repaint on progress or color change
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
