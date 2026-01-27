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
  static const String _keyPlayers = 'saved_trophies_v2'; // Clé V2 pour éviter conflits
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

    // Initialisation si joueur inconnu
    if (!stats.containsKey(playerName)) {
      stats[playerName] = {
        'totalWins': 0,
        'roles': {},
        'roleWins': {},
        'achievements': {}, // Map<String, String> (ID -> Date)
        'counters': {}
      };
    }

    var pData = Map<String, dynamic>.from(stats[playerName]);
    // On force le typage en Map<String, dynamic> pour éviter les erreurs de cast
    var achievements = Map<String, dynamic>.from(pData['achievements'] ?? {});

    // Si déjà débloqué, on arrête tout (false = pas nouveau)
    if (achievements.containsKey(achievementId)) {
      return false;
    }

    // Sinon, on enregistre la date et l'heure
    final now = DateTime.now();
    String timestamp = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} à ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    achievements[achievementId] = timestamp;
    pData['achievements'] = achievements;
    stats[playerName] = pData;

    await prefs.setString(_keyPlayers, jsonEncode(stats));
    return true; // true = C'est un nouveau succès !
  }

  // ==========================================================
  // 3. RÉCUPÉRATION DES SUCCÈS DÉBLOQUÉS (POUR L'UI)
  // ==========================================================
  static Future<List<String>> getUnlockedAchievements(String playerName) async {
    final stats = await getStats();
    if (!stats.containsKey(playerName)) return [];

    final pData = stats[playerName];
    if (pData['achievements'] == null) return [];

    // On retourne les clés de la map (les IDs des succès)
    return Map<String, dynamic>.from(pData['achievements']).keys.toList();
  }

  // ==========================================================
  // 4. SYSTÈME DE POP-UP EN CASCADE (QUEUE)
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
        top: 50, // Positionné en haut
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AchievementToast( // On utilise le widget dédié
            title: task.title,
            icon: task.icon,
            playerName: task.playerName,
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(entry);

    // Durée d'affichage (3.5 secondes)
    await Future.delayed(const Duration(milliseconds: 3500));

    entry.remove();
    _isDisplaying = false;

    // Si d'autres succès attendent, on les affiche
    if (context.mounted) {
      _processQueue(context);
    }
  }

  // ==========================================================
  // 5. ENREGISTREMENT DES VICTOIRES (POST-GAME)
  // ==========================================================
  static Future<void> recordWin(List<Player> winners, String roleGroup, {Map<String, dynamic>? customData}) async {
    // Anti-doublon (si on appelle 2 fois en moins de 5 secondes)
    if (_lastWinRecordTime != null) {
      final difference = DateTime.now().difference(_lastWinRecordTime!);
      if (difference < const Duration(seconds: 5)) return;
    }
    _lastWinRecordTime = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> playerStats = await getStats();
    final Set<String> processedNames = {}; // Pour éviter de compter 2 fois le même joueur

    for (var p in winners) {
      if (processedNames.contains(p.name)) continue;
      processedNames.add(p.name);

      final String name = p.name;
      final String actualRole = p.role?.toUpperCase().trim() ?? "SANS RÔLE";

      // Création ou récupération de la fiche joueur
      Map<String, dynamic> pData = playerStats.containsKey(name)
          ? Map<String, dynamic>.from(playerStats[name])
          : {
        'totalWins': 0,
        'roles': {},
        'roleWins': {},
        'achievements': {},
        'counters': {}
      };

      // Incrémentation victoire totale
      pData['totalWins'] = (pData['totalWins'] ?? 0) + 1;

      // Incrémentation victoire par Groupe (Village, Loups, Solo)
      Map<String, dynamic> rolesGroupMap = Map<String, dynamic>.from(pData['roles'] ?? {});
      rolesGroupMap[roleGroup] = (rolesGroupMap[roleGroup] ?? 0) + 1;
      pData['roles'] = rolesGroupMap;

      // Incrémentation victoire par Rôle précis (Voyante, Dresseur...)
      Map<String, dynamic> specificRoleMap = Map<String, dynamic>.from(pData['roleWins'] ?? {});
      specificRoleMap[actualRole] = (specificRoleMap[actualRole] ?? 0) + 1;
      pData['roleWins'] = specificRoleMap;

      // Mise à jour des compteurs cumulatifs (Archiviste, Voyageur...)
      var counters = Map<String, dynamic>.from(pData['counters'] ?? {});
      if (customData != null) {
        // Archiviste : Liste des pouvoirs uniques
        if (p.role == "Archiviste" && p.archivisteActionsUsed.isNotEmpty) {
          List<dynamic> history = List.from(counters['archiviste_actions_all_time'] ?? []);
          history.addAll(p.archivisteActionsUsed);
          counters['archiviste_actions_all_time'] = history.toSet().toList(); // Uniques
        }
        // Voyageur : Nombre de voyages
        if (p.travelNightsCount > 0) {
          counters['cumulative_travels'] = (counters['cumulative_travels'] ?? 0) + 1;
        }
        // Maison : Hôtes cumulés
        if ((customData['cumulative_hosted_count'] ?? 0) > 0) {
          counters['cumulative_hosted_count'] = (counters['cumulative_hosted_count'] ?? 0) + (customData['cumulative_hosted_count'] as int);
        }
      }
      pData['counters'] = counters;

      playerStats[name] = pData;
    }

    await prefs.setString(_keyPlayers, jsonEncode(playerStats));

    // Stats Globales (Camembert d'accueil)
    Map<String, int> globalStats = await getGlobalStats();
    globalStats[roleGroup] = (globalStats[roleGroup] ?? 0) + 1;
    await prefs.setString(_keyGlobalStats, jsonEncode(globalStats));
  }

  // ==========================================================
  // 6. GESTION DES DONNÉES (LECTURE / SUPPRESSION)
  // ==========================================================

  /// Supprime définitivement l'entrée JSON d'un joueur.
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