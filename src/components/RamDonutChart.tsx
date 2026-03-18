import { useEffect, useRef } from "react";

interface DonutChartProps {
  used: number;
  total: number;
  size?: number;
  strokeWidth?: number;
}

const RamDonutChart = ({ used, total, size = 200, strokeWidth = 14 }: DonutChartProps) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const percentage = (used / total) * 100;

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    canvas.width = size * dpr;
    canvas.height = size * dpr;
    ctx.scale(dpr, dpr);

    const cx = size / 2;
    const cy = size / 2;
    const radius = (size - strokeWidth) / 2;

    // Track
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.strokeStyle = "hsl(217, 33%, 22%)";
    ctx.lineWidth = strokeWidth;
    ctx.lineCap = "round";
    ctx.stroke();

    // Fill
    const startAngle = -Math.PI / 2;
    const endAngle = startAngle + (Math.PI * 2 * percentage) / 100;
    
    const gradient = ctx.createLinearGradient(0, 0, size, size);
    gradient.addColorStop(0, "hsl(187, 92%, 45%)");
    gradient.addColorStop(1, "hsl(187, 92%, 35%)");

    ctx.beginPath();
    ctx.arc(cx, cy, radius, startAngle, endAngle);
    ctx.strokeStyle = percentage > 85 ? "hsl(0, 84%, 60%)" : gradient;
    ctx.lineWidth = strokeWidth;
    ctx.lineCap = "round";
    ctx.stroke();
  }, [used, total, size, strokeWidth, percentage]);

  return (
    <div className="relative flex items-center justify-center">
      <canvas
        ref={canvasRef}
        style={{ width: size, height: size }}
      />
      <div className="absolute flex flex-col items-center">
        <span className="stat-value text-3xl">{used.toFixed(1)}</span>
        <span className="stat-unit">/ {total}GB</span>
      </div>
    </div>
  );
};

export default RamDonutChart;
