import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart';
import 'models/player.dart';

class BackupService {
  // Clés identiques à celles utilisées dans TrophyService et main.dart
  static const String _keyTrophies = 'saved_trophies_v2';
  static const String _keyGlobalStats = 'global_faction_stats';
  static const String _keyPlayersList = 'saved_players_list';

  // ==========================================================
  // 1. EXPORTER TOUTE LA MÉMOIRE
  // ==========================================================
  static Future<void> exportData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // A. Récupération des données brutes
      // Cela inclut : { "Joueur": { "achievements": {"id": "date"}, "totalWins": 5, ... } }
      String? trophiesRaw = prefs.getString(_keyTrophies);
      Map<String, dynamic> individualStats = trophiesRaw != null ? jsonDecode(trophiesRaw) : {};

      String? globalStatsRaw = prefs.getString(_keyGlobalStats);
      Map<String, dynamic> globalStats = globalStatsRaw != null ? jsonDecode(globalStatsRaw) : {};

      // B. Récupération de la liste des joueurs actifs (Répertoire)
      // On utilise globalPlayers pour être sûr d'avoir la liste à jour
      List<String> playerDirectory = globalPlayers.map((p) => p.name).toList();

      // C. Construction du JSON final
      Map<String, dynamic> backupData = {
        "version": "3.0",
        "timestamp": DateTime.now().toIso8601String(),
        "player_directory": playerDirectory, // Liste des noms pour le menu
        "individual_stats": individualStats, // Contient TOUT : succès + dates + stats
        "global_stats": globalStats,         // Victoires par faction (Village vs Loups)
      };

      // D. Création du fichier temporaire
      final directory = await getTemporaryDirectory();
      String dateStr = DateTime.now().toString().split(' ')[0]; // Format YYYY-MM-DD
      final file = File('${directory.path}/loup_garou_backup_$dateStr.json');

      await file.writeAsString(jsonEncode(backupData));

      // E. Partage du fichier (Envoi par mail, Drive, etc.)
      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Sauvegarde Loup-Garou 3.0 ($dateStr)',
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        );
      }

    } catch (e) {
      debugPrint("❌ Erreur Export : $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de l'export : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================
  // 2. IMPORTER ET REMPLACER LA MÉMOIRE
  // ==========================================================
  static Future<void> importData(BuildContext context) async {
    try {
      // A. Sélection du fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        // Parsing
        Map<String, dynamic> data;
        try {
          data = jsonDecode(content);
        } catch (e) {
          throw Exception("Fichier corrompu ou format invalide.");
        }

        final prefs = await SharedPreferences.getInstance();

        // --- ÉTAPE CRITIQUE : TABLE RASE ---
        // On supprime tout avant de restaurer pour éviter les doublons ou conflits
        await prefs.remove(_keyTrophies);
        await prefs.remove(_keyGlobalStats);
        await prefs.remove(_keyPlayersList);

        // Vide la liste en mémoire vive (RAM)
        globalPlayers.clear();

        // B. Restauration du Répertoire des Joueurs
        if (data.containsKey('player_directory')) {
          List<dynamic> rawList = data['player_directory'];
          List<String> names = rawList.map((e) => e.toString()).toList();

          // Sauvegarde Disque
          await prefs.setStringList(_keyPlayersList, names);

          // Restauration RAM immédiate (pour que le menu se mette à jour)
          for (String name in names) {
            globalPlayers.add(Player(name: name));
          }
        }

        // C. Restauration des Stats Individuelles & Succès
        if (data.containsKey('individual_stats')) {
          // On remet exactement le JSON qu'on avait exporté
          // TrophyService saura le lire car il contient les clés "achievements", "totalWins", etc.
          await prefs.setString(_keyTrophies, jsonEncode(data['individual_stats']));
        }

        // D. Restauration des Stats Globales
        if (data.containsKey('global_stats')) {
          await prefs.setString(_keyGlobalStats, jsonEncode(data['global_stats']));
        }

        debugPrint("✅ Import réussi : ${globalPlayers.length} joueurs restaurés.");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sauvegarde importée avec succès !"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Erreur Import : $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur d'importation : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}