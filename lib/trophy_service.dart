import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'models/achievement.dart';
import 'widgets/achievement_toast.dart';

/// Structure simple pour la file d'attente des notifications
class _AchievementTask {
  final String title;
  final String icon;
  final String playerName;
  _AchievementTask(this.title, this.icon, this.playerName);
}

class TrophyService {
  static const String _keyPlayers = 'saved_trophies';
  static const String _keyGlobalStats = 'global_faction_stats';

  // --- GESTION DES NOTIFICATIONS ---
  static final List<_AchievementTask> _achievementQueue = [];
  static bool _isDisplaying = false;

  // --- SÉCURITÉ ANTI-DOUBLON ---
  static DateTime? _lastWinRecordTime;

  // ==========================================================
  // 1. DÉVERROUILLAGE IMMÉDIAT (PENDANT LE JEU)
  // ==========================================================
  static Future<void> checkAndUnlockImmediate({
    required BuildContext context,
    required String playerName,
    required String achievementId,
    required Map<String, dynamic> checkData,
  }) async {
    final ach = AchievementData.allAchievements.firstWhere(
          (a) => a.id == achievementId,
      orElse: () => throw Exception("Succès $achievementId introuvable"),
    );

    if (ach.checkCondition(checkData)) {
      bool newlyUnlocked = await unlockAchievement(playerName, achievementId);

      if (newlyUnlocked && context.mounted) {
        showAchievementPopup(context, ach.title, ach.icon, playerName);
      }
    }
  }

  // ==========================================================
  // 2. DÉVERROUILLAGE SUCCÈS (DATE FIGÉE)
  // ==========================================================
  static Future<bool> unlockAchievement(String playerName, String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> stats = await getStats();

    if (!stats.containsKey(playerName)) {
      stats[playerName] = {
        'totalWins': 0,
        'roles': {},
        'roleWins': {},
        'achievements': {}
      };
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

  // ==========================================================
  // 3. SYSTÈME DE POP-UP EN CASCADE (QUEUE)
  // ==========================================================
  static void showAchievementPopup(BuildContext context, String title, String icon, String playerName) {
    _achievementQueue.add(_AchievementTask(title, icon, playerName));
    _processQueue(context);
  }

  static Future<void> _processQueue(BuildContext context) async {
    if (_isDisplaying || _achievementQueue.isEmpty) return;
    _isDisplaying = true;

    final task = _achievementQueue.removeAt(0);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0, left: 0, right: 0,
        child: TweenAnimationBuilder<Offset>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: const Offset(0, -1.2), end: const Offset(0, 0)),
          curve: Curves.easeOutBack,
          builder: (context, offset, child) {
            return FractionalTranslation(
              translation: offset,
              child: AchievementToast(
                title: task.title,
                icon: task.icon,
                playerName: task.playerName,
              ),
            );
          },
        ),
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(entry);

    await Future.delayed(const Duration(milliseconds: 3500));

    entry.remove();
    _isDisplaying = false;

    if (context.mounted) {
      _processQueue(context);
    }
  }

  // ==========================================================
  // 4. ENREGISTREMENT DES VICTOIRES (POST-GAME)
  // ==========================================================
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
          : { 'totalWins': 0, 'roles': {}, 'roleWins': {}, 'achievements': {} };

      pData['totalWins'] = (pData['totalWins'] ?? 0) + 1;

      Map<String, dynamic> rolesGroupMap = Map<String, dynamic>.from(pData['roles'] ?? {});
      rolesGroupMap[roleGroup] = (rolesGroupMap[roleGroup] ?? 0) + 1;
      pData['roles'] = rolesGroupMap;

      Map<String, dynamic> specificRoleMap = Map<String, dynamic>.from(pData['roleWins'] ?? {});
      specificRoleMap[actualRole] = (specificRoleMap[actualRole] ?? 0) + 1;
      pData['roleWins'] = specificRoleMap;

      playerStats[name] = pData;
    }

    await prefs.setString(_keyPlayers, jsonEncode(playerStats));

    Map<String, int> globalStats = await getGlobalStats();
    globalStats[roleGroup] = (globalStats[roleGroup] ?? 0) + 1;
    await prefs.setString(_keyGlobalStats, jsonEncode(globalStats));
  }

  // ==========================================================
  // 5. RÉCUPÉRATION ET SUPPRESSION (FIX BUGS STATS)
  // ==========================================================

  /// Supprime définitivement l'entrée JSON d'un joueur.
  /// Garantit qu'un nouveau joueur avec le même nom commence à zéro.
  static Future<void> deletePlayerStats(String playerName) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> stats = await getStats();

    if (stats.containsKey(playerName)) {
      stats.remove(playerName);
      await prefs.setString(_keyPlayers, jsonEncode(stats));
      debugPrint("🗑️ Données JSON effacées pour : $playerName");
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
}