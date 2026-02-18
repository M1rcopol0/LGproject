import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../globals.dart';

class CloudService {
  // ⚠️ URL DU SCRIPT GOOGLE APPS SCRIPT V3
  // Après déploiement de google_apps_script_v3.js, mettre à jour cette URL
  static const String _scriptUrl = "https://script.google.com/macros/s/AKfycbx4V7JsiDtJsuJQs48lv5ybwcD2qgtI4QRy8pjRFfwDex4_-2hMcu1g6yCHtpn3pY7v/exec";

  // Cache pour lookup rapide des achievements (optimisation O(n²) → O(n))
  static final Map<String, Achievement> _achievementMap = Map.fromIterable(
    AchievementData.allAchievements,
    key: (a) => (a as Achievement).id,
    value: (a) => a as Achievement,
  );

  // =========================================================================
  // A. PULL AU DÉMARRAGE (ÉCRASE LOCAL - PAS DE FUSION)
  // Utilisée au démarrage de l'app dans main.dart
  // =========================================================================
  static Future<void> pullAndOverwriteLocal(BuildContext context) async {
    try {
      debugPrint("☁️ LOG [Cloud] : Téléchargement database cloud...");

      // 1. GET cloud (cellule B1 du Google Sheet)
      var response = await http.get(Uri.parse(_scriptUrl));

      if (response.statusCode != 200) {
        throw Exception("Erreur GET: ${response.statusCode}");
      }

      if (!response.body.startsWith("{")) {
        throw Exception("Réponse invalide (pas JSON)");
      }

      Map<String, dynamic> cloudDb = jsonDecode(response.body);

      debugPrint("✅ LOG [Cloud] : Database récupérée depuis le cloud");
      debugPrint("   - Version: ${cloudDb['version']}");
      debugPrint("   - Timestamp: ${cloudDb['timestamp']}");

      // 2. ÉCRASER SharedPreferences locales (pas de fusion)
      final prefs = await SharedPreferences.getInstance();

      // Global stats et individual stats : écriture directe
      await prefs.setString('global_faction_stats', jsonEncode(cloudDb['global_stats'] ?? {}));
      await prefs.setString('saved_trophies_v2', jsonEncode(cloudDb['individual_stats'] ?? {}));

      // IMPORTANT : Reconstruire registered_players avec la structure complète
      // car player_directory ne contient QUE phoneNumber dans le cloud
      Map<String, dynamic> individualStats = cloudDb['individual_stats'] ?? {};
      Map<String, dynamic> playerDirectory = cloudDb['player_directory'] ?? {};
      Map<String, dynamic> rebuiltRegisteredPlayers = {};

      // Pour chaque joueur dans individual_stats, créer l'entrée complète
      individualStats.forEach((playerName, stats) {
        try {
          int totalWins = (stats['totalWins'] is int) ? stats['totalWins'] : 0;
          Map<String, dynamic> roles = (stats['roles'] is Map) ? stats['roles'] : {};

          // Validation et calcul sécurisé de gamesPlayed
          int gamesPlayed = 0;
          try {
            gamesPlayed = roles.values.fold<int>(0, (sum, wins) {
              if (wins is int) return sum + wins;
              if (wins is String) return sum + (int.tryParse(wins) ?? 0);
              return sum;
            });
          } catch (e) {
            debugPrint("⚠️ LOG [Cloud] : Erreur calcul gamesPlayed pour $playerName - $e");
          }

          // Récupérer le téléphone depuis player_directory (avec fallback sécurisé)
          String? phoneNumber;
          try {
            var playerData = playerDirectory[playerName];
            phoneNumber = (playerData is Map) ? playerData['phoneNumber']?.toString() : null;
          } catch (e) {
            debugPrint("⚠️ LOG [Cloud] : Erreur récupération téléphone pour $playerName - $e");
          }

          // Récupérer les achievements (clés seulement)
          Map<String, dynamic> achievementsMap = (stats['achievements'] is Map) ? stats['achievements'] : {};
          List<String> achievementsList = achievementsMap.keys.toList();

          rebuiltRegisteredPlayers[playerName] = {
            'gamesPlayed': gamesPlayed,
            'wins': totalWins,
            'achievements': achievementsList,
            'phoneNumber': phoneNumber ?? '',
          };
        } catch (e) {
          debugPrint("⚠️ LOG [Cloud] : Erreur reconstruction joueur $playerName - $e (ignoré)");
        }
      });

      // Ajouter les joueurs qui sont seulement dans player_directory (sans stats)
      playerDirectory.forEach((playerName, data) {
        if (!rebuiltRegisteredPlayers.containsKey(playerName)) {
          rebuiltRegisteredPlayers[playerName] = {
            'gamesPlayed': 0,
            'wins': 0,
            'achievements': [],
            'phoneNumber': data['phoneNumber'],
          };
        }
      });

      await prefs.setString('registered_players', jsonEncode(rebuiltRegisteredPlayers));

      debugPrint("✅ LOG [Cloud] : Données cloud écrites en local (écrasement)");
      debugPrint("   - ${rebuiltRegisteredPlayers.length} joueurs dans registered_players");

      // 3. Mettre à jour globalPlayers (pour autocomplete)
      await _updateGlobalPlayers(rebuiltRegisteredPlayers);

      // Pas de pop-up de confirmation (silencieux)
    } catch (e) {
      debugPrint("⚠️ LOG [Cloud] : Impossible de charger le cloud - $e");
      debugPrint("   → Continuer avec données locales existantes");
      // Pas de pop-up d'erreur au démarrage (silencieux)
    }
  }

  // =========================================================================
  // B. PUSH EN FIN DE PARTIE (SANS FUSION)
  // Utilisée dans fin_screen.dart après TrophyService.recordWin()
  // Retourne true si succès, false si échec
  // =========================================================================
  static Future<bool> pushLocalToCloud(BuildContext context) async {
    try {
      debugPrint("☁️ LOG [Cloud] : Envoi database locale vers cloud...");

      // 1. Construire database depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      final globalStatsStr = prefs.getString('global_faction_stats') ?? '{}';
      final individualStatsStr = prefs.getString('saved_trophies_v2') ?? '{}';
      final registeredPlayersStr = prefs.getString('registered_players') ?? '{}';

      Map<String, dynamic> globalStats = jsonDecode(globalStatsStr);
      Map<String, dynamic> individualStats = jsonDecode(individualStatsStr);
      Map<String, dynamic> registeredPlayers = jsonDecode(registeredPlayersStr);

      // IMPORTANT : Simplifier player_directory pour ne garder QUE phoneNumber
      // (éviter doublon de données, car individual_stats contient déjà tout)
      Map<String, dynamic> playerDirectory = _buildPlayerDirectory(registeredPlayers);

      debugPrint("   - ${globalStats.length} stats globales");
      debugPrint("   - ${individualStats.length} joueurs (stats)");
      debugPrint("   - ${playerDirectory.length} joueurs (annuaire)");

      // 2. Enrichir individualStats avec rich_achievements (pour onglets visuels)
      Map<String, dynamic> enrichedStats = _enrichWithAchievements(individualStats);

      // 3. Construire payload
      Map<String, dynamic> database = {
        "version": "3.0",
        "timestamp": DateTime.now().toIso8601String(),
        "global_stats": globalStats,
        "individual_stats": enrichedStats,
        "player_directory": playerDirectory,
        "metadata": {
          "last_sync": DateTime.now().toIso8601String(),
        }
      };

      // 4. POST vers cloud
      var response = await http.post(
        Uri.parse(_scriptUrl),
        body: jsonEncode({
          "action": "update_database",
          "database": database
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        debugPrint("✅ LOG [Cloud] : Sync cloud réussie");
        // Pas de pop-up de confirmation (silencieux)
        return true; // Succès
      } else {
        throw Exception("Erreur POST: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ LOG [Cloud] : Échec sync cloud - $e");
      return false; // Échec
    }
  }

  // =========================================================================
  // C. CRÉER UNE BACKUP CLOUD
  // Utilisée dans settings_screen.dart
  // =========================================================================
  static Future<void> createCloudBackup(BuildContext context, String label) async {
    try {
      debugPrint("☁️ LOG [Cloud] : Création backup cloud - $label");

      // 1. Récupérer database actuelle depuis local
      final prefs = await SharedPreferences.getInstance();

      final globalStats = jsonDecode(prefs.getString('global_faction_stats') ?? '{}');
      final individualStats = jsonDecode(prefs.getString('saved_trophies_v2') ?? '{}');
      final registeredPlayers = jsonDecode(prefs.getString('registered_players') ?? '{}');

      // Simplifier player_directory pour ne garder QUE phoneNumber
      Map<String, dynamic> playerDirectory = _buildPlayerDirectory(registeredPlayers);

      Map<String, dynamic> database = {
        "version": "3.0",
        "timestamp": DateTime.now().toIso8601String(),
        "global_stats": globalStats,
        "individual_stats": individualStats,
        "player_directory": playerDirectory,
      };

      // 2. POST pour créer backup
      var response = await http.post(
        Uri.parse(_scriptUrl),
        body: jsonEncode({
          "action": "create_backup",
          "database": database,
          "label": label
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        debugPrint("✅ LOG [Cloud] : Backup créée - Index: ${result['backup_index']}");
        // Pas de pop-up de confirmation (silencieux)
      } else {
        throw Exception("Erreur POST: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ LOG [Cloud] : Erreur création backup - $e");
      // Pas de pop-up d'erreur (silencieux)
    }
  }

  // =========================================================================
  // D. UTILITAIRES PRIVÉS
  // =========================================================================

  // Construire playerDirectory simplifié (seulement phoneNumber) depuis registered_players
  static Map<String, dynamic> _buildPlayerDirectory(Map<String, dynamic> registeredPlayers) {
    Map<String, dynamic> playerDirectory = {};
    registeredPlayers.forEach((playerName, data) {
      playerDirectory[playerName] = {
        'phoneNumber': data['phoneNumber'],
      };
    });
    return playerDirectory;
  }

  // Enrichir avec rich_achievements (pour onglets visuels Google Sheets)
  // OPTIMISÉ : Utilise Map lookup au lieu de firstWhere() (O(n²) → O(n))
  static Map<String, dynamic> _enrichWithAchievements(Map<String, dynamic> individualStats) {
    Map<String, dynamic> enrichedStats = {};

    individualStats.forEach((name, data) {
      var pStats = Map<String, dynamic>.from(data);
      var achievementsMap = pStats['achievements'] as Map<String, dynamic>? ?? {};
      List<Map<String, dynamic>> richAchievements = [];

      achievementsMap.forEach((id, dateStr) {
        try {
          // Lookup optimisé dans le Map pré-construit
          var ach = _achievementMap[id] ?? Achievement(
            id: id,
            title: "Inconnu ($id)",
            description: "-",
            icon: "❓",
            rarity: 1,
            checkCondition: (_) => false,
          );
          richAchievements.add({
            'title': ach.title,
            'description': ach.description,
            'icon': ach.icon,
            'rarity': ach.rarity,
            'date': dateStr
          });
        } catch (_) {}
      });

      // Trier par rareté décroissante
      richAchievements.sort((a, b) => (b['rarity'] as int).compareTo(a['rarity'] as int));
      pStats['rich_achievements'] = richAchievements;
      enrichedStats[name] = pStats;
    });

    return enrichedStats;
  }

  // Mettre à jour globalPlayers depuis playerDirectory (pour autocomplete)
  static Future<void> _updateGlobalPlayers(Map<String, dynamic> playerDirectory) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> currentDirectory = globalPlayers.map((p) => p.name).toList();
    bool directoryChanged = false;

    for (String name in playerDirectory.keys) {
      if (!currentDirectory.contains(name)) {
        // Ajout seulement si pas déjà présent
        debugPrint("   + Joueur ajouté à globalPlayers: $name");
        directoryChanged = true;
        currentDirectory.add(name);
      }
    }

    if (directoryChanged) {
      // Sauvegarder la liste mise à jour
      await prefs.setStringList('saved_players_list', currentDirectory);
      debugPrint("✅ Annuaire local mis à jour (${currentDirectory.length} joueurs)");
    }
  }

}
