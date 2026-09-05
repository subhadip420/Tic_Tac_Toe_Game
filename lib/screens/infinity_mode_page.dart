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

class InfinityModePage extends StatefulWidget {
  const InfinityModePage({super.key});

  @override
  State<InfinityModePage> createState() => _InfinityModePageState();
}

class _InfinityModePageState extends State<InfinityModePage> with TickerProviderStateMixin {
  /// Confetti animation controller
  late ConfettiController confettiController;

  /// Glow animation controller
  late AnimationController glowController;
  late Animation<double> glowAnimation;

  /// Winning line animation controller
  late AnimationController lineController;
  late Animation<double> lineAnimation;

  /// Turn timer animation controller
  late AnimationController timerController;

  /// Player symbols
  String player1Symbol = "X";
  String player2Symbol = "O";

  /// Game messages & States
  String gameMessage = "";
  bool player1Turn = true;
  bool isPlayer1First = true;

  /// Settings
  bool isDark = true;
  bool soundOn = true;
  bool vibrationOn = true;
  bool timerEnabled = false;

  bool resetPressed = false;

  /// Game board data (Fixed 3x3)
  List<String> board = List.filled(9, "");
  final int boardSize = 3;

  /// ✨ PRO MATCH LOGIC: Track moves
  List<int> player1Moves = [];
  List<int> player2Moves = [];

  /// ✨ PRO MATCH LOGIC: Selection state
  bool isPieceSelected = false;
  int selectedPieceIndex = -1;

  bool gameOver = false;
  int lastMove = -1;
  int pressedIndex = -1;
  List<int>? winningLine;
  int player1Score = 0;
  int player2Score = 0;

  /// Timer variables
  int turnTime = 30;
  int currentTime = 30;
  late double progress;
  bool isTimeUp = false;
  Timer? turnTimer;
  int lastAlertSecond = -1;
  bool hasGameStarted = false;

  bool get isGameRunning {
    return board.any((e) => e != "") && !gameOver;
  }

  /// Sound players
  final AudioPlayer xPlayer = AudioPlayer();
  final AudioPlayer oPlayer = AudioPlayer();
  final AudioPlayer winPlayer = AudioPlayer();
  final AudioPlayer clockSoundPlayer = AudioPlayer();
  final AudioPlayer drawPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: turnTime),
    );
    progress = 1 - timerController.value;

    lineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    lineAnimation = CurvedAnimation(parent: lineController, curve: Curves.easeInOut);

    Future.delayed(Duration.zero, () {
      choosePlayerDialog();
    });

    confettiController = ConfettiController(duration: const Duration(seconds: 2));

    glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));

    loadSettings();
    player1Turn = true;
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
    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      soundOn = prefs.getBool("sound_on") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
      timerEnabled = prefs.getBool("timer_enabled") ?? true;
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
        onTimeUp();
      }
    });
  }

  void onTimeUp() {
    if (gameOver) return;
    stopTickingSound();
    setState(() {
      gameOver = true;
      isTimeUp = true;
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
    await xPlayer.play(AssetSource("audio/tap.mp3"));
  }

  Future<void> playOSound() async {
    if (!soundOn) return;
    await oPlayer.stop();
    await oPlayer.play(AssetSource("audio/tap.mp3"));
  }

  Future<void> playWinSound() async {
    if (!soundOn) return;
    await winPlayer.stop();
    await winPlayer.play(AssetSource("audio/win.mp3"));
  }

  Future<void> playVibration(int duration) async {
    if (!vibrationOn) return;
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: duration);
    }
  }

  /// ✨ MAIN LOGIC FOR PRO MATCH
  void handleTap(int index) {
    if (gameOver) return;

    String currentPlayerSymbol = player1Turn ? player1Symbol : player2Symbol;
    List<int> currentPlayerMoves = player1Turn ? player1Moves : player2Moves;

    /// Phase 1: Player ke paas 3 se kam piece hain, normal game chalega
    if (currentPlayerMoves.length < 3) {
      if (board[index] != "") return; // Khali jagah par hi click karna hoga

      _placePiece(index, currentPlayerSymbol, currentPlayerMoves);
    }
    /// Phase 2: Player ke paas 3 piece hain, ab replace (move) karna hoga
    else {
      // 1. Agar player apne hi kisi piece par click karta hai (Select karne ke liye)
      if (board[index] == currentPlayerSymbol) {
        if (vibrationOn) HapticFeedback.lightImpact();
        setState(() {
          isPieceSelected = true;
          selectedPieceIndex = index;
        });
        return;
      }

      // 2. Agar player khali box par click karta hai
      if (board[index] == "") {
        if (isPieceSelected) {
          // Agar piece select kiya hua hai, toh use move kar do
          _movePiece(selectedPieceIndex, index, currentPlayerSymbol, currentPlayerMoves);
        } else {
          // Agar piece select nahi kiya aur khali box par click kar diya
          CustomToast.show(
            context: context,
            message: "Tap your piece first to move it!",
            isDark: isDark,
            icon: Icons.touch_app,
            color: Colors.orange,
          );
        }
      }
    }
  }

  void _placePiece(int targetIndex, String symbol, List<int> playerMoves) {
    if (!hasGameStarted) {
      hasGameStarted = true;
      if (timerEnabled) startTurnTimer();
    }

    setState(() {
      pressedIndex = targetIndex;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      setState(() {
        pressedIndex = -1;
        board[targetIndex] = symbol;
        playerMoves.add(targetIndex);
        lastMove = targetIndex;
      });

      _finishTurn(symbol);
    });
  }

  void _movePiece(int fromIndex, int toIndex, String symbol, List<int> playerMoves) {
    setState(() {
      pressedIndex = toIndex;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      setState(() {
        pressedIndex = -1;
        // Purani jagah se piece hatao
        board[fromIndex] = "";
        playerMoves.remove(fromIndex);

        // Nayi jagah par piece lagao
        board[toIndex] = symbol;
        playerMoves.add(toIndex);

        lastMove = toIndex;
        // Selection reset kar do
        isPieceSelected = false;
        selectedPieceIndex = -1;
      });

      _finishTurn(symbol);
    });
  }

  void _finishTurn(String symbol) {
    if (symbol == "X") {
      playXSound();
      if (vibrationOn) HapticFeedback.lightImpact();
    } else {
      playOSound();
      if (vibrationOn) HapticFeedback.lightImpact();
    }

    checkWinner();

    if (!gameOver) {
      setState(() {
        player1Turn = !player1Turn;
        // Turn change hote hi dusre player ka koi piece selected nahi rehna chahiye
        isPieceSelected = false;
        selectedPieceIndex = -1;
      });
      stopTickingSound();
      if (timerEnabled) startTurnTimer();
    }
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  width: 300,
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.05)]
                          : [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.12)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.transparent.withValues(alpha: isDark ? 0.10 : 0.06),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                        offset: const Offset(0, 8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Choose Player 1 Symbol",
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
                          GestureDetector(
                            onTap: () {
                              if (vibrationOn) HapticFeedback.lightImpact();
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
                                color: isDark ? const Color(0xFF1F2A44) : const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.blueAccent, width: 1.5),
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
                          GestureDetector(
                            onTap: () {
                              if (vibrationOn) HapticFeedback.lightImpact();
                              setState(() {
                                player1Symbol = "O";
                                player2Symbol = "X";
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1F2A44) : const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.orangeAccent, width: 1.5),
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
    }
  }

  void checkWinner() {
    String currentPlayer = player1Turn ? player1Symbol : player2Symbol;
    int winLength = 3;

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        int index = row * boardSize + col;
        if (board[index] != currentPlayer) continue;

        if (_checkDirection(row, col, 0, 1, currentPlayer, winLength)) return;
        if (_checkDirection(row, col, 1, 0, currentPlayer, winLength)) return;
        if (_checkDirection(row, col, 1, 1, currentPlayer, winLength)) return;
        if (_checkDirection(row, col, 1, -1, currentPlayer, winLength)) return;
      }
    }
  }

  bool _checkDirection(int row, int col, int rowDir, int colDir, String player, int winLength) {
    if (gameOver) return true;

    List<int> matched = [];
    for (int i = 0; i < winLength; i++) {
      int newRow = row + rowDir * i;
      int newCol = col + colDir * i;

      if (newRow < 0 || newRow >= boardSize || newCol < 0 || newCol >= boardSize) return false;

      int index = newRow * boardSize + newCol;
      if (board[index] != player) return false;

      matched.add(index);
    }

    stopTickingSound();
    setState(() {
      gameOver = true;
      winningLine = List<int>.from(matched);
    });

    lineController.reset();
    lineController.forward();

    if (player == player1Symbol) {
      player1Score++;
    } else {
      player2Score++;
    }

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
        if (vibrationOn) HapticFeedback.heavyImpact();
        resetGame();
      },
      onNegative: () {
        if (vibrationOn) HapticFeedback.lightImpact();
      },
    );
  }

  void resetGame() {
    stopTickingSound();
    setState(() {
      hasGameStarted = false;
      timerController.reset();
      isTimeUp = false;
      currentTime = 30;

      isPlayer1First = !isPlayer1First;
      player1Turn = isPlayer1First;

      board = List.filled(9, "");
      player1Moves.clear();
      player2Moves.clear();

      /// Reset selection states
      isPieceSelected = false;
      selectedPieceIndex = -1;

      winningLine = null;
      lastMove = -1;
      gameOver = false;
      gameMessage = "";
    });

    lineController.reset();
    turnTimer?.cancel();
  }

  void showSettingsMenu() {
    showGlassSettingsMenu(
      context: context,
      isDark: isDark,
      items: [
        SettingsMenuItem(
          affectsTheme: true,
          iconBuilder: (value) => value ? Icons.dark_mode : Icons.light_mode,
          title: "Dark Theme",
          value: isDark,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (vibrationOn) HapticFeedback.lightImpact();
            setState(() {
              isDark = value;
            });
            await prefs.setBool("theme_dark", isDark);
          },
        ),
        SettingsMenuItem(
          iconBuilder: (value) => value ? Icons.volume_up : Icons.volume_off,
          title: "Sound",
          value: soundOn,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (vibrationOn) HapticFeedback.lightImpact();
            setState(() {
              soundOn = value;
            });
            await prefs.setBool("sound_on", soundOn);
          },
        ),
        SettingsMenuItem(
          iconBuilder: (value) => value ? Icons.vibration : Icons.phonelink_erase,
          title: "Vibration",
          value: vibrationOn,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if (!vibrationOn) HapticFeedback.lightImpact();
            setState(() {
              vibrationOn = value;
            });
            await prefs.setBool("vibration_on", vibrationOn);
          },
        ),
        SettingsMenuItem(
          iconBuilder: (value) => value ? Icons.timer : Icons.timer_off,
          title: "Timer",
          value: timerEnabled,
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
            if (vibrationOn) HapticFeedback.lightImpact();
            setState(() {
              timerEnabled = value;
            });
            await prefs.setBool("timer_enabled", timerEnabled);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color boardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;
    Color cellColor = isDark ? const Color(0xFF1F2A44) : const Color(0xFFF0F0F0);
    Color textColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      canPop: (gameOver || !board.any((e) => e != "")),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!gameOver && board.any((e) => e != "")) {
          if (vibrationOn) HapticFeedback.lightImpact();
          await showExitDialog();
        } else {
          if (vibrationOn) HapticFeedback.lightImpact();
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.25),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Tooltip(
              message: "Back",
              child: GestureDetector(
                onTap: () async {
                  if (!gameOver && board.any((e) => e != "")) {
                    if (vibrationOn) HapticFeedback.lightImpact();
                    await showExitDialog();
                  } else {
                    if (vibrationOn) HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  }
                },
                child: build3DIconButton(icon: Icons.arrow_back, isDark: isDark),
              ),
            ),
          ),
          title: Text(
            "Pro Match",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Tooltip(
                message: "Settings",
                child: GestureDetector(
                  onTap: () {
                    if (vibrationOn) HapticFeedback.lightImpact();
                    showSettingsMenu();
                  },
                  child: build3DIconButton(icon: Icons.settings, isDark: isDark),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
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

            /// Background Arts
            Positioned(
              top: -30,
              left: -20,
              child: Transform.rotate(
                angle: -0.2,
                child: Text(
                  "X",
                  style: TextStyle(
                    fontSize: 200,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: isDark ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Transform.rotate(
                angle: 0.7,
                child: Text(
                  "O",
                  style: TextStyle(
                    fontSize: 250,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: isDark
                        ? Colors.orangeAccent.withValues(alpha: 0.05)
                        : Colors.deepOrange.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: -10,
              child: Transform.rotate(
                angle: -0.7,
                child: Text(
                  "X",
                  style: TextStyle(
                    fontSize: 250,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: isDark ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 230,
              left: 0,
              child: Transform.rotate(
                angle: -0.9,
                child: Text(
                  "O",
                  style: TextStyle(
                    fontSize: 200,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: isDark
                        ? Colors.orangeAccent.withValues(alpha: 0.05)
                        : Colors.deepOrange.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 250,
              right: -20,
              child: Transform.rotate(
                angle: 0.9,
                child: Text(
                  "O",
                  style: TextStyle(
                    fontSize: 150,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: isDark
                        ? Colors.orangeAccent.withValues(alpha: 0.05)
                        : Colors.deepOrange.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -40,
              child: Transform.rotate(
                angle: 0.8,
                child: Text(
                  "X",
                  style: TextStyle(
                    fontSize: 200,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: isDark ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -50,
              child: Transform.rotate(
                angle: 0.9,
                child: Text(
                  "O",
                  style: TextStyle(
                    fontSize: 370,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: isDark
                        ? Colors.orangeAccent.withValues(alpha: 0.05)
                        : Colors.deepOrange.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),

            ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple],
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          scoreBox("Player 1", player1Symbol, boardColor, textColor),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(color: boardColor, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              "$player1Score - $player2Score",
                              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
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
                            "Time's Up!",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 0),

                      if (!gameOver)
                        Text(
                          player1Turn ? "Player 1 Turn" : "Player 2 Turn",
                          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),

                      const SizedBox(height: 20),

                      if (gameMessage != "")
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, double value, child) {
                            Color cardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;
                            List<Color> gradientColors = gameMessage.contains("WIN")
                                ? [Colors.greenAccent, Colors.blueAccent]
                                : [Colors.orangeAccent, Colors.yellow];
                            return AnimatedBuilder(
                              animation: glowAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, -40 * (1 - value)),
                                    child: Transform.scale(
                                      scale: 0.95 + (0.05 * value),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: gradientColors),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: gradientColors.first.withValues(alpha: glowAnimation.value),
                                              blurRadius: 12 * glowAnimation.value,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: cardColor,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              ShaderMask(
                                                shaderCallback: (rect) {
                                                  return LinearGradient(colors: gradientColors).createShader(rect);
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
                                              Text(
                                                gameMessage,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      color: gradientColors.first.withValues(
                                                        alpha: glowAnimation.value,
                                                      ),
                                                      blurRadius: 10 * glowAnimation.value,
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
                      const SizedBox(height: 20),

                      /// Game board section
                      SizedBox(
                        height: 320,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 320,
                            height: 320,
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.blueAccent, Colors.deepOrangeAccent, Colors.blueAccent]
                                    : [Colors.blueAccent, Colors.deepOrangeAccent, Colors.blueAccent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: const Offset(4, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(color: boardColor, borderRadius: BorderRadius.circular(20)),
                              child: Stack(
                                children: [
                                  GridView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: board.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: boardSize, // Always 3
                                      childAspectRatio: 1,
                                    ),
                                    itemBuilder: (context, index) {
                                      bool highlight = index == lastMove;
                                      bool win = winningLine != null && winningLine!.contains(index);

                                      /// ✨ PRO MATCH FADING EFFECT: Identify the SELECTED piece
                                      bool isFading = (isPieceSelected && selectedPieceIndex == index);

                                      return GestureDetector(
                                        onTap: () => handleTap(index),
                                        child: AnimatedScale(
                                          scale: pressedIndex == index ? 0.92 : 1,
                                          duration: const Duration(milliseconds: 120),
                                          child: Container(
                                            margin: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: cellColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: board[index] != ""
                                                  ? Border.all(
                                                      // Selected piece ka border highlight karo
                                                      color: isFading
                                                          ? (isDark ? Colors.yellowAccent : Colors.redAccent)
                                                          : (isDark ? Color(0xFF47798A) : Color(0xFF9ED3E8)),
                                                      width: isFading ? 2 : 1,
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
                                                  const BoxShadow(color: Colors.green, blurRadius: 8, spreadRadius: 1),
                                                // Selected piece ka extra glow
                                                if (isFading)
                                                  BoxShadow(
                                                    color: isDark ? Colors.yellowAccent : Colors.redAccent,
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                              ],
                                            ),
                                            child: Center(
                                              /// Apply fading animation to the SELECTED piece
                                              child: AnimatedOpacity(
                                                opacity: isFading ? 0.35 : 1.0,
                                                duration: const Duration(milliseconds: 300),
                                                child: board[index] == "X"
                                                    ? const GameX(size: 40)
                                                    : board[index] == "O"
                                                    ? const GameO(size: 40)
                                                    : const SizedBox(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (winningLine != null)
                                    AnimatedBuilder(
                                      animation: lineAnimation,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          size: Size(304, 304),
                                          painter: WinLinePainter(winningLine!, lineAnimation.value, boardSize),
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
                                  if (vibrationOn) HapticFeedback.mediumImpact();
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
                                  if (vibrationOn) HapticFeedback.mediumImpact();
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
                            showResetGameDialog();
                            if (vibrationOn) HapticFeedback.lightImpact();
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
                                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
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
            IgnorePointer(
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple],
              ),
            ),
          ],
        ),
      ),
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
        if (vibrationOn) HapticFeedback.lightImpact();
      },
      onPositive: () async {
        if (vibrationOn) HapticFeedback.mediumImpact();
        stopTickingSound();
        Navigator.pop(context);
      },
    );
  }

  Widget scoreBox(String player, String symbol, Color bg, Color textColor) {
    Color borderColor = symbol == "X" ? Colors.blueAccent : Colors.orangeAccent;
    bool isPlayer1 = player == "Player 1";
    bool isActive = !gameOver && ((player1Turn && isPlayer1) || (!player1Turn && !isPlayer1));
    List<Color> gradientColors = symbol == "X"
        ? [Colors.blueAccent, Colors.cyanAccent]
        : [Colors.orangeAccent, Colors.deepOrange];

    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        double glowValue = isActive ? glowAnimation.value : 0;
        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(colors: gradientColors).createShader(rect);
                    },
                    child: Text(
                      symbol,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    player,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (isActive && timerEnabled)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: timerController,
                  builder: (context, child) {
                    int timeLeft = getTimeLeft();
                    if (timeLeft <= 5 && timeLeft > 0) {
                      if (timeLeft != lastAlertSecond) {
                        lastAlertSecond = timeLeft;
                        if (soundOn) {
                          clockSoundPlayer.stop();
                          clockSoundPlayer.play(AssetSource("audio/tick.mp3"));
                        }
                        if (vibrationOn) HapticFeedback.mediumImpact();
                      }
                    }
                    return CustomPaint(painter: TimerBorderPainter(1 - timerController.value, borderColor));
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
