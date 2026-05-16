import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/build_circle_icon_button.dart';

bool isDark = true;

class HowToPlayPage extends StatefulWidget {
  const HowToPlayPage({super.key});

  @override
  State<HowToPlayPage> createState() => _HowToPlayPageState();
}

class _HowToPlayPageState extends State<HowToPlayPage> {
  @override
  void initState() {
    super.initState();

    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // backgroundColor: const Color(0xFF1F2A44),
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FB),

      appBar: AppBar(
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // transparent status bar
          statusBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark, // Android
          statusBarBrightness: isDark
              ? Brightness.dark
              : Brightness.light, // iOS
        ),

        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white24
                : Colors.black12,
          ),
        ),

        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),

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
          "How To Play",

          style: TextStyle(
            color: isDark
                ? Colors.cyanAccent
                : Colors.blue,

            fontWeight: FontWeight.bold,
          ),
        ),

        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Tooltip(
            message: "Back",
            child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
              },
              child: build3DIconButton(icon:Icons.arrow_back,isDark: isDark),
            ),
          ),
        ),
      ),

      /// 🔥 SCROLLABLE BODY
      //body: SingleChildScrollView(
        body: SafeArea(
        top: false,
    child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),

        child: Padding(
          //padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
            bottom: 00,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0),

                    Text(
                      "Game Rules",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Container(
                      width: 145,
                      height: 2,
                      color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                    ),

                    const SizedBox(height: 20),

                    ruleItem(
                      icon: Icons.emoji_events,
                      title: "WIN",
                      description:
                      "Match 3 symbols.\nPlayer wins the game.",
                      graphic: buildWinGraphic(),
                    ),

                    Divider(
                      color: isDark ? Colors.white24 : Colors.blue,
                      height: 40,
                    ),

                    ruleItem(
                      icon: Icons.sentiment_dissatisfied,
                      title: "DEFEAT",
                      description:
                      "Opponent matches 3 symbols.\nPlayer loses the game.",
                      graphic: buildDefeatGraphic(),
                    ),

                    Divider(
                      color: isDark ? Colors.white24 : Colors.blue,
                      height: 40,
                    ),

                    ruleItem(
                      icon: Icons.handshake,
                      title: "DRAW",
                      description:
                      "Board fills with no match.\nGame ends in a draw.",
                      graphic: buildDrawGraphic(),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      "Win Conditions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Container(
                      width: 170,
                      height: 2,
                      color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 TABLE
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,

                        borderRadius: BorderRadius.circular(6),

                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.12),
                            blurRadius: 8,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),

                      child: Table(
                        border: TableBorder.symmetric(
                          inside: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),

                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1.8),
                        },

                        children: [
                          /// 🔥 HEADER
                          TableRow(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.withValues(alpha:0.2)
                                  : Colors.blue.withValues(alpha:0.1),
                            ),

                            children: [
                              tableCell("Board Size", isHeader: true),

                              tableCell("Win Condition", isHeader: true),
                            ],
                          ),

                          /// 🔥 ROWS
                          buildTableRow("3x3", "Connect 3 symbols"),
                          buildTableRow("4x4", "Connect 4 symbols"),
                          buildTableRow("5x5", "Connect 4 symbols"),
                          buildTableRow("6x6", "Connect 4 symbols"),
                          buildTableRow("7x7", "Connect 5 symbols"),
                          buildTableRow("8x8", "Connect 5 symbols"),
                          buildTableRow("9x9", "Connect 5 symbols"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }

  Widget ruleItem({
    required IconData icon,
    required String title,
    required String description,
    required Widget graphic,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isDark ? Colors.amber : Colors.blueAccent, size: 28),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blue,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                description,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.blue,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        graphic,
      ],
    );
  }

  // WIN Graphic
  // WIN Graphic
  Widget buildWinGraphic() {
    return miniBoard(["O", "O", "O", "", "X", "", "X", "", ""]);
  }

  // DEFEAT Graphic
  Widget buildDefeatGraphic() {
    return miniBoard(["X", "", "O", "X", "O", "", "X", "", ""]);
  }

  // DRAW Graphic
  Widget buildDrawGraphic() {
    return miniBoard(["X", "O", "X", "O", "X", "O", "O", "X", "O"]);
  }

  // Widget miniBoard(List<String> values) {
  //   return Container(
  //     padding: const EdgeInsets.all(6),
  //
  //     decoration: BoxDecoration(
  //       color: isDark ? const Color(0xFF1E293B) : Colors.white,
  //
  //       borderRadius: BorderRadius.circular(6),
  //
  //       border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
  //
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha:0.15),
  //           blurRadius: 8,
  //           offset: const Offset(2, 4),
  //         ),
  //       ],
  //     ),
  //
  //     child: SizedBox(
  //       width: 70,
  //       height: 70,
  //
  //       child: GridView.builder(
  //         physics: const NeverScrollableScrollPhysics(),
  //         itemCount: 9,
  //
  //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //           crossAxisCount: 3,
  //         ),
  //
  //         itemBuilder: (context, index) {
  //           String value = values[index];
  //
  //           Color textColor;
  //
  //           if (value == "X") {
  //             textColor = Colors.blueAccent;
  //           } else if (value == "O") {
  //             textColor = Colors.orangeAccent;
  //           } else {
  //             textColor = Colors.transparent;
  //           }
  //
  //           return Container(
  //             alignment: Alignment.center,
  //
  //             decoration: BoxDecoration(
  //               border: Border.all(
  //                 color: isDark ? Colors.white24 : Colors.black45,
  //               ),
  //             ),
  //
  //             child: Text(
  //               value,
  //
  //               style: TextStyle(
  //                 color: textColor,
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 18,
  //               ),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget miniBoard(List<String> values) {
    return Container(
      padding: const EdgeInsets.all(4), // Reduced padding to give the grid more space

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),

      child: SizedBox(
        width: 72,  // Slightly increased size to properly fit the 3x3 grid
        height: 72,

        child: GridView.builder(
          padding: EdgeInsets.zero, // 🔥 CRITICAL FIX: Removes default GridView padding that was hiding the grid
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 1,  // Adds subtle spacing between rows
            crossAxisSpacing: 1, // Adds subtle spacing between columns
          ),

          itemBuilder: (context, index) {
            String value = values[index];
            Color textColor;

            if (value == "X") {
              textColor = Colors.blueAccent;
            } else if (value == "O") {
              textColor = Colors.orangeAccent;
            } else {
              textColor = Colors.transparent;
            }

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.5, // Thinner border so it doesn't clutter the small grid cells
                ),
              ),

              child: Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Decreased font size from 18 to 14 so text fits inside the small cells
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  TableRow buildTableRow(String board, String condition) {
    return TableRow(children: [tableCell(board), tableCell(condition)]);
  }

  Widget tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),

      child: Text(
        text,
        textAlign: TextAlign.center,

        style: TextStyle(
          fontSize: isHeader ? 16 : 14,

          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,

          color: isHeader
              ? (isDark ? Colors.cyanAccent : Colors.blue)
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

///end main class
