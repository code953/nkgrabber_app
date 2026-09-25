/// Draws the user's background image behind every page.
library;

import 'dart:io';

import 'package:flutter/material.dart';

/// Stacks [child] over [image] and a surface-coloured scrim.
///
/// Sits in `MaterialApp.builder`, directly above the router's Navigator.
/// Switching between the bare child and the Stack is safe: the Navigator
/// carries a GlobalKey, so it is reparented rather than rebuilt and open
/// dialogs survive a background change.
class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.image,
    required this.overlayPercent,
    required this.child,
    super.key,
  });

  final File? image;

  /// Scrim opacity, 0–100.
  final int overlayPercent;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    if (image == null) return child;

    final box = _decodeBox(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: ResizeImage(
            FileImage(image),
            width: box,
            height: box,
            policy: ResizeImagePolicy.fit,
          ),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // Deleted behind our back: show the plain theme, not an error.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        ColoredBox(
          color: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: overlayPercent / 100),
        ),
        child,
      ],
    );
  }

  /// The box the picture is decoded into.
  ///
  /// Bounded so an 8000 px photo is not held at full size, and taken from the
  /// *display* rather than the window: the cache key includes this size, so
  /// tying it to the window would re-decode on every frame of a desktop
  /// resize.
  static int _decodeBox(BuildContext context) {
    final display = View.of(context).display.size.longestSide;
    return display.isFinite && display > 0
        ? display.round().clamp(1024, 8192)
        : 2560;
  }
}
