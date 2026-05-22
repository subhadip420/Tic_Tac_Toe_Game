import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import '../widgets/build_circle_icon_button.dart';
import '../widgets/glass_settings_menu.dart';
import '../widgets/loading_dialog_with_button.dart';

class DrawBoardPage extends StatefulWidget {
  const DrawBoardPage({super.key});

  @override
  State<DrawBoardPage> createState() => _DrawBoardPageState();
}

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
  bool vibrationOn = true;
  bool autoGrid = false;
  bool snapToBox = false;
  bool detectXO = false;
  bool turnBased = false;

  @override
  void initState() {
    super.initState();
    loadTheme().then((_) {
      setDefaultColor();
    });
  }

  Future loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      isDark = prefs.getBool("theme_dark") ?? true;
      vibrationOn = prefs.getBool("vibration_on") ?? true;
    });
  }

  void setDefaultColor() {
    selectedColor = isDark ? Colors.white : Colors.black;
  }

  ///new
  void showSettingsMenu() {
    showGlassSettingsMenu(
      context: context,
      isDark: isDark,
      items: [
        /// THEME
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

              /// RESET COLOR
              setDefaultColor();
            });

            await prefs.setBool("theme_dark", isDark);
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
            if (!vibrationOn) {
              HapticFeedback.lightImpact();
            }
            setState(() {
              vibrationOn = value;
            });

            await prefs.setBool("vibration_on", vibrationOn);
          },
        ),

        /// AUTO GRID
        SettingsMenuItem(
          iconBuilder: (value) {
            return Icons.grid_on;
          },
          title: "Auto Grid",
          value: autoGrid,
          onChanged: (value) {
            if (vibrationOn) {
              HapticFeedback.lightImpact();
            }
            setState(() {
              autoGrid = value;
            });
          },
        ),
      ],
    );
  }

  ///new
  Future<bool> showExitDialog() async {
    bool shouldExit = false;

    await showAppDialog(
      context: context,
      title: "EXIT MATCH",
      message: "Exit and end the match?",
      positiveText: "EXIT",
      negativeText: "CANCEL",
      barrierDismissible: true,
      canPop: true,

      onNegative: () {
        if (vibrationOn) {
          HapticFeedback.lightImpact();
        }
        shouldExit = false;
      },
      onPositive: () async {
        if (vibrationOn) {
          HapticFeedback.mediumImpact();
        }
        shouldExit = true;
      },
    );
    return shouldExit;
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
        backgroundColor: isDark ? Color(0xFF2B3A5A) : Color(0xFFF5F5F0),

        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Tooltip(
            message: "Back",
            child: GestureDetector(
              onTap: () async {
                if (vibrationOn) {
                  HapticFeedback.lightImpact();
                }
                // await showExitDialog();
                // Navigator.pop(context);
                bool exit = await showExitDialog();
                if (exit) {
                  Navigator.pop(context);
                }
              },
              child: build3DIconButton(icon: Icons.arrow_back, isDark: isDark),
            ),
          ),
        ),

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
                child: build3DIconButton(icon: Icons.settings, isDark: isDark),
              ),
            ),
          ),
        ],
      ),

      /// FIX: BODY STRUCTURE
      body: Column(
        children: [
          /// DRAW AREA
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
                    currentStrokeColor = isEraser ? bgColor : selectedColor;
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

          /// FIXED TOOL PANEL (BOTTOM)
          Container(
            padding: const EdgeInsets.all(10),
            color: isDark ? const Color(0xFF2B3A5A) : Color(0xFFE5E5E3),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ///TOOLS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    toolButton(
                      icon: Icons.edit,
                      isSelected: !isEraser,
                      onTap: () {
                        if (vibrationOn) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() {
                          isEraser = false;
                        });
                      },
                    ),

                    toolButton(
                      icon: Icons.cleaning_services,
                      isSelected: isEraser,
                      onTap: () {
                        if (vibrationOn) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() {
                          isEraser = true;
                        });
                      },
                    ),

                    toolButton(
                      icon: Icons.delete,
                      isSelected: false,
                      onTap: () {
                        if (vibrationOn) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() {
                          strokes.clear();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// COLORS
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
                    if (vibrationOn) {
                      HapticFeedback.selectionClick();
                    }
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

  ///TOOL BUTTON
  Widget toolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (details) {
        if (isEraser) {
          eraseStroke(details.localPosition);
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

  /// COLOR BUTTON
  Widget colorBtn(Color color) {
    bool isSelected = selectedColor == color;

    return GestureDetector(
      onTap: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
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
    const double threshold = 20;

    for (int i = strokes.length - 1; i >= 0; i--) {
      Stroke stroke = strokes[i];
      for (var point in stroke.points) {
        if (point == null) continue;
        double dx = point.dx - touchPoint.dx;
        double dy = point.dy - touchPoint.dy;
        double distance = sqrt(dx * dx + dy * dy);
        if (distance < threshold) {
          setState(() {
            strokes.removeAt(i);
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

/// PAINTER
class DrawPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset?> currentStroke;
  final Color currentStrokeColor;
  final double currentStrokeWidth;
  final bool isDark;
  final bool autoGrid;

  DrawPainter(
    this.strokes,
    this.currentStroke,
    this.currentStrokeColor,
    this.currentStrokeWidth,
    this.isDark,
    this.autoGrid,
  );

  @override
  void paint(Canvas canvas, Size size) {
    /// DRAW GRID ONLY IF ENABLED
    if (autoGrid) {
      final gridPaint = Paint()
        ..color = isDark ? Colors.white : Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      double w = size.width;
      double h = size.height;

      ///OUTER BOX (border)
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gridPaint);

      // vertical
      canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), gridPaint);
      canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), gridPaint);

      // horizontal
      canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), gridPaint);
      canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), gridPaint);
    }

    /// DRAW SAVED STROKES (correct color per stroke)
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }

    /// DRAW CURRENT STROKE (real-time color)
    final paint = Paint()
      ..color = currentStrokeColor
      ..strokeWidth = currentStrokeWidth
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
