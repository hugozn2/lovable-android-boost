import { useState, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import RamDonutChart from "../components/RamDonutChart";
import StatCard from "../components/StatCard";
import { Cpu, Battery, Wifi, Thermometer, Trash2, Zap } from "lucide-react";

const transition = { duration: 0.2, ease: [0.25, 0.1, 0.25, 1] };

const Dashboard = () => {
  const [ramUsed, setRamUsed] = useState(5.2);
  const [cacheSize, setCacheSize] = useState(1847);
  const [cpuTemp, setCpuTemp] = useState(42);
  const [batteryHealth, setBatteryHealth] = useState(94);
  const [cpuClock, setCpuClock] = useState(2.84);
  const [networkLatency, setNetworkLatency] = useState(23);
  const [isOptimizing, setIsOptimizing] = useState(false);
  const [optimizeResult, setOptimizeResult] = useState<string | null>(null);
  const [bgApps, setBgApps] = useState(14);

  // Simulate live telemetry
  useEffect(() => {
    const interval = setInterval(() => {
      setCpuTemp((prev) => Math.max(35, Math.min(55, prev + (Math.random() - 0.5) * 2)));
      setNetworkLatency((prev) => Math.max(8, Math.min(80, prev + Math.round((Math.random() - 0.5) * 6))));
      setCpuClock((prev) => +(Math.max(1.8, Math.min(3.2, prev + (Math.random() - 0.5) * 0.1))).toFixed(2));
    }, 2000);
    return () => clearInterval(interval);
  }, []);

  const handleOptimize = useCallback(() => {
    if (isOptimizing) return;
    setIsOptimizing(true);
    setOptimizeResult(null);

    const freedRam = +(Math.random() * 1.5 + 0.5).toFixed(1);
    const freedCache = Math.round(Math.random() * 800 + 400);
    const killedApps = Math.round(Math.random() * 8 + 3);

    // Animate countdown
    const steps = 15;
    let step = 0;
    const startRam = ramUsed;
    const startCache = cacheSize;
    const startApps = bgApps;
    const targetRam = Math.max(2.1, startRam - freedRam);
    const targetCache = Math.max(120, startCache - freedCache);
    const targetApps = Math.max(2, startApps - killedApps);

    const timer = setInterval(() => {
      step++;
      const progress = step / steps;
      setRamUsed(+(startRam - (startRam - targetRam) * progress).toFixed(1));
      setCacheSize(Math.round(startCache - (startCache - targetCache) * progress));
      setBgApps(Math.round(startApps - (startApps - targetApps) * progress));

      if (step >= steps) {
        clearInterval(timer);
        setIsOptimizing(false);
        setOptimizeResult(`${freedRam}GB RAM freed · ${freedCache}MB cache cleared · ${killedApps} apps killed`);
        setTimeout(() => setOptimizeResult(null), 4000);
      }
    }, 80);
  }, [isOptimizing, ramUsed, cacheSize, bgApps]);

  return (
    <div className="flex flex-col gap-5 pb-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tighter text-foreground">
            Aura
          </h1>
          <p className="text-sm text-muted-foreground">Hardware, refined.</p>
        </div>
        <div className="flex items-center gap-2 card-surface !p-2 !rounded-[12px]">
          <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
          <span className="text-xs font-mono text-muted-foreground">{bgApps} bg apps</span>
        </div>
      </div>

      {/* RAM Donut */}
      <div className="card-surface flex flex-col items-center gap-4 py-6">
        <span className="stat-label">RAM Pressure</span>
        <RamDonutChart used={ramUsed} total={8} />
        <div className="flex gap-6 text-center">
          <div>
            <span className="font-mono text-sm text-primary">{cacheSize}MB</span>
            <p className="text-xs text-muted-foreground">Cache</p>
          </div>
          <div>
            <span className="font-mono text-sm text-primary">{bgApps}</span>
            <p className="text-xs text-muted-foreground">Background</p>
          </div>
        </div>
      </div>

      {/* Optimize Button */}
      <motion.button
        whileTap={{ scale: 0.97 }}
        transition={transition}
        onClick={handleOptimize}
        disabled={isOptimizing}
        className="btn-primary-full flex items-center justify-center gap-2 disabled:opacity-70"
      >
        {isOptimizing ? (
          <>
            <Zap className="w-5 h-5 animate-pulse" />
            Purging Background...
          </>
        ) : (
          <>
            <Trash2 className="w-5 h-5" />
            Optimize System
          </>
        )}
      </motion.button>

      {/* Result feedback */}
      <AnimatePresence>
        {optimizeResult && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="card-surface !bg-primary/10 text-center"
          >
            <p className="text-sm font-mono text-primary">{optimizeResult}</p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-3">
        <StatCard
          label="CPU Temp"
          value={Math.round(cpuTemp)}
          unit="°C"
          percentage={cpuTemp * 1.5}
          danger={cpuTemp > 45}
        />
        <StatCard
          label="Battery"
          value={batteryHealth}
          unit="%"
          percentage={batteryHealth}
        />
        <StatCard
          label="CPU Clock"
          value={cpuClock}
          unit="GHz"
          percentage={(cpuClock / 3.2) * 100}
        />
        <StatCard
          label="Latency"
          value={networkLatency}
          unit="ms"
          percentage={Math.min(100, networkLatency * 1.25)}
          danger={networkLatency > 60}
        />
      </div>
    </div>
  );
};

export default Dashboard;
