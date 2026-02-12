import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class PlayerDirectory {
  static const String _key = "registered_players";
  static const String _legacyKey = "saved_players_list";

  // --- SYNCHRONISATION (RÉCUPÉRATION DES ANCIENS JOUEURS) ---
  static Future<void> synchronizeWithLegacy(List<String> legacyNames) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> directory = await getDirectory();
    bool changed = false;

    for (String name in legacyNames) {
      // Si le joueur existe dans la liste simple mais pas dans l'annuaire complet
      if (!directory.containsKey(name)) {
        directory[name] = {
          "gamesPlayed": 0,
          "wins": 0,
          "achievements": [],
          "phoneNumber": null,
        };
        changed = true;
      }
    }

    if (changed) {
      await prefs.setString(_key, jsonEncode(directory));
      debugPrint("📂 Annuaire synchronisé : ${legacyNames.length} joueurs traités.");
    }
  }

  // --- ENREGISTREMENT ---
  static Future<void> registerPlayer(String name, {String? phoneNumber}) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> directory = await getDirectory();

    if (!directory.containsKey(name)) {
      directory[name] = {
        "gamesPlayed": 0,
        "wins": 0,
        "achievements": [],
        "phoneNumber": phoneNumber,
      };
    } else if (phoneNumber != null) {
      directory[name]["phoneNumber"] = phoneNumber;
    }

    await prefs.setString(_key, jsonEncode(directory));
    await _updateLegacyList(directory.keys.toList()); // Synchro inverse
  }

  // --- MISE À JOUR PROFIL (NOM + TÉL) ---
  static Future<void> updatePlayerProfile(String oldName, String newName, String? newPhone) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> directory = await getDirectory();

    if (!directory.containsKey(oldName)) return;

    Map<String, dynamic> playerData = directory[oldName];
    playerData["phoneNumber"] = newPhone;

    if (oldName != newName) {
      // Si changement de nom, on déplace la donnée
      if (directory.containsKey(newName)) {
        // Conflit : on garde l'ancien (ou on écrase, ici simple update)
        directory[newName]["phoneNumber"] = newPhone;
      } else {
        directory[newName] = playerData;
      }
      directory.remove(oldName);
    } else {
      directory[oldName] = playerData;
    }

    await prefs.setString(_key, jsonEncode(directory));
    await _updateLegacyList(directory.keys.toList()); // Synchro inverse
  }

  // Helper pour maintenir la liste compatible avec le reste du jeu
  static Future<void> _updateLegacyList(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_legacyKey, names);
  }

  static Future<Map<String, dynamic>> getDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_key);
    if (data == null) return {};
    return jsonDecode(data);
  }

  static Future<String?> getPhoneNumber(String name) async {
    var dir = await getDirectory();
    if (dir.containsKey(name)) {
      return dir[name]["phoneNumber"];
    }
    return null;
  }
}