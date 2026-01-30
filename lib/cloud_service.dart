import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'trophy_service.dart';
import 'models/achievement.dart';
import 'models/player.dart';
import 'globals.dart';

class CloudService {
  // ⚠️ VOTRE URL
  static const String _scriptUrl = "https://script.google.com/macros/s/AKfycby1YAq78gkUu8b8abXsbBlFM6N60bFHEmkLdQtgJ6ii5YfEYddmgpZAwHfpb54y3NDo/exec";

  // =========================================================================
  // A. SYNCHRONISATION INTELLIGENTE (PULL + MERGE + PUSH)
  // Utilisée au démarrage et à la fin des parties
  // =========================================================================
  static Future<void> synchronizeData(BuildContext context) async {
    try {
      debugPrint("☁️ LOG [Cloud] : Début de la synchronisation intelligente...");

      // 1. TÉLÉCHARGER (GET)
      Map<String, dynamic>? cloudData;
      try {
        var response = await http.get(Uri.parse(_scriptUrl));
        if (response.statusCode == 200 && response.body.startsWith("{")) {
          cloudData = jsonDecode(response.body) as Map<String, dynamic>?;
        }
      } catch (e) {
        debugPrint("⚠️ Impossible de lire le Cloud : $e");
      }

      // 2. FUSIONNER (MERGE)
      final prefs = await SharedPreferences.getInstance();
      final localGlobalStats = await TrophyService.getGlobalStats();
      final localPlayerStats = await TrophyService.getStats();

      final Map<String, dynamic> cloudGlobalStats =
      cloudData != null && cloudData['global_stats'] != null
          ? Map<String, dynamic>.from(cloudData['global_stats'])
          : {};

      final Map<String, dynamic> cloudPlayerStats =
      cloudData != null && cloudData['individual_stats'] != null
          ? Map<String, dynamic>.from(cloudData['individual_stats'])
          : {};

      // Fusion des stats globales
      Map<String, int> mergedGlobalStats = {
        'VILLAGE': _max(localGlobalStats['VILLAGE'] ?? 0, cloudGlobalStats['VILLAGE'] ?? 0),
        'LOUPS-GAROUS': _max(localGlobalStats['LOUPS-GAROUS'] ?? 0, cloudGlobalStats['LOUPS-GAROUS'] ?? 0),
        'SOLO': _max(localGlobalStats['SOLO'] ?? 0, cloudGlobalStats['SOLO'] ?? 0),
      };

      // Fusion des stats joueurs
      Set<String> allPlayerNames = {};
      allPlayerNames.addAll(localPlayerStats.keys);
      allPlayerNames.addAll(cloudPlayerStats.keys);

      Map<String, dynamic> mergedPlayerStats = {};

      for (String name in allPlayerNames) {
        var local = localPlayerStats[name] != null ? Map<String, dynamic>.from(localPlayerStats[name] as Map) : {};
        var cloud = cloudPlayerStats[name] != null ? Map<String, dynamic>.from(cloudPlayerStats[name] as Map) : {};

        int wins = _max(local['totalWins'] ?? 0, cloud['totalWins'] ?? 0);

        Map<String, dynamic> finalRoles = (local['totalWins'] ?? 0) >= (cloud['totalWins'] ?? 0)
            ? Map<String, dynamic>.from(local['roleWins'] ?? {})
            : Map<String, dynamic>.from(cloud['roleWins'] ?? {});

        Map<String, dynamic> mergedAch = Map<String, dynamic>.from(local['achievements'] ?? {});
        Map<String, dynamic> cloudAch = Map<String, dynamic>.from(cloud['achievements'] ?? {});
        cloudAch.forEach((key, val) {
          if (!mergedAch.containsKey(key)) mergedAch[key] = val;
        });

        mergedPlayerStats[name] = {
          'totalWins': wins,
          'roleWins': finalRoles,
          'achievements': mergedAch,
          'counters': local['counters'] ?? cloud['counters'] ?? {},
        };
      }

      // 3. SAUVEGARDER EN LOCAL
      await prefs.setString('global_faction_stats', jsonEncode(mergedGlobalStats));
      await prefs.setString('saved_trophies_v2', jsonEncode(mergedPlayerStats));

      List<String> currentDirectory = globalPlayers.map((p) => p.name).toList();
      bool directoryChanged = false;
      for (String name in mergedPlayerStats.keys) {
        if (!currentDirectory.contains(name)) {
          globalPlayers.add(Player(name: name));
          currentDirectory.add(name);
          directoryChanged = true;
        }
      }
      if (directoryChanged) {
        await prefs.setStringList('saved_players_list', currentDirectory);
      }

      // 4. ENVOYER AU CLOUD (PUSH) via la méthode commune
      await _pushToCloud(context, mergedGlobalStats, mergedPlayerStats, "Synchro terminée");

    } catch (e) {
      debugPrint("❌ LOG [Cloud] : Erreur Synchro - $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur Synchro : $e"), backgroundColor: Colors.red));
      }
    }
  }

  // =========================================================================
  // B. FORCER L'ENVOI (PUSH ONLY - ÉCRASE LE CLOUD)
  // Utilisée lors des suppressions ou reset pour nettoyer le Google Sheet
  // =========================================================================
  static Future<void> forceUploadData(BuildContext context) async {
    try {
      debugPrint("☁️ LOG [Cloud] : Forçage de l'upload (Écrasement du Cloud)...");

      // On prend juste ce qu'il y a en local (qui vient d'être nettoyé)
      final localGlobalStats = await TrophyService.getGlobalStats();
      final localPlayerStats = await TrophyService.getStats();

      // On envoie directement sans télécharger avant
      await _pushToCloud(context, localGlobalStats, localPlayerStats, "Mise à jour Cloud forcée");

    } catch (e) {
      debugPrint("❌ LOG [Cloud] : Erreur Force Upload - $e");
    }
  }

  // =========================================================================
  // C. MÉTHODE PRIVÉE D'ENVOI (POST)
  // =========================================================================
  static Future<void> _pushToCloud(BuildContext context, Map<String, dynamic> globalStats, Map<String, dynamic> playerStats, String successMessage) async {
    // Enrichissement des données pour l'affichage visuel
    Map<String, dynamic> enrichedStats = {};
    playerStats.forEach((name, data) {
      var pStats = Map<String, dynamic>.from(data);
      var achievementsMap = pStats['achievements'] as Map<String, dynamic>? ?? {};
      List<Map<String, dynamic>> richAchievements = [];

      achievementsMap.forEach((id, dateStr) {
        try {
          var ach = AchievementData.allAchievements.firstWhere(
                  (a) => a.id == id,
              orElse: () => Achievement(id: id, title: "Inconnu", description: "-", icon: "❓", rarity: 1, checkCondition: (_)=>false)
          );
          richAchievements.add({
            'title': ach.title, 'description': ach.description, 'icon': ach.icon, 'rarity': ach.rarity, 'date': dateStr
          });
        } catch (_) {}
      });

      richAchievements.sort((a, b) => (b['rarity'] as int).compareTo(a['rarity'] as int));
      pStats['rich_achievements'] = richAchievements;
      enrichedStats[name] = pStats;
    });

    Map<String, dynamic> payload = {
      "global_stats": globalStats,
      "individual_stats": enrichedStats,
      "timestamp": DateTime.now().toIso8601String(),
    };

    var postResponse = await http.post(
      Uri.parse(_scriptUrl),
      body: jsonEncode(payload),
      headers: {"Content-Type": "application/json"},
    );

    if (postResponse.statusCode == 200 || postResponse.statusCode == 302) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("☁️ $successMessage !"), backgroundColor: Colors.green),
        );
      }
    } else {
      throw Exception("Erreur POST: ${postResponse.statusCode}");
    }
  }

  static int _max(dynamic a, dynamic b) {
    int valA = (a is int) ? a : int.tryParse(a.toString()) ?? 0;
    int valB = (b is int) ? b : int.tryParse(b.toString()) ?? 0;
    return (valA > valB) ? valA : valB;
  }

  // Alias pour garder la compatibilité si appelé ailleurs
  static Future<void> uploadData(BuildContext context) async {
    await synchronizeData(context);
  }
}