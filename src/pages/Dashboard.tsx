import { useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import RamDonutChart from "../components/RamDonutChart";
import StatCard from "../components/StatCard";
import { useBattery, useDeviceInfo, useNetwork, usePerformanceMemory, useStorageEstimate } from "../hooks/useDeviceData";
import { Battery, Wifi, Cpu, HardDrive, Snowflake, Trash2, Zap, Globe, MemoryStick, MonitorSmartphone } from "lucide-react";

const transition = { duration: 0.2, ease: [0.25, 0.1, 0.25, 1] as const };

const Dashboard = () => {
  const battery = useBattery();
  const device = useDeviceInfo();
  const network = useNetwork();
  const memory = usePerformanceMemory();
  const storage = useStorageEstimate();

  const [isOptimizing, setIsOptimizing] = useState(false);
  const [optimizeResult, setOptimizeResult] = useState<string | null>(null);

  const handleOptimize = useCallback(() => {
    if (isOptimizing) return;
    setIsOptimizing(true);
    setOptimizeResult(null);

    // Real: clear browser caches, run GC hint
    const startTime = performance.now();

    // Clear performance entries
    performance.clearMarks();
    performance.clearMeasures();
    performance.clearResourceTimings();

    // Clear various browser storage caches
    const clearOps: Promise<unknown>[] = [];

    // Clear Cache API storage
    if ("caches" in window) {
      clearOps.push(
        caches.keys().then((names) =>
          Promise.all(names.map((name) => caches.delete(name)))
        )
      );
    }

    // Clear sessionStorage
    try {
      const sessionItems = sessionStorage.length;
      sessionStorage.clear();
      console.log(`[Frost] Cleared ${sessionItems} session storage items`);
    } catch (e) {
      console.log("[Frost] sessionStorage not available");
    }

    Promise.all(clearOps).then(() => {
      const elapsed = Math.round(performance.now() - startTime);

      // Re-estimate storage after cleanup
      if (navigator.storage?.estimate) {
        navigator.storage.estimate().then((est) => {
          const usedMB = Math.round((est.usage || 0) / (1024 * 1024));
          setOptimizeResult(
            `Cache cleared · Performance entries purged · ${elapsed}ms elapsed · ${usedMB}MB storage in use`
          );
        });
      } else {
        setOptimizeResult(`Cache cleared · Performance entries purged · ${elapsed}ms`);
      }

      setIsOptimizing(false);
      setTimeout(() => setOptimizeResult(null), 5000);
    });
  }, [isOptimizing]);

  const batteryStatus = battery.level > 50 ? "success" : battery.level > 20 ? "warning" : "danger";
  const networkStatus = network.rtt > 200 ? "danger" : network.rtt > 100 ? "warning" : "normal";

  return (
    <div className="flex flex-col gap-4 pb-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-[12px] bg-primary/10 flex items-center justify-center">
            <Snowflake className="w-5 h-5 text-primary" />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-gradient-frost">
              Frost Optimizer
            </h1>
            <p className="text-[11px] text-muted-foreground font-mono">
              {device.platform} · {device.online ? "Online" : "Offline"}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2 card-surface !p-2 !rounded-[12px]">
          <div className={`w-2 h-2 rounded-full ${device.online ? "bg-success" : "bg-destructive"} animate-pulse-frost`} />
          <span className="text-[10px] font-mono text-muted-foreground">
            {device.cpuCores} cores
          </span>
        </div>
      </div>

      {/* Main Chart - Memory */}
      <div className="card-frost flex flex-col items-center gap-4 py-6 frost-glow">
        <span className="stat-label">
          {memory.supported ? "JS Heap Memory" : "Device Memory"}
        </span>
        <RamDonutChart
          value={memory.supported ? memory.usedMB : (device.deviceMemory || 0)}
          max={memory.supported ? memory.totalMB : (device.deviceMemory || 8)}
          label={memory.supported ? "heap usage" : "estimated ram"}
          unit={memory.supported ? `/ ${memory.totalMB}MB` : "GB"}
        />
        <div className="flex gap-8 text-center">
          <div>
            <span className="font-mono text-sm text-primary">
              {device.deviceMemory ? `${device.deviceMemory}GB` : "N/A"}
            </span>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wider">Device RAM</p>
          </div>
          <div>
            <span className="font-mono text-sm text-primary">{device.cpuCores}</span>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wider">CPU Cores</p>
          </div>
          <div>
            <span className="font-mono text-sm text-primary">
              {storage.supported ? `${storage.usedMB}MB` : "N/A"}
            </span>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wider">Storage Used</p>
          </div>
        </div>
      </div>

      {/* Optimize Button */}
      <motion.button
        whileTap={{ scale: 0.97 }}
        transition={transition}
        onClick={handleOptimize}
        disabled={isOptimizing}
        className="btn-primary-full flex items-center justify-center gap-2"
      >
        {isOptimizing ? (
          <>
            <Zap className="w-5 h-5 animate-pulse-frost" />
            Optimizing...
          </>
        ) : (
          <>
            <Trash2 className="w-5 h-5" />
            Optimize System
          </>
        )}
      </motion.button>

      {/* Result Feedback */}
      <AnimatePresence>
        {optimizeResult && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="card-surface !border-primary/20 text-center"
          >
            <p className="text-xs font-mono text-primary leading-relaxed">{optimizeResult}</p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-3">
        <StatCard
          label="Battery"
          value={battery.supported ? battery.level : "N/A"}
          unit={battery.supported ? (battery.charging ? "% ⚡" : "%") : ""}
          percentage={battery.supported ? battery.level : undefined}
          icon={Battery}
          status={battery.supported ? batteryStatus : "normal"}
        />
        <StatCard
          label="Network"
          value={network.supported ? network.rtt : "N/A"}
          unit={network.supported ? "ms RTT" : ""}
          percentage={network.supported ? Math.min(100, (network.rtt / 300) * 100) : undefined}
          icon={Wifi}
          status={network.supported ? networkStatus : "normal"}
        />
        <StatCard
          label="Downlink"
          value={network.supported ? network.downlink : "N/A"}
          unit={network.supported ? "Mbps" : ""}
          percentage={network.supported ? Math.min(100, (network.downlink / 10) * 100) : undefined}
          icon={Globe}
          status="normal"
        />
        <StatCard
          label="Net Type"
          value={network.supported ? network.effectiveType : "N/A"}
          unit=""
          icon={MonitorSmartphone}
          status="normal"
        />
      </div>

      {/* Device Info Card */}
      <div className="card-surface">
        <span className="stat-label">Device Information</span>
        <div className="mt-3 space-y-2">
          <div className="flex justify-between items-center">
            <span className="text-xs text-muted-foreground flex items-center gap-2">
              <Cpu className="w-3 h-3" /> Platform
            </span>
            <span className="text-xs font-mono text-foreground">{device.platform}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-xs text-muted-foreground flex items-center gap-2">
              <MemoryStick className="w-3 h-3" /> CPU Cores
            </span>
            <span className="text-xs font-mono text-foreground">{device.cpuCores}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-xs text-muted-foreground flex items-center gap-2">
              <HardDrive className="w-3 h-3" /> Storage Quota
            </span>
            <span className="text-xs font-mono text-foreground">
              {storage.supported ? `${storage.totalMB}MB` : "N/A"}
            </span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-xs text-muted-foreground flex items-center gap-2">
              <Globe className="w-3 h-3" /> Language
            </span>
            <span className="text-xs font-mono text-foreground">{device.language}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
