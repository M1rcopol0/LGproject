import 'package:shared_preferences/shared_preferences.dart';

// Barrel file — re-exporte tous les modules d'etat et de config
export 'config/game_config.dart';
export 'state/game_state.dart';
export 'state/night_state.dart';
export 'state/achievement_flags.dart';
export 'services/audio_service.dart';

import 'state/game_state.dart';
import 'state/night_state.dart';
import 'state/achievement_flags.dart';
import 'services/audio_service.dart';

// --- NETTOYAGE (RESET) ---
Future<void> resetAllGameData({bool eraseAllHistory = false}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('current_game_save');

  if (eraseAllHistory) {
    await prefs.remove('saved_players_list');
    await prefs.remove('saved_trophies_v2');
    await prefs.remove('global_faction_stats');
    globalPlayers.clear();
  } else {
    for (var p in globalPlayers) {
      p.isPlaying = true;
      p.isAlive = true;
      p.role = null;
      p.team = "village";
    }
  }

  resetGameState();
  resetNightState();
  resetAchievementFlags();

  stopMusic();
}
