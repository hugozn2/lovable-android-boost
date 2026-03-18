import { motion } from "framer-motion";
import { type LucideIcon } from "lucide-react";

interface StatCardProps {
  label: string;
  value: string | number;
  unit: string;
  percentage?: number;
  icon?: LucideIcon;
  status?: "normal" | "warning" | "danger" | "success";
}

const transition = { duration: 0.2, ease: [0.25, 0.1, 0.25, 1] as const };

const statusColors = {
  normal: "",
  warning: "text-warning",
  danger: "text-destructive",
  success: "text-success",
};

const progressClass = {
  normal: "progress-fill",
  warning: "progress-fill",
  danger: "progress-fill-danger",
  success: "progress-fill-success",
};

const StatCard = ({ label, value, unit, percentage, icon: Icon, status = "normal" }: StatCardProps) => {
  return (
    <motion.div
      whileTap={{ scale: 0.98 }}
      transition={transition}
      className="card-surface flex flex-col gap-2.5"
    >
      <div className="flex items-center justify-between">
        <span className="stat-label">{label}</span>
        {Icon && <Icon className="w-3.5 h-3.5 text-muted-foreground" />}
      </div>
      <div className="flex items-baseline gap-1">
        <span className={`stat-value ${statusColors[status]}`}>
          {value}
        </span>
        <span className="stat-unit">{unit}</span>
      </div>
      {percentage !== undefined && (
        <div className="progress-track">
          <div
            className={progressClass[status]}
            style={{ width: `${Math.min(100, Math.max(0, percentage))}%` }}
          />
        </div>
      )}
    </motion.div>
  );
};

export default StatCard;
