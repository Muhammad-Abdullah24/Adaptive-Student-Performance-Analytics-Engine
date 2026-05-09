import { useState, useEffect } from "react";
import COLORS from "../data/colors";
import { MiniBar } from "../components/UI";

const API = "http://localhost:5000/api";

export default function CoursesPage() {
  const [courses,  setCourses]  = useState([]);
  const [loading,  setLoading]  = useState(true);
  const [error,    setError]    = useState(null);
  const [expanded, setExpanded] = useState(null);
  const [students, setStudents] = useState([]);
  const [loadingStudents, setLoadingStudents] = useState(false);

  useEffect(() => {
    fetch(`${API}/courses`)
      .then((r) => r.json())
      .then((d) => { setCourses(d.data || []); setLoading(false); })
      .catch(() => { setError("Failed to load courses"); setLoading(false); });
  }, []);

  const handleExpand = (courseCode) => {
    if (expanded === courseCode) { setExpanded(null); setStudents([]); return; }
    setExpanded(courseCode);
    setLoadingStudents(true);
    fetch(`${API}/courses/${courseCode}/students`)
      .then((r) => r.json())
      .then((d) => { setStudents(d.data || []); setLoadingStudents(false); })
      .catch(() => setLoadingStudents(false));
  };

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 5 }}>Instructor View</div>
        <h2 style={{ fontSize: 24, fontWeight: 700, color: COLORS.text, margin: 0, letterSpacing: "-0.02em" }}>Course Analytics</h2>
      </div>

      {loading && <div style={{ textAlign: "center", padding: 40, color: COLORS.textMuted }}>Loading courses...</div>}
      {error   && <div style={{ textAlign: "center", padding: 40, color: COLORS.rose }}>{error}</div>}

      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {courses.map((c) => (
          <div key={c.COURSE_ID}>
            <div style={{
              background: COLORS.white, border: "1px solid rgba(15,23,42,0.06)",
              borderRadius: 18, padding: 24,
              display: "grid", gridTemplateColumns: "1fr auto", gap: 20, alignItems: "center",
              boxShadow: "0 1px 3px rgba(15,23,42,0.04), 0 4px 20px rgba(15,23,42,0.04)",
            }}>
              <div>
                <div style={{ display: "flex", gap: 12, alignItems: "center", marginBottom: 8 }}>
                  <span style={{ background: COLORS.indigoLight, color: COLORS.indigo, padding: "3px 10px", borderRadius: 6, fontSize: 12, fontWeight: 700 }}>{c.COURSE_CODE}</span>
                  <span style={{ fontSize: 16, fontWeight: 700, color: COLORS.text }}>{c.TITLE}</span>
                </div>
                <div style={{ fontSize: 13, color: COLORS.textMuted, marginBottom: 14 }}>
                  {c.INSTRUCTOR_NAME} · {c.ENROLLED_STUDENTS} students enrolled
                  {c.FLAGGED_STUDENTS > 0 && <span style={{ color: COLORS.rose, fontWeight: 700 }}> · {c.FLAGGED_STUDENTS} flagged</span>}
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, maxWidth: 400 }}>
                  <div>
                    <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600, marginBottom: 4 }}>CLASS AVERAGE</div>
                    <div style={{ fontSize: 18, fontWeight: 700, color: COLORS.text, marginBottom: 6 }}>{Number(c.AVG_SCORE || 0).toFixed(1)}%</div>
                    <MiniBar value={c.AVG_SCORE || 0} height={5} />
                  </div>
                  <div>
                    <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600, marginBottom: 4 }}>PASS RATE</div>
                    <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 6, color: c.PASS_RATE_PCT >= 80 ? COLORS.emerald : c.PASS_RATE_PCT >= 70 ? COLORS.amber : COLORS.rose }}>
                      {Number(c.PASS_RATE_PCT || 0).toFixed(1)}%
                    </div>
                    <MiniBar value={c.PASS_RATE_PCT || 0} color={COLORS.emerald} height={5} />
                  </div>
                </div>
              </div>

              <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
                <div style={{
                  width: 80, height: 80, borderRadius: "50%",
                  background: `conic-gradient(${COLORS.emerald} ${(c.PASS_RATE_PCT || 0) * 3.6}deg, ${COLORS.slate200} 0deg)`,
                  display: "flex", alignItems: "center", justifyContent: "center",
                }}>
                  <div style={{ width: 58, height: 58, borderRadius: "50%", background: COLORS.white, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14, fontWeight: 700, color: COLORS.text }}>
                    {Number(c.PASS_RATE_PCT || 0).toFixed(0)}%
                  </div>
                </div>
                <button onClick={() => handleExpand(c.COURSE_CODE)} style={{
                  border: `1px solid ${COLORS.indigo}`, background: expanded === c.COURSE_CODE ? COLORS.indigo : COLORS.white,
                  color: expanded === c.COURSE_CODE ? COLORS.white : COLORS.indigo,
                  borderRadius: 8, padding: "6px 14px", fontSize: 12, cursor: "pointer", fontWeight: 600,
                }}>
                  {expanded === c.COURSE_CODE ? "Hide Students" : "View Students"}
                </button>
              </div>
            </div>

            {/* Expanded student list */}
            {expanded === c.COURSE_CODE && (
              <div style={{ background: "#F8F9FF", border: "1px solid rgba(79,70,229,0.12)", borderRadius: "0 0 16px 16px", padding: 20, marginTop: -8 }}>
                {loadingStudents ? (
                  <div style={{ textAlign: "center", color: COLORS.textMuted, padding: 20 }}>Loading students...</div>
                ) : (
                  <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
                    <thead>
                      <tr>
                        {["CMS ID", "Name", "CGPA", "Risk", "Section", "Grade", "Status"].map((h) => (
                          <th key={h} style={{ padding: "8px 12px", textAlign: "left", fontWeight: 700, color: COLORS.textMuted, fontSize: 10, letterSpacing: "0.08em", textTransform: "uppercase" }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {students.map((s, i) => (
                        <tr key={i} style={{ borderTop: "1px solid rgba(15,23,42,0.06)" }}>
                          <td style={{ padding: "10px 12px", color: COLORS.indigo, fontWeight: 600 }}>{s.CMS_ID}</td>
                          <td style={{ padding: "10px 12px", fontWeight: 600, color: COLORS.text }}>{s.NAME}</td>
                          <td style={{ padding: "10px 12px", fontWeight: 700, color: s.CGPA >= 3 ? COLORS.emerald : s.CGPA >= 2 ? COLORS.amber : COLORS.rose }}>{Number(s.CGPA).toFixed(2)}</td>
                          <td style={{ padding: "10px 12px" }}>
                            <span style={{ fontSize: 11, fontWeight: 700, color: s.RISK_LEVEL === "CRITICAL" ? COLORS.rose : s.RISK_LEVEL === "HIGH" ? COLORS.amber : COLORS.emerald }}>
                              {s.RISK_LEVEL}
                            </span>
                          </td>
                          <td style={{ padding: "10px 12px", color: COLORS.textMuted }}>{s.SECTION}</td>
                          <td style={{ padding: "10px 12px", color: COLORS.textMuted }}>{s.FINAL_GRADE || "—"}</td>
                          <td style={{ padding: "10px 12px", color: COLORS.textMuted }}>{s.ENROLLMENT_STATUS}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}