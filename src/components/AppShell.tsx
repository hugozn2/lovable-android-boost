import { useState } from "react";
import { motion } from "framer-motion";
import { Activity, Gamepad2 } from "lucide-react";
import Dashboard from "../pages/Dashboard";
import GameSpace from "../pages/GameSpace";

const tabs = [
  { id: "dashboard", label: "System", icon: Activity },
  { id: "games", label: "Games", icon: Gamepad2 },
] as const;

type TabId = (typeof tabs)[number]["id"];

const AppShell = () => {
  const [activeTab, setActiveTab] = useState<TabId>("dashboard");

  return (
    <div className="min-h-screen bg-background flex flex-col max-w-lg mx-auto">
      {/* Content */}
      <main className="flex-1 px-4 pt-6 overflow-y-auto">
        {activeTab === "dashboard" && <Dashboard />}
        {activeTab === "games" && <GameSpace />}
      </main>

      {/* Bottom Navigation */}
      <nav className="sticky bottom-0 bg-card/80 backdrop-blur-xl border-t border-border px-6 pb-safe">
        <div className="flex justify-around">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            const isGame = tab.id === "games";
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`nav-tab relative ${
                  isActive
                    ? isGame
                      ? "nav-tab-game-active"
                      : "nav-tab-active"
                    : ""
                }`}
              >
                <Icon className="w-5 h-5" />
                <span className="text-xs font-medium">{tab.label}</span>
                {isActive && (
                  <motion.div
                    layoutId="tab-indicator"
                    className={`absolute -top-px left-2 right-2 h-0.5 rounded-full ${
                      isGame ? "bg-game-accent" : "bg-primary"
                    }`}
                  />
                )}
              </button>
            );
          })}
        </div>
      </nav>
    </div>
  );
};

export default AppShell;
