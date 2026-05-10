import { useState, useEffect } from "react";
import COLORS from "../data/colors";
import { Badge } from "../components/UI";

const API = "http://localhost:5000/api";

function Modal({ title, onClose, children }) {
  return (
    <div style={{
      position: "fixed", inset: 0, background: "rgba(15,23,42,0.5)",
      display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000,
    }}>
      <div style={{
        background: "#fff", borderRadius: 20, padding: 32, width: 480, maxWidth: "90vw",
        boxShadow: "0 20px 60px rgba(15,23,42,0.2)",
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
          <div style={{ fontSize: 18, fontWeight: 700, color: COLORS.text }}>{title}</div>
          <button onClick={onClose} style={{ background: "none", border: "none", fontSize: 20, cursor: "pointer", color: COLORS.textMuted }}>x</button>
        </div>
        {children}
      </div>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{ fontSize: 11, fontWeight: 700, color: COLORS.textMuted, letterSpacing: "0.06em", textTransform: "uppercase", marginBottom: 6 }}>{label}</div>
      {children}
    </div>
  );
}

const inputStyle = {
  width: "100%", border: "1px solid #E2E8F0", borderRadius: 8,
  padding: "10px 12px", fontSize: 14, outline: "none", boxSizing: "border-box",
  fontFamily: "inherit", color: "#0F172A", background: "#fff",
};

const selectStyle = { ...inputStyle, cursor: "pointer" };

export default function StudentsPage() {
  const [students,   setStudents]   = useState([]);
  const [courses,    setCourses]    = useState([]);
  const [loading,    setLoading]    = useState(true);
  const [search,     setSearch]     = useState("");
  const [filterRisk, setFilterRisk] = useState("all");
  const [filterDept, setFilterDept] = useState("all");
  const [selected,   setSelected]   = useState(null);
  const [showAdd,    setShowAdd]    = useState(false);
  const [showEnroll, setShowEnroll] = useState(false);
  const [msg,        setMsg]        = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const [addForm,    setAddForm]    = useState({ cmsId: "", name: "", email: "", cgpa: "", semester: "", deptCode: "CS" });
  const [enrollForm, setEnrollForm] = useState({ studentId: "", courseId: "", semesterLabel: "Spring 2026", section: "A" });

  const loadStudents = () => {
    const params = new URLSearchParams();
    if (filterRisk !== "all") params.append("risk", filterRisk.toUpperCase());
    if (filterDept !== "all") params.append("dept", filterDept.toUpperCase());
    setLoading(true);
    fetch(`${API}/students?${params}`)
      .then((r) => r.json())
      .then((d) => { setStudents(d.data || []); setLoading(false); })
      .catch(() => setLoading(false));
  };

  useEffect(() => { loadStudents(); }, [filterRisk, filterDept]);

  useEffect(() => {
    fetch(`${API}/courses`)
      .then((r) => r.json())
      .then((d) => setCourses(d.data || []));
  }, []);

  const filtered = students.filter((s) => {
    const q = search.toLowerCase();
    return s.NAME?.toLowerCase().includes(q) || s.CMS_ID?.includes(search);
  });

  const showToast = (text, ok = true) => {
    setMsg({ text, ok });
    setTimeout(() => setMsg(null), 4000);
  };

  const handleAddStudent = async () => {
    setSubmitting(true);
    try {
      const r = await fetch(`${API}/students`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(addForm),
      });
      const d = await r.json();
      if (d.success) {
        showToast(d.message);
        setShowAdd(false);
        setAddForm({ cmsId: "", name: "", email: "", cgpa: "", semester: "", deptCode: "CS" });
        loadStudents();
      } else {
        showToast(d.message, false);
      }
    } catch { showToast("Request failed", false); }
    setSubmitting(false);
  };

  const handleEnroll = async () => {
    setSubmitting(true);
    try {
      const r = await fetch(`${API}/students/enroll`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(enrollForm),
      });
      const d = await r.json();
      if (d.success) {
        showToast(d.message);
        setShowEnroll(false);
        loadStudents();
      } else {
        showToast(d.message, false);
      }
    } catch { showToast("Request failed", false); }
    setSubmitting(false);
  };

  const depts = ["all", "CS", "EE", "CE", "SE", "AI"];

  return (
    <div>
      {msg && (
        <div style={{
          position: "fixed", top: 20, right: 20, zIndex: 2000,
          background: msg.ok ? "#10B981" : "#EF4444",
          color: "#fff", padding: "12px 20px", borderRadius: 12,
          fontWeight: 600, fontSize: 14, boxShadow: "0 4px 20px rgba(0,0,0,0.15)",
        }}>{msg.text}</div>
      )}

      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 24 }}>
        <div>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 5 }}>Records</div>
          <h2 style={{ fontSize: 24, fontWeight: 700, color: COLORS.text, margin: 0 }}>
            Student Registry <span style={{ fontSize: 14, fontWeight: 400, color: COLORS.textMuted }}>({filtered.length} students)</span>
          </h2>
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          <button onClick={() => setShowEnroll(true)} style={{
            background: "#fff", color: "#4F46E5", border: "1px solid #4F46E5",
            borderRadius: 9, padding: "9px 18px", fontSize: 12, fontWeight: 600, cursor: "pointer",
          }}>+ Enroll in Course</button>
          <button onClick={() => setShowAdd(true)} style={{
            background: "#4F46E5", color: "#fff", border: "none",
            borderRadius: 9, padding: "9px 18px", fontSize: 12, fontWeight: 600, cursor: "pointer",
          }}>+ Add Student</button>
        </div>
      </div>

      <div style={{ display: "flex", gap: 12, marginBottom: 12 }}>
        <input placeholder="Search by name or CMS ID..." value={search}
          onChange={(e) => setSearch(e.target.value)} style={{ ...inputStyle, flex: 1 }} />
      </div>
      <div style={{ display: "flex", gap: 8, marginBottom: 8, flexWrap: "wrap" }}>
        <span style={{ fontSize: 12, color: COLORS.textMuted, alignSelf: "center" }}>Risk:</span>
        {["all", "critical", "high", "medium", "low"].map((r) => (
          <button key={r} onClick={() => setFilterRisk(r)} style={{
            border: `1px solid ${filterRisk === r ? "#4F46E5" : "#E2E8F0"}`,
            background: filterRisk === r ? "#EEF2FF" : "#fff",
            color: filterRisk === r ? "#4F46E5" : COLORS.textMuted,
            borderRadius: 8, padding: "6px 12px", fontSize: 12, cursor: "pointer", fontWeight: 600, textTransform: "capitalize",
          }}>{r}</button>
        ))}
      </div>
      <div style={{ display: "flex", gap: 8, marginBottom: 20, flexWrap: "wrap" }}>
        <span style={{ fontSize: 12, color: COLORS.textMuted, alignSelf: "center" }}>Dept:</span>
        {depts.map((d) => (
          <button key={d} onClick={() => setFilterDept(d)} style={{
            border: `1px solid ${filterDept === d ? "#4F46E5" : "#E2E8F0"}`,
            background: filterDept === d ? "#EEF2FF" : "#fff",
            color: filterDept === d ? "#4F46E5" : COLORS.textMuted,
            borderRadius: 8, padding: "6px 12px", fontSize: 12, cursor: "pointer", fontWeight: 600,
          }}>{d}</button>
        ))}
      </div>

      {loading && <div style={{ textAlign: "center", padding: 40, color: COLORS.textMuted }}>Loading students...</div>}

      {!loading && (
        <div style={{ background: "#fff", borderRadius: 18, overflow: "hidden", boxShadow: "0 1px 3px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
            <thead>
              <tr style={{ background: "#F8F9FF", borderBottom: "1px solid rgba(15,23,42,0.06)" }}>
                {["CMS ID", "Name", "Dept", "Semester", "CGPA", "Risk Level", "Open Flags", ""].map((h) => (
                  <th key={h} style={{ padding: "13px 16px", textAlign: "left", fontWeight: 700, color: COLORS.textMuted, fontSize: 10, letterSpacing: "0.08em", textTransform: "uppercase" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((s) => (
                <tr key={s.STUDENT_ID} onClick={() => setSelected(selected?.STUDENT_ID === s.STUDENT_ID ? null : s)}
                  style={{ borderTop: "1px solid rgba(15,23,42,0.04)", cursor: "pointer" }}>
                  <td style={{ padding: "14px 16px", fontWeight: 600, color: "#4F46E5" }}>{s.CMS_ID}</td>
                  <td style={{ padding: "14px 16px", fontWeight: 600, color: COLORS.text }}>{s.NAME}</td>
                  <td style={{ padding: "14px 16px", color: COLORS.textMuted }}>{s.DEPT_CODE}</td>
                  <td style={{ padding: "14px 16px", color: COLORS.textMuted }}>{s.SEMESTER}</td>
                  <td style={{ padding: "14px 16px" }}>
                    <span style={{ fontWeight: 700, fontSize: 15, color: s.CGPA >= 3 ? "#10B981" : s.CGPA >= 2 ? "#F59E0B" : "#EF4444" }}>
                      {Number(s.CGPA).toFixed(2)}
                    </span>
                  </td>
                  <td style={{ padding: "14px 16px" }}><Badge variant={s.RISK_LEVEL?.toLowerCase()}>{s.RISK_LEVEL}</Badge></td>
                  <td style={{ padding: "14px 16px" }}>
                    <span style={{ color: s.OPEN_FLAGS > 0 ? "#EF4444" : COLORS.text, fontWeight: s.OPEN_FLAGS > 0 ? 700 : 400 }}>{s.OPEN_FLAGS}</span>
                  </td>
                  <td style={{ padding: "14px 16px", color: "#4F46E5", fontSize: 12, fontWeight: 600 }}>
                    {selected?.STUDENT_ID === s.STUDENT_ID ? "Close" : "View"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {selected && (
        <div style={{ marginTop: 20, background: "#fff", borderRadius: 18, padding: 26, border: "1px solid rgba(79,70,229,0.15)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
            <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
              <div style={{ width: 56, height: 56, borderRadius: "50%", background: "#EEF2FF", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, fontWeight: 700, color: "#4F46E5" }}>
                {selected.NAME?.split(" ").map((n) => n[0]).join("")}
              </div>
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: COLORS.text }}>{selected.NAME}</div>
                <div style={{ color: COLORS.textMuted, fontSize: 14 }}>{selected.CMS_ID} - {selected.DEPT_CODE} - Semester {selected.SEMESTER}</div>
              </div>
            </div>
            <Badge variant={selected.RISK_LEVEL?.toLowerCase()}>{selected.RISK_LEVEL} RISK</Badge>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
            {[
              { label: "CGPA",       val: Number(selected.CGPA).toFixed(2) },
              { label: "Open Flags", val: selected.OPEN_FLAGS },
              { label: "Department", val: selected.DEPT_CODE  },
              { label: "Semester",   val: selected.SEMESTER   },
            ].map((m) => (
              <div key={m.label} style={{ background: "#F1F5F9", borderRadius: 10, padding: "14px 16px" }}>
                <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600, marginBottom: 6 }}>{m.label}</div>
                <div style={{ fontSize: 20, fontWeight: 700, color: COLORS.text }}>{m.val}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {showAdd && (
        <Modal title="Add New Student" onClose={() => setShowAdd(false)}>
          <Field label="CMS ID"><input style={inputStyle} placeholder="e.g. 505001" value={addForm.cmsId} onChange={(e) => setAddForm({ ...addForm, cmsId: e.target.value })} /></Field>
          <Field label="Full Name"><input style={inputStyle} placeholder="e.g. Ali Raza" value={addForm.name} onChange={(e) => setAddForm({ ...addForm, name: e.target.value })} /></Field>
          <Field label="Email"><input style={inputStyle} placeholder="e.g. ali.raza@stud.nust.edu.pk" value={addForm.email} onChange={(e) => setAddForm({ ...addForm, email: e.target.value })} /></Field>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12 }}>
            <Field label="CGPA"><input style={inputStyle} placeholder="0.00-4.00" type="number" step="0.01" min="0" max="4" value={addForm.cgpa} onChange={(e) => setAddForm({ ...addForm, cgpa: e.target.value })} /></Field>
            <Field label="Semester"><input style={inputStyle} placeholder="1-8" type="number" min="1" max="8" value={addForm.semester} onChange={(e) => setAddForm({ ...addForm, semester: e.target.value })} /></Field>
            <Field label="Department">
              <select style={selectStyle} value={addForm.deptCode} onChange={(e) => setAddForm({ ...addForm, deptCode: e.target.value })}>
                {["CS", "EE", "CE", "SE", "AI"].map((d) => <option key={d}>{d}</option>)}
              </select>
            </Field>
          </div>
          <div style={{ fontSize: 12, color: COLORS.textMuted, marginBottom: 16 }}>Risk level is auto-calculated from CGPA.</div>
          <button onClick={handleAddStudent} disabled={submitting} style={{
            width: "100%", background: "#4F46E5", color: "#fff", border: "none",
            borderRadius: 10, padding: "12px", fontSize: 14, fontWeight: 700, cursor: "pointer",
          }}>{submitting ? "Adding..." : "Add Student"}</button>
        </Modal>
      )}

      {showEnroll && (
        <Modal title="Enroll Student in Course" onClose={() => setShowEnroll(false)}>
          <Field label="Student">
            <select style={selectStyle} value={enrollForm.studentId} onChange={(e) => setEnrollForm({ ...enrollForm, studentId: e.target.value })}>
              <option value="">Select Student</option>
              {students.map((s) => <option key={s.STUDENT_ID} value={s.STUDENT_ID}>{s.NAME} ({s.CMS_ID})</option>)}
            </select>
          </Field>
          <Field label="Course">
            <select style={selectStyle} value={enrollForm.courseId} onChange={(e) => setEnrollForm({ ...enrollForm, courseId: e.target.value })}>
              <option value="">Select Course</option>
              {courses.map((c) => <option key={c.COURSE_ID} value={c.COURSE_ID}>{c.COURSE_CODE} - {c.TITLE}</option>)}
            </select>
          </Field>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            <Field label="Semester">
              <select style={selectStyle} value={enrollForm.semesterLabel} onChange={(e) => setEnrollForm({ ...enrollForm, semesterLabel: e.target.value })}>
                {["Spring 2026", "Fall 2026", "Spring 2027"].map((s) => <option key={s}>{s}</option>)}
              </select>
            </Field>
            <Field label="Section">
              <select style={selectStyle} value={enrollForm.section} onChange={(e) => setEnrollForm({ ...enrollForm, section: e.target.value })}>
                {["A", "B", "C"].map((s) => <option key={s}>{s}</option>)}
              </select>
            </Field>
          </div>
          <button onClick={handleEnroll} disabled={submitting || !enrollForm.studentId || !enrollForm.courseId} style={{
            width: "100%", background: "#4F46E5", color: "#fff", border: "none",
            borderRadius: 10, padding: "12px", fontSize: 14, fontWeight: 700, cursor: "pointer",
            opacity: !enrollForm.studentId || !enrollForm.courseId ? 0.6 : 1,
          }}>{submitting ? "Enrolling..." : "Enroll Student"}</button>
        </Modal>
      )}
    </div>
  );
}