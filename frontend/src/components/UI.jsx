import COLORS from "../data/colors";

// ── Badge ──────────────────────────────────────────────────────────────────────
export function Badge({ variant, children, small }) {
  const map = {
    low:         { bg: COLORS.emeraldLight, color: COLORS.emeraldDark },
    medium:      { bg: COLORS.amberLight,   color: COLORS.amberDark   },
    high:        { bg: "#FEF3C7",           color: "#92400E"           },
    critical:    { bg: COLORS.roseLight,    color: COLORS.roseDark     },
    success:     { bg: COLORS.emeraldLight, color: COLORS.emeraldDark  },
    warning:     { bg: COLORS.amberLight,   color: COLORS.amberDark    },
    danger:      { bg: COLORS.roseLight,    color: COLORS.roseDark     },
    info:        { bg: COLORS.skyLight,     color: COLORS.skyDark      },
    pending:     { bg: COLORS.amberLight,   color: COLORS.amberDark    },
    completed:   { bg: COLORS.emeraldLight, color: COLORS.emeraldDark  },
    in_progress: { bg: COLORS.skyLight,     color: COLORS.skyDark      },
    easy:        { bg: COLORS.emeraldLight, color: COLORS.emeraldDark  },
    hard:        { bg: COLORS.roseLight,    color: COLORS.roseDark     },
    default:     { bg: COLORS.slate100,     color: COLORS.slate        },
  };
  const s = map[variant] || map.default;
  return (
    <span style={{
      background: s.bg, color: s.color,
      padding: small ? "2px 8px" : "3px 10px",
      borderRadius: 20, fontSize: small ? 11 : 12,
      fontWeight: 600, letterSpacing: "0.02em", whiteSpace: "nowrap",
    }}>
      {children}
    </span>
  );
}

// ── MiniBar ────────────────────────────────────────────────────────────────────
export function MiniBar({ value, max = 100, color = COLORS.indigo, height = 7 }) {
  const fill = value < 50 ? COLORS.rose : value < 70 ? COLORS.amber : color;
  return (
    <div style={{ background: COLORS.slate200, borderRadius: 99, height, overflow: "hidden", width: "100%" }}>
      <div style={{ width: `${(value / max) * 100}%`, height: "100%", background: `linear-gradient(90deg, ${fill}, ${fill}CC)`, borderRadius: 99, transition: "width 0.7s ease" }} />
    </div>
  );
}

// ── StatCard ───────────────────────────────────────────────────────────────────
export function StatCard({ label, value, sub, color, trend }) {
  return (
    <div style={{
      background: COLORS.white,
      borderRadius: 18, padding: "22px 24px 20px",
      boxShadow: "0 1px 2px rgba(15,23,42,0.04), 0 6px 20px rgba(15,23,42,0.05)",
      border: "1px solid rgba(15,23,42,0.06)",
      position: "relative", overflow: "hidden",
    }}>
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 3, background: color, borderRadius: "18px 18px 0 0" }} />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 18 }}>
        <div style={{ width: 34, height: 34, borderRadius: 10, background: color + "18", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ width: 13, height: 13, borderRadius: 4, background: color }} />
        </div>
        {trend !== undefined && (
          <span style={{
            fontSize: 11, fontWeight: 600, letterSpacing: "0.01em",
            color: trend > 0 ? COLORS.emerald : COLORS.rose,
            background: trend > 0 ? COLORS.emeraldLight : COLORS.roseLight,
            padding: "3px 8px", borderRadius: 99,
          }}>{trend > 0 ? "+" : ""}{trend}%</span>
        )}
      </div>
      <div style={{ fontSize: 32, fontWeight: 700, color: COLORS.text, letterSpacing: "-0.03em", lineHeight: 1 }}>{value}</div>
      <div style={{ fontSize: 10, fontWeight: 700, color: COLORS.textMuted, marginTop: 8, letterSpacing: "0.09em", textTransform: "uppercase" }}>{label}</div>
      {sub && <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 4 }}>{sub}</div>}
    </div>
  );
}

// ── BarChart ───────────────────────────────────────────────────────────────────
export function BarChart({ data, xKey, yKey, color, height = 180 }) {
  const max = Math.max(...data.map((d) => d[yKey]));
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height, paddingTop: 8 }}>
      {data.map((d, i) => {
        const pct = (d[yKey] / max) * 100;
        return (
          <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 5 }}>
            <div style={{ fontSize: 10, color: COLORS.textMuted, fontWeight: 600, letterSpacing: "0.01em" }}>{d[yKey]}</div>
            <div style={{ width: "100%", height: `${pct}%`, minHeight: 4, background: `linear-gradient(180deg, ${color} 0%, ${color}88 100%)`, borderRadius: "5px 5px 0 0" }} />
            <div style={{ fontSize: 9, color: COLORS.textMuted, letterSpacing: "0.03em" }}>{d[xKey]}</div>
          </div>
        );
      })}
    </div>
  );
}

// ── RiskGauge ──────────────────────────────────────────────────────────────────
export function RiskGauge({ dist }) {
  const total = Object.values(dist).reduce((a, b) => a + b, 0);
  const segments = [
    { key: "critical", color: COLORS.rose,    label: "Critical" },
    { key: "high",     color: COLORS.amber,   label: "High"     },
    { key: "medium",   color: "#FBBF24",      label: "Medium"   },
    { key: "low",      color: COLORS.emerald, label: "Low"      },
  ];
  return (
    <div>
      <div style={{ display: "flex", gap: 3, height: 10, borderRadius: 99, overflow: "hidden", marginBottom: 14 }}>
        {segments.map((s) => (
          <div key={s.key} style={{ width: `${(dist[s.key] / total) * 100}%`, background: s.color, borderRadius: 99 }} />
        ))}
      </div>
      <div style={{ display: "flex", gap: 16, flexWrap: "wrap" }}>
        {segments.map((s) => (
          <div key={s.key} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13 }}>
            <div style={{ width: 10, height: 10, borderRadius: 3, background: s.color }} />
            <span style={{ color: COLORS.textMuted }}>{s.label}</span>
            <span style={{ fontWeight: 700, color: COLORS.text }}>{dist[s.key]}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}
