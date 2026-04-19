import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Helper to create sliding page transitions (from right to left)
CustomTransitionPage slideRightPage(Widget child, {LocalKey? key}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

/// Helper to create fading page transitions
CustomTransitionPage fadeInPage(Widget child, {LocalKey? key}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
