import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/achievement.dart';
import '../widgets/achievement_toast.dart';

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

  // Cache RAM pour éviter le double affichage immédiat
  static final Map<String, DateTime> _recentlyShownToasts = {};

  static DateTime? _lastWinRecordTime;

  // ==========================================================
  // 1. DÉVERROUILLAGE IMMÉDIAT
  // ==========================================================
  static Future<void> checkAndUnlockImmediate({
    required BuildContext context,
    required String playerName,
    required String achievementId,
    required Map<String, dynamic> checkData,
  }) async {
    Achievement? ach;
    try {
      ach = AchievementData.allAchievements.firstWhere((a) => a.id == achievementId);
    } catch (e) {
      return;
    }

    if (ach.checkCondition(checkData)) {
      bool isBrandNew = await unlockAchievement(playerName, achievementId);

      if (!isBrandNew) {
        debugPrint("⏳ LOG [Trophy] : Succès '${ach.title}' déjà obtenu pour $playerName -> Pas de pop-up.");
        return;
      }

      debugPrint("🏆 LOG [Trophy] : Nouveau succès débloqué : ${ach.title}");

      if (context.mounted) {
        String ramKey = "${playerName}_$achievementId";
        DateTime? lastShownRAM = _recentlyShownToasts[ramKey];

        if (lastShownRAM == null || DateTime.now().difference(lastShownRAM).inSeconds > 10) {
          _recentlyShownToasts[ramKey] = DateTime.now();
          debugPrint("🔔 LOG [Trophy] : Affichage POP-UP pour '${ach.title}' !");
          _showAchievementPopup(context, ach, playerName);
        }
      }
    }
  }

  // ==========================================================
  // 2. GESTION BASE DE DONNÉES (UNLOCK / REMOVE)
  // ==========================================================

  // Méthode pour ajouter un succès
  static Future<bool> unlockAchievement(String playerName, String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> stats = await getStats();

    if (!stats.containsKey(playerName)) {
      stats[playerName] = {'totalWins': 0, 'roles': {}, 'achievements': {}};
    }

    var pData = Map<String, dynamic>.from(stats[playerName]);
    var achievements = Map<String, dynamic>.from(pData['achievements'] ?? {});

    if (achievements.containsKey(achievementId)) {
      return false;
    }

    final now = DateTime.now();
    String timestamp = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} à ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    achievements[achievementId] = timestamp;
    pData['achievements'] = achievements;
    stats[playerName] = pData;

    await prefs.setString(_keyPlayers, jsonEncode(stats));
    return true;
  }

  // --- CELLE QUI MANQUAIT : SUPPRESSION D'UN SUCCÈS ---
  static Future<void> removeAchievement(String playerName, String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> stats = await getStats();

    if (stats.containsKey(playerName)) {
      var pData = Map<String, dynamic>.from(stats[playerName]);
      var achievements = Map<String, dynamic>.from(pData['achievements'] ?? {});

      if (achievements.containsKey(achievementId)) {
        achievements.remove(achievementId);
        pData['achievements'] = achievements;
        stats[playerName] = pData;
        await prefs.setString(_keyPlayers, jsonEncode(stats));
        debugPrint("🗑️ LOG [Trophy] : Succès '$achievementId' retiré manuellement pour $playerName.");
      }
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
      AchievementToast.show(context, task.achievement, task.playerName);
    }

    await Future.delayed(const Duration(seconds: 4));
    _isDisplaying = false;

    if (context.mounted && _achievementQueue.isNotEmpty) {
      _processQueue(context);
    }
  }

  // ==========================================================
  // 4. AUTRES MÉTHODES
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
        // cumulative_hosted_count est géré par recordGamePlayed (tous les joueurs, toutes issues)
      }
      pData['counters'] = counters;
      playerStats[name] = pData;
    }

    await prefs.setString(_keyPlayers, jsonEncode(playerStats));

    Map<String, int> globalStats = await getGlobalStats();
    globalStats[roleGroup] = (globalStats[roleGroup] ?? 0) + 1;
    await prefs.setString(_keyGlobalStats, jsonEncode(globalStats));
  }

  /// Enregistre une partie jouée pour TOUS les joueurs actifs (victoire ou défaite).
  /// Accumule :
  ///   - counters['roleGamesPlayed'][ROLE]++ (pour "redistribuer les rôles")
  ///   - counters['cumulative_hosted_count'] += hostedCountThisGame (pour "Formation hôtelière")
  static Future<void> recordGamePlayed(List<Player> allPlayers) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> playerStats = await getStats();
    final Set<String> processedNames = {};

    for (var p in allPlayers) {
      if (processedNames.contains(p.name)) continue;
      processedNames.add(p.name);
      if (p.role == null) continue;

      final String name = p.name;
      final String roleKey = p.role!.toUpperCase().trim();

      Map<String, dynamic> pData = playerStats.containsKey(name)
          ? Map<String, dynamic>.from(playerStats[name])
          : {'totalWins': 0, 'roles': {}, 'roleWins': {}, 'achievements': {}, 'counters': {}};

      var counters = Map<String, dynamic>.from(pData['counters'] ?? {});

      // Parties jouées par rôle (toutes issues confondues)
      Map<String, dynamic> roleGamesPlayed = Map<String, dynamic>.from(counters['roleGamesPlayed'] ?? {});
      roleGamesPlayed[roleKey] = (roleGamesPlayed[roleKey] ?? 0) + 1;
      counters['roleGamesPlayed'] = roleGamesPlayed;

      // Joueurs hébergés cumulés (Maison — toutes issues confondues)
      if (p.hostedCountThisGame > 0) {
        counters['cumulative_hosted_count'] =
            (counters['cumulative_hosted_count'] ?? 0) + p.hostedCountThisGame;
      }

      pData['counters'] = counters;
      playerStats[name] = pData;
    }

    await prefs.setString(_keyPlayers, jsonEncode(playerStats));
    debugPrint("📊 LOG [Trophy] : recordGamePlayed → ${allPlayers.length} joueur(s) mis à jour.");
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

  static Future<void> resetAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlayers);
    await prefs.remove(_keyGlobalStats);
    debugPrint("🔥 LOG [Trophy] : TOUTES les statistiques et succès ont été effacés.");
  }
}