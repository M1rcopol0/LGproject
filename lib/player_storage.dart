import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class PlayerDirectory {
  static const String _directoryKey = "registered_players";
  // On n'utilise plus _legacyKey pour la lecture, seulement pour le backup si besoin

  // --- LECTURE (SINGLE SOURCE OF TRUTH) ---
  // Cette fonction remplace l'ancien chargement. Elle retourne la liste des noms directement depuis l'annuaire.
  static Future<List<String>> getSavedPlayers() async {
    Map<String, dynamic> directory = await getDirectory();
    // On retourne les clés (les noms), triées alphabétiquement
    List<String> names = directory.keys.toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  // --- SYNCHRONISATION INITIALE ---
  // À appeler au démarrage (main.dart) pour importer les vieux joueurs dans l'annuaire si c'est la 1ère fois
  static Future<void> synchronizeWithLegacy(List<String> legacyNames) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> directory = await getDirectory();
    bool changed = false;

    for (String name in legacyNames) {
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
      await prefs.setString(_directoryKey, jsonEncode(directory));
      debugPrint("📂 Annuaire synchronisé avec les anciennes données.");
    }
  }

  // --- ENREGISTREMENT ---
  static Future<void> registerPlayer(String name, {String? phoneNumber}) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> directory = await getDirectory();

    // On écrase ou on crée (permet de mettre à jour le tel si on ré-ajoute le même nom)
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

    await prefs.setString(_directoryKey, jsonEncode(directory));
    // Pas besoin de sauvegarder une autre liste, l'annuaire suffit.
  }

  // --- MISE À JOUR PROFIL ---
  static Future<void> updatePlayerProfile(String oldName, String newName, String? newPhone) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> directory = await getDirectory();

    if (!directory.containsKey(oldName)) return;

    Map<String, dynamic> playerData = directory[oldName];
    playerData["phoneNumber"] = newPhone;

    if (oldName != newName) {
      // Si le nom change, on crée une nouvelle entrée et on supprime l'ancienne
      directory[newName] = playerData; // Conserve les stats
      directory.remove(oldName);
    } else {
      directory[oldName] = playerData;
    }

    await prefs.setString(_directoryKey, jsonEncode(directory));
  }

  // --- SUPPRESSION ---
  static Future<void> deletePlayer(String name) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> directory = await getDirectory();

    if (directory.containsKey(name)) {
      directory.remove(name);
      await prefs.setString(_directoryKey, jsonEncode(directory));
    }
  }

  static Future<Map<String, dynamic>> getDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_directoryKey);
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