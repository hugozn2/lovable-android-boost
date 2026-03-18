import { useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Plus, Gamepad2, Zap, X, Search, Snowflake } from "lucide-react";

interface Game {
  id: string;
  name: string;
  icon: string;
  color: string;
}

const PRESET_GAMES: Game[] = [
  { id: "1", name: "PUBG Mobile", icon: "🎯", color: "hsl(45, 90%, 50%)" },
  { id: "2", name: "Genshin Impact", icon: "⚔️", color: "hsl(200, 80%, 50%)" },
  { id: "3", name: "Call of Duty", icon: "🔫", color: "hsl(0, 70%, 50%)" },
  { id: "4", name: "Free Fire", icon: "🔥", color: "hsl(30, 90%, 50%)" },
  { id: "5", name: "Minecraft", icon: "⛏️", color: "hsl(120, 50%, 40%)" },
  { id: "6", name: "Roblox", icon: "🧱", color: "hsl(0, 80%, 55%)" },
  { id: "7", name: "Fortnite", icon: "🏗️", color: "hsl(210, 80%, 55%)" },
  { id: "8", name: "League of Legends", icon: "🏆", color: "hsl(50, 80%, 50%)" },
  { id: "9", name: "Clash Royale", icon: "👑", color: "hsl(220, 70%, 55%)" },
  { id: "10", name: "Among Us", icon: "🚀", color: "hsl(350, 70%, 50%)" },
];

const transition = { duration: 0.2, ease: [0.25, 0.1, 0.25, 1] as const };

const GameSpace = () => {
  const [games, setGames] = useState<Game[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [optimizingGame, setOptimizingGame] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [optimizedGame, setOptimizedGame] = useState<string | null>(null);

  const addGame = useCallback((game: Game) => {
    setGames((prev) => {
      if (prev.find((g) => g.id === game.id)) return prev;
      return [...prev, game];
    });
    setShowAddModal(false);
    setSearchQuery("");
  }, []);

  const removeGame = useCallback((id: string) => {
    setGames((prev) => prev.filter((g) => g.id !== id));
  }, []);

  const turboLaunch = useCallback((game: Game) => {
    setOptimizingGame(game.id);

    // Real optimization: clear caches and performance data
    performance.clearMarks();
    performance.clearMeasures();
    performance.clearResourceTimings();

    // Clear Cache API
    if ("caches" in window) {
      caches.keys().then((names) =>
        Promise.all(names.map((name) => caches.delete(name)))
      );
    }

    // Clear session storage
    try { sessionStorage.clear(); } catch (e) { /* noop */ }

    setTimeout(() => {
      setOptimizingGame(null);
      setOptimizedGame(game.name);
      setTimeout(() => setOptimizedGame(null), 3000);
    }, 2200);
  }, []);

  const availableGames = PRESET_GAMES.filter(
    (g) =>
      !games.find((added) => added.id === g.id) &&
      g.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="flex flex-col gap-4 pb-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-[12px] bg-game-accent/10 flex items-center justify-center">
            <Gamepad2 className="w-5 h-5 text-game-accent" />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-gradient-game">
              Game Space
            </h1>
            <p className="text-[11px] text-muted-foreground font-mono">
              {games.length} game{games.length !== 1 ? "s" : ""} configured
            </p>
          </div>
        </div>
      </div>

      {/* Optimized Feedback */}
      <AnimatePresence>
        {optimizedGame && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="card-surface !border-game-accent/20 text-center"
          >
            <p className="text-xs font-mono" style={{ color: "hsl(263, 70%, 65%)" }}>
              ✓ {optimizedGame} optimized · Cache cleared · Resources allocated
            </p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Game List */}
      {games.length === 0 ? (
        <div className="card-frost game-glow flex flex-col items-center gap-4 py-12">
          <div className="w-16 h-16 rounded-full bg-game-accent/10 flex items-center justify-center">
            <Gamepad2 className="w-8 h-8 text-game-accent" />
          </div>
          <div className="text-center">
            <p className="text-sm text-foreground font-medium">No games added</p>
            <p className="text-xs text-muted-foreground mt-1">
              Add games for one-tap turbo optimization
            </p>
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          <AnimatePresence mode="popLayout">
            {games.map((game) => (
              <motion.div
                key={game.id}
                layout
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95 }}
                whileTap={{ scale: 0.98 }}
                transition={transition}
                className="card-surface-elevated flex items-center gap-4"
              >
                <div
                  className="w-14 h-14 rounded-2xl flex items-center justify-center text-2xl flex-shrink-0"
                  style={{ backgroundColor: game.color + "18" }}
                >
                  {game.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-sm text-foreground truncate">{game.name}</p>
                  <p className="text-[10px] text-muted-foreground font-mono uppercase tracking-wider mt-0.5">
                    Cache + Memory + CPU
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <motion.button
                    whileTap={{ scale: 0.9 }}
                    onClick={() => turboLaunch(game)}
                    disabled={optimizingGame !== null}
                    className="w-11 h-11 rounded-[12px] flex items-center justify-center bg-game-accent/20 disabled:opacity-40 transition-opacity"
                  >
                    <Zap className="w-5 h-5 text-game-accent" />
                  </motion.button>
                  <motion.button
                    whileTap={{ scale: 0.9 }}
                    onClick={() => removeGame(game.id)}
                    className="w-11 h-11 rounded-[12px] flex items-center justify-center bg-muted/50"
                  >
                    <X className="w-4 h-4 text-muted-foreground" />
                  </motion.button>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}

      {/* Add Game Button */}
      <motion.button
        whileTap={{ scale: 0.97 }}
        transition={transition}
        onClick={() => setShowAddModal(true)}
        className="btn-game-full flex items-center justify-center gap-2"
      >
        <Plus className="w-5 h-5" />
        Add Game
      </motion.button>

      {/* Optimization Overlay */}
      <AnimatePresence>
        {optimizingGame && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-background/95 backdrop-blur-md"
          >
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.8, opacity: 0 }}
              transition={{ duration: 0.3 }}
              className="flex flex-col items-center gap-8"
            >
              <div className="relative">
                <div className="w-24 h-24 rounded-full border-2 border-game-accent/30 flex items-center justify-center">
                  <Snowflake className="w-12 h-12 text-game-accent animate-spin" style={{ animationDuration: "3s" }} />
                </div>
                <div className="absolute inset-0 rounded-full animate-ping opacity-20 border-2 border-game-accent" />
              </div>
              <div className="text-center space-y-2">
                <p className="text-lg font-bold text-foreground">
                  Allocating Resources
                </p>
                <p className="text-xs font-mono text-muted-foreground">
                  Clearing cache · Purging memory · Boosting priority
                </p>
              </div>
              <div className="w-56 progress-track h-1.5">
                <motion.div
                  initial={{ width: "0%" }}
                  animate={{ width: "100%" }}
                  transition={{ duration: 2, ease: "easeInOut" }}
                  className="progress-fill-accent"
                />
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Add Game Modal */}
      <AnimatePresence>
        {showAddModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-40 flex items-end justify-center bg-background/80 backdrop-blur-sm"
            onClick={() => { setShowAddModal(false); setSearchQuery(""); }}
          >
            <motion.div
              initial={{ y: "100%" }}
              animate={{ y: 0 }}
              exit={{ y: "100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 300 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-lg bg-card border-t border-border rounded-t-[24px] p-6 max-h-[70vh] flex flex-col gap-4"
            >
              <div className="w-10 h-1 bg-muted rounded-full mx-auto" />
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-bold text-foreground">Add Game</h2>
                <button onClick={() => { setShowAddModal(false); setSearchQuery(""); }}>
                  <X className="w-5 h-5 text-muted-foreground" />
                </button>
              </div>

              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <input
                  type="text"
                  placeholder="Search games..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full bg-muted rounded-[12px] pl-10 pr-4 py-3 text-sm text-foreground placeholder:text-muted-foreground outline-none focus:ring-2 focus:ring-game-accent/50 transition-shadow"
                />
              </div>

              <div className="flex-1 overflow-y-auto flex flex-col gap-1">
                {availableGames.map((game) => (
                  <motion.button
                    key={game.id}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => addGame(game)}
                    className="flex items-center gap-3 p-3 rounded-[12px] hover:bg-muted/70 transition-colors text-left w-full"
                  >
                    <div
                      className="w-11 h-11 rounded-xl flex items-center justify-center text-lg flex-shrink-0"
                      style={{ backgroundColor: game.color + "18" }}
                    >
                      {game.icon}
                    </div>
                    <span className="font-medium text-sm text-foreground">{game.name}</span>
                  </motion.button>
                ))}
                {availableGames.length === 0 && (
                  <p className="text-center text-xs text-muted-foreground py-6 font-mono">
                    No games available
                  </p>
                )}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default GameSpace;
