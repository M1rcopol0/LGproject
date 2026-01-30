import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int rarity; // 1: Facile, 2: Moyen, 3: Difficile, 4: Légendaire
  final bool Function(Map<String, dynamic> playerData) checkCondition;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.checkCondition,
  });

  Color get color {
    switch (rarity) {
      case 1: return Colors.blueAccent;
      case 2: return Colors.greenAccent;
      case 3: return Colors.purpleAccent;
      case 4: return Colors.amber;
      default: return Colors.grey;
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case 1: return "FACILE";
      case 2: return "INTERMÉDIAIRE";
      case 3: return "DIFFICILE";
      case 4: return "LÉGENDAIRE";
      default: return "";
    }
  }
}

class AchievementData {
  static final List<Achievement> allAchievements = [

    // ==========================================
    // VILLAGE
    // ==========================================

    // --- Archiviste ---
    Achievement(
      id: "archiviste_king",
      title: "Le roi du CDI",
      description: "Utilisez les 4 pouvoirs de l'Archiviste en une seule partie (Censure, Vote, Bouc, Transcendance).",
      icon: "👑", rarity: 4,
      checkCondition: (data) => data['archiviste_king_qualified'] == true,
    ),
    Achievement(
      id: "archiviste_prince",
      title: "Le prince du CDI",
      description: "Utilisez les 4 pouvoirs différents de l'Archiviste au cours de votre carrière.",
      icon: "📚", rarity: 2,
      checkCondition: (data) => data['archiviste_prince_qualified'] == true,
    ),

    // --- Devin ---
    Achievement(
      id: "double_check_devin",
      title: "Il fallait en être sûr...",
      description: "Révélez 2 fois le rôle du même joueur en une partie.",
      icon: "🔎", rarity: 2,
      checkCondition: (data) => data['devin_revealed_same_twice'] == true,
    ),
    Achievement(
      id: "messmerde",
      title: "Messmerde",
      description: "Survivez sans jamais exposer le rôle d'un joueur.",
      icon: "😴", rarity: 2,
      checkCondition: (data) => data['player_role']?.toLowerCase() == "devin" && data['is_player_alive'] == true && (data['devin_reveals_count'] ?? 0) == 0,
    ),

    // --- Dingo ---
    Achievement(
      id: "crazy_dingo_vote",
      title: "Le plus taré des dingos",
      description: "Votez contre vous-même à chaque vote et survivez.",
      icon: "🤪", rarity: 4,
      checkCondition: (data) =>
      data['player_role']?.toString().toLowerCase() == "dingo" &&
          data['dingo_self_voted_all_game'] == true &&
          data['is_player_alive'] == true,
    ),
    Achievement(
      id: "bad_shooter",
      title: "Mauvais tireur",
      description: "Ne réussissez aucun de vos tirs dans une partie (min. 1).",
      icon: "🎯", rarity: 1,
      checkCondition: (data) =>
      data['player_role']?.toString().toLowerCase() == "dingo" &&
          (data['dingo_shots_fired'] ?? 0) >= 1 &&
          (data['dingo_shots_hit'] ?? 0) == 0,
    ),
    Achievement(
      id: "parking_shot",
      title: "Un tir du parking !",
      description: "En tant que dingo, tuez le dernier ennemi du village.",
      icon: "🏀", rarity: 3,
      checkCondition: (data) => data['parking_shot_achieved'] == true,
    ),

    // --- Enculateur du bled ---
    Achievement(
      id: "bled_all_covered",
      title: "Sortez couvert !",
      description: "Violez tous les joueurs d'une partie au moins une fois.",
      icon: "🍆", rarity: 4,
      checkCondition: (data) => data['bled_protected_everyone'] == true,
    ),

    // --- Exorciste ---
    Achievement(
      id: "mime_win",
      title: "Vite fait, bien fait !",
      description: "Faites gagner le village grâce à vos talents de mime.",
      icon: "🎭", rarity: 3,
      checkCondition: (data) => data['exorcisme_success_win'] == true,
    ),

    // --- Grand-mère ---
    Achievement(
      id: "self_quiche_save",
      title: "Le petit chaperon rouge",
      description: "Survivez à la nuit grâce à votre propre quiche.",
      icon: "👵", rarity: 2,
      checkCondition: (data) => data['player_role']?.toLowerCase() == "grand-mère" && data['saved_by_own_quiche'] == true,
    ),
    Achievement(
      id: "quiche_hero",
      title: "Quiche ou tarte ?",
      description: "Prévenez le meurtre de 4 joueurs en une seule nuit.",
      icon: "🥧", rarity: 3,
      checkCondition: (data) => data['quiche_saved_count'] != null && (data['quiche_saved_count'] as int) >= 4,
    ),

    // --- Houston ---
    Achievement(
      id: "apollo_13",
      title: "Apollo 13",
      description: "Désignez un loup et un rôle solo en même temps.",
      icon: "🚀", rarity: 2,
      checkCondition: (data) => data['houstonApollo13Triggered'] == true,
    ),

    // --- Maison ---

    Achievement(
      id: "house_collapse",
      title: "Assurance Tous Risques",
      description: "Votre maison s'est effondrée pour protéger un invité d'une attaque mortelle.",
      icon: "🧱", rarity: 1,
      checkCondition: (data) => false, // Déclenché manuellement par Logic.eliminatePlayer
    ),

    Achievement(
      id: "crazy_casa",
      title: "Crazy Casa",
      description: "En tant que maison, survivez à la partie.",
      icon: "🏡", rarity: 3,
      checkCondition: (data) => data['player_role']?.toLowerCase() == "maison" && data['winner_role'] == "VILLAGE" && data['is_player_alive'] == true,
    ),
    Achievement(
      id: "welcome_wolf",
      title: "La prochaine fois je n'ouvrirai pas...",
      description: "Accueillez un loup-garou dans votre maison.",
      icon: "🐺", rarity: 2,
      checkCondition: (data) => data['maison_hosted_wolf'] == true,
    ),
    Achievement(
      id: "house_fast_death",
      title: "Vous auriez pu toquer !",
      description: "En tant que maison, mourrez dès la première nuit.",
      icon: "🏚️", rarity: 2,
      checkCondition: (data) => data['player_role']?.toLowerCase() == "maison" && data['turn_count'] == 1 && data['death_cause'] == "direct_hit",
    ),

    // --- Tardos ---
    Achievement(
      id: "tardos_oups",
      title: "Oups...",
      description: "Faites exploser votre propre bombe à la figure.",
      icon: "💥", rarity: 2,
      checkCondition: (data) => data['tardos_suicide'] == true,
    ),

    // --- Voyageur ---
    Achievement(
      id: "traveler_sniper",
      title: "I'm back.",
      description: "Au retour de votre voyage, éliminez un loup-garou.",
      icon: "🔫", rarity: 2,
      checkCondition: (data) => data['traveler_killed_wolf'] == true,
    ),

    // ==========================================
    // LOUPS
    // ==========================================

    // --- Général ---
    Achievement(
      id: "pack_fast_food",
      title: "Fast Food",
      description: "En tant que loup, gagner avant le Jour 4.",
      icon: "🍔", rarity: 2,
      checkCondition: (data) =>
      data['is_wolf_faction'] == true && data['winner_role'] == "LOUPS-GAROUS" && data['turn_count'] < 4,
    ),
    Achievement(
      id: "pack_unbreakable",
      title: "Meute Soudée",
      description: "Gagner sans qu'aucun loup n'ait voté contre un autre loup.",
      icon: "🐾", rarity: 3,
      checkCondition: (data) =>
      data['is_wolf_faction'] == true && data['winner_role'] == "LOUPS-GAROUS" && data['no_friendly_fire_vote'] == true,
    ),

    // --- Loup-garou chaman ---
    Achievement(
      id: "chaman_sniper",
      title: "Exécution Ciblée",
      description: "En tant que Loup-garou chaman, tuez au vote une personne espionnée la nuit précédente.",
      icon: "🎯", rarity: 2,
      checkCondition: (data) => data['chaman_sniper_achieved'] == true,
    ),
    Achievement(
      id: "chaman_double_agent",
      title: "Infiltration Totale",
      description: "Gagner sans avoir reçu le moindre vote contre vous en tant que Loup-garou chaman.",
      icon: "👤", rarity: 4,
      checkCondition: (data) =>
      data['player_role'] == "Loup-garou chaman" && data['winner_role'] == "LOUPS-GAROUS" && (data['totalVotesReceivedDuringGame'] ?? 0) == 0,
    ),

    // --- Loup-garou évolué ---
    Achievement(
      id: "evolved_alpha",
      title: "Alpha Dominant",
      description: "Gagner en étant le dernier loup vivant.",
      icon: "👑", rarity: 3,
      checkCondition: (data) =>
      data['is_wolf_faction'] == true &&
          data['winner_role'] == "LOUPS-GAROUS" &&
          data['wolves_alive_count'] == 1 &&
          data['is_player_alive'] == true,
    ),
    Achievement(
      id: "evolved_hunger",
      title: "Fringale Nocturne",
      description: "La victime survit à votre morsure nocturne mais meurt au vote suivant.",
      icon: "🩸", rarity: 3,
      checkCondition: (data) => data['evolved_hunger_achieved'] == true,
    ),
    Achievement(
      id: "clean_paws",
      title: "Montrez patte blanche",
      description: "Gagnez sans tuer personne la nuit.",
      icon: "🐾", rarity: 4,
      checkCondition: (data) => data['is_wolf_faction'] == true && data['winner_role'] == "LOUPS-GAROUS" && data['wolves_night_kills'] == 0,
    ),

    // --- Somnifère ---
    Achievement(
      id: "somni_blackout",
      title: "Nuit Éternelle",
      description: "En tant que Somnifère, gagner après avoir utilisé votre potion.",
      icon: "💤", rarity: 2,
      checkCondition: (data) =>
      data['player_role'] == "Somnifère" && data['winner_role'] == "LOUPS-GAROUS" && (data['somnifere_uses_left'] ?? 1) == 0,
    ),

    // ==========================================
    // SOLO
    // ==========================================

    // --- Dresseur & Pokémon ---
    Achievement(
      id: "pokemon_fail",
      title: "C'est pas très efficace...",
      description: "Le Pokémon meurt dès le tour 1 (Nuit ou Jour).",
      icon: "⚰️", rarity: 1,
      checkCondition: (data) =>
      (data['player_role']?.toString().toLowerCase() == "pokémon" ||
          data['player_role']?.toString().toLowerCase() == "dresseur") &&
          data['pokemon_died_t1'] == true,
    ),
    Achievement(
      id: "master_no_pokemon",
      title: "Maître sans Pokémon",
      description: "Gagner en tant que Dresseur alors que le Pokémon est mort la première nuit.",
      icon: "👊", rarity: 3,
      checkCondition: (data) =>
      (data['player_role'] == "Dresseur") && (data['winner_role'] == "DRESSEUR") && (data['pokemon_died_t1'] == true),
    ),
    Achievement(
      id: "electric_phoenix",
      title: "Phénix Électrique",
      description: "Ressusciter et gagner en tant que Pokémon.",
      icon: "🐦‍🔥", rarity: 2,
      checkCondition: (data) =>
      (data['player_role'] == "Pokémon") && (data['winner_role'] == "DRESSEUR") && (data['was_revived'] == true),
    ),

    // --- Maître du temps ---
    Achievement(
      id: "time_paradox",
      title: "Paradoxe Temporel",
      description: "En tant que Maître du temps, tuer deux personnes de camps opposés la même nuit.",
      icon: "⏳", rarity: 2,
      checkCondition: (data) => data['paradox_achieved'] == true,
    ),
    Achievement(
      id: "time_master_clean",
      title: "Synchronisation Parfaite",
      description: "Gagner sans jamais utiliser votre pouvoir.",
      icon: "🕰️", rarity: 3,
      checkCondition: (data) =>
      data['player_role'] == "Maître du temps" &&
          data['winner_role'] == "MAÎTRE DU TEMPS" &&
          data['time_master_used_power'] == false,
    ),
    Achievement(
      id: "time_perfect",
      title: "Timing Précis",
      description: "En tant que Maître du temps, gagner au Jour 5.",
      icon: "🕙", rarity: 3,
      checkCondition: (data) =>
      data['player_role'] == "Maître du temps" && data['winner_role'] == "MAÎTRE DU TEMPS" && data['turn_count'] == 5,
    ),

    // --- Pantin ---
    Achievement(
      id: "pantin_chain",
      title: "Effet Domino",
      description: "Avoir maudit 4 personnes vivantes simultanément.",
      icon: "🔗", rarity: 4,
      checkCondition: (data) => (data['max_simultaneous_curses'] ?? 0) >= 4,
    ),
    Achievement(
      id: "pantin_clutch",
      title: "Vote Décisif",
      description: "En tant que Pantin, éliminez votre cible au vote avec seulement une voix d'écart.",
      icon: "🎭", rarity: 3,
      checkCondition: (data) => data['pantin_clutch_triggered'] == true,
    ),

    // --- Phyl ---
    Achievement(
      id: "phyl_silent_assassin",
      title: "Assassin Silencieux",
      description: "Gagner seul avant la fin du jour 2 en jouant Phyl.",
      icon: "🤫", rarity: 4,
      checkCondition: (data) =>
      data['player_role'] == "Phyl" && data['winner_role'] == "PHYL" && data['turn_count'] <= 2,
    ),

    // --- Ron-Aldo ---
    Achievement(
      id: "ultimate_fan",
      title: "Fan Ultime",
      description: "Trahir Ron-Aldo et en subir les conséquences.",
      icon: "🔪", rarity: 3,
      checkCondition: (data) =>
      data['hasBetrayedRonAldo'] == true &&
          data['winner_role'] == "VILLAGE",
    ),
    Achievement(
      id: "fan_sacrifice",
      title: "Garde du Corps",
      description: "Se sacrifier pour Ron-Aldo.",
      icon: "🧡", rarity: 1,
      checkCondition: (data) => data['is_fan_sacrifice'] == true,
    ),
    Achievement(
      id: "siuuu_win",
      title: "Le GOAT",
      description: "Gagner la partie en tant que Ron-Aldo.",
      icon: "⚽", rarity: 2,
      checkCondition: (data) =>
      data['player_role']?.toString().trim() == "Ron-Aldo" &&
          data['is_fan'] == false &&
          data['winner_role'] == "RON-ALDO",
    ),

    // ==========================================
    // STATS GLOBALES ET SPÉCIFIQUES
    // ==========================================

    Achievement(
      id: "lone_wolf",
      title: "En solitaire",
      description: "Gagner avec un rôle Solo.",
      icon: "👤", rarity: 1,
      checkCondition: (data) {
        final roles = Map<String, dynamic>.from(data['roles'] ?? {});
        return (roles['SOLO'] ?? 0) >= 1;
      },
    ),
    Achievement(
      id: "village_hero",
      title: "Héros du Village",
      description: "Gagner avec le Village.",
      icon: "🏡", rarity: 1,
      checkCondition: (data) {
        final roles = Map<String, dynamic>.from(data['roles'] ?? {});
        return (roles['VILLAGE'] ?? 0) >= 1;
      },
    ),
    Achievement(
      id: "canaclean",
      title: "Le Canaclean",
      description: "Clara, Gabriel, Jean, Marc et vous devez être dans la même équipe et vivants.",
      icon: "🧼", rarity: 4,
      checkCondition: (data) => data['canaclean_present'] == true,
    ),
    Achievement(
      id: "wolf_pack",
      title: "Membre de la Meute",
      description: "Gagner avec les Loups-Garous.",
      icon: "🐺", rarity: 1,
      checkCondition: (data) {
        final roles = Map<String, dynamic>.from(data['roles'] ?? {});
        return (roles['LOUPS-GAROUS'] ?? 0) >= 1;
      },
    ),
    Achievement(
      id: "first_blood",
      title: "Premier Sang",
      description: "Être le premier joueur à mourir dans la partie.",
      icon: "🩸", rarity: 1,
      checkCondition: (data) => false,
    ),
    Achievement(
      id: "first_win",
      title: "Première Victoire",
      description: "Gagner une partie pour la première fois.",
      icon: "🏆", rarity: 1,
      checkCondition: (data) => (data['totalWins'] ?? 0) >= 1,
    ),

    // --- Cumulatifs et Vétérans ---
    Achievement(
      id: "veteran_village",
      title: "Ancien du Village",
      description: "Gagner 10 fois avec le Village.",
      icon: "👴", rarity: 1,
      checkCondition: (data) {
        final roles = Map<String, dynamic>.from(data['roles'] ?? {});
        return (roles['VILLAGE'] ?? 0) >= 10;
      },
    ),
    Achievement(
      id: "hotel_training", title: "Formation hôtelière",
      description: "Accueillez un total de 10 joueurs (cumulé).",
      icon: "🛎️", rarity: 2,
      checkCondition: (data) => (data['cumulative_hosted_count'] ?? 0) >= 10,
    ),
    Achievement(
      id: "terminator_travel", title: "I'll be back.",
      description: "Partez en voyage dans 5 parties différentes.",
      icon: "🕶️", rarity: 2,
      checkCondition: (data) => (data['cumulative_travels'] ?? 0) >= 5,
    ),
    Achievement(
      id: "villageois_eternal", title: "On pouvait pas redistribuer les rôles ?",
      description: "Jouez 5 parties en tant que Villageois.",
      icon: "👨‍🌾", rarity: 4,
      checkCondition: (data) {
        final roleWins = Map<String, dynamic>.from(data['roleWins'] ?? {});
        return (roleWins['VILLAGEOIS'] ?? 0) >= 5;
      },
    ),
    Achievement(
      id: "veteran_wolf", title: "Vétéran de la Meute",
      description: "Gagnez 10 parties en tant que Loup-garou.",
      icon: "🩸", rarity: 2,
      checkCondition: (data) {
        final roles = Map<String, dynamic>.from(data['roles'] ?? {});
        return (roles['LOUPS-GAROUS'] ?? 0) >= 10;
      },
    ),
  ];
}