import '../models/player.dart';

// --- ETAT DU JEU (CYCLE) ---
List<Player> globalPlayers = [];
bool isDayTime = false;
int globalTurnNumber = 1;
double globalTimerMinutes = 2.0;
bool globalRolesDistributed = false;
bool hasVotedThisTurn = false;

// --- GOUVERNANCE (Maire / Roi / Dictateur) ---
String globalGovernanceMode = "MAIRE";

// --- FLAG CHRONOLOGIE ---
bool nightOnePassed = false;

// --- PARAMETRES DE VOTE ---
bool globalVoteAnonyme = true;

void resetGameState() {
  globalTimerMinutes = 2.0;
  isDayTime = false;
  globalTurnNumber = 1;
  globalRolesDistributed = false;
  nightOnePassed = false;
  hasVotedThisTurn = false;
  globalGovernanceMode = "MAIRE";
}
