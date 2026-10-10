import 'package:flutter/material.dart';

class SemanticButtonRegistry {
  static final Map<String, GlobalKey> _registry = {};

  static void register(String label, GlobalKey key) {
    _registry[label] = key;
  }

  static GlobalKey? get(String label) => _registry[label];

  static void clear() => _registry.clear();
}
