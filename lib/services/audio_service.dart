import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../state/game_state.dart';

// --- PARAMETRES AUDIO ---
bool globalMusicEnabled = true;
bool globalSfxEnabled = true;
double globalVolume = 1.0;

// --- SYSTEME AUDIO (2 pistes indépendantes) ---
final AudioPlayer globalAudioPlayer = AudioPlayer();   // SFX
final AudioPlayer globalMusicPlayer = AudioPlayer();   // Musique de fond

/// Initialise les 2 lecteurs audio.
/// Le lecteur SFX utilise AndroidAudioFocus.none pour ne pas voler le focus de la musique.
Future<void> initAudio() async {
  debugPrint("🔊 AUDIO [Init] : Initialisation des lecteurs audio.");
  try {
    await globalAudioPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        audioFocus: AndroidAudioFocus.none,
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
      ),
    ));
    debugPrint("🔊 AUDIO [Init] : SFX player configuré avec AndroidAudioFocus.none.");
  } catch (e) {
    debugPrint("🔊 AUDIO [Init] : Erreur configuration SFX player : $e");
  }

  globalMusicPlayer.onPlayerStateChanged.listen((state) {
    debugPrint("🎵 AUDIO [Musique] : État changé -> $state");
  });
  globalAudioPlayer.onPlayerStateChanged.listen((state) {
    debugPrint("🔊 AUDIO [SFX] : État changé -> $state");
  });
}

Future<void> loadAudioSettings() async {
  final prefs = await SharedPreferences.getInstance();
  globalMusicEnabled = prefs.getBool('settings_music') ?? true;
  globalSfxEnabled = prefs.getBool('settings_sfx') ?? true;
  globalVoteAnonyme = prefs.getBool('settings_vote_anonyme') ?? true;
  globalVolume = prefs.getDouble('app_volume') ?? 1.0;
  debugPrint("🔊 AUDIO [Settings] : music=$globalMusicEnabled sfx=$globalSfxEnabled volume=$globalVolume");
  await initAudio();
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
  if (!globalSfxEnabled) return;
  debugPrint("🔊 AUDIO [SFX] : Lecture -> $fileName (volume=$globalVolume)");
  try {
    await globalAudioPlayer.setVolume(globalVolume);
    await globalAudioPlayer.stop();
    await globalAudioPlayer.play(AssetSource('sounds/$fileName'));
    debugPrint("🔊 AUDIO [SFX] : play() appelé pour $fileName");
  } catch (e) {
    debugPrint("🔊 AUDIO [SFX] : Erreur -> $e");
  }
}

Future<void> playMusic(String fileName) async {
  debugPrint("🎵 AUDIO [Musique] : Demande lecture -> $fileName (enabled=$globalMusicEnabled volume=$globalVolume)");
  if (globalMusicEnabled) {
    try {
      await globalMusicPlayer.setVolume(globalVolume * 0.5);
      await globalMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await globalMusicPlayer.play(AssetSource('sounds/$fileName'));
      debugPrint("🎵 AUDIO [Musique] : play() appelé pour $fileName");
    } catch (e) {
      debugPrint("🎵 AUDIO [Musique] : Erreur -> $e");
    }
  }
}

Future<void> stopMusic() async {
  debugPrint("🎵 AUDIO [Musique] : stopMusic() appelé.");
  try {
    await globalMusicPlayer.stop();
    debugPrint("🎵 AUDIO [Musique] : stop() exécuté.");
  } catch (e) {
    debugPrint("🎵 AUDIO [Musique] : Erreur stop -> $e");
  }
}
