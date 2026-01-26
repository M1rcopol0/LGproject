import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Role {
  final String name;
  final String description;
  final String faction; // Village, Loup, Solo
  final String version; // 1.0, 3.0

  Role({
    required this.name,
    required this.description,
    required this.faction,
    required this.version,
  });

  Color get factionColor {
    switch (faction) {
      case "Village": return Colors.green;
      case "Loup": return Colors.red;
      case "Solo": return Colors.purple;
      default: return Colors.grey;
    }
  }
}
