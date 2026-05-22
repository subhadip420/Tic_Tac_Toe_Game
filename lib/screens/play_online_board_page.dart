import 'dart:async';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/game_symbols.dart';
import '../widgets/build_circle_icon_button.dart';
import '../widgets/custom_toast.dart';
import '../widgets/glass_settings_menu.dart';
import '../widgets/loading_dialog_with_button.dart';
import '../widgets/neon_glowing_button.dart';
import 'two_player_draw_board_page.dart';
import '../../widgets/loading_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // 🔥 for kIsWeb
import 'package:http/http.dart' as http;
import 'web_listener_stub.dart' if (dart.library.html) 'web_listener.dart';
import 'package:marquee/marquee.dart';

class PlayOnlineBoardPage extends StatefulWidget {
  final String roomCode;

  const PlayOnlineBoardPage({super.key, required this.roomCode});

  @override
  State<PlayOnlineBoardPage> createState() => _PlayOnlineBoardPageState();
}

class _PlayOnlineBoardPageState extends State<PlayOnlineBoardPage>
    with TickerProviderStateMixin {
  int boardSize = 3;
  List<String> board = [];

  late ConfettiController confettiController;
  late AnimationController glowController;
  late Animation<double> glowAnimation;
  late AnimationController lineController;
  late Animation<double> lineAnimation;

  final ScrollController nameScrollController = ScrollController();
  late AnimationController nameScrollAnim;

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

  String gameMessage = "";

  int player1Score = 0;
  int player2Score = 0;

  bool isDark = true; // default dark
  bool soundOn = true; // default sound on
  bool vibrationOn = true;
  bool resetPressed = false;

  String player1Symbol = "";
  String player2Symbol = "";

  bool player1Turn = true;
  bool isPlayer1First = true;

  late DatabaseReference roomRef;
  late DatabaseReference dbRef;

  String currentTurn = "";
  String mySymbol = "";

  String myId = "";
  String opponentId = "";

  bool isRestarting = false;
  bool dialogOpen = false;
  bool hasShownResult = false;
  bool disconnectSetupDone = false;
  bool disconnectDialogShown = false;
  bool isOfflineDialogShown = false;
  late StreamSubscription connectivitySubscription;

  bool isDialogOpen = false;
  BuildContext? disconnectDialogCtx;
  bool opponentExitDialogShown = false;
  StreamSubscription? presenceSubscription;

  List<String> previousBoard = [];
  double resendProgress = 0;
  int resendCooldown = 0;
  Timer? resendTimer;

  // 🔥 Heartbeat System Variables
  // 🔥 Heartbeat System Variables
  Timer? heartbeatTimer;
  int lastPingReceivedLocalTime = 0; // 🔥 100% Local Time
  int lastOpponentPingValue = -1;
  int myPingCounter = 0;
  bool isDisconnectDialogOpen = false;
  BuildContext? internetDialogCtx;
  bool isRoomActive = true;
  bool isGamePageClosed = false;
  bool hasFirstMove = false;
  late AnimationController timerController;

  int turnDuration = 30;
  int serverStartTime = 0;
  bool isReplayResetting = false;
  bool isSendingReplay = false;
  bool isTimeUp = false;
  int lastAlertSecond = -1;
  bool isExitDialogOpen = false;
  String lastRematchAction = "";

  // @override
  // void initState() {
  //   super.initState();
  //
  //   dbRef = FirebaseDatabase.instanceFor(
  //     app: FirebaseDatabase.instance.app,
  //     databaseURL:
  //         "https://tic-tac-toe-9c3bf-default-rtdb.asia-southeast1.firebasedatabase.app/",
  //   ).ref();
  //
  //   roomRef = dbRef.child("rooms/${widget.roomCode}");
  //
  //   listenToGame();
  //   startHeartbeat();
  //
  //   timerController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(seconds: 30),
  //   );
  //
  //   lineController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 600),
  //   );
  //
  //   lineAnimation = CurvedAnimation(
  //     parent: lineController,
  //     curve: Curves.easeInOut,
  //   );
  //
  //   confettiController = ConfettiController(
  //     duration: const Duration(seconds: 3),
  //   );
  //
  //   glowController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(seconds: 2),
  //   )..repeat(reverse: true);
  //
  //   glowAnimation = Tween<double>(
  //     begin: 0.4,
  //     end: 1,
  //   ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));
  //
  //   connectivitySubscription = Connectivity().onConnectivityChanged.listen((
  //     _,
  //   ) async {
  //     // ❌ WEB skip karo
  //     if (kIsWeb) return;
  //
  //     bool hasInternet = await checkInternet();
  //
  //     // 🔴 OFFLINE
  //     if (!hasInternet) {
  //       if (!isOfflineDialogShown) {
  //         isOfflineDialogShown = true;
  //
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           noInternetDialog();
  //         });
  //       }
  //     }
  //     // 🟢 ONLINE BACK
  //     else {
  //       if (isOfflineDialogShown) {
  //         isOfflineDialogShown = false;
  //
  //         // 🔥 Safe Pop: গেম পেজ না কেটে শুধু ইন্টারনেট ডায়ালগটাই কাটবে
  //         if (mounted && internetDialogCtx != null) {
  //
  //           /// 🔥 CLOSE INTERNET DIALOG
  //           final navigator = Navigator.of(context, rootNavigator: true);
  //
  //           if (isDialogOpen && navigator.canPop()) {
  //             navigator.pop();
  //
  //             isDialogOpen = false;
  //
  //             internetDialogCtx = null;
  //           }
  //           internetDialogCtx = null;
  //         }
  //
  //         showToast("Reconnected ✅");
  //
  //         // 💥 সার্ভারে কোনো ডেটা পাঠানোর আগে চেক করো রুমটা বেঁচে আছে কিনা!
  //         final snapshot = await roomRef.get();
  //         if (!snapshot.exists) {
  //           // রুম আগেই ডিলিট হয়ে গেছে, তাই চুপচাপ বেরিয়ে যাও
  //           heartbeatTimer?.cancel();
  //           // 💥 THE FIX: অটো-ব্যাক না করে ডায়ালগ দেখাও
  //           if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
  //             opponentExitDialogShown = true;
  //             WidgetsBinding.instance.addPostFrameCallback((_) {
  //               if (mounted) showOpponentExitDialog();
  //             });
  //           }
  //           return;
  //         }
  //
  //         // 💥 THE FIX: অনলাইনে ফেরার সাথে সাথে ঘড়ি রিসেট করে দিলাম!
  //         lastPingReceivedLocalTime = DateTime.now().millisecondsSinceEpoch;
  //
  //         if (mySymbol.isNotEmpty) {
  //           String playerKey = mySymbol == player1Symbol
  //               ? "player1"
  //               : "player2";
  //           roomRef.child("exitStatus/$playerKey").set("online");
  //           roomRef.child("players/$playerKey").update({
  //             "uid": myId,
  //             "symbol": mySymbol,
  //           });
  //           registerPresence();
  //         }
  //       }
  //     }
  //   });
  //
  //   if (kIsWeb) {
  //     setupWebListeners(
  //       onOffline: () {
  //         if (!isOfflineDialogShown) {
  //           isOfflineDialogShown = true;
  //           noInternetDialog();
  //         }
  //       },
  //       onOnline: () async {
  //         if (isOfflineDialogShown) {
  //           isOfflineDialogShown = false;
  //
  //           // 🔥 Safe Pop Web
  //           if (mounted && internetDialogCtx != null) {
  //             //Navigator.pop(internetDialogCtx!);
  //             if (internetDialogCtx != null &&
  //                 Navigator.of(
  //                   internetDialogCtx!,
  //                   rootNavigator: true,
  //                 ).canPop()) {
  //               Navigator.of(internetDialogCtx!, rootNavigator: true).pop();
  //             }
  //             internetDialogCtx = null;
  //           }
  //
  //           showToast("Reconnected ✅");
  //         }
  //
  //         // 🔥 FIX: Update karne se pehle check karo room exist karta hai ya nahi
  //         final snapshot = await roomRef.get();
  //         if (!snapshot.exists) {
  //           heartbeatTimer?.cancel();
  //
  //           // 💥 THE FIX: ডায়ালগ দেখাও
  //           if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
  //             opponentExitDialogShown = true;
  //             WidgetsBinding.instance.addPostFrameCallback((_) {
  //               if (mounted) showOpponentExitDialog();
  //             });
  //           }
  //
  //           return;
  //         }
  //
  //         // 💥 THE FIX: এখানেও অনলাইনে ফেরার সাথে সাথে ঘড়ি রিসেট করে দিলাম!
  //         lastPingReceivedLocalTime = DateTime.now().millisecondsSinceEpoch;
  //
  //         if (mySymbol.isNotEmpty) {
  //           String playerKey = mySymbol == player1Symbol
  //               ? "player1"
  //               : "player2";
  //           roomRef.child("exitStatus/$playerKey").set("online");
  //           roomRef.child("players/$playerKey").update({
  //             "uid": myId,
  //             "symbol": mySymbol,
  //           });
  //           registerPresence();
  //         }
  //       },
  //     );
  //   }
  //
  //
  //   nameScrollAnim = AnimationController(
  //     vsync: this,
  //     duration: const Duration(seconds: 6),
  //   );
  //
  //   nameScrollAnim.addListener(() {
  //     if (nameScrollController.hasClients) {
  //       double maxScroll = nameScrollController.position.maxScrollExtent;
  //       nameScrollController.jumpTo(maxScroll * nameScrollAnim.value);
  //     }
  //   });
  //
  //   nameScrollAnim.repeat(reverse: true); // 🔥 smooth back-forth
  //
  //   timerController.addListener(() {
  //     if (timerController.value >= 1.0 && !gameOver) {
  //       print("⏰ TIME UP TRIGGERED");
  //
  //       setState(() {
  //         isTimeUp = true;
  //         gameOver = true;
  //       });
  //
  //       stopTickingSound();
  //       timerController.stop();
  //
  //       onTimeUpOnline();
  //     }
  //   });
  //
  //   loadSettings();
  // }

  @override
  void initState() {

    super.initState();

    initializeFirebase();

    initializeGame();

    initializeAnimations();

    initializeConnectivity();

    initializeWebListeners();

    initializeNameScroll();

    initializeTimerListener();

    loadSettings();
  }

  void initializeFirebase() {

    dbRef = FirebaseDatabase.instanceFor(

      app: FirebaseDatabase.instance.app,

      databaseURL:
      "https://tic-tac-toe-9c3bf-default-rtdb.asia-southeast1.firebasedatabase.app/",
    ).ref();

    roomRef =
        dbRef.child(
          "rooms/${widget.roomCode}",
        );
  }


  void initializeGame() {

    listenToGame();

    startHeartbeat();
  }

  void initializeAnimations() {

    timerController =
        AnimationController(

          vsync: this,

          duration:
          const Duration(
            seconds: 30,
          ),
        );

    lineController =
        AnimationController(

          vsync: this,

          duration:
          const Duration(
            milliseconds: 600,
          ),
        );

    lineAnimation =
        CurvedAnimation(

          parent: lineController,

          curve: Curves.easeInOut,
        );

    confettiController =
        ConfettiController(

          duration:
          const Duration(
            seconds: 3,
          ),
        );

    glowController =
    AnimationController(

      vsync: this,

      duration:
      const Duration(
        seconds: 2,
      ),
    )

      ..repeat(
        reverse: true,
      );

    glowAnimation =
        Tween<double>(

          begin: 0.4,

          end: 1,
        ).animate(

          CurvedAnimation(

            parent: glowController,

            curve: Curves.easeInOut,
          ),
        );
  }


  void initializeConnectivity() {

    connectivitySubscription =
        Connectivity()
            .onConnectivityChanged
            .listen((_) async {

          if (kIsWeb) return;

          bool hasInternet =
          await checkInternet();

          if (!hasInternet) {

            handleOffline();

          } else {

            await handleOnline();
          }
        });
  }


  void initializeWebListeners() {

    if (!kIsWeb) return;

    setupWebListeners(

      onOffline: () {

        if (!isOfflineDialogShown) {

          isOfflineDialogShown = true;
          if (vibrationOn) {HapticFeedback.mediumImpact();}
          noInternetDialog();
        }
      },

      onOnline: () async {

        await handleWebReconnect();
      },
    );
  }


  void initializeNameScroll() {

    nameScrollAnim =
        AnimationController(

          vsync: this,

          duration:
          const Duration(
            seconds: 6,
          ),
        );

    nameScrollAnim.addListener(() {

      if (nameScrollController
          .hasClients) {

        double maxScroll =
            nameScrollController
                .position
                .maxScrollExtent;

        nameScrollController.jumpTo(
          maxScroll *
              nameScrollAnim.value,
        );
      }
    });

    nameScrollAnim.repeat(
      reverse: true,
    );
  }


  void initializeTimerListener() {

    timerController.addListener(() {

      if (timerController.value >= 1.0 &&
          !gameOver) {

        print("⏰ TIME UP TRIGGERED");

        setState(() {

          isTimeUp = true;

          gameOver = true;
        });

        stopTickingSound();

        timerController.stop();

        onTimeUpOnline();
      }
    });
  }

  void handleOffline() {

    if (isOfflineDialogShown) return;

    isOfflineDialogShown = true;

    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      if (vibrationOn) {HapticFeedback.mediumImpact();}
      noInternetDialog();
    });
  }


  Future<void> handleOnline() async {

    if (!isOfflineDialogShown) return;

    isOfflineDialogShown = false;

    closeInternetDialog();

    //showToast("Reconnected ✅");
    CustomToast.show(
      context: context,
      message: "Reconnected.",
      isDark: isDark,
      icon: Icons.wifi_rounded,
      color: Colors.green,
    );

    final snapshot =
    await roomRef.get();

    if (!snapshot.exists) {

      heartbeatTimer?.cancel();

      if (mounted &&
          !isGamePageClosed &&
          !opponentExitDialogShown) {

        opponentExitDialogShown = true;

        WidgetsBinding.instance
            .addPostFrameCallback((_) {

          if (mounted) {
            showOpponentExitDialog();
          }
        });
      }

      return;
    }

    lastPingReceivedLocalTime =
        DateTime.now()
            .millisecondsSinceEpoch;

    await restorePresence();
  }


  Future<void> handleWebReconnect() async {

    if (isOfflineDialogShown) {

      isOfflineDialogShown = false;

      closeInternetDialog();

      //showToast("Reconnected ✅");
      CustomToast.show(
        context: context,
        message: "Reconnected.",
        isDark: isDark,
        icon: Icons.wifi_rounded,
        color: Colors.green,
      );
    }

    final snapshot =
    await roomRef.get();

    if (!snapshot.exists) {

      heartbeatTimer?.cancel();

      if (mounted &&
          !isGamePageClosed &&
          !opponentExitDialogShown) {

        opponentExitDialogShown = true;

        WidgetsBinding.instance
            .addPostFrameCallback((_) {

          if (mounted) {
            showOpponentExitDialog();
          }
        });
      }

      return;
    }

    lastPingReceivedLocalTime =
        DateTime.now()
            .millisecondsSinceEpoch;

    await restorePresence();
  }


  Future<void> restorePresence() async {

    if (mySymbol.isEmpty) return;

    String playerKey =
    mySymbol == player1Symbol
        ? "player1"
        : "player2";

    await roomRef
        .child("exitStatus/$playerKey")
        .set("online");

    await roomRef
        .child("players/$playerKey")
        .update({

      "uid": myId,

      "symbol": mySymbol,
    });

    registerPresence();
  }


  void closeInternetDialog() {

    if (!mounted ||
        internetDialogCtx == null) {
      return;
    }

    final navigator =
    Navigator.of(
      context,
      rootNavigator: true,
    );

    if (isDialogOpen &&
        navigator.canPop()) {

      navigator.pop();

      isDialogOpen = false;

      internetDialogCtx = null;
    }

    internetDialogCtx = null;
  }



  @override
  void dispose() {
    heartbeatTimer?.cancel();
    presenceSubscription?.cancel();

    if (mySymbol.isNotEmpty) {
      String playerKey = mySymbol == player1Symbol ? "player1" : "player2";
      roomRef.child("exitStatus/$playerKey").onDisconnect().cancel();
    }
    resendTimer?.cancel();
    confettiController.dispose();
    glowController.dispose();
    lineController.dispose();
    connectivitySubscription.cancel();
    nameScrollAnim.dispose();
    nameScrollController.dispose();
    stopTickingSound();
    super.dispose();
  }

  ///old
  // void closeGamePage() {
  //   if (!isGamePageClosed && mounted) {
  //     isGamePageClosed = true;
  //     Navigator.of(context).pop(); // এই ফাংশন গেম পেজকে মাত্র একবারই কাটতে দেবে
  //   }
  // }

  ///new
  void closeGamePage() {
    if (!mounted || isGamePageClosed) return;

    isGamePageClosed = true;

    /// 🔥 CLOSE ALL DIALOGS FIRST
    Navigator.of(context, rootNavigator: true).popUntil((route) {
      return route is PageRoute;
    });

    /// 🔥 CLOSE GAME PAGE
    Navigator.of(context).pop();
  }

  void stopTickingSound() {
    clockSoundPlayer.stop();

    lastAlertSecond = -1;
  }

  Future<bool> checkInternet() async {
    // 🌐 WEB → always true (handled by events)
    if (kIsWeb) {
      return true;
    }

    // 📱 MOBILE → real check
    try {
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<void> registerPresence() async {
    if (mySymbol.isEmpty) return;

    String playerKey = mySymbol == player1Symbol ? "player1" : "player2";

    try {
      // 💥 THE FINAL FIX: Firebase mein andha update karne se pehle check karo ki room zinda hai ya nahi!
      final snapshot = await roomRef.get();
      if (!snapshot.exists) {
        isRoomActive = false;
        return; // 🔥 Room pehle hi delete ho chuka hai, isliye yahan se chup-chap nikal jao! Kuch likhna mat.
      }

      // Agar room zinda hai, sirf tabhi status update karo
      await roomRef.child("exitStatus/$playerKey").onDisconnect().cancel();
      await roomRef.child("exitStatus/$playerKey").set("online");
    } catch (e) {
      print("Presence error: $e");
    }
  }

  void setupPresence() {
    DatabaseReference connectedRef = FirebaseDatabase.instance.ref(
      ".info/connected",
    );

    presenceSubscription?.cancel();
    presenceSubscription = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;

      // যখনই ইন্টারনেট কানেকশন পাবে, ফায়ারবেসকে আবার নতুন করে রুলস বুঝিয়ে দেবে
      if (connected) {
        registerPresence();
      }
    });
  }

  void startHeartbeat() {
    heartbeatTimer?.cancel();
    heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // 💥 THE FIX: অফলাইন থাকলে অথবা রুম ডিলিট হয়ে গেলে পিং পাঠানো বন্ধ!
      if (isOfflineDialogShown || !isRoomActive) return;

      // 1. নিজের পিং পাঠানো
      if (mySymbol.isNotEmpty) {
        String myKey = mySymbol == player1Symbol ? "player1" : "player2";
        myPingCounter++;
        roomRef.child("pings/$myKey").set(myPingCounter);
      }

      // 2. অপোনেন্ট চেক
      if (opponentId != "Waiting..." && opponentId.isNotEmpty) {
        int now = DateTime.now().millisecondsSinceEpoch;

        if (lastPingReceivedLocalTime == 0) {
          lastPingReceivedLocalTime = now;
        }

        // 🔥 ঠিক ১২ সেকেন্ড
        if (now - lastPingReceivedLocalTime > 12000) {
          // নিজের ইন্টারনেট ঠিক থাকলে তবেই ডায়ালগ আনবে
          if (!isDisconnectDialogOpen &&
              !opponentExitDialogShown &&
              !isOfflineDialogShown) {
            isDisconnectDialogOpen = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (vibrationOn) {HapticFeedback.mediumImpact();}
                showOpponentDisconnectDialog();
              }
            });
          }
        }
      }
    });
  }

  Future<void> handleTap(int index) async {
    if (gameOver || isTimeUp) return;

    if (winningLine != null) return;

    // ❌ already filled
    if (board[index] != "") return;

    // ❌ not your turn
    if (currentTurn != mySymbol) return;

    setState(() {
      pressedIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        pressedIndex = -1;
      });
    });

    // /// 🔥 FIRST MOVE START
    // if (!hasFirstMove) {
    //   hasFirstMove = true;
    // }

    List<String> newBoard = List.from(board);
    newBoard[index] = mySymbol;

    // 🔥 check winner
    final result = checkWinnerDynamic(newBoard, boardSize);

    String nextTurn = mySymbol == "X" ? "O" : "X";

    Map<String, dynamic>? scoreUpdate;

    if (result["winner"] != "" && result["winner"] != "draw") {
      final snapshot = await roomRef.child("score").get();

      int p1Score = snapshot.child("player1").value as int? ?? 0;
      int p2Score = snapshot.child("player2").value as int? ?? 0;

      // 🔥 check winner
      if (result["winner"] == player1Symbol) {
        p1Score++;
      } else {
        p2Score++;
      }

      scoreUpdate = {"score/player1": p1Score, "score/player2": p2Score};
    }

    /// 🔥 STOP OLD TURN TICK SOUND
    stopTickingSound();

    await roomRef.update({
      "board": newBoard,
      "currentTurn": result["winner"] == "" ? nextTurn : "",
      "winner": result["winner"],
      "winningLine": result["line"], // 🔥 important
      "lastMove": index,

      /// 🔥 GLOBAL MATCH START
      "matchStarted": true,

      /// 🔥 ADD THIS
      "timerStart": ServerValue.timestamp,
      "turnDuration": 30,

      // if (hasFirstMove) ...{
      //   "timerStart": ServerValue.timestamp,
      //   "turnDuration": 30,
      // },

      if (scoreUpdate != null) ...scoreUpdate,
    });
  }

  Future loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      soundOn = prefs.getBool("sound_on") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
    });
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

  Future<void> playLoseSound() async {
    if (!soundOn) return;

    await drawPlayer.stop();
    await drawPlayer.play(AssetSource("audio/lose.mp3"));
  }

  Future<void> playVibration(int duration) async {
    if (!vibrationOn) return;

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration);
    }
  }


  ///old
  // void listenToGame() async {
  //   String winner = "";
  //   final prefs = await SharedPreferences.getInstance();
  //   String userId = prefs.getString("nickname") ?? "";
  //
  //   roomRef.onValue.listen((event) {
  //     // ১. রুম ডিলিট হলে (Normal বা Zombie)
  //     if (!event.snapshot.exists) {
  //       isRoomActive = false;
  //       heartbeatTimer?.cancel();
  //
  //       // 💥 THE FIX: নতুন কোনো ডায়ালগের দরকার নেই, তোমার পুরোনো opponentExitDialogShown ফ্লাগ ব্যবহার করছি
  //       if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
  //         opponentExitDialogShown = true; // লক করে দিলাম, ডায়ালগ একবারই আসবে
  //
  //         // যদি অন্য কোনো ডিসকানেক্ট ডায়ালগ খোলা থাকে, সেটা বন্ধ করো
  //         if (isDisconnectDialogOpen && disconnectDialogCtx != null) {
  //           //Navigator.pop(disconnectDialogCtx!);
  //           if (disconnectDialogCtx != null &&
  //               Navigator.of(
  //                 disconnectDialogCtx!,
  //                 rootNavigator: true,
  //               ).canPop()) {
  //
  //             Navigator.of(
  //               disconnectDialogCtx!,
  //               rootNavigator: true,
  //             ).pop();
  //           }
  //           isDisconnectDialogOpen = false;
  //         }
  //         if (isDialogOpen && internetDialogCtx != null) {
  //           //Navigator.pop(internetDialogCtx!);
  //           if (internetDialogCtx != null &&
  //               Navigator.of(
  //                 internetDialogCtx!,
  //                 rootNavigator: true,
  //               ).canPop()) {
  //
  //             Navigator.of(
  //               internetDialogCtx!,
  //               rootNavigator: true,
  //             ).pop();
  //           }
  //           isDialogOpen = false;
  //         }
  //
  //         // 💥 তোমার আগের "Opponent Left" ডায়ালগটাই কল করে দিলাম
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           if (mounted) showOpponentExitDialog();
  //         });
  //       }
  //       return;
  //     }
  //
  //     final data = Map<String, dynamic>.from(event.snapshot.value as Map);
  //
  //     bool firebaseTimeUp = data["timeUp"] ?? false;
  //
  //
  //
  //     ///new
  //     if (data["timerStart"] != null) {
  //
  //       int newStart = data["timerStart"];
  //
  //       turnDuration = data["turnDuration"] ?? 30;
  //
  //       /// 🔥 ALWAYS UPDATE ON REPLAY
  //       if (serverStartTime != newStart || timerController.value >= 1.0) {
  //
  //         serverStartTime = newStart;
  //
  //         lastAlertSecond = -1;
  //
  //         syncTimer();
  //       }
  //     }
  //
  //     // ২. 💥 THE ZOMBIE KILLER: ফায়ারবেস যদি জমানো ডেটা দিয়ে ভুল করে রুম বানায়!
  //     if (data["board"] == null || data["players"] == null) {
  //       roomRef.remove(); // জম্বি রুমটাকে সাথে সাথে আবার ডিলিট করে দাও!
  //       isRoomActive = false;
  //       heartbeatTimer?.cancel();
  //
  //       // 💥 THE FIX: অটো-ব্যাক না করে ডায়ালগ দেখাও
  //       if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
  //         opponentExitDialogShown = true;
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           if (mounted) showOpponentExitDialog();
  //         });
  //       }
  //
  //       return;
  //     }
  //
  //     setState(() {
  //       isTimeUp = firebaseTimeUp;
  //       winner = data["winner"] ?? "";
  //       boardSize = data["boardSize"] ?? 3;
  //       board = List<String>.from(data["board"]);
  //
  //       List<String> newBoard = List<String>.from(data["board"]);
  //
  //       // 🔥 FIRST LOAD → SKIP SOUND
  //       if (previousBoard.isEmpty) {
  //         previousBoard = List.from(newBoard);
  //       } else {
  //         for (int i = 0; i < newBoard.length; i++) {
  //           if (previousBoard[i] != newBoard[i]) {
  //             if (newBoard[i] == "X") {
  //               playXSound();
  //               playVibration(120);
  //             } else if (newBoard[i] == "O") {
  //               playOSound();
  //               playVibration(120);
  //             }
  //
  //             break;
  //           }
  //         }
  //
  //         previousBoard = List.from(newBoard);
  //       }
  //
  //       currentTurn = data["currentTurn"] ?? "";
  //
  //       final playersData = data["players"];
  //       // 🔥 SAFE PARSING: Prevent crash if a player node is removed during disconnect
  //       final p1 = playersData != null ? playersData["player1"] : null;
  //       final p2 = playersData != null ? playersData["player2"] : null;
  //
  //       myId = userId;
  //
  //       if (p1 != null && p1["uid"] == userId) {
  //         mySymbol = p1["symbol"] ?? "";
  //         opponentId = p2?["uid"] ?? "Waiting...";
  //         player1Symbol = p1["symbol"] ?? "";
  //         player2Symbol = p2?["symbol"] ?? "";
  //       } else if (p2 != null && p2["uid"] == userId) {
  //         mySymbol = p2["symbol"] ?? "";
  //         opponentId = p1?["uid"] ?? "Waiting...";
  //         player1Symbol = p1?["symbol"] ?? "";
  //         player2Symbol = p2["symbol"] ?? "";
  //       }
  //
  //
  //       if (!disconnectSetupDone && mySymbol.isNotEmpty) {
  //         disconnectSetupDone = true;
  //         setupPresence(); // 🔥 নতুন ফাংশন কল করা হলো
  //         registerPresence();
  //       }
  //
  //       List<int>? newLine = data["winningLine"] != null
  //           ? List<int>.from(data["winningLine"])
  //           : null;
  //
  //       if (newLine != null && newLine.isNotEmpty) {
  //         // 🔥 only trigger if new line आया hai
  //         if (winningLine == null) {
  //           winningLine = newLine;
  //
  //           lineController.reset();
  //           lineController.forward();
  //         }
  //       } else {
  //         winningLine = null;
  //       }
  //
  //       lastMove = data["lastMove"] ?? -1;
  //
  //       String firebaseWinner = data["winner"] ?? "";
  //
  //       gameOver = firebaseWinner.isNotEmpty;
  //
  //       if (firebaseWinner.isNotEmpty && !hasShownResult) {
  //         hasShownResult = true; // 🔥 only once
  //
  //         if (firebaseWinner == "draw") {
  //           gameMessage = " DRAW ";
  //           playDrawSound();
  //         } else if (firebaseWinner == mySymbol) {
  //           gameMessage = " YOU WIN ";
  //           confettiController.play(); // 🎉 only once
  //           playWinSound();
  //         } else {
  //           gameMessage = " YOU LOSE ";
  //           playLoseSound();
  //         }
  //       } else if (firebaseWinner.isEmpty) {
  //
  //         /// 🔥 NEW GAME RESET (CRITICAL FIX)
  //         hasShownResult = false;
  //         gameMessage = "";
  //         isTimeUp = false;   // 🔥 ADD THIS
  //         gameOver = false;   // 🔥 ADD THIS
  //       }
  //     });
  //
  //     final rematch = data["rematch"];
  //
  //     if (rematch != null) {
  //       String requestedBy = rematch["requestedBy"] ?? "";
  //       String status = rematch["status"] ?? "";
  //
  //       // 🔥 requester side
  //       if (requestedBy == myId) {
  //         if (status == "accepted") {
  //           closeDialogSafe(); // ✅ FIX
  //
  //           if (!isRestarting) {
  //             isRestarting = true;
  //
  //             /// 🔥 ADD THIS PART (CRITICAL)
  //             timerController.stop();
  //             timerController.reset();
  //             clockSoundPlayer.stop();
  //             lastAlertSecond = -1;
  //
  //
  //             WidgetsBinding.instance.addPostFrameCallback((_) {
  //               restartGame();
  //             });
  //           }
  //         }
  //
  //         if (status == "rejected") {
  //           closeDialogSafe();
  //
  //           // 🔥 CHECK if opponent actually left
  //           final exitStatus = data["exitStatus"];
  //
  //           bool p1Exit = exitStatus?["player1"] ?? false;
  //           bool p2Exit = exitStatus?["player2"] ?? false;
  //
  //           String myKey = mySymbol == player1Symbol ? "player1" : "player2";
  //
  //           bool opponentLeft =
  //               (myKey == "player1" && p2Exit) ||
  //               (myKey == "player2" && p1Exit);
  //
  //           // ✅ only show if NOT exit
  //           if (!opponentLeft) {
  //             showToast("Replay request rejected ❌");
  //             // showRejectedDialog(); ❌ optional remove (toast enough)
  //           }
  //         }
  //       }
  //
  //       final players = data["players"];
  //
  //       if (players == null || players.isEmpty) {
  //         roomRef.remove(); // 🔥 auto delete room
  //       }
  //
  //       // 🔥 cancel detect
  //       if (status == "" && requestedBy == "") {
  //         closeDialogSafe(); // ✅ FIX
  //       }
  //
  //       // 🔥 opponent side → show dialog
  //       if (status == "pending" &&
  //           requestedBy.isNotEmpty &&
  //           requestedBy != myId &&
  //           !dialogOpen) {
  //         dialogOpen = true;
  //
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           showRematchDialog();
  //         });
  //       }
  //
  //       // 🔥 opponent cancel detect
  //       if ((status == "" || status == "rejected") && dialogOpen) {
  //         closeDialogSafe(); // ✅ FIX
  //       }
  //     }
  //
  //     final score = data["score"];
  //
  //     if (score != null) {
  //       player1Score = score["player1"] ?? 0;
  //       player2Score = score["player2"] ?? 0;
  //     }
  //
  //     // 🔥 Heartbeat Signal logic inside listenToGame
  //     // 🔥 Listen to pings
  //     final pings = data["pings"];
  //     if (pings != null && opponentId != "Waiting...") {
  //       String oppKey = mySymbol == player1Symbol ? "player2" : "player1";
  //       int oppPing = pings[oppKey] ?? -1;
  //
  //       // 🔥 Naya ping aane par time reset karo
  //       if (oppPing != -1 && oppPing != lastOpponentPingValue) {
  //         lastOpponentPingValue = oppPing;
  //         lastPingReceivedLocalTime =
  //             DateTime.now().millisecondsSinceEpoch; // Local Time Reset
  //
  //         // Reconnect hone par dialog hata do
  //         if (isDisconnectDialogOpen) {
  //           isDisconnectDialogOpen = false;
  //           if (disconnectDialogCtx != null && mounted) {
  //             //Navigator.pop(disconnectDialogCtx!);
  //             if (disconnectDialogCtx != null &&
  //                 Navigator.of(
  //                   disconnectDialogCtx!,
  //                   rootNavigator: true,
  //                 ).canPop()) {
  //
  //               Navigator.of(
  //                 disconnectDialogCtx!,
  //                 rootNavigator: true,
  //               ).pop();
  //             }
  //             disconnectDialogCtx = null;
  //             showToast("Opponent reconnected! 🎮");
  //           }
  //         }
  //       }
  //     }
  //
  //
  //
  //     final exitStatus = data["exitStatus"];
  //
  //     if (exitStatus != null) {
  //       String p1Status = exitStatus["player1"]?.toString() ?? "online";
  //       String p2Status = exitStatus["player2"]?.toString() ?? "online";
  //
  //       String myKey = mySymbol == player1Symbol ? "player1" : "player2";
  //       String opponentStatus = myKey == "player1" ? p2Status : p1Status;
  //
  //       // 🔴 Sirf tab jab Opponent khud "Exit" daba kar jaye
  //       if (opponentStatus == "exited" && !opponentExitDialogShown) {
  //         opponentExitDialogShown = true;
  //
  //         if (isDisconnectDialogOpen &&
  //             disconnectDialogCtx != null &&
  //             mounted) {
  //           isDisconnectDialogOpen = false;
  //           //Navigator.pop(disconnectDialogCtx!);
  //           if (disconnectDialogCtx != null &&
  //               Navigator.of(
  //                 disconnectDialogCtx!,
  //                 rootNavigator: true,
  //               ).canPop()) {
  //
  //             Navigator.of(
  //               disconnectDialogCtx!,
  //               rootNavigator: true,
  //             ).pop();
  //           }
  //           disconnectDialogCtx = null;
  //         }
  //
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           if (mounted) showOpponentExitDialog();
  //         });
  //       }
  //     }
  //   });
  // }

  Future<void> listenToGame() async {
    final prefs = await SharedPreferences.getInstance();

    String userId = prefs.getString("nickname") ?? "";

    roomRef.onValue.listen((event) {
      /// 🔥 ROOM DELETED
      if (handleRoomDeleted(event)) {
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      /// 🔥 TIMER
      handleTimerSync(data);

      /// 🔥 ZOMBIE ROOM
      if (handleZombieRoom(data)) {
        return;
      }

      /// 🔥 MAIN GAME UI
      updateGameState(data, userId);

      /// 🔥 REMATCH
      handleRematch(data);

      /// 🔥 SCORE
      updateScore(data);

      /// 🔥 HEARTBEAT
      handleHeartbeat(data);

      /// 🔥 EXIT STATUS
      handleExitStatus(data);
    });
  }

  bool handleRoomDeleted(DatabaseEvent event) {
    if (event.snapshot.exists) {
      return false;
    }

    isRoomActive = false;

    heartbeatTimer?.cancel();

    if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
      opponentExitDialogShown = true;

      /// 🔥 CLOSE DISCONNECT DIALOG
      if (isDisconnectDialogOpen && disconnectDialogCtx != null) {
        if (Navigator.of(disconnectDialogCtx!, rootNavigator: true).canPop()) {
          Navigator.of(disconnectDialogCtx!, rootNavigator: true).pop();
        }

        isDisconnectDialogOpen = false;
      }

      /// 🔥 CLOSE INTERNET DIALOG
      if (isDialogOpen && internetDialogCtx != null) {
        if (Navigator.of(internetDialogCtx!, rootNavigator: true).canPop()) {
          Navigator.of(internetDialogCtx!, rootNavigator: true).pop();
        }

        isDialogOpen = false;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          stopTickingSound();
          showOpponentExitDialog();
        }
      });
    }

    return true;
  }

  void handleTimerSync(Map<String, dynamic> data) {

    bool matchStarted =
        data["matchStarted"] ?? false;

    if (!matchStarted) {

      timerController.stop();

      timerController.reset();

      serverStartTime = 0;

      return;
    }

    if (data["timerStart"] != null) {
      int newStart = data["timerStart"];

      turnDuration = data["turnDuration"] ?? 30;

      if (serverStartTime != newStart || timerController.value >= 1.0) {
        serverStartTime = newStart;

        lastAlertSecond = -1;

        syncTimer();
      }
    }
  }

  bool handleZombieRoom(Map<String, dynamic> data) {
    if (data["board"] != null && data["players"] != null) {
      return false;
    }

    roomRef.remove();

    isRoomActive = false;

    heartbeatTimer?.cancel();

    if (mounted && !isGamePageClosed && !opponentExitDialogShown) {
      opponentExitDialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showOpponentExitDialog();
        }
      });
    }

    return true;
  }

  void updateGameState(Map<String, dynamic> data, String userId) {
    setState(() {
      updateBoardData(data);

      updateBoardSound(data);

      updatePlayerData(data, userId);

      updateWinningLine(data);

      updateWinnerState(data);
    });
  }

  ///old updateBoardData
  // void updateBoardData(
  //     Map<String, dynamic> data,
  //     ) {
  //
  //   isTimeUp = data["timeUp"] ?? false;
  //
  //   boardSize = data["boardSize"] ?? 3;
  //
  //   board = List<String>.from(
  //     data["board"],
  //   );
  //
  //   currentTurn =
  //       data["currentTurn"] ?? "";
  //
  //   lastMove =
  //       data["lastMove"] ?? -1;
  // }

  ///new updateBoardData
  void updateBoardData(Map<String, dynamic> data) {
    isTimeUp = data["timeUp"] ?? false;

    boardSize = data["boardSize"] ?? 3;

    board = List<String>.from(data["board"]);

    /// 🔥 SAVE OLD TURN
    String oldTurn = currentTurn;

    currentTurn = data["currentTurn"] ?? "";

    /// 🔥 TURN CHANGED
    if (oldTurn != currentTurn) {
      stopTickingSound();
    }

    lastMove = data["lastMove"] ?? -1;
  }

  void updateBoardSound(Map<String, dynamic> data) {
    List<String> newBoard = List<String>.from(data["board"]);

    if (previousBoard.isEmpty) {
      previousBoard = List.from(newBoard);

      return;
    }

    for (int i = 0; i < newBoard.length; i++) {
      if (previousBoard[i] != newBoard[i]) {
        if (newBoard[i] == "X") {
          playXSound();

          //playVibration(120);
          if (vibrationOn) {HapticFeedback.lightImpact();}
        } else if (newBoard[i] == "O") {
          playOSound();

          //playVibration(120);
          if (vibrationOn) {HapticFeedback.lightImpact();}
        }

        break;
      }
    }

    previousBoard = List.from(newBoard);
  }

  void updatePlayerData(Map<String, dynamic> data, String userId) {
    final playersData = data["players"];

    final p1 = playersData != null ? playersData["player1"] : null;

    final p2 = playersData != null ? playersData["player2"] : null;

    myId = userId;

    if (p1 != null && p1["uid"] == userId) {
      mySymbol = p1["symbol"] ?? "";

      opponentId = p2?["uid"] ?? "Waiting...";

      player1Symbol = p1["symbol"] ?? "";

      player2Symbol = p2?["symbol"] ?? "";
    } else if (p2 != null && p2["uid"] == userId) {
      mySymbol = p2["symbol"] ?? "";

      opponentId = p1?["uid"] ?? "Waiting...";

      player1Symbol = p1?["symbol"] ?? "";

      player2Symbol = p2["symbol"] ?? "";
    }

    if (!disconnectSetupDone && mySymbol.isNotEmpty) {
      disconnectSetupDone = true;

      setupPresence();

      registerPresence();
    }
  }

  void updateWinningLine(Map<String, dynamic> data) {
    List<int>? newLine = data["winningLine"] != null
        ? List<int>.from(data["winningLine"])
        : null;

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

  void updateWinnerState(Map<String, dynamic> data) {
    String firebaseWinner = data["winner"] ?? "";

    gameOver = firebaseWinner.isNotEmpty;

    if (firebaseWinner.isNotEmpty && !hasShownResult) {
      stopTickingSound();

      hasShownResult = true;

      if (firebaseWinner == "draw") {
        gameMessage = " DRAW ";
        playDrawSound();
        if (vibrationOn) {
          //HapticFeedback.mediumImpact();
          playVibration(120);
        }

      } else if (firebaseWinner == mySymbol) {
        gameMessage = " YOU WIN ";
        confettiController.play();
        playWinSound();
        if (vibrationOn) {
          playVibration(120);
          //HapticFeedback.vibrate();
          }

      } else {
        gameMessage = " YOU LOSE ";
        playLoseSound();
        if (vibrationOn) {
          //HapticFeedback.vibrate();
          playVibration(120);
        }
      }
    } else if (firebaseWinner.isEmpty) {
      hasShownResult = false;

      gameMessage = "";

      isTimeUp = false;

      gameOver = false;
    }
  }

  /// old REMATCH
  // void handleRematch(
  //     Map<String, dynamic> data,
  //     ) {
  //
  //   final rematch = data["rematch"];
  //
  //   if (rematch == null) return;
  //
  //   String requestedBy =
  //       rematch["requestedBy"] ?? "";
  //
  //   String status =
  //       rematch["status"] ?? "";
  //
  //   /// 🔥 REQUESTER SIDE
  //   if (requestedBy == myId) {
  //
  //     /// ✅ ACCEPTED
  //     if (status == "accepted") {
  //
  //       closeDialogSafe();
  //
  //       if (!isRestarting) {
  //
  //         isRestarting = true;
  //
  //         /// 🔥 RESET TIMER
  //         timerController.stop();
  //
  //         timerController.reset();
  //
  //         clockSoundPlayer.stop();
  //
  //         lastAlertSecond = -1;
  //
  //         WidgetsBinding.instance
  //             .addPostFrameCallback((_) {
  //
  //           restartGame();
  //         });
  //       }
  //     }
  //
  //     /// ❌ REJECTED
  //     if (status == "rejected") {
  //
  //       closeDialogSafe();
  //
  //       /// 🔥 CHECK EXIT STATUS
  //       final exitStatus =
  //       data["exitStatus"];
  //
  //       bool p1Exit =
  //           exitStatus?["player1"] ?? false;
  //
  //       bool p2Exit =
  //           exitStatus?["player2"] ?? false;
  //
  //       String myKey =
  //       mySymbol == player1Symbol
  //           ? "player1"
  //           : "player2";
  //
  //       bool opponentLeft =
  //
  //           (myKey == "player1" &&
  //               p2Exit) ||
  //
  //               (myKey == "player2" &&
  //                   p1Exit);
  //
  //       /// 🔥 SHOW ONLY IF NOT EXITED
  //       if (!opponentLeft) {
  //
  //         showToast(
  //           "Replay request rejected ❌",
  //         );
  //       }
  //
  //     }
  //   }
  //
  //   /// 🔥 AUTO DELETE ROOM
  //   final players = data["players"];
  //
  //   if (players == null ||
  //       players.isEmpty) {
  //
  //     roomRef.remove();
  //   }
  //
  //   /// 🔥 CANCEL DETECT
  //   if (status == "" &&
  //       requestedBy == "") {
  //
  //     closeDialogSafe();
  //   }
  //
  //   /// 🔥 OPPONENT SIDE
  //   if (status == "pending" &&
  //       requestedBy.isNotEmpty &&
  //       requestedBy != myId &&
  //       !dialogOpen) {
  //
  //     dialogOpen = true;
  //
  //     WidgetsBinding.instance
  //         .addPostFrameCallback((_) {
  //
  //       showRematchDialog();
  //     });
  //   }
  //
  //   /// 🔥 OPPONENT CANCEL DETECT
  //   if ((status == "" ||
  //       status == "rejected") &&
  //       dialogOpen) {
  //
  //     closeDialogSafe();
  //   }
  // }

  ///new handleRematch
  void handleRematch(Map<String, dynamic> data) {
    final rematch = data["rematch"];

    if (rematch == null) return;

    String requestedBy = rematch["requestedBy"] ?? "";

    String status = rematch["status"] ?? "";

    String cancelledBy = rematch["cancelledBy"] ?? "";

    /// 🔥 UNIQUE ACTION KEY
    String actionKey = "$status-$requestedBy-$cancelledBy";

    /// ✅ ACCEPTED
    if (requestedBy == myId && status == "accepted") {
      closeDialogSafe();

      lastRematchAction = "";

      if (!isRestarting) {
        isRestarting = true;

        timerController.stop();

        timerController.reset();

        stopTickingSound();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          restartGame();
        });
      }
    }

    /// ❌ REJECTED
    if (status == "rejected") {
      closeDialogSafe();
      stopTickingSound();

      /// 🔥 PREVENT MULTIPLE TOAST
      if (lastRematchAction != actionKey) {
        lastRematchAction = actionKey;

        /// 🔥 SENDER SIDE
        if (cancelledBy != myId) {
          if (vibrationOn) {HapticFeedback.mediumImpact();}
          //showToast("Opponent rejected ❌");
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

    /// ❌ CANCELLED
    if (status == "" && requestedBy == "" && cancelledBy.isNotEmpty) {
      closeDialogSafe();
      stopTickingSound();

      /// 🔥 PREVENT MULTIPLE TOAST
      if (lastRematchAction != actionKey) {
        lastRematchAction = actionKey;

        /// 🔥 OPPONENT SIDE
        if (cancelledBy != myId) {
          if (vibrationOn) {HapticFeedback.mediumImpact();}
          //showToast("Opponent cancelled ❌");
          CustomToast.show(
            context: context,
            message: "Opponent cancelled!",
            isDark: isDark,
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
          );
        }
      }

      /// 🔥 CLEANUP
      roomRef.child("rematch/cancelledBy").remove();
    }

    /// 🔥 RESET ACTION
    if (status == "" && requestedBy == "" && cancelledBy == "") {
      lastRematchAction = "";
    }

    /// 🔥 AUTO DELETE ROOM
    final players = data["players"];

    if (players == null || players.isEmpty) {
      roomRef.remove();
    }

    /// 🔥 OPPONENT SIDE
    if (status == "pending" &&
        requestedBy.isNotEmpty &&
        requestedBy != myId &&
        !dialogOpen) {
      dialogOpen = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showRematchDialog();
        if (vibrationOn) {HapticFeedback.mediumImpact();}
      });
    }

    /// 🔥 CLOSE DIALOG
    if ((status == "" || status == "rejected") && dialogOpen) {
      closeDialogSafe();
    }
  }

  /// 🔥 SCORE
  void updateScore(Map<String, dynamic> data) {
    final score = data["score"];

    if (score == null) return;

    player1Score = score["player1"] ?? 0;

    player2Score = score["player2"] ?? 0;
  }

  /// 🔥 HEARTBEAT
  void handleHeartbeat(Map<String, dynamic> data) {
    final pings = data["pings"];

    if (pings == null || opponentId == "Waiting...") {
      return;
    }

    String oppKey = mySymbol == player1Symbol ? "player2" : "player1";

    int oppPing = pings[oppKey] ?? -1;

    /// 🔥 NEW PING
    if (oppPing != -1 && oppPing != lastOpponentPingValue) {
      lastOpponentPingValue = oppPing;

      lastPingReceivedLocalTime = DateTime.now().millisecondsSinceEpoch;

      /// 🔥 RECONNECTED
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

          //showToast("Opponent reconnected!");
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

  /// 🔥 EXIT STATUS
  void handleExitStatus(Map<String, dynamic> data) {
    final exitStatus = data["exitStatus"];

    if (exitStatus == null) return;

    String p1Status = exitStatus["player1"]?.toString() ?? "online";

    String p2Status = exitStatus["player2"]?.toString() ?? "online";

    String myKey = mySymbol == player1Symbol ? "player1" : "player2";

    String opponentStatus = myKey == "player1" ? p2Status : p1Status;

    /// 🔥 OPPONENT EXITED
    if (opponentStatus == "exited" && !opponentExitDialogShown) {
      opponentExitDialogShown = true;

      /// 🔥 CLOSE DISCONNECT DIALOG
      if (isDisconnectDialogOpen && disconnectDialogCtx != null && mounted) {
        isDisconnectDialogOpen = false;

        if (Navigator.of(disconnectDialogCtx!, rootNavigator: true).canPop()) {
          Navigator.of(disconnectDialogCtx!, rootNavigator: true).pop();
        }

        disconnectDialogCtx = null;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          /// 🔥 CLOSE OLD EXIT DIALOG
          if (isExitDialogOpen) {
            final navigator = Navigator.of(context, rootNavigator: true);

            if (navigator.canPop()) {
              navigator.pop();
            }

            isExitDialogOpen = false;
          }

          stopTickingSound();

          if (vibrationOn) {HapticFeedback.mediumImpact();}
          showOpponentExitDialog();
        }
      });
    }
  }


  ///old syncTimer
  // void syncTimer() {
  //
  //
  //   if (gameOver) {
  //     timerController.stop();
  //     return;
  //   }
  //
  //   if (serverStartTime == 0 || turnDuration <= 0) return;
  //
  //   int now = DateTime.now().millisecondsSinceEpoch;
  //
  //   double elapsedMs = (now - serverStartTime).toDouble();
  //   double durationMs = turnDuration * 1000;
  //
  //   double progress = (elapsedMs / durationMs).clamp(0.0, 1.0);
  //
  //   /// 🔥 ONLY SET VALUE FIRST TIME OR BIG DIFF
  //   if ((timerController.value - progress).abs() > 0.05) {
  //     timerController.value = progress;
  //   }
  //
  //   /// 🔥 CONTINUE ONLY IF NOT RUNNING
  //   if (!timerController.isAnimating && progress < 1.0) {
  //     timerController.animateTo(
  //       1.0,
  //       duration: Duration(milliseconds: ((1 - progress) * durationMs).toInt()),
  //       curve: Curves.linear,
  //     );
  //   }
  //
  //   /// 🔥 TIME UP CHECK (SAFE)
  //   if (progress >= 1.0 && !gameOver && !isTimeUp) {
  //     print("⏰ TIME UP SYNC TRIGGER");
  //
  //     isTimeUp = true;
  //     gameOver = true;
  //
  //     stopTickingSound();
  //     timerController.stop();
  //
  //     onTimeUpOnline();
  //   }
  // }

  ///new syncTimer
  void syncTimer() {

    if (gameOver) {

      timerController.stop();

      return;
    }

    /// 🔥 WAIT FOR FIRST MOVE
    if (serverStartTime == 0) {

      timerController.stop();

      timerController.reset();

      return;
    }

    int now =
        DateTime.now()
            .millisecondsSinceEpoch;

    double elapsedMs =
    (now - serverStartTime)
        .toDouble();

    double durationMs =
        turnDuration * 1000;

    double progress =
    (elapsedMs / durationMs)
        .clamp(0.0, 1.0);

    timerController.value = progress;

    if (!timerController.isAnimating &&
        progress < 1.0) {

      timerController.animateTo(
        1.0,

        duration: Duration(
          milliseconds:
          ((1 - progress) * durationMs)
              .toInt(),
        ),

        curve: Curves.linear,
      );
    }

    /// 🔥 TIME UP
    if (progress >= 1.0 &&
        !gameOver &&
        !isTimeUp) {

      isTimeUp = true;

      gameOver = true;

      stopTickingSound();

      timerController.stop();

      onTimeUpOnline();
    }
  }

  Future<void> onTimeUpOnline() async {
    if (!isTimeUp || gameOver == false) return;

    String winner = currentTurn == "X" ? "O" : "X";

    final snapshot = await roomRef.child("score").get();

    int p1Score = snapshot.child("player1").value as int? ?? 0;
    int p2Score = snapshot.child("player2").value as int? ?? 0;

    if (winner == player1Symbol) {
      p1Score++;
    } else {
      p2Score++;
    }

    stopTickingSound();

    await roomRef.update({
      "winner": winner,
      "currentTurn": "",
      "score/player1": p1Score,
      "score/player2": p2Score,

      /// 🔥 ADD THIS
      "timeUp": true,
    });
  }

  int getTimeLeft() {
    return (turnDuration * (1 - timerController.value))
        .clamp(0, turnDuration)
        .toInt();
  }

  // void showToast(String msg) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
  //   );
  // }

  // void showToast(
  //
  //     String msg, {
  //
  //       IconData? icon,
  //
  //       Color? color,
  //
  //       Duration duration =
  //       const Duration(
  //         seconds: 2,
  //       ),
  //     }) {
  //
  //   final isDarkTheme = isDark;
  //
  //   ScaffoldMessenger.of(context)
  //       .hideCurrentSnackBar();
  //
  //   ScaffoldMessenger.of(context)
  //       .showSnackBar(
  //
  //     SnackBar(
  //
  //       duration: duration,
  //
  //       behavior:
  //       SnackBarBehavior.floating,
  //
  //       backgroundColor:
  //       Colors.transparent,
  //
  //       elevation: 0,
  //
  //       margin:
  //       const EdgeInsets.symmetric(
  //
  //         horizontal: 20,
  //
  //         vertical: 14,
  //       ),
  //
  //       content: Container(
  //
  //         padding:
  //         const EdgeInsets.symmetric(
  //
  //           horizontal: 16,
  //
  //           vertical: 14,
  //         ),
  //
  //         decoration: BoxDecoration(
  //
  //           borderRadius:
  //           BorderRadius.circular(18),
  //
  //           gradient: LinearGradient(
  //
  //             colors: isDarkTheme
  //
  //                 ? [
  //
  //               const Color(
  //                 0xFF1E293B,
  //               ),
  //
  //               const Color(
  //                 0xFF334155,
  //               ),
  //             ]
  //
  //                 : [
  //
  //               Colors.white,
  //
  //               const Color(
  //                 0xFFF3F6FB,
  //               ),
  //             ],
  //           ),
  //
  //           border: Border.all(
  //
  //             color: isDarkTheme
  //
  //                 ? Colors.cyanAccent
  //                 .withValues(
  //               alpha: 0.25,
  //             )
  //
  //                 : Colors.blueAccent
  //                 .withValues(
  //               alpha: 0.25,
  //             ),
  //           ),
  //
  //           boxShadow: [
  //
  //             BoxShadow(
  //
  //               color:
  //               (color ??
  //                   Colors
  //                       .blueAccent)
  //                   .withValues(
  //                 alpha: 0.25,
  //               ),
  //
  //               blurRadius: 14,
  //
  //               spreadRadius: 1,
  //
  //               offset:
  //               const Offset(0, 4),
  //             ),
  //           ],
  //         ),
  //
  //         child: Row(
  //
  //           children: [
  //
  //             Container(
  //
  //               width: 34,
  //               height: 34,
  //
  //               decoration: BoxDecoration(
  //
  //                 shape:
  //                 BoxShape.circle,
  //
  //                 gradient:
  //                 LinearGradient(
  //
  //                   colors: [
  //
  //                     (color ??
  //                         Colors
  //                             .blueAccent),
  //
  //                     (color ??
  //                         Colors
  //                             .cyanAccent),
  //                   ],
  //                 ),
  //               ),
  //
  //               child: Icon(
  //
  //                 icon ??
  //                     Icons.info_rounded,
  //
  //                 color: Colors.white,
  //
  //                 size: 18,
  //               ),
  //             ),
  //
  //             const SizedBox(width: 12),
  //
  //             Expanded(
  //
  //               child: Text(
  //
  //                 msg,
  //
  //                 style: TextStyle(
  //
  //                   color: isDarkTheme
  //
  //                       ? Colors.white
  //
  //                       : Colors.black87,
  //
  //                   fontSize: 14,
  //
  //                   fontWeight:
  //                   FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    int myScore = 0;
    int opponentScore = 0;

    if (mySymbol == player1Symbol) {
      myScore = player1Score;
      opponentScore = player2Score;
    } else {
      myScore = player2Score;
      opponentScore = player1Score;
    }

    Color boardColor = isDark ? const Color(0xFF2B3A5A) : Colors.white;
    Color cellColor = isDark
        ? const Color(0xFF1F2A44)
        : const Color(0xFFF0F0F0);
    Color textColor = isDark ? Colors.white : Colors.black;

    return PopScope(
      canPop: false, // ❌ direct back block
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        showExitDialog(); // 🔥 dialog show
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          backgroundColor: isDark ? Color(0xFF2B3A5A) : Color(0xFFF5F5F0),
          elevation: 0,

          // leading: IconButton(
          //   icon: Icon(Icons.arrow_back, color: textColor),
          //   onPressed: () {
          //     playVibration(120);
          //     showExitDialog(); // 🔥
          //   },
          // ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Tooltip(
              message: "Back",
              child: GestureDetector(
                onTap: () async {
                  //await handleBackPress();
                  //playVibration(120);
                  if (vibrationOn) {HapticFeedback.lightImpact();}
                  showExitDialog();
                },
                child: build3DIconButton(
                  icon: Icons.arrow_back,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          title: GestureDetector(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Text(
                  "Online Match",

                  style: TextStyle(
                    color: isDark ? Colors.cyanAccent : Colors.blue,

                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

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

          // actions: [
          //   // 👇 Gesture icon clickable
          //   const SizedBox(width: 0),
          //   IconButton(
          //     icon: Icon(Icons.settings, color: textColor),
          //     onPressed: () {
          //       showSettingsMenu(); // ✅ new toggle menu
          //     },
          //   ),
          // ],
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: "Settings",
                child: GestureDetector(
                  onTap: () {
                    if (vibrationOn) {HapticFeedback.lightImpact();}
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
            // 🔥 Background Gradient (same as offline)
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
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center, // 🔥 CENTER
                  children: [
                    const SizedBox(height: 20),

                    // Row(
                    //   children: [
                    //
                    //     /// 👈 LEFT (YOU)
                    //     Expanded(
                    //       child: Align(
                    //         alignment: Alignment.centerLeft,
                    //         child: scoreBox(
                    //           "You",
                    //           mySymbol,
                    //           boardColor,
                    //           textColor,
                    //         ),
                    //       ),
                    //     ),
                    //
                    //     const SizedBox(width: 10),
                    //
                    //     /// 🎯 CENTER SCORE (ALWAYS CENTER)
                    //     Container(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 20,
                    //         vertical: 8,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: boardColor,
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       child: Text(
                    //         "$myScore - $opponentScore",
                    //         style: TextStyle(
                    //           color: textColor,
                    //           fontSize: 18,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //     ),
                    //
                    //     const SizedBox(width: 10),
                    //
                    //     /// 👉 RIGHT (OPPONENT)
                    //     Expanded(
                    //       child: Align(
                    //         alignment: Alignment.centerRight,
                    //         child: scoreBox(
                    //           opponentId,
                    //           mySymbol == "X" ? "O" : "X",
                    //           boardColor,
                    //           textColor,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Row(
                      children: [
                        /// 👈 LEFT
                        scoreBox("You", mySymbol, boardColor, textColor),

                        const SizedBox(width: 10),

                        /// 🎯 CENTER
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

                        /// 👉 RIGHT
                        scoreBox(
                          opponentId,
                          mySymbol == "X" ? "O" : "X",
                          boardColor,
                          textColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

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

                    // 🔥 Turn Text (dummy for now)
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
                            gradientColors = [Colors.redAccent, Colors.orange];
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

                    // 🔥 GAME BOARD (MAIN PART)
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 320,
                        height: 320,
                        padding: const EdgeInsets.all(1.5),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.blueAccent,
                              Colors.deepOrange,
                              Colors.blueAccent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
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

                          // 🔥 IMPORTANT: STACK ADD KIYA
                          child: Stack(
                            children: [
                              // 🔹 BOARD GRID
                              GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),

                                itemCount: boardSize * boardSize,

                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: boardSize,
                                    ),

                                itemBuilder: (context, index) {
                                  // double symbolSize = boardSize <= 3
                                  //     ? 40
                                  //     : boardSize <= 5
                                  //     ? 28
                                  //     : 20;

                                  double symbolSize = boardSize <= 3
                                      ? 40
                                      : boardSize <= 5
                                      ? 28
                                      : boardSize <= 7
                                      ? 18
                                      : 13;

                                  bool highlight = index == lastMove;
                                  bool win =
                                      winningLine != null &&
                                      winningLine!.contains(index);

                                  return GestureDetector(
                                    onTap: (gameOver || isTimeUp)
                                        ? null
                                        : () => handleTap(index),

                                    child: AnimatedScale(
                                      scale: pressedIndex == index ? 0.92 : 1,
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),

                                      child: Container(
                                        // margin: EdgeInsets.all(
                                        //   boardSize == 3 ? 6 : 3,
                                        // ),
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
                                          //borderRadius: BorderRadius.circular(12,),
                                          borderRadius: BorderRadius.circular(
                                            boardSize <= 5
                                                ? 12
                                                : boardSize <= 7
                                                ? 8
                                                : 5,
                                          ),
                                          // 🔥 border if filled
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
                                            // 🔥 LAST MOVE GLOW
                                            if (highlight)
                                              const BoxShadow(
                                                color: Colors.blueAccent,
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),

                                            // 🔥 WIN GLOW
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

                              // 🔥 WIN LINE (TOP LAYER)
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

                    // 🔥 GAME END BUTTONS
                    if (gameMessage != "")
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NeonGlowingButton(
                              text: "Exit",
                              icon: Icons.exit_to_app,
                              onTap: () {
                                //playVibration(120);
                                if (vibrationOn) {HapticFeedback.mediumImpact();}
                                showExitDialog();
                              },

                              isDark: isDark,

                              glowController: glowController,

                              glowAnimation: glowAnimation,
                            ),

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

  Future<void> handleReplayRequest() async {
    if (isSendingReplay) return;

    isSendingReplay = true;

    //playVibration(120);
    if (vibrationOn) {HapticFeedback.mediumImpact();}

    try {
      // 🔥 send request
      await roomRef.child("rematch").update({
        "requestedBy": myId,
        "status": "pending",
      });

      // 🔥 show waiting dialog
      showRematchWaitingDialog();

      // 🔥 START COOLDOWN
      //startResendCooldown();
    } catch (e) {
      print("Replay Error: $e");
      //showToast("Something went wrong ❌");
      if (vibrationOn) {HapticFeedback.mediumImpact();}
      CustomToast.show(
        context: context,
        message: "Something went wrong!",
        isDark: isDark,
        icon: Icons.error_outline_rounded,
        color: Colors.redAccent,
      );
    } finally {
      isSendingReplay = false;
    }
  }

  ///old
  // void showRematchWaitingDialog() {
  //   dialogOpen = true;
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text("Replay request send"),
  //
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: const [
  //             // 🔥 LOADING CIRCLE
  //             SizedBox(
  //               height: 40,
  //               width: 40,
  //               child: CircularProgressIndicator(
  //                 strokeWidth: 3,
  //                 color: Colors.blueAccent,
  //               ),
  //             ),
  //
  //             SizedBox(height: 16),
  //
  //             // 🔥 TEXT
  //             Text("Waiting for opponent response"),
  //           ],
  //         ),
  //
  //         actions: [
  //           // ❌ CANCEL BUTTON
  //           TextButton(
  //             onPressed: () async {
  //               if (mounted && Navigator.of(context).canPop()) {
  //                 // Navigator.of(context, rootNavigator: true).pop();
  //               }
  //
  //               // 🔥 cancel request in Firebase
  //               await roomRef.child("rematch").set({
  //                 "requestedBy": "",
  //                 "status": "",
  //               });
  //
  //               showToast("Request cancelled ❌");
  //             },
  //             child: const Text("Cancel"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  ///new
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

      onNegative: () async {
        dialogOpen = false;
        if (vibrationOn) {HapticFeedback.mediumImpact();}
        // /// 🔥 CANCEL REQUEST
        // await roomRef.child("rematch").set({
        //   "requestedBy": "",
        //   "status": "",
        // });

        LoadingDialog.show(context, message: "Cancelling Request...");

        try {
          /// 🔥 CANCEL REQUEST
          await roomRef.child("rematch").set({
            "requestedBy": "",

            "status": "",

            "cancelledBy": myId,
          });

          //showToast("Request cancelled ❌");
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

  // Future<void> showRematchWaitingDialog() async {
  //
  //   dialogOpen = true;
  //
  //   await showAppDialog(
  //     context: context,
  //
  //     title: "REMATCH",
  //
  //     message:
  //     "Waiting for opponent response...\nPlease stay connected.",
  //
  //     positiveText: "",
  //     negativeText: "CANCEL",
  //
  //     barrierDismissible: false,
  //
  //     showContentLoading: true,
  //
  //     onNegative: () async {
  //
  //       /// 🔥 CANCEL REQUEST
  //       await roomRef.child("rematch").set({
  //         "requestedBy": "",
  //         "status": "",
  //       });
  //
  //       dialogOpen = false;
  //
  //       showToast("Request cancelled ❌");
  //     },
  //   );
  // }

  ///old
  // void showRematchDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) {
  //       return AlertDialog(
  //         title: const Text("Replay Request"),
  //         content: const Text("Your opponent wants to play again"),
  //
  //         actions: [
  //           // ❌ DECLINE
  //           TextButton(
  //             onPressed: () async {
  //               Navigator.pop(dialogContext); // 🔥 ONLY dialog close
  //
  //               dialogOpen = false;
  //
  //               await roomRef.child("rematch").update({
  //                 //"requestedBy": myId,
  //                 "status": "rejected",
  //               });
  //             },
  //             child: const Text("Decline"),
  //           ),
  //
  //           // ✅ PLAY
  //           TextButton(
  //             onPressed: () async {
  //               Navigator.pop(dialogContext); // 🔥 ONLY dialog close
  //
  //               dialogOpen = false;
  //
  //               await roomRef.child("rematch").update({"status": "accepted"});
  //             },
  //             child: const Text("Play"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  ///new
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

      /// ❌ DECLINE
      onNegative: () async {
        dialogOpen = false;
        if (vibrationOn) {HapticFeedback.mediumImpact();}
        // await roomRef.child("rematch").update({
        //   "status": "rejected",
        // });

        LoadingDialog.show(context, message: "Declining Request...");

        try {
          await roomRef.child("rematch").update({
            "status": "rejected",
            "cancelledBy": myId,
          });

          /// 🔥 SELF TOAST
          //showToast("Replay rejected ❌");
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

      /// ✅ PLAY AGAIN
      onPositive: () async {
        dialogOpen = false;
        if (vibrationOn) {HapticFeedback.mediumImpact();}
        // await roomRef.child("rematch").update({
        //   "status": "accepted",
        // });
        LoadingDialog.show(context, message: "Starting Rematch...");

        try {
          await roomRef.child("rematch").update({"status": "accepted"});
        } catch (e) {
          print("Rematch accept error: $e");
        } finally {
          LoadingDialog.hide(context);
        }
      },
    );
  }

  // Future<void> showRematchDialog() async {
  //
  //   dialogOpen = true;
  //
  //   await showAppDialog(
  //     context: context,
  //
  //     title: "REMATCH REQUEST",
  //
  //     message:
  //     "Your opponent wants another battle.\nDo you want to play again?",
  //
  //     positiveText: "PLAY",
  //     negativeText: "DECLINE",
  //
  //     barrierDismissible: false,
  //
  //     onNegative: () async {
  //
  //       dialogOpen = false;
  //
  //       await roomRef.child("rematch").update({
  //         "status": "rejected",
  //       });
  //     },
  //
  //     onPositive: () async {
  //
  //       dialogOpen = false;
  //
  //       await roomRef.child("rematch").update({
  //         "status": "accepted",
  //       });
  //     },
  //   );
  // }

  // 🟠 শুধু ইন্টারনেট ডিসকানেক্ট হলে এই ডায়ালগ আসবে

  ///old
  // void showDisconnectDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) {
  //       disconnectDialogCtx = dialogContext;
  //       return AlertDialog(
  //         title: const Text("Opponent Disconnected"),
  //         content: const Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             CircularProgressIndicator(color: Colors.blueAccent),
  //             SizedBox(height: 20),
  //             Text("Waiting for opponent to reconnect..."),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () async {
  //               Navigator.pop(dialogContext);
  //               heartbeatTimer?.cancel();
  //
  //               // 💥 FIX: অপোনেন্ট আগে থেকেই গায়েব, তাই তুমি বের হলে পুরো রুম ডিলিট!
  //               await roomRef.remove();
  //
  //               closeGamePage(); // 💥 Safe Pop
  //             },
  //             child: const Text("Leave Game"),
  //           ),
  //         ],
  //       );
  //     },
  //   ).then((_) {
  //     disconnectDialogCtx = null;
  //     isDisconnectDialogOpen = false;
  //   });
  // }

  ///new
  Future<void> showOpponentDisconnectDialog() async {
    isDisconnectDialogOpen = true;

    await showAppDialog(
      context: context,

      /// 🔥 SAVE CONTEXT
      onDialogCreated: (dialogContext) {
        disconnectDialogCtx = dialogContext;
      },

      title: "CONNECTION LOST",

      message: "Opponent disconnected.\nWaiting for reconnection...",

      positiveText: "",
      negativeText: "LEAVE GAME",

      barrierDismissible: false,

      showContentLoading: true,

      onNegative: () async {
        isDisconnectDialogOpen = false;

        disconnectDialogCtx = null;
        if (vibrationOn) {HapticFeedback.mediumImpact();}
        /// 🔥 CLOSE DIALOG FIRST
        final navigator = Navigator.of(context, rootNavigator: true);

        if (navigator.canPop()) {
          navigator.pop();
        }

        /// 🔥 SMALL DELAY
        await Future.delayed(const Duration(milliseconds: 100));

        /// 🔥 SAFE EXIT
        await exitFromGame();
      },
    ).then((_) {
      disconnectDialogCtx = null;
      isDisconnectDialogOpen = false;
    });
  }

  ///old
  // void showExitDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) {
  //       return AlertDialog(
  //         title: const Text("Exit Room"),
  //         content: const Text("Are you sure you want to exit?"),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(dialogContext);
  //             },
  //             child: const Text("Cancel"),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //
  //               Navigator.pop(dialogContext);
  //
  //               await exitFromGame();
  //             },
  //             child: const Text("Exit"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  //new

  ///new
  Future<void> showExitDialog() async {
    isExitDialogOpen = true;
    await showAppDialog(
      context: context,

      title: "EXIT ROOM",

      message: "Exit and end the match?",

      positiveText: "EXIT",
      negativeText: "CANCEL",

      barrierDismissible: false,

      onNegative: () {
        if (vibrationOn) {HapticFeedback.lightImpact();}
        isExitDialogOpen = false;
        // 🔥 nothing needed
      },

      onPositive: () async {
        isExitDialogOpen = false;
        await exitFromGame();
        if (vibrationOn) {HapticFeedback.mediumImpact();}
      },
    );

    /// 🔥 SAFETY
    isExitDialogOpen = false;
  }

  Future<void> exitFromGame() async {
    stopTickingSound();
    heartbeatTimer?.cancel();

    String playerKey = mySymbol == player1Symbol ? "player1" : "player2";

    /// 🔥 MARK EXIT
    await roomRef.child("exitStatus/$playerKey").set("exited");

    /// 🔥 RESET REMATCH
    await roomRef.child("rematch").set({"requestedBy": "", "status": ""});

    /// 🔥 GET EXIT STATUS
    final snapshot = await roomRef.child("exitStatus").get();

    String p1Status = snapshot.child("player1").value?.toString() ?? "online";

    String p2Status = snapshot.child("player2").value?.toString() ?? "online";

    /// 🔥 HEARTBEAT CHECK
    bool isOpponentDead = false;

    if (lastPingReceivedLocalTime > 0) {
      int now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastPingReceivedLocalTime > 12000) {
        isOpponentDead = true;
      }
    }

    /// 🔥 REMOVE ROOM
    if ((p1Status == "exited" && p2Status == "exited") || isOpponentDead) {
      await roomRef.remove();
    } else {
      /// 🔥 NOTIFY OPPONENT
      await roomRef.update({"roomStatus": "ended", "exitBy": myId});
    }

    /// 🔥 CLOSE PAGE
    closeGamePage();
  }

  ///old OpponentExitDialog
  // void showOpponentExitDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) {
  //       return AlertDialog(
  //         title: const Text("Opponent Left"),
  //         content: const Text("Your opponent has left the game."),
  //         actions: [
  //           TextButton(
  //             onPressed: () async {
  //               Navigator.pop(dialogContext);
  //               heartbeatTimer?.cancel();
  //
  //               // 💥 FIX: অপোনেন্ট তো আগেই Exit করেছে, তাই তুমি বের হওয়ার সময় ডিরেক্ট রুম ডিলিট!
  //               await roomRef.remove();
  //
  //               closeGamePage(); // 💥 Safe Pop
  //             },
  //             child: const Text("Exit"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  //new

  //new

  ///new OpponentExitDialog
  Future<void> showOpponentExitDialog() async {
    await showAppDialog(
      context: context,

      title: "OPPONENT LEFT",

      message: "Your opponent has left the match.\nThe room will be closed.",

      positiveText: "EXIT",
      negativeText: "",

      barrierDismissible: false,

      onPositive: () async {
        heartbeatTimer?.cancel();
        if (vibrationOn) {HapticFeedback.mediumImpact();}
        /// 🔥 REMOVE ROOM
        await roomRef.remove();

        /// 🔥 CLOSE PAGE
        closeGamePage();
      },
    );
  }

  // void showRejectedDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) {
  //       return StatefulBuilder(
  //         builder: (context, setStateDialog) {
  //           return AlertDialog(
  //             title: const Text("Replay Rejected"),
  //             content: const Text("Opponent rejected replay ❌"),
  //
  //             actions: [
  //               // 🔁 RESEND BUTTON
  //               TextButton(
  //                 onPressed: resendCooldown == 0
  //                     ? () {
  //                         Navigator.pop(dialogContext);
  //                         handleReplayRequest();
  //                       }
  //                     : null,
  //
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     // 🔁 ICON
  //                     if (resendCooldown == 0)
  //                       const Icon(Icons.refresh, size: 18),
  //
  //                     // 🔥 PROGRESS
  //                     if (resendCooldown > 0)
  //                       SizedBox(
  //                         width: 18,
  //                         height: 18,
  //                         child: CircularProgressIndicator(
  //                           value: resendProgress,
  //                           strokeWidth: 2.5,
  //                         ),
  //                       ),
  //
  //                     const SizedBox(width: 8),
  //
  //                     Text(
  //                       resendCooldown == 0
  //                           ? "Resend"
  //                           : "Wait ${resendCooldown}s",
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.pop(dialogContext);
  //                 },
  //                 child: const Text("OK"),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // void startResendCooldown() {
  //   resendCooldown = 5;
  //   resendProgress = 1.0;
  //
  //   resendTimer?.cancel();
  //
  //   resendTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
  //     if (resendCooldown == 0) {
  //       timer.cancel();
  //     } else {
  //       resendProgress -= 0.02;
  //
  //       if (resendProgress <= 0) {
  //         resendCooldown--;
  //         resendProgress = 1.0;
  //       }
  //
  //       // 🔥 FORCE UI UPDATE
  //       if (mounted) {
  //         setState(() {});
  //       }
  //     }
  //   });
  // }

  // void closeDialogSafe() {
  //   if (dialogOpen && mounted) {
  //     Navigator.of(context, rootNavigator: true).pop();
  //     dialogOpen = false;
  //   }
  // }

  void closeDialogSafe() {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);

    if (dialogOpen && navigator.canPop()) {
      navigator.pop();

      dialogOpen = false;
    }
  }

  ///old restart game
  // Future<void> restartGame() async {
  //
  //   if (isReplayResetting) return;
  //
  //   isReplayResetting = true;
  //
  //   String nextStart = Random().nextBool() ? "X" : "O";
  //
  //   /// 🔥 STOP OLD TIMER + SOUND (ADD)
  //   timerController.stop();
  //   timerController.reset();
  //   clockSoundPlayer.stop();
  //   lastAlertSecond = -1;
  //
  //   // 🔥 FIREBASE RESET
  //   await roomRef.update({
  //     "board": List.filled(boardSize * boardSize, ""),
  //     "winner": "",
  //     "winningLine": [],
  //     "currentTurn": nextStart,
  //     "lastMove": -1,
  //
  //     /// 🔥 ADD TIMER RESET (IMPORTANT)
  //     "timerStart": ServerValue.timestamp,
  //     "turnDuration": 30,
  //   });
  //
  //   await Future.delayed(const Duration(milliseconds: 200));
  //
  //   await roomRef.child("rematch").set({
  //     "requestedBy": "",
  //     "status": ""
  //   });
  //
  //   // 🔥 LOCAL UI RESET (VERY IMPORTANT)
  //   if (mounted) {
  //     setState(() {
  //       winningLine = null;
  //       gameMessage = "";
  //       lastMove = -1;
  //       hasShownResult = false;
  //
  //       /// 🔥 ADD THIS
  //       gameOver = false;
  //       isTimeUp = false;
  //     });
  //   }
  //
  //   // 🔥 STOP EFFECTS
  //   confettiController.stop();
  //   lineController.reset();
  //
  //   isRestarting = false;
  // }

  ///new restart game 1
  // Future<void> restartGame() async {
  //
  //   if (isReplayResetting) return;
  //
  //   isReplayResetting = true;
  //
  //   String nextStart = Random().nextBool() ? "X" : "O";
  //
  //   /// 🔥 HARD RESET TIMER
  //   timerController.stop();
  //   timerController.reset();
  //
  //   clockSoundPlayer.stop();
  //
  //   lastAlertSecond = -1;
  //
  //   serverStartTime = 0;
  //
  //   /// 🔥 LOCAL RESET
  //   if (mounted) {
  //     setState(() {
  //
  //       winningLine = null;
  //
  //       gameMessage = "";
  //
  //       lastMove = -1;
  //
  //       hasShownResult = false;
  //
  //       gameOver = false;
  //
  //       isTimeUp = false;
  //     });
  //   }
  //
  //   /// 🔥 FIREBASE RESET
  //   await roomRef.update({
  //
  //     "board": List.filled(boardSize * boardSize, ""),
  //
  //     "winner": "",
  //
  //     "winningLine": [],
  //
  //     "currentTurn": nextStart,
  //
  //     "lastMove": -1,
  //
  //     /// 🔥 IMPORTANT
  //     "timerStart": ServerValue.timestamp,
  //
  //     "turnDuration": 30,
  //
  //     /// 🔥 ADD
  //     "timeUp": false,
  //   });
  //
  //   await Future.delayed(
  //     const Duration(milliseconds: 300),
  //   );
  //
  //   await roomRef.child("rematch").set({
  //
  //     "requestedBy": "",
  //
  //     "status": ""
  //   });
  //
  //   confettiController.stop();
  //
  //   lineController.reset();
  //
  //   isRestarting = false;
  //
  //   isReplayResetting = false;
  // }

  ///new restart game 2
  Future<void> restartGame() async {
    if (isReplayResetting) return;

    LoadingDialog.show(context, message: "Restarting Match...\n Please Wait");

    isReplayResetting = true;

    String nextStart = Random().nextBool() ? "X" : "O";

    /// 🔥 HARD RESET TIMER
    timerController.stop();

    timerController.reset();

    stopTickingSound();

    serverStartTime = 0;
    hasFirstMove = false;

    /// 🔥 LOCAL RESET
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
      /// 🔥 FIREBASE RESET
      await roomRef.update({
        "board": List.filled(boardSize * boardSize, ""),

        "winner": "",

        "winningLine": [],

        "currentTurn": nextStart,

        "lastMove": -1,

        /// 🔥 IMPORTANT
        //"timerStart": ServerValue.timestamp,
        "timerStart": 0,
        "matchStarted": false,
        "turnDuration": 30,

        "timeUp": false,
      });

      await Future.delayed(const Duration(milliseconds: 300));

      await roomRef.child("rematch").set({"requestedBy": "", "status": ""});

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

  ///old showInternetDialog()
  // void showInternetDialog() {
  //   isDialogOpen = true;
  //
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) {
  //       internetDialogCtx = dialogContext; // 💥 ডায়ালগের কনটেক্সট সেভ করা হলো
  //
  //       return AlertDialog(
  //         title: const Text("Internet Disconnected"),
  //         content: const Text("Please check your connection"),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               if (kIsWeb) {
  //                 showToast("Waiting for internet... 🌐");
  //                 return;
  //               }
  //               checkInternet().then((hasInternet) {
  //                 if (hasInternet) {
  //                   isOfflineDialogShown = false;
  //                   isDialogOpen = false;
  //                   Navigator.pop(dialogContext);
  //                 } else {
  //                   showToast("Still offline ❌");
  //                 }
  //               });
  //             },
  //             child: const Text("Try Again"),
  //           ),
  //         ],
  //       );
  //     },
  //   ).then((_) {
  //     isDialogOpen = false;
  //     internetDialogCtx = null;
  //   });
  // }

  ///new showInternetDialog()1
  // Future<void> showInternetDialog() async {
  //
  //   isDialogOpen = true;
  //
  //   await showAppDialog(
  //     context: context,
  //
  //     /// 🔥 SAVE DIALOG CONTEXT
  //     onDialogCreated: (dialogContext) {
  //       internetDialogCtx = dialogContext;
  //     },
  //
  //     title: "NO INTERNET",
  //
  //     message:
  //     "Connection lost.\nPlease check your internet connection.",
  //
  //     positiveText: "TRY AGAIN",
  //     negativeText: "",
  //
  //     barrierDismissible: false,
  //
  //     onPositive: () async {
  //
  //       if (kIsWeb) {
  //
  //         showToast("Waiting for internet... 🌐");
  //         return;
  //       }
  //
  //       bool hasInternet = await checkInternet();
  //
  //       if (hasInternet) {
  //
  //         isOfflineDialogShown = false;
  //         isDialogOpen = false;
  //
  //         /// 🔥 CLOSE DIALOG
  //         if (internetDialogCtx != null &&
  //             Navigator.of(
  //               internetDialogCtx!,
  //               rootNavigator: true,
  //             ).canPop()) {
  //
  //           Navigator.of(
  //             internetDialogCtx!,
  //             rootNavigator: true,
  //           ).pop();
  //         }
  //
  //       } else {
  //
  //         showToast("Still offline ❌");
  //       }
  //     },
  //   ).then((_) {
  //
  //     isDialogOpen = false;
  //     internetDialogCtx = null;
  //   });
  // }

  ///new noInternetDialog()2
  Future<void> noInternetDialog() async {
    if (isDialogOpen) return;

    isDialogOpen = true;

    await showAppDialog(
      context: context,

      /// 🔥 SAVE DIALOG CONTEXT
      onDialogCreated: (dialogContext) {
        internetDialogCtx = dialogContext;
      },

      title: "NO INTERNET",

      message: "Connection lost.\nWaiting for internet connection...",

      positiveText: "",
      negativeText: "EXIT",

      barrierDismissible: false,

      showContentLoading: true,

      /// 🔥 EXIT GAME
      onNegative: () async {
        isDialogOpen = false;

        internetDialogCtx = null;

        stopTickingSound();

        /// 🔥 DIRECT EXIT
        closeGamePage();
      },
    ).then((_) {
      isDialogOpen = false;

      internetDialogCtx = null;
    });
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
  //             margin: const EdgeInsets.symmetric(horizontal: 8),
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

  ///old
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

  ///new
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
            if (vibrationOn) {HapticFeedback.selectionClick();}

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
            if (vibrationOn) {HapticFeedback.mediumImpact();}

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

  // Widget scoreBox(String player, String symbol, Color bg, Color textColor) {
  //   // 🔥 active player based on Firebase turn
  //   bool isActive = !gameOver && currentTurn == symbol;
  //
  //   List<Color> gradientColors = symbol == "X"
  //       ? [Colors.blueAccent, Colors.cyanAccent]
  //       : [Colors.orangeAccent, Colors.deepOrange];
  //
  //   return AnimatedBuilder(
  //     animation: glowAnimation,
  //     builder: (context, child) {
  //       double glowValue = isActive ? glowAnimation.value : 0;
  //
  //       return Container(
  //         width: 100,
  //         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
  //
  //         decoration: BoxDecoration(
  //           color: bg,
  //           borderRadius: BorderRadius.circular(12),
  //
  //           boxShadow: isActive
  //               ? [
  //                   BoxShadow(
  //                     color: gradientColors.first.withValues(alpha: glowValue),
  //                     blurRadius: 16 * glowValue,
  //                     spreadRadius: 1,
  //                   ),
  //                 ]
  //               : [],
  //         ),
  //
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.center, // 🔥 CENTER
  //           children: [
  //             // 🔥 SYMBOL
  //             ShaderMask(
  //               shaderCallback: (rect) {
  //                 return LinearGradient(
  //                   colors: gradientColors,
  //                 ).createShader(rect);
  //               },
  //               child: Text(
  //                 symbol,
  //                 style: const TextStyle(
  //                   fontSize: 26,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //
  //             const SizedBox(height: 2),
  //
  //             // 🔥 PLAYER NAME
  //             // Text(
  //             //   player,
  //             //   style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
  //             // ),
  //
  //             LayoutBuilder(
  //               builder: (context, constraints) {
  //
  //                 final textSpan = TextSpan(
  //                   text: player,
  //                   style: TextStyle(
  //                     color: textColor,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 );
  //
  //                 final textPainter = TextPainter(
  //                   text: textSpan,
  //                   maxLines: 1,
  //                   textDirection: TextDirection.ltr,
  //                 )..layout();
  //
  //                 double textWidth = textPainter.width;
  //                 double boxWidth = constraints.maxWidth;
  //
  //                 /// 🔥 CONDITION
  //                 if (textWidth > boxWidth) {
  //                   /// 👉 AUTO SCROLL
  //                   return SizedBox(
  //                     height: 18,
  //                     child: ClipRect(
  //                       child: SingleChildScrollView(
  //                         controller: nameScrollController,
  //                         scrollDirection: Axis.horizontal,
  //                         physics: const NeverScrollableScrollPhysics(),
  //
  //                         child: Text(
  //                           player,
  //                           style: TextStyle(
  //                             color: textColor,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 } else {
  //                   /// 👉 NORMAL TEXT (CENTER)
  //                   return Center(
  //                     child: Text(
  //                       player,
  //                       maxLines: 1,
  //                       overflow: TextOverflow.clip,
  //                       style: TextStyle(
  //                         color: textColor,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   );
  //                 }
  //               },
  //             ),
  //
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget scoreBox(String player, String symbol, Color bg, Color textColor) {
    bool isActive = !gameOver && currentTurn == symbol;

    List<Color> gradientColors = symbol == "X"
        ? [Colors.blueAccent, Colors.cyanAccent]
        : [Colors.orangeAccent, Colors.deepOrange];

    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        double glowValue = isActive ? glowAnimation.value : 0;

        return Stack(
          children: [
            /// 🔥 MAIN BOX (UNCHANGED)
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
                  /// 🔥 SYMBOL
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

                  /// 🔥 PLAYER NAME (UNCHANGED)
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

            /// 🔥 TIMER BORDER (NEW)
            if (isActive)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: timerController,
                  builder: (context, child) {
                    int timeLeft = getTimeLeft();

                    /// 🔥 LAST 5 SEC ALERT
                    if (timeLeft <= 5 && timeLeft > 0) {
                      if (timeLeft != lastAlertSecond) {
                        lastAlertSecond = timeLeft;

                        if (soundOn) {
                          clockSoundPlayer.stop();
                          clockSoundPlayer.play(AssetSource("audio/tick.mp3"));
                        }

                        if (vibrationOn) {
                          HapticFeedback.mediumImpact();
                        }
                      }
                    }

                    /// 🔥 COLOR LOGIC
                    Color dynamicColor;

                    if (timeLeft <= 5) {
                      dynamicColor = Colors.red;
                    } else {
                      dynamicColor = symbol == "X"
                          ? Colors.blueAccent
                          : Colors.orangeAccent;
                    }

                    return CustomPaint(
                      painter: TimerBorderPainter(
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

int getWinLength(int size) {
  if (size <= 4) return size; // 3→3, 4→4
  if (size <= 6) return 4; // 5,6 → 4
  return 5; // 7,8,9 → 5
}

Map<String, dynamic> checkWinnerDynamic(List<String> b, int size) {
  int winLen = getWinLength(size);

  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      String current = b[i * size + j];
      if (current.isEmpty) continue;

      List<int> tempLine = [];

      // Horizontal
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

        if (win) return {"winner": current, "line": tempLine};
      }

      // Vertical
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

        if (win) return {"winner": current, "line": tempLine};
      }

      // Diagonal ↘
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

        if (win) return {"winner": current, "line": tempLine};
      }

      // Diagonal ↙
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

        if (win) return {"winner": current, "line": tempLine};
      }
    }
  }

  if (!b.contains("")) return {"winner": "draw", "line": []};

  return {"winner": "", "line": []};
}

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

///////////////////////////////////////
