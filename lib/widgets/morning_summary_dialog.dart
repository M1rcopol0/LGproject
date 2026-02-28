import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/player.dart';
import '../logic/night/night_actions_logic.dart'; // Pour NightResult

class MorningSummaryDialog extends StatefulWidget {
  final NightResult result;
  final List<Player> players;
  final VoidCallback onConfirm;

  const MorningSummaryDialog({
    super.key,
    required this.result,
    required this.players,
    required this.onConfirm,
  });

  @override
  State<MorningSummaryDialog> createState() => _MorningSummaryDialogState();
}

class _MorningSummaryDialogState extends State<MorningSummaryDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _factionColor(String? team) {
    switch (team) {
      case "loups": return Colors.redAccent;
      case "village": return Colors.greenAccent;
      case "solo": return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }

  IconData _factionIcon(String? team) {
    switch (team) {
      case "loups": return Icons.whatshot;
      case "village": return Icons.shield;
      case "solo": return Icons.star;
      default: return Icons.person;
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Préparation des listes pour l'affichage
    List<String> mutedPlayers = widget.players
        .where((p) => p.isMutedDay && p.isAlive)
        .map((p) => p.name)
        .toList();
    mutedPlayers.sort((a, b) => a.compareTo(b));

    Player? voyageurRetour = widget.players.firstWhereOrNull((p) =>
        p.role?.toLowerCase() == "voyageur" &&
        p.isAlive &&
        !p.canTravelAgain &&
        !p.isInTravel &&
        p.hasReturnedThisTurn);

    Player? archivisteTranscende = widget.players.firstWhereOrNull((p) =>
        p.role?.toLowerCase() == "archiviste" &&
        p.isAlive &&
        p.isAwayAsMJ &&
        !p.needsToChooseTeam &&
        p.mjNightsCount == 0);

    List<Player> sortedDeadPlayers = List.from(widget.result.deadPlayers);
    sortedDeadPlayers.sort((a, b) => a.name.compareTo(b.name));

    final bool hasDeaths = sortedDeadPlayers.isNotEmpty;
    final String titleText = widget.result.exorcistVictory
        ? "✝️ EXORCISME ACCOMPLI"
        : hasDeaths
            ? "☀️ L'AUBE SE LÈVE..."
            : "🌅 NUIT PAISIBLE";
    final Color titleColor = widget.result.exorcistVictory
        ? Colors.amberAccent
        : hasDeaths
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Dialog(
      backgroundColor: const Color(0xFF1D1E33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- TITRE ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(
                  widget.result.exorcistVictory ? Icons.auto_fix_high : Icons.wb_sunny,
                  color: titleColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titleText,
                    style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // --- ONGLETS ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _buildTab("ANNONCES", 0),
                const SizedBox(width: 8),
                _buildTab(hasDeaths ? "DÉCÈS" : "DÉCÈS (0)", 1, enabled: hasDeaths),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // --- PAGES SWIPEABLES ---
          SizedBox(
            height: 320,
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) {
                debugPrint("📋 CAPTEUR [MorningSummary] : Swipe vers page $i (${i == 0 ? 'ANNONCES' : 'DÉCÈS'}).");
                setState(() => _currentPage = i);
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAnnouncementsPage(
                    voyageurRetour: voyageurRetour,
                    archivisteTranscende: archivisteTranscende,
                    mutedPlayers: mutedPlayers,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDeathsPage(sortedDeadPlayers),
                ),
              ],
            ),
          ),

          // --- INDICATEURS DOTS ---
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == i ? Colors.orangeAccent : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),

          // --- BOUTON ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                debugPrint("📋 CAPTEUR [MorningSummary] : Bouton 'VOIR LE VILLAGE' pressé.");
                widget.onConfirm();
              },
              child: const Text("VOIR LE VILLAGE",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, {bool enabled = true}) {
    final bool active = _currentPage == index;
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () {
          debugPrint("📋 CAPTEUR [MorningSummary] : Clic onglet '$label' (index $index).");
          _goToPage(index);
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active && enabled ? Colors.orangeAccent.withOpacity(0.2) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: active && enabled ? Colors.orangeAccent : Colors.white24,
                width: active && enabled ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: !enabled ? Colors.white24 : active ? Colors.orangeAccent : Colors.white54,
              fontWeight: active && enabled ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsPage({
    required Player? voyageurRetour,
    required Player? archivisteTranscende,
    required List<String> mutedPlayers,
  }) {
    final bool hasAnything = widget.result.exorcistVictory ||
        widget.result.announcements.isNotEmpty ||
        widget.result.revealedPlayerNames.isNotEmpty ||
        voyageurRetour != null ||
        mutedPlayers.isNotEmpty ||
        archivisteTranscende != null ||
        widget.result.villageIsNarcoleptic;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Victoire exorcisme
          if (widget.result.exorcistVictory)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                border: Border.all(color: Colors.amberAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "L'EXORCISME A RÉUSSI !\nLe village est purifié et gagne immédiatement !",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
              ),
            ),

          // Annonces spéciales
          if (!widget.result.exorcistVictory && widget.result.announcements.isNotEmpty) ...[
            const Text("📢 ANNONCES SPÉCIALES :",
                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ...widget.result.announcements.map((msg) => Text("- $msg",
                style: const TextStyle(color: Colors.white70))),
            const Divider(color: Colors.white24),
          ],

          // Révélations (Devin)
          if (widget.result.revealedPlayerNames.isNotEmpty) ...[
            const Text("🔍 RÉVÉLATIONS :",
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...widget.result.revealedPlayerNames.map((name) => Text(
                "- $name a été identifié(e) par le Devin",
                style: const TextStyle(color: Colors.white70))),
            const Divider(color: Colors.white24),
          ],

          // Retour forcé voyageur
          if (voyageurRetour != null) ...[
            const Text("🛑 RETOUR FORCÉ :",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            Text(
              "Le Voyageur a dû rentrer. Il ne repartira plus.\n💊 Munitions restantes : ${voyageurRetour.travelerBullets}",
              style: const TextStyle(color: Colors.white70),
            ),
            const Divider(color: Colors.white24),
          ],

          // Silence
          if (mutedPlayers.isNotEmpty) ...[
            const Text("🤐 SILENCE :",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            Text("${mutedPlayers.join(", ")} ne peut pas parler.",
                style: const TextStyle(color: Colors.white70)),
            const Divider(color: Colors.white24),
          ],

          // Transcendance archiviste
          if (archivisteTranscende != null) ...[
            const Text("🗂️ TRANSCENDANCE :",
                style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
            Text(
              "${archivisteTranscende.name} a quitté le village pour devenir Maître du Jeu. Il ne jouera plus jusqu'à sa victoire.",
              style: const TextStyle(color: Colors.white70),
            ),
            const Divider(color: Colors.white24),
          ],

          // Somnifère
          if (widget.result.villageIsNarcoleptic)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.15),
                border: Border.all(color: Colors.purpleAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bedtime, color: Colors.purpleAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Le village est pris d'un profond sommeil...",
                      style: TextStyle(color: Colors.purpleAccent),
                    ),
                  ),
                ],
              ),
            ),

          // Rien à signaler
          if (!hasAnything)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nightlight_round, color: Colors.white54, size: 20),
                  SizedBox(width: 8),
                  Text("Nuit sans événements particuliers.",
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeathsPage(List<Player> sortedDeadPlayers) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sortedDeadPlayers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nightlight_round, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Text("Personne n'est mort cette nuit.",
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else ...[
            const Text("💀 DÉCÈS :",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...sortedDeadPlayers.map((p) {
              final String deathReason = widget.result.deathReasons[p.name] ?? '';
              final bool isHeartbreak = deathReason.contains("Chagrin d'amour");
              final Color borderColor = isHeartbreak
                  ? Colors.pinkAccent.withOpacity(0.7)
                  : _factionColor(p.team).withOpacity(0.6);
              final Color bgColor = isHeartbreak
                  ? Colors.pink.withOpacity(0.1)
                  : _factionColor(p.team).withOpacity(0.1);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor, width: isHeartbreak ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isHeartbreak ? Icons.favorite_border : _factionIcon(p.team),
                      color: isHeartbreak ? Colors.pinkAccent : _factionColor(p.team),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(
                            "${p.role}  •  $deathReason",
                            style: TextStyle(
                                color: isHeartbreak ? Colors.pinkAccent : Colors.white70,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
