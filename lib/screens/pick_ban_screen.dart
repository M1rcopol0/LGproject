import 'package:flutter/material.dart';
import '../globals.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PickBanScreen extends StatefulWidget {
  const PickBanScreen({super.key});

  @override
  State<PickBanScreen> createState() => _PickBanScreenState();
}

class _PickBanScreenState extends State<PickBanScreen> {
  late List<RoleItem> villageRoles;
  late List<RoleItem> wolfRoles;
  late List<RoleItem> soloRoles;

  // Définition du Preset 2.0
  final List<String> preset2_0 = [
    "Chasseur",
    "Cupidon",
    "Grand-mère",
    "Kung-Fu Panda",
    "Saltimbanque",
    "Sorcière",
    "Villageois",
    "Voyante",
    "Loup-garou évolué"
  ];

  // Définition du Preset 3.0 (Les autres + Grand-mère + LG évolué)
  final List<String> preset3_0 = [
    // Village (Exclus du 2.0)
    "Archiviste", "Devin", "Dingo", "Zookeeper", "Enculateur du bled",
    "Exorciste", "Houston", "Maison", "Tardos", "Voyageur",
    // Inclus aussi dans 3.0
    "Grand-mère",

    // Loups (Exclus du 2.0)
    "Loup-garou chaman", "Somnifère",
    // Inclus aussi dans 3.0
    "Loup-garou évolué",

    // Solos (Tous, car aucun dans la 2.0)
    "Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Ron-Aldo"
  ];

  @override
  void initState() {
    super.initState();
    _initializeLists();
  }

  void _initializeLists() {
    // Liste complète des rôles Villageois (Incluant les nouveaux)
    final allVillage = [
      "Archiviste", "Devin", "Dingo", "Zookeeper", "Enculateur du bled",
      "Exorciste", "Grand-mère", "Houston", "Maison", "Tardos", "Villageois", "Voyageur",
      "Sorcière", "Cupidon", "Voyante", "Saltimbanque", "Chasseur", "Kung-Fu Panda"
    ];

    // Liste complète des rôles Loups (Incluant le classique)
    final allWolves = [
      "Loup-garou chaman", "Loup-garou évolué", "Somnifère"
    ];

    final allSolos = ["Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Ron-Aldo"];

    // TRI ALPHABÉTIQUE (Pour l'affichage)
    allVillage.sort((a, b) => a.compareTo(b));
    allWolves.sort((a, b) => a.compareTo(b));
    allSolos.sort((a, b) => a.compareTo(b));

    // Mapping et récupération de l'état de sélection depuis globals.dart
    villageRoles = allVillage.map((name) {
      bool selected = globalPickBan["village"]?.contains(name) ?? false;
      return RoleItem(name, isSelected: selected);
    }).toList();

    wolfRoles = allWolves.map((name) {
      bool selected = globalPickBan["loups"]?.contains(name) ?? false;
      return RoleItem(name, isSelected: selected);
    }).toList();

    soloRoles = allSolos.map((name) {
      bool selected = globalPickBan["solo"]?.contains(name) ?? false;
      return RoleItem(
          name,
          isSelected: selected,
          displayName: (name == "Dresseur") ? "Dresseur & Pokémon" : name
      );
    }).toList();

    _saveToGlobals();
  }

  void _saveToGlobals() {
    globalPickBan["village"] = villageRoles.where((r) => r.isSelected).map((r) => r.name).toList();
    globalPickBan["loups"] = wolfRoles.where((r) => r.isSelected).map((r) => r.name).toList();

    List<String> selectedSolos = soloRoles.where((r) => r.isSelected).map((r) => r.name).toList();
    // Logique spéciale pour ajouter automatiquement le Pokémon si le Dresseur est choisi
    if (selectedSolos.contains("Dresseur")) {
      if (!selectedSolos.contains("Pokémon")) selectedSolos.add("Pokémon");
    }
    globalPickBan["solo"] = selectedSolos;
  }

  // Fonction pour appliquer un preset
  void _applyPreset(List<String> targetRoles) {
    setState(() {
      for (var r in villageRoles) {
        r.isSelected = targetRoles.contains(r.name);
      }
      for (var r in wolfRoles) {
        r.isSelected = targetRoles.contains(r.name);
      }
      for (var r in soloRoles) {
        r.isSelected = targetRoles.contains(r.name);
      }
      _saveToGlobals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("Gestion des rôles"),
        backgroundColor: const Color(0xFF1D1E33),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Réinitialiser",
            onPressed: () {
              setState(() {
                // Reset propre : tout vide par défaut pour permettre une sélection personnalisée
                globalPickBan["village"] = [];
                globalPickBan["loups"] = [];
                globalPickBan["solo"] = [];
                _initializeLists();
              });
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- BOUTONS DE PRESETS ---
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  onPressed: () => _applyPreset(preset2_0),
                  child: const Text("PRESET 2.0", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  onPressed: () => _applyPreset(preset3_0),
                  child: const Text("PRESET 3.0", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          _buildFactionHeader("VILLAGE", Colors.greenAccent),
          _buildRoleGrid(villageRoles),
          const SizedBox(height: 20),
          _buildFactionHeader("LOUPS-GAROUS", Colors.redAccent),
          _buildRoleGrid(wolfRoles),
          const SizedBox(height: 20),
          _buildFactionHeader("SOLO", Colors.orangeAccent),
          _buildRoleGrid(soloRoles),
          const SizedBox(height: 100),
        ],
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF1D1E33),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text("SAUVEGARDER ET RETOURNER", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFactionHeader(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: color),
          const SizedBox(width: 10),
          Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildRoleGrid(List<RoleItem> roles) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              role.isSelected = !role.isSelected;
            });
            _saveToGlobals();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: role.isSelected ? Colors.indigo.withOpacity(0.5) : Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: role.isSelected ? Colors.indigoAccent : Colors.white10,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  role.isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: role.isSelected ? Colors.white : Colors.white24,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    role.displayName ?? role.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: role.isSelected ? Colors.white : Colors.white54,
                      fontSize: 10,
                      fontWeight: role.isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RoleItem {
  final String name;
  final String? displayName;
  bool isSelected;
  RoleItem(this.name, {this.isSelected = false, this.displayName});
}