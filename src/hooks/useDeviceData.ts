import { useState, useEffect, useCallback } from "react";

export interface BatteryInfo {
  level: number; // 0-100
  charging: boolean;
  chargingTime: number;
  dischargingTime: number;
  supported: boolean;
}

export interface DeviceInfo {
  deviceMemory: number | null; // GB (approximate)
  cpuCores: number;
  platform: string;
  userAgent: string;
  language: string;
  online: boolean;
}

export interface NetworkInfo {
  type: string;
  downlink: number; // Mbps
  rtt: number; // ms
  effectiveType: string;
  supported: boolean;
}

export interface StorageInfo {
  usedMB: number;
  totalMB: number;
  supported: boolean;
}

// Extend Navigator for non-standard APIs
interface NavigatorExtended extends Navigator {
  deviceMemory?: number;
  connection?: {
    type?: string;
    downlink?: number;
    rtt?: number;
    effectiveType?: string;
    addEventListener: (event: string, cb: () => void) => void;
    removeEventListener: (event: string, cb: () => void) => void;
  };
  getBattery?: () => Promise<{
    level: number;
    charging: boolean;
    chargingTime: number;
    dischargingTime: number;
    addEventListener: (event: string, cb: () => void) => void;
    removeEventListener: (event: string, cb: () => void) => void;
  }>;
}

export function useDeviceInfo(): DeviceInfo {
  const nav = navigator as NavigatorExtended;
  return {
    deviceMemory: nav.deviceMemory ?? null,
    cpuCores: nav.hardwareConcurrency || 1,
    platform: nav.platform || "Unknown",
    userAgent: nav.userAgent,
    language: nav.language,
    online: nav.onLine,
  };
}

export function useBattery(): BatteryInfo {
  const [battery, setBattery] = useState<BatteryInfo>({
    level: 0,
    charging: false,
    chargingTime: 0,
    dischargingTime: 0,
    supported: false,
  });

  useEffect(() => {
    const nav = navigator as NavigatorExtended;
    if (!nav.getBattery) return;

    let batteryObj: Awaited<ReturnType<NonNullable<NavigatorExtended["getBattery"]>>> | null = null;

    const update = () => {
      if (!batteryObj) return;
      setBattery({
        level: Math.round(batteryObj.level * 100),
        charging: batteryObj.charging,
        chargingTime: batteryObj.chargingTime,
        dischargingTime: batteryObj.dischargingTime,
        supported: true,
      });
    };

    nav.getBattery().then((b) => {
      batteryObj = b;
      update();
      b.addEventListener("levelchange", update);
      b.addEventListener("chargingchange", update);
    }).catch(() => {});

    return () => {
      if (batteryObj) {
        batteryObj.removeEventListener("levelchange", update);
        batteryObj.removeEventListener("chargingchange", update);
      }
    };
  }, []);

  return battery;
}

export function useNetwork(): NetworkInfo {
  const nav = navigator as NavigatorExtended;
  const conn = nav.connection;

  const getInfo = useCallback((): NetworkInfo => {
    if (!conn) return { type: "unknown", downlink: 0, rtt: 0, effectiveType: "unknown", supported: false };
    return {
      type: conn.type || "unknown",
      downlink: conn.downlink || 0,
      rtt: conn.rtt || 0,
      effectiveType: conn.effectiveType || "unknown",
      supported: true,
    };
  }, [conn]);

  const [info, setInfo] = useState<NetworkInfo>(getInfo);

  useEffect(() => {
    if (!conn) return;
    const update = () => setInfo(getInfo());
    conn.addEventListener("change", update);
    return () => conn.removeEventListener("change", update);
  }, [conn, getInfo]);

  return info;
}

export function useStorageEstimate(): StorageInfo {
  const [storage, setStorage] = useState<StorageInfo>({ usedMB: 0, totalMB: 0, supported: false });

  useEffect(() => {
    if (!navigator.storage?.estimate) return;
    navigator.storage.estimate().then((est) => {
      setStorage({
        usedMB: Math.round((est.usage || 0) / (1024 * 1024)),
        totalMB: Math.round((est.quota || 0) / (1024 * 1024)),
        supported: true,
      });
    }).catch(() => {});
  }, []);

  return storage;
}

export function usePerformanceMemory() {
  const [memory, setMemory] = useState<{ usedMB: number; totalMB: number; supported: boolean }>({
    usedMB: 0,
    totalMB: 0,
    supported: false,
  });

  useEffect(() => {
    const perf = performance as Performance & {
      memory?: { usedJSHeapSize: number; totalJSHeapSize: number; jsHeapSizeLimit: number };
    };

    if (!perf.memory) return;

    const update = () => {
      if (!perf.memory) return;
      setMemory({
        usedMB: Math.round(perf.memory.usedJSHeapSize / (1024 * 1024)),
        totalMB: Math.round(perf.memory.jsHeapSizeLimit / (1024 * 1024)),
        supported: true,
      });
    };

    update();
    const interval = setInterval(update, 3000);
    return () => clearInterval(interval);
  }, []);

  return memory;
}
