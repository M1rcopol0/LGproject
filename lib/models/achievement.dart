import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  // Helper pour récupérer la couleur selon la rareté
  Color get color {
    switch (rarity) {
      case 1: return Colors.blueAccent; // Facile
      case 2: return Colors.greenAccent; // Intermédiaire
      case 3: return Colors.purpleAccent; // Difficile
      case 4: return Colors.amber; // Légendaire (Or)
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

    // --- RON-ALDO ---
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
    Achievement(
      id: "fan_sacrifice",
      title: "Garde du Corps",
      description: "Se sacrifier pour Ron-Aldo.",
      icon: "🧡", rarity: 1,
      checkCondition: (data) => data['is_fan_sacrifice'] == true,
    ),
    Achievement(
      id: "ultimate_fan",
      title: "Fan Ultime",
      description: "Trahir Ron-Aldo et en subir les conséquences.",
      icon: "🔪", rarity: 3,
      checkCondition: (data) =>
      data['hasBetrayedRonAldo'] == true &&
          data['winner_role'] == "VILLAGE",
    ),

    // --- DRESSEUR & POKÉMON ---
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

    // --- PANTIN ---
    Achievement(
      id: "pantin_clutch",
      title: "Vote Décisif",
      description: "En tant que Pantin, être sauvé car votre vote double a éliminé votre cible.",
      icon: "🎭", rarity: 3,
      checkCondition: (data) => data['pantin_clutch_save'] == true,
    ),
    Achievement(
      id: "pantin_chain",
      title: "Effet Domino",
      description: "Avoir maudit 4 personnes vivantes simultanément.",
      icon: "🔗", rarity: 4,
      checkCondition: (data) => (data['max_simultaneous_curses'] ?? 0) >= 4,
    ),

    // --- MAÎTRE DU TEMPS ---
    Achievement(
      id: "time_paradox",
      title: "Paradoxe Temporel",
      description: "En tant que Maître du temps, tuer deux personnes de camps opposés la même nuit.",
      icon: "⏳", rarity: 2,
      checkCondition: (data) => data['paradox_achieved'] == true,
    ),
    Achievement(
      id: "time_perfect",
      title: "Timing Précis",
      description: "En tant que Maître du temps, gagner au Jour 5.",
      icon: "🕙", rarity: 3,
      checkCondition: (data) =>
      data['player_role'] == "Maître du temps" && data['winner_role'] == "MAÎTRE DU TEMPS" && data['turn_count'] == 5,
    ),

    // --- PHYL ---
    Achievement(
      id: "phyl_silent_assassin",
      title: "Assassin Silencieux",
      description: "Gagner seul avant la fin du jour 2 en jouant Phyl.",
      icon: "🤫", rarity: 4,
      checkCondition: (data) =>
      data['player_role'] == "Phyl" && data['winner_role'] == "PHYL" && data['turn_count'] <= 2,
    ),

    // --- LOUPS ---
    Achievement(
      id: "pack_unbreakable",
      title: "Meute Soudée",
      description: "Gagner sans qu'aucun loup n'ait voté contre un autre loup.",
      icon: "🐾", rarity: 3,
      checkCondition: (data) =>
      data['is_wolf_faction'] == true && data['winner_role'] == "LOUPS-GAROUS" && data['no_friendly_fire_vote'] == true,
    ),
    Achievement(
      id: "pack_fast_food",
      title: "Fast Food",
      description: "En tant que loup, gagner avant le Jour 4.",
      icon: "🍔", rarity: 2,
      checkCondition: (data) =>
      data['is_wolf_faction'] == true && data['winner_role'] == "LOUPS-GAROUS" && data['turn_count'] < 4,
    ),

    // --- LG CHAMAN ---
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

    // --- SOMNIFÈRE ---
    Achievement(
      id: "somni_blackout",
      title: "Nuit Éternelle",
      description: "En tant que Somnifère, gagner après avoir utilisé vos deux potions.",
      icon: "💤", rarity: 2,
      checkCondition: (data) =>
      data['player_role'] == "Somnifère" && data['winner_role'] == "LOUPS-GAROUS" && (data['somnifere_uses_left'] ?? 1) == 0,
    ),

    // --- LG ÉVOLUÉ ---
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

    // --- MAISON ---
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
      icon: "🏚️", rarity: 1,
      checkCondition: (data) => data['player_role']?.toLowerCase() == "maison" && data['turn_count'] == 1 && data['death_cause'] == "direct_hit",
    ),

    // --- TARDOS ---
    Achievement(
      id: "tardos_oups",
      title: "Oups...",
      description: "Faites exploser votre propre bombe à la figure.",
      icon: "💥", rarity: 4,
      checkCondition: (data) => data['player_role']?.toLowerCase() == "tardos" && data['death_cause'] == "Explosion accidentelle",
    ),

    // --- EXORCISTE ---
    Achievement(
      id: "mime_win",
      title: "Vite fait, bien fait !",
      description: "Faites gagner le village grâce à vos talents de mime.",
      icon: "🎭", rarity: 3,
      checkCondition: (data) => data['player_role']?.toLowerCase() == "exorciste" && data['exorcisme_success_win'] == true,
    ),

    // --- VOYAGEUR ---
    Achievement(
      id: "traveler_sniper",
      title: "I'm back.",
      description: "Au retour de votre voyage, éliminez un loup-garou.",
      icon: "🔫", rarity: 2,
      checkCondition: (data) => data['traveler_killed_wolf'] == true,
    ),

    // --- GRAND-MÈRE ---
    Achievement(
      id: "quiche_hero",
      title: "Quiche ou tarte ?",
      description: "Prévenez le meurtre de 4 joueurs en une seule nuit.",
      icon: "🥧", rarity: 3,
      checkCondition: (data) => data['quiche_saved_count'] != null && data['quiche_saved_count'] >= 4,
    ),
    Achievement(
      id: "self_quiche_save",
      title: "Le petit chaperon rouge",
      description: "Survivez à la nuit grâce à votre propre quiche.",
      icon: "👵", rarity: 2,
      checkCondition: (data) => data['player_role']?.toLowerCase() == "grand-mère" && data['saved_by_own_quiche'] == true,
    ),

    // --- ENCULATEUR DU BLED ---
    Achievement(
      id: "bled_all_covered",
      title: "Sortez couvert !",
      description: "Violez tous les joueurs d'une partie au moins une fois.",
      icon: "🍆", rarity: 4,
      checkCondition: (data) => data['bled_protected_everyone'] == true,
    ),

    // --- DINGO ---
    Achievement(
      id: "bad_shooter",
      title: "Mauvais tireur",
      description: "Ne réussissez aucun de vos tirs dans une partie (min. 3).",
      icon: "🎯", rarity: 1,
      checkCondition: (data) =>
      data['player_role']?.toString().toLowerCase() == "dingo" && // Sécurité rôle
          data['dingo_shots_fired'] >= 3 &&
          data['dingo_shots_hit'] == 0,
    ),
    Achievement(
      id: "parking_shot",
      title: "Un tir du parking !",
      description: "En tant que dingo, tuez le dernier ennemi du village.",
      icon: "🏀", rarity: 3,
      checkCondition: (data) => data['parking_shot_achieved'] == true,
    ),
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

    // --- HOUSTON ---
    Achievement(
      id: "apollo_13",
      title: "Apollo 13",
      description: "Désignez un loup et un rôle solo en même temps.",
      icon: "🚀", rarity: 2,
      // La logique est maintenant stockée dans le flag player
      checkCondition: (data) => data['houstonApollo13Triggered'] == true,
    ),

    // --- DEVIN ---
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
      checkCondition: (data) => data['player_role']?.toLowerCase() == "devin" && data['is_player_alive'] == true && data['devin_reveals_count'] == 0,
    ),

    // --- ARCHIVISTE ---
    Achievement(
      id: "archiviste_king",
      title: "Le roi du CDI", // Succès 'One Shot'
      description: "Utilisez 4 pouvoirs différents en une seule partie.",
      icon: "📚", rarity: 4,
      checkCondition: (data) => data['archiviste_all_powers_used_in_game'] == true,
    ),

    // --- DIVERS ---
    Achievement(
      id: "canaclean",
      title: "Le Canaclean",
      description: "Clara, Gabriel, Jean, Marc et vous devez être dans la même équipe et vivants.",
      icon: "🧼", rarity: 4,
      checkCondition: (data) => data['canaclean_present'] == true,
    ),

    // --- SUCCÈS CUMULATIFS ---
    Achievement(
      id: "terminator_travel", title: "I'll be back.",
      description: "Partez en voyage dans 5 parties différentes.",
      icon: "🕶️", rarity: 2,
      checkCondition: (data) => (data['cumulative_travels'] ?? 0) >= 5,
    ),
    Achievement(
      id: "hotel_training", title: "Formation hôtelière",
      description: "Accueillez un total de 10 joueurs (cumulé).",
      icon: "🛎️", rarity: 2,
      checkCondition: (data) => (data['cumulative_hosted_count'] ?? 0) >= 10,
    ),
    Achievement(
      id: "villageois_eternal", title: "On pouvait pas redistribuer les rôles ?",
      description: "Jouez 5 parties en tant que Villageois.",
      icon: "👨‍🌾", rarity: 4,
      checkCondition: (data) => (data['cumulative_villageois_count'] ?? 0) >= 5,
    ),
    Achievement(
      id: "archiviste_prince", title: "Le prince du CDI", // Succès 'Cumulatif'
      description: "Utilisez 4 pouvoirs différents au cours de votre carrière.",
      icon: "📖", rarity: 2,
      checkCondition: (data) => data['archiviste_all_powers_cumulated'] == true,
    ),

    Achievement(
      id: "veteran_village",
      title: "Ancien du Village",
      description: "Gagner 10 fois avec le Village.",
      icon: "🏘️", rarity: 1,
      checkCondition: (data) {
        final roles = Map<String, dynamic>.from(data['roles'] ?? {});
        return (roles['VILLAGE'] ?? 0) >= 10;
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