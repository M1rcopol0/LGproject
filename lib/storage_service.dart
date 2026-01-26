import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StorageService {
  static const String _playerKey = 'saved_players_list';
  static const String _trophyKey = 'saved_trophies';

  // --- SAUVEGARDER LES NOMS DES JOUEURS ---
  static Future<void> savePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    // On ne sauvegarde que les noms pour rester simple
    List<String> names = players.map((p) => p.name).toList();
    await prefs.setStringList(_playerKey, names);
  }

  // --- CHARGER LES JOUEURS ---
  static Future<List<Player>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? names = prefs.getStringList(_playerKey);
    if (names == null) return [];
    return names.map((name) => Player(name: name)).toList();
  }

  // --- SAUVEGARDER LES TROPHÉES ---
  static Future<void> saveTrophies(Map<String, dynamic> trophies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trophyKey, jsonEncode(trophies));
  }

  // --- CHARGER LES TROPHÉES ---
  static Future<Map<String, dynamic>> loadTrophies() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_trophyKey);
    if (data == null) return {};
    return jsonDecode(data);
  }
}