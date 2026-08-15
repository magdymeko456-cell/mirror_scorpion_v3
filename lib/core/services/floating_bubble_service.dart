import 'package:flutter/material.dart';

class FloatingBubbleService extends ChangeNotifier {
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  void toggleBubble(bool value) {
    _isEnabled = value;
    notifyListeners();
  }
}
