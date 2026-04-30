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
export function MiniBar({ value, max = 100, color = COLORS.indigo, height = 6 }) {
  const fill = value < 50 ? COLORS.rose : value < 70 ? COLORS.amber : color;
  return (
    <div style={{ background: COLORS.slate200, borderRadius: 99, height, overflow: "hidden", width: "100%" }}>
      <div style={{ width: `${(value / max) * 100}%`, height: "100%", background: fill, borderRadius: 99, transition: "width 0.6s ease" }} />
    </div>
  );
}

// ── StatCard ───────────────────────────────────────────────────────────────────
export function StatCard({ label, value, sub, icon, color, trend }) {
  return (
    <div style={{
      background: COLORS.white, border: `1px solid ${COLORS.slate200}`,
      borderRadius: 16, padding: "20px 24px", borderLeft: `4px solid ${color}`,
    }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <div>
          <div style={{ fontSize: 13, color: COLORS.textMuted, fontWeight: 500, marginBottom: 6, letterSpacing: "0.03em" }}>{label}</div>
          <div style={{ fontSize: 30, fontWeight: 700, color: COLORS.text, lineHeight: 1 }}>{value}</div>
          {sub && <div style={{ fontSize: 12, color: COLORS.textMuted, marginTop: 6 }}>{sub}</div>}
        </div>
        <div style={{
          width: 44, height: 44, borderRadius: 12,
          background: color + "20", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20,
        }}>{icon}</div>
      </div>
      {trend && (
        <div style={{ marginTop: 12, fontSize: 12, color: trend > 0 ? COLORS.emerald : COLORS.rose, fontWeight: 600 }}>
          {trend > 0 ? "▲" : "▼"} {Math.abs(trend)}% vs last week
        </div>
      )}
    </div>
  );
}

// ── BarChart ───────────────────────────────────────────────────────────────────
export function BarChart({ data, xKey, yKey, color, height = 180 }) {
  const max = Math.max(...data.map((d) => d[yKey]));
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 8, height, paddingTop: 8 }}>
      {data.map((d, i) => {
        const pct = (d[yKey] / max) * 100;
        return (
          <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
            <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600 }}>{d[yKey]}</div>
            <div style={{ width: "100%", height: `${pct}%`, minHeight: 4, background: color, borderRadius: "6px 6px 0 0" }} />
            <div style={{ fontSize: 10, color: COLORS.textMuted }}>{d[xKey]}</div>
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
      <div style={{ display: "flex", gap: 4, height: 24, borderRadius: 12, overflow: "hidden", marginBottom: 12 }}>
        {segments.map((s) => (
          <div key={s.key} style={{ width: `${(dist[s.key] / total) * 100}%`, background: s.color }} />
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
