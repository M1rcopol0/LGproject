import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/player.dart';
import '../logic/logic.dart';
import '../globals.dart';
import '../services/game_save_service.dart';
import '../services/trophy_service.dart';
import '../services/audio_service.dart'; // Pour centraliser l'audio
import '../player_storage.dart';
import 'fin_screen.dart';
import '../models/achievement.dart';

// Écrans de phase
import 'night_actions_screen.dart';
import 'vote_screens.dart';
import 'mj_result_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/wiki_screen.dart';
import 'settings_screen.dart';
import 'game_history_screen.dart';
import '../state/game_history.dart';

// Widgets
import '../widgets/game_info_header.dart';
import '../widgets/player_list_card.dart';
import '../widgets/game_action_buttons.dart';

class VillageScreen extends StatefulWidget {
  final List<Player> players;
  const VillageScreen({super.key, required this.players});

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  Timer? _timer;
  int _currentSeconds = 0;
  bool _isTimerRunning = false;
  bool _isGameOverProcessing = false;

  @override
  void initState() {
    super.initState();
    debugPrint("🏡 LOG [Village] : Arrivée au village.");
    _currentSeconds = (globalTimerMinutes * 60).toInt();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGameStateIntegrity();
    });
  }

  // --- TIMER ---
  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_currentSeconds > 0) {
          setState(() => _currentSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _isTimerRunning = false);
          playSfx("alarm.mp3");
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _currentSeconds = (globalTimerMinutes * 60).toInt();
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  // --- TRANSITIONS ANIMÉES ---

  PageRoute _fadeRoute(Widget page, {int ms = 350}) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: Duration(milliseconds: ms),
    transitionsBuilder: (_, anim, __, child) =>
      FadeTransition(opacity: anim, child: child),
  );

  void _showHistory() {
    Navigator.push(context, _fadeRoute(
      GameHistoryScreen(history: gameHistory),
      ms: 250,
    ));
  }

  // --- NAVIGATION PHASES DE JEU ---

  void _goToNight({bool force = false}) {
    bool isFirstNight = (globalTurnNumber == 1 && !nightOnePassed);

    if (!force && !hasVotedThisTurn && !isFirstNight) {
      _showVoteForgottenDialog();
      return;
    }

    debugPrint("🌙 LOG [Village] : Départ pour la Nuit $globalTurnNumber.");

    // Préparation logique
    GameLogic.nextTurn(widget.players);
    _resetTimer();
    setState(() => isDayTime = false);
    playMusic("ambiance_nuit.mp3");

    Navigator.push(
        context,
        _fadeRoute(NightActionsScreen(players: widget.players), ms: 600),
    ).then((_) async {
      if (!mounted) return;

      // Si NightActionsScreen a navigué vers GameOverScreen via pushAndRemoveUntil,
      // VillageScreen n'est plus la route active → le callback .then s'est quand même
      // déclenché (pop implicite) mais on ne doit rien faire.
      if (ModalRoute.of(context)?.isCurrent != true) {
        debugPrint("⚠️ LOG [Village] : Callback nuit ignoré (NightActionsScreen a terminé la partie).");
        return;
      }

      // Retour de la nuit (Matin)
      setState(() {
        nightOnePassed = true;
        globalTurnNumber++;
        isDayTime = true;
        hasVotedThisTurn = false;
        _resetTimer();
      });

      _checkGameStateIntegrity();
      if (!_isGameOverProcessing) {
        await GameSaveService.saveGame();
      }
    });
  }

  void _goToVote() async {
    _resetTimer();
    playMusic("vote_music.mp3");

    void onVoteComplete() {
      stopMusic();
      hasVotedThisTurn = true;
      setState(() {
        _checkGameOver();
        if (!_isGameOverProcessing) {
          bool chiefAlive = widget.players.any((p) => p.isAlive && p.isVillageChief);
          if (!chiefAlive) _showChiefElectionDialog();
        }
        isDayTime = true; // Reste jour après le vote pour le débrief
        _resetTimer();
      });
    }

    if (globalVoteAnonyme) {
      debugPrint("🗳️ CAPTEUR [Vote] : Lancement vote anonyme.");
      Navigator.push(context, _fadeRoute(VotePlayerSelectionScreen(allPlayers: widget.players, onComplete: onVoteComplete), ms: 300));
    } else {
      debugPrint("🗳️ CAPTEUR [Vote] : Lancement vote MJ direct.");
      Navigator.push(context, _fadeRoute(MJResultScreen(allPlayers: widget.players, onComplete: onVoteComplete), ms: 300));
    }
  }

  void _showVoteForgottenDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("⚠️ Vote Oublié", style: TextStyle(color: Colors.redAccent)),
        content: const Text("Le village n'a pas voté ce jour."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _goToNight(force: true);
              },
              child: const Text("FORCER LA NUIT", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  // --- ADMINISTRATION (MJ) ---

  void _handlePlayerTap(Player p) {
    if (!p.isPlaying) return;
    _showPlayerAdminMenu(p);
  }

  void _showPlayerAdminMenu(Player p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.name.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(p.role?.toUpperCase() ?? "INCONNU", style: const TextStyle(color: Colors.white54, fontSize: 14)),
            if (p.phoneNumber != null) Text("📞 ${p.phoneNumber}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
            const Divider(color: Colors.white10, height: 30),

            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: const Text("ÉDITER (Nom/Tél)"),
              onTap: () { Navigator.pop(ctx); _showEditPlayerDialog(p); },
            ),
            ListTile(
              leading: Icon(p.isAlive ? Icons.dangerous : Icons.favorite, color: p.isAlive ? Colors.redAccent : Colors.greenAccent),
              title: Text(p.isAlive ? "ÉLIMINER" : "RESSUSCITER"),
              onTap: () {
                Navigator.pop(ctx);
                p.isAlive ? _executeManualElimination(p) : _executeManualResurrection(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.orangeAccent),
              title: const Text("CHANGER LE RÔLE"),
              onTap: () { Navigator.pop(ctx); _showRoleChangeDialog(p); },
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high, color: Colors.cyanAccent),
              title: const Text("APPLIQUER UN EFFET"),
              onTap: () { Navigator.pop(ctx); _showEffectsMenu(p); },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text("NOMMER CHEF"),
              onTap: () {
                setState(() {
                  for (var pl in widget.players) pl.isVillageChief = false;
                  p.isVillageChief = true;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.purpleAccent),
              title: const Text("GÉRER SUCCÈS"),
              onTap: () { Navigator.pop(ctx); _showAchievementManager(p); },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlayerDialog(Player p) {
    TextEditingController nameCtrl = TextEditingController(text: p.name);
    TextEditingController phoneCtrl = TextEditingController(text: p.phoneNumber ?? "");
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: const Text("Édition MJ"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom")),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Tél"), keyboardType: TextInputType.phone),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
        ElevatedButton(onPressed: () async {
          if (nameCtrl.text.isNotEmpty) {
            await PlayerDirectory.updatePlayerProfile(p.name, nameCtrl.text, phoneCtrl.text.isEmpty ? null : phoneCtrl.text);
            setState(() {
              p.name = Player.formatName(nameCtrl.text);
              p.phoneNumber = phoneCtrl.text.isEmpty ? null : phoneCtrl.text;
            });
            Navigator.pop(ctx);
          }
        }, child: const Text("OK"))
      ],
    ));
  }

  void _showRoleChangeDialog(Player p) {
    final List<String> allRoles = [
      ...allRolesByFaction["village"]!.map((r) => "$r (Village)"),
      ...allRolesByFaction["loups"]!.map((r) => "$r (Loups)"),
      ...allRolesByFaction["solo"]!.map((r) => "$r (Solo)"),
    ];
    String selectedDisplay = allRoles.isNotEmpty ? allRoles.first : "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateInner) => AlertDialog(
          backgroundColor: const Color(0xFF1D1E33),
          title: Text("Changer le rôle de ${p.name}"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Rôle actuel : ${p.role?.toUpperCase() ?? 'INCONNU'}", style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedDisplay,
              dropdownColor: const Color(0xFF1D1E33),
              isExpanded: true,
              items: allRoles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) { if (v != null) setStateInner(() => selectedDisplay = v); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                final rawRole = selectedDisplay.replaceAll(RegExp(r' \(.*\)$'), '');
                final newTeam = GameLogic.getTeamForRole(rawRole.toLowerCase());
                setState(() { p.changeRole(rawRole.toLowerCase(), newTeam); });
                Navigator.pop(ctx);
                debugPrint("🎭 MJ : Rôle de ${p.name} changé en $rawRole ($newTeam)");
              },
              child: const Text("CONFIRMER"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEffectsMenu(Player p) {
    Widget sectionHeader(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label, style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E21),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => StatefulBuilder(
          builder: (ctx, setStateInner) {
            void toggle(VoidCallback fn) { setStateInner(fn); setState(() {}); }
            return ListView(controller: controller, children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 8),

              // ⚔️ Protections
              sectionHeader("⚔️ Protections"),
              SwitchListTile(title: const Text("Protégé par le Saltimbanque"), value: p.isProtectedBySaltimbanque, onChanged: (v) => toggle(() => p.isProtectedBySaltimbanque = v), activeColor: Colors.greenAccent),
              SwitchListTile(title: const Text("Immunisé contre le vote (Bled)"), value: p.isImmunizedFromVote, onChanged: (v) => toggle(() => p.isImmunizedFromVote = v), activeColor: Colors.cyanAccent),
              SwitchListTile(title: const Text("Pouvoir de bouc émissaire (Archiviste)"), value: p.hasScapegoatPower, onChanged: (v) => toggle(() => p.hasScapegoatPower = v), activeColor: Colors.cyanAccent),

              // 🚫 Restrictions
              sectionHeader("🚫 Restrictions"),
              SwitchListTile(
                title: const Text("Touché par la fléchette du Zookeeper"),
                value: p.hasBeenHitByDart,
                onChanged: (v) => toggle(() {
                  p.hasBeenHitByDart = v;
                  p.zookeeperEffectReady = v;
                }),
                activeColor: Colors.purpleAccent,
              ),
              SwitchListTile(title: const Text("Maudit par le Pantin"), value: p.isCursed, onChanged: (v) => toggle(() => p.isCursed = v), activeColor: Colors.purpleAccent),
              SwitchListTile(title: const Text("Porteur d'une bombe (Tardos)"), value: p.isBombed, onChanged: (v) => toggle(() { p.isBombed = v; p.attachedBombTimer = v ? 2 : 0; }), activeColor: Colors.deepOrangeAccent),

              // ⚡ Effets spéciaux
              sectionHeader("⚡ Effets spéciaux"),
              SwitchListTile(title: const Text("Rôle révélé publiquement (Devin)"), value: p.isRevealedByDevin, onChanged: (v) => toggle(() => p.isRevealedByDevin = v), activeColor: Colors.cyanAccent),
              SwitchListTile(title: const Text("En voyage (Voyageur)"), value: p.isInTravel, onChanged: (v) => toggle(() => p.isInTravel = v), activeColor: Colors.redAccent),
              ListTile(
                title: const Text("Munitions du Voyageur", style: TextStyle(color: Colors.white)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent),
                      onPressed: p.travelerBullets > 0 ? () => toggle(() => p.travelerBullets--) : null,
                    ),
                    Text("${p.travelerBullets}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.orangeAccent),
                      onPressed: () => toggle(() => p.travelerBullets++),
                    ),
                  ],
                ),
              ),
              SwitchListTile(title: const Text("Absent — mode MJ (Transcendance)"), value: p.isAwayAsMJ, onChanged: (v) => toggle(() => p.isAwayAsMJ = v), activeColor: Colors.redAccent),


              // 🏠 États de rôle
              sectionHeader("🏠 États de rôle"),
              SwitchListTile(title: const Text("Hébergé dans la Maison"), value: p.isInHouse, onChanged: (v) => toggle(() => p.isInHouse = v), activeColor: Colors.blueAccent),
              SwitchListTile(title: const Text("Lié par Cupidon (couple)"), value: p.isLinkedByCupidon, onChanged: (v) => toggle(() => p.isLinkedByCupidon = v), activeColor: Colors.pinkAccent),
              SwitchListTile(title: const Text("Fan de Ron-Aldo (change l'équipe en solo)"), value: p.isFanOfRonAldo, onChanged: (v) { if (v) toggle(() { p.isFanOfRonAldo = true; p.changeRole("fan de ron-aldo", "solo"); }); }, activeColor: Colors.amberAccent),

              const SizedBox(height: 24),
            ]);
          },
        ),
      ),
    );
  }

  void _showAchievementManager(Player p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: Text("Succès de ${p.name}"), content: SizedBox(width: double.maxFinite, height: 400, child: FutureBuilder<List<String>>(future: TrophyService.getUnlockedAchievements(p.name), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); List<String> unlocked = List.from(snapshot.data ?? []); return StatefulBuilder(builder: (context, setStateInner) { return ListView.builder(itemCount: AchievementData.allAchievements.length, itemBuilder: (context, index) { final ach = AchievementData.allAchievements[index]; final isUnlocked = unlocked.contains(ach.id); return CheckboxListTile(title: Text(ach.title, style: TextStyle(color: isUnlocked ? Colors.white : Colors.white54)), value: isUnlocked, activeColor: ach.color, checkColor: Colors.black, onChanged: (val) async { if (val == true) { await TrophyService.unlockAchievement(p.name, ach.id); unlocked.add(ach.id); } else { await TrophyService.removeAchievement(p.name, ach.id); unlocked.remove(ach.id); } setStateInner(() {}); },);},);});},),), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("FERMER"))]));
  }

  void _executeManualElimination(Player p) async {
    debugPrint("🚀 CAPTEUR [Navigation] : Élimination manuelle MJ de ${p.name}.");

    // Correction : eliminationPlayer renvoie une Liste
    List<Player> victims = GameLogic.eliminatePlayer(context, widget.players, p, reason: "Élimination Manuelle (MJ)");

    setState(() {});
    playSfx("cloche.mp3");

    String msg = victims.isEmpty ? "Cible immunisée." : "${victims.map((v) => v.name).join(', ')} a/ont quitté la partie.";

    await showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("SENTENCE MJ"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]
    ));

    _checkGameStateIntegrity();
  }

  void _executeManualResurrection(Player p) {
    debugPrint("🚀 CAPTEUR [Navigation] : Résurrection manuelle MJ de ${p.name}.");
    setState(() {
      p.isAlive = true;
      p.isEffectivelyAsleep = false;
      p.hasBeenHitByDart = false;
      if (p.role?.toLowerCase() == "maison") p.isHouseDestroyed = false;
    });
    playSfx("magic_sparkle.mp3");
    _checkGameStateIntegrity();
  }

  // --- LOGIQUE DE FIN DE PARTIE ---

  void _checkGameStateIntegrity() {
    _checkGameOver();
    if (!_isGameOverProcessing && isDayTime && nightOnePassed) {
      bool chiefExists = widget.players.any((p) => p.isAlive && p.isVillageChief);
      if (!chiefExists) _showChiefElectionDialog();
    }
  }

  void _checkGameOver() {
    if (_isGameOverProcessing) return;
    String? winner = WinConditionLogic.checkWinner(widget.players);
    if (winner != null && (globalTurnNumber > 1 || nightOnePassed)) {
      _handleGameOver(winner);
    }
  }

  Future<void> _handleGameOver(String winnerRole) async {
    setState(() => _isGameOverProcessing = true);
    _timer?.cancel();

    await GameSaveService.clearSave();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      _fadeRoute(GameOverScreen(winnerType: winnerRole, players: widget.players), ms: 700),
      (route) => false,
    );
  }

  void _showChiefElectionDialog() {
    List<Player> eligible = widget.players.where((p) => p.isAlive).toList();
    eligible.sort((a, b) => a.name.compareTo(b.name));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("ÉLECTION DU CHEF", style: TextStyle(color: Colors.amberAccent)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: eligible.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(eligible[i].name, style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  for (var pl in widget.players) pl.isVillageChief = false;
                  eligible[i].isVillageChief = true;
                  debugPrint("🚀 CAPTEUR [Navigation] : Élection chef: ${eligible[i].name}.");
                });
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Player> displayList = List.from(widget.players);
    displayList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(isDayTime ? "JOUR $globalTurnNumber" : "NUIT $globalTurnNumber"),
        backgroundColor: const Color(0xFF1D1E33),
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white70), onPressed: _showHistory),
          IconButton(icon: const Icon(FontAwesomeIcons.trophy, color: Colors.amber, size: 20), onPressed: () {
            final activeRoles = [
              ...widget.players.map((p) => p.role ?? '').where((r) => r.isNotEmpty),
              'MODE_$globalGovernanceMode',
              ...widget.players.map((p) => 'PLAYER_${p.name}'),
            ];
            Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsPage(activeRoles: activeRoles)));
          }),
          IconButton(icon: const Icon(Icons.menu_book), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WikiPage()))),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Column(
        children: [
          GameInfoHeader(
            isGameStarted: true,
            playerCount: widget.players.where((p) => p.isAlive).length,
            timeString: _formatTime(_currentSeconds),
            isTimerRunning: _isTimerRunning,
            onToggleTimer: _toggleTimer,
            onResetTimer: _resetTimer,
          ),

          Expanded(
            child: ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final p = displayList[index];
                return PlayerListCard(
                  player: p,
                  isGameStarted: true,
                  onTap: () => _handlePlayerTap(p),
                  onCheckChanged: null,
                );
              },
            ),
          ),

          GameActionButtons(
            isGameStarted: true,
            onVote: _goToVote,
            onNight: () => _goToNight(force: false),
          ),
        ],
      ),
    );
  }
}