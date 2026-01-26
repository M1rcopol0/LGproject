import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlayerDirectory {
  static const String _key = "registered_players";

  // Sauvegarder un nouveau joueur ou mettre à jour un ancien
  static Future<void> registerPlayer(String name) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> directory = await getDirectory();

    if (!directory.containsKey(name)) {
      directory[name] = {
        "gamesPlayed": 0,
        "wins": 0,
        "achievements": [],
      };
      await prefs.setString(_key, jsonEncode(directory));
    }
  }

  // Récupérer la liste complète des noms pour l'autocomplétion
  static Future<Map<String, dynamic>> getDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_key);
    if (data == null) return {};
    return jsonDecode(data);
  }
}