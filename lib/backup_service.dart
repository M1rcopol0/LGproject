import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart';
import 'models/player.dart';
import 'trophy_service.dart';

class BackupService {
  // --- EXPORTER TOUTE LA MÉMOIRE ---
  static Future<void> exportData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Récupérer les stats et succès individuels (la map des trophées)
      String? trophiesRaw = prefs.getString('saved_trophies');
      Map<String, dynamic> playerStats = trophiesRaw != null ? jsonDecode(trophiesRaw) : {};

      // 2. Récupérer les stats globales des factions
      String? globalStatsRaw = prefs.getString('global_faction_stats');
      Map<String, dynamic> globalStats = globalStatsRaw != null ? jsonDecode(globalStatsRaw) : {};

      // 3. Récupérer la liste des joueurs enregistrés (Noms du répertoire)
      List<String> playerDirectory = globalPlayers.map((p) => p.name).toList();

      // 4. Construction de l'objet JSON unique imbriquant toutes les données
      Map<String, dynamic> fullBackup = {
        "version": "3.0",
        "timestamp": DateTime.now().toIso8601String(),
        "player_directory": playerDirectory,
        "individual_stats": playerStats, // Succès + Stats individuelles
        "global_stats": globalStats,      // Victoires par faction
      };

      // 5. Écrire dans un fichier temporaire
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/wolf_memory_backup.json');
      await file.writeAsString(jsonEncode(fullBackup));

      // 6. Ouvrir la fenêtre de partage
      await Share.shareXFiles([XFile(file.path)], text: 'Sauvegarde de ma mémoire Loup-Garou 3.0');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'exportation : $e"), backgroundColor: Colors.red),
      );
    }
  }

  // --- IMPORTER ET IMBRIQUER LA MÉMOIRE ---
  static Future<void> importData(BuildContext context) async {
    try {
      // 1. Sélection du fichier JSON
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(content);

        final prefs = await SharedPreferences.getInstance();

        // A. Restauration des Stats Individuelles & Succès sur le disque
        if (data.containsKey('individual_stats')) {
          await prefs.setString('saved_trophies', jsonEncode(data['individual_stats']));
        }

        // B. Restauration des Stats Globales sur le disque
        if (data.containsKey('global_stats')) {
          await prefs.setString('global_faction_stats', jsonEncode(data['global_stats']));
        }

        // C. Restauration du Répertoire des Joueurs (Mémoire RAM + Disque)
        if (data.containsKey('player_directory')) {
          List<dynamic> names = data['player_directory'];
          List<String> stringNames = names.map((e) => e.toString()).toList();

          for (var sName in stringNames) {
            // Évite les doublons en mémoire vive
            if (!globalPlayers.any((p) => p.name == sName)) {
              globalPlayers.add(Player(name: sName));
            }
          }
          // Sauvegarde de la liste des noms pour le prochain démarrage
          await prefs.setStringList('saved_players_list', stringNames);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Mémoire restaurée : Joueurs, Stats et Succès synchronisés !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'importation : $e"), backgroundColor: Colors.red),
      );
    }
  }
}