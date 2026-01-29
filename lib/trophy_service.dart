import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'models/achievement.dart';
import 'widgets/achievement_toast.dart';

class _AchievementTask {
  final Achievement achievement;
  final String playerName;
  _AchievementTask(this.achievement, this.playerName);
}

class TrophyService {
  static const String _keyPlayers = 'saved_trophies_v2';
  static const String _keyGlobalStats = 'global_faction_stats';

  // File d'attente pour les Toasts
  static final List<_AchievementTask> _achievementQueue = [];
  static bool _isDisplaying = false;

  // Cache RAM pour éviter le double affichage immédiat (spam visuel en < 5 sec)
  static final Map<String, DateTime> _recentlyShownToasts = {};

  // Sécurité anti-doublon pour l'enregistrement des victoires
  static DateTime? _lastWinRecordTime;

  // ==========================================================
  // 1. DÉVERROUILLAGE IMMÉDIAT (COEUR DU SYSTÈME)
  // ==========================================================
  static Future<void> checkAndUnlockImmediate({
    required BuildContext context,
    required String playerName,
    required String achievementId,
    required Map<String, dynamic> checkData,
  }) async {
    // 1. Récupération du succès
    Achievement? ach;
    try {
      ach = AchievementData.allAchievements.firstWhere((a) => a.id == achievementId);
    } catch (e) {
      // ID inconnu, on arrête
      return;
    }

    // 2. Vérification de la condition du jeu
    if (ach.checkCondition(checkData)) {

      // 3. Tentative de déblocage en base de données
      // Returns true = C'est une première fois.
      // Returns false = C'était déjà acquis.
      bool isBrandNew = await unlockAchievement(playerName, achievementId);
      bool shouldShowPopup = false;

      if (isBrandNew) {
        // C'est nouveau -> On affiche !
        shouldShowPopup = true;
        debugPrint("🏆 LOG [Trophy] : Nouveau succès débloqué : ${ach.title}");
      } else {
        // C'est déjà acquis -> On vérifie la date pour voir si c'est "tout frais" (< 1m30s)
        String? storedDateStr = await _getAchievementDate(playerName, achievementId);
        if (storedDateStr != null) {
          DateTime? storedDate = _parseCustomDate(storedDateStr);
          if (storedDate != null) {
            final diff = DateTime.now().difference(storedDate);
            // Si obtenu il y a moins de 90 secondes, on considère que c'est l'action actuelle
            if (diff.inSeconds < 90) {
              shouldShowPopup = true;
              debugPrint("♻️ LOG [Trophy] : Succès existant mais RÉCENT (${diff.inSeconds}s) -> Affichage autorisé.");
            } else {
              // C'est un vieux succès, on ne spamme pas
              debugPrint("⏳ LOG [Trophy] : Succès ancien (${storedDateStr}) -> Pas de pop-up.");
            }
          }
        }
      }

      // 4. Affichage avec sécurité anti-spam RAM (éviter double affichage en 1 sec)
      if (shouldShowPopup && context.mounted) {
        String ramKey = "${playerName}_$achievementId";
        DateTime? lastShownRAM = _recentlyShownToasts[ramKey];

        // Si on l'a déjà montré il y a moins de 10 secondes (RAM), on bloque
        if (lastShownRAM == null || DateTime.now().difference(lastShownRAM).inSeconds > 10) {
          _recentlyShownToasts[ramKey] = DateTime.now();
          debugPrint("🔔 LOG [Trophy] : Affichage POP-UP pour '${ach.title}' !");
          _showAchievementPopup(context, ach, playerName);
        }
      }
    }
  }

  // ==========================================================
  // 2. GESTION BASE DE DONNÉES (UNLOCK)
  // ==========================================================
  static Future<bool> unlockAchievement(String playerName, String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> stats = await getStats();

    if (!stats.containsKey(playerName)) {
      stats[playerName] = {'totalWins': 0, 'roles': {}, 'achievements': {}};
    }

    var pData = Map<String, dynamic>.from(stats[playerName]);
    var achievements = Map<String, dynamic>.from(pData['achievements'] ?? {});

    // Si déjà présent, on ne touche PAS à la date d'origine et on renvoie false
    if (achievements.containsKey(achievementId)) {
      return false;
    }

    // Nouveau -> On enregistre la date actuelle
    final now = DateTime.now();
    // Format sans les secondes (limitation actuelle conservée pour compatibilité)
    String timestamp = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} à ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    achievements[achievementId] = timestamp;
    pData['achievements'] = achievements;
    stats[playerName] = pData;

    await prefs.setString(_keyPlayers, jsonEncode(stats));
    return true;
  }

  // Helper pour récupérer la date stockée
  static Future<String?> _getAchievementDate(String playerName, String achievementId) async {
    final stats = await getStats();
    if (!stats.containsKey(playerName)) return null;
    final achievements = stats[playerName]['achievements'];
    if (achievements is Map && achievements.containsKey(achievementId)) {
      return achievements[achievementId] as String;
    }
    return null;
  }

  // Helper pour parser le format "dd/MM/yyyy à HH:mm"
  static DateTime? _parseCustomDate(String dateStr) {
    try {
      // Ex: "29/01/2026 à 16:33"
      final parts = dateStr.split(' à '); // ["29/01/2026", "16:33"]
      if (parts.length != 2) return null;

      final dateParts = parts[0].split('/'); // ["29", "01", "2026"]
      final timeParts = parts[1].split(':'); // ["16", "33"]

      if (dateParts.length != 3 || timeParts.length != 2) return null;

      return DateTime(
        int.parse(dateParts[2]), // Année
        int.parse(dateParts[1]), // Mois
        int.parse(dateParts[0]), // Jour
        int.parse(timeParts[0]), // Heure
        int.parse(timeParts[1]), // Minute
      );
    } catch (e) {
      return null;
    }
  }

  // ==========================================================
  // 3. AFFICHAGE (QUEUE)
  // ==========================================================
  static void _showAchievementPopup(BuildContext context, Achievement achievement, String playerName) {
    _achievementQueue.add(_AchievementTask(achievement, playerName));
    _processQueue(context);
  }

  static Future<void> _processQueue(BuildContext context) async {
    if (_isDisplaying || _achievementQueue.isEmpty) return;
    _isDisplaying = true;

    final task = _achievementQueue.removeAt(0);

    if (context.mounted) {
      // CORRECTION : Appel avec 3 arguments (context, achievement, playerName)
      AchievementToast.show(context, task.achievement, task.playerName);
    }

    // On laisse le temps au toast de s'afficher et disparaître
    await Future.delayed(const Duration(seconds: 4)); // Réglé à 4s pour une bonne lecture
    _isDisplaying = false;

    // Suite de la file
    if (context.mounted && _achievementQueue.isNotEmpty) {
      _processQueue(context);
    }
  }

  // ==========================================================
  // 4. AUTRES MÉTHODES (Stats, Getters...)
  // ==========================================================

  static Future<List<String>> getUnlockedAchievements(String playerName) async {
    final stats = await getStats();
    if (!stats.containsKey(playerName)) return [];
    final pData = stats[playerName];
    if (pData['achievements'] == null) return [];
    return Map<String, dynamic>.from(pData['achievements']).keys.toList();
  }

  static Future<void> recordWin(List<Player> winners, String roleGroup, {Map<String, dynamic>? customData}) async {
    if (_lastWinRecordTime != null) {
      final difference = DateTime.now().difference(_lastWinRecordTime!);
      if (difference < const Duration(seconds: 5)) return;
    }
    _lastWinRecordTime = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> playerStats = await getStats();
    final Set<String> processedNames = {};

    for (var p in winners) {
      if (processedNames.contains(p.name)) continue;
      processedNames.add(p.name);

      final String name = p.name;
      final String actualRole = p.role?.toUpperCase().trim() ?? "SANS RÔLE";

      Map<String, dynamic> pData = playerStats.containsKey(name)
          ? Map<String, dynamic>.from(playerStats[name])
          : { 'totalWins': 0, 'roles': {}, 'roleWins': {}, 'achievements': {}, 'counters': {} };

      pData['totalWins'] = (pData['totalWins'] ?? 0) + 1;

      Map<String, dynamic> rolesGroupMap = Map<String, dynamic>.from(pData['roles'] ?? {});
      rolesGroupMap[roleGroup] = (rolesGroupMap[roleGroup] ?? 0) + 1;
      pData['roles'] = rolesGroupMap;

      Map<String, dynamic> specificRoleMap = Map<String, dynamic>.from(pData['roleWins'] ?? {});
      specificRoleMap[actualRole] = (specificRoleMap[actualRole] ?? 0) + 1;
      pData['roleWins'] = specificRoleMap;

      var counters = Map<String, dynamic>.from(pData['counters'] ?? {});
      if (customData != null) {
        if (p.role == "Archiviste" && p.archivisteActionsUsed.isNotEmpty) {
          List<dynamic> history = List.from(counters['archiviste_actions_all_time'] ?? []);
          history.addAll(p.archivisteActionsUsed);
          counters['archiviste_actions_all_time'] = history.toSet().toList();
        }
        if (p.travelNightsCount > 0) {
          counters['cumulative_travels'] = (counters['cumulative_travels'] ?? 0) + 1;
        }
        if ((customData['cumulative_hosted_count'] ?? 0) > 0) {
          counters['cumulative_hosted_count'] = (counters['cumulative_hosted_count'] ?? 0) + (customData['cumulative_hosted_count'] as int);
        }
      }
      pData['counters'] = counters;
      playerStats[name] = pData;
    }

    await prefs.setString(_keyPlayers, jsonEncode(playerStats));

    Map<String, int> globalStats = await getGlobalStats();
    globalStats[roleGroup] = (globalStats[roleGroup] ?? 0) + 1;
    await prefs.setString(_keyGlobalStats, jsonEncode(globalStats));
  }

  static Future<void> deletePlayerStats(String playerName) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> stats = await getStats();
    if (stats.containsKey(playerName)) {
      stats.remove(playerName);
      await prefs.setString(_keyPlayers, jsonEncode(stats));
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_keyPlayers);
    if (data == null || data.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, int>> getGlobalStats() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_keyGlobalStats);
    Map<String, int> defaults = {'VILLAGE': 0, 'LOUPS-GAROUS': 0, 'SOLO': 0};
    if (data == null || data.isEmpty) return defaults;
    try {
      Map<String, dynamic> decoded = jsonDecode(data);
      Map<String, int> result = Map.from(defaults);
      decoded.forEach((key, value) {
        if (value is int) result[key] = value;
      });
      return result;
    } catch (e) {
      return defaults;
    }
  }

  // --- NOUVEAU : NETTOYAGE COMPLET DES SUCCÈS ---
  static Future<void> resetAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlayers);
    await prefs.remove(_keyGlobalStats);
    debugPrint("🔥 LOG [Trophy] : TOUTES les statistiques et succès ont été effacés.");
  }
}