import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pick_ban_screen.dart';
import 'globals.dart';
import 'backup_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'trophy_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  // --- LOGIQUE DE RÉINITIALISATION GLOBALE (HARD RESET) ---
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Table rase ?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Cela supprimera TOUS les joueurs, leurs succès, les stats globales et remettra les réglages par défaut.\n\n(Vos préférences audio seront conservées).",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ANNULER", style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () async {
              // APPEL DU HARD RESET : eraseAllHistory mis à true
              await resetAllGameData(eraseAllHistory: true);

              if (mounted) {
                setState(() {}); // Rafraîchit l'écran pour mettre à jour l'UI (liste vide)
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Base de données et statistiques entièrement effacées."),
                      backgroundColor: Colors.redAccent
                  ),
                );
              }
            },
            child: const Text("TOUT EFFACER", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // --- LOGIQUE IMPORTATION ---
  void _confirmImport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Importer une sauvegarde", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Ceci fusionnera les joueurs et remplacera les trophées/stats par ceux du fichier.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              Navigator.pop(ctx);
              BackupService.importData(context).then((_) {
                setState(() {});
              });
            },
            child: const Text("CHOISIR FICHIER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LOGIQUE SUPPRESSION INDIVIDUELLE ---
  void _showDeletePlayerDialog() async {
    if (globalPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucun joueur dans la liste actuelle."))
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Supprimer un joueur", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: globalPlayers.length,
            itemBuilder: (context, index) {
              final player = globalPlayers[index];
              return ListTile(
                title: Text(player.name, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onTap: () async {
                  // 1. SUPPRESSION DES STATS (Succès, Victoires)
                  await TrophyService.deletePlayerStats(player.name);

                  // 2. SUPPRESSION DU JOUEUR DE LA LISTE LOCALE (RAM)
                  setState(() {
                    globalPlayers.removeAt(index);
                  });

                  // 3. MISE À JOUR DU RÉPERTOIRE PERSISTANT (Disque)
                  final prefs = await SharedPreferences.getInstance();
                  List<String> names = globalPlayers.map((p) => p.name).toList();
                  await prefs.setStringList('saved_players_list', names);

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${player.name} retiré et stats réinitialisées."))
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("FERMER", style: TextStyle(color: Colors.white54))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("Paramètres"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- AUDIO ---
          ListTile(
            title: const Text("Musique de fond", style: TextStyle(color: Colors.white)),
            trailing: Switch(
              activeColor: Colors.orangeAccent,
              value: globalMusicEnabled,
              onChanged: (v) {
                setState(() => globalMusicEnabled = v);
                saveAudioSettings();
              },
            ),
          ),
          ListTile(
            title: const Text("Effets sonores (SFX)", style: TextStyle(color: Colors.white)),
            trailing: Switch(
              activeColor: Colors.orangeAccent,
              value: globalSfxEnabled,
              onChanged: (v) {
                setState(() => globalSfxEnabled = v);
                saveAudioSettings();
              },
            ),
          ),

          const Divider(color: Colors.white24),

          // --- TIMER ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              "Durée du Timer : ${globalTimerMinutes.toInt()} min",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Slider(
            value: globalTimerMinutes,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            activeColor: Colors.orangeAccent,
            onChanged: (v) => setState(() => globalTimerMinutes = v),
          ),

          const Divider(color: Colors.white24),

          // --- PICK & BAN ---
          ListTile(
            title: const Text("Choisir les rôles (Pick & Ban)", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.edit, color: Colors.orangeAccent),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const PickBanScreen())
            ),
          ),
          ListTile(
            title: const Text("Version du jeu", style: TextStyle(color: Colors.white)),
            subtitle: Text(globalGameVersion, style: const TextStyle(color: Colors.white38)),
            trailing: const Icon(Icons.info_outline, color: Colors.white24),
          ),

          const Divider(color: Colors.white24, height: 40),
          const Text("GESTION DE LA MÉMOIRE", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 15),

          // --- BOUTONS EXPORT / IMPORT ---
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    foregroundColor: Colors.blueAccent,
                    side: const BorderSide(color: Colors.blueAccent),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => BackupService.exportData(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("EXPORTER"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                    foregroundColor: Colors.purpleAccent,
                    side: const BorderSide(color: Colors.purpleAccent),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _confirmImport(context),
                  icon: const Icon(Icons.file_download),
                  label: const Text("IMPORTER"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- BOUTONS SUPPRESSION ---
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withOpacity(0.1),
              foregroundColor: Colors.orangeAccent,
              side: const BorderSide(color: Colors.orangeAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showDeletePlayerDialog,
            icon: const Icon(Icons.person_remove),
            label: const Text("SUPPRIMER UN JOUEUR"),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showResetDialog,
            icon: const Icon(Icons.delete_forever),
            label: const Text("RÉINITIALISER TOUT"),
          ),
        ],
      ),
    );
  }
}