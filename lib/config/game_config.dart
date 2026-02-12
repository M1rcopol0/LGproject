import 'package:talker_flutter/talker_flutter.dart';
import '../models/player.dart';

// --- ROUTES ---
const String routeGameMenu = '/GameMenu';

// --- CONFIGURATION GENERALE ---
String globalGameVersion = "1.7.1 - Release";
late Talker globalTalker;

// --- UTILITAIRES ---
String formatPlayerName(String name) => Player.formatName(name);

// --- PICK & BAN ---
Map<String, List<String>> globalPickBan = {
  "village": [
    "Archiviste", "Devin", "Dingo", "Zookeeper", "Enculateur du bled",
    "Exorciste", "Grand-mère", "Houston", "Maison", "Tardos", "Voyageur", "Villageois",
    "Cupidon", "Sorcière", "Voyante", "Saltimbanque", "Chasseur", "Kung-Fu Panda"
  ],
  "loups": [
    "Loup-garou chaman", "Loup-garou évolué", "Somnifère",
  ],
  "solo": [
    "Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Pokémon", "Ron-Aldo"
  ],
};

// --- DEFINITION DES ACTIONS DE NUIT ---
class NightAction {
  final String role;
  final String instruction;
  final String sound;
  NightAction({required this.role, required this.instruction, this.sound = 'default_night.mp3'});
}

List<NightAction> nightActionsOrder = [
  NightAction(role: "Cupidon", instruction: "Formez le couple.", sound: "love.mp3"),
  NightAction(role: "Phyl", instruction: "Éliminez vos cibles.", sound: "writing.mp3"),
  NightAction(role: "Tardos", instruction: "Amorcez votre bombe.", sound: "fuse.mp3"),
  NightAction(role: "Dresseur", instruction: "Immobilisation immédiate, Protection ou Attaque ?", sound: "dresseur.mp3"),
  NightAction(role: "Pokémon", instruction: "Choisissez une cible à tuer si vous mourrez", sound: "pokémon.mp3"),
  NightAction(role: "Exorciste", instruction: "Mimez le bon rôle.", sound: "mime.mp3"),
  NightAction(role: "Archiviste", instruction: "Consultez les archives.", sound: "paper_scroll.mp3"),
  NightAction(role: "Maison", instruction: "Choisissez un joueur à accueillir.", sound: "door_close.mp3"),
  NightAction(role: "Saltimbanque", instruction: "Protégez quelqu'un.", sound: "shield.mp3"),
  NightAction(role: "Houston", instruction: "Choisissez deux personnes à surveiller.", sound: "radar.mp3"),
  NightAction(role: "Voyante", instruction: "Découvrez un rôle.", sound: "crystal_ball.mp3"),
  NightAction(role: "Devin", instruction: "Concentrez-vous sur un joueur.", sound: "magic_sparkle.mp3"),
  NightAction(role: "Voyageur", instruction: "Choisissez votre destination.", sound: "footsteps.mp3"),
  NightAction(role: "Loups-garous évolués", instruction: "Votez pour une victime.", sound: "wolf_howl.mp3"),
  NightAction(role: "Loup-garou chaman", instruction: "Consultez l'identité d'un joueur.", sound: "shaman_ritual.mp3"),
  NightAction(role: "Sorcière", instruction: "Utilisez vos potions.", sound: "witch_brew.mp3"),
  NightAction(role: "Maître du temps", instruction: "Éliminez deux personnes.", sound: "clock_tick.mp3"),
  NightAction(role: "Pantin", instruction: "Maudissez un joueur.", sound: "curse.mp3"),
  NightAction(role: "Dingo", instruction: "Tentez un tir.", sound: "dingo_laugh.mp3"),
  NightAction(role: "Enculateur du bled", instruction: "Protégez un joueur du vote.", sound: "unzip.mp3"),
  NightAction(role: "Kung-Fu Panda", instruction: "Désignez un joueur qui devra crier.", sound: "gong.mp3"),
  NightAction(role: "Somnifère", instruction: "Voulez-vous rendormir le village demain ?", sound: "sleep.mp3"),
  NightAction(role: "Zookeeper", instruction: "Tirez une fléchette narcoleptique.", sound: "dart.mp3"),
  NightAction(role: "Grand-mère", instruction: "Cuisinez une quiche pour demain.", sound: "rocking_chair.mp3"),
  NightAction(role: "Ron-Aldo", instruction: "Recrutez un fan.", sound: "siuuu.mp3"),
];
