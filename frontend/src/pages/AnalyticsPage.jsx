import COLORS from "../data/colors";
import { STUDENTS, WEEKLY_ATTEMPTS } from "../data/mockData";
import { Badge, BarChart } from "../components/UI";

function CodeTag({ children }) {
  return (
    <code style={{ fontFamily: "monospace", background: COLORS.slateLight, padding: "1px 6px", borderRadius: 4, fontSize: 11 }}>
      {children}
    </code>
  );
}

function QueryLabel({ color, bg, children }) {
  return (
    <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 16, background: bg, color, padding: "6px 10px", borderRadius: 6 }}>
      {children}
    </div>
  );
}

export default function AnalyticsPage() {
  const belowAvg  = STUDENTS.filter((s) => s.cgpa < 2.5);
  const topFive   = [...STUDENTS].sort((a, b) => b.cgpa - a.cgpa).slice(0, 5);

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 5 }}>Queries</div>
        <h2 style={{ fontSize: 24, fontWeight: 700, color: COLORS.text, margin: 0, letterSpacing: "-0.02em" }}>Advanced Analytics</h2>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20, marginBottom: 20 }}>
        {/* Window Function — Ranking */}
        <div style={{ background: COLORS.white, borderRadius: 20, padding: 24, boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 6px 24px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4, color: COLORS.text }}>Top Students by CGPA</div>
          <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8 }}>
            via <CodeTag>RANK() OVER (PARTITION BY dept ORDER BY cgpa DESC)</CodeTag>
          </div>
          <QueryLabel color={COLORS.indigoDark} bg={COLORS.indigoLight}>Window Function Query</QueryLabel>
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {topFive.map((s, i) => (
              <div key={s.id} style={{ display: "flex", alignItems: "center", gap: 12, padding: "8px 12px", background: COLORS.slateLight, borderRadius: 8 }}>
                <div style={{
                  width: 26, height: 26, borderRadius: "50%",
                  background: i === 0 ? "#FFD700" : i === 1 ? "#C0C0C0" : i === 2 ? "#CD7F32" : COLORS.slate200,
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 12, fontWeight: 700, color: COLORS.text,
                }}>{i + 1}</div>
                <div style={{ flex: 1, fontSize: 13, fontWeight: 600, color: COLORS.text }}>{s.name}</div>
                <Badge variant="default" small>{s.dept}</Badge>
                <div style={{ fontWeight: 700, color: COLORS.emerald, fontSize: 14 }}>{s.cgpa.toFixed(2)}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Correlated Subquery */}
        <div style={{ background: COLORS.white, borderRadius: 20, padding: 24, boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 6px 24px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4, color: COLORS.text }}>Below-Average Performers</div>
          <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8 }}>
            via <CodeTag>WHERE cgpa &lt; (SELECT AVG FROM dept)</CodeTag>
          </div>
          <QueryLabel color={COLORS.roseDark} bg={COLORS.roseLight}>Correlated Subquery</QueryLabel>
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {belowAvg.map((s) => (
              <div key={s.id} style={{
                display: "flex", alignItems: "center", gap: 12,
                padding: "8px 12px", background: COLORS.roseLight,
                borderRadius: 8, border: `1px solid ${COLORS.rose}30`,
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 700, color: COLORS.text }}>{s.name}</div>
                  <div style={{ fontSize: 11, color: COLORS.textMuted }}>Dept avg: 2.80 — Gap: {(2.80 - s.cgpa).toFixed(2)}</div>
                </div>
                <div style={{ fontWeight: 700, color: COLORS.rose, fontSize: 15 }}>{s.cgpa.toFixed(2)}</div>
                <Badge variant={s.risk} small>{s.risk}</Badge>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* CTE + Rolling Average */}
      <div style={{ background: COLORS.white, borderRadius: 20, padding: 24, boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 6px 24px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
        <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4, color: COLORS.text }}>
          Weekly Average Score Trend (CTE + Rolling Window)
        </div>
        <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8 }}>
          <CodeTag>WITH ranked AS (...), rolling AS (...) SELECT ... FROM rolling WHERE rn &lt;= 8</CodeTag>
        </div>
        <QueryLabel color={COLORS.emeraldDark} bg={COLORS.emeraldLight}>CTE with Rolling Window</QueryLabel>
        <BarChart data={WEEKLY_ATTEMPTS} xKey="week" yKey="avg" color={COLORS.violet} height={180} />
        <div style={{ marginTop: 8, fontSize: 12, color: COLORS.textMuted, textAlign: "center" }}>
          Weekly average score (%) — 8-week trend
        </div>
      </div>
    </div>
  );
}
