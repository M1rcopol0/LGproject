import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'trophy_service.dart';
import 'models/achievement.dart';
import 'models/player.dart'; // Pour update globalPlayers si besoin
import 'globals.dart';       // Pour globalPlayers

class CloudService {
  // ⚠️ VOTRE URL (Vérifiez qu'elle est à jour après le redéploiement)
  static const String _scriptUrl = "https://script.google.com/macros/s/AKfycby1YAq78gkUu8b8abXsbBlFM6N60bFHEmkLdQtgJ6ii5YfEYddmgpZAwHfpb54y3NDo/exec";

  // =========================================================================
  // FONCTION INTELLIGENTE : SYNC (PULL + MERGE + PUSH)
  // =========================================================================
  static Future<void> synchronizeData(BuildContext context) async {
    try {
      debugPrint("☁️ LOG [Cloud] : Début de la synchronisation intelligente...");

      // ---------------------------------------------------------
      // ÉTAPE 1 : TÉLÉCHARGER LES DONNÉES DU CLOUD (GET)
      // ---------------------------------------------------------
      Map<String, dynamic>? cloudData;
      try {
        var response = await http.get(Uri.parse(_scriptUrl));

        if (response.statusCode == 200) {
          // Vérifions si c'est bien du JSON
          if (response.body.startsWith("{")) {
            cloudData = jsonDecode(response.body) as Map<String, dynamic>?;
          }
        }
      } catch (e) {
        debugPrint("⚠️ Impossible de lire le Cloud (Peut-être vide ?) : $e");
      }

      // ---------------------------------------------------------
      // ÉTAPE 2 : FUSIONNER (LOCAL + CLOUD)
      // ---------------------------------------------------------
      final prefs = await SharedPreferences.getInstance();

      // Données Locales Actuelles
      final localGlobalStats = await TrophyService.getGlobalStats();
      final localPlayerStats = await TrophyService.getStats();

      // Données Cloud (Conversion sécurisée des types)
      // CORRECTION ICI : On s'assure que ce sont bien des Map<String, dynamic>
      final Map<String, dynamic> cloudGlobalStats =
      cloudData != null && cloudData['global_stats'] != null
          ? Map<String, dynamic>.from(cloudData['global_stats'])
          : {};

      final Map<String, dynamic> cloudPlayerStats =
      cloudData != null && cloudData['individual_stats'] != null
          ? Map<String, dynamic>.from(cloudData['individual_stats'])
          : {};

      // A. Fusion Global Stats (On prend le MAX pour chaque faction)
      Map<String, int> mergedGlobalStats = {
        'VILLAGE': _max(localGlobalStats['VILLAGE'] ?? 0, cloudGlobalStats['VILLAGE'] ?? 0),
        'LOUPS-GAROUS': _max(localGlobalStats['LOUPS-GAROUS'] ?? 0, cloudGlobalStats['LOUPS-GAROUS'] ?? 0),
        'SOLO': _max(localGlobalStats['SOLO'] ?? 0, cloudGlobalStats['SOLO'] ?? 0),
      };

      // B. Fusion Individual Stats (Joueur par Joueur)
      Set<String> allPlayerNames = {};
      // .keys renvoie un itérable typé String grâce au cast précédent
      allPlayerNames.addAll(localPlayerStats.keys);
      allPlayerNames.addAll(cloudPlayerStats.keys);

      Map<String, dynamic> mergedPlayerStats = {};

      for (String name in allPlayerNames) {
        var local = localPlayerStats[name] != null ? Map<String, dynamic>.from(localPlayerStats[name] as Map) : {};
        var cloud = cloudPlayerStats[name] != null ? Map<String, dynamic>.from(cloudPlayerStats[name] as Map) : {};

        // 1. Victoires : On prend le max
        int wins = _max(local['totalWins'] ?? 0, cloud['totalWins'] ?? 0);

        // 2. Rôles : Si Cloud > Local en victoires, on prend Cloud.
        Map<String, dynamic> finalRoles = (local['totalWins'] ?? 0) >= (cloud['totalWins'] ?? 0)
            ? Map<String, dynamic>.from(local['roleWins'] ?? {})
            : Map<String, dynamic>.from(cloud['roleWins'] ?? {});

        // 3. Succès : L'UNION des deux listes
        Map<String, dynamic> mergedAch = Map<String, dynamic>.from(local['achievements'] ?? {});
        Map<String, dynamic> cloudAch = Map<String, dynamic>.from(cloud['achievements'] ?? {});

        cloudAch.forEach((key, val) {
          if (!mergedAch.containsKey(key)) {
            mergedAch[key] = val;
          }
        });

        // Reconstruction de l'objet joueur
        mergedPlayerStats[name] = {
          'totalWins': wins,
          'roleWins': finalRoles,
          'achievements': mergedAch,
          'counters': local['counters'] ?? cloud['counters'] ?? {},
        };
      }

      // ---------------------------------------------------------
      // ÉTAPE 3 : SAUVEGARDER LA FUSION EN LOCAL (Mise à jour du téléphone)
      // ---------------------------------------------------------
      await prefs.setString('global_faction_stats', jsonEncode(mergedGlobalStats));
      await prefs.setString('saved_trophies_v2', jsonEncode(mergedPlayerStats));

      // Mise à jour de l'annuaire visuel
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

      debugPrint("✅ LOG [Cloud] : Fusion terminée. Données locales à jour.");

      // ---------------------------------------------------------
      // ÉTAPE 4 : PRÉPARER L'ENVOI (Données Enrichies)
      // ---------------------------------------------------------

      Map<String, dynamic> enrichedStats = {};
      mergedPlayerStats.forEach((name, data) {
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

      // ---------------------------------------------------------
      // ÉTAPE 5 : UPLOAD FINAL VERS LE CLOUD (POST)
      // ---------------------------------------------------------
      Map<String, dynamic> payload = {
        "global_stats": mergedGlobalStats,
        "individual_stats": enrichedStats, // Version enrichie
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
            const SnackBar(content: Text("☁️ Synchro terminée (Import + Export) !"), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("Erreur POST: ${postResponse.statusCode}");
      }

    } catch (e) {
      debugPrint("❌ LOG [Cloud] : Erreur globale Synchro - $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur Synchro : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  static int _max(dynamic a, dynamic b) {
    int valA = (a is int) ? a : int.tryParse(a.toString()) ?? 0;
    int valB = (b is int) ? b : int.tryParse(b.toString()) ?? 0;
    return (valA > valB) ? valA : valB;
  }

  static Future<void> uploadData(BuildContext context) async {
    await synchronizeData(context);
  }
}