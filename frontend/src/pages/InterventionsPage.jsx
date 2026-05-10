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
      <div style={{ background: "#fff", borderRadius: 20, padding: 32, width: 500, maxWidth: "90vw", boxShadow: "0 20px 60px rgba(15,23,42,0.2)" }}>
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

export default function InterventionsPage() {
  const [interventions, setInterventions] = useState([]);
  const [students,      setStudents]      = useState([]);
  const [riskFlags,     setRiskFlags]     = useState([]);
  const [loading,       setLoading]       = useState(true);
  const [showCreate,    setShowCreate]    = useState(false);
  const [submitting,    setSubmitting]    = useState(false);
  const [msg,           setMsg]           = useState(null);

  const [form, setForm] = useState({
    studentId: "", flagId: "", instructorId: 1,
    intType: "ACADEMIC_WARNING", description: "",
    dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().split("T")[0],
  });

  const load = () => {
    setLoading(true);
    fetch(`${API}/interventions`)
      .then((r) => r.json())
      .then((d) => { setInterventions(d.data || []); setLoading(false); })
      .catch(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  useEffect(() => {
    fetch(`${API}/students`)
      .then((r) => r.json())
      .then((d) => setStudents(d.data || []));
  }, []);

  const showToast = (text, ok = true) => {
    setMsg({ text, ok });
    setTimeout(() => setMsg(null), 4000);
  };

  const handleStatusUpdate = (id, newStatus) => {
    fetch(`${API}/interventions/${id}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: newStatus }),
    }).then(() => { load(); showToast("Status updated successfully."); });
  };

  const handleCreate = async () => {
    if (!form.studentId || !form.description) {
      showToast("Student and description are required.", false); return;
    }
    setSubmitting(true);
    try {
      // Get a risk flag for this student if exists, otherwise use first flag
      const flagRes = await fetch(`${API}/interventions`).then((r) => r.json());
      const existingFlag = flagRes.data?.find((i) => i.student_id == form.studentId);

      const r = await fetch(`${API}/interventions`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          flagId:       form.flagId || 1,
          studentId:    parseInt(form.studentId),
          instructorId: parseInt(form.instructorId),
          intType:      form.intType,
          description:  form.description,
          dueDate:      form.dueDate,
        }),
      });
      const d = await r.json();
      if (d.success) {
        showToast("Intervention created successfully.");
        setShowCreate(false);
        setForm({ studentId: "", flagId: "", instructorId: 1, intType: "ACADEMIC_WARNING", description: "", dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().split("T")[0] });
        load();
      } else {
        showToast(d.message, false);
      }
    } catch { showToast("Request failed", false); }
    setSubmitting(false);
  };

  const counts = {
    PENDING:     interventions.filter((i) => i.STATUS === "PENDING").length,
    IN_PROGRESS: interventions.filter((i) => i.STATUS === "IN_PROGRESS").length,
    COMPLETED:   interventions.filter((i) => i.STATUS === "COMPLETED").length,
  };

  const statusColor = (s) => ({ PENDING: "#F59E0B", IN_PROGRESS: "#0EA5E9", COMPLETED: "#10B981", CANCELLED: "#EF4444" }[s] || "#94A3B8");

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
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 5 }}>Monitoring</div>
          <h2 style={{ fontSize: 24, fontWeight: 700, color: COLORS.text, margin: 0 }}>Interventions Tracker</h2>
        </div>
        <button onClick={() => setShowCreate(true)} style={{
          background: "#4F46E5", color: "#fff", border: "none",
          borderRadius: 9, padding: "9px 18px", fontSize: 12, fontWeight: 600, cursor: "pointer",
        }}>+ Create Intervention</button>
      </div>

      {/* Summary */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 16, marginBottom: 24 }}>
        {[
          { label: "PENDING",     count: counts.PENDING,     color: "#F59E0B" },
          { label: "IN PROGRESS", count: counts.IN_PROGRESS, color: "#0EA5E9" },
          { label: "COMPLETED",   count: counts.COMPLETED,   color: "#10B981" },
        ].map((s) => (
          <div key={s.label} style={{
            background: "#fff", border: "1px solid rgba(15,23,42,0.06)",
            borderRadius: 16, padding: "18px 20px", display: "flex", alignItems: "center", gap: 16,
            boxShadow: "0 1px 3px rgba(15,23,42,0.04)", borderTop: `3px solid ${s.color}`,
          }}>
            <div style={{ fontSize: 32, fontWeight: 700, color: s.color }}>{s.count}</div>
            <div style={{ fontSize: 12, fontWeight: 700, color: s.color, letterSpacing: "0.05em" }}>{s.label}</div>
          </div>
        ))}
      </div>

      {loading && <div style={{ textAlign: "center", padding: 40, color: COLORS.textMuted }}>Loading interventions...</div>}

      <div style={{ display: "flex", flexDirection: "column", gap: 12, marginBottom: 24 }}>
        {interventions.map((iv) => (
          <div key={iv.INTERVENTION_ID} style={{
            background: "#fff", border: "1px solid rgba(15,23,42,0.06)",
            borderRadius: 16, padding: "18px 24px",
            display: "flex", justifyContent: "space-between", alignItems: "center",
            boxShadow: "0 1px 3px rgba(15,23,42,0.04)",
            borderLeft: `4px solid ${statusColor(iv.STATUS)}`,
          }}>
            <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
              <div style={{
                width: 44, height: 44, borderRadius: "50%", background: "#EEF2FF",
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 16, fontWeight: 700, color: "#4F46E5",
              }}>
                {iv.STUDENT_NAME?.split(" ").map((n) => n[0]).join("")}
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: 15, color: COLORS.text, marginBottom: 3 }}>{iv.STUDENT_NAME}</div>
                <div style={{ fontSize: 13, color: COLORS.textMuted }}>
                  {iv.INT_TYPE?.replace(/_/g, " ")}
                  {iv.COURSE_CODE ? ` · ${iv.COURSE_CODE}` : ""}
                  {iv.FLAG_TYPE ? <span style={{ color: "#EF4444" }}> · {iv.FLAG_TYPE}</span> : ""}
                </div>
                <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 2 }}>
                  Due: {iv.DUE_DATE ? new Date(iv.DUE_DATE).toLocaleDateString() : "—"}
                </div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <Badge variant={iv.STATUS?.toLowerCase()}>{iv.STATUS?.replace(/_/g, " ")}</Badge>
              {iv.STATUS === "PENDING" && (
                <button onClick={() => handleStatusUpdate(iv.INTERVENTION_ID, "IN_PROGRESS")} style={{
                  border: "1px solid #0EA5E9", background: "#fff", color: "#0EA5E9",
                  borderRadius: 8, padding: "7px 14px", fontSize: 12, cursor: "pointer", fontWeight: 600,
                }}>Start</button>
              )}
              {iv.STATUS === "IN_PROGRESS" && (
                <button onClick={() => handleStatusUpdate(iv.INTERVENTION_ID, "COMPLETED")} style={{
                  border: "1px solid #10B981", background: "#fff", color: "#10B981",
                  borderRadius: 8, padding: "7px 14px", fontSize: 12, cursor: "pointer", fontWeight: 600,
                }}>Complete</button>
              )}
            </div>
          </div>
        ))}
      </div>

      {showCreate && (
        <Modal title="Create Intervention" onClose={() => setShowCreate(false)}>
          <Field label="Student">
            <select style={selectStyle} value={form.studentId} onChange={(e) => setForm({ ...form, studentId: e.target.value })}>
              <option value="">Select Student</option>
              {students.map((s) => <option key={s.STUDENT_ID} value={s.STUDENT_ID}>{s.NAME} ({s.CMS_ID}) - {s.RISK_LEVEL}</option>)}
            </select>
          </Field>
          <Field label="Intervention Type">
            <select style={selectStyle} value={form.intType} onChange={(e) => setForm({ ...form, intType: e.target.value })}>
              {["ACADEMIC_WARNING", "COUNSELING_REFERRAL", "TUTORING_ASSIGNED", "ATTENDANCE_WARNING", "PARENT_NOTIFICATION"].map((t) => (
                <option key={t} value={t}>{t.replace(/_/g, " ")}</option>
              ))}
            </select>
          </Field>
          <Field label="Description">
            <textarea style={{ ...inputStyle, minHeight: 80, resize: "vertical" }}
              placeholder="Describe the intervention action plan..."
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />
          </Field>
          <Field label="Due Date">
            <input style={inputStyle} type="date" value={form.dueDate} onChange={(e) => setForm({ ...form, dueDate: e.target.value })} />
          </Field>
          <Field label="Risk Flag ID (optional)">
            <input style={inputStyle} type="number" placeholder="Leave blank to use default flag"
              value={form.flagId} onChange={(e) => setForm({ ...form, flagId: e.target.value })} />
          </Field>
          <button onClick={handleCreate} disabled={submitting} style={{
            width: "100%", background: "#4F46E5", color: "#fff", border: "none",
            borderRadius: 10, padding: "12px", fontSize: 14, fontWeight: 700, cursor: "pointer",
          }}>{submitting ? "Creating..." : "Create Intervention"}</button>
        </Modal>
      )}
    </div>
  );
}