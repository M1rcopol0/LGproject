import 'package:flutter/material.dart';
import 'player_serialization.dart';

class Player {
  String name;
  String? role;
  String? previousRole; // Pour suivre les conversions (ex: Maison -> Fan)
  String team; // "village", "loups", "solo"
  bool isAlive;
  String? phoneNumber; // Format: "+33612345678"

  // --- FILTRE JOUEUR ACTIF ---
  bool isPlaying;
  bool isVillageChief;
  bool isRoleLocked;

  // --- NOUVEAUX CHAMPS SUCCÈS ---
  List<String> votedAgainstHistory; // List au lieu de Set pour garder les doublons
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
  int archivisteScapegoatCharges; // NOUVEAU : Charges du pouvoir Bouc Émissaire (2)

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

  // --- NOUVEAUX RÔLES ---

  // SALTIMBANQUE
  bool isProtectedBySaltimbanque;
  Player? lastSaltimbanqueTarget;

  // CUPIDON
  bool isLinkedByCupidon;
  Player? lover;

  // ENFANT SAUVAGE
  Player? modelPlayer; // Le modèle de l'enfant sauvage

  // SORCIÈRE
  bool hasUsedSorciereRevive;
  bool hasUsedSorciereKill;

  // KUNG-FU PANDA
  bool mustScreamKungFu; // Si le joueur a été ciblé par le Panda

  // --- STATS GLOBALES ET SUCCÈS ---
  int roleChangesCount;
  int killsThisGame;
  int mutedPlayersCount;
  bool hasHeardWolfSecrets;
  bool canacleanPresent;

  // UI
  bool isSelected;

  Player({
    required String name,
    this.role,
    this.phoneNumber,
    this.previousRole,
    this.team = "village",
    this.isAlive = true,
    this.isPlaying = false, // Par défaut false pour le lobby
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
    this.archivisteScapegoatCharges = 0,
    this.phylTargets = const [],
    this.isSavedByTimeMaster = false,
    this.timeMasterTargets = const [],
    this.votes = 0,
    this.isVoteCancelled = false,
    this.travelerKilledWolf = false,
    this.hostedCountThisGame = 0,
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
    this.somnifereUses = 2,
    this.lastQuicheTurn = -1,
    this.isVillageProtected = false,
    this.hasBakedQuiche = false,
    this.hasSavedSelfWithQuiche = false,
    this.roleChangesCount = 0,
    this.killsThisGame = 0,
    this.mutedPlayersCount = 0,
    this.hasHeardWolfSecrets = false,
    this.canacleanPresent = false,
    this.isSelected = false,
    List<String>? votedAgainstHistory,
    this.hostedRonAldoThisTurn = false,
    this.wasMaisonConverted = false,
    this.hostedEnemiesCount = 0,
    this.isRoi = false,
    this.isProtectedBySaltimbanque = false,
    this.lastSaltimbanqueTarget,
    this.isLinkedByCupidon = false,
    this.lover,
    this.modelPlayer,
    this.hasUsedSorciereRevive = false,
    this.hasUsedSorciereKill = false,
    this.mustScreamKungFu = false,
  })  : name = formatName(name),
        revealedPlayersHistory = revealedPlayersHistory ?? [],
        protectedPlayersHistory = protectedPlayersHistory ?? {},
        votedAgainstHistory = votedAgainstHistory ?? [];

  // --- GETTERS & HELPERS ---

  bool get isLinked => isLinkedByCupidon;
  bool get isWolf => team == "loups";

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

  // --- MÉTHODES ---

  void changeRole(String newRole, String newTeam) {
    previousRole = role; // Sauvegarde de l'ancien rôle
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
    previousRole = null;
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
    somnifereUses = 2;
    votes = 0;
    timeMasterTargets = [];
    lastBledTarget = null;
    hasSurvivedWolfBite = false;
    isBombed = false;
    attachedBombTimer = 0;
    pantinCurseTimer = null;

    // RESET NOUVEAUX CHAMPS
    votedAgainstHistory = [];
    hostedRonAldoThisTurn = false;
    wasMaisonConverted = false;
    hostedEnemiesCount = 0;
    isRoi = false;
    archivisteActionsUsed = [];
    archivisteScapegoatCharges = 0;

    // RESET RÔLES 2.0
    isProtectedBySaltimbanque = false;
    lastSaltimbanqueTarget = null;
    isLinkedByCupidon = false;
    lover = null;
    modelPlayer = null;
    hasUsedSorciereRevive = false;
    hasUsedSorciereKill = false;
    mustScreamKungFu = false;
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
    hostedRonAldoThisTurn = false;
    isProtectedBySaltimbanque = false;
    mustScreamKungFu = false;
  }

  // Sérialisation déléguée à PlayerSerializer
  Map<String, dynamic> toJson() => PlayerSerializer.toJson(this);
  factory Player.fromMap(Map<String, dynamic> map) => PlayerSerializer.fromMap(map);
}