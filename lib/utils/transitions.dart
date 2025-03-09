import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var curve = Curves.easeInOut;
      var curveTween = CurveTween(curve: curve);

      var fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(animation.drive(curveTween));

      return FadeTransition(
        opacity: fadeAnimation,
        child: child,
      );
    },
  );
}

class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var curve = Curves.easeInOut;
      var curveTween = CurveTween(curve: curve);

      var slideAnimation = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation.drive(curveTween));

      var fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(animation.drive(curveTween));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}