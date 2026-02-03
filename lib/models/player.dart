import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Player {
  String name;
  String? role;
  String team; // "village", "loups", "solo"
  bool isAlive;

  // --- FILTRE JOUEUR ACTIF ---
  bool isPlaying;
  bool isVillageChief;
  bool isRoleLocked;

  // --- NOUVEAUX CHAMPS SUCCÈS ---
  Set<String> votedAgainstHistory; // Pour "Un choix cornélien"
  bool hostedRonAldoThisTurn;      // Pour "Ramenez la coupe à la maison"
  bool wasMaisonConverted;         // Pour "Ramenez la coupe à la maison"
  int hostedEnemiesCount;          // Pour "Epstein House"
  bool isRoi;                      // Pour "Louis croix V bâton"

  // --- ÉTATS DE JEU ---
  bool isInHouse;
  bool isHouseDestroyed;
  bool isMutedDay;
  bool isImmunizedFromVote;
  bool isProtectedByPokemon;
  bool isEffectivelyAsleep;
  bool hasReturnedThisTurn; // Pour l'annonce du matin (Voyageur)
  bool travelerKilledWolf; // Pour 'traveler_sniper'
  int hostedCountThisGame; // Pour 'hotel_training'
  bool timeMasterUsedPower; // Pour 'time_perfect'
  bool tardosSuicide; // Pour 'tardos_oups'
  bool pantinClutchTriggered; // Pour le succès Clutch

  // --- NOUVEAU : Succès Fringale Nocturne ---
  bool hasSurvivedWolfBite;

  // --- NOUVEAU : Cible du Devin ---
  bool isRevealedByDevin;

  // --- ZOOKEEPER ---
  bool hasBeenHitByDart;
  bool zookeeperEffectReady;
  bool powerActiveThisTurn;

  // --- VOYAGEUR ---
  bool isInTravel;
  bool canTravelAgain;
  int travelNightsCount;
  int travelerBullets; // Munitions accumulées

  // --- ARCHIVISTE ---
  bool isAwayAsMJ;
  int mjNightsCount;
  bool needsToChooseTeam;
  bool hasUsedSwapMJ;
  int scapegoatUses;
  bool hasScapegoatPower;
  List<String> archivisteActionsUsed;

  // --- PHYL ---
  List<Player> phylTargets;

  // --- MAÎTRE DU TEMPS ---
  bool isSavedByTimeMaster;
  List<String> timeMasterTargets; // Cibles choisies par le Maître du Temps

  // --- STATS DE SESSION ---
  int votes;
  bool isVoteCancelled;
  Player? targetVote;
  int totalVotesReceivedDuringGame;

  // --- RÔLES SPÉCIFIQUES ---
  bool isFanOfRonAldo;
  int fanJoinOrder;
  bool hasBetrayedRonAldo;

  int? pantinCurseTimer;
  bool isCursed;
  bool hasSurvivedVote; // Immunité unique au premier vote

  // Dingo
  int dingoStrikeCount; // NE PAS RESET
  int dingoShotsFired;
  int dingoShotsHit;
  bool dingoSelfVotedOnly;
  bool parkingShotUnlocked;

  // Dresseur / Pokémon
  bool pokemonWillResurrect;
  bool wasRevivedInThisGame;
  bool hasUsedRevive;

  Player? lastDresseurAction;
  Player? pokemonRevengeTarget;

  // Devin
  int concentrationNights;
  String? concentrationTargetName;
  String? lastRevealedPlayerName;
  int devinRevealsCount;
  List<String> revealedPlayersHistory; // Historique pour "Double Check"
  bool hasRevealedSamePlayerTwice;

  // Enculateur du bled
  Set<String> protectedPlayersHistory; // Historique pour "Sortez couvert"
  String? lastBledTarget; // Nom de la dernière personne protégée

  // Tardos
  Player? tardosTarget;
  bool hasPlacedBomb;      // Vrai si une bombe est en cours (tic-tac)
  bool hasUsedBombPower;   // Vrai si le pouvoir a été consommé définitivement
  bool isBombed;           // Marqueur visuel sur la victime
  int bombTimer;
  int attachedBombTimer;   // Timer manuel (posé par MJ via Dev Mode)

  // Houston
  List<Player> houstonTargets;
  bool houstonApollo13Triggered; // Flag pour succès Apollo 13

  // Somnifère
  int somnifereUses;

  // Grand-mère
  int lastQuicheTurn;
  bool isVillageProtected;
  bool hasBakedQuiche;
  bool hasSavedSelfWithQuiche;

  // --- STATS GLOBALES ET SUCCÈS ---
  int roleChangesCount;
  int killsThisGame;
  int mutedPlayersCount;
  bool hasHeardWolfSecrets;
  int maxSimultaneousCurses;
  bool canacleanPresent;

  // UI
  bool isSelected;

  Player({
    required String name,
    this.role,
    this.team = "village",
    this.isAlive = true,
    this.isPlaying = false,
    this.isVillageChief = false,
    this.isRoleLocked = false,
    this.isInHouse = false,
    this.isHouseDestroyed = false,
    this.isMutedDay = false,
    this.isImmunizedFromVote = false,
    this.isProtectedByPokemon = false,
    this.isEffectivelyAsleep = false,
    this.hasReturnedThisTurn = false,
    this.isRevealedByDevin = false,
    this.pantinClutchTriggered = false,
    this.hasSurvivedWolfBite = false,
    this.hasBeenHitByDart = false,
    this.zookeeperEffectReady = false,
    this.powerActiveThisTurn = false,
    this.isInTravel = false,
    this.canTravelAgain = true,
    this.travelNightsCount = 0,
    this.travelerBullets = 0,
    this.isAwayAsMJ = false,
    this.mjNightsCount = 0,
    this.needsToChooseTeam = false,
    this.hasUsedSwapMJ = false,
    this.scapegoatUses = 1,
    this.hasScapegoatPower = false,
    this.archivisteActionsUsed = const [],
    this.phylTargets = const [],
    this.isSavedByTimeMaster = false,
    this.timeMasterTargets = const [],
    this.votes = 0,
    this.isVoteCancelled = false,
    this.travelerKilledWolf = false,
    this.hostedCountThisGame = 0,
    this.timeMasterUsedPower = false,
    this.tardosSuicide = false,
    this.targetVote,
    this.totalVotesReceivedDuringGame = 0,
    this.isFanOfRonAldo = false,
    this.fanJoinOrder = 0,
    this.hasBetrayedRonAldo = false,
    this.pantinCurseTimer,
    this.isCursed = false,
    this.hasSurvivedVote = false,
    this.dingoStrikeCount = 0,
    this.dingoShotsFired = 0,
    this.dingoShotsHit = 0,
    this.dingoSelfVotedOnly = true,
    this.parkingShotUnlocked = false,
    this.pokemonWillResurrect = false,
    this.wasRevivedInThisGame = false,
    this.hasUsedRevive = false,
    this.lastDresseurAction,
    this.pokemonRevengeTarget,
    this.concentrationNights = 0,
    this.concentrationTargetName,
    this.lastRevealedPlayerName,
    this.devinRevealsCount = 0,
    List<String>? revealedPlayersHistory,
    Set<String>? protectedPlayersHistory,
    this.lastBledTarget,
    this.hasRevealedSamePlayerTwice = false,
    this.tardosTarget,
    this.hasPlacedBomb = false,
    this.hasUsedBombPower = false,
    this.isBombed = false,
    this.bombTimer = 0,
    this.attachedBombTimer = 0,
    this.houstonTargets = const [],
    this.houstonApollo13Triggered = false,
    this.somnifereUses = 1,
    this.lastQuicheTurn = -1,
    this.isVillageProtected = false,
    this.hasBakedQuiche = false,
    this.hasSavedSelfWithQuiche = false,
    this.roleChangesCount = 0,
    this.killsThisGame = 0,
    this.mutedPlayersCount = 0,
    this.hasHeardWolfSecrets = false,
    this.maxSimultaneousCurses = 0,
    this.canacleanPresent = false,
    this.isSelected = false,

    // NOUVEAUX CHAMPS (Initialisation)
    Set<String>? votedAgainstHistory,
    this.hostedRonAldoThisTurn = false,
    this.wasMaisonConverted = false,
    this.hostedEnemiesCount = 0,
    this.isRoi = false,

  }) : name = formatName(name),
        revealedPlayersHistory = revealedPlayersHistory ?? [],
        protectedPlayersHistory = protectedPlayersHistory ?? {},
        votedAgainstHistory = votedAgainstHistory ?? {};

  static String formatName(String input) {
    if (input.trim().isEmpty) return input;
    return input.trim().split(' ').where((word) => word.isNotEmpty).map((word) {
      String cleanWord = word.toLowerCase();
      return cleanWord.split('-').map((part) {
        if (part.isEmpty) return "";
        return part[0].toUpperCase() + part.substring(1);
      }).join('-');
    }).join(' ');
  }

  bool get isWolf => team == "loups";

  void changeRole(String newRole, String newTeam) {
    debugPrint("🎭 LOG [RoleChange] : $name ($role) devient $newRole ($newTeam)");
    role = newRole;
    team = newTeam;
    roleChangesCount++;
  }

  void die(String reason) {
    if (isAlive) {
      isAlive = false;
      debugPrint("💀 LOG [Death] : $name est mort. Raison : $reason");
    }
  }

  void resetFullState() {
    role = null;
    team = "village";
    isAlive = true;
    isProtectedByPokemon = false;
    isVillageProtected = false;
    isMutedDay = false;
    isEffectivelyAsleep = false;
    hasReturnedThisTurn = false;
    isInHouse = false;
    isInTravel = false;
    canTravelAgain = true;
    travelerBullets = 0;
    somnifereUses = 1;
    votes = 0;
    timeMasterTargets = [];
    lastBledTarget = null;
    hasSurvivedWolfBite = false;
    isBombed = false;
    attachedBombTimer = 0;
    pantinCurseTimer = null;

    // RESET NOUVEAUX CHAMPS
    votedAgainstHistory = {};
    hostedRonAldoThisTurn = false;
    wasMaisonConverted = false;
    hostedEnemiesCount = 0;
    isRoi = false;
  }

  void resetTemporaryStates() {
    isMutedDay = false;
    isProtectedByPokemon = false;
    isVoteCancelled = false;
    powerActiveThisTurn = false;
    targetVote = null;
    isSelected = false;
    isSavedByTimeMaster = false;
    pokemonRevengeTarget = null;
    hasReturnedThisTurn = false;

    // RESET TEMPORAIRE
    hostedRonAldoThisTurn = false;
  }

  Widget buildStatusIcons() {
    if (!isAlive) return const SizedBox.shrink();

    List<Widget> icons = [];

    if (isVillageChief) icons.add(const Icon(Icons.workspace_premium, size: 16, color: Colors.amber));
    if (isRoi) icons.add(const Icon(FontAwesomeIcons.crown, size: 14, color: Colors.amberAccent)); // Icône Roi
    if (isInHouse) icons.add(const Icon(Icons.home, size: 16, color: Colors.orangeAccent));
    if (isProtectedByPokemon) icons.add(const Icon(Icons.bolt, size: 16, color: Colors.yellow));
    if (isEffectivelyAsleep) icons.add(const Icon(Icons.bedtime, size: 16, color: Colors.blueAccent));

    if (isRevealedByDevin) {
      icons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(Icons.remove_red_eye, size: 16, color: Colors.purpleAccent),
      ));
    }

    if (hasBeenHitByDart) icons.add(const Icon(Icons.colorize, size: 16, color: Colors.deepPurpleAccent));
    if (pantinCurseTimer != null) icons.add(const Icon(Icons.link, size: 16, color: Colors.redAccent));

    if (isBombed) {
      icons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(FontAwesomeIcons.bomb, size: 14, color: Colors.redAccent),
      ));
    }

    if (role?.toLowerCase() == "dingo" && dingoStrikeCount > 0) {
      icons.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_fixed, size: 14, color: Colors.red),
            Text(
              "$dingoStrikeCount",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ));
    }

    if (role?.toLowerCase() == "voyageur" && travelerBullets > 0) {
      icons.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.change_history, size: 14, color: Colors.cyanAccent),
            Text(
              "$travelerBullets",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'team': team,
      'isAlive': isAlive,
      'isPlaying': isPlaying,
      'isVillageChief': isVillageChief,
      'isRoleLocked': isRoleLocked,
      'isInHouse': isInHouse,
      'isHouseDestroyed': isHouseDestroyed,
      'isMutedDay': isMutedDay,
      'isImmunizedFromVote': isImmunizedFromVote,
      'isProtectedByPokemon': isProtectedByPokemon,
      'isEffectivelyAsleep': isEffectivelyAsleep,
      'isRevealedByDevin': isRevealedByDevin,
      'hasBeenHitByDart': hasBeenHitByDart,
      'zookeeperEffectReady': zookeeperEffectReady,
      'powerActiveThisTurn': powerActiveThisTurn,
      'isInTravel': isInTravel,
      'canTravelAgain': canTravelAgain,
      'travelNightsCount': travelNightsCount,
      'travelerBullets': travelerBullets,
      'isAwayAsMJ': isAwayAsMJ,
      'mjNightsCount': mjNightsCount,
      'needsToChooseTeam': needsToChooseTeam,
      'hasUsedSwapMJ': hasUsedSwapMJ,
      'scapegoatUses': scapegoatUses,
      'hasScapegoatPower': hasScapegoatPower,
      'archivisteActionsUsed': archivisteActionsUsed,
      'votes': votes,
      'isVoteCancelled': isVoteCancelled,
      'totalVotesReceivedDuringGame': totalVotesReceivedDuringGame,
      'isFanOfRonAldo': isFanOfRonAldo,
      'fanJoinOrder': fanJoinOrder,
      'hasBetrayedRonAldo': hasBetrayedRonAldo,
      'pantinCurseTimer': pantinCurseTimer,
      'isCursed': isCursed,
      'hasSurvivedVote': hasSurvivedVote,
      'dingoStrikeCount': dingoStrikeCount,
      'dingoShotsFired': dingoShotsFired,
      'dingoShotsHit': dingoShotsHit,
      'dingoSelfVotedOnly': dingoSelfVotedOnly,
      'parkingShotUnlocked': parkingShotUnlocked,
      'pokemonWillResurrect': pokemonWillResurrect,
      'wasRevivedInThisGame': wasRevivedInThisGame,
      'hasUsedRevive': hasUsedRevive,
      'concentrationNights': concentrationNights,
      'concentrationTargetName': concentrationTargetName,
      'lastRevealedPlayerName': lastRevealedPlayerName,
      'devinRevealsCount': devinRevealsCount,
      'revealedPlayersHistory': revealedPlayersHistory,
      'hasRevealedSamePlayerTwice': hasRevealedSamePlayerTwice,
      'protectedPlayersHistory': protectedPlayersHistory.toList(),
      'lastBledTarget': lastBledTarget,
      'hasPlacedBomb': hasPlacedBomb,
      'hasUsedBombPower': hasUsedBombPower,
      'isBombed': isBombed,
      'bombTimer': bombTimer,
      'attachedBombTimer': attachedBombTimer,
      'houstonApollo13Triggered': houstonApollo13Triggered,
      'somnifereUses': somnifereUses,
      'lastQuicheTurn': lastQuicheTurn,
      'isVillageProtected': isVillageProtected,
      'hasBakedQuiche': hasBakedQuiche,
      'hasSavedSelfWithQuiche': hasSavedSelfWithQuiche,
      'roleChangesCount': roleChangesCount,
      'killsThisGame': killsThisGame,
      'mutedPlayersCount': mutedPlayersCount,
      'hasHeardWolfSecrets': hasHeardWolfSecrets,
      'maxSimultaneousCurses': maxSimultaneousCurses,
      'canacleanPresent': canacleanPresent,
      'travelerKilledWolf': travelerKilledWolf,
      'hostedCountThisGame': hostedCountThisGame,
      'timeMasterUsedPower': timeMasterUsedPower,
      'tardosSuicide': tardosSuicide,
      'pantinClutchTriggered': pantinClutchTriggered,
      'timeMasterTargets': timeMasterTargets,
      'hasSurvivedWolfBite': hasSurvivedWolfBite,

      // SERIALISATION NOUVEAUX CHAMPS
      'votedAgainstHistory': votedAgainstHistory.toList(),
      'hostedRonAldoThisTurn': hostedRonAldoThisTurn,
      'wasMaisonConverted': wasMaisonConverted,
      'hostedEnemiesCount': hostedEnemiesCount,
      'isRoi': isRoi,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      name: map['name'],
      revealedPlayersHistory: List<String>.from(map['revealedPlayersHistory'] ?? []),
      protectedPlayersHistory: Set<String>.from(map['protectedPlayersHistory'] ?? []),
      votedAgainstHistory: Set<String>.from(map['votedAgainstHistory'] ?? []), // RESTAURATION
    )
      ..role = map['role']
      ..team = map['team'] ?? "village"
      ..isAlive = map['isAlive'] ?? true
      ..isPlaying = map['isPlaying'] ?? false
      ..isVillageChief = map['isVillageChief'] ?? false
      ..isRoleLocked = map['isRoleLocked'] ?? false
      ..isInHouse = map['isInHouse'] ?? false
      ..isHouseDestroyed = map['isHouseDestroyed'] ?? false
      ..isMutedDay = map['isMutedDay'] ?? false
      ..isImmunizedFromVote = map['isImmunizedFromVote'] ?? false
      ..isProtectedByPokemon = map['isProtectedByPokemon'] ?? false
      ..isEffectivelyAsleep = map['isEffectivelyAsleep'] ?? false
      ..isRevealedByDevin = map['isRevealedByDevin'] ?? false
      ..hasBeenHitByDart = map['hasBeenHitByDart'] ?? false
      ..zookeeperEffectReady = map['zookeeperEffectReady'] ?? false
      ..powerActiveThisTurn = map['powerActiveThisTurn'] ?? false
      ..isInTravel = map['isInTravel'] ?? false
      ..canTravelAgain = map['canTravelAgain'] ?? true
      ..travelNightsCount = map['travelNightsCount'] ?? 0
      ..travelerBullets = map['travelerBullets'] ?? 0
      ..isAwayAsMJ = map['isAwayAsMJ'] ?? false
      ..mjNightsCount = map['mjNightsCount'] ?? 0
      ..needsToChooseTeam = map['needsToChooseTeam'] ?? false
      ..hasUsedSwapMJ = map['hasUsedSwapMJ'] ?? false
      ..scapegoatUses = map['scapegoatUses'] ?? 1
      ..hasScapegoatPower = map['hasScapegoatPower'] ?? false
      ..archivisteActionsUsed = List<String>.from(map['archivisteActionsUsed'] ?? [])
      ..votes = map['votes'] ?? 0
      ..isVoteCancelled = map['isVoteCancelled'] ?? false
      ..totalVotesReceivedDuringGame = map['totalVotesReceivedDuringGame'] ?? 0
      ..isFanOfRonAldo = map['isFanOfRonAldo'] ?? false
      ..fanJoinOrder = map['fanJoinOrder'] ?? 0
      ..hasBetrayedRonAldo = map['hasBetrayedRonAldo'] ?? false
      ..pantinCurseTimer = map['pantinCurseTimer']
      ..isCursed = map['isCursed'] ?? false
      ..hasSurvivedVote = map['hasSurvivedVote'] ?? false
      ..dingoStrikeCount = map['dingoStrikeCount'] ?? 0
      ..dingoShotsFired = map['dingoShotsFired'] ?? 0
      ..dingoShotsHit = map['dingoShotsHit'] ?? 0
      ..dingoSelfVotedOnly = map['dingoSelfVotedOnly'] ?? true
      ..parkingShotUnlocked = map['parkingShotUnlocked'] ?? false
      ..pokemonWillResurrect = map['pokemonWillResurrect'] ?? false
      ..wasRevivedInThisGame = map['wasRevivedInThisGame'] ?? false
      ..hasUsedRevive = map['hasUsedRevive'] ?? false
      ..concentrationNights = map['concentrationNights'] ?? 0
      ..concentrationTargetName = map['concentrationTargetName']
      ..lastRevealedPlayerName = map['lastRevealedPlayerName']
      ..devinRevealsCount = map['devinRevealsCount'] ?? 0
      ..hasRevealedSamePlayerTwice = map['hasRevealedSamePlayerTwice'] ?? false
      ..hasPlacedBomb = map['hasPlacedBomb'] ?? false
      ..hasUsedBombPower = map['hasUsedBombPower'] ?? false
      ..isBombed = map['isBombed'] ?? false
      ..bombTimer = map['bombTimer'] ?? 0
      ..attachedBombTimer = map['attachedBombTimer'] ?? 0
      ..houstonApollo13Triggered = map['houstonApollo13Triggered'] ?? false
      ..somnifereUses = map['somnifereUses'] ?? 2
      ..lastQuicheTurn = map['lastQuicheTurn'] ?? -1
      ..isVillageProtected = map['isVillageProtected'] ?? false
      ..hasBakedQuiche = map['hasBakedQuiche'] ?? false
      ..hasSavedSelfWithQuiche = map['hasSavedSelfWithQuiche'] ?? false
      ..roleChangesCount = map['roleChangesCount'] ?? 0
      ..killsThisGame = map['killsThisGame'] ?? 0
      ..mutedPlayersCount = map['mutedPlayersCount'] ?? 0
      ..hasHeardWolfSecrets = map['hasHeardWolfSecrets'] ?? false
      ..maxSimultaneousCurses = map['maxSimultaneousCurses'] ?? 0
      ..canacleanPresent = map['canacleanPresent'] ?? false
      ..travelerKilledWolf = map['travelerKilledWolf'] ?? false
      ..hostedCountThisGame = map['hostedCountThisGame'] ?? 0
      ..timeMasterUsedPower = map['timeMasterUsedPower'] ?? false
      ..tardosSuicide = map['tardosSuicide'] ?? false
      ..pantinClutchTriggered = map['pantinClutchTriggered'] ?? false
      ..lastBledTarget = map['lastBledTarget']
      ..timeMasterTargets = List<String>.from(map['timeMasterTargets'] ?? [])
      ..hasSurvivedWolfBite = map['hasSurvivedWolfBite'] ?? false

    // RESTAURATION NOUVEAUX CHAMPS
      ..hostedRonAldoThisTurn = map['hostedRonAldoThisTurn'] ?? false
      ..wasMaisonConverted = map['wasMaisonConverted'] ?? false
      ..hostedEnemiesCount = map['hostedEnemiesCount'] ?? 0
      ..isRoi = map['isRoi'] ?? false;
  }
}