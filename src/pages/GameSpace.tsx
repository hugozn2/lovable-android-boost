import { useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Plus, Gamepad2, Zap, X, Search } from "lucide-react";

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

  const addGame = useCallback((game: Game) => {
    setGames((prev) => {
      if (prev.find((g) => g.id === game.id)) return prev;
      return [...prev, game];
    });
    setShowAddModal(false);
  }, []);

  const removeGame = useCallback((id: string) => {
    setGames((prev) => prev.filter((g) => g.id !== id));
  }, []);

  const turboLaunch = useCallback((game: Game) => {
    setOptimizingGame(game.id);
    // Simulate optimization + launch
    setTimeout(() => {
      setOptimizingGame(null);
    }, 2500);
  }, []);

  const availableGames = PRESET_GAMES.filter(
    (g) =>
      !games.find((added) => added.id === g.id) &&
      g.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="flex flex-col gap-5 pb-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tighter text-foreground">
            Game Space
          </h1>
          <p className="text-sm text-muted-foreground">
            {games.length} game{games.length !== 1 ? "s" : ""} configured
          </p>
        </div>
        <Gamepad2 className="w-6 h-6 text-game-accent" />
      </div>

      {/* Game List */}
      {games.length === 0 ? (
        <div className="card-surface flex flex-col items-center gap-3 py-10">
          <Gamepad2 className="w-12 h-12 text-muted-foreground" />
          <p className="text-sm text-muted-foreground">No games added yet</p>
          <p className="text-xs text-muted-foreground">
            Add games for one-tap turbo optimization
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {games.map((game) => (
            <motion.div
              key={game.id}
              layout
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              whileTap={{ scale: 0.98 }}
              transition={transition}
              className="card-surface flex items-center gap-4"
            >
              <div
                className="w-14 h-14 rounded-2xl flex items-center justify-center text-2xl flex-shrink-0"
                style={{ backgroundColor: game.color + "22" }}
              >
                {game.icon}
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-foreground truncate">{game.name}</p>
                <p className="text-xs text-muted-foreground font-mono">
                  RAM + Cache + CPU optimized
                </p>
              </div>
              <div className="flex items-center gap-2">
                <motion.button
                  whileTap={{ scale: 0.9 }}
                  onClick={() => turboLaunch(game)}
                  disabled={optimizingGame !== null}
                  className="w-10 h-10 rounded-[12px] flex items-center justify-center bg-game-accent disabled:opacity-50"
                >
                  <Zap className="w-5 h-5 text-accent-foreground" />
                </motion.button>
                <motion.button
                  whileTap={{ scale: 0.9 }}
                  onClick={() => removeGame(game.id)}
                  className="w-10 h-10 rounded-[12px] flex items-center justify-center bg-muted"
                >
                  <X className="w-4 h-4 text-muted-foreground" />
                </motion.button>
              </div>
            </motion.div>
          ))}
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
            className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-background/95 backdrop-blur-sm"
          >
            <motion.div
              initial={{ scale: 0.8 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.8 }}
              transition={{ duration: 0.3 }}
              className="flex flex-col items-center gap-6"
            >
              <div className="w-20 h-20 rounded-full border-4 border-game-accent flex items-center justify-center">
                <Zap className="w-10 h-10 text-game-accent animate-pulse" />
              </div>
              <div className="text-center">
                <p className="text-lg font-semibold text-foreground">
                  Allocating Resources...
                </p>
                <p className="text-sm font-mono text-muted-foreground mt-2">
                  Clearing RAM · Killing background · Boosting CPU
                </p>
              </div>
              <div className="w-48 progress-track h-1.5">
                <motion.div
                  initial={{ width: "0%" }}
                  animate={{ width: "100%" }}
                  transition={{ duration: 2.2, ease: "easeInOut" }}
                  className="progress-fill-accent"
                />
              </div>
              <p className="text-xs font-mono text-game-accent">
                System latency reduced by {Math.round(Math.random() * 15 + 5)}ms
              </p>
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
            onClick={() => setShowAddModal(false)}
          >
            <motion.div
              initial={{ y: "100%" }}
              animate={{ y: 0 }}
              exit={{ y: "100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 300 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-lg bg-card rounded-t-[24px] p-6 max-h-[70vh] flex flex-col gap-4"
            >
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-foreground">Add Game</h2>
                <button onClick={() => setShowAddModal(false)}>
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
                  className="w-full bg-muted rounded-[12px] pl-10 pr-4 py-3 text-sm text-foreground placeholder:text-muted-foreground outline-none focus:ring-2 focus:ring-game-accent"
                />
              </div>

              <div className="flex-1 overflow-y-auto flex flex-col gap-2">
                {availableGames.map((game) => (
                  <motion.button
                    key={game.id}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => addGame(game)}
                    className="flex items-center gap-3 p-3 rounded-[12px] hover:bg-muted transition-colors text-left w-full"
                  >
                    <div
                      className="w-12 h-12 rounded-2xl flex items-center justify-center text-xl flex-shrink-0"
                      style={{ backgroundColor: game.color + "22" }}
                    >
                      {game.icon}
                    </div>
                    <span className="font-medium text-foreground">{game.name}</span>
                  </motion.button>
                ))}
                {availableGames.length === 0 && (
                  <p className="text-center text-sm text-muted-foreground py-4">
                    No more games to add
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
