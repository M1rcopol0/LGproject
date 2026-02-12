import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/trophy_service.dart';
import 'models/achievement.dart';
import 'models/player.dart';
import 'globals.dart';

class CloudService {
  // ⚠️ VOTRE URL
  static const String _scriptUrl = "https://script.google.com/macros/s/AKfycbwwZHAFLcOU0liI-MbLifSFc2EZ0qxGFOpe0aipnd32NWiguM5_FLWuPoocgj6TajLQ/exec";

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

      // --- FUSION DES JOUEURS AVEC NORMALISATION DES NOMS ---
      // Cette étape permet de fusionner "claude" et "Claude" en une seule entrée
      Map<String, dynamic> mergedPlayerStats = {};

      // Fonction d'aide pour fusionner un paquet de données dans le résultat final
      void mergeIntoFinal(String rawName, Map<String, dynamic> sourceData) {
        // 1. Nettoyage du nom (ex: "claude " -> "Claude")
        String cleanName = Player.formatName(rawName);
        if (cleanName.isEmpty) return;

        // 2. Initialisation si nouveau
        if (!mergedPlayerStats.containsKey(cleanName)) {
          mergedPlayerStats[cleanName] = {
            'totalWins': 0, 'roles': {}, 'roleWins': {}, 'achievements': {}, 'counters': {}
          };
        }

        var existing = mergedPlayerStats[cleanName];
        var source = sourceData;

        // 3. Fusion des Victoires (MAX)
        existing['totalWins'] = _max(existing['totalWins'], source['totalWins'] ?? 0);

        // 4. Fusion des Groupes de Rôles (MAX par clé)
        Map<String, dynamic> sourceRoles = Map<String, dynamic>.from(source['roles'] ?? {});
        Map<String, dynamic> existingRoles = Map<String, dynamic>.from(existing['roles'] ?? {});
        sourceRoles.forEach((k, v) {
          existingRoles[k] = _max(existingRoles[k] ?? 0, v);
        });
        existing['roles'] = existingRoles;

        // 5. Fusion des Rôles Spécifiques (MAX par clé)
        Map<String, dynamic> sourceRoleWins = Map<String, dynamic>.from(source['roleWins'] ?? {});
        Map<String, dynamic> existingRoleWins = Map<String, dynamic>.from(existing['roleWins'] ?? {});
        sourceRoleWins.forEach((k, v) {
          existingRoleWins[k] = _max(existingRoleWins[k] ?? 0, v);
        });
        existing['roleWins'] = existingRoleWins;

        // 6. Fusion des Succès (UNION)
        // On garde l'ancienneté si conflit
        Map<String, dynamic> sourceAch = Map<String, dynamic>.from(source['achievements'] ?? {});
        Map<String, dynamic> existingAch = Map<String, dynamic>.from(existing['achievements'] ?? {});
        sourceAch.forEach((k, v) {
          if (!existingAch.containsKey(k)) existingAch[k] = v;
        });
        existing['achievements'] = existingAch;

        // 7. Fusion des Compteurs (MAX)
        Map<String, dynamic> sourceCounters = Map<String, dynamic>.from(source['counters'] ?? {});
        Map<String, dynamic> existingCounters = Map<String, dynamic>.from(existing['counters'] ?? {});
        sourceCounters.forEach((k, v) {
          // Pour les compteurs simples (int)
          if (v is int) {
            existingCounters[k] = _max(existingCounters[k] ?? 0, v);
          }
          // Pour les listes (ex: archiviste), on fait l'union
          else if (v is List && (existingCounters[k] is List || existingCounters[k] == null)) {
            List currentList = List.from(existingCounters[k] ?? []);
            for (var item in v) {
              if (!currentList.contains(item)) currentList.add(item);
            }
            existingCounters[k] = currentList;
          }
        });
        existing['counters'] = existingCounters;
      }

      // A. Traitement LOCAL
      localPlayerStats.forEach((key, val) {
        if (val is Map) mergeIntoFinal(key, Map<String, dynamic>.from(val));
      });

      // B. Traitement CLOUD
      cloudPlayerStats.forEach((key, val) {
        if (val is Map) mergeIntoFinal(key, Map<String, dynamic>.from(val));
      });

      // 3. SAUVEGARDER EN LOCAL
      await prefs.setString('global_faction_stats', jsonEncode(mergedGlobalStats));
      await prefs.setString('saved_trophies_v2', jsonEncode(mergedPlayerStats));

      // Mise à jour de l'annuaire (Liste des joueurs pour l'auto-complétion)
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

      // 4. ENVOYER AU CLOUD (PUSH)
      // On envoie la version propre et fusionnée
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
              orElse: () => Achievement(id: id, title: "Inconnu ($id)", description: "-", icon: "❓", rarity: 1, checkCondition: (_)=>false)
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