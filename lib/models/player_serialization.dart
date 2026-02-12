import 'player.dart';

class PlayerSerializer {
  static Map<String, dynamic> toJson(Player p) {
    return {
      'name': p.name,
      'role': p.role,
      'phoneNumber': p.phoneNumber,
      'previousRole': p.previousRole,
      'team': p.team,
      'isAlive': p.isAlive,
      'isPlaying': p.isPlaying,
      'isVillageChief': p.isVillageChief,
      'isRoleLocked': p.isRoleLocked,
      'isInHouse': p.isInHouse,
      'isHouseDestroyed': p.isHouseDestroyed,
      'isMutedDay': p.isMutedDay,
      'isImmunizedFromVote': p.isImmunizedFromVote,
      'isProtectedByPokemon': p.isProtectedByPokemon,
      'isEffectivelyAsleep': p.isEffectivelyAsleep,
      'isRevealedByDevin': p.isRevealedByDevin,
      'hasBeenHitByDart': p.hasBeenHitByDart,
      'zookeeperEffectReady': p.zookeeperEffectReady,
      'powerActiveThisTurn': p.powerActiveThisTurn,
      'isInTravel': p.isInTravel,
      'canTravelAgain': p.canTravelAgain,
      'travelNightsCount': p.travelNightsCount,
      'travelerBullets': p.travelerBullets,
      'isAwayAsMJ': p.isAwayAsMJ,
      'mjNightsCount': p.mjNightsCount,
      'needsToChooseTeam': p.needsToChooseTeam,
      'hasUsedSwapMJ': p.hasUsedSwapMJ,
      'scapegoatUses': p.scapegoatUses,
      'hasScapegoatPower': p.hasScapegoatPower,
      'archivisteActionsUsed': p.archivisteActionsUsed,
      'archivisteScapegoatCharges': p.archivisteScapegoatCharges,
      'votes': p.votes,
      'isVoteCancelled': p.isVoteCancelled,
      'totalVotesReceivedDuringGame': p.totalVotesReceivedDuringGame,
      'isFanOfRonAldo': p.isFanOfRonAldo,
      'fanJoinOrder': p.fanJoinOrder,
      'hasBetrayedRonAldo': p.hasBetrayedRonAldo,
      'pantinCurseTimer': p.pantinCurseTimer,
      'isCursed': p.isCursed,
      'hasSurvivedVote': p.hasSurvivedVote,
      'dingoStrikeCount': p.dingoStrikeCount,
      'dingoShotsFired': p.dingoShotsFired,
      'dingoShotsHit': p.dingoShotsHit,
      'dingoSelfVotedOnly': p.dingoSelfVotedOnly,
      'parkingShotUnlocked': p.parkingShotUnlocked,
      'pokemonWillResurrect': p.pokemonWillResurrect,
      'wasRevivedInThisGame': p.wasRevivedInThisGame,
      'hasUsedRevive': p.hasUsedRevive,
      'concentrationNights': p.concentrationNights,
      'concentrationTargetName': p.concentrationTargetName,
      'lastRevealedPlayerName': p.lastRevealedPlayerName,
      'devinRevealsCount': p.devinRevealsCount,
      'revealedPlayersHistory': p.revealedPlayersHistory,
      'hasRevealedSamePlayerTwice': p.hasRevealedSamePlayerTwice,
      'protectedPlayersHistory': p.protectedPlayersHistory.toList(),
      'lastBledTarget': p.lastBledTarget,
      'hasPlacedBomb': p.hasPlacedBomb,
      'hasUsedBombPower': p.hasUsedBombPower,
      'isBombed': p.isBombed,
      'bombTimer': p.bombTimer,
      'attachedBombTimer': p.attachedBombTimer,
      'houstonApollo13Triggered': p.houstonApollo13Triggered,
      'somnifereUses': p.somnifereUses,
      'lastQuicheTurn': p.lastQuicheTurn,
      'isVillageProtected': p.isVillageProtected,
      'hasBakedQuiche': p.hasBakedQuiche,
      'hasSavedSelfWithQuiche': p.hasSavedSelfWithQuiche,
      'roleChangesCount': p.roleChangesCount,
      'killsThisGame': p.killsThisGame,
      'mutedPlayersCount': p.mutedPlayersCount,
      'hasHeardWolfSecrets': p.hasHeardWolfSecrets,
      'canacleanPresent': p.canacleanPresent,
      'travelerKilledWolf': p.travelerKilledWolf,
      'hostedCountThisGame': p.hostedCountThisGame,
      'tardosSuicide': p.tardosSuicide,
      'pantinClutchTriggered': p.pantinClutchTriggered,
      'timeMasterTargets': p.timeMasterTargets,
      'hasSurvivedWolfBite': p.hasSurvivedWolfBite,
      'votedAgainstHistory': p.votedAgainstHistory,
      'hostedRonAldoThisTurn': p.hostedRonAldoThisTurn,
      'wasMaisonConverted': p.wasMaisonConverted,
      'hostedEnemiesCount': p.hostedEnemiesCount,
      'isRoi': p.isRoi,
      'isProtectedBySaltimbanque': p.isProtectedBySaltimbanque,
      'isLinkedByCupidon': p.isLinkedByCupidon,
      'hasUsedSorciereRevive': p.hasUsedSorciereRevive,
      'hasUsedSorciereKill': p.hasUsedSorciereKill,
      'mustScreamKungFu': p.mustScreamKungFu,
    };
  }

  static Player fromMap(Map<String, dynamic> map) {
    return Player(
      name: map['name'],
      revealedPlayersHistory: List<String>.from(map['revealedPlayersHistory'] ?? []),
      protectedPlayersHistory: Set<String>.from(map['protectedPlayersHistory'] ?? []),
      votedAgainstHistory: List<String>.from(map['votedAgainstHistory'] ?? []),
    )
      ..role = map['role']
      ..previousRole = map['previousRole']
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
      ..archivisteScapegoatCharges = map['archivisteScapegoatCharges'] ?? 0
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
      ..canacleanPresent = map['canacleanPresent'] ?? false
      ..travelerKilledWolf = map['travelerKilledWolf'] ?? false
      ..hostedCountThisGame = map['hostedCountThisGame'] ?? 0
      ..tardosSuicide = map['tardosSuicide'] ?? false
      ..pantinClutchTriggered = map['pantinClutchTriggered'] ?? false
      ..lastBledTarget = map['lastBledTarget']
      ..timeMasterTargets = List<String>.from(map['timeMasterTargets'] ?? [])
      ..hasSurvivedWolfBite = map['hasSurvivedWolfBite'] ?? false
      ..hostedRonAldoThisTurn = map['hostedRonAldoThisTurn'] ?? false
      ..wasMaisonConverted = map['wasMaisonConverted'] ?? false
      ..hostedEnemiesCount = map['hostedEnemiesCount'] ?? 0
      ..isRoi = map['isRoi'] ?? false
      ..isProtectedBySaltimbanque = map['isProtectedBySaltimbanque'] ?? false
      ..isLinkedByCupidon = map['isLinkedByCupidon'] ?? false
      ..hasUsedSorciereRevive = map['hasUsedSorciereRevive'] ?? false
      ..hasUsedSorciereKill = map['hasUsedSorciereKill'] ?? false
      ..mustScreamKungFu = map['mustScreamKungFu'] ?? false;
  }
}
