import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/player.dart';
import 'globals.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GameSaveService {
  static const String _keyCurrentGame = 'current_game_save';

  // --- SAUVEGARDER L'ÉTAT ACTUEL ---
  static Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Convertir les joueurs
    List<Map<String, dynamic>> playersJson = globalPlayers.map((p) => p.toJson()).toList();

    // 2. Créer l'objet de sauvegarde
    Map<String, dynamic> saveData = {
      'timestamp': DateTime.now().toIso8601String(),
      'turn': globalTurnNumber,
      'isDayTime': isDayTime,
      'nightOnePassed': nightOnePassed,
      'rolesDistributed': globalRolesDistributed,
      'players': playersJson,

      // Flags Globaux Importants
      'anybodyDeadYet': anybodyDeadYet,
      'firstDeadPlayerName': firstDeadPlayerName,
      'wolfVotedWolf': wolfVotedWolf,
      'pokemonDiedTour1': pokemonDiedTour1,
      'pantinClutchSave': pantinClutchSave,
      'paradoxAchieved': paradoxAchieved,
      'chamanSniperAchieved': chamanSniperAchieved,
      'evolvedHungerAchieved': evolvedHungerAchieved,
      'fanSacrificeAchieved': fanSacrificeAchieved,
      'nightWolvesTargetSurvived': nightWolvesTargetSurvived,
    };

    // 3. Écrire
    await prefs.setString(_keyCurrentGame, jsonEncode(saveData));
    print("✅ Partie sauvegardée (Jour $globalTurnNumber)");
  }

  // --- VÉRIFIER SI UNE SAUVEGARDE EXISTE ---
  static Future<bool> hasSaveGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyCurrentGame);
  }

  // --- CHARGER LA PARTIE ---
  static Future<bool> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_keyCurrentGame);
      if (jsonString == null) return false;

      Map<String, dynamic> data = jsonDecode(jsonString);

      // 1. Restaurer les variables globales
      globalTurnNumber = data['turn'];
      isDayTime = data['isDayTime']; // Normalement true si on sauvegarde le matin
      nightOnePassed = data['nightOnePassed'] ?? false;
      globalRolesDistributed = data['rolesDistributed'] ?? false;

      anybodyDeadYet = data['anybodyDeadYet'] ?? false;
      firstDeadPlayerName = data['firstDeadPlayerName'];
      wolfVotedWolf = data['wolfVotedWolf'] ?? false;
      pokemonDiedTour1 = data['pokemonDiedTour1'] ?? false;
      pantinClutchSave = data['pantinClutchSave'] ?? false;
      paradoxAchieved = data['paradoxAchieved'] ?? false;
      chamanSniperAchieved = data['chamanSniperAchieved'] ?? false;
      evolvedHungerAchieved = data['evolvedHungerAchieved'] ?? false;
      fanSacrificeAchieved = data['fanSacrificeAchieved'] ?? false;
      nightWolvesTargetSurvived = data['nightWolvesTargetSurvived'] ?? false;

      // 2. Reconstruire les Joueurs (PASSE 1 : Création)
      List<dynamic> playersData = data['players'];
      List<Player> loadedPlayers = playersData.map((map) => Player.fromMap(map)).toList();

      // 3. Reconnecter les Références (PASSE 2 : Liaison)
      // On a besoin de retrouver les objets Player à partir de leurs noms sauvegardés
      for (int i = 0; i < loadedPlayers.length; i++) {
        Player p = loadedPlayers[i];
        Map<String, dynamic> map = playersData[i];

        // Helper pour trouver un joueur par nom
        Player? find(String? name) => name == null ? null : loadedPlayers.firstWhere((pl) => pl.name == name, orElse: () => Player(name: "Inconnu", isAlive: false));

        // Reconnexion Tardos
        p.tardosTarget = find(map['tardosTarget']);

        // Reconnexion Phyl (Liste)
        if (map['phylTargets'] != null) {
          p.phylTargets = (map['phylTargets'] as List).map((n) => find(n.toString())).whereType<Player>().toList();
        }

        // Reconnexion Houston (Liste)
        if (map['houstonTargets'] != null) {
          p.houstonTargets = (map['houstonTargets'] as List).map((n) => find(n.toString())).whereType<Player>().toList();
        }

        // Reconnexion Vote
        p.targetVote = find(map['targetVote']);
      }

      // 4. Mettre à jour la liste globale
      globalPlayers = loadedPlayers;
      return true;

    } catch (e) {
      print("Erreur chargement sauvegarde : $e");
      return false;
    }
  }

  // --- EFFACER LA SAUVEGARDE (Fin de partie) ---
  static Future<void> clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentGame);
  }
}