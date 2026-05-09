import { useState, useEffect } from "react";
import COLORS from "../data/colors";
import { Badge } from "../components/UI";

const API = "http://localhost:5000/api";

export default function InterventionsPage() {
  const [interventions, setInterventions] = useState([]);
  const [loading,       setLoading]       = useState(true);
  const [error,         setError]         = useState(null);

  const load = () => {
    setLoading(true);
    fetch(`${API}/interventions`)
      .then((r) => r.json())
      .then((d) => { setInterventions(d.data || []); setLoading(false); })
      .catch(() => { setError("Failed to load interventions"); setLoading(false); });
  };

  useEffect(() => { load(); }, []);

  const counts = {
    PENDING:     interventions.filter((i) => i.STATUS === "PENDING").length,
    IN_PROGRESS: interventions.filter((i) => i.STATUS === "IN_PROGRESS").length,
    COMPLETED:   interventions.filter((i) => i.STATUS === "COMPLETED").length,
  };

  const handleStatusUpdate = (id, newStatus) => {
    fetch(`${API}/interventions/${id}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: newStatus }),
    }).then(() => load());
  };

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 24 }}>
        <div>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 5 }}>Monitoring</div>
          <h2 style={{ fontSize: 24, fontWeight: 700, color: COLORS.text, margin: 0, letterSpacing: "-0.02em" }}>Interventions Tracker</h2>
        </div>
      </div>

      {/* Summary */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 16, marginBottom: 24 }}>
        {[
          { label: "PENDING",     count: counts.PENDING,     color: COLORS.amber   },
          { label: "IN PROGRESS", count: counts.IN_PROGRESS, color: COLORS.sky     },
          { label: "COMPLETED",   count: counts.COMPLETED,   color: COLORS.emerald },
        ].map((s) => (
          <div key={s.label} style={{
            background: COLORS.white, border: `1px solid rgba(15,23,42,0.06)`,
            borderRadius: 16, padding: "18px 20px", display: "flex", alignItems: "center", gap: 16,
            boxShadow: "0 1px 3px rgba(15,23,42,0.04), 0 4px 16px rgba(15,23,42,0.04)",
            borderTop: `3px solid ${s.color}`,
          }}>
            <div style={{ fontSize: 32, fontWeight: 700, color: s.color }}>{s.count}</div>
            <div style={{ fontSize: 12, fontWeight: 700, color: s.color, letterSpacing: "0.05em" }}>{s.label}</div>
          </div>
        ))}
      </div>

      {loading && <div style={{ textAlign: "center", padding: 40, color: COLORS.textMuted }}>Loading interventions...</div>}
      {error   && <div style={{ textAlign: "center", padding: 40, color: COLORS.rose }}>{error}</div>}

      {/* Intervention Cards */}
      <div style={{ display: "flex", flexDirection: "column", gap: 12, marginBottom: 24 }}>
        {interventions.map((iv) => (
          <div key={iv.INTERVENTION_ID} style={{
            background: COLORS.white, border: "1px solid rgba(15,23,42,0.06)",
            borderRadius: 16, padding: "18px 24px",
            display: "flex", justifyContent: "space-between", alignItems: "center",
            boxShadow: "0 1px 3px rgba(15,23,42,0.04), 0 4px 16px rgba(15,23,42,0.03)",
          }}>
            <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
              <div style={{
                width: 44, height: 44, borderRadius: "50%", background: COLORS.indigoLight,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 16, fontWeight: 700, color: COLORS.indigo,
              }}>
                {iv.STUDENT_NAME?.split(" ").map((n) => n[0]).join("")}
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: 15, color: COLORS.text, marginBottom: 3 }}>{iv.STUDENT_NAME}</div>
                <div style={{ fontSize: 13, color: COLORS.textMuted }}>
                  {iv.INT_TYPE?.replace(/_/g, " ")} · {iv.COURSE_CODE || "—"}
                  {iv.FLAG_TYPE && <span style={{ color: COLORS.rose }}> · {iv.FLAG_TYPE}</span>}
                </div>
                <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 2 }}>
                  Assigned: {iv.ASSIGNED_DATE ? new Date(iv.ASSIGNED_DATE).toLocaleDateString() : "—"} · Due: {iv.DUE_DATE ? new Date(iv.DUE_DATE).toLocaleDateString() : "—"}
                </div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <Badge variant={iv.STATUS?.toLowerCase()}>{iv.STATUS?.replace(/_/g, " ")}</Badge>
              {iv.STATUS === "PENDING" && (
                <button onClick={() => handleStatusUpdate(iv.INTERVENTION_ID, "IN_PROGRESS")} style={{
                  border: `1px solid ${COLORS.sky}`, background: COLORS.white,
                  color: COLORS.sky, borderRadius: 8, padding: "7px 14px",
                  fontSize: 12, cursor: "pointer", fontWeight: 600,
                }}>Start</button>
              )}
              {iv.STATUS === "IN_PROGRESS" && (
                <button onClick={() => handleStatusUpdate(iv.INTERVENTION_ID, "COMPLETED")} style={{
                  border: `1px solid ${COLORS.emerald}`, background: COLORS.white,
                  color: COLORS.emerald, borderRadius: 8, padding: "7px 14px",
                  fontSize: 12, cursor: "pointer", fontWeight: 600,
                }}>Complete</button>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* DB Context */}
      <div style={{ background: "#F8F9FF", border: "1px solid rgba(79,70,229,0.12)", borderRadius: 16, padding: 20, borderLeft: `3px solid ${COLORS.indigo}` }}>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: COLORS.indigo, marginBottom: 8 }}>Database Backend</div>
        <div style={{ fontSize: 13, color: COLORS.slate, lineHeight: 1.7 }}>
          Each intervention record is stored in the{" "}
          <code style={{ background: COLORS.white, padding: "1px 6px", borderRadius: 4, fontFamily: "monospace", fontSize: 12 }}>INTERVENTIONS</code>{" "}
          table linked to{" "}
          <code style={{ background: COLORS.white, padding: "1px 6px", borderRadius: 4, fontFamily: "monospace", fontSize: 12 }}>RISK_FLAGS</code>.
          Status updates are cached in Redis and invalidated on every PATCH request.
        </div>
      </div>
    </div>
  );
}