import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/player.dart';
import '../logic.dart';
import '../globals.dart';
import '../game_save_service.dart';
import '../achievement_logic.dart';
import '../trophy_service.dart';
import '../player_storage.dart';
import '../fin.dart';
import '../models/achievement.dart';

// Écrans de phase
import '../night_actions_screen.dart';
import '../vote_screens.dart';
import '../mj_result_screen.dart';
import '../achievements_page.dart';
import '../wiki_page.dart';
import '../settings_screen.dart';

// Widgets
import '../widgets/game_info_header.dart';
import '../widgets/player_list_card.dart';
import '../widgets/game_action_buttons.dart';

class VillageScreen extends StatefulWidget {
  final List<Player> players; // Ce sont les joueurs ACTIFS de la partie
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
        MaterialPageRoute(builder: (_) => NightActionsScreen(players: widget.players))
    ).then((_) async {
      if (!mounted) return;

      // Retour de la nuit (Matin)
      setState(() {
        nightOnePassed = true;
        globalTurnNumber++;
        isDayTime = true;
        hasVotedThisTurn = false;
        _resetTimer();
      });

      if (exorcistWin) {
        debugPrint("🏆 LOG [Village] : Victoire Exorciste !");
        await _handleGameOver("EXORCISTE");
        return;
      }

      _checkGameStateIntegrity();
      if (!_isGameOverProcessing) {
        await GameSaveService.saveGame();
      }
    });
  }

  void _goToVote() async {
    _resetTimer();
    await playSfx("vote_music.mp3");

    void onVoteComplete() {
      hasVotedThisTurn = true;
      setState(() {
        _checkGameOver();
        if (!_isGameOverProcessing) {
          bool chiefAlive = widget.players.any((p) => p.isAlive && p.isVillageChief);
          if (!chiefAlive) _showChiefElectionDialog();
        }
        isDayTime = false; // Fin de journée après le vote
        _resetTimer();
      });
    }

    if (globalVoteAnonyme) {
      debugPrint("🗳️ CAPTEUR [Vote] : Lancement vote anonyme.");
      Navigator.push(context, MaterialPageRoute(builder: (_) => VotePlayerSelectionScreen(allPlayers: widget.players, onComplete: onVoteComplete)));
    } else {
      debugPrint("🗳️ CAPTEUR [Vote] : Lancement vote MJ direct.");
      Navigator.push(context, MaterialPageRoute(builder: (_) => MJResultScreen(allPlayers: widget.players, onComplete: onVoteComplete)));
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
    if (!p.isPlaying) return; // Sécurité
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
              title: const Text("ÉDITER (Nom/Tél)", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _showEditPlayerDialog(p); },
            ),
            ListTile(
              leading: Icon(p.isAlive ? Icons.dangerous : Icons.favorite, color: p.isAlive ? Colors.redAccent : Colors.greenAccent),
              title: Text(p.isAlive ? "ÉLIMINER" : "RESSUSCITER", style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                p.isAlive ? _executeManualElimination(p) : _executeManualResurrection(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high, color: Colors.cyanAccent),
              title: const Text("APPLIQUER UN EFFET", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _showEffectsMenu(p); },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text("NOMMER CHEF", style: TextStyle(color: Colors.white)),
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
              title: const Text("GÉRER SUCCÈS", style: TextStyle(color: Colors.white)),
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
      title: const Text("Édition MJ", style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nom")),
        TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Tél"), keyboardType: TextInputType.phone),
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

  void _showEffectsMenu(Player p) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF0A0E21), builder: (ctx) => Container(padding: const EdgeInsets.all(20), child: ListView(children: [
      SwitchListTile(title: const Text("Dans la Maison", style: TextStyle(color: Colors.white)), value: p.isInHouse, onChanged: (v) => setState(() => p.isInHouse = v), activeColor: Colors.blueAccent),
      SwitchListTile(title: const Text("Protégé (Dresseur)", style: TextStyle(color: Colors.white)), value: p.isProtectedByPokemon, onChanged: (v) => setState(() => p.isProtectedByPokemon = v), activeColor: Colors.blueAccent),
      SwitchListTile(title: const Text("Endormi (Venin/Somni)", style: TextStyle(color: Colors.white)), value: p.isEffectivelyAsleep, onChanged: (v) => setState(() => p.isEffectivelyAsleep = v), activeColor: Colors.blueAccent),
      SwitchListTile(title: const Text("Censuré (Muet)", style: TextStyle(color: Colors.white)), value: p.isMutedDay, onChanged: (v) => setState(() => p.isMutedDay = v), activeColor: Colors.blueAccent),
      SwitchListTile(title: const Text("Immunisé Vote (Bled)", style: TextStyle(color: Colors.white)), value: p.isImmunizedFromVote, onChanged: (v) => setState(() => p.isImmunizedFromVote = v), activeColor: Colors.blueAccent),
      SwitchListTile(title: const Text("Révélé (Devin)", style: TextStyle(color: Colors.white)), value: p.isRevealedByDevin, onChanged: (v) => setState(() => p.isRevealedByDevin = v), activeColor: Colors.blueAccent),
      SwitchListTile(title: const Text("En Voyage", style: TextStyle(color: Colors.white)), value: p.isInTravel, onChanged: (v) => setState(() => p.isInTravel = v), activeColor: Colors.blueAccent),
      SwitchListTile(title: const Text("Fan de Ron-Aldo", style: TextStyle(color: Colors.white)), value: p.isFanOfRonAldo, onChanged: (v) => setState(() => p.isFanOfRonAldo = v), activeColor: Colors.blueAccent),
      SwitchListTile(title: const Text("Transcendance (Absent)", style: TextStyle(color: Colors.white)), value: p.isAwayAsMJ, onChanged: (v) => setState(() => p.isAwayAsMJ = v), activeColor: Colors.blueAccent),
    ])));
  }

  void _showAchievementManager(Player p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: Text("Succès de ${p.name}", style: const TextStyle(color: Colors.white)), content: SizedBox(width: double.maxFinite, height: 400, child: FutureBuilder<List<String>>(future: TrophyService.getUnlockedAchievements(p.name), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); List<String> unlocked = List.from(snapshot.data ?? []); return StatefulBuilder(builder: (context, setStateInner) { return ListView.builder(itemCount: AchievementData.allAchievements.length, itemBuilder: (context, index) { final ach = AchievementData.allAchievements[index]; final isUnlocked = unlocked.contains(ach.id); return CheckboxListTile(title: Text(ach.title, style: TextStyle(color: isUnlocked ? Colors.white : Colors.white54)), value: isUnlocked, activeColor: ach.color, checkColor: Colors.black, onChanged: (val) async { if (val == true) { await TrophyService.unlockAchievement(p.name, ach.id); unlocked.add(ach.id); } else { await TrophyService.removeAchievement(p.name, ach.id); unlocked.remove(ach.id); } setStateInner(() {}); },);},);});},),), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("FERMER"))]));
  }

  void _executeManualElimination(Player p) async {
    debugPrint("🚀 CAPTEUR [Navigation] : Élimination manuelle MJ de ${p.name} (${p.role}).");
    hasVotedThisTurn = true;
    Player v = GameLogic.eliminatePlayer(context, widget.players, p, reason: "Élimination Manuelle (MJ)");
    setState(() {});
    playSfx("cloche.mp3");

    // Popup confirmation
    await showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D1E33), title: const Text("MORT CONFIRMÉE", style: TextStyle(color: Colors.white)), content: Text("${v.name} était ${v.role?.toUpperCase()}.", style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));

    _checkGameStateIntegrity();
  }

  void _executeManualResurrection(Player p) {
    debugPrint("🚀 CAPTEUR [Navigation] : Résurrection manuelle MJ de ${p.name} (${p.role}).");
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
    String? winner = GameLogic.checkWinner(widget.players);
    if (winner != null && (globalTurnNumber > 1 || nightOnePassed)) {
      _handleGameOver(winner);
    }
  }

  Future<void> _handleGameOver(String winnerRole) async {
    setState(() => _isGameOverProcessing = true);
    _timer?.cancel();

    List<Player> winnersList = widget.players.where((p) =>
    (winnerRole == "VILLAGE" && p.team == "village") ||
        (winnerRole == "LOUPS" && p.team == "loups") ||
        (winnerRole == "SOLO" && p.team == "solo") ||
        (winnerRole == "EXORCISTE" && p.team == "village")
    ).toList();

    await AchievementLogic.checkEndGameAchievements(context, winnersList, widget.players);
    await GameSaveService.clearSave();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: winnerRole, players: widget.players)),
          (route) => false, // Retour à la racine (qui relancera le Lobby propre)
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
                  debugPrint("🚀 CAPTEUR [Navigation] : Élection chef: ${eligible[i].name} (${eligible[i].role}).");
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
    // Tri par nom pour l'affichage
    List<Player> displayList = List.from(widget.players);
    displayList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(isDayTime ? "JOUR $globalTurnNumber" : "NUIT $globalTurnNumber", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D1E33),
        actions: [
          IconButton(icon: const Icon(FontAwesomeIcons.trophy, color: Colors.amber, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsPage()))),
          IconButton(icon: const Icon(Icons.menu_book), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WikiPage()))),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Column(
        children: [
          GameInfoHeader(
            isGameStarted: true,
            playerCount: widget.players.where((p) => p.isAlive).length, // Affiche les vivants
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
                  onTap: () => _handlePlayerTap(p), // Ouvre le menu MJ
                  onCheckChanged: null, // Pas de case à cocher en jeu
                );
              },
            ),
          ),

          // BOUTONS ACTIONS DE JEU
          GameActionButtons(
            isGameStarted: true,
            onVote: _goToVote,
            onNight: () => _goToNight(force: false),
            // onStartGame et onAddPlayer ne sont pas utilisés ici (phase de jeu)
          ),
        ],
      ),
    );
  }
}