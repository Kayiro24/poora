import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';

/// 56px coral circle with a white +.
class CoralFab extends StatelessWidget {
  const CoralFab({
    required this.onPressed,
    this.semanticLabel = 'Create task',
    super.key,
  });

  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Tokens.coral,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: 56,
            child: Icon(Icons.add_rounded, color: Tokens.white, size: 30),
          ),
        ),
      ),
    );
  }
}
