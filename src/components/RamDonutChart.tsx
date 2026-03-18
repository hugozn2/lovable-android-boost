import { useEffect, useRef } from "react";

interface DonutChartProps {
  value: number;
  max: number;
  label: string;
  unit: string;
  size?: number;
  strokeWidth?: number;
  color?: string;
  dangerThreshold?: number;
}

const RamDonutChart = ({
  value,
  max,
  label,
  unit,
  size = 180,
  strokeWidth = 12,
  color = "hsl(195, 100%, 50%)",
  dangerThreshold = 85,
}: DonutChartProps) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const percentage = max > 0 ? (value / max) * 100 : 0;
  const isDanger = percentage > dangerThreshold;

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    canvas.width = size * dpr;
    canvas.height = size * dpr;
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, size, size);

    const cx = size / 2;
    const cy = size / 2;
    const radius = (size - strokeWidth * 2) / 2;

    // Track (background ring)
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.strokeStyle = "hsl(220, 18%, 16%)";
    ctx.lineWidth = strokeWidth;
    ctx.lineCap = "round";
    ctx.stroke();

    // Fill arc
    if (percentage > 0) {
      const startAngle = -Math.PI / 2;
      const endAngle = startAngle + (Math.PI * 2 * Math.min(percentage, 100)) / 100;

      ctx.beginPath();
      ctx.arc(cx, cy, radius, startAngle, endAngle);
      ctx.strokeStyle = isDanger ? "hsl(0, 72%, 55%)" : color;
      ctx.lineWidth = strokeWidth;
      ctx.lineCap = "round";

      // Glow effect
      ctx.shadowColor = isDanger ? "hsl(0, 72%, 55%)" : color;
      ctx.shadowBlur = 12;
      ctx.stroke();
      ctx.shadowBlur = 0;
    }
  }, [value, max, size, strokeWidth, color, percentage, isDanger]);

  return (
    <div className="relative flex items-center justify-center">
      <canvas ref={canvasRef} style={{ width: size, height: size }} />
      <div className="absolute flex flex-col items-center">
        <span className={`text-3xl font-mono font-bold ${isDanger ? "text-destructive" : "text-primary"}`}>
          {typeof value === "number" ? (value % 1 === 0 ? value : value.toFixed(1)) : value}
        </span>
        <span className="stat-unit">{unit}</span>
        <span className="text-[10px] text-muted-foreground mt-1 uppercase tracking-widest">{label}</span>
      </div>
    </div>
  );
};

export default RamDonutChart;
