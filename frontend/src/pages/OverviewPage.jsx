import COLORS from "../data/colors";
import { TOPIC_DATA, WEEKLY_ATTEMPTS, RISK_DIST, SESSION_LOG } from "../data/mockData";
import { StatCard, RiskGauge, BarChart, MiniBar, Badge } from "../components/UI";

export default function OverviewPage() {
  const logBorderColor = (type) => ({
    success: COLORS.emerald,
    danger:  COLORS.rose,
    warning: COLORS.amber,
    info:    COLORS.sky,
  }[type] || COLORS.sky);

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: COLORS.text, margin: 0 }}>System Overview</h2>
        <p style={{ color: COLORS.textMuted, fontSize: 14, margin: "6px 0 0" }}>
          Spring 2026 — Live analytics across all departments
        </p>
      </div>

      {/* Stat Cards */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16, marginBottom: 24 }}>
        <StatCard label="TOTAL STUDENTS"   value="847"  sub="Across 5 departments" icon="🎓" color={COLORS.indigo}  trend={3.2}  />
        <StatCard label="AT-RISK STUDENTS" value="94"   sub="Require intervention"  icon="⚠️" color={COLORS.rose}   trend={-8.1} />
        <StatCard label="AVG. CGPA"        value="2.89" sub="University-wide"       icon="📊" color={COLORS.emerald} trend={1.4}  />
        <StatCard label="ACTIVE SESSIONS"  value="312"  sub="Last 7 days"           icon="⚡" color={COLORS.violet} trend={12.7} />
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20, marginBottom: 20 }}>
        {/* Risk Distribution */}
        <div style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 16, padding: 24 }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 16, color: COLORS.text }}>Risk Distribution</div>
          <RiskGauge dist={RISK_DIST} />
          <div style={{ marginTop: 20, padding: "12px 16px", background: COLORS.roseLight, borderRadius: 10, fontSize: 13, color: COLORS.roseDark }}>
            <strong>Trigger alert:</strong> 8 students flagged as Critical this week — PL/SQL trigger auto-enrolled them in intervention queue.
          </div>
        </div>

        {/* Weekly Attempts */}
        <div style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 16, padding: 24 }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4, color: COLORS.text }}>Weekly Assessment Attempts</div>
          <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 16 }}>Total submissions per week</div>
          <BarChart data={WEEKLY_ATTEMPTS} xKey="week" yKey="attempts" color={COLORS.indigo} height={160} />
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        {/* Topic Mastery */}
        <div style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 16, padding: 24 }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 16, color: COLORS.text }}>Topic Mastery Heatmap</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {TOPIC_DATA.map((t) => (
              <div key={t.topic}>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13, marginBottom: 4 }}>
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

        {/* Live Activity Log */}
        <div style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 16, padding: 24 }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4, color: COLORS.text }}>Live Activity Log</div>
          <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 16 }}>Trigger-driven real-time events</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10, maxHeight: 340, overflowY: "auto" }}>
            {SESSION_LOG.map((log, i) => (
              <div key={i} style={{
                display: "flex", gap: 12, padding: "10px 14px",
                background: COLORS.slateLight, borderRadius: 10,
                borderLeft: `3px solid ${logBorderColor(log.type)}`,
              }}>
                <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600, minWidth: 42, paddingTop: 1 }}>{log.time}</div>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: COLORS.text }}>{log.student}</div>
                  <div style={{ fontSize: 12, color: COLORS.textMuted }}>{log.event}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
