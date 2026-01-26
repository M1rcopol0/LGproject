import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WikiPage extends StatelessWidget {
  const WikiPage({super.key});

  @override
  Widget build(BuildContext context) {
    // PopScope permet d'intercepter l'action de retour (fermeture)
    return PopScope(
      canPop: true, // On autorise la fermeture
      onPopInvoked: (didPop) {
        // Si la fermeture a bien eu lieu
        if (didPop) {
          playSfx("grimoire_open.mp3");
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Grimoire des Rôles")),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFactionHeader("VILLAGE", Colors.greenAccent),
            const WikiItem(
                role: "Archiviste",
                desc: "L'Archiviste peut utiliser un pouvoir par nuit parmi les suivants :\n\n"
                    "- Empêcher le vote d'un joueur lors de la journée suivante\n"
                    "- Empêcher un joueur de parler pendant la journée suivante\n"
                    "- Permettre au joueur censé mourir de sélectionner un joueur qui mourra à sa place (utilisable 2 fois par partie uniquement)\n"
                    "- Peut choisir de remplacer le MJ, ce dernier devient un joueur inactif sans pouvoir ni victoire, et ne peut redevenir MJ qu'en trouvant le même numéro que l'Archiviste : 1ère nuit 1 chance sur 15, 2ème nuit 1  chance sur 7 et à partir de la 3ème nuit 1 chance sur 3. Lorsque l'Archiviste reprend sa place, il choisit quel camp il veut rejoindre et le note afin de vérifier en fin de partie."
            ),
            const WikiItem(
                role: "Devin",
                desc: "Pendant deux nuits, le Devin se concentre sur une personne dont le rôle sera révélé au grand jour. Chaque nuit, il a le droit de changer son objet de concentration mais il se réinitialise."
            ),
            const WikiItem(
                role: "Dingo",
                desc: "Chaque nuit, le Dingo peut lancer un objet léger sur un participant de son choix. Il peut recevoir un objet lourd à lancer à la discrétion du MJ. Lors du lancer de l’objet lourd, un son retentira pour demander aux joueurs de se protéger. Le Dingo doit atteindre 4 cibles pendant la partie avant d’être tué. Il ne doit pas se déplacer. Une fois ses quatre cibles touchées, il reçoit un objet lourd et pendant la journée il le lance sur qui il veut en le tuant."
            ),
            const WikiItem(
                role: "Zookeeper",
                desc: "Chaque nuit, le Zookeeper peut utiliser son fusil tranquillisant pour endormir sa cible, qui ne se réveillera pas la nuit suivante."
            ),
            const WikiItem(
                role: "Enculateur du bled",
                desc: "Chaque nuit, l'Enculateur du bled choisit une personne à violer pendant la journée, ce qui la protège du vote."
            ),
            const WikiItem(
                role: "Exorciste",
                desc: "Lors de la deuxième nuit, l’Exorciste doit deviner en mimant le rôle d’un joueur aléatoire désigné par le MJ. Ce dernier décide du rôle mimé en interprétant le signe. Si l’Exorciste devine, le village gagne. S'il rate, il devient simple Villageois jusqu’à la fin de la partie."
            ),
            const WikiItem(
                role: "Grand-mère",
                desc: "Toutes les deux nuits, la Grand-mère choisit de faire une quiche. Cette dernière protège tous les joueurs de la mort pendant la nuit. La Grand-mère a 1 chance sur 2 de rater sa quiche, la rendant inefficace."
            ),
            const WikiItem(
                role: "Houston",
                desc: "Une nuit sur deux, Houston se réveille pour désigner 2 joueurs. Au réveil, le MJ annonce “Qui voilà-je” si les deux joueurs sont dans la même équipe ou alors “Houston, on a un problème” s’ils ne le sont pas."
            ),
            const WikiItem(
                role: "Maison",
                desc: "Chaque nuit la Maison peut accueillir une personne. Cette personne est protégée des attaques pendant la nuit. La Maison peut contenir simultanément 2 personnes maximum et ne peut pas les enlever de la maison une fois choisies. Si une personne protégée est ciblée, elle survit et la maison meurt à la place. Si le Tardos attaque la maison ou un des membres, tout le monde meurt."
            ),
            const WikiItem(
                role: "Tardos",
                desc: "Le Tardos a le droit de poser une bombe dans la partie sur un joueur. Une fois posée, la bombe n’explose pas avant deux nuits, puis explose en tuant la cible et un de ses voisins aléatoirement. La bombe du Tardos à 1 chance sur 100 de lui exploser dans les mains, le tuant instantanément."
            ),
            const WikiItem(
                role: "Villageois",
                desc: "Un simple Villageois sans pouvoir spécifique."
            ),
            const WikiItem(
                role: "Voyageur",
                desc: "Le Voyageur choisit de partir en voyage aussi longtemps qu’il le souhaite. Toutes les deux nuits d’absence, il gagne une balle qu’il pourra utiliser à son retour. Pendant son absence son vote ne sera pas comptabilisé. S’il est “tué” pendant son voyage ou voté lors de la journée, il revient avec ce qu’il a récupéré, est exposé aux yeux de tous et devient un simple Villageois."
            ),

            _buildFactionHeader("LOUPS-GAROUS", Colors.redAccent),
            const WikiItem(
                role: "Loup-garou chaman",
                desc: "Le Loup-garou chaman est un Loup-garou évolué qui peut voir le rôle d’une personne au choix lors de la nuit. Pendant le vote des autres Loups-garous évolués, le sien n’est pas comptabilisé. Si tous les autres Loups-garous évolués sont tués, il perd son don de clairvoyance et gagne le pouvoir de voter la nuit."
            ),
            const WikiItem(
                role: "Loup-garou évolué",
                desc: "Chaque nuit, le Loup-garou évolué se concerte avec ses camarades pour désigner une personne à tuer. Il peut mettre une chiquette à qui il veut en mourant (sauf Charles et Gabriel)."
            ),
            const WikiItem(
                role: "Somnifère",
                desc: "2 fois par partie, Somnifère choisit d’empoisonner tous les joueurs en les endormant pendant la journée. Ils se réveilleront pour entendre les morts de la nuit puis devront se rendormir."
            ),

            _buildFactionHeader("SOLO", Colors.orangeAccent),
            const WikiItem(
                role: "Chuchoteur",
                desc: "Chaque nuit, le Chuchoteur choisit une cible à qui passer Jimi. La cible aura interdiction de parler la journée et ne pourra pas voter. Les nuits 3 et 4, il peut chuchoter à l'oreille de 2 joueurs qui ne peuvent ni parler ni voter. A partir de la nuit 5, le Chuchoteur étend son pouvoir à 3 joueurs simultanément."
            ),
            const WikiItem(
                role: "Maître du temps",
                desc: "Toutes les nuits le Maître du temps tue 2 joueurs de son choix."
            ),
            const WikiItem(
                role: "Pantin",
                desc: "Invincible à tout sauf le vote du jour, chaque nuit le Pantin maudit 2 personnes qui mourront 2 tours plus tard. S'il est voté, il ne meurt que deux nuits après le vote. La Maison est maudite dès lors qu'elle accueille une personne maudite. Le vote du Pantin compte double."
            ),
            const WikiItem(
                role: "Phyl",
                desc: "Pour gagner, Phyl doit être nommé chef du village (d'une manière ou d'une autre) et que ses 2 cibles indiquées par le MJ en début de partie soient décédées."
            ),
            const WikiItem(
                role: "Dresseur",
                desc: "Chaque nuit, le Dresseur a deux choix : immobiliser un joueur selon le choix de son Pokémon en désactivant son action de la nuit, ou alors protéger son Pokémon (ou lui-même) pour la nuit. Si c'est le Dresseur qui se protège grâce à son Pokémon, le Pokémon mourra en cas d'attaque (sauf s'il est déjà mort, dans ce cas le Dresseur meurt). Si le Pokémon est mort, le Dresseur peut le réanimer pendant la nuit une seule fois. Chaque nuit le Dresseur doit changer d'action."
            ),
            const WikiItem(
                role: "Pokémon",
                desc: "Le Pokémon est comme un Villageois, mais lorsqu'il meurt il peut électrocuter une personne de son choix. Si le Dresseur choisit d'immobiliser quelqu'un, c'est le Pokémon qui choisit sa cible. Si le Dresseur meurt, le Pokémon électrocute une personne de son choix par nuit."
            ),
            const WikiItem(
                role: "Ron-Aldo",
                desc: "Chaque nuit, Ron-Aldo se réveille pour convertir un Fan avec une limite de 3 Fans maximum. Lorsque le Fan est converti, le MJ lui tape sur la tête pour qu'il reconnaisse son nouveau maître. Si Ron-Aldo meurt d’une manière ou d’une autre, c’est son Fan le plus ancien qui meurt à la place."
            ),
            const WikiItem(
                role: "Fan de Ron-Aldo",
                desc: "Dès qu’il est désigné par Ron-Aldo, le Fan perd son rôle précédent et ses pouvoirs. Son seul but désormais est de suivre Ron-Aldo et de le défendre par tous les moyens. Lors d’un vote, le Fan doit obligatoirement suivre les indications de Ron-Aldo. Cela signifie que même si Ron-Aldo accuse son Fan, il devra se désigner lui-même. Seul le premier Fan recruté par Ron-Aldo peut le protéger d’une mort certaine. À la mort de Ron-Aldo, les Fans doivent gagner entre eux."
            ),

            // NOUVELLE SECTION : TITRES ET POSITIONS
            _buildFactionHeader("TITRES & POSITIONS", Colors.amberAccent),
            const WikiItem(
                role: "Maire",
                desc: "Le Maire est élu au matin du premier jour par les joueurs. Il est chargé de choisir qui sera lynché en cas d'égalité. Si le Maire meurt, il nomme un successeur qui prendra sa place."
            ),
            const WikiItem(
                role: "Roi",
                desc: "Le Roi est élu de la même manière que le Maire. Une fois par mandat, il peut opposer son veto au vote du jour et annuler le lynchage d'un joueur. Sa décision intervient après l'annonce du résultat du vote."
            ),
            const WikiItem(
                role: "Dictateur",
                desc: "Le Dictateur peut détourner le vote du village vers un joueur de son choix une fois par mandat. Sa décision intervient après l'annonce du résultat du vote."
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactionHeader(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class WikiItem extends StatelessWidget {
  final String role;
  final String desc;
  const WikiItem({super.key, required this.role, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1D1E33),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(role, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        subtitle: Text(desc, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}