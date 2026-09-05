import { TrendingUp, TrendingDown } from "lucide-react";

export default function KpiCard({ title, value, growth, isPositive = true, icon: Icon, color = "indigo", subtext }) {
  const colorMap = {
    indigo: { bg: "rgba(99, 102, 241, 0.12)", border: "rgba(99, 102, 241, 0.3)", text: "#818cf8" },
    cyan: { bg: "rgba(6, 182, 212, 0.12)", border: "rgba(6, 182, 212, 0.3)", text: "#38bdf8" },
    emerald: { bg: "rgba(16, 185, 129, 0.12)", border: "rgba(16, 185, 129, 0.3)", text: "#34d399" },
    amber: { bg: "rgba(245, 158, 11, 0.12)", border: "rgba(245, 158, 11, 0.3)", text: "#fbbf24" },
    rose: { bg: "rgba(244, 63, 94, 0.12)", border: "rgba(244, 63, 94, 0.3)", text: "#f87171" },
  };

  const currentTheme = colorMap[color] || colorMap.indigo;

  return (
    <div className="glass-card" style={{ display: "flex", flexDirection: "column", gap: "12px", position: "relative", overflow: "hidden" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div
          style={{
            width: "42px",
            height: "42px",
            borderRadius: "12px",
            background: currentTheme.bg,
            border: `1px solid ${currentTheme.border}`,
            color: currentTheme.text,
            display: "flex",
            alignItems: "center",
            justifyContent: "center"
          }}
        >
          {Icon && <Icon size={22} />}
        </div>
        {growth && (
          <span
            className={`badge ${isPositive ? "badge-emerald" : "badge-rose"}`}
          >
            {isPositive ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
            {growth}
          </span>
        )}
      </div>

      <div>
        <div style={{ fontSize: "1.8rem", fontWeight: "800", color: "#f9fafb", fontFamily: "var(--font-heading)", letterSpacing: "-0.02em" }}>
          {value}
        </div>
        <div style={{ fontSize: "0.85rem", fontWeight: "600", color: "var(--text-muted)", marginTop: "2px" }}>
          {title}
        </div>
        {subtext && (
          <div style={{ fontSize: "0.75rem", color: "var(--text-dim)", marginTop: "6px" }}>
            {subtext}
          </div>
        )}
      </div>
    </div>
  );
}
