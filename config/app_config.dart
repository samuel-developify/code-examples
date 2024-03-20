import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConfig {
  static const String apiUrl = _testApiUrl;
  static const String _testApiUrl = String.fromEnvironment('host', defaultValue: '');
}
