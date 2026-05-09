import { useState, useEffect } from "react";
import COLORS from "../data/colors";
import { Badge, MiniBar } from "../components/UI";

const API = "http://localhost:5000/api";

function CodeTag({ children }) {
  return <code style={{ fontFamily: "monospace", background: COLORS.slateLight, padding: "1px 6px", borderRadius: 4, fontSize: 11 }}>{children}</code>;
}

function QueryLabel({ color, bg, children }) {
  return <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 16, background: bg, color, padding: "6px 10px", borderRadius: 6 }}>{children}</div>;
}

export default function AnalyticsPage() {
  const [topicMastery, setTopicMastery] = useState([]);
  const [belowAvg,     setBelowAvg]     = useState([]);
  const [rollingAvg,   setRollingAvg]   = useState([]);
  const [loading,      setLoading]      = useState(true);

  useEffect(() => {
    Promise.all([
      fetch(`${API}/analytics/topic-mastery`).then((r) => r.json()),
      fetch(`${API}/analytics/below-dept-avg`).then((r) => r.json()),
      fetch(`${API}/analytics/rolling-avg`).then((r) => r.json()),
    ]).then(([tm, ba, ra]) => {
      setTopicMastery(tm.data || []);
      setBelowAvg(ba.data || []);
      setRollingAvg(ra.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  // Group rolling avg by student, show last 3 attempts
  const rollingByStudent = rollingAvg.reduce((acc, row) => {
    if (!acc[row.NAME]) acc[row.NAME] = [];
    if (acc[row.NAME].length < 3) acc[row.NAME].push(row);
    return acc;
  }, {});
  const topRolling = Object.entries(rollingByStudent).slice(0, 5);

  if (loading) return <div style={{ textAlign: "center", padding: 60, color: COLORS.textMuted }}>Loading analytics...</div>;

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 5 }}>Queries</div>
        <h2 style={{ fontSize: 24, fontWeight: 700, color: COLORS.text, margin: 0, letterSpacing: "-0.02em" }}>Advanced Analytics</h2>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20, marginBottom: 20 }}>

        {/* Topic Mastery */}
        <div style={{ background: COLORS.white, borderRadius: 20, padding: 24, boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 6px 24px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4, color: COLORS.text }}>Topic Mastery</div>
          <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8 }}>
            via <CodeTag>AVG(mastery_pct) GROUP BY topic, course</CodeTag>
          </div>
          <QueryLabel color={COLORS.indigoDark} bg={COLORS.indigoLight}>Aggregation Query</QueryLabel>
          <div style={{ display: "flex", flexDirection: "column", gap: 10, maxHeight: 300, overflowY: "auto" }}>
            {topicMastery.slice(0, 12).map((t, i) => (
              <div key={i}>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginBottom: 4 }}>
                  <span style={{ color: COLORS.text, fontWeight: 500 }}>{t.TOPIC_NAME} <span style={{ color: COLORS.textMuted, fontSize: 11 }}>({t.COURSE_CODE})</span></span>
                  <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                    <Badge variant={t.DIFFICULTY_LEVEL?.toLowerCase()} small>{t.DIFFICULTY_LEVEL}</Badge>
                    <span style={{ color: COLORS.textMuted, fontWeight: 700 }}>{Number(t.AVG_MASTERY).toFixed(1)}%</span>
                  </div>
                </div>
                <MiniBar value={t.AVG_MASTERY} />
              </div>
            ))}
          </div>
        </div>

        {/* Below Dept Average */}
        <div style={{ background: COLORS.white, borderRadius: 20, padding: 24, boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 6px 24px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4, color: COLORS.text }}>Below Department Average</div>
          <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8 }}>
            via <CodeTag>WHERE cgpa &lt; (SELECT AVG FROM dept)</CodeTag>
          </div>
          <QueryLabel color={COLORS.roseDark} bg={COLORS.roseLight}>Correlated Subquery</QueryLabel>
          <div style={{ display: "flex", flexDirection: "column", gap: 8, maxHeight: 300, overflowY: "auto" }}>
            {belowAvg.slice(0, 10).map((s, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "8px 12px", background: COLORS.roseLight, borderRadius: 8, border: `1px solid ${COLORS.rose}30` }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 700, color: COLORS.text }}>{s.NAME}</div>
                  <div style={{ fontSize: 11, color: COLORS.textMuted }}>Dept avg: {Number(s.DEPT_AVG).toFixed(2)} — Gap: {Number(s.GAP).toFixed(2)}</div>
                </div>
                <div style={{ fontWeight: 700, color: COLORS.rose, fontSize: 15 }}>{Number(s.CGPA).toFixed(2)}</div>
                <span style={{ fontSize: 10, color: COLORS.textMuted }}>{s.DEPT_CODE}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Rolling Average */}
      <div style={{ background: COLORS.white, borderRadius: 20, padding: 24, boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 6px 24px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
        <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4, color: COLORS.text }}>Rolling 3-Attempt Average</div>
        <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 8 }}>
          <CodeTag>AVG(score) OVER (PARTITION BY student_id ORDER BY rn ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)</CodeTag>
        </div>
        <QueryLabel color={COLORS.emeraldDark} bg={COLORS.emeraldLight}>CTE with Rolling Window Function</QueryLabel>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 12 }}>
          {topRolling.map(([name, attempts]) => (
            <div key={name} style={{ background: COLORS.slateLight, borderRadius: 12, padding: 16 }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: COLORS.text, marginBottom: 8 }}>{name}</div>
              {attempts.map((a, i) => (
                <div key={i} style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginBottom: 4 }}>
                  <span style={{ color: COLORS.textMuted }}>Attempt #{a.RN}</span>
                  <span style={{ fontWeight: 600, color: COLORS.text }}>Score: {Number(a.SCORE).toFixed(1)}</span>
                  <span style={{ color: COLORS.indigo, fontWeight: 700 }}>Avg: {Number(a.ROLLING_3_AVG).toFixed(1)}</span>
                </div>
              ))}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}