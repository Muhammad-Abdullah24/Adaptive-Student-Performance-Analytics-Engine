import COLORS from "../data/colors";
import { TOPIC_DATA, WEEKLY_ATTEMPTS, RISK_DIST, SESSION_LOG } from "../data/mockData";
import { StatCard, RiskGauge, BarChart, MiniBar, Badge } from "../components/UI";

const CARD = {
  background: "#FFFFFF",
  borderRadius: 20,
  padding: 24,
  boxShadow: "0 1px 2px rgba(15,23,42,0.04), 0 6px 24px rgba(15,23,42,0.06)",
  border: "1px solid rgba(15,23,42,0.07)",
};

const LABEL_STYLE = {
  fontSize: 10, fontWeight: 700, letterSpacing: "0.09em",
  textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 14,
};

const RISK_META = [
  { key: "critical", label: "Critical", color: COLORS.rose    },
  { key: "high",     label: "High",     color: COLORS.amber   },
  { key: "medium",   label: "Medium",   color: "#FBBF24"      },
  { key: "low",      label: "Low",      color: COLORS.emerald },
];

export default function OverviewPage() {
  const logBorderColor = (type) => ({
    success: COLORS.emerald,
    danger:  COLORS.rose,
    warning: COLORS.amber,
    info:    COLORS.sky,
  }[type] || COLORS.sky);

  const total = Object.values(RISK_DIST).reduce((a, b) => a + b, 0);

  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: "repeat(4, 1fr)",
      gap: 14,
    }}>

      {/* ── TILE 1 — Risk Distribution (2 cols × 2 rows) ── */}
      <div style={{ ...CARD, gridColumn: "span 2", gridRow: "span 2", display: "flex", flexDirection: "column" }}>
        <div style={LABEL_STYLE}>Risk Distribution</div>

        {/* Mini risk count tiles */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 20 }}>
          {RISK_META.map((r) => (
            <div key={r.key} style={{
              borderRadius: 14, padding: "13px 16px",
              background: r.color + "0D",
              borderLeft: `3px solid ${r.color}`,
            }}>
              <div style={{ fontSize: 28, fontWeight: 700, color: r.color, letterSpacing: "-0.03em", lineHeight: 1 }}>
                {Math.round((RISK_DIST[r.key] / total) * 847)}
              </div>
              <div style={{ fontSize: 9, fontWeight: 700, color: r.color, opacity: 0.75, letterSpacing: "0.08em", textTransform: "uppercase", marginTop: 4 }}>{r.label}</div>
            </div>
          ))}
        </div>

        {/* Gauge bar */}
        <RiskGauge dist={RISK_DIST} />

        {/* Alert */}
        <div style={{ marginTop: "auto", paddingTop: 16 }}>
          <div style={{ padding: "10px 13px", background: "#FFF1F2", borderRadius: 10, fontSize: 12, color: COLORS.roseDark, borderLeft: `3px solid ${COLORS.rose}`, lineHeight: 1.6 }}>
            <span style={{ fontWeight: 700 }}>Trigger alert — </span>8 students flagged Critical this week via PL/SQL trigger.
          </div>
        </div>
      </div>

      {/* ── TILES 2–5 — Stat Cards (1×1 each, auto-fill cols 3–4, rows 1–2) ── */}
      <StatCard label="Total Students"   value="847"  sub="Across 5 departments" color={COLORS.indigo}  trend={3.2}  />
      <StatCard label="At-Risk Students" value="94"   sub="Require intervention"  color={COLORS.rose}   trend={-8.1} />
      <StatCard label="Avg. CGPA"        value="2.89" sub="University-wide"       color={COLORS.emerald} trend={1.4}  />
      <StatCard label="Active Sessions"  value="312"  sub="Last 7 days"           color={COLORS.violet} trend={12.7} />

      {/* ── TILE 6 — Weekly Attempts (2 wide) ── */}
      <div style={{ ...CARD, gridColumn: "span 2" }}>
        <div style={LABEL_STYLE}>Weekly Assessment Attempts</div>
        <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: -8, marginBottom: 14 }}>Total submissions per week</div>
        <BarChart data={WEEKLY_ATTEMPTS} xKey="week" yKey="attempts" color={COLORS.indigo} height={150} />
      </div>

      {/* ── TILE 7 — Topic Mastery (2 wide) ── */}
      <div style={{ ...CARD, gridColumn: "span 2" }}>
        <div style={LABEL_STYLE}>Topic Mastery</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 11 }}>
          {TOPIC_DATA.map((t) => (
            <div key={t.topic}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13, marginBottom: 5 }}>
                <span style={{ color: COLORS.text, fontWeight: 500 }}>{t.topic}</span>
                <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                  <Badge variant={t.difficulty} small>{t.difficulty}</Badge>
                  <span style={{ color: COLORS.textMuted, fontWeight: 700 }}>{t.mastery}%</span>
                </div>
              </div>
              <MiniBar value={t.mastery} />
            </div>
          ))}
        </div>
      </div>

      {/* ── TILE 8 — Live Activity Log (full width, 3-column) ── */}
      <div style={{ ...CARD, gridColumn: "span 4" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
          <div style={{ ...LABEL_STYLE, marginBottom: 0 }}>Live Activity Log</div>
          <span style={{ fontSize: 10, color: COLORS.textMuted, letterSpacing: "0.04em" }}>Trigger-driven events</span>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 9 }}>
          {SESSION_LOG.map((log, i) => (
            <div key={i} style={{
              display: "flex", gap: 11, padding: "10px 13px",
              background: "#F8F9FF", borderRadius: 10,
              borderLeft: `3px solid ${logBorderColor(log.type)}`,
            }}>
              <div style={{ fontSize: 10, color: COLORS.textMuted, fontWeight: 600, minWidth: 36, paddingTop: 1, flexShrink: 0 }}>{log.time}</div>
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: COLORS.text }}>{log.student}</div>
                <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 1 }}>{log.event}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}
