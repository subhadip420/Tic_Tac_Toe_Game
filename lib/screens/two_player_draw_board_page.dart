import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import '../widgets/build_3d_icon_button.dart';

class DrawBoardPage extends StatefulWidget {
  const DrawBoardPage({super.key});

  @override
  State<DrawBoardPage> createState() => _DrawBoardPageState();
}

// ✅ Stroke model (TOP LEVEL, not inside class)
class Stroke {
  final List<Offset?> points;
  final Color color;
  final double width;

  Stroke(this.points, this.color, this.width);
}

class _DrawBoardPageState extends State<DrawBoardPage> {
  List<Stroke> strokes = [];
  List<Offset?> currentStroke = [];

  Color selectedColor = Colors.black;
  double strokeWidth = 4;

  Color currentStrokeColor = Colors.black;
  double currentStrokeWidth = 4;

  bool isEraser = false;
  bool showTools = false;
  bool isDark = true;

  bool autoGrid = false;
  bool snapToBox = false;
  bool detectXO = false;
  bool turnBased = false;



  @override
  void initState() {
    super.initState();
    loadTheme().then((_) {
      setDefaultColor(); // ✅ ADD
    });
  }

  Future loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
    });
  }

  void setDefaultColor() {
    selectedColor = isDark ? Colors.white : Colors.black;
  }

  void showSettingsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery
            .of(context)
            .size
            .width,
        kToolbarHeight,
        0,
        0,
      ),

      color: isDark ? const Color(0xFF344364) : Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      items: [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 200,
            child: StatefulBuilder(
              builder: (context, setStateMenu) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🌙 THEME TOGGLE
                    settingsTile(
                      icon: isDark ? Icons.dark_mode : Icons.light_mode,
                      title: "Dark Theme",
                      value: isDark,
                      onChanged: (value) async {
                        SharedPreferences prefs =
                        await SharedPreferences.getInstance();

                        setState(() {
                          isDark = value;
                          setDefaultColor(); // ✅ RESET COLOR
                        });

                        // setStateMenu(() {});
                        prefs.setBool("theme_dark", isDark);
                        Navigator.pop(context);
                      },
                    ),

                    const Divider(height: 10, thickness: 0.6),

                    // 🎮 AUTO GRID
                    settingsTile(
                      icon: Icons.grid_on,
                      title: "Auto Grid",
                      value: autoGrid,
                      onChanged: (value) {
                        setState(() {
                          autoGrid = value;
                        });
                        setStateMenu(() {});
                      },
                    ),



                    //
                    // // 🎯 SNAP TO BOX
                    // settingsTile(
                    //   icon: Icons.crop_square,
                    //   title: "Snap to Box",
                    //   value: snapToBox,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       snapToBox = value;
                    //     });
                    //     setStateMenu(() {});
                    //   },
                    // ),
                    //
                    // // ❌⭕ DETECT XO
                    // settingsTile(
                    //   icon: Icons.gesture,
                    //   title: "Detect X / O",
                    //   value: detectXO,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       detectXO = value;
                    //     });
                    //     setStateMenu(() {});
                    //   },
                    // ),

                    // 🔄 TURN BASED MODE
                    // settingsTile(
                    //   icon: Icons.swap_horiz,
                    //   title: "Turn Based Mode",
                    //   value: turnBased,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       turnBased = value;
                    //     });
                    //     setStateMenu(() {});
                    //   },
                    // ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget settingsTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min, // ✅ IMPORTANT

        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 8),

          Expanded(
            // ✅ takes only needed space
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),

          // ✅ SHRINK SWITCH
          Transform.scale(
            scale: 0.8, // 👈 make switch smaller

            child: Switch(
              value: value,
              activeThumbColor: Colors.blueAccent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // 👈 remove extra padding
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    Color bgColor = isDark ? Color(0xFF161C28) : Color(0xFFEBEBEC);
    Color textColor = isDark ? Colors.cyanAccent : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Draw & Play",
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
        isDark ? Color(0xFF2B3A5A) : Color(0xFFF5F5F0),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: textColor),
        //   onPressed: () => Navigator.pop(context),
        // ),

        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
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

        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.settings, color: textColor),
        //     onPressed: () {
        //       showSettingsMenu();
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
                  showSettingsMenu();
                },
                child: build3DIconButton(icon:Icons.settings,isDark: isDark),
              ),
            ),
          ),
        ],
      ),

      // ✅ FIX: BODY STRUCTURE
      body: Column(
        children: [

          // 🎨 DRAW AREA
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                Size canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return GestureDetector(

                  onTapDown: (details) {
                    if (isEraser) {
                      eraseStroke(details.localPosition);
                    }
                  },

                  onPanStart: (details) {
                    if (isEraser) return;

                    currentStroke = [];

                    Offset point = details.localPosition;

                    if (snapToBox && autoGrid) {
                      point = snapToGridPoint(point, canvasSize);
                    }

                    currentStrokeColor =
                    isEraser ? bgColor : selectedColor;

                    currentStrokeWidth = strokeWidth;

                    currentStroke.add(point);
                  },

                  onPanUpdate: (details) {
                    if (isEraser) return;

                    setState(() {
                      Offset point = details.localPosition;

                      if (snapToBox && autoGrid) {
                        point = snapToGridPoint(point, canvasSize);
                      }

                      currentStroke.add(point);
                    });
                  },

                  onPanEnd: (_) {
                    if (isEraser) return;

                    strokes.add(
                      Stroke(
                        List.from(currentStroke),
                        currentStrokeColor,
                        currentStrokeWidth,
                      ),
                    );

                    currentStroke = [];
                  },

                  child: Container(
                    color: bgColor,
                    child: CustomPaint(
                      painter: DrawPainter(
                        strokes,
                        currentStroke,
                        currentStrokeColor,
                        currentStrokeWidth,
                        isDark,
                        autoGrid,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                );
              },
            ),
          ),

          // 🎛 FIXED TOOL PANEL (BOTTOM)
          Container(
            padding: const EdgeInsets.all(10),
            color: isDark
                ? const Color(0xFF2B3A5A)
                : Color(0xFFE5E5E3),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // 🖊 TOOLS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    toolButton(
                      icon: Icons.edit,
                      isSelected: !isEraser,
                      onTap: () {
                        setState(() {
                          isEraser = false;
                        });
                      },
                    ),

                    toolButton(
                      icon: Icons.cleaning_services,
                      isSelected: isEraser,
                      onTap: () {
                        setState(() {
                          isEraser = true;
                        });
                      },
                    ),

                    toolButton(
                      icon: Icons.delete,
                      isSelected: false,
                      onTap: () {
                        setState(() {
                          strokes.clear();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 🎨 COLORS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    colorBtn(Colors.black),
                    colorBtn(Colors.red),
                    colorBtn(Colors.blue),
                    colorBtn(Colors.green),
                    colorBtn(Colors.orange),
                    colorBtn(Colors.white),
                  ],
                ),

                // 🎚 SIZE
                Slider(
                  value: strokeWidth,
                  min: 2,
                  max: 12,
                  onChanged: (value) {
                    setState(() {
                      strokeWidth = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎛 TOOL BUTTON
  Widget toolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(

      onTapDown: (details) {
        if (isEraser) {
          eraseStroke(details.localPosition); // ✅ erase on tap
        }
      },

      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }

  // 🎨 COLOR BUTTON
  Widget colorBtn(Color color) {
    bool isSelected = selectedColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
          isEraser = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(2),

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),

        child: CircleAvatar(backgroundColor: color, radius: 14),
      ),
    );
  }

  void eraseStroke(Offset touchPoint) {
    const double threshold = 20; // 👈 sensitivity (increase/decrease)

    for (int i = strokes.length - 1; i >= 0; i--) {
      Stroke stroke = strokes[i];

      for (var point in stroke.points) {
        if (point == null) continue;

        double dx = point.dx - touchPoint.dx;
        double dy = point.dy - touchPoint.dy;

        double distance = sqrt(dx * dx + dy * dy);

        if (distance < threshold) {
          setState(() {
            strokes.removeAt(i); // ✅ remove whole stroke
          });
          return;
        }
      }
    }
  }

  Offset snapToGridPoint(Offset point, Size size) {
    double cellW = size.width / 3;
    double cellH = size.height / 3;

    int col = (point.dx / cellW).floor();
    int row = (point.dy / cellH).floor();

    // safety
    col = col.clamp(0, 2);
    row = row.clamp(0, 2);

    double centerX = col * cellW + cellW / 2;
    double centerY = row * cellH + cellH / 2;

    return Offset(centerX, centerY);
  }


} // end ,main class///////////////////////////////////////////////////////////////////

// 🎨 PAINTER
class DrawPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset?> currentStroke;
  final Color currentStrokeColor; // ✅ ADD
  final double currentStrokeWidth; // ✅ ADD
  final bool isDark;
  final bool autoGrid;

  DrawPainter(this.strokes,
      this.currentStroke,
      this.currentStrokeColor,
      this.currentStrokeWidth,
      this.isDark,
      this.autoGrid,);

  @override
  void paint(Canvas canvas, Size size) {
    // 🎯 DRAW GRID ONLY IF ENABLED
    if (autoGrid) {
      final gridPaint = Paint()
        ..color = isDark ? Colors.white : Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      double w = size.width;
      double h = size.height;

      // ✅ OUTER BOX (border)
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        gridPaint,
      );

      // vertical
      canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), gridPaint);
      canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), gridPaint);

      // horizontal
      canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), gridPaint);
      canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), gridPaint);
    }

    // ✅ DRAW SAVED STROKES (correct color per stroke)
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke
            .color // ✅ FIX
        ..strokeWidth = stroke
            .width // ✅ FIX
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }

    // ✅ DRAW CURRENT STROKE (real-time color)
    final paint = Paint()
      ..color =
          currentStrokeColor // ✅ FIX
      ..strokeWidth =
          currentStrokeWidth // ✅ FIX
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < currentStroke.length - 1; i++) {
      if (currentStroke[i] != null && currentStroke[i + 1] != null) {
        canvas.drawLine(currentStroke[i]!, currentStroke[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
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