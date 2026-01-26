import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'models/player.dart';

// --- ROUTES ---
const String routeGameMenu = '/GameMenu';

// --- ÉTAT DU JEU (CYCLE MODIFIÉ) ---
List<Player> globalPlayers = [];
bool isDayTime = false;            // Le jeu commence par la Nuit
int globalTurnNumber = 1;          // Nuit 1 -> Jour 1 -> Nuit 2...
double globalTimerMinutes = 2.0;
bool globalRolesDistributed = false;

// --- FLAG CHRONOLOGIE ---
bool nightOnePassed = false;

// --- FLAGS DE SUCCÈS (3.0) ---
bool anybodyDeadYet = false;
String? firstDeadPlayerName;
bool wolfVotedWolf = false;
bool pokemonDiedTour1 = false;
bool pantinClutchSave = false;
bool paradoxAchieved = false;
bool chamanSniperAchieved = false;
bool evolvedHungerAchieved = false;
bool fanSacrificeAchieved = false;
bool ultimateFanAchieved = false;
bool parkingShotUnlocked = false;

// --- TRACKING ACTIONS SPÉCIFIQUES ---
Player? nightChamanTarget;
Player? nightWolvesTarget;
bool nightWolvesTargetSurvived = false;
int wolvesNightKills = 0;
int quicheSavedThisNight = 0;

// --- PARAMÈTRES ---
bool globalMusicEnabled = true;
bool globalSfxEnabled = true;
String globalGameVersion = "3.0.0 - Stable";

// --- GESTION PERSISTANTE DES PARAMÈTRES AUDIO ---
Future<void> loadAudioSettings() async {
  final prefs = await SharedPreferences.getInstance();
  globalMusicEnabled = prefs.getBool('settings_music') ?? true;
  globalSfxEnabled = prefs.getBool('settings_sfx') ?? true;
}

Future<void> saveAudioSettings() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('settings_music', globalMusicEnabled);
  await prefs.setBool('settings_sfx', globalSfxEnabled);
  if (!globalMusicEnabled) stopMusic();
}

// --- PICK & BAN (MIS À JOUR) ---
Map<String, List<String>> globalPickBan = {
  "village": [
    "Archiviste", "Devin", "Dingo", "Zookeeper", "Enculateur du bled",
    "Exorciste", "Grand-mère", "Houston", "Maison", "Tardos", "Voyageur", "Villageois"
  ],
  "loups": [
    "Loup-garou chaman", "Loup-garou évolué", "Somnifère"
  ],
  "solo": [
    "Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Pokémon", "Ron-Aldo"
  ],
};

// --- FORMATAGE NOMS ---
String formatPlayerName(String name) => Player.formatName(name);

// --- NETTOYAGE (RESET) ---
Future<void> resetAllGameData({bool eraseAllHistory = false}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('current_game_save');

  if (eraseAllHistory) {
    await prefs.remove('saved_players_list');
    await prefs.remove('saved_trophies');
    await prefs.remove('global_faction_stats');
    await prefs.remove('registered_players');
    globalPlayers.clear();
  }

  globalTimerMinutes = 2.0;
  isDayTime = false; // Reset au cycle Nuit
  globalTurnNumber = 1;
  globalRolesDistributed = false;
  nightOnePassed = false;

  // Reset Flags Succès
  anybodyDeadYet = false;
  firstDeadPlayerName = null;
  wolfVotedWolf = false;
  pokemonDiedTour1 = false;
  pantinClutchSave = false;
  paradoxAchieved = false;
  fanSacrificeAchieved = false;
  ultimateFanAchieved = false;
  chamanSniperAchieved = false;
  evolvedHungerAchieved = false;

  // Reset Tracking
  nightChamanTarget = null;
  nightWolvesTarget = null;
  nightWolvesTargetSurvived = false;
  wolvesNightKills = 0;
  quicheSavedThisNight = 0;

  stopMusic();
}

// --- SYSTÈME AUDIO ---
final AudioPlayer globalAudioPlayer = AudioPlayer();
final AudioPlayer globalMusicPlayer = AudioPlayer();

Future<void> playSfx(String fileName) async {
  if (globalSfxEnabled) {
    try {
      await globalAudioPlayer.stop();
      await globalAudioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) { debugPrint("Erreur SFX : $e"); }
  }
}

Future<void> playMusic(String fileName) async {
  if (globalMusicEnabled) {
    try {
      await globalMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await globalMusicPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) { debugPrint("Erreur Musique : $e"); }
  }
}

Future<void> stopMusic() async {
  try { await globalMusicPlayer.stop(); } catch (e) { debugPrint("Erreur stop : $e"); }
}

// --- LOGIQUE NOCTURNE (ORDRE OPTIMISÉ) ---
class NightAction {
  final String role;
  final String instruction;
  final String sound;
  NightAction({required this.role, required this.instruction, this.sound = 'default_night.mp3'});
}

// L'ordre est stratégique : Protections/Sommeil -> Infos -> Attaques
List<NightAction> nightActionsOrder = [
  NightAction(role: "Tardos", instruction: "Amorcez votre bombe.", sound: "fuse.mp3"),
  NightAction(role: "Exorciste", instruction: "Mimez le bon rôle", sound: "mime.mp3"),
  NightAction(role: "Dresseur", instruction: "Immobilisation immédiate, Protection ou Attaque ?", sound: "pokémon.mp3"),
  NightAction(role: "Voyageur", instruction: "Choisissez votre destination.", sound: "footsteps.mp3"),
  NightAction(role: "Archiviste", instruction: "Consultez les archives.", sound: "paper_scroll.mp3"),
  NightAction(role: "Maison", instruction: "Choisissez un joueur à accueillir.", sound: "door_close.mp3"),
  NightAction(role: "Houston", instruction: "Choisissez deux personnes à surveiller.", sound: "radar.mp3"),
  NightAction(role: "Devin", instruction: "Concentrez-vous sur un joueur.", sound: "magic_sparkle.mp3"),
  NightAction(role: "Loups-garous évolués", instruction: "Les Loups votent pour une victime.", sound: "wolf_howl.mp3"),
  NightAction(role: "Loup-garou chaman", instruction: "Consultez l'identité d'un joueur.", sound: "shaman_ritual.mp3"),
  NightAction(role: "Phyl", instruction: "Éliminez vos cibles.", sound: "writing.mp3"),
  NightAction(role: "Maître du temps", instruction: "Éliminez deux personnes.", sound: "clock_tick.mp3"),
  NightAction(role: "Pantin", instruction: "Maudissez 2 joueurs.", sound: "curse.mp3"),
  NightAction(role: "Dingo", instruction: "Tentez un tir (4 succès = mort).", sound: "dingo_laugh.mp3"),
  NightAction(role: "Enculateur du bled", instruction: "Protégez un joueur du vote.", sound: "unzip.mp3"),
  NightAction(role: "Somnifère", instruction: "Voulez-vous rendormir le village demain ?", sound: "sleep.mp3"),
  NightAction(role: "Zookeeper", instruction: "Tirez une fléchette narcoleptique (effet demain).", sound: "dart.mp3"),
  NightAction(role: "Grand-mère", instruction: "Cuisinez une quiche pour demain.", sound: "rocking_chair.mp3"),
  NightAction(role: "Ron-Aldo", instruction: "Recrutez un fan. SIUUU !", sound: "siuuu.mp3"),
];