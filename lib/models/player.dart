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
  bool isHouseDestroyed; // Marqueur définitif pour la Maison
  bool isMutedDay;
  bool isImmunizedFromVote;
  bool isProtectedByPokemon;
  bool isEffectivelyAsleep;

  // --- ZOOKEEPER ---
  bool hasBeenHitByDart;      // Cible touchée par le Zookeeper
  bool zookeeperEffectReady;  // Le venin s'activera à la prochaine préparation nocturne
  bool powerActiveThisTurn;   // Verrou de cycle (anti-réveil immédiat)

  // --- VOYAGEUR ---
  bool isInTravel;
  bool canTravelAgain;
  int travelNightsCount;
  int travelerBullets;

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

  // Dingo
  int dingoStrikeCount;
  int dingoShotsFired;
  int dingoShotsHit;
  bool dingoSelfVotedOnly;

  // Dresseur / Pokémon (Duo Solo)
  bool pokemonWillResurrect;
  bool wasRevivedInThisGame;
  bool hasUsedRevive; // UNIQUE UTILISATION PAR PARTIE (Dresseur)
  String? lastDresseurAction; // "IMMOBILISER", "PROTEGER", "ATTAQUE", "REVIVE"

  // Devin
  int concentrationNights;
  String? concentrationTargetName;
  String? lastRevealedPlayerName;
  int devinRevealsCount;

  // Tardos
  Player? tardosTarget;
  bool hasPlacedBomb;
  int bombTimer;

  // Houston
  List<Player> houstonTargets;

  // Somnifère
  int somnifereUses;

  // Grand-mère
  int lastQuicheTurn;
  bool isVillageProtected; // Protection active ce tour
  bool hasBakedQuiche;     // Quiche en préparation pour le tour suivant (N+1)

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

    this.votes = 0,
    this.isVoteCancelled = false,
    this.targetVote,
    this.totalVotesReceivedDuringGame = 0,

    this.isFanOfRonAldo = false,
    this.fanJoinOrder = 0,
    this.hasBetrayedRonAldo = false,

    this.pantinCurseTimer,
    this.isCursed = false,

    this.dingoStrikeCount = 0,
    this.dingoShotsFired = 0,
    this.dingoShotsHit = 0,
    this.dingoSelfVotedOnly = true,

    this.pokemonWillResurrect = false,
    this.wasRevivedInThisGame = false,
    this.hasUsedRevive = false,
    this.lastDresseurAction,

    this.concentrationNights = 0,
    this.concentrationTargetName,
    this.lastRevealedPlayerName,
    this.devinRevealsCount = 0,

    this.tardosTarget,
    this.hasPlacedBomb = false,
    this.bombTimer = 0,

    this.houstonTargets = const [],

    this.somnifereUses = 2,

    this.lastQuicheTurn = -1,
    this.isVillageProtected = false,
    this.hasBakedQuiche = false,

    this.roleChangesCount = 0,
    this.killsThisGame = 0,
    this.mutedPlayersCount = 0,
    this.hasHeardWolfSecrets = false,
    this.maxSimultaneousCurses = 0,
    this.canacleanPresent = false,

    this.isSelected = false,
  }) : name = formatName(name);

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

  void resetTemporaryStates() {
    isMutedDay = false;
    isProtectedByPokemon = false;
    isVoteCancelled = false;
    powerActiveThisTurn = false;
    // Note: isEffectivelyAsleep est géré par NightActionsLogic
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
      'dingoStrikeCount': dingoStrikeCount,
      'dingoShotsFired': dingoShotsFired,
      'dingoShotsHit': dingoShotsHit,
      'dingoSelfVotedOnly': dingoSelfVotedOnly,
      'pokemonWillResurrect': pokemonWillResurrect,
      'wasRevivedInThisGame': wasRevivedInThisGame,
      'hasUsedRevive': hasUsedRevive,
      'lastDresseurAction': lastDresseurAction,
      'concentrationNights': concentrationNights,
      'concentrationTargetName': concentrationTargetName,
      'lastRevealedPlayerName': lastRevealedPlayerName,
      'devinRevealsCount': devinRevealsCount,
      'hasPlacedBomb': hasPlacedBomb,
      'bombTimer': bombTimer,
      'somnifereUses': somnifereUses,
      'lastQuicheTurn': lastQuicheTurn,
      'isVillageProtected': isVillageProtected,
      'hasBakedQuiche': hasBakedQuiche,
      'roleChangesCount': roleChangesCount,
      'killsThisGame': killsThisGame,
      'mutedPlayersCount': mutedPlayersCount,
      'hasHeardWolfSecrets': hasHeardWolfSecrets,
      'maxSimultaneousCurses': maxSimultaneousCurses,
      'canacleanPresent': canacleanPresent,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(name: map['name'])
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
      ..dingoStrikeCount = map['dingoStrikeCount'] ?? 0
      ..dingoShotsFired = map['dingoShotsFired'] ?? 0
      ..dingoShotsHit = map['dingoShotsHit'] ?? 0
      ..dingoSelfVotedOnly = map['dingoSelfVotedOnly'] ?? true
      ..pokemonWillResurrect = map['pokemonWillResurrect'] ?? false
      ..wasRevivedInThisGame = map['wasRevivedInThisGame'] ?? false
      ..hasUsedRevive = map['hasUsedRevive'] ?? false
      ..lastDresseurAction = map['lastDresseurAction']
      ..concentrationNights = map['concentrationNights'] ?? 0
      ..concentrationTargetName = map['concentrationTargetName']
      ..lastRevealedPlayerName = map['lastRevealedPlayerName']
      ..devinRevealsCount = map['devinRevealsCount'] ?? 0
      ..hasPlacedBomb = map['hasPlacedBomb'] ?? false
      ..bombTimer = map['bombTimer'] ?? 0
      ..somnifereUses = map['somnifereUses'] ?? 2
      ..lastQuicheTurn = map['lastQuicheTurn'] ?? -1
      ..isVillageProtected = map['isVillageProtected'] ?? false
      ..hasBakedQuiche = map['hasBakedQuiche'] ?? false
      ..roleChangesCount = map['roleChangesCount'] ?? 0
      ..killsThisGame = map['killsThisGame'] ?? 0
      ..mutedPlayersCount = map['mutedPlayersCount'] ?? 0
      ..hasHeardWolfSecrets = map['hasHeardWolfSecrets'] ?? false
      ..maxSimultaneousCurses = map['maxSimultaneousCurses'] ?? 0
      ..canacleanPresent = map['canacleanPresent'] ?? false;
  }
}