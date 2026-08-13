import 'package:flutter/material.dart';

/// Chave global do ScaffoldMessenger — permite mostrar SnackBar de qualquer lugar
/// (inclusive de serviços, sem BuildContext).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void avisar(String msg) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
