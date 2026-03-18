import { motion } from "framer-motion";

interface StatCardProps {
  label: string;
  value: string | number;
  unit: string;
  percentage?: number;
  danger?: boolean;
}

const transition = { duration: 0.2, ease: [0.25, 0.1, 0.25, 1] };

const StatCard = ({ label, value, unit, percentage, danger }: StatCardProps) => {
  return (
    <motion.div
      whileTap={{ scale: 0.98 }}
      transition={transition}
      className="card-surface flex flex-col gap-2"
    >
      <span className="stat-label">{label}</span>
      <div className="flex items-baseline gap-1">
        <span className={`stat-value ${danger ? "text-destructive" : ""}`}>
          {value}
        </span>
        <span className="stat-unit">{unit}</span>
      </div>
      {percentage !== undefined && (
        <div className="progress-track">
          <div
            className={danger ? "progress-fill bg-destructive" : "progress-fill"}
            style={{ width: `${percentage}%` }}
          />
        </div>
      )}
    </motion.div>
  );
};

export default StatCard;
