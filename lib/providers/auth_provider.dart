import 'package:flutter/material.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

class HikerAuthProvider extends InheritedWidget {
  final AuthService authService;

  const HikerAuthProvider({
    super.key,
    required this.authService,
    required super.child,
  });

  static AuthService of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<HikerAuthProvider>();
    assert(provider != null, 'No HikerAuthProvider found in context');
    return provider!.authService;
  }

  @override
  bool updateShouldNotify(HikerAuthProvider oldWidget) =>
      authService != oldWidget.authService;
}