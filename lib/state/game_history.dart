// --- HISTORIQUE DE LA PARTIE ---

class EliminationRecord {
  final String playerName;
  final String role;
  final String? team;
  final String reason;

  EliminationRecord({
    required this.playerName,
    required this.role,
    this.team,
    required this.reason,
  });
}

class TurnHistoryEntry {
  final int turn;
  final String phase; // "nuit" ou "jour"
  final List<EliminationRecord> eliminations; // mutable pour fusion via addToHistory

  TurnHistoryEntry({
    required this.turn,
    required this.phase,
    required this.eliminations,
  });
}

List<TurnHistoryEntry> gameHistory = [];

void resetGameHistory() => gameHistory = [];

/// Ajoute des éliminations à l'entrée existante du même (turn, phase),
/// ou crée une nouvelle entrée si elle n'existe pas encore.
void addToHistory(int turn, String phase, List<EliminationRecord> eliminations) {
  TurnHistoryEntry? existing;
  for (int i = gameHistory.length - 1; i >= 0; i--) {
    if (gameHistory[i].turn == turn && gameHistory[i].phase == phase) {
      existing = gameHistory[i];
      break;
    }
  }
  if (existing != null) {
    existing.eliminations.addAll(eliminations);
  } else {
    gameHistory.add(TurnHistoryEntry(turn: turn, phase: phase, eliminations: eliminations));
  }
}
