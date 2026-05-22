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
  final String? initialCode;

  const PlayOnlineStartPage({Key? key, this.initialCode}) : super(key: key);

  @override
  State<PlayOnlineStartPage> createState() => PlayOnlineStartPageState();
}

class PlayOnlineStartPageState extends State<PlayOnlineStartPage>
    with TickerProviderStateMixin {
  static PlayOnlineStartPageState? instance;
  String nickname = "Player";
  bool isCreateSelected = true;
  bool isPublicRoom = false;
  String roomCode = "XXXXXX";
  String enteredCode = "";
  final FocusNode codeFocusNode = FocusNode();
  bool isCodeGenerated = false;
  bool isButtonDisabled = false;
  bool opponentJoined = false;

  /// HEARTBEAT TIMER
  Timer? roomHeartbeatTimer;
  int countdown = 300; // 5 min
  Timer? timer;
  late double progress = countdown / 300;
  bool isDark = true; // default dark
  bool vibrationOn = true;
  String? profileImagePath;
  BuildContext? startDialogContext;
  StreamSubscription? roomListener;
  bool isExiting = false;
  int selectedBoardSize = 3;
  final List<int> boardSizes = [3, 4, 5, 6, 7, 8, 9];

  String dots = "";
  Timer? dotTimer;

  StreamSubscription? internetSubscription;
  BuildContext? noInternetDialogCtx;
  bool isOfflineDialogShowing = false;

  List<Map> publicRooms = [];
  String currentUserId = "";
  bool hasCancelled = false;

  TextEditingController codeController = TextEditingController();
  TextEditingController hiddenController = TextEditingController();
  FocusNode hiddenFocus = FocusNode();

  BuildContext? waitingDialogContext;

  bool isError = false;
  bool isPageActive = true;
  bool hasHandledMatchAction = false;

  late AnimationController shakeController;
  late Animation<double> shakeAnimation;
  AnimationController? borderController;

  StreamSubscription? publicRoomListener;
  Timer? publicRoomRefreshTimer;
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        "https://tic-tac-toe-9c3bf-default-rtdb.asia-southeast1.firebasedatabase.app/",
  ).ref();

  @override
  void initState() {
    super.initState();
    instance = this;
    monitorInternet();
    loadBoardSize();
    loadProfileImage();
    loadUser();
    loadSettings();
    cleanUpDeadRooms();
    //startPublicRoomRefresh();
    Future.delayed(Duration.zero, () {
      checkUser(); // ADD THIS
    });

    borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 300),
    );

    borderController!.forward(); // start animation

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
      // 🔥 back to center
    ]).animate(CurvedAnimation(parent: shakeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    timer?.cancel();
    roomListener?.cancel();
    super.dispose();
    instance = null; // 🔥 ADD
    publicRoomListener?.cancel();
    dotTimer?.cancel();
    internetSubscription?.cancel();
    shakeController.dispose();
    borderController?.dispose();
    hasHandledMatchAction = true;
    publicRoomRefreshTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    //final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !isCodeGenerated,

      /// block back when code active
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

        backgroundColor: isDark
            ? const Color(0xFF0F172A) // dark background
            : const Color(0xFFF3F7FF),

        /// light background
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,

          /// FIX STATUS BAR ICON COLOR
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // transparent status bar
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark, // Android
            statusBarBrightness: isDark
                ? Brightness.dark
                : Brightness.light, // iOS
          ),

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ),

          /// 🔥 BLUR + GLASS EFFECT
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

          title: Text(
            "Play Online",
            style: TextStyle(
              color: isDark ? Colors.cyanAccent : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Tooltip(
              message: "Back",
              child: GestureDetector(
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
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: "Profile",
                child: GestureDetector(
                  onTap: () {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }

                    /// IF ROOM ACTIVE
                    if (isCodeGenerated) {
                      showCloseRoomBeforeOpenProfileDialog();
                    } else {
                      openProfileDialog();
                    }
                  },
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
            padding: EdgeInsets.fromLTRB(
              20,
              kToolbarHeight +
                  MediaQuery.of(context).padding.top +
                  10, // 🔥 FIX
              20,
              20,
            ),
            child: build3DCard(),
          ),
        ),
      ),
    );
  }

  Widget build3DCard() {
    return Column(
      children: [
        // EXISTING MAIN CARD
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF26344B) : const Color(0xFFE9E9EF),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              width: 1.5,
              color: isDark ? Color(0xFF122B57) : Colors.blue,
            ),
            boxShadow: [
              // Light shadow (top-left)
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.9),
                offset: const Offset(-6, -6),
                blurRadius: 12,
              ),

              // Dark shadow (bottom-right)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                offset: const Offset(6, 6),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            children: [
              /// CREATE / JOIN
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    /// CREATE
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }
                          setState(() => isCreateSelected = true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isCreateSelected
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),

                            /// subtle 3D shadow
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

                    /// JOIN
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }
                          setState(() => isCreateSelected = false);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isCreateSelected
                                ? Color(0xFF448BE5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),

                            /// subtle 3D shadow
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

              if (isCreateSelected) ...[
                const SizedBox(height: 10),

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

                    ///  Outer Glow
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
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),

                      ///  Inner Shadow (depth feel)
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
                        ///  Top Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Board Size",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),

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

                        ///  Your Premium Slider (same as before)
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

                            onChanged: (value) {
                              int newValue = value.toInt();

                              if (newValue != selectedBoardSize) {
                                if (vibrationOn) {
                                  HapticFeedback.selectionClick();
                                }
                              }

                              setState(() {
                                selectedBoardSize = newValue;
                              });

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

              /// INNER ROOM CARD
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),

                  /// GRADIENT BORDER
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.blueAccent],
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  margin: const EdgeInsets.all(1.5),

                  /// border thickness
                  decoration: BoxDecoration(
                    ///  Gradient Background (same feel, not too strong)
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF0F172A)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFCDEDF8), Color(0xFFCDEDF8)],
                          ),

                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),

                    ///  Glow Effect (NEW)
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(
                          alpha: isDark ? 0.4 : 0.3,
                        ),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),

                      /// keep your original shadow feel
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
                      ///  PUBLIC ROOM → SHOW LOTTIE
                      if (isCreateSelected &&
                          isCodeGenerated &&
                          isPublicRoom) ...[
                        //const SizedBox(height: 10),

                        ///  LOTTIE LOADING
                        SizedBox(
                          height: 100,
                          child: Lottie.asset(
                            "assets/lottie/sandy_loading.json",
                            repeat: true,
                          ),
                        ),
                      ]
                      /// PRIVATE ROOM → SHOW CODE
                      else if (isCreateSelected) ...[
                        Text(
                          "Your Room Code",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 5),

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
                      /// JOIN MODE
                      else ...[
                        Text(
                          "Enter Room Code",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 5),
                        buildCodeInput(),
                      ],

                      if (isCreateSelected && isCodeGenerated)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              ///  Expiry Time
                              Text(
                                "Your Room Code will expire in "
                                "${(countdown ~/ 60).toString().padLeft(2, '0')}:"
                                "${(countdown % 60).toString().padLeft(2, '0')} min",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              /// Blinking dots text
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

              if (isCreateSelected && !isCodeGenerated)
                Pressable3DButton(
                  onTap: () async {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }
                    if (isButtonDisabled) return;
                    bool isConnected = await checkInternet();

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

              /// CREATE MODE BUTTONS
              if (isCreateSelected && isCodeGenerated) ...[
                Row(
                  children: [
                    // COPY
                    Expanded(
                      child: Pressable3DButton(
                        onTap: () async {
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }
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

                    /// SHARE
                    Expanded(
                      child: Pressable3DButton(
                        onTap: () async {
                          HapticFeedback.lightImpact();
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

              /// JOIN MODE BUTTONS
              if (!isCreateSelected) ...[
                Row(
                  children: [
                    // PASTE
                    Expanded(
                      child: Pressable3DButton(
                        onTap: () async {
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }
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

                    /// PLAY
                    Expanded(
                      child: Pressable3DButton(
                        onTap: () async {
                          /// STEP 1: FORCE HIDE KEYBOARD
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (vibrationOn) {
                            HapticFeedback.lightImpact();
                          }
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          /// STEP 2: validation
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

              if (isCreateSelected && isCodeGenerated) ...[
                const SizedBox(height: 10),
                Pressable3DButton(
                  onTap: () async {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }
                    FocusScope.of(context).unfocus();
                    await showCloseRoomDialog();
                  },

                  child: Stack(
                    children: [
                      /// MAIN BUTTON
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
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
                            Icon(
                              Icons.close,
                              color: isDark ? Colors.redAccent : Colors.red,
                            ),
                            const SizedBox(width: 8),
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

                      ///  PROGRESS BORDER
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BorderProgressPainter(
                            countdown / 300,
                            Colors.red,
                            20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (isCreateSelected && !isCodeGenerated) ...[
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
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
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),

                const SizedBox(height: 10),
              ],

              /// RANDOM MATCH BUTTON (only CREATE mode)
              if (isCreateSelected && !isCodeGenerated) ...[
                Pressable3DButton(
                  onTap: () async {
                    if (vibrationOn) {
                      HapticFeedback.lightImpact();
                    }
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

        buildAvailableRoomsCard(),
      ],
    );
  }

  Widget buildAvailableRoomsCard() {
    //final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26344B) : const Color(0xFFE9E9EF),
        borderRadius: BorderRadius.circular(25),

        /// Add Border
        border: Border.all(
          width: 1.5,
          color: isDark ? Color(0xFF122B57) : Colors.blue,
        ),

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
          Center(
            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.only(bottom: 0),

              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(23.5),
                  topRight: Radius.circular(23.5),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                color: isDark ? Color(0xFF122B57) : Colors.white70,

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
                  Text(
                    "Available Rooms",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
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
              : SizedBox(
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: publicRooms.length,
                    itemBuilder: (context, index) {
                      final room = publicRooms[index];

                      return KeyedSubtree(
                        key: ValueKey(room["code"]),
                        child: buildRoomItem(room),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget buildRoomItem(Map room) {
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

    String name = room["name"] ?? "Player";
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "P";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      /// OUTER GRADIENT BORDER
      padding: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.blueAccent],
        ),

        /// glow
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

          ///  YOUR ORIGINAL GRADIENT (unchanged)
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                ),

          ///  keep shadows
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
            /// LEFT SIDE (Avatar + Name + Board)
            Expanded(
              child: Row(
                children: [
                  /// AVATAR
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

                  /// NAME + BOARD SIZE (same row)
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
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

                              ///  AUTO MARQUEE ONLY IF OVERFLOW
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

                              /// NORMAL TEXT
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

                        /// BOARD SIZE (FIXED POSITION)
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

            isMyRoom
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
                : GestureDetector(
                    onTap: () async {
                      await smartJoinRoom(room["code"]);
                    },

                    child: Stack(
                      children: [
                        /// MAIN BUTTON
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

                        ///  TIMER BORDER
                        Positioned.fill(
                          child: CustomPaint(
                            painter: BorderProgressPainter(
                              remainingProgress,
                              Colors.cyanAccent,
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

  Widget buildCodeInput() {
    //final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        ///REAL TEXTFIELD (NOT hidden)
        TextField(
          controller: hiddenController,
          focusNode: hiddenFocus,
          maxLength: 6,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,

          style: const TextStyle(
            color: Colors.transparent, // 🔥 hide text
          ),

          cursorColor: Colors.transparent,

          /// hide cursor
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
          ),

          onChanged: (value) {
            String filtered = value.toUpperCase().replaceAll(
              RegExp(r'[^A-Z0-9]'),
              '',
            );

            if (filtered.length > 6) {
              filtered = filtered.substring(0, 6);
            }

            setState(() {
              enteredCode = filtered;
              hiddenController.text = filtered;
              hiddenController.selection = TextSelection.fromPosition(
                TextPosition(offset: filtered.length),
              );
            });

            if (filtered.length == 6) {
              FocusScope.of(context).unfocus();
            }
          },
        ),

        /// UI BOXES (overlay)
        IgnorePointer(
          /// IMPORTANT
          child: AnimatedBuilder(
            animation: shakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(shakeAnimation.value, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
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

                    border: Border.all(
                      color: isError
                          ? Colors.red
                          /// ERROR COLOR
                          : (isActive
                                ? Colors.blue
                                : (isDark ? Colors.white24 : Colors.black12)),
                      width: isError ? 2 : (isActive ? 2 : 1),
                    ),
                  ),

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

  Future<void> loadBoardSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedBoardSize = prefs.getInt("board_size") ?? 3;
    });
  }

  Future<void> saveBoardSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("board_size", size);
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString("nickname") ?? "Player";
    });
    listenPublicRooms();
  }

  Future loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
    });
  }

  void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void triggerError() async {
    /// vibration
    HapticFeedback.mediumImpact();

    setState(() {
      isError = true;
    });

    await shakeController.forward(from: 0);

    /// reset perfectly
    shakeController.reset();

    setState(() {
      isError = false;
    });
  }

  void loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      profileImagePath = prefs.getString("profile_image");
    });
  }

  Future<void> handleBackPress() async {
    if (isExiting) return;
    isExiting = true;

    try {
      if (!isCodeGenerated) {
        //Navigator.pop(context);
        Navigator.of(context, rootNavigator: true).pop();
        return;
      }
      if (vibrationOn) {
        HapticFeedback.selectionClick();
      }
      await showCloseRoomBeforeExitDialog();
    } finally {
      isExiting = false;
    }
  }

  ///  START ROOM HEARTBEAT
  void startRoomHeartbeat(String roomCode) {
    ///  STOP OLD TIMER
    roomHeartbeatTimer?.cancel();

    roomHeartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        await dbRef
            .child("rooms/$roomCode/heartbeat/player1")
            .set(DateTime.now().millisecondsSinceEpoch);
      } catch (e) {
        print("Heartbeat Error: $e");
      }
    });
  }

  ///  STOP HEARTBEAT
  void stopRoomHeartbeat() {
    if (roomHeartbeatTimer?.isActive ?? false) {
      roomHeartbeatTimer?.cancel();
      print(" Room heartbeat stopped");
    }
  }

  void updatePublicRooms(dynamic data) {
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
      if (value["roomType"] == "public" && value["status"] == "waiting") {
        final heartbeatData = value["heartbeat"];
        int heartbeat = 0;
        if (heartbeatData != null && heartbeatData["player1"] != null) {
          heartbeat = heartbeatData["player1"];
        }

        ///  HEARTBEAT EXPIRED
        if (heartbeat > 0) {
          bool isAlive = (currentTime - heartbeat) <= 30000;
          if (!isAlive) return;
        }

        temp.add({
          "code": key,
          "name": value["players"]["player1"]["uid"] ?? "Player",
          "boardSize": value["boardSize"] ?? 3,
          "creatorId": value["creatorId"],
          "createdAt": value["createdAt"] ?? 0,

          ///  SAVE HEARTBEAT
          "heartbeat": heartbeat,
        });
      }
    });

    temp = temp.reversed.toList();
    if (!mounted) return;
    setState(() {
      publicRooms = temp;
    });
  }

  ///new listenPublicRooms
  void listenPublicRooms() {
    publicRoomListener?.cancel();
    publicRoomListener = dbRef.child("rooms").onValue.listen((event) {
      if (!mounted) return;
      updatePublicRooms(event.snapshot.value);
    });
  }

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

  void monitorInternet() {
    /// 1. Page open hote hi check
    checkInternet().then((hasInternet) {
      _updateInternetState(hasInternet);
    });

    /// 2. Mobile realtime listener
    internetSubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      bool hasInternet = await checkInternet();
      _updateInternetState(hasInternet);
    });

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

  void _updateInternetState(bool hasInternet) {
    ///  PAGE NOT ACTIVE
    if (!isPageActive) return;
    if (!mounted) return;

    if (!hasInternet) {
      /// show dialog
      if (!isOfflineDialogShowing) {
        isOfflineDialogShowing = true;

        Future.delayed(Duration.zero, () {
          if (mounted) {
            if (vibrationOn) {
              HapticFeedback.vibrate();
            }
            showNoInternetDialog();
          }
        });
      }
    } else {
      /// close dialog
      if (isOfflineDialogShowing && noInternetDialogCtx != null) {
        //Navigator.of(noInternetDialogCtx!).pop();
        Navigator.of(noInternetDialogCtx!, rootNavigator: true).pop();
        noInternetDialogCtx = null;
        isOfflineDialogShowing = false;
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }

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

  ///new
  Future<void> _exitFromNoInternet() async {
    ///  STOP ROOM HEARTBEAT
    stopRoomHeartbeat();

    ///  RESET FLAGS
    noInternetDialogCtx = null;
    isOfflineDialogShowing = false;

    ///  EXIT PAGE ONLY
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> generateCode() async {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random random = Random();
    String newCode = List.generate(6, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();

    setState(() {
      roomCode = newCode;
      isPublicRoom = false;
      isCodeGenerated = true;
      isButtonDisabled = true;
      opponentJoined = false;
      countdown = 300;
    });

    startTimer();
    startDotAnimation();
    borderController?.reset();
    borderController?.forward();
    print(" Generating Code...");
    await createPrivateRoomInFirebase(newCode); //  FIX
    print("✅ Done");
  }

  ///new PublicRoom
  Future<void> createPublicRoomInFirebase() async {
    /// already room check
    if (isCodeGenerated) {
      //showToast("Room already created!");
      CustomToast.show(
        context: context,
        message: "Room Already Created!",
        isDark: isDark,
        //icon: Icons.meeting_room_rounded,
        color: Colors.orange,
      );
      return;
    }
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

    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random random = Random();
    String newCode = List.generate(6, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();

    setState(() {
      roomCode = newCode;
      isCodeGenerated = true;
      isButtonDisabled = true;
      opponentJoined = false;
      countdown = 300;
      isPublicRoom = true;
    });
    startTimer();
    startDotAnimation();
    borderController?.reset();
    borderController?.forward();
    LoadingDialog.show(context, message: "Creating Room...");

    try {
      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString("nickname") ?? "Player";

      /// CURRENT TIME
      int now = DateTime.now().millisecondsSinceEpoch;
      await dbRef.child("rooms/$newCode").set({
        "matchStarted": false,
        "roomCode": newCode,
        "creatorId": userId,
        "createdAt": now,
        "status": "waiting",

        /// PUBLIC ROOM
        "roomType": "public",
        "boardSize": selectedBoardSize,
        "players": {
          "player1": {"uid": userId, "symbol": "O"},
        },

        /// HEARTBEAT
        "heartbeat": {"player1": now},
        "exitStatus": {"player1": "online", "player2": "online"},
        "currentTurn": "",
        "board": List.filled(selectedBoardSize * selectedBoardSize, ""),
        "winner": "",
      });

      ///  START HEARTBEAT
      startRoomHeartbeat(newCode);
      listenForOpponent(newCode);

      CustomToast.show(
        context: context,
        message: "Finding Opponent...",
        isDark: isDark,
        icon: Icons.search_rounded,
        color: Colors.blueAccent,
      );
    } catch (e) {
      print("❌ Firebase ERROR: $e");
    } finally {
      LoadingDialog.hide(context);
    }
  }

  Future<void> createPrivateRoomInFirebase(String code) async {
    LoadingDialog.show(context, message: "Creating room...");

    try {
      print(" createRoomInFirebase start");

      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString("nickname") ?? "Player";

      await dbRef.child("rooms/$code").set({
        "roomCode": code,
        "creatorId": userId,
        "createdAt": DateTime.now().millisecondsSinceEpoch,
        "status": "waiting",
        "matchStarted": false,
        "roomType": "private",
        "boardSize": selectedBoardSize,
        "players": {
          "player1": {"uid": userId, "symbol": "O"},
        },
        "exitStatus": {"player1": "online", "player2": "online"},
        "currentTurn": "",
        "board": List.filled(selectedBoardSize * selectedBoardSize, ""),
        "winner": "",
      });

      print("✅ Room created");
      listenForOpponent(code);
    } catch (e) {
      print("❌ Firebase ERROR: $e");
    } finally {
      LoadingDialog.hide(context);
    }
  }

  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      /// PAUSE when opponent joined (DON'T cancel)
      if (opponentJoined) {
        return;
      }

      if (countdown == 0) {
        t.cancel();

        if (!opponentJoined) {
          deleteRoom(roomCode);
        }

        setState(() {
          roomCode = "XXXXXX";
          isCodeGenerated = false;
          isButtonDisabled = false;
        });

        CustomToast.show(
          context: context,
          message: "Room Expired!",
          isDark: isDark,
          icon: Icons.timer_off_rounded,
          color: Colors.redAccent,
        );
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  void startDotAnimation() {
    dotTimer?.cancel();

    dotTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      setState(() {
        if (dots.length >= 3) {
          dots = "";
        } else {
          dots += ".";
        }
      });
    });
  }

  Future<void> handleCopyRoomCode() async {
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
    await Clipboard.setData(ClipboardData(text: roomCode));
    CustomToast.show(
      context: context,
      message: "Room Code Copied.",
      isDark: isDark,
      icon: Icons.copy_rounded,
      color: Colors.green,
    );
  }

  Future<void> handlePasteRoomCode() async {
    final data = await Clipboard.getData('text/plain');

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

    String pasted = data.text!.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );

    if (pasted.length > 6) {
      pasted = pasted.substring(0, 6);
    }
    setState(() {
      enteredCode = pasted;
      hiddenController.text = pasted;
    });

    CustomToast.show(
      context: context,
      message: "Code Pasted!",
      isDark: isDark,
      icon: Icons.content_paste_rounded,
      color: Colors.green,
    );
  }

  ////////////////////////////////////////////////////////////////////////

  Future<void> handleShareRoomCode() async {
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

    String link = generateInviteLink();
    DateTime now = DateTime.now();
    DateTime expiry = now.add(const Duration(minutes: 5));

    String formattedTime =
        "${expiry.hour.toString().padLeft(2, '0')}:"
        "${expiry.minute.toString().padLeft(2, '0')}";

    await SharePlus.instance.share(
      ShareParams(
        text:
            "🎮 Join my TicTacToe match!\n"
            "Room Code: $roomCode\n"
            "Click here to join instantly:\n$link \n"
            "Expires at: $formattedTime",
      ),
    );
  }

  String generateInviteLink() {
    return "https://tic-tac-toe-9c3bf.web.app/join?code=$roomCode";
  }

  Future<void> handleDeepLinkJoin(String code) async {
    print(" AUTO JOIN: $code");
    if (isCodeGenerated && roomCode.isNotEmpty) {
      await deleteRoom(roomCode);
    }

    enteredCode = code;
    hiddenController.text = code;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 200));
    await smartJoinRoom(code);

    /// MAIN JOIN
  }

  void handleIncomingLink(Uri uri) {
    if (uri.path.contains("join")) {
      String? code = uri.queryParameters['code'];

      if (code != null && code.isNotEmpty) {
        print(" Deep link received: $code");

        Future.delayed(const Duration(milliseconds: 100), () {
          /// CASE 1: Already on Start Page
          if (PlayOnlineStartPageState.instance != null) {
            PlayOnlineStartPageState.instance!.handleDeepLinkJoin(code);
          } else {
            /// CASE 2: Open Start Page
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => PlayOnlineStartPage(initialCode: code),
                settings: const RouteSettings(name: "/playOnline"),
              ),
              (route) => false,
            );
          }
        });
      }
    }
  }

  Future<void> checkUser() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString("nickname") ?? "";
    if (name.isEmpty) {
      name = generatePlayerName();
      await prefs.setString("nickname", name);
    }
    if (!mounted) return;
    setState(() {
      nickname = name;
    });
  }

  ///new cleanUp
  Future<void> cleanUpDeadRooms() async {
    LoadingDialog.show(context, message: "Removing Expired Room");

    try {
      final dbRef = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
            "https://tic-tac-toe-9c3bf-default-rtdb.asia-southeast1.firebasedatabase.app/",
      ).ref();

      final snapshot = await dbRef.child("rooms").get();

      if (snapshot.exists) {
        final rooms = Map<String, dynamic>.from(snapshot.value as Map);
        int currentTime = DateTime.now().millisecondsSinceEpoch;
        for (var entry in rooms.entries) {
          String roomCode = entry.key;
          Map<String, dynamic> roomData = Map<String, dynamic>.from(
            entry.value as Map,
          );
          int createdAt = roomData["createdAt"] as int? ?? currentTime;
          bool isOlderThanOneHour = (currentTime - createdAt) > 3600000;
          final exitStatus = roomData["exitStatus"];
          final players = roomData["players"];
          String p1Status = exitStatus?["player1"]?.toString() ?? "";
          String p2Status = exitStatus?["player2"]?.toString() ?? "";
          bool p2Exists = players != null && players["player2"] != null;
          bool bothExited = (p1Status == "exited" && p2Status == "exited");
          bool onlyP1Exited = (p1Status == "exited" && !p2Exists);
          if (isOlderThanOneHour || bothExited || onlyP1Exited) {
            await dbRef.child("rooms/$roomCode").remove();
            print(" Deleted dead room -> $roomCode");
          }
        }
      }
    } catch (e) {
      print("Garbage Collector Error: $e");
    } finally {
      /// ALWAYS CLOSE LOADING
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }
  }

  String generatePlayerName() {
    Random random = Random();
    int number = 100000 + random.nextInt(900000);

    /// 6 digit
    return "Player$number";
  }

  void openProfileDialog() async {
    final prefs = await SharedPreferences.getInstance();
    String currentName = prefs.getString("nickname") ?? "Player";
    TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return TweenAnimationBuilder(
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
                        /// MAIN CARD
                        Container(
                          margin: const EdgeInsets.only(top: 20),

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),

                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),

                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  60,
                                  20,
                                  20,
                                ),

                                decoration: BoxDecoration(
                                  /// GLASS BG
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

                                  /// BORDER
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: isDark ? 0.18 : 0.35,
                                    ),
                                    width: 1.5,
                                  ),

                                  /// SHADOW
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
                                    /// GAMING AVATAR
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

                                    /// USERNAME FIELD
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),

                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.7,
                                              ),

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

                                        onChanged: (value) {
                                          setStateDialog(() {});
                                        },

                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),

                                        decoration: InputDecoration(
                                          hintText: "Enter username",

                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black45,
                                          ),

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

                                    /// BUTTONS
                                    Row(
                                      children: [
                                        /// EXIT
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (vibrationOn) {
                                                HapticFeedback.lightImpact();
                                              }
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

                                        /// SAVE
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (vibrationOn) {
                                                HapticFeedback.lightImpact();
                                              }
                                              await updateProfile(
                                                context: context,
                                                prefs: prefs,
                                                controller: controller,

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

                        /// FLOATING HEADER
                        Positioned(
                          top: 0,

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 10,
                            ),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),

                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.blue.withValues(alpha: 0.5),
                                width: 2,
                              ),

                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF1E293B),
                                        const Color(0xFF1E293B),
                                      ]
                                    : [Colors.white, Colors.white],
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.blue.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),

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

  Future<void> updateProfile({
    required BuildContext context,
    required SharedPreferences prefs,
    required TextEditingController controller,
    required Function(String) onProfileUpdated,
  }) async {
    String newName = controller.text.trim();

    /// EMPTY CHECK
    if (newName.isEmpty) {
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter name")));

      return;
    }

    /// SAVE
    await prefs.setString("nickname", newName);

    /// UPDATE UI
    onProfileUpdated(newName);

    /// CLOSE DIALOG
    Navigator.pop(context);

    CustomToast.show(
      context: context,
      message: "Profile Updated!",
      isDark: isDark,
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );
  }

  Future<void> deleteRoom(String code) async {
    if (code.isEmpty) return;

    /// Internet check
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

    /// Loading
    LoadingDialog.show(context, message: "Closing room...");

    try {
      /// stop timers
      timer?.cancel();
      dotTimer?.cancel();
      borderController?.stop();

      stopRoomHeartbeat();

      ///delete from Firebase
      await dbRef.child("rooms/$code").remove();

      print("✅ Room deleted from Firebase");

      /// reset state
      if (mounted) {
        setState(() {
          isCodeGenerated = false;
          isPublicRoom = false;
          isButtonDisabled = false;
          roomCode = "XXXXXX";
          opponentJoined = false;
        });
      }

      //showToast("Room closed!");
      CustomToast.show(
        context: context,
        message: "Room Closed!",
        isDark: isDark,
        icon: Icons.cancel_presentation_rounded,
        color: Colors.redAccent,
      );
    } catch (e) {
      print(" Firebase Error: $e");
      // showToast("Failed to close room!");
      CustomToast.show(
        context: context,
        message: "Failed to Close Room!",
        isDark: isDark,
        icon: Icons.error_outline_rounded,
        color: Colors.redAccent,
      );
    } finally {
      LoadingDialog.hide(context);
    }
  }

  ///new
  void listenForOpponent(String code) {
    roomListener?.cancel();

    hasHandledMatchAction = false;

    roomListener = dbRef.child("rooms/$code").onValue.listen((event) {
      ///  SAFETY
      if (!mounted) return;

      ///  PREVENT MULTIPLE FIRE
      if (hasHandledMatchAction) return;

      ///  ROOM DELETED
      if (!event.snapshot.exists) {
        return;
      }
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      ///  OPPONENT JOINED
      if (data["status"] == "joined") {
        if (!opponentJoined && startDialogContext == null) {
          setState(() {
            opponentJoined = true;
          });

          hasHandledMatchAction = false;
          startDialogContext = null;
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }
          showStartMatchDialog(code);
        }
      }

      ///  OPPONENT CANCELLED
      if (data["cancelledBy"] == "player2") {
        //hasHandledMatchAction = true;

        ///  CLOSE ONLY DIALOG
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

        CustomToast.show(
          context: context,
          message: "Opponent Cancelled!",
          isDark: isDark,
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
        );

        ///  REMOVE FIREBASE FLAG
        dbRef.child("rooms/$code/cancelledBy").remove();
        return;
      }
    });
  }

  Future<void> startMatch(String code) async {
    ///  STOP OLD INTERNET LISTENER
    await internetSubscription?.cancel();

    ///  PAGE NO LONGER ACTIVE
    isPageActive = false;
    //showToast("Match Started!");
    CustomToast.show(
      context: context,
      message: "Match Started!",
      isDark: isDark,
      icon: Icons.sports_esports_rounded,
      color: Colors.green,
    );

    /// Navigate to game screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayOnlineBoardPage(roomCode: code),
      ),
    );

    stopRoomHeartbeat();

    /// UI reset (optional)
    setState(() {
      roomCode = "XXXXXX";
      isCodeGenerated = false;
      isPublicRoom = false;
      isButtonDisabled = false;
    });
  }

  Future<void> validateRoomCode() async {
    /// Input check
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

    ///Internet check
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

    /// All good → call main function
    await smartJoinRoom(enteredCode);
  }

  Future<void> smartJoinRoom(String code) async {
    hasCancelled = false;

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

    //  Internet check
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

    /// IMPORTANT: stop here if already has room
    if (isCodeGenerated && roomCode.isNotEmpty) {
      if (vibrationOn) {
        HapticFeedback.selectionClick();
      }
      await showCloseRoomBeforeJoinDialog();
      return;

      /// STOP — no auto join
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    try {
      /// IMPORTANT delay
      await Future.delayed(const Duration(milliseconds: 300));
      //}

      /// STEP 2: join new room
      await _joinRoomInternal(code);
    } catch (e) {
      print("Smart join error: $e");
      CustomToast.show(
        context: context,
        message: "Failed to Join Room!",
        isDark: isDark,
        icon: Icons.error_outline_rounded,
        color: Colors.redAccent,
      );
    }
  }

  Future<void> _joinRoomInternal(String code) async {
    final snapshot = await dbRef.child("rooms/$code").get();

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

    final players = data["players"] as Map?;
    final player1 = players?["player1"] as Map?;

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
    String userId = prefs.getString("nickname") ?? "Player";

    String creatorId = player1["uid"] ?? "";

    /// self join
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

    /// already playing
    if (data["status"] == "playing") {
      //showToast("Match already started!");
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

    /// room full
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

    LoadingDialog.show(context, message: "Joining room...");
    //activeRoomCode = code;

    /// SAFE JOIN (atomic style)
    await dbRef.child("rooms/$code/players/player2").set({
      "uid": userId,
      "symbol": "X",
    });

    await dbRef.child("rooms/$code").update({
      "status": "joined",
      "currentTurn": "X",
    });

    /// CLOSE LOADING FIRST
    LoadingDialog.hide(context);

    /// WAIT UI
    Future.delayed(Duration.zero, () {
      if (vibrationOn) {
        HapticFeedback.selectionClick();
      }
      showWaitingDialog(code);
    });

    roomListener?.cancel();

    roomListener = dbRef.child("rooms/$code").onValue.listen((event) {
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

      ///ADD HERE (VERY IMPORTANT POSITION)
      if (data["rejectedBy"] == "player1") {
        /// IMPORTANT: resume timer
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

        /// cleanup
        dbRef.child("rooms/$code/rejectedBy").remove();

        roomListener?.cancel(); // 🔥 stop listener
        return;
      }

      if (data["status"] == "playing") {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        //showToast("Match Started!");
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        CustomToast.show(
          context: context,
          message: "Match Started!",
          isDark: isDark,
          icon: Icons.sports_esports_rounded,
          color: Colors.green,
        );

        setState(() {
          hiddenController.text = "";
          enteredCode = "";
          isButtonDisabled = false;
          roomCode = "XXXXXX";
        });

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

  Future<void> showCloseRoomDialog() async {
    await showAppDialog(
      context: context,
      title: "Close Room",
      message: "Do you want to close this room?",
      positiveText: "CLOSE",
      negativeText: "NO",
      showLoadingOnPositive: true,
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
      },

      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await deleteRoom(roomCode);
        //if (mounted) Navigator.pop(context);
      },
    );
  }

  Future<void> showCloseRoomBeforeExitDialog() async {
    await showAppDialog(
      context: context,
      title: "Close Room",
      message: "Please close room before exit.",
      positiveText: "CLOSE",
      negativeText: "WAIT",
      barrierDismissible: false,

      /// always false
      showLoadingOnPositive: true,

      /// loader
      //showContentLoading: false,
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
      },
      onPositive: () async {
        await deleteRoom(roomCode); // 🔥 full logic

        if (mounted) {
          if (vibrationOn) {
            HapticFeedback.lightImpact();
          }
          Navigator.pop(context); // 🔥 exit page
        }
      },
    );
  }

  Future<void> showCloseRoomBeforeOpenProfileDialog() async {
    await showAppDialog(
      context: context,
      title: "Close Room",
      message: "Please close room to open profile.",
      positiveText: "CLOSE",
      negativeText: "WAIT",
      barrierDismissible: false,
      showLoadingOnPositive: true,

      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
      },
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await deleteRoom(roomCode);
      },
    );
  }

  Future<void> showCloseRoomBeforeJoinDialog() async {
    await showAppDialog(
      context: context,
      title: "Close Room",
      message: "Please close your room to join another room!",

      positiveText: "CLOSE",
      negativeText: "NO",

      //showContentLoading: false,
      barrierDismissible: false,

      /// always false
      showLoadingOnPositive: true,

      /// loader button me
      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
      },
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await deleteRoom(roomCode);
      },
    );
  }

  /////////////////////////////////////////////////////////////////////////////

  Future<void> showWaitingDialog(String code) async {
    await showAppDialog(
      context: context,
      title: "Request Send",
      message: "Waiting for opponent responses...\nPlease stay connected.",
      positiveText: "",
      negativeText: "CANCEL",
      barrierDismissible: false,
      showContentLoading: true,
      onNegative: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        LoadingDialog.show(context, message: "Cancelling Request...");
        try {
          await dbRef.child("rooms/$code/players/player2").remove();
          await dbRef.child("rooms/$code").update({
            "status": "waiting",
            "currentTurn": "",
            "cancelledBy": "player2",
          });

          /// IMPORTANT
          hasCancelled = true;

          /// STOP OLD LISTENER
          await roomListener?.cancel();
          roomListener = null;
        } catch (e) {
          print("Cancel error: $e");
        } finally {
          LoadingDialog.hide(context);
        }

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

  Future<void> showStartMatchDialog(String code) async {
    await showAppDialog(
      context: context,

      /// SAVE DIALOG CONTEXT
      onDialogCreated: (dialogContext) {
        startDialogContext = dialogContext;
      },
      title: "MATCH FOUND",
      message: "Someone joined your room.\nStart the match now.",
      positiveText: "START",
      negativeText: "REJECT",
      barrierDismissible: false,
      showContentLoading: true,

      /// REJECT
      onNegative: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        startDialogContext = null;
        LoadingDialog.show(context, message: "Rejecting Request...");
        try {
          await dbRef.child("rooms/$code").update({
            "players/player2": null,
            "rejectedBy": "player1",
            "status": "waiting",
            "currentTurn": "",
          });
        } catch (e) {
          print("🔥 Firebase Error: $e");
        } finally {
          LoadingDialog.hide(context);
        }
        setState(() {
          opponentJoined = false;
        });

        CustomToast.show(
          context: context,
          message: "Request rejected!",
          isDark: isDark,
          icon: Icons.close_rounded,
          color: Colors.redAccent,
        );
      },

      /// START MATCH
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        startDialogContext = null;
        try {
          await dbRef.child("rooms/$code").update({
            "status": "playing",
            "currentTurn": "X",
          });
        } catch (e) {
          print(" Firebase Error: $e");
        }

        startMatch(code);
      },
    );
  }

  ///new
  Future<void> showNoInternetDialog() async {
    await showAppDialog(
      context: context,

      /// SAVE DIALOG CONTEXT
      onDialogCreated: (dialogContext) {
        noInternetDialogCtx = dialogContext;
      },
      title: "NO INTERNET",
      message: "Connection lost.\nWaiting for internet...",
      positiveText: "",
      negativeText: "EXIT",
      barrierDismissible: false,
      showContentLoading: true,

      ///  EXIT
      onNegative: () async {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        await _exitFromNoInternet();
      },
    );

    /// RESET
    noInternetDialogCtx = null;
    isOfflineDialogShowing = false;
  }
} // end main class //////////////////////////////////////////

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
  bool isPressed = false;

  void _handleTap() async {
    setState(() => isPressed = true);

    /// small delay so animation visible
    await Future.delayed(const Duration(milliseconds: 120));

    setState(() => isPressed = false);

    await widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,

      /// use onTap only
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),

        /// press effect (down movement)
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

class GlowThumb extends SliderComponentShape {
  final bool isDark;

  GlowThumb({required this.isDark});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
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

    /// Glow effect
    final Paint glowPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, 14, glowPaint);

    /// Main thumb
    final Paint thumbPaint = Paint()..color = Colors.blueAccent;

    canvas.drawCircle(center, 10, thumbPaint);
  }
}

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

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    /// Gradient Paint (Blue → Cyan)
    final Paint activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.blueAccent, Colors.purpleAccent],
      ).createShader(trackRect);

    /// Inactive Paint
    final Paint inactivePaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.2);

    /// Active track (left)
    final Rect leftTrack = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );

    /// Inactive track (right)
    final Rect rightTrack = Rect.fromLTRB(
      thumbCenter.dx,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    final Radius radius = const Radius.circular(10);
    canvas.drawRRect(RRect.fromRectAndRadius(leftTrack, radius), activePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightTrack, radius),
      inactivePaint,
    );
  }
}

class BorderProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;

  BorderProgressPainter(this.progress, this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final metric = path.computeMetrics().first;

    /// BACKGROUND BORDER (FULL)
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      /// light shade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, bgPaint);

    ///  PROGRESS BORDER (ANIMATED)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final extractPath = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(extractPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant BorderProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}
