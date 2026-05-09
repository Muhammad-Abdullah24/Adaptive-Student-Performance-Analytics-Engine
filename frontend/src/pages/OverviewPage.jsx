import { useState, useEffect } from "react";
import COLORS from "../data/colors";
import { StatCard, RiskGauge, MiniBar, Badge } from "../components/UI";

const API = "http://localhost:5000/api";

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
  { key: "CRITICAL", label: "Critical", color: COLORS.rose    },
  { key: "HIGH",     label: "High",     color: COLORS.amber   },
  { key: "MEDIUM",   label: "Medium",   color: "#FBBF24"      },
  { key: "LOW",      label: "Low",      color: COLORS.emerald },
];

export default function OverviewPage() {
  const [students,     setStudents]     = useState([]);
  const [topicMastery, setTopicMastery] = useState([]);
  const [interventions,setInterventions]= useState([]);
  const [loading,      setLoading]      = useState(true);

  useEffect(() => {
    Promise.all([
      fetch(`${API}/students`).then((r) => r.json()),
      fetch(`${API}/analytics/topic-mastery`).then((r) => r.json()),
      fetch(`${API}/interventions`).then((r) => r.json()),
    ]).then(([s, tm, iv]) => {
      setStudents(s.data || []);
      setTopicMastery(tm.data || []);
      setInterventions(iv.data || []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  if (loading) return <div style={{ textAlign: "center", padding: 60, color: COLORS.textMuted }}>Loading dashboard...</div>;

  // Compute stats from real data
  const riskDist = { CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0 };
  students.forEach((s) => { if (riskDist[s.RISK_LEVEL] !== undefined) riskDist[s.RISK_LEVEL]++; });

  const totalStudents = students.length;
  const atRisk        = (riskDist.CRITICAL || 0) + (riskDist.HIGH || 0);
  const avgCgpa       = totalStudents > 0
    ? (students.reduce((sum, s) => sum + Number(s.CGPA), 0) / totalStudents).toFixed(2)
    : "0.00";
  const pendingIV     = interventions.filter((i) => i.STATUS === "PENDING" || i.STATUS === "IN_PROGRESS").length;

  // Top 8 topics for mastery display
  const topTopics = [...topicMastery].sort((a, b) => b.AVG_MASTERY - a.AVG_MASTERY).slice(0, 8);

  // Recent interventions as activity log
  const recentActivity = interventions.slice(0, 6);

  const logBorderColor = (status) => ({
    PENDING:     COLORS.amber,
    IN_PROGRESS: COLORS.sky,
    COMPLETED:   COLORS.emerald,
    CANCELLED:   COLORS.rose,
  }[status] || COLORS.sky);

  // For RiskGauge — convert to lowercase keys
  const riskDistLower = {
    critical: riskDist.CRITICAL,
    high:     riskDist.HIGH,
    medium:   riskDist.MEDIUM,
    low:      riskDist.LOW,
  };

  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14 }}>

      {/* Risk Distribution */}
      <div style={{ ...CARD, gridColumn: "span 2", gridRow: "span 2", display: "flex", flexDirection: "column" }}>
        <div style={LABEL_STYLE}>Risk Distribution</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 20 }}>
          {RISK_META.map((r) => (
            <div key={r.key} style={{ borderRadius: 14, padding: "13px 16px", background: r.color + "0D", borderLeft: `3px solid ${r.color}` }}>
              <div style={{ fontSize: 28, fontWeight: 700, color: r.color, letterSpacing: "-0.03em", lineHeight: 1 }}>
                {riskDist[r.key]}
              </div>
              <div style={{ fontSize: 9, fontWeight: 700, color: r.color, opacity: 0.75, letterSpacing: "0.08em", textTransform: "uppercase", marginTop: 4 }}>{r.label}</div>
            </div>
          ))}
        </div>
        <RiskGauge dist={riskDistLower} />
        <div style={{ marginTop: "auto", paddingTop: 16 }}>
          <div style={{ padding: "10px 13px", background: "#FFF1F2", borderRadius: 10, fontSize: 12, color: COLORS.roseDark, borderLeft: `3px solid ${COLORS.rose}`, lineHeight: 1.6 }}>
            <span style={{ fontWeight: 700 }}>At-risk alert — </span>{atRisk} students flagged Critical or High risk.
          </div>
        </div>
      </div>

      {/* Stat Cards */}
      <StatCard label="Total Students"   value={totalStudents} sub="Across 5 departments" color={COLORS.indigo}  trend={0}   />
      <StatCard label="At-Risk Students" value={atRisk}        sub="Critical + High risk" color={COLORS.rose}   trend={0}   />
      <StatCard label="Avg. CGPA"        value={avgCgpa}       sub="University-wide"      color={COLORS.emerald} trend={0}  />
      <StatCard label="Open Interventions" value={pendingIV}   sub="Pending or in progress" color={COLORS.violet} trend={0} />

      {/* Topic Mastery */}
      <div style={{ ...CARD, gridColumn: "span 2" }}>
        <div style={LABEL_STYLE}>Topic Mastery — Top 8</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 11 }}>
          {topTopics.map((t) => (
            <div key={t.TOPIC_NAME + t.COURSE_CODE}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13, marginBottom: 5 }}>
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

      {/* Recent Interventions as Activity Log */}
      <div style={{ ...CARD, gridColumn: "span 2" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
          <div style={{ ...LABEL_STYLE, marginBottom: 0 }}>Recent Interventions</div>
          <span style={{ fontSize: 10, color: COLORS.textMuted, letterSpacing: "0.04em" }}>Live from Oracle</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
          {recentActivity.map((iv) => (
            <div key={iv.INTERVENTION_ID} style={{
              display: "flex", gap: 11, padding: "10px 13px",
              background: "#F8F9FF", borderRadius: 10,
              borderLeft: `3px solid ${logBorderColor(iv.STATUS)}`,
            }}>
              <div style={{ fontSize: 10, color: logBorderColor(iv.STATUS), fontWeight: 700, minWidth: 80, paddingTop: 1, flexShrink: 0 }}>
                {iv.STATUS?.replace(/_/g, " ")}
              </div>
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: COLORS.text }}>{iv.STUDENT_NAME}</div>
                <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 1 }}>
                  {iv.INT_TYPE?.replace(/_/g, " ")} · {iv.COURSE_CODE || "—"}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}