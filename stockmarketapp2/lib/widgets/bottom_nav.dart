// lib/widgets/bottom_nav.dart

/// DEPRECATED: This standalone `BottomNav` widget is no longer used in the app.
/// The floating, pill-shaped bottom navigation bar has been inlined into each
/// screen to allow per-screen active-state handling and custom icons/colors.
///
/// ────────────────────────────────────────────────────────────────────────────────
/// Overview:
///   • Positions itself at the bottom with horizontal padding.
///   • Renders a Row of equally spaced icons.
///   • Highlights the active icon with a colored background, rounded corners,
///     and a subtle “glow” shadow.
///   • Calls back to its owner via the `onTap` list when an icon is tapped.
///
/// Parameters:
///   • `currentIndex` (int) : zero-based index of the active icon.
///   • `icons`        (List<IconData>) : the icon glyphs to show.
///   • `onTap`        (List<NavCallback>) : callbacks matching each icon.
///
/// Usage (legacy):
/// ```dart
/// BottomNav(
///   currentIndex: 2,
///   icons: [Icons.home, Icons.search, Icons.person],
///   onTap: [onHome, onSearch, onProfile],
/// )
/// ```
///
/// Now, each screen defines its own NavIcon row directly in its scaffold,
/// and this file can be safely removed once all references are cleaned up.

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

typedef NavCallback = void Function();

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<IconData> icons;
  final List<NavCallback> onTap;

  const BottomNav({
    Key? key,
    required this.currentIndex,
    required this.icons,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 16,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.textMedium.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(1, 1),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(icons.length, (i) {
            final active = i == currentIndex;
            return InkResponse(
              onTap: onTap[i],
              splashColor: const Color(0xFF180E8D),
              radius: 28,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: active
                    ? BoxDecoration(
                  color: AppColors.upwardMovement.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.upwardMovement.withOpacity(0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                )
                    : null,
                child: Icon(
                  icons[i],
                  size: 28,
                  color: active ? AppColors.upwardMovement : AppColors.textMedium,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
