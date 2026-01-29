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

  // --- ÉTATS DE JEU ---
  bool isInHouse;
  bool isHouseDestroyed;
  bool isMutedDay;
  bool isImmunizedFromVote;
  bool isProtectedByPokemon;
  bool isEffectivelyAsleep;

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

  // --- MAÎTRE DU TEMPS (Nouveau correctif) ---
  bool isSavedByTimeMaster;

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

  // CORRECTION : Changement de String? à Player? pour la logique de protection
  Player? lastDresseurAction;
  // NOUVEAU : Cible de vengeance du Pokémon
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

  // Tardos
  Player? tardosTarget;
  bool hasPlacedBomb;      // Vrai si une bombe est en cours (tic-tac)
  bool hasUsedBombPower;   // Vrai si le pouvoir a été consommé définitivement
  bool isBombed;           // Marqueur visuel sur la victime
  int bombTimer;

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
    this.isRevealedByDevin = false, // Init
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
    this.votes = 0,
    this.isVoteCancelled = false,
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
    // --- CORRECTION : Utilisation de valeurs mutables ---
    List<String>? revealedPlayersHistory,
    Set<String>? protectedPlayersHistory,
    this.hasRevealedSamePlayerTwice = false,
    this.tardosTarget,
    this.hasPlacedBomb = false,
    this.hasUsedBombPower = false,
    this.isBombed = false,
    this.bombTimer = 0,
    this.houstonTargets = const [],
    this.houstonApollo13Triggered = false,
    this.somnifereUses = 2,
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
  }) : name = formatName(name),
  // Initialisation mutable pour éviter l'erreur "Unmodifiable Set"
        revealedPlayersHistory = revealedPlayersHistory ?? [],
        protectedPlayersHistory = protectedPlayersHistory ?? {};

  static String formatName(String input) {
    if (input.trim().isEmpty) return input;
    return input.trim().toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return "";
      return word.split('-').map((part) {
        if (part.isEmpty) return "";
        return part[0].toUpperCase() + part.substring(1);
      }).join('-');
    }).join(' ');
  }

  bool get isWolf => team == "loups";

  // --- LOGICIELS DE CAPTEURS ---
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

  void resetTemporaryStates() {
    isMutedDay = false;
    isProtectedByPokemon = false;
    isVoteCancelled = false;
    powerActiveThisTurn = false;
    targetVote = null;
    isSelected = false;
    isSavedByTimeMaster = false; // Reset Time Master
    // lastDresseurAction = null; // Optionnel selon persistance voulue
    pokemonRevengeTarget = null; // Reset vengeance Pokemon
    // isBombed et isRevealedByDevin persistent
  }

  // --- GÉNÉRATEUR D'ICÔNES POUR LE MENU ---
  Widget buildStatusIcons() {
    if (!isAlive) return const SizedBox.shrink();

    List<Widget> icons = [];

    if (isVillageChief) icons.add(const Icon(Icons.workspace_premium, size: 16, color: Colors.amber));
    if (isInHouse) icons.add(const Icon(Icons.home, size: 16, color: Colors.orangeAccent));
    if (isProtectedByPokemon) icons.add(const Icon(Icons.bolt, size: 16, color: Colors.yellow));
    if (isEffectivelyAsleep) icons.add(const Icon(Icons.bedtime, size: 16, color: Colors.blueAccent));

    // ICÔNE DEVIN (ŒIL)
    // S'affiche UNIQUEMENT si le rôle a été révélé
    if (isRevealedByDevin) {
      icons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(Icons.remove_red_eye, size: 16, color: Colors.purpleAccent),
      ));
    }

    if (hasBeenHitByDart) icons.add(const Icon(Icons.colorize, size: 16, color: Colors.deepPurpleAccent));
    if (pantinCurseTimer != null) icons.add(const Icon(Icons.link, size: 16, color: Colors.redAccent));

    // ICÔNE VICTIME DE BOMBE (BOMBE ROUGE)
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
            const Icon(Icons.change_history, size: 14, color: Colors.cyanAccent), // Triangle comme balle
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

  // --- JSON SERIALIZATION ---
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
      'isRevealedByDevin': isRevealedByDevin, // SAVE
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
      // Modif: On sauvegarde le nom car lastDresseurAction est maintenant un Player?
      'lastDresseurAction': lastDresseurAction?.name,
      'concentrationNights': concentrationNights,
      'concentrationTargetName': concentrationTargetName,
      'lastRevealedPlayerName': lastRevealedPlayerName,
      'devinRevealsCount': devinRevealsCount,
      'revealedPlayersHistory': revealedPlayersHistory,
      'hasRevealedSamePlayerTwice': hasRevealedSamePlayerTwice,
      'protectedPlayersHistory': protectedPlayersHistory.toList(), // Set -> List
      'hasPlacedBomb': hasPlacedBomb,
      'hasUsedBombPower': hasUsedBombPower,
      'isBombed': isBombed, // SAVE
      'bombTimer': bombTimer,
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
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      name: map['name'],
      // --- CORRECTION : Récupération en tant que structures mutables ---
      revealedPlayersHistory: List<String>.from(map['revealedPlayersHistory'] ?? []),
      protectedPlayersHistory: Set<String>.from(map['protectedPlayersHistory'] ?? []),
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
      ..isRevealedByDevin = map['isRevealedByDevin'] ?? false // LOAD
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
    // Note: On ne récupère pas lastDresseurAction ici car c'est un Player object,
    // et fromMap ne connait pas la liste des joueurs. C'est un état temporaire.
      ..concentrationNights = map['concentrationNights'] ?? 0
      ..concentrationTargetName = map['concentrationTargetName']
      ..lastRevealedPlayerName = map['lastRevealedPlayerName']
      ..devinRevealsCount = map['devinRevealsCount'] ?? 0
      ..hasRevealedSamePlayerTwice = map['hasRevealedSamePlayerTwice'] ?? false
      ..hasPlacedBomb = map['hasPlacedBomb'] ?? false
      ..hasUsedBombPower = map['hasUsedBombPower'] ?? false
      ..isBombed = map['isBombed'] ?? false // LOAD
      ..bombTimer = map['bombTimer'] ?? 0
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
      ..canacleanPresent = map['canacleanPresent'] ?? false;
  }
}