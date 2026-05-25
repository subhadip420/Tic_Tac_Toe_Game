import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:vibration/vibration.dart';
import 'dart:ui';
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
  // AUDIO PLAYERS
  final AudioPlayer xPlayer = AudioPlayer(); // X sound
  final AudioPlayer oPlayer = AudioPlayer(); // O sound

  final AudioPlayer winPlayer = AudioPlayer(); // Win sound
  final AudioPlayer losePlayer = AudioPlayer(); // Lose sound
  final AudioPlayer drawPlayer = AudioPlayer(); // Draw sound

  /// ANIMATION
  late AnimationController glowController;
  late Animation<double> glowAnimation;

  late ConfettiController confettiController;

  /// GAME MESSAGE
  String gameMessage = "";

  /// SYMBOLS
  String playerSymbol = "X";
  String botSymbol = "O";

  /// DIFFICULTY
  String difficulty = "Easy";

  /// SCORE
  int playerScore = 0;
  int aiScore = 0;

  /// SETTINGS
  bool isDark = true;
  bool soundOn = true;
  bool vibrationOn = true;

  /// GAME STATE
  bool gameOver = false;
  bool playerTurn = true;

  /// BOARD
  List<String> board = List.filled(9, "");

  List<int>? winningLine;

  int lastMove = -1;
  int pressedIndex = -1;

  /// UI STATE
  bool resetPressed = false;

  @override
  void initState() {
    super.initState();

    /// Winning line animation controller
    lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    /// Smooth curve animation for winning line effect
    lineAnimation = CurvedAnimation(
      parent: lineController,
      curve: Curves.easeInOut,
    );

    /// Load saved app settings
    loadSettings();

    /// Open symbol selection dialog (X or O)
    Future.delayed(Duration.zero, () {
      chooseSymbolDialog();
    });

    /// Confetti animation controller
    confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    /// Glow animation controller
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    /// Glow animation values
    glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    /// Dispose glow animation controller
    glowController.dispose();

    /// Dispose confetti animation controller
    confettiController.dispose();

    /// Dispose winning line animation controller
    lineController.dispose();
    super.dispose();
  }

  /// Load saved app settings from SharedPreferences
  Future loadSettings() async {
    /// Get SharedPreferences instance
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      /// Load saved theme mode
      isDark = prefs.getBool("theme_dark") ?? true;

      /// Load sound setting
      soundOn = prefs.getBool("sound_on") ?? true;

      /// Load vibration setting
      vibrationOn = prefs.getBool("vibration_on") ?? true;
    });
  }

  /// Show symbol selection dialog
  void chooseSymbolDialog() {
    showGeneralDialog(
      /// Current screen context
      context: context,
      barrierDismissible: false,

      /// Prevent closing dialog by tapping outside
      barrierLabel: "Symbol",

      /// Background overlay color
      barrierColor: Colors.black.withValues(alpha: 0.5),

      /// Dialog opening animation duration
      transitionDuration: const Duration(milliseconds: 250),

      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            /// Transparent material background
            color: Colors.transparent,

            child: ClipRRect(
              /// Rounded dialog corners
              borderRadius: BorderRadius.circular(28),

              child: BackdropFilter(
                /// Glass blur effect
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),

                child: Container(
                  width: 300,
                  height: 200,

                  /// Inner padding of dialog
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    /// Glassmorphism gradient background
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

                    /// Rounded container corners
                    borderRadius: BorderRadius.circular(28),

                    /// Glass border effect
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.18 : 0.35,
                      ),
                      width: 1.5,
                    ),

                    /// Dialog shadow effects
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
                          /// X symbol selection button
                          GestureDetector(
                            onTap: () {
                              /// Medium vibration feedback
                              //playVibration(120);
                              if (vibrationOn) {
                                HapticFeedback.mediumImpact();
                              }

                              /// Set player and bot symbols
                              setState(() {
                                playerSymbol = "X";
                                botSymbol = "O";
                              });

                              /// Close dialog
                              Navigator.pop(context);
                            },

                            child: Container(
                              width: 90,
                              height: 90,

                              decoration: BoxDecoration(
                                color: isDark
                                    /// Button background color
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

                          /// O symbol selection button
                          GestureDetector(
                            onTap: () {
                              /// Medium vibration feedback
                              //playVibration(120);
                              if (vibrationOn) {
                                HapticFeedback.mediumImpact();
                              }

                              /// Set player and bot symbols
                              setState(() {
                                playerSymbol = "O";
                                botSymbol = "X";
                              });

                              /// Close dialog
                              Navigator.pop(context);
                            },

                            child: Container(
                              width: 90,
                              height: 90,

                              decoration: BoxDecoration(
                                /// Button background color
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

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        /// Apply smooth popup animation curve
        final curvedValue = Curves.easeOutBack.transform(animation.value);

        return Transform.scale(
          /// Dialog scale animation value
          scale: curvedValue,

          /// Fade animation effect
          child: Opacity(opacity: animation.value, child: child),
        );
      },
    );
  }

  /// Handle player tap on board cell
  void handleTap(int index) {
    /// Prevent tapping on filled cell,
    /// bot turn, or game over state
    if (board[index] != "" || !playerTurn || gameOver) return;

    setState(() {
      /// Store pressed cell index for tap animation
      pressedIndex = index;
    });

    /// Small delay for tap animation effect
    Future.delayed(const Duration(milliseconds: 120), () {
      setState(() {
        /// Reset pressed animation state
        pressedIndex = -1;

        /// Place player symbol on board
        board[index] = playerSymbol;

        /// Store last played move index
        lastMove = index;

        /// Switch turn to bot
        playerTurn = false;
      });

      /// Play X sound effect
      if (playerSymbol == "X") {
        playXSound();
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// Play O sound effect
      } else {
        playOSound();
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
      }

      /// Check game winner after player move
      checkWinner();

      /// Trigger AI move if game not finished
      if (!gameOver) {
        Future.delayed(const Duration(milliseconds: 500), aiMove);
      }
    });
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

  /// Play winner sound effect
  Future playWinSound() async {
    if (!soundOn) return;
    await winPlayer.stop();
    await winPlayer.play(AssetSource("audio/win.mp3"));
  }

  /// Play losing sound effect
  Future playLoseSound() async {
    if (!soundOn) return;
    await losePlayer.stop();
    await losePlayer.play(AssetSource("audio/lose.mp3"));
  }

  /// Play draw sound
  Future playDrawSound() async {
    if (!soundOn) return;
    await drawPlayer.stop();
    await drawPlayer.play(AssetSource("audio/draw.mp3"));
  }

  /// Trigger device vibration
  Future playVibration(int duration) async {

    /// Stop if vibration is disabled
    if (!vibrationOn) return;

    /// Check device vibration support
    final hasVibrator =
    await Vibration.hasVibrator();

    if (hasVibrator == true) {

      /// Trigger vibration
      Vibration.vibrate(duration: duration);
    }
  }

  /// AI bot move handler
  void aiMove() {
    if (gameOver) return;

    int move;

    /// Easy difficulty → random moves
    if (difficulty == "Easy") {
      move = getRandomMove();

      /// Medium difficulty → random + smart moves
    } else if (difficulty == "Medium") {
      if (Random().nextBool()) {
        move = getBestMove();
      } else {
        move = getRandomMove();
      }

      /// Hard difficulty → best move only
    } else {
      move = getBestMove();
    }

    setState(() {
      board[move] = botSymbol;
      lastMove = move;
      playerTurn = true;
    });

    /// Play X sound effect
    if (botSymbol == "X") {
      playXSound();
      if (vibrationOn) {
        HapticFeedback.lightImpact();
      }

      /// Play O sound effect
    } else {
      playOSound();
      if (vibrationOn) {
        HapticFeedback.lightImpact();
      }
    }

    /// Check winner after bot move
    checkWinner();
  }

  /// Check game winner or draw condition
  void checkWinner() {
    /// All possible winning combinations
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
          /// Store winning line indexes
          winningLine = combo;

          /// Stop further gameplay
          gameOver = true;
        });

        /// Reset winning line animation
        lineController.reset();

        /// Start winning line animation
        lineController.forward();

        /// Delay result dialog for animation completion
        Future.delayed(const Duration(milliseconds: 900), () {
          /// Player win condition
          if (board[combo[0]] == playerSymbol) {
            playerScore++;
            showResult(true);

            /// AI win condition
          } else {
            aiScore++;

            /// Show lose result dialog
            showResult(false);
          }
        });

        return;
      }
    }

    /// Draw match condition
    if (!board.contains("") && winningLine == null) {
      gameOver = true;

      /// Small delay before showing draw dialog
      Future.delayed(const Duration(milliseconds: 400), () {
        /// Show draw result dialog
        showResult(null);
      });
    }
  }

  /// Show game result
  void showResult(bool? playerWin) {
    setState(() {
      /// Player win condition
      if (playerWin == true) {
        gameMessage = " YOU WIN ";
        playWinSound();
        playVibration(200);
        confettiController.play();

        /// Player lose condition
      } else if (playerWin == false) {
        gameMessage = " YOU LOSE ";
        playLoseSound();
        playVibration(180);

        /// Draw match condition
      } else {
        gameMessage = " DRAW ";
        playDrawSound();
        playVibration(150);
      }
    });
  }

  /// Check if game has started
  bool get gameStarted {
    return board.contains("X") || board.contains("O");
  }

  /// Show reset game confirmation dialog
  Future<void> showResetGameDialog() async {
    await showAppDialog(
      context: context,
      title: "RESET GAME",
      message: "Are you sure you want to reset the current match?",
      positiveText: "RESET",
      negativeText: "CANCEL",

      /// Allow outside tap to close dialog
      barrierDismissible: true,

      /// Allow back button close
      canPop: true,

      /// Reset button callback
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        resetGame();
      },

      /// Cancel button callback
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// dialog auto close
      },
    );
  }

  /// Reset current game state
  void resetGame() {
    setState(() {
      board = List.filled(9, "");
      winningLine = null;
      lastMove = -1;
      playerTurn = true;
      gameOver = false;
      gameMessage = "";
    });

    /// Reset winning line animation
    lineController.reset();
  }

  int getRandomMove() {
    List<int> empty = [];
    for (int i = 0; i < 9; i++) {
      /// Check empty board position
      if (board[i] == "") empty.add(i);
    }

    /// Shuffle empty positions
    empty.shuffle();

    /// Return random empty position
    return empty.first;
  }

  /// Find best AI move using minimax
  int getBestMove() {
    int bestScore = -1000;
    int move = -1;

    for (int i = 0; i < 9; i++) {
      /// Check empty board position
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

    /// Return best move index
    return move;
  }

  /// Minimax algorithm for AI decision making
  int minimax(List<String> newBoard, int depth, bool isMaximizing) {
    /// Check board winner result
    String? result = checkWinnerForAI(newBoard);

    /// Return score based on result
    if (result != null) {
      if (result == botSymbol) return 10 - depth;
      if (result == playerSymbol) return depth - 10;
      return 0;
    }

    /// Maximizing bot turn
    if (isMaximizing) {
      int bestScore = -1000;

      for (int i = 0; i < 9; i++) {
        if (newBoard[i] == "") {
          newBoard[i] = botSymbol;
          int score = minimax(newBoard, depth + 1, false);
          newBoard[i] = "";

          /// Store minimum score
          bestScore = max(score, bestScore);
        }
      }

      return bestScore;

      /// Minimizing player turn
    } else {
      int bestScore = 1000;

      for (int i = 0; i < 9; i++) {
        if (newBoard[i] == "") {
          newBoard[i] = playerSymbol;

          /// Recursive minimax call
          int score = minimax(newBoard, depth + 1, true);
          newBoard[i] = "";
          bestScore = min(score, bestScore);
        }
      }
      return bestScore;
    }
  }

  /// Check winner for AI minimax algorithm
  String? checkWinnerForAI(List<String> b) {
    /// All possible winning combinations
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
      /// Check if all 3 positions contain same symbol
      if (b[combo[0]] != "" &&
          b[combo[0]] == b[combo[1]] &&
          b[combo[1]] == b[combo[2]]) {
        return b[combo[0]];
      }
    }

    /// Check draw condition
    if (!b.contains("")) return "draw";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    //Color bgColor = isDark ? const Color(0xFF1F2A44) : const Color(0xFFF5F5F5);
    /// Board background color
    Color boardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;

    /// Cell background color
    Color cellColor = isDark
        ? const Color(0xFF1F2A44)
        : const Color(0xFFF0F0F0);

    /// Main text color
    Color textColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      /// Allow back press only if game over
      canPop: (gameOver || !board.any((e) => e != "")),

      /// Handle back button action
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        /// Match running condition
        if (!gameOver && board.any((e) => e != "")) {
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }

          /// Show exit confirmation dialog
          await showExitDialog();
        } else {
          /// Direct back action
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }

          /// Close current screen
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },

      child: Scaffold(
        /// Transparent scaffold background
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          ///  AppBar background color
          backgroundColor: isDark ? Color(0xFF2B3A5A) : Color(0xFFF5F5F0),
          //backgroundColor: Colors.transparent,
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
                  /// Match running condition
                  if (!gameOver && board.any((e) => e != "")) {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }

                    /// Show exit confirmation dialog
                    await showExitDialog();
                  } else {
                    /// Direct back action
                    //playVibration(120);
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }
                    Navigator.pop(context);
                  }
                },

                /// Custom 3D back button
                child: build3DIconButton(
                  icon: Icons.arrow_back,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          title: GestureDetector(
            /// Handle difficulty button tap
            onTap: () {
              /// Prevent difficulty change during match
              if (gameStarted && !gameOver) {
                /// Show warning toast
                CustomToast.show(
                  context: context,
                  message: "Finish Match First",
                  isDark: isDark,
                  //icon: Icons.lock_clock_rounded,
                  color: Colors.orange,
                );

                if (vibrationOn) {
                  HapticFeedback.mediumImpact();
                }
                return;
              }

              /// Open difficulty selection menu
              showDifficultyMenu();
              if (vibrationOn) {
                HapticFeedback.mediumImpact();
              }
            },

            child: Container(
              /// Outer gradient border container
              padding: const EdgeInsets.all(1.5), // 🔥 border thickness

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                /// Difficulty button gradient border
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

                  /// Inner background gradient
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Color(0xFF2B3A5A), Color(0xFF2B3A5A)]
                        : [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                  ),

                  /// Glow shadow effect
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
                    /// Current difficulty text
                    Text(
                      difficulty,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(width: 4),

                    /// Dropdown arrow icon
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

          /// Keep title in center
          centerTitle: true,

          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: "Settings",
                child: GestureDetector(
                  /// Open settings menu
                  onTap: () {
                    if (vibrationOn) {
                      HapticFeedback.mediumImpact();
                    }
                    showSettingsMenu();
                  },

                  /// Custom settings button
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

            /// Confetti animation widget
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
                /// Main screen padding
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      /// SCORE SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// Player score box
                          scoreBox("You", playerSymbol, boardColor, textColor),

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
                              "$playerScore - $aiScore",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          /// AI score box
                          scoreBox("AI", botSymbol, boardColor, textColor),
                        ],
                      ),

                      const SizedBox(height: 40),

                      /// Turn indicator text
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

                      /// Result message widget
                      if (gameMessage != "")
                        TweenAnimationBuilder(
                          /// Result popup animation
                          duration: const Duration(milliseconds: 450),
                          tween: Tween<double>(begin: 0.85, end: 1),
                          curve: Curves.easeOutBack,
                          builder: (context, double scale, child) {
                            /// Result card background color
                            Color cardColor = isDark
                                ? const Color(0xFF2B3A5A)
                                : Colors.white;

                            List<Color> gradientColors;

                            /// Win message colors
                            if (gameMessage.contains("WIN")) {
                              gradientColors = [
                                Colors.greenAccent,
                                Colors.blueAccent,
                              ];

                              /// Lose message colors
                            } else if (gameMessage.contains("LOSE")) {
                              gradientColors = [
                                Colors.redAccent,
                                Colors.orange,
                              ];

                              /// Draw message colors
                            } else {
                              gradientColors = [
                                Colors.orangeAccent,
                                Colors.yellow,
                              ];
                            }

                            return AnimatedBuilder(
                              /// Glow animation listener
                              animation: glowAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  /// Scale animation effect
                                  scale: scale,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(2),

                                    decoration: BoxDecoration(
                                      /// Animated gradient border
                                      gradient: LinearGradient(
                                        colors: gradientColors,
                                      ),
                                      borderRadius: BorderRadius.circular(20),

                                      /// Glow shadow effect
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
                                          /// Gradient border text
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

                                          /// Main glowing text
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

                      /// Game board section
                      SizedBox(
                        height: 320,

                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 280,
                            height: 280,

                            /// Outer border padding
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),

                              /// Board gradient border
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.blueAccent,
                                        Colors.orangeAccent,
                                        Colors.blueAccent,
                                      ]
                                    : [
                                        Colors.blueAccent,
                                        Colors.deepOrange,
                                        Colors.blueAccent,
                                      ],
                              ),

                              /// Glow and depth shadow
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: boardColor,
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Stack(
                                children: [
                                  /// Tic Tac Toe grid
                                  GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: 9,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
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
                                            margin: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: cellColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),

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
                                              /// Display X or O symbol
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

                                  /// Winning line animation
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
                                  /// Heavy vibration feedback
                                  if (vibrationOn) {
                                    HapticFeedback.heavyImpact();
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

                      const SizedBox(height: 60),

                      /// Reset game button
                      if (!gameOver && board.any((e) => e != ""))
                        GestureDetector(
                          /// Button press animation start
                          onTapDown: (_) {
                            setState(() {
                              resetPressed = true;
                            });
                          },

                          /// Button release action
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

                          /// Reset press state on cancel
                          onTapCancel: () {
                            setState(() {
                              resetPressed = false;
                            });
                          },

                          child: AnimatedScale(
                            /// Press scale animation
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

                                /// Button shadow effect
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

            /// Front layer confetti animation
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

  /// Show settings bottom menu
  void showSettingsMenu() {
    showGlassSettingsMenu(
      context: context,
      isDark: isDark,

      items: [
        /// Theme mode setting
        SettingsMenuItem(
          affectsTheme: true,

          /// Theme icon based on current mode
          iconBuilder: (value) {
            return value ? Icons.dark_mode : Icons.light_mode;
          },

          /// Current theme state
          title: "Dark Theme",
          value: isDark,
          onChanged: (value) async {
            /// Get SharedPreferences instance
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (vibrationOn) {
              HapticFeedback.lightImpact();
            }

            /// Update theme state
            setState(() {
              isDark = value;
            });

            /// Save theme setting
            await prefs.setBool("theme_dark", isDark);
          },
        ),

        /// Sound setting
        SettingsMenuItem(
          /// Sound icon based on state
          iconBuilder: (value) {
            return value ? Icons.volume_up : Icons.volume_off;
          },

          title: "Sound",
          value: soundOn,
          onChanged: (value) async {
            /// Get SharedPreferences instance
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (vibrationOn) {
              HapticFeedback.lightImpact();
            }

            /// Update sound state
            setState(() {
              soundOn = value;
            });
            await prefs.setBool("sound_on", soundOn);
          },
        ),

        /// Vibration setting
        SettingsMenuItem(
          iconBuilder: (value) {
            /// Vibration icon based on state
            return value ? Icons.vibration : Icons.phonelink_erase;
          },

          title: "Vibration",
          value: vibrationOn,
          onChanged: (value) async {
            /// Get SharedPreferences instance
            SharedPreferences prefs = await SharedPreferences.getInstance();

            /// Vibration feedback before disabling
            if (!vibrationOn) {
              HapticFeedback.lightImpact();
            }

            /// Save vibration setting
            setState(() {
              vibrationOn = value;
            });
            await prefs.setBool("vibration_on", vibrationOn);
          },
        ),
      ],
    );
  }

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
      },

      /// Exit button action
      onPositive: () async {
        //playVibration(120);
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }

        /// Close current screen
        Navigator.pop(context);
      },
    );
  }

  /// Score display widget
  Widget scoreBox(String player, String symbol, Color bg, Color textColor) {
    /// Check current player
    bool isPlayer = player == "You";

    /// Active turn highlight condition
    bool isActive =
        !gameOver && ((playerTurn && isPlayer) || (!playerTurn && !isPlayer));

    /// Symbol gradient colors
    List<Color> gradientColors = symbol == "X"
        ? [Colors.blueAccent, Colors.cyanAccent]
        : [Colors.orangeAccent, Colors.deepOrange];

    return AnimatedBuilder(
      /// Glow animation listener
      animation: glowAnimation,
      builder: (context, child) {
        /// Active glow intensity
        double glowValue = isActive ? glowAnimation.value : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),

            /// Active player glow effect
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              /// Player name text
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

  /// Difficulty selection option tile
  Widget difficultyOption(String level) {
    return ListTile(
      leading: RadioGroup<String>(
        groupValue: difficulty,
        onChanged: (value) {
          /// Update selected difficulty
          setState(() {
            difficulty = value!;
          });

          /// Close difficulty dialog
          Navigator.pop(context);
        },

        child: Radio<String>(
          /// Difficulty option value
          value: level,

          /// Custom radio button color
          fillColor: WidgetStateProperty.resolveWith((states) {
            /// Selected radio color
            if (states.contains(WidgetState.selected)) {
              return Colors.green;
            }

            /// Default radio color
            return isDark ? Colors.white : Colors.black;
          }),
        ),
      ),

      /// Difficulty text
      title: Text(
        level,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),

      /// Handle difficulty selection
      onTap: () {
        /// Update selected difficulty
        setState(() {
          difficulty = level;
        });

        /// Light vibration feedback
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// Close difficulty dialog
        Navigator.pop(context);
      },
    );
  }

  /// Show difficulty selection menu
  void showDifficultyMenu() {
    showMenu(
      context: context,

      /// Menu display position
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2 - 110,
        85,
        MediaQuery.of(context).size.width / 2 - 110,
        0,
      ),

      /// Transparent popup background
      color: Colors.transparent,
      elevation: 0,
      items: [
        PopupMenuItem(
          /// Disable default popup click behavior
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
                  width: 200,

                  /// Popup inner padding
                  padding: const EdgeInsets.all(14),
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

                    /// Popup shadow effect
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
                      /// Easy difficulty option
                      buildDifficultyTile("Easy"),
                      const SizedBox(height: 10),

                      /// Medium difficulty option
                      buildDifficultyTile("Medium"),
                      const SizedBox(height: 10),

                      /// Medium difficulty option
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

  /// Build difficulty option tile
  Widget buildDifficultyTile(String level) {
    /// Check selected difficulty
    bool selected = difficulty == level;
    List<Color> glowColors;

    /// Easy difficulty colors
    if (level == "Easy") {
      glowColors = [Colors.greenAccent, Colors.green];

      /// Medium difficulty colors
    } else if (level == "Medium") {
      glowColors = [Colors.orangeAccent, Colors.deepOrange];

      /// Hard difficulty colors
    } else {
      glowColors = [Colors.redAccent, Colors.pinkAccent];
    }

    return GestureDetector(
      /// Handle difficulty selection
      onTap: () {
        /// Update selected difficulty
        setState(() {
          difficulty = level;
        });

        /// Light vibration feedback
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// Close difficulty menu
        Navigator.pop(context);
      },

      child: AnimatedContainer(
        /// Selection animation duration
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),

          /// Selected gradient background
          gradient: selected ? LinearGradient(colors: glowColors) : null,

          /// Default background color
          color: selected
              ? null
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.55),

          /// Tile border
          border: Border.all(
            color: selected
                ? Colors.transparent
                : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),

          /// Glow effect for selected tile
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
            /// Difficulty text
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

            /// Selection indicator
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

              /// Selected check icon
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
