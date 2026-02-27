import 'package:telephony/telephony.dart';
import 'package:flutter/material.dart';
import '../models/player.dart';

class SmsService {
  static final Telephony _telephony = Telephony.instance;

  // ---------------------------------------------------------------------------
  // DESCRIPTIONS DES RÔLES
  // Rôles 3.0 : tirés du wiki (wiki_screen.dart)
  // Rôles 2.0 : rédigés pour l'occasion
  // ---------------------------------------------------------------------------
  static const Map<String, String> _roleDescriptions = {

    // -------------------------------------------------------------------------
    // VILLAGE — rôles 3.0 (wiki)
    // -------------------------------------------------------------------------

    "archiviste":
        "Tu peux utiliser un pouvoir par nuit parmi : "
        "empêcher le vote d'un joueur, l'empêcher de parler, "
        "activer le Bouc Émissaire (2 fois par partie : le condamné choisit qui mourra à sa place), "
        "ou remplacer le MJ. Si tu deviens MJ, tu peux reprendre ta place en devinant le bon numéro "
        "(1/15 la 1ère nuit, 1/7 la 2ème, 1/3 ensuite) et choisir ton camp au retour.",

    "devin":
        "Pendant deux nuits consécutives, concentre-toi sur un même joueur. "
        "Son rôle sera révélé au grand jour le lendemain. "
        "Tu peux changer de cible chaque nuit, mais le compteur repart à zéro.",

    "dingo":
        "Chaque nuit, tu lances un objet léger sur un joueur. "
        "Une fois 2 cibles touchées dans la partie, tu reçois un objet lourd : "
        "tu pourras alors éliminer la cible de ton choix en le lançant la nuit. "
        "Tu ne dois pas te déplacer lors du lancer.",

    "zookeeper":
        "Chaque nuit, tu tires une fléchette tranquillisante sur un joueur. "
        "Ta cible ne se réveillera pas la nuit suivante et ne pourra pas agir. "
        "Tu ne peux pas viser la même personne deux nuits de suite.",

    "enculateur du bled":
        "Chaque nuit, tu choisis un joueur à protéger contre le vote du village. "
        "Il sera immunisé au lynchage du lendemain. "
        "Tu ne peux pas te protéger toi-même, ni protéger la même personne deux nuits de suite.",

    "exorciste":
        "À la deuxième nuit, le MJ te désigne un joueur aléatoire : tu dois mimer son rôle. "
        "Si le MJ valide ton interprétation, le village gagne immédiatement ! "
        "En cas d'échec, tu deviens un simple Villageois pour le reste de la partie.",

    "grand-mère":
        "Toutes les deux nuits, tu peux cuisiner une quiche. "
        "Elle protège tous les joueurs de la mort pendant la nuit suivante. "
        "Attention : la quiche n'empêche pas la bombe du Tardos d'exploser.",

    "houston":
        "Une nuit sur deux, tu désignes 2 joueurs. "
        "Le MJ annonce le lendemain matin : \"Qui voilà-je\" s'ils sont dans le même camp, "
        "ou \"Houston, on a un problème\" s'ils ne le sont pas.",

    "maison":
        "Chaque nuit, tu peux accueillir un joueur chez toi (max 2 simultanément). "
        "Si un résident est ciblé, il survit et tu meurs à sa place. "
        "Si le Tardos cible la maison ou un résident, tout le monde meurt.",

    "tardos":
        "Tu poses une seule bombe dans la partie sur un joueur de ton choix. "
        "Elle n'explose qu'après deux nuits, tuant la cible et un voisin aléatoire. "
        "Si la bombe atteint la Maison ou un de ses membres, tous meurent dans l'explosion. "
        "Attention : 1 chance sur 100 que la bombe t'explose dans les mains à l'amorçage !",

    "villageois":
        "Tu es un simple villageois sans pouvoir particulier. "
        "Ta seule arme, c'est ta voix lors des votes. "
        "Observe, écoute et débusque les loups !",

    "voyageur":
        "Tu peux partir en voyage aussi longtemps que tu le souhaites. "
        "Toutes les deux nuits d'absence, tu gagnes une balle utilisable à ton retour. "
        "Si tu es tué ou voté pendant ton absence, tu reviens avec tes balles mais ne peux plus repartir.",

    // -------------------------------------------------------------------------
    // VILLAGE — rôles 2.0 (rédigés)
    // -------------------------------------------------------------------------

    "chasseur":
        "À ta mort — que ce soit par vote ou attaque nocturne — "
        "tu déclenches immédiatement ta vengeance : tu choisis un joueur à éliminer avec toi. ",

    "cupidon":
        "La première nuit uniquement, tu lies deux joueurs par les flèches de l'amour. "
        "Si l'un des amoureux meurt, l'autre mourra de chagrin immédiatement. "
        "Ce lien dépasse les camps : choisis ton couple avec soin.",

    "saltimbanque":
        "Chaque nuit, tu choisis un joueur à protéger des attaques nocturnes. "
        "Tu ne peux pas protéger la même personne deux nuits de suite. "
        "Ta protection prend fin au lever du soleil.",

    "sorcière":
        "Tu possèdes deux potions à usage unique : "
        "une Potion de Vie pour sauver la victime des loups cette nuit, "
        "et une Potion de Mort pour empoisonner n'importe quel joueur vivant. "
        "Une seule potion par nuit. Utilise-la à bon escient.",

    "voyante":
        "Chaque nuit, tu regardes dans ta boule de cristal "
        "et découvres le rôle exact d'un joueur de ton choix.",

    "kung-fu panda":
        "Chaque nuit, tu désignes un joueur qui devra hurler dans la nuit."
        "Tu n'as aucun autre pouvoir... mais la pression psychologique est une arme.",

    // -------------------------------------------------------------------------
    // LOUPS-GAROUS — rôles 3.0 (wiki)
    // -------------------------------------------------------------------------

    "loup-garou chaman":
        "Tu es un loup-garou évolué avec le don de clairvoyance : "
        "chaque nuit, tu peux voir le rôle d'un joueur de ton choix (ton vote ne compte pas lors du vote des loups). "
        "Si tous les autres loups évolués meurent, tu perds ta vision mais gagnes le droit de voter la nuit.",

    "loup-garou évolué":
        "Chaque nuit, tu te concertes avec tes camarades loups pour désigner une victime à tuer. "
        "En mourant, tu peux mettre une chiquette au le joueur de ton choix ",

    "somnifère":
        "Une fois par partie, tu peux empoisonner tous les joueurs et les endormir pendant la journée. "
        "Ils se réveilleront uniquement pour entendre les morts de la nuit, "
        "puis devront se rendormir sans pouvoir voter ni parler.",

    // -------------------------------------------------------------------------
    // SOLO — rôles 3.0 (wiki)
    // -------------------------------------------------------------------------

    "maître du temps":
        "Toutes les nuits, tu peux tuer 2 joueurs de ton choix, ",

    "pantin":
        "Invincible à tout sauf au vote du village. "
        "Chaque nuit, tu maudis 2 personnes qui mourront 2 tours plus tard. "
        "Si tu es voté, tu ne mourras que deux nuits après le vote. "
        "Ton vote compte double. En cas de quiche, les morts de malédiction sont retardés d'une nuit.",

    "phyl":
        "Pour gagner, tu dois être nommé chef du village "
        "ET que tes 2 cibles (indiquées par le MJ en début de partie) soient mortes. "
        "Tu joues seul — manipule le village pour atteindre tes deux objectifs.",

    "dresseur":
        "Chaque nuit, tu as deux choix : immobiliser un joueur (ton Pokémon choisit la cible), "
        "ou protéger ton Pokémon (ou toi-même). Si c'est toi qui te protèges, le Pokémon mourra à ta place. "
        "Si le Pokémon meurt, tu peux le réanimer une seule fois. Tu dois alterner d'action chaque nuit.",

    "pokémon":
        "Tu es comme un Villageois, mais à ta mort tu peux électrocuter un joueur de ton choix. "
        "Si le Dresseur immobilise quelqu'un, c'est toi qui choisis sa cible. "
        "Si le Dresseur meurt, tu électrocutes librement un joueur par nuit.",

    "ron-aldo":
        "Chaque nuit, tu te réveilles pour convertir un Fan (max 3 au total). "
        "Le MJ signale discrètement au nouveau Fan qu'il t'appartient. "
        "Si tu meurs, ton Fan le plus ancien meurt à ta place (une seule fois). ",

    // -------------------------------------------------------------------------
    // SOLO — rôles 2.0 (rédigés)
    // -------------------------------------------------------------------------

    "chuchoteur":
        "Chaque nuit, tu réduis des joueurs au silence : ils ne peuvent plus voter le lendemain. "
        "Plus la partie avance, plus tu peux en cibler : 1 au début, puis 2, puis 3. "
        "Tu joues seul — fais semer la méfiance sans révéler ta présence.",
  };

  static String? _cleanPhoneNumber(String raw) {
    if (raw.isEmpty) return null;
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('06') || clean.startsWith('07')) {
      clean = '+33${clean.substring(1)}';
    }
    if (clean.length < 4) return null;
    return clean;
  }

  static Future<bool> sendRoleToPlayer(Player player, List<Player> allPlayers) async {
    String? phone = _cleanPhoneNumber(player.phoneNumber ?? "");

    if (phone == null) {
      debugPrint("❌ SMS Ignoré : Pas de numéro valide pour ${player.name}");
      return false;
    }

    final String roleKey = player.role?.toLowerCase() ?? "";
    final String roleDesc = _roleDescriptions[roleKey] ?? "Consulte le MJ pour connaître ton rôle en détail.";

    // --- CONSTRUCTION DU MESSAGE ---
    String message = "🐺 [LOUP-GAROU] 🐺\n\n"
        "Bonjour ${player.name},\n"
        "Ton rôle : ${player.role?.toUpperCase()}\n"
        "Ton équipe : ${player.team.toUpperCase()}\n\n"
        "📖 ${roleDesc}";

    // 1. INFO POUR LES LOUPS
    if (player.team == 'loups') {
      List<String> allies = allPlayers
          .where((p) => p.team == 'loups' && p.name != player.name && p.isAlive)
          .map((p) => p.name)
          .toList();

      if (allies.isNotEmpty) {
        message += "\n\n🌑 LA MEUTE :\n${allies.join("\n")}";
      } else {
        message += "\n\n🌑 Tu es le seul loup pour l'instant.";
      }
    }

    // 2. INFO POUR DRESSEUR / POKÉMON
    if (roleKey == 'dresseur') {
      var pokemon = allPlayers.where((p) =>
          p.role?.toLowerCase() == 'pokemon' || p.role?.toLowerCase() == 'pokémon').toList();
      if (pokemon.isNotEmpty) {
        message += "\n\n⚡ TON POKÉMON :\n${pokemon.first.name}";
      }
    } else if (roleKey == 'pokemon' || roleKey == 'pokémon') {
      var dresseur = allPlayers.where((p) => p.role?.toLowerCase() == 'dresseur').toList();
      if (dresseur.isNotEmpty) {
        message += "\n\n🧢 TON DRESSEUR :\n${dresseur.first.name}";
      }
    }

    // 3. INFO POUR PHYL (ses cibles assignées)
    if (roleKey == 'phyl' && player.phylTargets.isNotEmpty) {
      final List<String> targetNames = player.phylTargets.map((p) => p.name).toList();
      message += "\n\n🎯 TES CIBLES :\n${targetNames.join("\n")}";
    }

    // 4. INFO POUR RON-ALDO (ses fans actuels)
    if (roleKey == 'ron-aldo') {
      List<String> fans = allPlayers
          .where((p) => p.role?.toLowerCase() == 'fan de ron-aldo' && p.isAlive)
          .map((p) => p.name)
          .toList();
      if (fans.isNotEmpty) {
        message += "\n\n🙌 TES FANS :\n${fans.join("\n")}";
      }
    }

    message += "\n\nBonne chance !";

    try {
      debugPrint("📤 Envoi SMS à ${player.name} ($phone)...");
      await _telephony.sendSms(
        to: phone,
        message: message,
        isMultipart: true,
      );
      return true;
    } catch (e) {
      debugPrint("❌ Erreur SMS vers ${player.name}: $e");
      return false;
    }
  }

  static Future<void> sendRolesToAll(BuildContext context, List<Player> players) async {
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) return;

    int count = 0;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Envoi des SMS de rôles... 📨"), duration: Duration(seconds: 2)),
      );
    }

    for (var p in players) {
      if (!p.isPlaying || !p.isAlive) continue;

      await Future.delayed(const Duration(milliseconds: 400));

      bool success = await sendRoleToPlayer(p, players);
      if (success) count++;
    }

    debugPrint("✅ Campagne SMS terminée. $count messages envoyés.");
  }
}
