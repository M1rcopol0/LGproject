import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../state/game_state.dart';

// --- PARAMETRES AUDIO ---
bool globalMusicEnabled = true;
bool globalSfxEnabled = true;
double globalVolume = 1.0;

// --- SYSTEME AUDIO ---
final AudioPlayer globalAudioPlayer = AudioPlayer();
final AudioPlayer globalMusicPlayer = AudioPlayer();

Future<void> loadAudioSettings() async {
  final prefs = await SharedPreferences.getInstance();
  globalMusicEnabled = prefs.getBool('settings_music') ?? true;
  globalSfxEnabled = prefs.getBool('settings_sfx') ?? true;
  globalVoteAnonyme = prefs.getBool('settings_vote_anonyme') ?? true;
  globalVolume = prefs.getDouble('app_volume') ?? 1.0;
}

Future<void> saveAudioSettings() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('settings_music', globalMusicEnabled);
  await prefs.setBool('settings_sfx', globalSfxEnabled);
  await prefs.setBool('settings_vote_anonyme', globalVoteAnonyme);
  await prefs.setDouble('app_volume', globalVolume);
  if (!globalMusicEnabled) stopMusic();
}

Future<void> playSfx(String fileName) async {
  if (globalSfxEnabled) {
    try {
      await globalAudioPlayer.setVolume(globalVolume);
      await globalAudioPlayer.stop();
      await globalAudioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) { debugPrint("Erreur SFX : $e"); }
  }
}

Future<void> playMusic(String fileName) async {
  if (globalMusicEnabled) {
    try {
      await globalMusicPlayer.setVolume(globalVolume * 0.5);
      await globalMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await globalMusicPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) { debugPrint("Erreur Musique : $e"); }
  }
}

Future<void> stopMusic() async {
  try { await globalMusicPlayer.stop(); } catch (e) { debugPrint("Erreur stop : $e"); }
}
