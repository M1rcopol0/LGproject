import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/player.dart';
import 'logic/logic.dart';
import 'screens/vote_screens.dart';
import 'screens/mj_result_screen.dart';
import 'screens/night_actions_screen.dart';
import 'screens/settings_screen.dart';
import 'wiki_page.dart';
import 'screens/roulette_screen.dart';
import 'globals.dart';
import 'screens/fin_screen.dart';
import 'services/game_save_service.dart';
import 'logic/achievement_logic.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/achievement.dart';
import 'services/trophy_service.dart';
import 'cloud_service.dart';
import 'achievements_page.dart';

// Import des widgets modulaires
import 'widgets/game_info_header.dart';
import 'widgets/player_list_card.dart';
import 'widgets/game_action_buttons.dart';

class GameMenuScreen extends StatefulWidget {
  final List<Player> players;
  const GameMenuScreen({super.key, required this.players});

  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  Timer? _timer;
  int _currentSeconds = 0;
  bool _isTimerRunning = false;
  bool _isGameOverProcessing = false;

  @override
  void initState() {
    super.initState();
    debugPrint("📱 LOG [Menu] : Initialisation de l'écran principal.");
    _currentSeconds = (globalTimerMinutes * 60).toInt();
    _recoverActivePlayers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGameStateIntegrity();
    });
  }

  void _recoverActivePlayers() {
    if (globalRolesDistributed) {
      for (var p in widget.players) {
        if (p.role != null && p.role!.isNotEmpty) {
          p.isPlaying = true;
        }
      }
    }
  }

  List<Player> get _activePlayers => widget.players.where((p) => p.isPlaying).toList();

  // ==========================================================
  // GESTION DU TIMER
  // ==========================================================

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_isTimerRunning) return;
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

  // ==========================================================
  // NAVIGATION & FLUX DE JEU
  // ==========================================================

  void _goToNight({bool force = false}) {
    bool isFirstNight = (globalTurnNumber == 1 && !nightOnePassed);

    if (!force && !hasVotedThisTurn && !isFirstNight) {
      _showVoteForgottenDialog();
      return;
    }

    debugPrint("🌙 LOG [Menu] : Passage à la nuit (Fin Jour $globalTurnNumber).");

    // 1. Préparation des variables via Logic
    // On n'incrémente PAS le tour ici.
    GameLogic.nextTurn(_activePlayers);

    _resetTimer();
    isDayTime = false;
    playMusic("ambiance_nuit.mp3");

    // 2. Navigation vers l'écran de nuit
    Navigator.push(context, MaterialPageRoute(builder: (_) => NightActionsScreen(players: _activePlayers))).then((_) async {
      // 3. RETOUR (MATIN)
      if (!mounted) return;

      setState(() {
        // Mise à jour des compteurs temporels
        nightOnePassed = true;
        globalTurnNumber++;
        isDayTime = true;
        hasVotedThisTurn = false;
        _resetTimer();
      });

      debugPrint("🔴 DEBUG_TRACE [Menu] : Retour de nuit. Check Exorciste: $exorcistWin");

      if (exorcistWin) {
        debugPrint("🏆 LOG [Menu] : Victoire Exorciste détectée au réveil !");
        await GameSaveService.clearSave(); // Nettoyage save
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: "EXORCISTE", players: widget.players)),
                (route) => false
        );
        return; // On arrête tout ici
      }

      // Vérification standard (ex: plus de Loups, plus de Villageois)
      _checkGameStateIntegrity();

      // 4. Si la partie continue, on sauvegarde le nouvel état (Matin du Jour X)
      if (!_isGameOverProcessing) {
        debugPrint("✅ LOG [Menu] : Matin du Jour $globalTurnNumber - Sauvegarde...");
        await GameSaveService.saveGame();
      }
    });
  }

  void _showVoteForgottenDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("⚠️ Vote Oublié", style: TextStyle(color: Colors.redAccent)),
        content: const Text("Le village n'a pas voté ce jour."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER", style: TextStyle(color: Colors.white54))),
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

  void _goToVote() async {
    _resetTimer();
    await playSfx("vote_music.mp3");

    void onVoteComplete() {
      hasVotedThisTurn = true;
      setState(() {
        _checkGameOver();
        if (!_isGameOverProcessing) {
          bool chiefAlive = _activePlayers.any((p) => p.isAlive && p.isVillageChief);
          if (!chiefAlive) _showChiefElectionDialog();
        }
        isDayTime = false;
        _resetTimer();
      });
    }

    debugPrint("🗳️ LOG [Menu] : Option Vote Anonyme = $globalVoteAnonyme");

    if (globalVoteAnonyme) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VotePlayerSelectionScreen(
        allPlayers: _activePlayers,
        onComplete: onVoteComplete,
      )));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MJResultScreen(
        allPlayers: _activePlayers,
        onComplete: onVoteComplete,
      )));
    }
  }

  void _startGame() async {
    if (_activePlayers.length < 3) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen()));
    setState(() {
      GameLogic.assignRoles(_activePlayers);
      globalRolesDistributed = true;
      globalTurnNumber = 1;
      isDayTime = true;
      nightOnePassed = false;
    });
    await GameSaveService.saveGame();
  }

  // ==========================================================
  // MENU DEV / ADMINISTRATION MJ
  // ==========================================================

  void _handlePlayerTap(Player p) {
    if (!globalRolesDistributed) {
      setState(() => p.isPlaying = !p.isPlaying);
      return;
    }
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
            Text(p.name.toUpperCase(),
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(p.role?.toUpperCase() ?? "SANS RÔLE",
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const Divider(color: Colors.white10, height: 30),
            ListTile(
              leading: Icon(p.isAlive ? Icons.dangerous : Icons.favorite, color: p.isAlive ? Colors.redAccent : Colors.greenAccent),
              title: Text(p.isAlive ? "ÉLIMINER LE JOUEUR" : "RESSUSCITER LE JOUEUR", style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                if (p.isAlive) {
                  _executeManualElimination(p);
                } else {
                  _executeManualResurrection(p);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high, color: Colors.blueAccent),
              title: const Text("APPLIQUER UN EFFET / ÉTAT", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showEffectsMenu(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text("NOMMER CHEF DU VILLAGE", style: TextStyle(color: Colors.white)),
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
              title: const Text("GÉRER LES SUCCÈS (MJ)", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showAchievementManager(p);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementManager(Player p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text("Succès de ${p.name}", style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<String>>(
            future: TrophyService.getUnlockedAchievements(p.name),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              List<String> unlocked = List.from(snapshot.data ?? []);
              return StatefulBuilder(
                  builder: (context, setStateInner) {
                    return ListView.builder(
                      itemCount: AchievementData.allAchievements.length,
                      itemBuilder: (context, index) {
                        final ach = AchievementData.allAchievements[index];
                        final isUnlocked = unlocked.contains(ach.id);
                        return CheckboxListTile(
                          title: Text(ach.title, style: TextStyle(color: isUnlocked ? Colors.white : Colors.white54)),
                          value: isUnlocked,
                          activeColor: ach.color,
                          checkColor: Colors.black,
                          onChanged: (val) async {
                            if (val == true) {
                              await TrophyService.unlockAchievement(p.name, ach.id);
                              unlocked.add(ach.id);
                            } else {
                              await TrophyService.removeAchievement(p.name, ach.id);
                              unlocked.remove(ach.id);
                            }
                            setStateInner(() {});
                          },
                        );
                      },
                    );
                  }
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("FERMER"))],
      ),
    );
  }

  void _showEffectsMenu(Player p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E21),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _effectSwitch("Dans la Maison", p.isInHouse, (v) => setState(() => p.isInHouse = v)),
            _effectSwitch("Protégé (Dresseur)", p.isProtectedByPokemon, (v) => setState(() => p.isProtectedByPokemon = v)),
            _effectSwitch("Endormi (Venin/Somni)", p.isEffectivelyAsleep, (v) => setState(() => p.isEffectivelyAsleep = v)),
            _effectSwitch("Censuré (Muet)", p.isMutedDay, (v) => setState(() => p.isMutedDay = v)),
            _effectSwitch("Immunisé Vote (Bled)", p.isImmunizedFromVote, (v) => setState(() => p.isImmunizedFromVote = v)),
            _effectSwitch("Révélé (Devin)", p.isRevealedByDevin, (v) => setState(() => p.isRevealedByDevin = v)),
            _effectSwitch("En Voyage", p.isInTravel, (v) => setState(() => p.isInTravel = v)),
            _effectSwitch("Fan de Ron-Aldo", p.isFanOfRonAldo, (v) => setState(() => p.isFanOfRonAldo = v)),
            _effectSwitch("Transcendance (Absent)", p.isAwayAsMJ, (v) => setState(() => p.isAwayAsMJ = v)),
          ],
        ),
      ),
    );
  }

  Widget _effectSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(title: Text(label, style: const TextStyle(color: Colors.white)), value: value, activeColor: Colors.blueAccent, onChanged: onChanged);
  }

  void _executeManualElimination(Player p) async {
    hasVotedThisTurn = true;
    Player v = GameLogic.eliminatePlayer(context, _activePlayers, p, reason: "Élimination Manuelle (MJ)");
    setState(() {});
    playSfx("cloche.mp3");
    await _showDeathResultDialog(v);
    _checkGameStateIntegrity();
  }

  void _executeManualResurrection(Player p) {
    setState(() {
      p.isAlive = true;
      p.isEffectivelyAsleep = false;
      p.hasBeenHitByDart = false;
      if (p.role?.toLowerCase() == "maison") p.isHouseDestroyed = false;
    });
    playSfx("magic_sparkle.mp3");
    _checkGameStateIntegrity();
  }

  void _checkGameStateIntegrity() {
    _checkGameOver();
    if (!_isGameOverProcessing && isDayTime && nightOnePassed) {
      _checkChiefAlive();
    }
  }

  void _checkGameOver() async {
    if (_isGameOverProcessing || !globalRolesDistributed) return;
    String? winner = GameLogic.checkWinner(_activePlayers);
    if (winner == null) return;
    if (globalTurnNumber <= 1 && !nightOnePassed) return;

    List<Player> winnersList = _activePlayers.where((p) =>
    (winner == "VILLAGE" && p.team == "village") ||
        (winner == "LOUPS" && p.team == "loups") ||
        (winner == "SOLO" && p.team == "solo")
    ).toList();

    await AchievementLogic.checkEndGameAchievements(context, winnersList, widget.players);

    setState(() => _isGameOverProcessing = true);
    _timer?.cancel();
    GameSaveService.clearSave();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: winner, players: widget.players)),
          (route) => false,
    );
  }

  void _checkChiefAlive() {
    bool chiefExists = _activePlayers.any((p) => p.isAlive && p.isVillageChief);
    if (!chiefExists) _showChiefElectionDialog();
  }

  void _showChiefElectionDialog() {
    List<Player> eligible = _activePlayers.where((p) => p.isAlive).toList();
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
                });
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _addPlayerDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedNames = prefs.getStringList("saved_players_list") ?? [];
    String currentNameInput = "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("NOUVEAU JOUEUR", style: TextStyle(color: Colors.white)),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => currentNameInput = v,
          decoration: const InputDecoration(labelText: "Nom"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          ElevatedButton(onPressed: () {
            if (currentNameInput.isNotEmpty) {
              setState(() => widget.players.add(Player(name: currentNameInput, isPlaying: true)));
              Navigator.pop(ctx);
            }
          }, child: const Text("AJOUTER"))
        ],
      ),
    );
  }

  Future<void> _showDeathResultDialog(Player victim) async {
    return showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: const Text("MORT CONFIRMÉE", style: TextStyle(color: Colors.white)),
      content: Text("${victim.name} était ${victim.role?.toUpperCase()}.", style: const TextStyle(color: Colors.white70)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)))],
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Player> displayList = globalRolesDistributed ? _activePlayers : List.from(widget.players);
    displayList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(!globalRolesDistributed ? "PRÉPARATION" : (isDayTime ? "JOUR $globalTurnNumber" : "NUIT $globalTurnNumber"), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.casino), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen()))),
          IconButton(
            icon: const Icon(FontAwesomeIcons.trophy, color: Colors.amber, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsPage())),
          ),
          IconButton(icon: const Icon(Icons.menu_book), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WikiPage()))),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Column(
        children: [
          GameInfoHeader(
            isGameStarted: globalRolesDistributed,
            playerCount: _activePlayers.length,
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
                  isGameStarted: globalRolesDistributed,
                  onTap: () => _handlePlayerTap(p),
                  onCheckChanged: !globalRolesDistributed
                      ? (v) => setState(() => p.isPlaying = v!)
                      : null,
                );
              },
            ),
          ),
          GameActionButtons(
            isGameStarted: globalRolesDistributed,
            onVote: _goToVote,
            onNight: () => _goToNight(force: false),
            onStartGame: _startGame,
            onAddPlayer: () => _addPlayerDialog(context),
          ),
        ],
      ),
    );
  }
}