import { useState } from "react";
import COLORS from "../data/colors";
import { Badge } from "../components/UI";

const TABLES = [
  { name: "DEPARTMENTS",         cols: 5,  fk: 0, desc: "Root of org hierarchy — dept master table" },
  { name: "INSTRUCTORS",         cols: 7,  fk: 1, desc: "Faculty with department and role assignments" },
  { name: "COURSES",             cols: 8,  fk: 2, desc: "Course catalog with credit hours and department mapping" },
  { name: "STUDENTS",            cols: 9,  fk: 1, desc: "Core student registry with enrollment and CGPA data" },
  { name: "TOPICS",              cols: 5,  fk: 1, desc: "Learning taxonomy nodes per course, supports subtopic hierarchy" },
  { name: "ENROLLMENTS",         cols: 6,  fk: 2, desc: "Student-course junction with semester, section, grade" },
  { name: "ASSESSMENTS",         cols: 9,  fk: 2, desc: "Quizzes, assignments, exams per course" },
  { name: "QUESTIONS",           cols: 8,  fk: 2, desc: "Item bank per assessment with topic mapping and difficulty" },
  { name: "ASSESSMENT_ATTEMPTS", cols: 10, fk: 3, desc: "Each submission attempt with score, duration, timestamp" },
  { name: "ATTEMPT_RESPONSES",   cols: 7,  fk: 2, desc: "Per-question responses — the granular core of the schema" },
  { name: "TOPIC_PERFORMANCE",   cols: 7,  fk: 3, desc: "Aggregated mastery per student-topic — updated by trigger" },
  { name: "SESSION_LOGS",        cols: 8,  fk: 2, desc: "Login/activity sessions with duration and event types" },
  { name: "RISK_FLAGS",          cols: 8,  fk: 3, desc: "Auto-generated flags from threshold-based triggers" },
  { name: "INTERVENTIONS",       cols: 9,  fk: 2, desc: "Instructor-assigned or auto-generated intervention records" },
];

const PROCEDURES = [
  { name: "sp_enroll_student",     purpose: "Validates prerequisites and inserts enrollment with audit trail" },
  { name: "sp_submit_attempt",     purpose: "Validates attempt count, scores submission, records late flag" },
  { name: "sp_compute_topic_score",purpose: "Recalculates mastery % using MERGE — called by trigger after every attempt" },
  { name: "sp_generate_risk_report",purpose: "Produces paginated risk summary via REF CURSOR — used by dashboard API" },
  { name: "sp_assign_intervention",purpose: "Creates intervention record linked to a risk flag" },
  { name: "sp_bulk_grade_import",  purpose: "BULK COLLECT import for external grade sheet migration" },
];

const TRIGGERS = [
  { name: "trg_topic_update_after_attempt", event: "AFTER INSERT ON ASSESSMENT_ATTEMPTS", desc: "Calls sp_compute_topic_score for all topics covered in the submitted attempt" },
  { name: "trg_risk_flag_on_cgpa_drop",     event: "AFTER UPDATE OF cgpa ON STUDENTS",    desc: "Inserts a RISK_FLAGS row if CGPA drops below 2.0; sets severity based on how far below" },
  { name: "trg_consecutive_fail_flag",      event: "AFTER INSERT ON ASSESSMENT_ATTEMPTS", desc: "Counts recent fails in same course; inserts HIGH risk flag after 3+ consecutive failures" },
  { name: "trg_attendance_limit",           event: "AFTER INSERT ON SESSION_LOGS",         desc: "Checks absence count against course limit; raises ATTENDANCE_BREACH flag on breach" },
  { name: "trg_enrollment_audit",           event: "AFTER INSERT OR UPDATE ON ENROLLMENTS",desc: "Writes immutable audit record to ENROLLMENT_AUDIT_LOG — append-only, no FK cascade" },
];

const QUERIES = [
  {
    title: "Students below department average — Correlated Subquery",
    sql:
`SELECT s.cms_id, s.name, s.cgpa, d.dept_code,
  ROUND((SELECT AVG(s2.cgpa) FROM STUDENTS s2
         WHERE s2.dept_id = s.dept_id), 2) AS dept_avg
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
WHERE s.cgpa < (
  SELECT AVG(s3.cgpa) FROM STUDENTS s3
  WHERE s3.dept_id = s.dept_id
)
ORDER BY dept_avg - s.cgpa DESC;`,
  },
  {
    title: "Top 3 students per course by score — Window Function RANK()",
    sql:
`SELECT * FROM (
  SELECT s.name, c.course_code, aa.score,
    RANK() OVER (PARTITION BY c.course_id ORDER BY aa.score DESC) AS rnk,
    ROUND(AVG(aa.score) OVER (PARTITION BY c.course_id), 2)       AS course_avg
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN STUDENTS s    ON aa.student_id    = s.student_id
  JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
  JOIN COURSES c     ON a.course_id      = c.course_id
  WHERE aa.status = 'GRADED'
) WHERE rnk <= 3
ORDER BY course_code, rnk;`,
  },
  {
    title: "3-attempt rolling average per student — CTE + Window",
    sql:
`WITH attempt_history AS (
  SELECT s.name, aa.student_id, aa.score, aa.end_time,
    ROW_NUMBER() OVER (
      PARTITION BY aa.student_id ORDER BY aa.end_time DESC
    ) AS rn
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN STUDENTS s ON aa.student_id = s.student_id
  WHERE aa.status = 'GRADED'
),
rolling_avg AS (
  SELECT name, student_id, score, rn,
    ROUND(AVG(score) OVER (
      PARTITION BY student_id
      ORDER BY rn ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3_avg
  FROM attempt_history WHERE rn <= 10
)
SELECT * FROM rolling_avg ORDER BY student_id, rn;`,
  },
  {
    title: "At-risk students with no active intervention — NOT EXISTS",
    sql:
`SELECT s.cms_id, s.name, s.cgpa, s.risk_level, d.dept_code
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
WHERE s.risk_level IN ('HIGH', 'CRITICAL')
  AND NOT EXISTS (
    SELECT 1 FROM INTERVENTIONS iv
    WHERE iv.student_id = s.student_id
      AND iv.status NOT IN ('CANCELLED', 'COMPLETED')
  )
ORDER BY CASE s.risk_level WHEN 'CRITICAL' THEN 1 ELSE 2 END, s.cgpa;`,
  },
];

export default function DatabasePage() {
  const [activeTab, setActiveTab] = useState("schema");

  const tabs = [
    ["schema",     "Schema"],
    ["procedures", "Stored Procedures"],
    ["triggers",   "Triggers"],
    ["queries",    "Key Queries"],
  ];

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: COLORS.text, margin: 0 }}>Database Architecture</h2>
        <p style={{ color: COLORS.textMuted, fontSize: 14, margin: "6px 0 0" }}>
          Oracle 21c XE — 14 tables · 6 stored procedures · 5 triggers · Bitmap indexes · RBAC
        </p>
      </div>

      {/* Tab Bar */}
      <div style={{ display: "flex", gap: 4, marginBottom: 24, background: COLORS.slateLight, padding: 4, borderRadius: 12, width: "fit-content" }}>
        {tabs.map(([k, l]) => (
          <button key={k} onClick={() => setActiveTab(k)} style={{
            border: "none",
            background: activeTab === k ? COLORS.white : "transparent",
            color: activeTab === k ? COLORS.indigo : COLORS.textMuted,
            borderRadius: 8, padding: "8px 18px", fontSize: 13, cursor: "pointer",
            fontWeight: activeTab === k ? 700 : 500,
            boxShadow: activeTab === k ? "0 1px 4px rgba(0,0,0,0.10)" : "none",
          }}>{l}</button>
        ))}
      </div>

      {/* Schema Tab */}
      {activeTab === "schema" && (
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          {TABLES.map((t) => (
            <div key={t.name} style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 12, padding: "14px 18px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                <code style={{ fontFamily: "monospace", fontSize: 13, fontWeight: 700, color: COLORS.indigo }}>{t.name}</code>
                <div style={{ display: "flex", gap: 6 }}>
                  <Badge variant="default" small>{t.cols} cols</Badge>
                  {t.fk > 0 && <Badge variant="info" small>{t.fk} FK{t.fk > 1 ? "s" : ""}</Badge>}
                </div>
              </div>
              <div style={{ fontSize: 12, color: COLORS.textMuted, lineHeight: 1.5 }}>{t.desc}</div>
            </div>
          ))}
        </div>
      )}

      {/* Procedures Tab */}
      {activeTab === "procedures" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          {PROCEDURES.map((p) => (
            <div key={p.name} style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 12, padding: "20px 24px" }}>
              <code style={{ fontFamily: "monospace", fontSize: 14, fontWeight: 700, color: COLORS.violet, display: "block", marginBottom: 8 }}>
                PROCEDURE {p.name}
              </code>
              <div style={{ fontSize: 13, color: COLORS.textMuted }}>{p.purpose}</div>
            </div>
          ))}
        </div>
      )}

      {/* Triggers Tab */}
      {activeTab === "triggers" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          {TRIGGERS.map((t) => (
            <div key={t.name} style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 12, padding: "20px 24px", borderLeft: `4px solid ${COLORS.amber}` }}>
              <code style={{ fontFamily: "monospace", fontSize: 14, fontWeight: 700, color: COLORS.text, display: "block", marginBottom: 4 }}>
                {t.name}
              </code>
              <div style={{ fontSize: 12, color: COLORS.amber, fontWeight: 600, marginBottom: 8 }}>{t.event}</div>
              <div style={{ fontSize: 13, color: COLORS.textMuted }}>{t.desc}</div>
            </div>
          ))}
        </div>
      )}

      {/* Queries Tab */}
      {activeTab === "queries" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          {QUERIES.map((q) => (
            <div key={q.title} style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 14, overflow: "hidden" }}>
              <div style={{ padding: "14px 20px", borderBottom: `1px solid ${COLORS.slate200}`, fontWeight: 700, fontSize: 14, color: COLORS.text }}>
                {q.title}
              </div>
              <pre style={{
                margin: 0, padding: "16px 20px", background: "#0F172A", color: "#93C5FD",
                fontSize: 12, fontFamily: "monospace", lineHeight: 1.8, overflowX: "auto",
              }}>{q.sql}</pre>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
