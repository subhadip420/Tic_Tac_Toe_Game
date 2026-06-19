import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:marquee/marquee.dart';
import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tic_tac_toe/screens/play_online_board_page.dart';
import '../main.dart';
import '../widgets/build_circle_icon_button.dart';
import '../widgets/build_icon_text_button.dart';
import '../widgets/custom_toast.dart';
import 'web_listener_stub.dart'
    if (dart.library.js_interop) 'web_listener.dart';
import '../../widgets/loading_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:tic_tac_toe/widgets/loading_dialog_with_button.dart';

class PlayOnlineStartPage extends StatefulWidget {
  /// Deep link room code
  //final String? initialCode;

  //const PlayOnlineStartPage({Key? key, this.initialCode}) : super(key: key);
  const PlayOnlineStartPage({Key? key}) : super(key: key);

  @override
  State<PlayOnlineStartPage> createState() => PlayOnlineStartPageState();
}

class PlayOnlineStartPageState extends State<PlayOnlineStartPage>
    with TickerProviderStateMixin {
  /// GLOBAL INSTANCE
  static PlayOnlineStartPageState? instance;

  /// USER DATA
  String nickname = "Player";
  String currentUserId = "";
  String? profileImagePath;

  /// ROOM SETTINGS
  bool isCreateSelected = true;
  bool isPublicRoom = false;
  String roomCode = "XXXXXX";
  String enteredCode = "";

  /// BOARD SETTINGS
  int selectedBoardSize = 3;
  final List<int> boardSizes = [3, 4, 5, 6, 7, 8, 9];

  /// GAME STATES
  bool isCodeGenerated = false;
  bool isButtonDisabled = false;
  bool opponentJoined = false;
  bool hasCancelled = false;
  bool isError = false;
  bool isPageActive = true;
  bool hasHandledMatchAction = false;
  bool isExiting = false;

  /// TIMER
  Timer? roomHeartbeatTimer;
  Timer? timer;
  Timer? dotTimer;
  Timer? publicRoomRefreshTimer;

  int countdown = 300;

  /// Countdown progress
  late double progress = countdown / 300;

  String dots = "";

  /// APP SETTINGS
  bool isDark = true;
  bool vibrationOn = true;

  /// FOCUS NODES
  FocusNode hiddenFocus = FocusNode();
  final FocusNode codeFocusNode = FocusNode();

  /// PUBLIC ROOM DATA
  List<Map> publicRooms = [];

  /// INPUT CONTROLLERS
  TextEditingController codeController = TextEditingController();
  TextEditingController hiddenController = TextEditingController();

  /// DIALOG CONTEXTS
  BuildContext? waitingDialogContext;
  BuildContext? noInternetDialogCtx;
  BuildContext? startDialogContext;

  bool isOfflineDialogShowing = false;

  /// ANIMATIONS
  late AnimationController shakeController;
  late Animation<double> shakeAnimation;
  AnimationController? borderController;

  /// STREAM LISTENERS
  StreamSubscription? publicRoomListener;
  StreamSubscription? internetSubscription;
  StreamSubscription? roomListener;

  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        "https://tic-tac-toe-9c3bf-default-rtdb.asia-southeast1.firebasedatabase.app/",
  ).ref();

  @override
  void initState() {
    super.initState();

    /// INSTANCE
    instance = this;

    // print("INITIAL CODE = ${widget.initialCode}");
    // if (widget.initialCode != null &&
    //     widget.initialCode!.isNotEmpty) {
    //
    //   Future.delayed(
    //     const Duration(seconds: 2),
    //         () {
    //       handleDeepLinkJoin(
    //         widget.initialCode!,
    //       );
    //     },
    //   );
    // }

    /// LOAD SETTINGS & USER DATA
    monitorInternet();
    loadBoardSize();
    loadProfileImage();
    loadUser();
    loadSettings();

    /// ROOM CLEANUP
    cleanUpDeadRooms();

    /// CHECK USER AFTER BUILD
    Future.delayed(Duration.zero, () {
      checkUser(); // ADD THIS
    });

    /// BORDER ANIMATION
    borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 300),
    );

    borderController!.forward(); // start animation
    /// SHAKE ANIMATION
    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: shakeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    /// CANCEL TIMERS
    timer?.cancel();
    dotTimer?.cancel();
    publicRoomRefreshTimer?.cancel();

    /// CANCEL STREAM LISTENERS
    publicRoomListener?.cancel();
    roomListener?.cancel();
    internetSubscription?.cancel();

    /// RESET INSTANCE
    instance = null;

    /// DISPOSE ANIMATIONS
    shakeController.dispose();
    borderController?.dispose();

    hasHandledMatchAction = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      /// Block back when room active
      canPop: !isCodeGenerated,

      /// Handle system back press
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await handleBackPress();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,

        /// Page background color
        backgroundColor: isDark
            ? const Color(0xFF0F172A) // dark background
            : const Color(0xFFF3F7FF),

        /// light background
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,

          /// Status bar style
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // transparent status bar
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark, // Android
            statusBarBrightness: isDark
                ? Brightness.dark
                : Brightness.light, // iOS
          ),

          /// Bottom divider line
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ),

          /// Glass blur background
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),

          /// AppBar title
          title: Text(
            "Play Online",
            style: TextStyle(
              color: isDark ? Colors.cyanAccent : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          leading: Padding(
            /// Back button
            padding: const EdgeInsets.only(left: 12),
            child: Tooltip(
              message: "Back",
              child: GestureDetector(
                /// Handle back action
                onTap: () async {
                  if (vibrationOn) {
                    HapticFeedback.lightImpact();
                  }
                  await handleBackPress();
                },
                child: build3DIconButton(
                  icon: Icons.arrow_back,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          actions: [
            /// Profile button
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: "Profile",
                child: GestureDetector(
                  /// Open profile dialog
                  onTap: () {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }

                    /// Prevent opening during active room
                    if (isCodeGenerated) {
                      showCloseRoomBeforeOpenProfileDialog();
                    } else {
                      openProfileDialog();
                    }
                  },

                  /// Profile avatar button
                  child: build3DIconButton(
                    text: nickname.isNotEmpty ? nickname[0].toUpperCase() : "P",
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ],
        ),

        body: SingleChildScrollView(
          child: Padding(
            /// Page padding
            padding: EdgeInsets.fromLTRB(
              20,

              /// Safe top spacing below AppBar
              kToolbarHeight + MediaQuery.of(context).padding.top + 10,
              20,
              20,
            ),

            /// Main 3D card widget
            child: build3DCard(),
          ),
        ),
      ),
    );
  }

  Widget build3DCard() {
    return Column(
      children: [
        /// Main create/join card
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            /// Card background color
            color: isDark ? const Color(0xFF26344B) : const Color(0xFFE9E9EF),
            borderRadius: BorderRadius.circular(25),

            /// Card border
            border: Border.all(
              width: 1.5,
              color: isDark ? Color(0xFF122B57) : Colors.blue,
            ),

            /// 3D shadow effect
            boxShadow: [
              /// Top-left light shadow
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.9),
                offset: const Offset(-6, -6),
                blurRadius: 12,
              ),

              /// Bottom-right dark shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                offset: const Offset(6, 6),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            children: [
              /// Create / Join toggle section
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    /// Create room button
                    Expanded(
                      child: GestureDetector(
                        /// Switch to create mode
                        onTap: () {
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }
                          setState(() => isCreateSelected = true);
                        },
                        child: AnimatedContainer(
                          /// Toggle animation
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            /// Active tab color
                            color: isCreateSelected
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),

                            /// Active shadow effect
                            boxShadow: isCreateSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            /// Create button text
                            child: Text(
                              "CREATE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: isCreateSelected
                                    ? Color(0xFFFFFFFF)
                                    : Color(0xFF9D9D9F),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Join room button
                    Expanded(
                      child: GestureDetector(
                        /// Switch to join mode
                        onTap: () {
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }
                          setState(() => isCreateSelected = false);
                        },
                        child: AnimatedContainer(
                          /// Toggle animation
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            /// Active tab color
                            color: !isCreateSelected
                                ? Color(0xFF448BE5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),

                            /// Active shadow effect
                            boxShadow: !isCreateSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            /// Join button text
                            child: Text(
                              "JOIN",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: !isCreateSelected
                                    ? Color(0xFFF8F9FA)
                                    : Color(0xFF9D9D9F),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Create room section
              if (isCreateSelected) ...[
                const SizedBox(height: 10),

                /// Board size selection card
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),

                    ///  Gradient Neon Border
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Colors.cyanAccent, Colors.cyanAccent]
                          : const [Colors.blueAccent, Colors.blueAccent],
                    ),

                    /// Outer glow effect
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      /// Inner card background
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),

                      /// Inner shadow depth
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.6 : 0.1,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Board size header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// Title text
                            Text(
                              "Board Size",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),

                            /// Selected board size text
                            Text(
                              "${selectedBoardSize}x$selectedBoardSize",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// Premium board size slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            trackShape: GradientTrackShape(),
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbShape: GlowThumb(isDark: isDark),
                          ),
                          child: Slider(
                            value: selectedBoardSize.toDouble(),
                            min: 3,
                            max: 9,
                            divisions: 6,
                            label: "${selectedBoardSize}x$selectedBoardSize",

                            /// Update board size
                            onChanged: (value) {
                              int newValue = value.toInt();

                              /// Vibration feedback
                              if (newValue != selectedBoardSize) {
                                if (vibrationOn) {
                                  HapticFeedback.selectionClick();
                                }
                              }

                              setState(() {
                                /// Update selected size
                                selectedBoardSize = newValue;
                              });

                              /// Save selected size
                              saveBoardSize(selectedBoardSize);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              /// Room display card
              Container(
                decoration: BoxDecoration(
                  /// Top rounded corners
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),

                  /// Gradient border
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.blueAccent],
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  margin: const EdgeInsets.all(1.5),

                  /// Border thickness
                  decoration: BoxDecoration(
                    /// Gradient background
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF0F172A)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFCDEDF8), Color(0xFFCDEDF8)],
                          ),

                    /// Card corner radius
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),

                    /// Glow & depth shadow
                    boxShadow: [
                      /// Cyan glow effect
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(
                          alpha: isDark ? 0.4 : 0.3,
                        ),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),

                      /// Main shadow
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.6 : 0.2,
                        ),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Public room loading animation
                      if (isCreateSelected &&
                          isCodeGenerated &&
                          isPublicRoom) ...[
                        //const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: Lottie.asset(
                            "assets/lottie/sandy_loading.json",
                            repeat: true,
                          ),
                        ),
                      ]
                      /// Private room code display
                      else if (isCreateSelected) ...[
                        Text(
                          "Your Room Code",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 5),

                        /// Generated room code
                        Text(
                          roomCode,
                          style: TextStyle(
                            fontSize: 34,
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ]
                      /// Join room section
                      else ...[
                        Text(
                          "Enter Room Code",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 5),

                        /// Room code input field
                        buildCodeInput(),
                      ],

                      /// Room waiting status
                      if (isCreateSelected && isCodeGenerated)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              /// Room expiry timer
                              Center(
                                child: Text(
                                  "Your Room Code will expire in "
                                  "${(countdown ~/ 60).toString().padLeft(2, '0')}:"
                                  "${(countdown % 60).toString().padLeft(2, '0')} min.",
                                  textAlign: TextAlign.center,

                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              /// Finding opponent animation text
                              Text(
                                "Finding Opponent$dots",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 0),

              /// Generate code button
              if (isCreateSelected && !isCodeGenerated)
                Pressable3DButton(
                  /// Generate room code
                  onTap: () async {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }

                    /// Prevent multiple taps
                    if (isButtonDisabled) return;

                    /// Check internet connection
                    bool isConnected = await checkInternet();

                    /// No internet warning
                    if (!isConnected) {
                      CustomToast.show(
                        context: context,
                        message: "No Internet Connection",
                        isDark: isDark,
                        icon: Icons.portable_wifi_off_rounded,
                        color: Colors.orange,
                      );
                      return;
                    }

                    /// Generate room code
                    await generateCode();
                  },
                  child: BuildIconTextButton(
                    icon: Icons.auto_awesome,
                    text: "GENERATE CODE",
                    isDark: isDark,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),

                    /// Button shadow
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.6 : 0.2,
                        ),
                        offset: const Offset(3, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 1),

              /// Create room action buttons
              if (isCreateSelected && isCodeGenerated) ...[
                Row(
                  children: [
                    /// Copy room code button
                    Expanded(
                      child: Pressable3DButton(
                        onTap: () async {
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }

                          /// Copy room code
                          handleCopyRoomCode();
                        }, // call function
                        child: BuildIconTextButton(
                          icon: Icons.copy,
                          text: "COPY",
                          isDark: isDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.6 : 0.2,
                              ),
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 2),

                    /// Share room code button
                    Expanded(
                      child: Pressable3DButton(
                        onTap: () async {
                          HapticFeedback.lightImpact();

                          /// Share room code
                          handleShareRoomCode();
                        },
                        child: BuildIconTextButton(
                          icon: Icons.share,
                          text: "SHARE",
                          isDark: isDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.6 : 0.2,
                              ),
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              /// Join room action buttons
              if (!isCreateSelected) ...[
                Row(
                  children: [
                    /// Paste room code button
                    Expanded(
                      child: Pressable3DButton(
                        onTap: () async {
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }

                          /// Paste copied room code
                          handlePasteRoomCode();
                        }, // function call
                        child: BuildIconTextButton(
                          icon: Icons.paste,
                          text: "PASTE",
                          isDark: isDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.6 : 0.2,
                              ),
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 2),

                    /// Play button
                    Expanded(
                      child: Pressable3DButton(
                        /// Validate & join room
                        onTap: () async {
                          /// Hide keyboard
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }

                          /// Small delay before validation
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          /// Validate room code
                          await validateRoomCode();
                        },
                        child: BuildIconTextButton(
                          icon: Icons.play_arrow,
                          text: "PLAY",
                          isDark: isDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(20),
                          ),

                          /// Button shadow
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.6 : 0.2,
                              ),
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              /// Close room section
              if (isCreateSelected && isCodeGenerated) ...[
                const SizedBox(height: 10),
                Pressable3DButton(
                  /// Show close room dialog
                  onTap: () async {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }

                    /// Hide keyboard
                    FocusScope.of(context).unfocus();
                    await showCloseRoomDialog();
                  },

                  child: Stack(
                    children: [
                      /// Main close room button
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          /// Button background gradient
                          gradient: isDark
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2A1A1A),
                                    Color(0xFF2A1A1A),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFF6DBDB),
                                    Color(0xFFF6DBDB),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            /// Close icon
                            Icon(
                              Icons.close,
                              color: isDark ? Colors.redAccent : Colors.red,
                            ),
                            const SizedBox(width: 8),

                            /// Button title
                            Text(
                              "CLOSE ROOM",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.redAccent : Colors.red,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Progress border animation
                      Positioned.fill(
                        child: CustomPaint(
                          /// Draw countdown progress border
                          painter: BorderProgressPainter(
                            /// Progress value
                            countdown / 300,

                            /// Border color
                            Colors.red,
                            20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              /// OR divider section
              if (isCreateSelected && !isCodeGenerated) ...[
                const SizedBox(height: 10),

                Row(
                  children: [
                    /// Left divider
                    Expanded(child: Divider(thickness: 1)),

                    /// OR text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    /// Right divider
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),

                const SizedBox(height: 10),
              ],

              /// Quick match button
              if (isCreateSelected && !isCodeGenerated) ...[
                Pressable3DButton(
                  /// Create public room
                  onTap: () async {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }

                    /// Hide keyboard
                    FocusScope.of(context).unfocus();

                    await createPublicRoomInFirebase();
                  },
                  child: BuildIconTextButton(
                    icon: Icons.public,
                    text: "QUICK MATCH",
                    isDark: isDark,
                    borderRadius: const BorderRadius.all(Radius.circular(19)),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 15),

        /// Available public rooms section
        buildAvailableRoomsCard(),
      ],
    );
  }

  Widget buildAvailableRoomsCard() {
    //final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        /// Card background color
        color: isDark ? const Color(0xFF26344B) : const Color(0xFFE9E9EF),
        borderRadius: BorderRadius.circular(25),

        /// Card border
        border: Border.all(
          width: 1.5,
          color: isDark ? Color(0xFF122B57) : Colors.blue,
        ),

        /// Card shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
            blurRadius: 10,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header section
          Center(
            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.only(bottom: 0),

              decoration: BoxDecoration(
                /// Header radius
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(23.5),
                  topRight: Radius.circular(23.5),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),

                /// Header background color
                color: isDark ? Color(0xFF122B57) : Colors.white70,

                /// Header glow shadow
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.blue.withValues(alpha: 0.4)
                        : Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 2,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                    offset: const Offset(0, 0),
                    blurRadius: 2,
                  ),
                ],
              ),

              child: Column(
                children: [
                  /// Card title
                  Text(
                    "Available Rooms",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,

                      /// Gradient text effect
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: isDark
                              ? [Colors.white, Colors.white]
                              : [Colors.blue, Colors.blue],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          //const SizedBox(height: 10),

          /// Empty room message
          publicRooms.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),

                  child: const Center(
                    child: Text(
                      "No available rooms to join",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              /// Public room list
              : SizedBox(
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: publicRooms.length,
                    itemBuilder: (context, index) {
                      final room = publicRooms[index];

                      return KeyedSubtree(
                        /// Prevent item flicker
                        key: ValueKey(room["code"]),

                        /// Room item widget
                        child: buildRoomItem(room),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  /// PUBLIC ROOM ITEM CARD
  Widget buildRoomItem(Map room) {
    /// Room timer progress
    int createdAt = room["createdAt"] ?? 0;
    int now = DateTime.now().millisecondsSinceEpoch;
    double totalDuration = 300000; // 5 min
    double elapsed = (now - createdAt).toDouble();
    double progress = (elapsed / totalDuration).clamp(0.0, 1.0);
    double remainingProgress = 1 - progress;

    /// SAFE access
    String? creatorId = room["creatorId"];

    /// SAFE compare
    bool isMyRoom =
        currentUserId.isNotEmpty &&
        creatorId != null &&
        creatorId == currentUserId;

    /// Player name & avatar letter
    String name = room["name"] ?? "Player";
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "P";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      /// Outer gradient border
      padding: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.blueAccent],
        ),

        /// Glow effect
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),

      child: Container(
        padding: const EdgeInsets.all(10),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),

          /// Main background gradient
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                ),

          /// Card shadow
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.2),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
              offset: const Offset(3, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// Left section
            Expanded(
              child: Row(
                children: [
                  /// Player avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.cyan],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// Player name & board size
                  Expanded(
                    child: Row(
                      children: [
                        /// Player name section
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              /// Check text overflow
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),

                                maxLines: 1,
                                textDirection: TextDirection.ltr,
                              )..layout();

                              bool shouldScroll =
                                  textPainter.width > constraints.maxWidth;

                              /// Auto marquee for long names
                              if (shouldScroll) {
                                return SizedBox(
                                  height: 20,
                                  child: Marquee(
                                    text: name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),

                                    scrollAxis: Axis.horizontal,
                                    blankSpace: 40,
                                    velocity: 25,
                                    pauseAfterRound: const Duration(seconds: 1),
                                    startPadding: 10,
                                    accelerationDuration: const Duration(
                                      milliseconds: 800,
                                    ),

                                    accelerationCurve: Curves.linear,
                                    decelerationDuration: const Duration(
                                      milliseconds: 500,
                                    ),

                                    decelerationCurve: Curves.easeOut,
                                  ),
                                );
                              }

                              /// Normal player name text
                              return Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 6),

                        /// Board size text
                        Text(
                          "(${room["boardSize"]}x${room["boardSize"]})",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            /// Room action button
            isMyRoom
                /// Current user's room label
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    child: Text(
                      "YOUR ROOM",
                      style: TextStyle(
                        color: isDark
                            ? Colors
                                  .white70 //  dark mode
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                /// Join room button
                : GestureDetector(
                    /// Join selected room
                    onTap: () async {
                      await smartJoinRoom(room["code"]);
                    },

                    child: Stack(
                      children: [
                        /// Main join button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.blue],
                            ),

                            /// Glow effect
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text(
                            "JOIN",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),

                        /// Timer progress border
                        Positioned.fill(
                          child: CustomPaint(
                            painter: BorderProgressPainter(
                              /// Remaining room timer progress
                              remainingProgress,

                              /// Border color
                              Colors.cyanAccent,

                              /// Border radius
                              12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// ROOM CODE INPUT UI
  Widget buildCodeInput() {
    //final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        /// Hidden real TextField
        TextField(
          controller: hiddenController,
          focusNode: hiddenFocus,
          maxLength: 6,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,

          /// Hide actual text
          style: const TextStyle(color: Colors.transparent),

          /// Hide cursor
          cursorColor: Colors.transparent,

          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
          ),

          /// Handle room code input
          onChanged: (value) {
            /// Allow only A-Z & 0-9
            String filtered = value.toUpperCase().replaceAll(
              RegExp(r'[^A-Z0-9]'),
              '',
            );

            /// Limit code length
            if (filtered.length > 6) {
              filtered = filtered.substring(0, 6);
            }

            setState(() {
              /// Update entered code
              enteredCode = filtered;
              hiddenController.text = filtered;

              /// Keep cursor at end
              hiddenController.selection = TextSelection.fromPosition(
                TextPosition(offset: filtered.length),
              );
            });

            /// Auto hide keyboard
            if (filtered.length == 6) {
              FocusScope.of(context).unfocus();
            }
          },
        ),

        /// Custom code UI boxes
        IgnorePointer(
          /// Prevent direct touch
          child: AnimatedBuilder(
            /// Shake animation
            animation: shakeController,
            builder: (context, child) {
              return Transform.translate(
                /// Error shake effect
                offset: Offset(shakeAnimation.value, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                /// Active input box
                bool isActive = index == enteredCode.length;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,

                    /// Border state colors
                    border: Border.all(
                      color: isError
                          ? Colors.red
                          : (isActive
                                ? Colors.blue
                                : (isDark ? Colors.white24 : Colors.black12)),
                      width: isError ? 2 : (isActive ? 2 : 1),
                    ),
                  ),

                  /// Display room code characters
                  child: Text(
                    index < enteredCode.length ? enteredCode[index] : "",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// LOAD SAVED BOARD SIZE
  Future<void> loadBoardSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      /// Load saved board size
      selectedBoardSize = prefs.getInt("board_size") ?? 3;
    });
  }

  /// SAVE BOARD SIZE
  Future<void> saveBoardSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("board_size", size);
  }

  /// LOAD USER DATA
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      /// Load current user id
      currentUserId = prefs.getString("nickname") ?? "Player";
    });

    /// Start listening public rooms
    listenPublicRooms();
  }

  /// LOAD APP SETTINGS
  Future loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      /// Load theme mode
      isDark = prefs.getBool("theme_dark") ?? true;

      /// Load vibration setting
      vibrationOn = prefs.getBool("vibration_on") ?? true;
    });
  }

  /// HIDE KEYBOARD
  void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// ERROR SHAKE ANIMATION
  void triggerError() async {
    /// Error vibration
    HapticFeedback.mediumImpact();

    /// Enable error state
    setState(() {
      isError = true;
    });

    /// Start shake animation
    await shakeController.forward(from: 0);

    /// Reset animation
    shakeController.reset();

    /// Disable error state
    setState(() {
      isError = false;
    });
  }

  /// LOAD PROFILE IMAGE
  void loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();

    /// Load saved profile image
    setState(() {
      profileImagePath = prefs.getString("profile_image");
    });
  }

  /// HANDLE BACK PRESS
  Future<void> handleBackPress() async {
    /// Prevent multiple exit calls
    if (isExiting) return;
    isExiting = true;

    try {
      /// Direct exit if room inactive
      if (!isCodeGenerated) {
        //Navigator.pop(context);
        Navigator.of(context, rootNavigator: true).pop();
        return;
      }

      /// Vibration feedback
      if (vibrationOn) {
        HapticFeedback.selectionClick();
      }

      /// Show close room dialog
      await showCloseRoomBeforeExitDialog();
    } finally {
      /// Reset exit state
      isExiting = false;
    }
  }

  ///  START ROOM HEARTBEAT
  void startRoomHeartbeat(String roomCode) {
    /// Stop old heartbeat timer
    roomHeartbeatTimer?.cancel();

    /// Send heartbeat every 5 seconds
    roomHeartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        /// Update player heartbeat timestamp
        await dbRef
            .child("rooms/$roomCode/heartbeat/player1")
            .set(DateTime.now().millisecondsSinceEpoch);
      } catch (e) {
        /// Heartbeat error log
        print("Heartbeat Error: $e");
      }
    });
  }

  /// STOP ROOM HEARTBEAT
  void stopRoomHeartbeat() {
    /// Cancel active heartbeat timer
    if (roomHeartbeatTimer?.isActive ?? false) {
      roomHeartbeatTimer?.cancel();
      print(" Room heartbeat stopped");
    }
  }

  /// UPDATE PUBLIC ROOM LIST
  void updatePublicRooms(dynamic data) {
    /// Clear rooms if no data
    if (data == null) {
      setState(() {
        publicRooms = [];
      });

      return;
    }

    Map rooms = data as Map;
    List<Map> temp = [];
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    rooms.forEach((key, value) {
      if (value == null) return;

      /// Filter waiting public rooms
      if (value["roomType"] == "public" && value["status"] == "waiting") {
        final heartbeatData = value["heartbeat"];
        int heartbeat = 0;

        /// Get player heartbeat
        if (heartbeatData != null && heartbeatData["player1"] != null) {
          heartbeat = heartbeatData["player1"];
        }

        /// Save heartbeat
        if (heartbeat > 0) {
          bool isAlive = (currentTime - heartbeat) <= 30000;
          if (!isAlive) return;
        }

        /// Reverse latest rooms first
        temp.add({
          "code": key,
          "name": value["players"]["player1"]["uid"] ?? "Player",
          "boardSize": value["boardSize"] ?? 3,
          "creatorId": value["creatorId"],
          "createdAt": value["createdAt"] ?? 0,

          /// Save heartbeat
          "heartbeat": heartbeat,
        });
      }
    });

    /// Reverse latest rooms first
    temp = temp.reversed.toList();
    if (!mounted) return;
    setState(() {
      /// Update public room list
      publicRooms = temp;
    });
  }

  /// LISTEN PUBLIC ROOMS
  void listenPublicRooms() {
    /// Cancel old listener
    publicRoomListener?.cancel();

    /// Listen realtime room updates
    publicRoomListener = dbRef.child("rooms").onValue.listen((event) {
      if (!mounted) return;
      updatePublicRooms(event.snapshot.value);
    });
  }

  /// CHECK INTERNET CONNECTION
  Future<bool> checkInternet() async {
    /// Web always returns true
    if (kIsWeb) {
      return true;
    }
    try {
      /// Ping Google endpoint
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 204;
    } catch (_) {
      /// No internet
      return false;
    }
  }

  /// MONITOR INTERNET STATUS
  void monitorInternet() {
    /// Initial internet check
    checkInternet().then((hasInternet) {
      _updateInternetState(hasInternet);
    });

    /// Mobile realtime connectivity listener
    internetSubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      bool hasInternet = await checkInternet();
      _updateInternetState(hasInternet);
    });

    /// Web online/offline listeners
    if (kIsWeb) {
      setupWebListeners(
        onOffline: () {
          if (!isPageActive || !mounted) return;
          _updateInternetState(false);
        },
        onOnline: () {
          if (!isPageActive || !mounted) return;
          _updateInternetState(true);
        },
      );
    }
  }

  /// UPDATE INTERNET STATE
  void _updateInternetState(bool hasInternet) {
    /// Stop if page inactive
    if (!isPageActive) return;
    if (!mounted) return;

    /// No internet detected
    if (!hasInternet) {
      /// Show no internet dialog
      if (!isOfflineDialogShowing) {
        isOfflineDialogShowing = true;

        Future.delayed(Duration.zero, () {
          if (mounted) {
            /// Vibration feedback
            if (vibrationOn) {
              HapticFeedback.vibrate();
            }
            showNoInternetDialog();
          }
        });
      }
    } else {
      /// Close offline dialog
      if (isOfflineDialogShowing && noInternetDialogCtx != null) {
        Navigator.of(noInternetDialogCtx!, rootNavigator: true).pop();
        noInternetDialogCtx = null;
        isOfflineDialogShowing = false;

        /// Vibration feedback
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }

        /// Internet restored toast
        CustomToast.show(
          context: context,
          message: "Internet Restored.",
          isDark: isDark,
          icon: Icons.wifi_rounded,
          color: Colors.green,
        );
      }
    }
  }

  /// EXIT FROM NO INTERNET SCREEN
  Future<void> _exitFromNoInternet() async {
    /// Stop room heartbeat
    stopRoomHeartbeat();

    /// Reset dialog flags
    noInternetDialogCtx = null;
    isOfflineDialogShowing = false;

    /// Exit current page
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// GENERATE PRIVATE ROOM CODE
  Future<void> generateCode() async {
    /// Random code characters
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random random = Random();

    /// Generate 6 digit room code
    String newCode = List.generate(6, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();

    setState(() {
      /// Update room state
      roomCode = newCode;
      isPublicRoom = false;
      isCodeGenerated = true;
      isButtonDisabled = true;
      opponentJoined = false;
      countdown = 300;
    });

    /// Start room timer & animation
    startTimer();
    startDotAnimation();
    borderController?.reset();
    borderController?.forward();
    print(" Generating Code...");

    /// Create Firebase room
    await createPrivateRoomInFirebase(newCode); //  FIX
    print("✅ Done");
  }

  /// CREATE PUBLIC ROOM
  Future<void> createPublicRoomInFirebase() async {
    /// Prevent duplicate room creation
    if (isCodeGenerated) {
      CustomToast.show(
        context: context,
        message: "Room Already Created!",
        isDark: isDark,
        //icon: Icons.meeting_room_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Check internet connection
    bool isConnected = await checkInternet();
    if (!isConnected) {
      CustomToast.show(
        context: context,
        message: "No Internet Connection",
        isDark: isDark,
        icon: Icons.wifi_off_rounded,
        color: Colors.orange,
      );

      return;
    }

    /// Generate random room code
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random random = Random();
    String newCode = List.generate(6, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();

    setState(() {
      /// Update room state
      roomCode = newCode;
      isCodeGenerated = true;
      isButtonDisabled = true;
      opponentJoined = false;
      countdown = 300;
      isPublicRoom = true;
    });

    /// Start timer & animation
    startTimer();
    startDotAnimation();
    borderController?.reset();
    borderController?.forward();

    /// Show loading dialog
    LoadingDialog.show(context, message: "Creating Room...");

    try {
      final prefs = await SharedPreferences.getInstance();

      /// Get current user id
      String userId = prefs.getString("nickname") ?? "Player";

      /// Current timestamp
      int now = DateTime.now().millisecondsSinceEpoch;

      /// Create Firebase room
      await dbRef.child("rooms/$newCode").set({
        "matchStarted": false,
        "roomCode": newCode,
        "creatorId": userId,
        "createdAt": now,
        "status": "waiting",

        /// Public room type
        "roomType": "public",
        "boardSize": selectedBoardSize,

        /// Player data
        "players": {
          "player1": {"uid": userId, "symbol": "O"},
        },

        /// Heartbeat data
        "heartbeat": {"player1": now},
        "exitStatus": {"player1": "online", "player2": "online"},
        "currentTurn": "",
        "board": List.filled(selectedBoardSize * selectedBoardSize, ""),
        "winner": "",
      });

      /// Start heartbeat listener
      startRoomHeartbeat(newCode);

      /// Listen opponent join
      listenForOpponent(newCode);

      /// Searching opponent toast
      CustomToast.show(
        context: context,
        message: "Finding Opponent...",
        isDark: isDark,
        icon: Icons.search_rounded,
        color: Colors.blueAccent,
      );
    } catch (e) {
      /// Firebase error log
      print("❌ Firebase ERROR: $e");
    } finally {
      /// Hide loading dialog
      LoadingDialog.hide(context);
    }
  }

  /// CREATE PRIVATE ROOM
  Future<void> createPrivateRoomInFirebase(String code) async {
    /// Show loading dialog
    LoadingDialog.show(context, message: "Creating room...");

    try {
      print(" createRoomInFirebase start");

      final prefs = await SharedPreferences.getInstance();

      /// Get current user id
      String userId = prefs.getString("nickname") ?? "Player";

      /// Create private room in Firebase
      await dbRef.child("rooms/$code").set({
        "roomCode": code,
        "creatorId": userId,
        "createdAt": DateTime.now().millisecondsSinceEpoch,
        "status": "waiting",
        "matchStarted": false,
        "roomType": "private",
        "boardSize": selectedBoardSize,

        /// Player data
        "players": {
          "player1": {"uid": userId, "symbol": "O"},
        },
        "exitStatus": {"player1": "online", "player2": "online"},
        "currentTurn": "",
        "board": List.filled(selectedBoardSize * selectedBoardSize, ""),
        "winner": "",
      });

      print("✅ Room created");

      /// Listen opponent join
      listenForOpponent(code);
    } catch (e) {
      /// Firebase error log
      print("❌ Firebase ERROR: $e");
    } finally {
      /// Hide loading dialog
      LoadingDialog.hide(context);
    }
  }

  /// START ROOM TIMER
  void startTimer() {
    /// Cancel old timer
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      /// Pause timer after opponent joins
      if (opponentJoined) {
        return;
      }

      /// Room expired
      if (countdown == 0) {
        t.cancel();

        /// Delete room if no opponent joined
        if (!opponentJoined) {
          deleteRoom(roomCode);
        }

        setState(() {
          /// Reset room state
          roomCode = "XXXXXX";
          isCodeGenerated = false;
          isButtonDisabled = false;
        });

        /// Room expired toast
        CustomToast.show(
          context: context,
          message: "Room Expired!",
          isDark: isDark,
          icon: Icons.timer_off_rounded,
          color: Colors.redAccent,
        );
      } else {
        setState(() {
          /// Decrease countdown timer
          countdown--;
        });
      }
    });
  }

  /// START LOADING DOT ANIMATION
  void startDotAnimation() {
    /// Cancel old animation timer
    dotTimer?.cancel();

    dotTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      /// Animate loading dots
      setState(() {
        if (dots.length >= 3) {
          dots = "";
        } else {
          dots += ".";
        }
      });
    });
  }

  /// COPY ROOM CODE
  Future<void> handleCopyRoomCode() async {
    /// Check valid room code
    if (roomCode.isEmpty || roomCode == "XXXXXX") {
      CustomToast.show(
        context: context,
        message: "No Room Code Available ❌",
        isDark: isDark,
        icon: Icons.error_outline_rounded,
        color: Colors.redAccent,
      );
      return;
    }

    /// Copy room code
    await Clipboard.setData(ClipboardData(text: roomCode));

    /// Success toast
    CustomToast.show(
      context: context,
      message: "Room Code Copied.",
      isDark: isDark,
      icon: Icons.copy_rounded,
      color: Colors.green,
    );
  }

  /// PASTE ROOM CODE
  Future<void> handlePasteRoomCode() async {
    /// Get clipboard text
    final data = await Clipboard.getData('text/plain');

    /// Empty clipboard check
    if (data?.text == null || data!.text!.isEmpty) {
      CustomToast.show(
        context: context,
        message: "Clipboard Empty!",
        isDark: isDark,
        icon: Icons.content_paste_off_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Filter valid room code characters
    String pasted = data.text!.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );

    /// Limit code length
    if (pasted.length > 6) {
      pasted = pasted.substring(0, 6);
    }
    setState(() {
      /// Update entered code
      enteredCode = pasted;
      hiddenController.text = pasted;
    });

    /// Paste success toast
    CustomToast.show(
      context: context,
      message: "Code Pasted!",
      isDark: isDark,
      icon: Icons.content_paste_rounded,
      color: Colors.green,
    );
  }

  ////////////////////////////////////////////////////////////////////////
  /// SHARE ROOM CODE
  Future<void> handleShareRoomCode() async {
    /// Validate room code
    if (roomCode.isEmpty || roomCode == "XXXXXX") {
      CustomToast.show(
        context: context,
        message: "No Room Code to Share!",
        isDark: isDark,
        //icon: Icons.share_off_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Generate invite link
    //String link = generateInviteLink();
    DateTime now = DateTime.now();
    DateTime expiry = now.add(const Duration(minutes: 5));

    /// Format expiry time
    String formattedTime =
        "${expiry.hour.toString().padLeft(2, '0')}:"
        "${expiry.minute.toString().padLeft(2, '0')}";

    /// Share invite message
    await SharePlus.instance.share(
      ShareParams(
        text:
            "🎮 Join my TicTacToe match!\n"
            "Room Code: $roomCode\n"
            //"Click here to join instantly:\n$link \n"
            "Open Play Online → Enter Code → Click Join\n"
            "Expires at: $formattedTime",
      ),
    );
  }

  /// GENERATE INVITE LINK
  // String generateInviteLink() {
  //   return "https://tic-tac-toe-9c3bf.web.app/join?code=$roomCode";
  // }

  /// HANDLE DEEP LINK JOIN
  // Future<void> handleDeepLinkJoin(String code) async {
  //   print(" AUTO JOIN: $code");
  //
  //   /// Delete current room if active
  //   if (isCodeGenerated && roomCode.isNotEmpty) {
  //     await deleteRoom(roomCode);
  //   }
  //
  //   /// Fill room code
  //   enteredCode = code;
  //   hiddenController.text = code;
  //   setState(() {});
  //
  //   /// Small delay before join
  //   await Future.delayed(const Duration(milliseconds: 200));
  //
  //   /// Join room automatically
  //   await smartJoinRoom(code);
  //
  //   /// MAIN JOIN
  // }

  /// HANDLE INCOMING DEEP LINK
  // void handleIncomingLink(Uri uri) {
  //   /// Check join route
  //   if (uri.path.contains("join")) {
  //     String? code = uri.queryParameters['code'];
  //
  //     /// Valid room code check
  //     if (code != null && code.isNotEmpty) {
  //       print(" Deep link received: $code");
  //
  //       Future.delayed(const Duration(milliseconds: 100), () {
  //         /// Already on online page
  //         if (PlayOnlineStartPageState.instance != null) {
  //           PlayOnlineStartPageState.instance!.handleDeepLinkJoin(code);
  //         } else {
  //           /// Open online start page
  //           navigatorKey.currentState?.pushAndRemoveUntil(
  //             MaterialPageRoute(
  //               builder: (_) => PlayOnlineStartPage(initialCode: code),
  //               settings: const RouteSettings(name: "/playOnline"),
  //             ),
  //             (route) => false,
  //           );
  //         }
  //       });
  //     }
  //   }
  // }

  /// CHECK & LOAD USER
  Future<void> checkUser() async {
    final prefs = await SharedPreferences.getInstance();

    /// Load saved nickname
    String name = prefs.getString("nickname") ?? "";

    /// Generate random name if empty
    if (name.isEmpty) {
      name = generatePlayerName();
      await prefs.setString("nickname", name);
    }
    if (!mounted) return;
    setState(() {
      /// Update nickname
      nickname = name;
    });
  }

  /// CLEAN EXPIRED / DEAD ROOMS
  Future<void> cleanUpDeadRooms() async {
    /// Show loading dialog
    //LoadingDialog.show(context, message: "Removing Expired Room");

    try {
      /// Firebase database reference
      final dbRef = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
            "https://tic-tac-toe-9c3bf-default-rtdb.asia-southeast1.firebasedatabase.app/",
      ).ref();

      /// Get all rooms
      final snapshot = await dbRef.child("rooms").get();

      if (snapshot.exists) {
        final rooms = Map<String, dynamic>.from(snapshot.value as Map);
        int currentTime = DateTime.now().millisecondsSinceEpoch;

        /// Check all rooms
        for (var entry in rooms.entries) {
          String roomCode = entry.key;
          Map<String, dynamic> roomData = Map<String, dynamic>.from(
            entry.value as Map,
          );

          /// Room created time
          int createdAt = roomData["createdAt"] as int? ?? currentTime;

          /// Room older than 1 hour
          bool isOlderThanOneHour = (currentTime - createdAt) > 3600000;
          final exitStatus = roomData["exitStatus"];
          final players = roomData["players"];

          /// Player exit status
          String p1Status = exitStatus?["player1"]?.toString() ?? "";
          String p2Status = exitStatus?["player2"]?.toString() ?? "";

          /// Check player2 exists
          bool p2Exists = players != null && players["player2"] != null;

          /// Room cleanup conditions
          bool bothExited = (p1Status == "exited" && p2Status == "exited");
          bool onlyP1Exited = (p1Status == "exited" && !p2Exists);

          /// Delete dead room
          if (isOlderThanOneHour || bothExited || onlyP1Exited) {
            await dbRef.child("rooms/$roomCode").remove();
            print(" Deleted dead room -> $roomCode");
          }
        }
      }
    } catch (e) {
      /// Cleanup error log
      print("Garbage Collector Error: $e");
    } finally {
      /// Always hide loading
      if (mounted) {
        //LoadingDialog.hide(context);
      }
    }
  }

  /// GENERATE RANDOM PLAYER NAME
  String generatePlayerName() {
    Random random = Random();
    int number = 100000 + random.nextInt(900000);

    /// Return 6 digit player name
    return "Player$number";
  }

  /// OPEN PROFILE DIALOG
  void openProfileDialog() async {
    final prefs = await SharedPreferences.getInstance();

    /// Load current nickname
    String currentName = prefs.getString("nickname") ?? "Player";
    TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return TweenAnimationBuilder(
              /// Dialog popup animation
              duration: const Duration(milliseconds: 450),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              curve: Curves.easeOutBack,

              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,

                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24),

                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,

                      children: [
                        /// Main profile card
                        Container(
                          margin: const EdgeInsets.only(top: 20),

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),

                            child: BackdropFilter(
                              /// Glass blur effect
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),

                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  60,
                                  20,
                                  20,
                                ),

                                decoration: BoxDecoration(
                                  /// Glass background gradient
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,

                                    colors: isDark
                                        ? [
                                            Colors.white.withValues(
                                              alpha: 0.14,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                          ]
                                        : [
                                            Colors.white.withValues(
                                              alpha: 0.35,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                          ],
                                  ),

                                  borderRadius: BorderRadius.circular(28),

                                  /// Border effect
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: isDark ? 0.18 : 0.35,
                                    ),
                                    width: 1.5,
                                  ),

                                  /// Glow & shadow
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withValues(
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
                                    /// Gaming avatar
                                    Container(
                                      width: 90,
                                      height: 90,

                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,

                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                                  Colors.blueAccent,
                                                  Colors.cyanAccent,
                                                ]
                                              : [
                                                  Colors.blue,
                                                  Colors.lightBlueAccent,
                                                ],
                                        ),

                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 2,
                                        ),

                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.cyanAccent.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 18,
                                          ),
                                        ],
                                      ),

                                      alignment: Alignment.center,

                                      /// Avatar first letter
                                      child: Text(
                                        controller.text.isNotEmpty
                                            ? controller.text[0].toUpperCase()
                                            : "",

                                        style: const TextStyle(
                                          fontSize: 34,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    /// Username input field
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),

                                        /// Field background color
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.7,
                                              ),

                                        /// Field border
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.15,
                                                )
                                              : Colors.blue.withValues(
                                                  alpha: 0.2,
                                                ),
                                        ),
                                      ),

                                      child: TextField(
                                        controller: controller,

                                        /// Update avatar letter live
                                        onChanged: (value) {
                                          setStateDialog(() {});
                                        },

                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),

                                        /// Placeholder text
                                        decoration: InputDecoration(
                                          hintText: "Enter username",

                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black45,
                                          ),

                                          /// User icon
                                          prefixIcon: Icon(
                                            Icons.person,
                                            color: isDark
                                                ? Colors.cyanAccent
                                                : Colors.blue,
                                          ),

                                          border: InputBorder.none,

                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 18,
                                              ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    /// Action buttons
                                    Row(
                                      children: [
                                        /// Exit button
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              /// Vibration feedback
                                              if (vibrationOn) {
                                                HapticFeedback.lightImpact();
                                              }

                                              /// Close dialog
                                              Navigator.pop(context);
                                            },

                                            child: buildGamingButton(
                                              text: "EXIT",

                                              backgroundColor: isDark
                                                  ? const Color(0xFF2A1A1A)
                                                  : Colors.redAccent,

                                              borderColor: isDark
                                                  ? Colors.redAccent
                                                  : Colors.white,

                                              textColor: Colors.white,

                                              loadingColor: Colors.white,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        /// Save profile button
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              /// Vibration feedback
                                              if (vibrationOn) {
                                                HapticFeedback.lightImpact();
                                              }

                                              /// Update profile data
                                              await updateProfile(
                                                context: context,
                                                prefs: prefs,
                                                controller: controller,

                                                /// Update nickname in UI
                                                onProfileUpdated: (newName) {
                                                  setState(() {
                                                    nickname = newName;
                                                  });
                                                },
                                              );
                                            },

                                            child: buildGamingButton(
                                              text: "SAVE",

                                              backgroundColor: isDark
                                                  ? const Color(0xFF162033)
                                                  : Colors.blue,

                                              borderColor: isDark
                                                  ? Colors.cyanAccent
                                                  : Colors.white,

                                              textColor: Colors.white,
                                              loadingColor: Colors.white,
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

                        /// Floating profile header
                        Positioned(
                          top: 0,

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 10,
                            ),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),

                              /// Header border
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.blue.withValues(alpha: 0.5),
                                width: 2,
                              ),

                              /// Header background
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF1E293B),
                                        const Color(0xFF1E293B),
                                      ]
                                    : [Colors.white, Colors.white],
                              ),

                              /// Glow effect
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.blue.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),

                            /// Header title
                            child: Text(
                              "PROFILE",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.blue,

                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// UPDATE PROFILE
  Future<void> updateProfile({
    required BuildContext context,
    required SharedPreferences prefs,
    required TextEditingController controller,
    required Function(String) onProfileUpdated,
  }) async {
    /// Get entered username
    String newName = controller.text.trim();

    /// Empty name validation
    if (newName.isEmpty) {
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter name")));

      return;
    }

    /// Save nickname locally
    await prefs.setString("nickname", newName);

    /// Update UI instantly
    onProfileUpdated(newName);

    /// Close dialog
    Navigator.pop(context);

    /// Success toast
    CustomToast.show(
      context: context,
      message: "Profile Updated!",
      isDark: isDark,
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );
  }

  /// DELETE ROOM
  Future<void> deleteRoom(String code) async {
    /// Invalid room check
    if (code.isEmpty) return;

    /// Internet connection check
    bool isConnected = await checkInternet();

    if (!isConnected) {
      CustomToast.show(
        context: context,
        message: "No Internet Connection",
        isDark: isDark,
        icon: Icons.wifi_off_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Show loading dialog
    LoadingDialog.show(context, message: "Closing room...");

    try {
      /// Stop all timers & animations
      timer?.cancel();
      dotTimer?.cancel();
      borderController?.stop();

      stopRoomHeartbeat();

      /// Delete room from Firebase
      await dbRef.child("rooms/$code").remove();

      print("Room deleted from Firebase");

      /// Reset room state
      if (mounted) {
        setState(() {
          isCodeGenerated = false;
          isPublicRoom = false;
          isButtonDisabled = false;
          roomCode = "XXXXXX";
          opponentJoined = false;
        });
      }

      /// Success toast
      CustomToast.show(
        context: context,
        message: "Room Closed!",
        isDark: isDark,
        icon: Icons.cancel_presentation_rounded,
        color: Colors.redAccent,
      );
    } catch (e) {
      /// Firebase error log
      print(" Firebase Error: $e");

      /// Failure toast
      CustomToast.show(
        context: context,
        message: "Failed to Close Room!",
        isDark: isDark,
        icon: Icons.error_outline_rounded,
        color: Colors.redAccent,
      );
    } finally {
      /// Hide loading dialog
      LoadingDialog.hide(context);
    }
  }

  /// LISTEN FOR OPPONENT JOIN
  void listenForOpponent(String code) {
    /// Cancel old listener
    roomListener?.cancel();

    hasHandledMatchAction = false;

    roomListener = dbRef.child("rooms/$code").onValue.listen((event) {
      /// Widget safety check
      if (!mounted) return;

      /// Prevent duplicate execution
      if (hasHandledMatchAction) return;

      /// Room deleted check
      if (!event.snapshot.exists) {
        return;
      }
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      /// Opponent joined room
      if (data["status"] == "joined") {
        if (!opponentJoined && startDialogContext == null) {
          setState(() {
            opponentJoined = true;
          });

          hasHandledMatchAction = false;
          startDialogContext = null;

          /// Vibration feedback
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }

          /// Show match start dialog
          showStartMatchDialog(code);
        }
      }

      /// Opponent cancelled room join
      if (data["cancelledBy"] == "player2") {
        //hasHandledMatchAction = true;

        /// Close active dialog
        if (startDialogContext != null) {
          final navigator = Navigator.of(
            startDialogContext!,
            rootNavigator: true,
          );
          if (navigator.canPop()) {
            navigator.pop();
          }
          startDialogContext = null;
        }
        setState(() {
          opponentJoined = false;
        });

        /// Cancelled toast
        CustomToast.show(
          context: context,
          message: "Opponent Cancelled!",
          isDark: isDark,
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
        );

        /// Remove Firebase cancel flag
        dbRef.child("rooms/$code/cancelledBy").remove();
        return;
      }
    });
  }

  /// START ONLINE MATCH
  Future<void> startMatch(String code) async {
    /// Stop internet listener
    await internetSubscription?.cancel();

    /// Mark page inactive
    isPageActive = false;

    /// Match start toast
    CustomToast.show(
      context: context,
      message: "Match Started!",
      isDark: isDark,
      icon: Icons.sports_esports_rounded,
      color: Colors.green,
    );

    /// Navigate to online game board
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayOnlineBoardPage(roomCode: code),
      ),
    );

    /// Stop heartbeat after match starts
    stopRoomHeartbeat();

    /// Reset room UI state
    setState(() {
      roomCode = "XXXXXX";
      isCodeGenerated = false;
      isPublicRoom = false;
      isButtonDisabled = false;
    });
  }

  /// VALIDATE ROOM CODE
  Future<void> validateRoomCode() async {
    /// Empty input check
    if (enteredCode.isEmpty) {
      CustomToast.show(
        context: context,
        message: "Please Enter Room Code!",
        isDark: isDark,
        icon: Icons.keyboard_alt_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Invalid code length check
    if (enteredCode.length < 6) {
      CustomToast.show(
        context: context,
        message: "Enter Valid 6-Digit Code!",
        isDark: isDark,
        icon: Icons.pin_outlined,
        color: Colors.orange,
      );
      return;
    }

    /// Internet connection check
    bool isConnected = await checkInternet();

    if (!isConnected) {
      CustomToast.show(
        context: context,
        message: "No Internet Connection",
        isDark: isDark,
        icon: Icons.wifi_off_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Join room after validation
    await smartJoinRoom(enteredCode);
  }

  /// SMART ROOM JOIN
  Future<void> smartJoinRoom(String code) async {
    hasCancelled = false;

    /// Invalid room code check
    if (code.isEmpty) {
      CustomToast.show(
        context: context,
        message: "Invalid Room!",
        isDark: isDark,
        icon: Icons.cancel_outlined,
        color: Colors.redAccent,
      );
      return;
    }

    /// Internet connection check
    bool isConnected = await checkInternet();
    if (!isConnected) {
      CustomToast.show(
        context: context,
        message: "No Internet Connection!️",
        isDark: isDark,
        icon: Icons.wifi_off_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Prevent joining while own room active
    if (isCodeGenerated && roomCode.isNotEmpty) {
      if (vibrationOn) {
        HapticFeedback.selectionClick();
      }
      await showCloseRoomBeforeJoinDialog();
      return;

      /// STOP — no auto join
    }

    /// Hide keyboard safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    try {
      /// Small delay before joining
      await Future.delayed(const Duration(milliseconds: 300));

      /// Start actual join process
      await _joinRoomInternal(code);
    } catch (e) {
      print("Smart join error: $e");

      /// Join failed toast
      CustomToast.show(
        context: context,
        message: "Failed to Join Room!",
        isDark: isDark,
        icon: Icons.error_outline_rounded,
        color: Colors.redAccent,
      );
    }
  }

  /// INTERNAL ROOM JOIN PROCESS
  Future<void> _joinRoomInternal(String code) async {
    /// Fetch room data
    final snapshot = await dbRef.child("rooms/$code").get();

    /// Room not found
    if (!snapshot.exists) {
      triggerError();

      if (vibrationOn) {
        HapticFeedback.lightImpact();
      }
      CustomToast.show(
        context: context,
        message: "Room Not Found!",
        isDark: isDark,
        icon: Icons.cancel_outlined,
        color: Colors.redAccent,
      );
      return;
    }

    final data = snapshot.value as Map?;

    /// Invalid room data
    if (data == null) {
      //showToast("Invalid room!");
      if (vibrationOn) {
        HapticFeedback.lightImpact();
      }
      CustomToast.show(
        context: context,
        message: "Invalid Room!",
        isDark: isDark,
        icon: Icons.cancel_outlined,
        color: Colors.redAccent,
      );
      return;
    }

    /// Get players data
    final players = data["players"] as Map?;
    final player1 = players?["player1"] as Map?;

    /// Invalid player data
    if (player1 == null) {
      if (vibrationOn) {
        HapticFeedback.lightImpact();
      }
      CustomToast.show(
        context: context,
        message: "Invalid room data!",
        isDark: isDark,
        icon: Icons.cancel_outlined,
        color: Colors.redAccent,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    /// Current user id
    String userId = prefs.getString("nickname") ?? "Player";

    String creatorId = player1["uid"] ?? "";

    /// Prevent self join
    if (creatorId == userId) {
      if (vibrationOn) {
        HapticFeedback.lightImpact();
      }
      CustomToast.show(
        context: context,
        message: "You can't join your own room!",
        isDark: isDark,
        icon: Icons.cancel_outlined,
        color: Colors.redAccent,
      );
      return;
    }

    /// Match already started check
    if (data["status"] == "playing") {
      if (vibrationOn) {
        HapticFeedback.lightImpact();
      }
      CustomToast.show(
        context: context,
        message: "Match already started!",
        isDark: isDark,
        icon: Icons.sports_esports_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Room full check
    if (players?["player2"] != null) {
      //showToast("Room already full!");
      if (vibrationOn) {
        HapticFeedback.lightImpact();
      }
      CustomToast.show(
        context: context,
        message: "Room already full!",
        isDark: isDark,
        icon: Icons.person_off_rounded,
        color: Colors.orange,
      );
      return;
    }

    /// Show loading dialog
    LoadingDialog.show(context, message: "Joining room...");
    //activeRoomCode = code;

    /// Add player2 in Firebase
    await dbRef.child("rooms/$code/players/player2").set({
      "uid": userId,
      "symbol": "X",
    });

    /// Update room status
    await dbRef.child("rooms/$code").update({
      "status": "joined",
      "currentTurn": "X",
    });

    /// Hide loading dialog
    LoadingDialog.hide(context);

    /// Show waiting dialog
    Future.delayed(Duration.zero, () {
      if (vibrationOn) {
        HapticFeedback.selectionClick();
      }
      showWaitingDialog(code);
    });

    /// Cancel old listener
    roomListener?.cancel();

    /// Listen room updates
    roomListener = dbRef.child("rooms/$code").onValue.listen((event) {
      /// Room deleted
      if (!event.snapshot.exists) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (mounted && navigator.canPop()) {
          navigator.pop();
        }

        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        CustomToast.show(
          context: context,
          message: "Room Deleted!",
          isDark: isDark,
          icon: Icons.delete_forever_rounded,
          color: Colors.redAccent,
        );
        roomListener?.cancel();
        return;
      }

      final data = event.snapshot.value as Map?;
      if (data == null) return;

      /// Opponent rejected join request
      if (data["rejectedBy"] == "player1") {
        setState(() {
          opponentJoined = false;
        });
        hideKeyboard();

        final navigator = Navigator.of(context, rootNavigator: true);
        if (mounted && navigator.canPop()) {
          navigator.pop();
        }

        Future.delayed(const Duration(milliseconds: 100), () {
          hideKeyboard();
        });

        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        CustomToast.show(
          context: context,
          message: "Opponent Rejected Request!",
          isDark: isDark,
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
        );

        /// Remove reject flag
        dbRef.child("rooms/$code/rejectedBy").remove();

        roomListener?.cancel();
        return;
      }

      /// Match started
      if (data["status"] == "playing") {
        /// Close waiting dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// Match started toast
        CustomToast.show(
          context: context,
          message: "Match Started!",
          isDark: isDark,
          icon: Icons.sports_esports_rounded,
          color: Colors.green,
        );

        setState(() {
          /// Reset join UI
          hiddenController.text = "";
          enteredCode = "";
          isButtonDisabled = false;
          roomCode = "XXXXXX";
        });

        /// Open online game board
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayOnlineBoardPage(roomCode: code),
          ),
        );

        roomListener?.cancel();
      }
    });
  }

  /// SHOW CLOSE ROOM DIALOG
  Future<void> showCloseRoomDialog() async {
    await showAppDialog(
      context: context,
      title: "Close Room",
      message: "Do you want to close this room?",
      positiveText: "CLOSE",
      negativeText: "NO",

      /// Show loader on positive button
      showLoadingOnPositive: true,

      /// Cancel action
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
      },

      /// Close room action
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await deleteRoom(roomCode);
        //if (mounted) Navigator.pop(context);
      },
    );
  }

  /// SHOW CLOSE ROOM BEFORE EXIT DIALOG
  Future<void> showCloseRoomBeforeExitDialog() async {
    await showAppDialog(
      context: context,
      title: "Close Room",
      message: "Please close room before exit.",
      positiveText: "CLOSE",
      negativeText: "WAIT",

      /// Prevent outside dismiss
      barrierDismissible: false,

      /// Show loading on button
      showLoadingOnPositive: true,

      /// Wait action
      //showContentLoading: false,
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
      },

      /// Close room & exit page
      onPositive: () async {
        await deleteRoom(roomCode);

        if (mounted) {
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }

          /// Exit current page
          Navigator.pop(context);
        }
      },
    );
  }

  /// SHOW CLOSE ROOM BEFORE PROFILE DIALOG
  Future<void> showCloseRoomBeforeOpenProfileDialog() async {
    await showAppDialog(
      context: context,
      title: "Close Room",
      message: "Please close room to open profile.",
      positiveText: "CLOSE",
      negativeText: "WAIT",

      /// Prevent outside dismiss
      barrierDismissible: false,

      /// Show loading on button
      showLoadingOnPositive: true,

      /// Wait action
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
      },

      /// Close room action
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await deleteRoom(roomCode);
      },
    );
  }

  /// SHOW CLOSE ROOM BEFORE JOIN DIALOG
  Future<void> showCloseRoomBeforeJoinDialog() async {
    await showAppDialog(
      context: context,
      title: "Close Room",
      message: "Please close your room to join another room!",

      positiveText: "CLOSE",
      negativeText: "NO",

      /// Prevent outside dismiss
      //showContentLoading: false,
      barrierDismissible: false,

      /// Show loading on positive button
      showLoadingOnPositive: true,

      /// Cancel action
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
      },

      /// Close room action
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await deleteRoom(roomCode);
      },
    );
  }

  /////////////////////////////////////////////////////////////////////////////
  /// SHOW WAITING FOR OPPONENT DIALOG
  Future<void> showWaitingDialog(String code) async {
    await showAppDialog(
      context: context,
      title: "Request Send",
      message: "Waiting for opponent responses...\nPlease stay connected.",
      positiveText: "",
      negativeText: "CANCEL",

      /// Prevent outside dismiss
      barrierDismissible: false,

      /// Show loading animation
      showContentLoading: true,

      /// Cancel join request
      onNegative: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }

        /// Show cancelling loader
        LoadingDialog.show(context, message: "Cancelling Request...");
        try {
          /// Remove player2 from room
          await dbRef.child("rooms/$code/players/player2").remove();

          /// Reset room state
          await dbRef.child("rooms/$code").update({
            "status": "waiting",
            "currentTurn": "",
            "cancelledBy": "player2",
          });

          /// Mark request cancelled
          hasCancelled = true;

          /// Stop room listener
          await roomListener?.cancel();
          roomListener = null;
        } catch (e) {
          /// Cancel error log
          print("Cancel error: $e");
        } finally {
          /// Hide loading dialog
          LoadingDialog.hide(context);
        }

        /// Cancel success toast
        CustomToast.show(
          context: context,
          message: "Request Cancelled!",
          isDark: isDark,
          icon: Icons.close_rounded,
          color: Colors.redAccent,
        );
      },
    );
  }

  /// SHOW START MATCH DIALOG
  Future<void> showStartMatchDialog(String code) async {
    await showAppDialog(
      context: context,

      /// Save dialog context
      onDialogCreated: (dialogContext) {
        startDialogContext = dialogContext;
      },
      title: "MATCH FOUND",
      message: "Someone joined your room.\nStart the match now.",
      positiveText: "START",
      negativeText: "REJECT",

      /// Prevent outside dismiss
      barrierDismissible: false,

      /// Show loading animation
      showContentLoading: true,

      /// Reject opponent request
      onNegative: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        startDialogContext = null;

        /// Show reject loader
        LoadingDialog.show(context, message: "Rejecting Request...");
        try {
          /// Remove player2 & reset room
          await dbRef.child("rooms/$code").update({
            "players/player2": null,
            "rejectedBy": "player1",
            "status": "waiting",
            "currentTurn": "",
          });
        } catch (e) {
          /// Firebase error log
          print("Firebase Error: $e");
        } finally {
          /// Hide loading dialog
          LoadingDialog.hide(context);
        }
        setState(() {
          opponentJoined = false;
        });

        /// Reject success toast
        CustomToast.show(
          context: context,
          message: "Request rejected!",
          isDark: isDark,
          icon: Icons.close_rounded,
          color: Colors.redAccent,
        );
      },

      /// Start online match
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        startDialogContext = null;
        try {
          /// Update room playing status
          await dbRef.child("rooms/$code").update({
            "status": "playing",
            "currentTurn": "X",
          });
        } catch (e) {
          /// Firebase error log
          print(" Firebase Error: $e");
        }

        /// Start match
        startMatch(code);
      },
    );
  }

  /// SHOW NO INTERNET DIALOG
  Future<void> showNoInternetDialog() async {
    await showAppDialog(
      context: context,

      /// Save dialog context
      onDialogCreated: (dialogContext) {
        noInternetDialogCtx = dialogContext;
      },
      title: "NO INTERNET",
      message: "Connection lost.\nWaiting for internet...",
      positiveText: "",
      negativeText: "EXIT",

      /// Prevent outside dismiss
      barrierDismissible: false,

      /// Show loading animation
      showContentLoading: true,

      /// Exit from online page
      onNegative: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await _exitFromNoInternet();
      },
    );

    /// Reset dialog states
    noInternetDialogCtx = null;
    isOfflineDialogShowing = false;
  }
} // end main class //////////////////////////////////////////

/// PRESSABLE 3D BUTTON
class Pressable3DButton extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onTap;

  const Pressable3DButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<Pressable3DButton> createState() => _Pressable3DButtonState();
}

class _Pressable3DButtonState extends State<Pressable3DButton> {
  /// Button press state
  bool isPressed = false;

  /// Handle press animation & tap
  void _handleTap() async {
    setState(() => isPressed = true);

    /// Small delay for animation
    await Future.delayed(const Duration(milliseconds: 120));

    setState(() => isPressed = false);

    /// Execute button action
    await widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// Tap action
      onTap: _handleTap,

      /// use onTap only
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),

        /// 3D press movement effect
        transform: Matrix4.translationValues(0, isPressed ? 4 : 0, 0),

        /// shadow change
        // decoration: BoxDecoration(
        //   // boxShadow: isPressed
        //   //     ? [
        //   //         BoxShadow(
        //   //           color: Colors.black.withOpacity(0.4),
        //   //           offset: const Offset(0, 0),
        //   //           blurRadius: 4,
        //   //         ),
        //   //       ]
        //   //     : [],
        // ),
        child: widget.child,
      ),
    );
  }
}

/// CUSTOM GLOW SLIDER THUMB
class GlowThumb extends SliderComponentShape {
  /// Theme mode
  final bool isDark;

  GlowThumb({required this.isDark});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    /// Thumb size
    return const Size(30, 30);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    /// Outer glow effect
    final Paint glowPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, 14, glowPaint);

    /// Main thumb circle
    final Paint thumbPaint = Paint()..color = Colors.blueAccent;

    canvas.drawCircle(center, 10, thumbPaint);
  }
}

/// CUSTOM GRADIENT SLIDER TRACK
class GradientTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required TextDirection textDirection,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 0,
    Offset? secondaryOffset,
  }) {
    final Canvas canvas = context.canvas;

    /// Slider track area
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    /// Active gradient track paint
    final Paint activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.blueAccent, Colors.purpleAccent],
      ).createShader(trackRect);

    /// Inactive track paint
    final Paint inactivePaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.2);

    /// Active track area
    final Rect leftTrack = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );

    /// Inactive track area
    final Rect rightTrack = Rect.fromLTRB(
      thumbCenter.dx,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    final Radius radius = const Radius.circular(10);

    /// Draw active track
    canvas.drawRRect(RRect.fromRectAndRadius(leftTrack, radius), activePaint);

    /// Draw inactive track
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightTrack, radius),
      inactivePaint,
    );
  }
}

/// ANIMATED BORDER PROGRESS PAINTER
class BorderProgressPainter extends CustomPainter {
  /// Progress value
  final double progress;

  /// Border color
  final Color color;

  /// Border radius
  final double radius;

  BorderProgressPainter(this.progress, this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final metric = path.computeMetrics().first;

    /// Background border paint
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      /// light shade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, bgPaint);

    /// Animated progress border paint
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final extractPath = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(extractPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant BorderProgressPainter oldDelegate) {
    /// Repaint when values change
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}
