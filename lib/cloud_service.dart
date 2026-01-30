import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'trophy_service.dart';
import 'models/achievement.dart'; // Nécessaire pour récupérer les infos statiques (titres, desc...)

class CloudService {
  // ⚠️ VOTRE URL SCRIPT ICI
  static const String _scriptUrl = "https://script.google.com/macros/s/AKfycbwax8zo2MSNXtkufe0HzGo7oMNrUBuVkDklCeoW1QI3IVkRMBiAjhPCMRFxCnaawiXM/exec";

  static Future<void> uploadData(BuildContext context) async {
    try {
      // 1. Récupération des données brutes
      final globalStats = await TrophyService.getGlobalStats();
      final rawPlayerStats = await TrophyService.getStats();

      // 2. ENRICHISSEMENT DES DONNÉES
      // On transforme les IDs de succès en objets complets (Titre, Desc, Couleur...)
      Map<String, dynamic> enrichedStats = {};

      rawPlayerStats.forEach((playerName, stats) {
        var pStats = Map<String, dynamic>.from(stats);

        // Récupération de la liste des succès acquis { "id": "date" }
        var achievementsMap = pStats['achievements'] as Map<String, dynamic>? ?? {};
        List<Map<String, dynamic>> richAchievements = [];

        achievementsMap.forEach((id, dateStr) {
          try {
            // On cherche les infos statiques dans le code
            var ach = AchievementData.allAchievements.firstWhere(
                    (a) => a.id == id,
                orElse: () => Achievement(
                    id: id, title: "Inconnu", description: "Succès retiré",
                    icon: "❓", rarity: 1, checkCondition: (_) => false
                )
            );

            richAchievements.add({
              'title': ach.title,
              'description': ach.description,
              'icon': ach.icon,
              'rarity': ach.rarity, // 1, 2, 3, 4
              'date': dateStr, // "29/01/2026 à 14:00"
            });
          } catch (e) {
            debugPrint("Erreur mapping succès $id : $e");
          }
        });

        // Optionnel : On trie par rareté (Légendaire en premier)
        richAchievements.sort((a, b) => (b['rarity'] as int).compareTo(a['rarity'] as int));

        pStats['rich_achievements'] = richAchievements;
        enrichedStats[playerName] = pStats;
      });

      // 3. Construction du paquet JSON final
      Map<String, dynamic> payload = {
        "global_stats": globalStats,
        "individual_stats": enrichedStats, // On envoie la version enrichie
        "timestamp": DateTime.now().toIso8601String(),
      };

      debugPrint("☁️ LOG [Cloud] : Envoi des données riches vers Google Sheets...");

      // 4. Envoi POST
      var response = await http.post(
        Uri.parse(_scriptUrl),
        body: jsonEncode(payload),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        debugPrint("✅ LOG [Cloud] : Synchronisation réussie !");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("☁️ Google Sheets mis à jour avec succès !"), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }

    } catch (e) {
      debugPrint("❌ LOG [Cloud] : Erreur Upload - $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de la synchro : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}