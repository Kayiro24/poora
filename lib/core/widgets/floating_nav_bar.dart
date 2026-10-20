import 'package:flutter/material.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';

class NavItem {
  const NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Pill-shaped dark bar floating 16px above the bottom edge. The active item
/// sits in an ice-coloured rounded square.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.items,
    required this.index,
    required this.onTap,
    super.key,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  static const height = 68.0;

  /// Space content should leave at the bottom so the bar never covers it.
  static double reservedHeight(BuildContext context) =>
      height + 16 + MediaQuery.paddingOf(context).bottom + 8;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(40, 0, 40, 16 + bottom),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: Tokens.outline, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavButton(
                item: items[i],
                active: i == index,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context),
          curve: Motion.curve,
          width: 52,
          height: 48,
          decoration: BoxDecoration(
            color: active ? Tokens.ice : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            active ? item.activeIcon : item.icon,
            color: active ? Tokens.textInverse : Tokens.textSecondary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
