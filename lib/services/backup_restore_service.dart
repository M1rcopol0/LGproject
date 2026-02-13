import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'trophy_service.dart';

/// Service de restauration de backup depuis un fichier JSON intégré
class BackupRestoreService {
  // Restaure la backup de production depuis assets/backup_prod.json
  static Future<bool> restoreProductionBackup(BuildContext context) async {
    try {
      debugPrint("🔄 LOG [Backup] : Chargement de la backup production...");

      // 1. Charger le fichier JSON depuis les assets
      final String jsonString = await rootBundle.loadString('assets/backup_prod.json');
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // 2. Vérifier que le format est correct
      if (!backupData.containsKey('global_stats') ||
          !backupData.containsKey('individual_stats')) {
        throw Exception("Format de backup invalide");
      }

      // 3. Restaurer dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Restaurer les stats globales
      final globalStats = Map<String, dynamic>.from(backupData['global_stats']);
      await prefs.setString('global_faction_stats', jsonEncode(globalStats));
      debugPrint("✅ LOG [Backup] : Stats globales restaurées");

      // Restaurer les stats individuelles
      final individualStats = Map<String, dynamic>.from(backupData['individual_stats']);
      await prefs.setString('saved_trophies_v2', jsonEncode(individualStats));
      debugPrint("✅ LOG [Backup] : Stats individuelles restaurées (${individualStats.length} joueurs)");

      // 4. Message de confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Backup restaurée : ${individualStats.length} joueurs"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint("🎉 LOG [Backup] : Restauration terminée avec succès !");
      return true;

    } catch (e) {
      debugPrint("❌ LOG [Backup] : Erreur lors de la restauration : $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erreur de restauration : $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      return false;
    }
  }

  // Affiche une confirmation avant de restaurer
  static Future<void> showRestoreConfirmation(BuildContext context, VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("Restaurer la backup ?", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cette action va :",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "✓ Remplacer toutes les stats actuelles",
              style: TextStyle(color: Colors.white70),
            ),
            const Text(
              "✓ Restaurer les données de production",
              style: TextStyle(color: Colors.white70),
            ),
            const Text(
              "✗ Supprimer les données de test",
              style: TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                "⚠️ Cette action est irréversible !",
                style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANNULER", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text("RESTAURER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
