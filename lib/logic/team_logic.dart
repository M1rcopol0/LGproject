class TeamLogic {
  static const List<String> wolfRoles = [
    "loup-garou chaman",
    "loup-garou évolué",
    "somnifère"
  ];

  static const List<String> soloRoles = [
    "chuchoteur",
    "maître du temps",
    "pantin",
    "phyl",
    "dresseur",
    "pokémon",
    "ron-aldo",
    "fan de ron-aldo"
  ];

  static String getTeamForRole(String role) {
    final rLower = role.toLowerCase().trim();
    if (wolfRoles.contains(rLower) || rLower.contains("loup")) return "loups";
    if (soloRoles.contains(rLower)) return "solo";
    return "village";
  }
}
