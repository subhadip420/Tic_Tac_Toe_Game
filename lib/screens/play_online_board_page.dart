import 'dart:async';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:ui';
import '../../widgets/game_symbols.dart';
import '../widgets/build_circle_icon_button.dart';
import '../widgets/custom_toast.dart';
import '../widgets/glass_settings_menu.dart';
import '../widgets/loading_dialog_with_button.dart';
import '../widgets/neon_glowing_button.dart';
import '../../widgets/loading_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // 🔥 for kIsWeb
import 'package:http/http.dart' as http;
import 'web_listener_stub.dart' if (dart.library.html) 'web_listener.dart';

/// ONLINE MULTIPLAYER GAME BOARD PAGE
class PlayOnlineBoardPage extends StatefulWidget {
  /// Room code from online lobby
  final String roomCode;

  const PlayOnlineBoardPage({super.key, required this.roomCode});

  @override
  State<PlayOnlineBoardPage> createState() => _PlayOnlineBoardPageState();
}

class _PlayOnlineBoardPageState extends State<PlayOnlineBoardPage>
    with TickerProviderStateMixin {
  /// BOARD & GAME STATE
  int boardSize = 3;
  List<String> board = [];

  /// CONTROLLERS & ANIMATIONS
  late ConfettiController confettiController;
  late AnimationController glowController;
  late Animation<double> glowAnimation;
  late AnimationController lineController;
  late Animation<double> lineAnimation;
  late AnimationController timerController;
  final ScrollController nameScrollController = ScrollController();
  late AnimationController nameScrollAnim;

  /// AUDIO PLAYERS
  final AudioPlayer xPlayer = AudioPlayer();
  final AudioPlayer oPlayer = AudioPlayer();
  final AudioPlayer clockSoundPlayer = AudioPlayer();
  final AudioPlayer winPlayer = AudioPlayer();
  final AudioPlayer losePlayer = AudioPlayer();
  final AudioPlayer drawPlayer = AudioPlayer();

  bool gameOver = false;
  int lastMove = -1;
  int pressedIndex = -1;
  List<int>? winningLine;

  /// SCORE & RESULT
  String gameMessage = "";
  int player1Score = 0;
  int player2Score = 0;

  /// SETTINGS
  bool isDark = true;
  bool soundOn = true;
  bool vibrationOn = true;
  bool resetPressed = false;

  /// PLAYER INFO
  String player1Symbol = "";
  String player2Symbol = "";

  bool player1Turn = true;
  bool isPlayer1First = true;

  /// FIREBASE
  late DatabaseReference roomRef;
  late DatabaseReference dbRef;

  String currentTurn = "";
  String mySymbol = "";

  String myId = "";
  String opponentId = "";

  /// GAME STATUS FLAGS
  bool isRestarting = false;
  bool dialogOpen = false;
  bool hasShownResult = false;
  bool disconnectSetupDone = false;
  bool disconnectDialogShown = false;
  bool isOfflineDialogShown = false;
  bool isDialogOpen = false;
  bool opponentExitDialogShown = false;
  bool isDisconnectDialogOpen = false;
  bool isReplayResetting = false;
  bool isSendingReplay = false;
  bool isTimeUp = false;
  bool isExitDialogOpen = false;
  bool isRoomActive = true;
  bool isGamePageClosed = false;
  bool hasFirstMove = false;

  /// STREAM SUBSCRIPTIONS
  late StreamSubscription connectivitySubscription;
  StreamSubscription? presenceSubscription;

  /// TIMERS
  Timer? resendTimer;
  Timer? heartbeatTimer;

  /// PREVIOUS GAME DATA
  List<String> previousBoard = [];

  /// REMATCH SYSTEM
  double resendProgress = 0;
  int resendCooldown = 0;
  String lastRematchAction = "";

  /// TIMER SYSTEM
  int turnDuration = 30;
  int serverStartTime = 0;
  int lastAlertSecond = -1;

  /// HEARTBEAT SYSTEM
  int lastPingReceivedLocalTime = 0;
  int lastOpponentPingValue = -1;
  int myPingCounter = 0;

  /// DIALOG CONTEXTS
  BuildContext? disconnectDialogCtx;
  BuildContext? internetDialogCtx;

  @override
  void initState() {
    super.initState();

    /// Firebase setup
    initializeFirebase();

    /// Start game systems
    initializeGame();

    /// Initialize animations
    initializeAnimations();

    /// Connectivity listener
    initializeConnectivity();

    /// Web reconnect listeners
    initializeWebListeners();

    /// Username marquee animation
    initializeNameScroll();

    /// Turn timer listener
    initializeTimerListener();

    /// Load saved settings
    loadSettings();
  }

  /// FIREBASE INITIALIZATION
  void initializeFirebase() {
    dbRef = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,

      databaseURL:
          "https://tic-tac-toe-9c3bf-default-rtdb.asia-southeast1.firebasedatabase.app/",
    ).ref();

    roomRef = dbRef.child("rooms/${widget.roomCode}");
  }

  /// GAME INITIALIZATION
  void initializeGame() {
    /// Listen realtime game updates
    listenToGame();

    /// Start heartbeat system
    startHeartbeat();
  }

  /// ANIMATION INITIALIZATION
  void initializeAnimations() {
    /// Turn timer animation
    timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    /// Winning line animation
    lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    lineAnimation = CurvedAnimation(
      parent: lineController,
      curve: Curves.easeInOut,
    );

    /// Confetti animation
    confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    /// Glow animation
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));
  }

  /// INTERNET CONNECTIVITY LISTENER
  void initializeConnectivity() {
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      _,
    ) async {
      if (kIsWeb) return;
      bool hasInternet = await checkInternet();

      /// Handle offline state
      if (!hasInternet) {
        handleOffline();
      } else {
        /// Handle reconnect
        await handleOnline();
      }
    });
  }

  /// WEB INTERNET LISTENER
  void initializeWebListeners() {
    if (!kIsWeb) return;
    setupWebListeners(
      /// Internet lost
      onOffline: () {
        if (!isOfflineDialogShown) {
          isOfflineDialogShown = true;
          if (vibrationOn) {
            HapticFeedback.mediumImpact();
          }
          noInternetDialog();
        }
      },

      /// Internet restored
      onOnline: () async {
        await handleWebReconnect();
      },
    );
  }

  /// PLAYER NAME AUTO SCROLL ANIMATION
  void initializeNameScroll() {
    nameScrollAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    /// Auto scroll listener
    nameScrollAnim.addListener(() {
      if (nameScrollController.hasClients) {
        double maxScroll = nameScrollController.position.maxScrollExtent;

        /// Smooth back & forth scroll
        nameScrollController.jumpTo(maxScroll * nameScrollAnim.value);
      }
    });

    /// Infinite reverse animation
    nameScrollAnim.repeat(reverse: true);
  }

  /// TURN TIMER LISTENER
  void initializeTimerListener() {
    timerController.addListener(() {
      /// Time finished
      if (timerController.value >= 1.0 && !gameOver) {
        print(" TIME UP TRIGGERED");
        setState(() {
          isTimeUp = true;
          gameOver = true;
        });

        /// Stop ticking sound
        stopTickingSound();

        /// Stop timer animation
        timerController.stop();

        /// Handle online timeout
        onTimeUpOnline();
      }
    });
  }

  /// HANDLE INTERNET DISCONNECT
  void handleOffline() {
    /// Prevent multiple dialogs
    if (isOfflineDialogShown) return;
    isOfflineDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vibrationOn) {
        HapticFeedback.mediumImpact();
      }

      /// Show no internet dialog
      noInternetDialog();
    });
  }

  /// HANDLE INTERNET RECONNECT
  Future<void> handleOnline() async {
    if (!isOfflineDialogShown) return;
    isOfflineDialogShown = false;

    /// Close internet dialog
    closeInternetDialog();

    /// Reconnected toast
    CustomToast.show(
      context: context,
      message: "Reconnected.",
      isDark: isDark,
      icon: Icons.wifi_rounded,
      color: Colors.green,
    );

    /// Check room exists
    final snapshot = await roomRef.get();
    if (!snapshot.exists) {
      heartbeatTimer?.cancel();

      /// Opponent room deleted
      if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
        opponentExitDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showOpponentExitDialog();
          }
        });
      }

      return;
    }

    /// Reset heartbeat timer
    lastPingReceivedLocalTime = DateTime.now().millisecondsSinceEpoch;

    /// Restore online presence
    await restorePresence();
  }

  /// HANDLE WEB RECONNECT
  Future<void> handleWebReconnect() async {
    /// Close offline dialog
    if (isOfflineDialogShown) {
      isOfflineDialogShown = false;
      closeInternetDialog();

      /// Reconnected toast
      CustomToast.show(
        context: context,
        message: "Reconnected.",
        isDark: isDark,
        icon: Icons.wifi_rounded,
        color: Colors.green,
      );
    }

    /// Check room exists
    final snapshot = await roomRef.get();
    if (!snapshot.exists) {
      heartbeatTimer?.cancel();

      /// Opponent room deleted
      if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
        opponentExitDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showOpponentExitDialog();
          }
        });
      }
      return;
    }

    /// Reset heartbeat timer
    lastPingReceivedLocalTime = DateTime.now().millisecondsSinceEpoch;

    /// Restore online presence
    await restorePresence();
  }

  /// RESTORE PLAYER PRESENCE
  Future<void> restorePresence() async {
    /// My symbol not loaded
    if (mySymbol.isEmpty) return;
    String playerKey = mySymbol == player1Symbol ? "player1" : "player2";

    /// Set player online
    await roomRef.child("exitStatus/$playerKey").set("online");

    /// Restore player data
    await roomRef.child("players/$playerKey").update({
      "uid": myId,
      "symbol": mySymbol,
    });

    /// Register disconnect presence
    registerPresence();
  }

  /// CLOSE INTERNET DIALOG
  void closeInternetDialog() {
    if (!mounted || internetDialogCtx == null) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);

    /// Close dialog safely
    if (isDialogOpen && navigator.canPop()) {
      navigator.pop();
      isDialogOpen = false;
      internetDialogCtx = null;
    }
    internetDialogCtx = null;
  }

  @override
  void dispose() {
    /// Stop heartbeat system
    heartbeatTimer?.cancel();

    /// Cancel presence listener
    presenceSubscription?.cancel();

    /// Cancel Firebase onDisconnect
    if (mySymbol.isNotEmpty) {
      String playerKey = mySymbol == player1Symbol ? "player1" : "player2";
      roomRef.child("exitStatus/$playerKey").onDisconnect().cancel();
    }

    /// Cancel resend timer
    resendTimer?.cancel();

    /// Dispose animations & controllers
    confettiController.dispose();
    glowController.dispose();
    lineController.dispose();
    nameScrollAnim.dispose();
    nameScrollController.dispose();

    /// Cancel internet listener
    connectivitySubscription.cancel();

    /// Stop ticking sound
    stopTickingSound();
    super.dispose();
  }

  /// CLOSE GAME PAGE SAFELY
  void closeGamePage() {
    if (!mounted || isGamePageClosed) return;

    isGamePageClosed = true;

    /// Close all opened dialogs
    Navigator.of(context, rootNavigator: true).popUntil((route) {
      return route is PageRoute;
    });

    /// Close game page
    Navigator.of(context).pop();
  }

  /// STOP TIMER TICK SOUND
  void stopTickingSound() {
    clockSoundPlayer.stop();
    lastAlertSecond = -1;
  }

  /// CHECK INTERNET CONNECTION
  Future<bool> checkInternet() async {
    if (kIsWeb) {
      return true;
    }

    try {
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// REGISTER PLAYER PRESENCE
  Future<void> registerPresence() async {
    if (mySymbol.isEmpty) return;

    String playerKey = mySymbol == player1Symbol ? "player1" : "player2";

    try {
      /// Check room exists
      final snapshot = await roomRef.get();
      if (!snapshot.exists) {
        isRoomActive = false;
        return;
      }

      /// Cancel old disconnect listener
      await roomRef.child("exitStatus/$playerKey").onDisconnect().cancel();

      /// Set player online
      await roomRef.child("exitStatus/$playerKey").set("online");
    } catch (e) {
      print("Presence error: $e");
    }
  }

  /// FIREBASE CONNECTION LISTENER
  void setupPresence() {
    DatabaseReference connectedRef = FirebaseDatabase.instance.ref(
      ".info/connected",
    );

    /// Cancel old listener
    presenceSubscription?.cancel();
    presenceSubscription = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;

      /// Re-register presence
      if (connected) {
        registerPresence();
      }
    });
  }

  /// START HEARTBEAT SYSTEM
  void startHeartbeat() {
    heartbeatTimer?.cancel();
    heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      /// Stop during offline
      if (isOfflineDialogShown || !isRoomActive) return;

      /// Send my heartbeat ping
      if (mySymbol.isNotEmpty) {
        String myKey = mySymbol == player1Symbol ? "player1" : "player2";
        myPingCounter++;
        roomRef.child("pings/$myKey").set(myPingCounter);
      }

      /// Check opponent connection
      if (opponentId != "Waiting..." && opponentId.isNotEmpty) {
        int now = DateTime.now().millisecondsSinceEpoch;

        if (lastPingReceivedLocalTime == 0) {
          lastPingReceivedLocalTime = now;
        }

        /// Opponent disconnected
        if (now - lastPingReceivedLocalTime > 12000) {
          if (!isDisconnectDialogOpen &&
              !opponentExitDialogShown &&
              !isOfflineDialogShown) {
            isDisconnectDialogOpen = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (vibrationOn) {
                  HapticFeedback.mediumImpact();
                }
                showOpponentDisconnectDialog();
              }
            });
          }
        }
      }
    });
  }

  /// HANDLE PLAYER TAP
  Future<void> handleTap(int index) async {
    /// Block tap after game over
    if (gameOver || isTimeUp) return;

    /// Prevent tap after win
    if (winningLine != null) return;

    /// Cell already filled
    if (board[index] != "") return;

    /// Not my turn
    if (currentTurn != mySymbol) return;

    /// Press animation
    setState(() {
      pressedIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        pressedIndex = -1;
      });
    });

    /// Update board locally
    List<String> newBoard = List.from(board);
    newBoard[index] = mySymbol;

    /// Check winner result
    final result = checkWinnerDynamic(newBoard, boardSize);

    String nextTurn = mySymbol == "X" ? "O" : "X";

    Map<String, dynamic>? scoreUpdate;

    /// Update score if winner found
    if (result["winner"] != "" && result["winner"] != "draw") {
      final snapshot = await roomRef.child("score").get();

      int p1Score = snapshot.child("player1").value as int? ?? 0;
      int p2Score = snapshot.child("player2").value as int? ?? 0;

      /// Increase winner score
      if (result["winner"] == player1Symbol) {
        p1Score++;
      } else {
        p2Score++;
      }

      scoreUpdate = {"score/player1": p1Score, "score/player2": p2Score};
    }

    /// Stop old timer sound
    stopTickingSound();

    /// Update Firebase game state
    await roomRef.update({
      "board": newBoard,
      "currentTurn": result["winner"] == "" ? nextTurn : "",
      "winner": result["winner"],

      /// Winning line indexes
      "winningLine": result["line"],
      "lastMove": index,

      /// Match started globally
      "matchStarted": true,

      /// Restart turn timer
      "timerStart": ServerValue.timestamp,
      "turnDuration": 30,

      if (scoreUpdate != null) ...scoreUpdate,
    });
  }

  /// LOAD SAVED SETTINGS
  Future loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      soundOn = prefs.getBool("sound_on") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
    });
  }

  /// PLAY X MOVE SOUND
  Future<void> playXSound() async {
    if (!soundOn) return;
    await xPlayer.stop();
    await xPlayer.play(AssetSource("audio/tap.mp3"));
  }

  /// PLAY O MOVE SOUND
  Future<void> playOSound() async {
    if (!soundOn) return;
    await oPlayer.stop();
    await oPlayer.play(AssetSource("audio/tap.mp3"));
  }

  /// PLAY WIN SOUND
  Future<void> playWinSound() async {
    if (!soundOn) return;
    await winPlayer.stop();
    await winPlayer.play(AssetSource("audio/win.mp3"));
  }

  /// PLAY DRAW SOUND
  Future<void> playDrawSound() async {
    if (!soundOn) return;
    await drawPlayer.stop();
    await drawPlayer.play(AssetSource("audio/draw.mp3"));
  }

  /// PLAY LOSE SOUND
  Future<void> playLoseSound() async {
    if (!soundOn) return;
    await drawPlayer.stop();
    await drawPlayer.play(AssetSource("audio/lose.mp3"));
  }

  /// PLAY DEVICE VIBRATION
  Future<void> playVibration(int duration) async {
    if (!vibrationOn) return;
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: duration);
    }
  }

  /// LISTEN REALTIME GAME DATA
  Future<void> listenToGame() async {
    final prefs = await SharedPreferences.getInstance();

    /// Current player id
    String userId = prefs.getString("nickname") ?? "";

    /// Firebase realtime listener
    roomRef.onValue.listen((event) {
      /// Handle deleted room
      if (handleRoomDeleted(event)) {
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      /// Sync turn timer
      handleTimerSync(data);

      /// Handle invalid room
      if (handleZombieRoom(data)) {
        return;
      }

      /// Update main game UI
      updateGameState(data, userId);

      /// Handle replay/rematch
      handleRematch(data);

      /// Update player scores
      updateScore(data);

      /// Handle heartbeat ping
      handleHeartbeat(data);

      /// Handle player exit state
      handleExitStatus(data);
    });
  }

  /// HANDLE ROOM DELETION
  bool handleRoomDeleted(DatabaseEvent event) {
    /// Room still exists
    if (event.snapshot.exists) {
      return false;
    }

    isRoomActive = false;

    /// Stop heartbeat system
    heartbeatTimer?.cancel();

    if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
      opponentExitDialogShown = true;

      /// Close disconnect dialog
      if (isDisconnectDialogOpen && disconnectDialogCtx != null) {
        if (Navigator.of(disconnectDialogCtx!, rootNavigator: true).canPop()) {
          Navigator.of(disconnectDialogCtx!, rootNavigator: true).pop();
        }

        isDisconnectDialogOpen = false;
      }

      /// Close internet dialog
      if (isDialogOpen && internetDialogCtx != null) {
        if (Navigator.of(internetDialogCtx!, rootNavigator: true).canPop()) {
          Navigator.of(internetDialogCtx!, rootNavigator: true).pop();
        }

        isDialogOpen = false;
      }

      /// Show opponent exit dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          stopTickingSound();
          showOpponentExitDialog();
        }
      });
    }

    return true;
  }

  /// SYNC ONLINE TURN TIMER
  void handleTimerSync(Map<String, dynamic> data) {
    bool matchStarted = data["matchStarted"] ?? false;

    /// Match not started
    if (!matchStarted) {
      timerController.stop();
      timerController.reset();
      serverStartTime = 0;
      return;
    }

    /// Sync server timer
    if (data["timerStart"] != null) {
      int newStart = data["timerStart"];
      turnDuration = data["turnDuration"] ?? 30;

      /// Restart timer if changed
      if (serverStartTime != newStart || timerController.value >= 1.0) {
        serverStartTime = newStart;
        lastAlertSecond = -1;

        /// Sync animation timer
        syncTimer();
      }
    }
  }

  /// HANDLE INVALID / ZOMBIE ROOM
  bool handleZombieRoom(Map<String, dynamic> data) {
    /// Valid room check
    if (data["board"] != null && data["players"] != null) {
      return false;
    }

    /// Remove broken room
    roomRef.remove();
    isRoomActive = false;

    /// Stop heartbeat
    heartbeatTimer?.cancel();
    if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
      opponentExitDialogShown = true;

      /// Show opponent exit dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showOpponentExitDialog();
        }
      });
    }

    return true;
  }

  /// UPDATE MAIN GAME STATE
  void updateGameState(Map<String, dynamic> data, String userId) {
    setState(() {
      /// Update board values
      updateBoardData(data);

      /// Play move sounds
      updateBoardSound(data);

      /// Update player info
      updatePlayerData(data, userId);

      /// Update winning line
      updateWinningLine(data);

      /// Update result state
      updateWinnerState(data);
    });
  }

  /// UPDATE BOARD DATA
  void updateBoardData(Map<String, dynamic> data) {
    isTimeUp = data["timeUp"] ?? false;
    boardSize = data["boardSize"] ?? 3;
    board = List<String>.from(data["board"]);

    /// Save previous turn
    String oldTurn = currentTurn;

    currentTurn = data["currentTurn"] ?? "";

    /// Stop tick sound on turn change
    if (oldTurn != currentTurn) {
      stopTickingSound();
    }
    lastMove = data["lastMove"] ?? -1;
  }

  /// PLAY BOARD MOVE SOUND
  void updateBoardSound(Map<String, dynamic> data) {
    List<String> newBoard = List<String>.from(data["board"]);

    /// First board sync
    if (previousBoard.isEmpty) {
      previousBoard = List.from(newBoard);

      return;
    }

    /// Detect changed cell
    for (int i = 0; i < newBoard.length; i++) {
      if (previousBoard[i] != newBoard[i]) {
        /// X move sound
        if (newBoard[i] == "X") {
          playXSound();
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }

          /// O move sound
        } else if (newBoard[i] == "O") {
          playOSound();
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }
        }

        break;
      }
    }

    /// Save latest board
    previousBoard = List.from(newBoard);
  }

  /// UPDATE PLAYER DATA
  void updatePlayerData(Map<String, dynamic> data, String userId) {
    final playersData = data["players"];
    final p1 = playersData != null ? playersData["player1"] : null;
    final p2 = playersData != null ? playersData["player2"] : null;
    myId = userId;

    /// Current user is player1
    if (p1 != null && p1["uid"] == userId) {
      mySymbol = p1["symbol"] ?? "";
      opponentId = p2?["uid"] ?? "Waiting...";
      player1Symbol = p1["symbol"] ?? "";
      player2Symbol = p2?["symbol"] ?? "";

      /// Current user is player2
    } else if (p2 != null && p2["uid"] == userId) {
      mySymbol = p2["symbol"] ?? "";
      opponentId = p1?["uid"] ?? "Waiting...";
      player1Symbol = p1?["symbol"] ?? "";
      player2Symbol = p2["symbol"] ?? "";
    }

    /// Setup online presence once
    if (!disconnectSetupDone && mySymbol.isNotEmpty) {
      disconnectSetupDone = true;
      setupPresence();
      registerPresence();
    }
  }

  /// UPDATE WINNING LINE
  void updateWinningLine(Map<String, dynamic> data) {
    List<int>? newLine = data["winningLine"] != null
        ? List<int>.from(data["winningLine"])
        : null;

    /// Start line animation
    if (newLine != null && newLine.isNotEmpty) {
      if (winningLine == null) {
        winningLine = newLine;
        lineController.reset();
        lineController.forward();
      }
    } else {
      winningLine = null;
    }
  }

  /// UPDATE WINNER RESULT STATE
  void updateWinnerState(Map<String, dynamic> data) {
    String firebaseWinner = data["winner"] ?? "";
    gameOver = firebaseWinner.isNotEmpty;

    /// Show result once
    if (firebaseWinner.isNotEmpty && !hasShownResult) {
      stopTickingSound();
      hasShownResult = true;

      /// Draw match
      if (firebaseWinner == "draw") {
        gameMessage = " DRAW ";
        playDrawSound();
        if (vibrationOn) {
          playVibration(120);
        }

        /// Player win
      } else if (firebaseWinner == mySymbol) {
        gameMessage = " YOU WIN ";
        confettiController.play();
        playWinSound();
        if (vibrationOn) {
          playVibration(120);
        }

        /// Player lose
      } else {
        gameMessage = " YOU LOSE ";
        playLoseSound();
        if (vibrationOn) {
          playVibration(120);
        }
      }

      /// Reset game result state
    } else if (firebaseWinner.isEmpty) {
      hasShownResult = false;
      gameMessage = "";
      isTimeUp = false;
      gameOver = false;
    }
  }

  /// HANDLE REMATCH SYSTEM
  void handleRematch(Map<String, dynamic> data) {
    final rematch = data["rematch"];

    if (rematch == null) return;
    String requestedBy = rematch["requestedBy"] ?? "";
    String status = rematch["status"] ?? "";
    String cancelledBy = rematch["cancelledBy"] ?? "";

    /// Unique rematch action key
    String actionKey = "$status-$requestedBy-$cancelledBy";

    /// REMATCH ACCEPTED
    if (requestedBy == myId && status == "accepted") {
      closeDialogSafe();
      lastRematchAction = "";

      if (!isRestarting) {
        isRestarting = true;

        /// Reset timer
        timerController.stop();
        timerController.reset();
        stopTickingSound();

        /// Restart game safely
        WidgetsBinding.instance.addPostFrameCallback((_) {
          restartGame();
        });
      }
    }

    /// REMATCH REJECTED
    if (status == "rejected") {
      closeDialogSafe();
      stopTickingSound();

      /// Prevent duplicate toast
      if (lastRematchAction != actionKey) {
        lastRematchAction = actionKey;

        /// Sender side
        if (cancelledBy != myId) {
          if (vibrationOn) {
            HapticFeedback.mediumImpact();
          }

          CustomToast.show(
            context: context,
            message: "Opponent rejected!",
            isDark: isDark,
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
          );
        }
      }
    }

    /// REMATCH CANCELLED
    if (status == "" && requestedBy == "" && cancelledBy.isNotEmpty) {
      closeDialogSafe();
      stopTickingSound();

      /// Prevent duplicate toast
      if (lastRematchAction != actionKey) {
        lastRematchAction = actionKey;

        /// Opponent side
        if (cancelledBy != myId) {
          if (vibrationOn) {
            HapticFeedback.mediumImpact();
          }

          CustomToast.show(
            context: context,
            message: "Opponent cancelled!",
            isDark: isDark,
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
          );
        }
      }

      /// Cleanup cancelled state
      roomRef.child("rematch/cancelledBy").remove();
    }

    /// Reset rematch action tracker
    if (status == "" && requestedBy == "" && cancelledBy == "") {
      lastRematchAction = "";
    }

    /// Auto delete empty room
    final players = data["players"];

    if (players == null || players.isEmpty) {
      roomRef.remove();
    }

    /// Opponent received rematch request
    if (status == "pending" &&
        requestedBy.isNotEmpty &&
        requestedBy != myId &&
        !dialogOpen) {
      dialogOpen = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showRematchDialog();
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }
      });
    }

    /// Close rematch dialog
    if ((status == "" || status == "rejected") && dialogOpen) {
      closeDialogSafe();
    }
  }

  /// UPDATE PLAYER SCORES
  void updateScore(Map<String, dynamic> data) {
    final score = data["score"];

    if (score == null) return;
    player1Score = score["player1"] ?? 0;
    player2Score = score["player2"] ?? 0;
  }

  /// HANDLE HEARTBEAT / OPPONENT CONNECTION
  void handleHeartbeat(Map<String, dynamic> data) {
    final pings = data["pings"];

    /// No ping data
    if (pings == null || opponentId == "Waiting...") {
      return;
    }

    /// Opponent player key
    String oppKey = mySymbol == player1Symbol ? "player2" : "player1";

    int oppPing = pings[oppKey] ?? -1;

    /// New opponent ping received
    if (oppPing != -1 && oppPing != lastOpponentPingValue) {
      lastOpponentPingValue = oppPing;

      /// Save latest heartbeat time
      lastPingReceivedLocalTime = DateTime.now().millisecondsSinceEpoch;

      /// Opponent reconnected
      if (isDisconnectDialogOpen) {
        isDisconnectDialogOpen = false;

        if (disconnectDialogCtx != null && mounted) {
          if (Navigator.of(
            disconnectDialogCtx!,
            rootNavigator: true,
          ).canPop()) {
            Navigator.of(disconnectDialogCtx!, rootNavigator: true).pop();
          }

          disconnectDialogCtx = null;

          CustomToast.show(
            context: context,
            message: "Opponent Reconnected!",
            isDark: isDark,
            icon: Icons.wifi_find_rounded,
            color: Colors.green,
          );
        }
      }
    }
  }

  /// HANDLE PLAYER EXIT STATUS
  void handleExitStatus(Map<String, dynamic> data) {
    final exitStatus = data["exitStatus"];

    if (exitStatus == null) return;

    /// Player exit states
    String p1Status = exitStatus["player1"]?.toString() ?? "online";
    String p2Status = exitStatus["player2"]?.toString() ?? "online";

    /// Current player key
    String myKey = mySymbol == player1Symbol ? "player1" : "player2";

    /// Opponent status
    String opponentStatus = myKey == "player1" ? p2Status : p1Status;

    /// Opponent exited match
    if (opponentStatus == "exited" && !opponentExitDialogShown) {
      opponentExitDialogShown = true;

      /// Close disconnect dialog
      if (isDisconnectDialogOpen && disconnectDialogCtx != null && mounted) {
        isDisconnectDialogOpen = false;

        if (Navigator.of(disconnectDialogCtx!, rootNavigator: true).canPop()) {
          Navigator.of(disconnectDialogCtx!, rootNavigator: true).pop();
        }

        disconnectDialogCtx = null;
      }

      /// Show opponent exit dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          /// Close existing exit dialog
          if (isExitDialogOpen) {
            final navigator = Navigator.of(context, rootNavigator: true);
            if (navigator.canPop()) {
              navigator.pop();
            }
            isExitDialogOpen = false;
          }
          stopTickingSound();
          if (vibrationOn) {
            HapticFeedback.mediumImpact();
          }
          showOpponentExitDialog();
        }
      });
    }
  }

  /// SYNC ONLINE TURN TIMER
  void syncTimer() {
    /// Stop timer after game over
    if (gameOver) {
      timerController.stop();
      return;
    }

    /// Wait until first move starts timer
    if (serverStartTime == 0) {
      timerController.stop();
      timerController.reset();
      return;
    }

    int now = DateTime.now().millisecondsSinceEpoch;

    /// Elapsed time from server
    double elapsedMs = (now - serverStartTime).toDouble();

    double durationMs = turnDuration * 1000;

    /// Calculate timer progress
    double progress = (elapsedMs / durationMs).clamp(0.0, 1.0);

    timerController.value = progress;

    /// Continue remaining timer animation
    if (!timerController.isAnimating && progress < 1.0) {
      timerController.animateTo(
        1.0,

        duration: Duration(milliseconds: ((1 - progress) * durationMs).toInt()),

        curve: Curves.linear,
      );
    }

    /// Handle time up
    if (progress >= 1.0 && !gameOver && !isTimeUp) {
      isTimeUp = true;
      gameOver = true;
      stopTickingSound();
      timerController.stop();
      onTimeUpOnline();
    }
  }

  /// HANDLE ONLINE TIME UP
  Future<void> onTimeUpOnline() async {
    /// Safety check
    if (!isTimeUp || gameOver == false) return;

    /// Opponent becomes winner
    String winner = currentTurn == "X" ? "O" : "X";

    /// Load current score
    final snapshot = await roomRef.child("score").get();
    int p1Score = snapshot.child("player1").value as int? ?? 0;
    int p2Score = snapshot.child("player2").value as int? ?? 0;

    /// Increase winner score
    if (winner == player1Symbol) {
      p1Score++;
    } else {
      p2Score++;
    }

    stopTickingSound();

    /// Update Firebase result
    await roomRef.update({
      "winner": winner,
      "currentTurn": "",
      "score/player1": p1Score,
      "score/player2": p2Score,

      /// Mark timeout state
      "timeUp": true,
    });
  }

  /// GET REMAINING TURN TIME
  int getTimeLeft() {
    return (turnDuration * (1 - timerController.value))
        .clamp(0, turnDuration)
        .toInt();
  }

  @override
  Widget build(BuildContext context) {
    /// Current player score mapping
    int myScore = 0;
    int opponentScore = 0;

    if (mySymbol == player1Symbol) {
      myScore = player1Score;
      opponentScore = player2Score;
    } else {
      myScore = player2Score;
      opponentScore = player1Score;
    }

    /// Theme colors
    Color boardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;
    Color cellColor = isDark
        ? const Color(0xFF1F2A44)
        : const Color(0xFFF0F0F0);
    Color textColor = isDark ? Colors.white : Colors.black;

    return PopScope(
      /// Block system back
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        /// Show exit dialog
        showExitDialog(); // 🔥 dialog show
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          backgroundColor: isDark ? Color(0xFF2B3A5A) : Color(0xFFF5F5F0),
          elevation: 0,

          /// BACK BUTTON
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Tooltip(
              message: "Back",
              child: GestureDetector(
                onTap: () async {
                  //await handleBackPress();
                  //playVibration(120);
                  if (vibrationOn) {
                    HapticFeedback.lightImpact();
                  }

                  /// Show exit dialog
                  showExitDialog();
                },
                child: build3DIconButton(
                  icon: Icons.arrow_back,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          /// TITLE
          title: GestureDetector(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                /// Main title
                Text(
                  "Online Match",

                  style: TextStyle(
                    color: isDark ? Colors.cyanAccent : Colors.blue,

                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                /// Board size info
                Text(
                  "Board Size : ${boardSize} x $boardSize",

                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,

                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          centerTitle: true,

          /// SETTINGS BUTTON
          actions: [
            Padding(
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
            /// BACKGROUND GRADIENT
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

            /// CONFETTI EFFECT
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

            /// MAIN CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center, // 🔥 CENTER
                  children: [
                    const SizedBox(height: 20),

                    /// SCORE SECTION
                    Row(
                      children: [
                        /// MY SCORE
                        scoreBox("You", mySymbol, boardColor, textColor),

                        const SizedBox(width: 10),

                        /// CENTER SCORE
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 80,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: boardColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$myScore - $opponentScore",
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// OPPONENT SCORE
                        scoreBox(
                          opponentId,
                          mySymbol == "X" ? "O" : "X",
                          boardColor,
                          textColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// TURN TIMER
                    if (!gameOver)
                      AnimatedBuilder(
                        animation: timerController,
                        builder: (context, _) {
                          int timeLeft = getTimeLeft();

                          return Text(
                            "Time: $timeLeft s ",
                            style: TextStyle(
                              color: timeLeft <= 5 ? Colors.red : textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),

                    /// TIME UP TEXT
                    if (isTimeUp)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "TIME'S UP",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    /// TURN STATUS
                    if (gameMessage == "")
                      Text(
                        currentTurn == mySymbol ? "Your Turn" : "Opponent Turn",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// RESULT MESSAGE
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

                          /// WIN COLORS
                          if (gameMessage.contains("WIN")) {
                            gradientColors = [
                              Colors.greenAccent,
                              Colors.blueAccent,
                            ];

                            /// LOSE COLORS
                          } else if (gameMessage.contains("LOSE")) {
                            gradientColors = [Colors.redAccent, Colors.orange];
                          }
                          /// DRAW COLORS
                          else {
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
                                    /// OUTER GLOW BORDER
                                    gradient: LinearGradient(
                                      colors: gradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(20),

                                    boxShadow: [
                                      BoxShadow(
                                        color: gradientColors.first.withValues(
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
                                        /// GRADIENT STROKE TEXT
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

                                        /// MAIN RESULT TEXT
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

                    /// GAME BOARD
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 320,
                        height: 320,
                        padding: const EdgeInsets.all(1.5),

                        decoration: BoxDecoration(
                          /// OUTER BORDER
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.blueAccent,
                              Colors.deepOrange,
                              Colors.blueAccent,
                            ],
                          ),
                          boxShadow: [
                            /// OUTER GLOW
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),

                            /// DEPTH SHADOW
                            const BoxShadow(
                              color: Colors.black26,
                              offset: Offset(4, 4),
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

                          /// BOARD STACK
                          child: Stack(
                            children: [
                              /// BOARD GRID
                              GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),

                                itemCount: boardSize * boardSize,

                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: boardSize,
                                    ),

                                itemBuilder: (context, index) {
                                  /// SYMBOL SIZE
                                  double symbolSize = boardSize <= 3
                                      ? 40
                                      : boardSize <= 5
                                      ? 28
                                      : boardSize <= 7
                                      ? 18
                                      : 13;

                                  /// LAST MOVE HIGHLIGHT
                                  bool highlight = index == lastMove;

                                  /// WINNING CELL
                                  bool win =
                                      winningLine != null &&
                                      winningLine!.contains(index);

                                  return GestureDetector(
                                    /// HANDLE CELL TAP
                                    onTap: (gameOver || isTimeUp)
                                        ? null
                                        : () => handleTap(index),

                                    child: AnimatedScale(
                                      scale: pressedIndex == index ? 0.92 : 1,
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),

                                      child: Container(
                                        margin: EdgeInsets.all(
                                          boardSize <= 3
                                              ? 6
                                              : boardSize <= 5
                                              ? 3
                                              : boardSize <= 7
                                              ? 1.5
                                              : 0.8,
                                        ),

                                        decoration: BoxDecoration(
                                          color: cellColor,

                                          borderRadius: BorderRadius.circular(
                                            boardSize <= 5
                                                ? 12
                                                : boardSize <= 7
                                                ? 8
                                                : 5,
                                          ),

                                          /// FILLED CELL BORDER
                                          border:
                                              (board.length > index &&
                                                  board[index] != "")
                                              ? Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF47798A)
                                                      : const Color(0xFF9ED3E8),
                                                  width: 1,
                                                )
                                              : null,

                                          boxShadow: [
                                            /// LAST MOVE GLOW
                                            if (highlight)
                                              const BoxShadow(
                                                color: Colors.blueAccent,
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),

                                            /// WIN GLOW
                                            if (win)
                                              const BoxShadow(
                                                color: Colors.green,
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                          ],
                                        ),

                                        child: Center(
                                          child:
                                              (board.length > index &&
                                                  board[index] == "X")
                                              ? GameX(size: symbolSize)
                                              : (board.length > index &&
                                                    board[index] == "O")
                                              ? GameO(size: symbolSize)
                                              : const SizedBox(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              /// WIN LINE ANIMATION
                              if (winningLine != null)
                                AnimatedBuilder(
                                  animation: lineAnimation,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: const Size(320, 320),
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

                    const SizedBox(height: 30),

                    /// GAME END BUTTONS
                    if (gameMessage != "")
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// EXIT BUTTON
                            NeonGlowingButton(
                              text: "Exit",
                              icon: Icons.exit_to_app,
                              onTap: () {
                                //playVibration(120);
                                if (vibrationOn) {
                                  HapticFeedback.mediumImpact();
                                }

                                /// SHOW EXIT DIALOG
                                showExitDialog();
                              },

                              isDark: isDark,
                              glowController: glowController,
                              glowAnimation: glowAnimation,
                            ),

                            /// REPLAY BUTTON
                            NeonGlowingButton(
                              text: "Replay",
                              icon: Icons.refresh,
                              onTap: handleReplayRequest,
                              isDark: isDark,
                              glowController: glowController,
                              glowAnimation: glowAnimation,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// HANDLE REMATCH REQUEST
  Future<void> handleReplayRequest() async {
    /// PREVENT MULTIPLE REQUESTS
    if (isSendingReplay) return;

    isSendingReplay = true;

    if (vibrationOn) {
      HapticFeedback.mediumImpact();
    }

    try {
      /// SEND REMATCH REQUEST
      await roomRef.child("rematch").update({
        "requestedBy": myId,
        "status": "pending",
      });

      /// SHOW WAITING DIALOG
      showRematchWaitingDialog();
    } catch (e) {
      print("Replay Error: $e");

      if (vibrationOn) {
        HapticFeedback.mediumImpact();
      }

      /// ERROR TOAST
      CustomToast.show(
        context: context,
        message: "Something went wrong!",
        isDark: isDark,
        icon: Icons.error_outline_rounded,
        color: Colors.redAccent,
      );
    } finally {
      /// RESET FLAG
      isSendingReplay = false;
    }
  }

  /// REMATCH WAITING DIALOG
  Future<void> showRematchWaitingDialog() async {
    dialogOpen = true;

    await showAppDialog(
      context: context,
      title: "REMATCH REQUEST",
      message: "Waiting for opponent response...\nPlease stay connected.",
      positiveText: "",
      negativeText: "CANCEL",
      barrierDismissible: false,
      showContentLoading: true,

      /// CANCEL REQUEST
      onNegative: () async {
        dialogOpen = false;
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }

        LoadingDialog.show(context, message: "Cancelling Request...");

        try {
          /// RESET REMATCH DATA
          await roomRef.child("rematch").set({
            "requestedBy": "",
            "status": "",
            "cancelledBy": myId,
          });

          /// CANCEL SUCCESS TOAST
          CustomToast.show(
            context: context,
            message: "Request cancelled!",
            isDark: isDark,
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
          );
        } catch (e) {
          print("Rematch cancel error: $e");
        } finally {
          LoadingDialog.hide(context);
        }

        //showToast("Request cancelled ❌");
      },
    );
  }

  /// REMATCH REQUEST DIALOG
  Future<void> showRematchDialog() async {
    dialogOpen = true;

    await showAppDialog(
      context: context,
      title: "REMATCH REQUEST",
      message:
          "Your opponent wants another battle.\nDo you want to play again?",

      positiveText: "PLAY",
      negativeText: "DECLINE",
      barrierDismissible: false,

      /// DECLINE REQUEST
      onNegative: () async {
        dialogOpen = false;
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }

        LoadingDialog.show(context, message: "Declining Request...");

        try {
          /// UPDATE REMATCH STATUS
          await roomRef.child("rematch").update({
            "status": "rejected",
            "cancelledBy": myId,
          });

          /// SELF TOAST
          CustomToast.show(
            context: context,
            message: "Replay rejected!",
            isDark: isDark,
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
          );
        } catch (e) {
          print("Rematch reject error: $e");
        } finally {
          LoadingDialog.hide(context);
        }
      },

      /// ACCEPT REMATCH
      onPositive: () async {
        dialogOpen = false;
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }

        LoadingDialog.show(context, message: "Starting Rematch...");

        try {
          /// ACCEPT REQUEST
          await roomRef.child("rematch").update({"status": "accepted"});
        } catch (e) {
          print("Rematch accept error: $e");
        } finally {
          LoadingDialog.hide(context);
        }
      },
    );
  }

  /// OPPONENT DISCONNECT DIALOG
  Future<void> showOpponentDisconnectDialog() async {
    isDisconnectDialogOpen = true;

    await showAppDialog(
      context: context,

      /// SAVE DIALOG CONTEXT
      onDialogCreated: (dialogContext) {
        disconnectDialogCtx = dialogContext;
      },
      title: "CONNECTION LOST",
      message: "Opponent disconnected.\nWaiting for reconnection...",
      positiveText: "",
      negativeText: "LEAVE GAME",
      barrierDismissible: false,
      showContentLoading: true,

      /// LEAVE GAME
      onNegative: () async {
        isDisconnectDialogOpen = false;

        disconnectDialogCtx = null;
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }

        /// CLOSE CURRENT DIALOG
        final navigator = Navigator.of(context, rootNavigator: true);

        if (navigator.canPop()) {
          navigator.pop();
        }

        /// SMALL DELAY
        await Future.delayed(const Duration(milliseconds: 100));

        /// SAFE EXIT
        await exitFromGame();
      },
    ).then((_) {
      /// RESET FLAGS
      disconnectDialogCtx = null;
      isDisconnectDialogOpen = false;
    });
  }

  /// EXIT MATCH DIALOG
  Future<void> showExitDialog() async {
    isExitDialogOpen = true;
    await showAppDialog(
      context: context,
      title: "EXIT ROOM",
      message: "Exit and end the match?",
      positiveText: "EXIT",
      negativeText: "CANCEL",
      barrierDismissible: false,

      /// CANCEL EXIT
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// SAFETY RESET
        isExitDialogOpen = false;

        /// nothing needed
      },

      /// CONFIRM EXIT
      onPositive: () async {
        isExitDialogOpen = false;
        await exitFromGame();
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }
      },
    );

    /// SAFETY RESET
    isExitDialogOpen = false;
  }

  /// EXIT FROM ONLINE GAME
  Future<void> exitFromGame() async {
    /// STOP TIMER & HEARTBEAT
    stopTickingSound();
    heartbeatTimer?.cancel();

    String playerKey = mySymbol == player1Symbol ? "player1" : "player2";

    /// MARK PLAYER EXIT
    await roomRef.child("exitStatus/$playerKey").set("exited");

    /// RESET REMATCH DATA
    await roomRef.child("rematch").set({"requestedBy": "", "status": ""});

    /// GET CURRENT EXIT STATUS
    final snapshot = await roomRef.child("exitStatus").get();

    String p1Status = snapshot.child("player1").value?.toString() ?? "online";

    String p2Status = snapshot.child("player2").value?.toString() ?? "online";

    /// CHECK OPPONENT HEARTBEAT
    bool isOpponentDead = false;

    if (lastPingReceivedLocalTime > 0) {
      int now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastPingReceivedLocalTime > 12000) {
        isOpponentDead = true;
      }
    }

    /// REMOVE ROOM IF BOTH LEFT
    if ((p1Status == "exited" && p2Status == "exited") || isOpponentDead) {
      await roomRef.remove();
    } else {
      /// NOTIFY OPPONENT
      await roomRef.update({"roomStatus": "ended", "exitBy": myId});
    }

    /// CLOSE GAME PAGE
    closeGamePage();
  }

  /// OPPONENT EXIT DIALOG
  Future<void> showOpponentExitDialog() async {
    await showAppDialog(
      context: context,

      title: "OPPONENT LEFT",
      message: "Your opponent has left the match.\nThe room will be closed.",
      positiveText: "EXIT",
      negativeText: "",
      barrierDismissible: false,

      /// EXIT GAME
      onPositive: () async {
        heartbeatTimer?.cancel();
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }

        ///  REMOVE ROOM
        await roomRef.remove();

        ///  CLOSE PAGE
        closeGamePage();
      },
    );
  }

  /// SAFE DIALOG CLOSE
  void closeDialogSafe() {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);

    if (dialogOpen && navigator.canPop()) {
      navigator.pop();

      dialogOpen = false;
    }
  }

  /// RESTART ONLINE MATCH
  Future<void> restartGame() async {
    /// PREVENT MULTIPLE RESET
    if (isReplayResetting) return;

    LoadingDialog.show(context, message: "Restarting Match...\n Please Wait");
    isReplayResetting = true;

    /// RANDOM START PLAYER
    String nextStart = Random().nextBool() ? "X" : "O";

    /// HARD RESET TIMER
    timerController.stop();
    timerController.reset();
    stopTickingSound();

    serverStartTime = 0;
    hasFirstMove = false;

    /// LOCAL UI RESET
    if (mounted) {
      setState(() {
        winningLine = null;
        gameMessage = "";
        lastMove = -1;
        hasShownResult = false;
        gameOver = false;
        isTimeUp = false;
      });
    }

    try {
      /// FIREBASE GAME RESET
      await roomRef.update({
        "board": List.filled(boardSize * boardSize, ""),
        "winner": "",
        "winningLine": [],
        "currentTurn": nextStart,
        "lastMove": -1,

        "timerStart": 0,
        "matchStarted": false,
        "turnDuration": 30,

        "timeUp": false,
      });

      /// SMALL DELAY
      await Future.delayed(const Duration(milliseconds: 300));

      /// RESET REMATCH DATA
      await roomRef.child("rematch").set({"requestedBy": "", "status": ""});

      /// RESET EFFECTS
      confettiController.stop();
      lineController.reset();
      isRestarting = false;
      isReplayResetting = false;
    } catch (e) {
      print("Restart error: $e");
    } finally {
      LoadingDialog.hide(context);
    }
  }

  /// NO INTERNET DIALOG
  Future<void> noInternetDialog() async {
    /// PREVENT MULTIPLE DIALOG
    if (isDialogOpen) return;

    isDialogOpen = true;

    await showAppDialog(
      context: context,

      /// SAVE DIALOG CONTEXT
      onDialogCreated: (dialogContext) {
        internetDialogCtx = dialogContext;
      },

      title: "NO INTERNET",
      message: "Connection lost.\nWaiting for internet connection...",
      positiveText: "",
      negativeText: "EXIT",
      barrierDismissible: false,
      showContentLoading: true,

      ///  EXIT GAME
      onNegative: () async {
        isDialogOpen = false;
        internetDialogCtx = null;
        stopTickingSound();

        /// CLOSE GAME PAGE
        closeGamePage();
      },
    ).then((_) {
      /// RESET FLAGS
      isDialogOpen = false;
      internetDialogCtx = null;
    });
  }

  /// SETTINGS MENU
  void showSettingsMenu() {
    showGlassSettingsMenu(
      context: context,
      isDark: isDark,

      items: [
        ///  THEME
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
              HapticFeedback.selectionClick();
            }

            setState(() {
              isDark = value;
            });

            /// SAVE THEME
            await prefs.setBool("theme_dark", isDark);
          },
        ),

        ///  SOUND
        SettingsMenuItem(
          iconBuilder: (value) {
            return value ? Icons.volume_up : Icons.volume_off;
          },
          title: "Sound",
          value: soundOn,
          onChanged: (value) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            if (vibrationOn) {
              HapticFeedback.mediumImpact();
            }

            setState(() {
              soundOn = value;
            });

            /// SAVE SOUND
            await prefs.setBool("sound_on", soundOn);
          },
        ),

        /// VIBRATION
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

            /// SAVE VIBRATION
            await prefs.setBool("vibration_on", vibrationOn);
          },
        ),
      ],
    );
  }

  /// PLAYER SCORE BOX
  Widget scoreBox(String player, String symbol, Color bg, Color textColor) {
    /// ACTIVE PLAYER TURN
    bool isActive = !gameOver && currentTurn == symbol;

    /// SYMBOL GLOW COLORS
    List<Color> gradientColors = symbol == "X"
        ? [Colors.blueAccent, Colors.cyanAccent]
        : [Colors.orangeAccent, Colors.deepOrange];

    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        /// ACTIVE GLOW VALUE
        double glowValue = isActive ? glowAnimation.value : 0;

        return Stack(
          children: [
            /// MAIN SCORE BOX
            Container(
              width: 100,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// PLAYER SYMBOL
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

                  const SizedBox(height: 2),

                  /// PLAYER NAME
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textSpan = TextSpan(
                        text: player,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      );

                      final textPainter = TextPainter(
                        text: textSpan,
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      )..layout();

                      double textWidth = textPainter.width;
                      double boxWidth = constraints.maxWidth;

                      /// AUTO SCROLL FOR LONG NAME
                      if (textWidth > boxWidth) {
                        return SizedBox(
                          height: 18,
                          child: ClipRect(
                            child: SingleChildScrollView(
                              controller: nameScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Text(
                                player,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        /// NORMAL TEXT
                        return Center(
                          child: Text(
                            player,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            ///  TIMER BORDER (NEW)
            if (isActive)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: timerController,
                  builder: (context, child) {
                    int timeLeft = getTimeLeft();

                    ///  LAST 5 SEC ALERT
                    if (timeLeft <= 5 && timeLeft > 0) {
                      if (timeLeft != lastAlertSecond) {
                        lastAlertSecond = timeLeft;

                        /// TICK SOUND
                        if (soundOn) {
                          clockSoundPlayer.stop();
                          clockSoundPlayer.play(AssetSource("audio/tick.mp3"));
                        }

                        /// VIBRATION ALERT
                        if (vibrationOn) {
                          HapticFeedback.mediumImpact();
                        }
                      }
                    }

                    /// TIMER BORDER COLOR
                    Color dynamicColor;

                    if (timeLeft <= 5) {
                      /// RED WARNING COLOR
                      dynamicColor = Colors.red;
                    } else {
                      /// PLAYER COLOR
                      dynamicColor = symbol == "X"
                          ? Colors.blueAccent
                          : Colors.orangeAccent;
                    }

                    return CustomPaint(
                      painter: TimerBorderPainter(
                        /// REVERSE TIMER PROGRESS
                        1 - timerController.value,
                        dynamicColor,
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
} //////////////////////////////////////////////////////end main class

/// GET REQUIRED WIN LENGTH
int getWinLength(int size) {
  if (size <= 4) return size; // 3→3, 4→4
  if (size <= 6) return 4; // 5,6 → 4
  return 5; // 7,8,9 → 5
}

/// DYNAMIC WINNER CHECK
Map<String, dynamic> checkWinnerDynamic(List<String> b, int size) {
  int winLen = getWinLength(size);

  /// CHECK ALL CELLS
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      /// CURRENT CELL VALUE
      String current = b[i * size + j];

      /// SKIP EMPTY CELL
      if (current.isEmpty) continue;

      List<int> tempLine = [];

      /// HORIZONTAL CHECK
      if (j + winLen <= size) {
        bool win = true;
        tempLine.clear();

        for (int k = 0; k < winLen; k++) {
          int idx = i * size + (j + k);
          if (b[idx] != current) {
            win = false;
            break;
          }
          tempLine.add(idx);
        }

        /// WIN FOUND
        if (win) return {"winner": current, "line": tempLine};
      }

      /// VERTICAL CHECK
      if (i + winLen <= size) {
        bool win = true;
        tempLine.clear();

        for (int k = 0; k < winLen; k++) {
          int idx = (i + k) * size + j;
          if (b[idx] != current) {
            win = false;
            break;
          }
          tempLine.add(idx);
        }

        /// WIN FOUND
        if (win) return {"winner": current, "line": tempLine};
      }

      /// DIAGONAL CHECK
      if (i + winLen <= size && j + winLen <= size) {
        bool win = true;
        tempLine.clear();

        for (int k = 0; k < winLen; k++) {
          int idx = (i + k) * size + (j + k);
          if (b[idx] != current) {
            win = false;
            break;
          }
          tempLine.add(idx);
        }

        /// WIN FOUND
        if (win) return {"winner": current, "line": tempLine};
      }

      /// DIAGONAL CHECK
      if (i + winLen <= size && j - winLen + 1 >= 0) {
        bool win = true;
        tempLine.clear();

        for (int k = 0; k < winLen; k++) {
          int idx = (i + k) * size + (j - k);
          if (b[idx] != current) {
            win = false;
            break;
          }
          tempLine.add(idx);
        }

        /// WIN FOUND
        if (win) return {"winner": current, "line": tempLine};
      }
    }
  }

  /// DRAW CONDITION
  if (!b.contains("")) return {"winner": "draw", "line": []};

  /// NO WINNER YET
  return {"winner": "", "line": []};
}

/// TIMER BORDER PAINTER
class TimerBorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  TimerBorderPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    /// MAIN RECTANGLE AREA
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    /// BORDER PAINT
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    /// ROUNDED BORDER PATH
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));

    /// GET PATH LENGTH
    final metric = path.computeMetrics().first;

    /// EXTRACT ANIMATED BORDER PATH
    final extractPath = metric.extractPath(0, metric.length * progress);

    /// DRAW TIMER BORDER
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant TimerBorderPainter oldDelegate) {
    /// REPAINT WHEN TIMER OR COLOR CHANGES
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

///////////////////////////////////////
