// import 'dart:ui';
//
// import 'package:flutter/material.dart';
//
// class SettingsMenuItem {
//   final IconData icon;
//
//   final String title;
//
//   final bool value;
//
//   final Function(bool) onChanged;
//
//   SettingsMenuItem({
//     required this.icon,
//
//     required this.title,
//
//     required this.value,
//
//     required this.onChanged,
//   });
// }
//
// Future<void> showGlassSettingsMenu({
//   required BuildContext context,
//
//   required bool isDark,
//
//   required List<SettingsMenuItem> items,
// }) async {
//   /// 🔥 LOCAL VALUES
//   List<bool> localValues = items.map((e) => e.value).toList();
//   /// 🔥 LOCAL THEME
//   bool localIsDark = isDark;
//
//   await showMenu(
//     context: context,
//
//     position: const RelativeRect.fromLTRB(1000, 80, 20, 0),
//
//     color: Colors.transparent,
//
//     elevation: 0,
//
//     items: [
//       PopupMenuItem(
//         enabled: false,
//
//         padding: EdgeInsets.zero,
//
//         child: Material(
//           color: Colors.transparent,
//
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(22),
//
//             child: ClipRect(
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//
//                 child: Container(
//                   width: 240,
//
//                   padding: const EdgeInsets.all(14),
//
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(22),
//
//                     color: localIsDark
//                         ? Colors.white.withValues(alpha: 0.08)
//                         : Colors.white.withValues(alpha: 0.18),
//
//                     border: Border.all(
//                       color: localIsDark
//                           ? Colors.white.withValues(alpha: 0.1)
//                           : Colors.black.withValues(alpha: 0.08),
//                     ),
//
//                     boxShadow: [
//                       BoxShadow(
//                         color: localIsDark
//                             ? Colors.black.withValues(alpha: 0.12)
//                             : Colors.blueGrey.withValues(alpha: 0.08),
//
//                         blurRadius: 20,
//
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//
//                   child: StatefulBuilder(
//                     builder: (context, setStateMenu) {
//                       return Column(
//                         mainAxisSize: MainAxisSize.min,
//
//                         children: items.asMap().entries.map((entry) {
//                           final index = entry.key;
//
//                           final item = entry.value;
//
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 4),
//
//                             child: Row(
//                               children: [
//                                 Icon(
//
//                                     item.title == "Dark Theme"
//
//                                         ? (localValues[index]
//                                         ? Icons.dark_mode
//                                         : Icons.light_mode)
//
//                                         : item.icon,
//
//                                   size: 20,
//
//                                     color: localIsDark
//                                         ? Colors.cyanAccent
//                                         : Colors.blue
//                                 ),
//
//                                 const SizedBox(width: 10),
//
//                                 Expanded(
//                                   child: Text(
//                                     item.title,
//
//                                     style: TextStyle(
//                                       color: localIsDark
//                                           ? Colors.white
//                                           : Colors.black87,
//
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//
//                                 Transform.scale(
//                                   scale: 0.85,
//
//                                   child: Switch(
//                                     value: localValues[index],
//
//                                     activeThumbColor: Colors.blueAccent,
//
//                                     onChanged: (value) async {
//                                       /// 🔥 INSTANT UI
//                                       setStateMenu(() {
//                                         localValues[index] = value;
//                                         /// 🔥 REALTIME THEME
//                                         if (item.title == "Dark Theme") {
//
//                                           localIsDark = value;
//                                         }
//                                       });
//
//                                       /// 🔥 REAL CALLBACK
//                                       item.onChanged(value);
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     ],
//   );
// }

import 'dart:ui';

import 'package:flutter/material.dart';

class SettingsMenuItem {
  /// 🔥 DYNAMIC ICON
  final IconData Function(bool value) iconBuilder;
  final bool Function(bool value)? canChange;
  final String title;

  final bool value;

  /// 🔥 THEME UPDATE CHECK
  final bool affectsTheme;

  final Function(bool) onChanged;

  SettingsMenuItem({
    required this.iconBuilder,
    this.canChange,
    required this.title,

    required this.value,

    required this.onChanged,

    this.affectsTheme = false,
  });
}

Future<void> showGlassSettingsMenu({
  required BuildContext context,

  required bool isDark,

  required List<SettingsMenuItem> items,
}) async {
  /// 🔥 LOCAL SWITCH VALUES
  List<bool> localValues = items.map((e) => e.value).toList();

  /// 🔥 LOCAL THEME
  bool localIsDark = isDark;

  await showMenu(
    context: context,

    position: const RelativeRect.fromLTRB(1000, 80, 20, 0),

    color: Colors.transparent,

    elevation: 0,

    items: [
      PopupMenuItem(
        enabled: false,

        padding: EdgeInsets.zero,

        child: Material(
          color: Colors.transparent,

          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),

            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),

                child: StatefulBuilder(
                  builder: (context, setStateMenu) {
                    return Container(
                      width: 240,

                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),

                        color: localIsDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.18),

                        border: Border.all(
                          color: localIsDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: localIsDark
                                ? Colors.black.withValues(alpha: 0.12)
                                : Colors.blueGrey.withValues(alpha: 0.08),

                            blurRadius: 20,

                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: items.asMap().entries.map((entry) {
                          final index = entry.key;

                          final item = entry.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),

                            child: Row(
                              children: [
                                Icon(
                                  item.iconBuilder(localValues[index]),

                                  size: 20,

                                  color: localIsDark
                                      ? Colors.cyanAccent
                                      : Colors.blue,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    item.title,

                                    style: TextStyle(
                                      color: localIsDark
                                          ? Colors.white
                                          : Colors.black87,

                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                Transform.scale(
                                  scale: 0.85,

                                  child: Switch(
                                    value: localValues[index],

                                    activeThumbColor: Colors.blueAccent,

                                    // onChanged: (value) async {
                                    //   setStateMenu(() {
                                    //     /// 🔥 UPDATE SWITCH
                                    //     localValues[index] = value;
                                    //
                                    //     /// 🔥 UPDATE THEME
                                    //     if (item.affectsTheme) {
                                    //       localIsDark = value;
                                    //     }
                                    //   });
                                    //
                                    //   /// 🔥 CALLBACK
                                    //   item.onChanged(value);
                                    // },

                                    onChanged: (value) async {

                                      /// 🔥 VALIDATION
                                      bool allowed =
                                          item.canChange?.call(value)
                                              ?? true;

                                      if (!allowed) return;

                                      setStateMenu(() {

                                        /// 🔥 UPDATE SWITCH
                                        localValues[index] = value;

                                        /// 🔥 UPDATE THEME
                                        if (item.affectsTheme) {

                                          localIsDark = value;
                                        }
                                      });

                                      /// 🔥 CALLBACK
                                      item.onChanged(value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
