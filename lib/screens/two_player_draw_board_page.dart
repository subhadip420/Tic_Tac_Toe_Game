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

/// Store drawing stroke data
class Stroke {
  /// Stroke points
  final List<Offset?> points;

  /// Stroke color
  final Color color;

  /// Stroke width
  final double width;

  Stroke(this.points, this.color, this.width);
}

class _DrawBoardPageState extends State<DrawBoardPage> {
  /// All saved strokes
  List<Stroke> strokes = [];

  /// Current drawing stroke
  List<Offset?> currentStroke = [];

  /// Selected drawing color
  Color selectedColor = Colors.black;

  /// Selected stroke width
  double strokeWidth = 4;

  /// Current active stroke color
  Color currentStrokeColor = Colors.black;

  /// Current active stroke width
  double currentStrokeWidth = 4;

  /// Eraser mode state
  bool isEraser = false;

  /// Tool panel visibility
  bool showTools = false;

  /// Theme mode state
  bool isDark = true;

  /// Vibration setting
  bool vibrationOn = true;

  /// Auto grid drawing mode
  bool autoGrid = false;

  /// Snap drawing inside box
  bool snapToBox = false;

  /// Detect X and O symbols
  bool detectXO = false;

  /// Alternate turn drawing mode
  bool turnBased = false;

  @override
  void initState() {
    super.initState();

    /// Load saved theme settings
    loadTheme().then((_) {
      /// Set default drawing color
      setDefaultColor();
    });
  }

  /// Load saved app settings
  Future loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      /// Load theme mode
      isDark = prefs.getBool("theme_dark") ?? true;

      /// Load vibration setting
      vibrationOn = prefs.getBool("vibration_on") ?? true;
    });
  }

  /// Set default drawing color
  void setDefaultColor() {
    selectedColor = isDark ? Colors.white : Colors.black;
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
              /// Update theme mode
              isDark = value;

              /// Reset drawing color
              setDefaultColor();
            });

            await prefs.setBool("theme_dark", isDark);
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

        /// Auto grid setting
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
              /// Toggle auto grid mode
              autoGrid = value;
            });
          },
        ),
      ],
    );
  }

  /// Show exit confirmation dialog
  Future<bool> showExitDialog() async {
    /// Store exit result
    bool shouldExit = false;

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
        shouldExit = false;
      },

      /// Exit button action
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
    /// Background color
    Color bgColor = isDark ? Color(0xFF161C28) : Color(0xFFEBEBEC);

    /// Main text color
    Color textColor = isDark ? Colors.cyanAccent : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        /// Screen title
        title: Text(
          "Draw & Play",
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        /// AppBar background color
        backgroundColor: isDark ? Color(0xFF2B3A5A) : Color(0xFFF5F5F0),

        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Tooltip(
            message: "Back",
            child: GestureDetector(
              /// Handle back button tap
              onTap: () async {
                if (vibrationOn) {
                  HapticFeedback.lightImpact();
                }

                /// Show exit dialog
                bool exit = await showExitDialog();

                /// Close screen if confirmed
                if (exit) {
                  Navigator.pop(context);
                }
              },

              /// Custom back button
              child: build3DIconButton(icon: Icons.arrow_back, isDark: isDark),
            ),
          ),
        ),

        actions: [
          /// Settings button
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: "Settings",
              child: GestureDetector(
                /// Open settings menu
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

      /// Main body section
      body: Column(
        children: [
          /// Drawing canvas area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                /// Canvas size
                Size canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return GestureDetector(
                  /// Erase stroke on tap
                  onTapDown: (details) {
                    if (isEraser) {
                      eraseStroke(details.localPosition);
                    }
                  },

                  /// Start drawing stroke
                  onPanStart: (details) {
                    if (isEraser) return;
                    currentStroke = [];
                    Offset point = details.localPosition;

                    /// Snap point to grid
                    if (snapToBox && autoGrid) {
                      point = snapToGridPoint(point, canvasSize);
                    }

                    /// Set current stroke style
                    currentStrokeColor = isEraser ? bgColor : selectedColor;
                    currentStrokeWidth = strokeWidth;
                    currentStroke.add(point);
                  },

                  /// Update drawing stroke
                  onPanUpdate: (details) {
                    if (isEraser) return;
                    setState(() {
                      Offset point = details.localPosition;

                      /// Snap point to grid
                      if (snapToBox && autoGrid) {
                        point = snapToGridPoint(point, canvasSize);
                      }
                      currentStroke.add(point);
                    });
                  },

                  /// Save completed stroke
                  onPanEnd: (_) {
                    if (isEraser) return;
                    strokes.add(
                      Stroke(
                        List.from(currentStroke),
                        currentStrokeColor,
                        currentStrokeWidth,
                      ),
                    );

                    /// Reset current stroke
                    currentStroke = [];
                  },

                  child: Container(
                    color: bgColor,

                    /// Drawing canvas painter
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

          /// Fixed bottom tool panel
          Container(
            padding: const EdgeInsets.all(10),

            /// Tool panel background color
            color: isDark ? const Color(0xFF2B3A5A) : Color(0xFFE5E5E3),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Drawing tool buttons
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
                          /// Pen tool
                          isEraser = false;
                        });
                      },
                    ),

                    /// Eraser tool
                    toolButton(
                      icon: Icons.cleaning_services,
                      isSelected: isEraser,
                      onTap: () {
                        if (vibrationOn) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() {
                          /// Enable eraser mode
                          isEraser = true;
                        });
                      },
                    ),

                    /// Clear canvas button
                    toolButton(
                      icon: Icons.delete,
                      isSelected: false,
                      onTap: () {
                        if (vibrationOn) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() {
                          /// Remove all strokes
                          strokes.clear();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Color selection buttons
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

                /// Stroke size slider
                Slider(
                  value: strokeWidth,
                  min: 2,
                  max: 12,
                  onChanged: (value) {
                    if (vibrationOn) {
                      HapticFeedback.selectionClick();
                    }
                    setState(() {
                      /// Update brush size
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

  /// Tool button widget
  Widget toolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      /// Erase stroke on tap down
      onTapDown: (details) {
        if (isEraser) {
          eraseStroke(details.localPosition);
        }
      },

      /// Handle tool selection
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          /// Selected tool highlight
          color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),

        /// Tool icon
        child: Icon(icon, color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }

  /// Color selection button
  Widget colorBtn(Color color) {
    /// Selected color check
    bool isSelected = selectedColor == color;

    return GestureDetector(
      /// Change drawing color
      onTap: () {
        if (vibrationOn) {
          HapticFeedback.selectionClick();
        }
        setState(() {
          /// Update selected color
          selectedColor = color;

          /// Disable eraser mode
          isEraser = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(2),

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          /// Selected color border
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),

        /// Color preview circle
        child: CircleAvatar(backgroundColor: color, radius: 14),
      ),
    );
  }

  /// Erase nearby stroke
  void eraseStroke(Offset touchPoint) {
    /// Eraser touch range
    const double threshold = 20;

    /// Check all strokes
    for (int i = strokes.length - 1; i >= 0; i--) {
      Stroke stroke = strokes[i];

      /// Check all stroke points
      for (var point in stroke.points) {
        if (point == null) continue;
        double dx = point.dx - touchPoint.dx;
        double dy = point.dy - touchPoint.dy;
        double distance = sqrt(dx * dx + dy * dy);

        /// Remove touched stroke
        if (distance < threshold) {
          setState(() {
            strokes.removeAt(i);
          });
          return;
        }
      }
    }
  }

  /// Snap drawing point to grid center
  Offset snapToGridPoint(Offset point, Size size) {
    /// Grid cell width
    double cellW = size.width / 3;

    /// Grid cell height
    double cellH = size.height / 3;

    /// Detect grid column
    int col = (point.dx / cellW).floor();

    /// Detect grid row
    int row = (point.dy / cellH).floor();

    /// Keep inside grid boundary
    col = col.clamp(0, 2);
    row = row.clamp(0, 2);

    /// Cell center X
    double centerX = col * cellW + cellW / 2;

    /// Cell center Y
    double centerY = row * cellH + cellH / 2;

    return Offset(centerX, centerY);
  }
} // end main class///////////////////////////////////////////////////////////////////

/// Drawing canvas painter
class DrawPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset?> currentStroke;
  final Color currentStrokeColor;
  final double currentStrokeWidth;

  /// Theme mode state
  final bool isDark;

  /// Auto grid mode state
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
    /// Draw grid if enabled
    if (autoGrid) {
      final gridPaint = Paint()
        /// Grid line color
        ..color = isDark ? Colors.white : Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      double w = size.width;
      double h = size.height;

      /// Outer grid border
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gridPaint);

      /// Vertical grid lines
      canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), gridPaint);
      canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), gridPaint);

      /// Horizontal grid lines
      canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), gridPaint);
      canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), gridPaint);
    }

    /// Draw saved strokes
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

    /// Draw current active stroke
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
