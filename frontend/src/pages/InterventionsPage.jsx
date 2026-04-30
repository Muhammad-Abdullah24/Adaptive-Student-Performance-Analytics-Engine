import COLORS from "../data/colors";
import { INTERVENTIONS } from "../data/mockData";
import { Badge } from "../components/UI";

export default function InterventionsPage() {
  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 700, color: COLORS.text, margin: 0 }}>Interventions Tracker</h2>
          <p style={{ color: COLORS.textMuted, fontSize: 14, margin: "6px 0 0" }}>Auto-flagged cases from risk triggers + manual entries</p>
        </div>
        <button style={{
          background: COLORS.rose, color: COLORS.white, border: "none",
          borderRadius: 10, padding: "10px 20px", fontSize: 13, fontWeight: 600, cursor: "pointer",
        }}>+ New Intervention</button>
      </div>

      {/* Summary */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 16, marginBottom: 24 }}>
        {[
          { label: "PENDING",     count: 1, color: COLORS.amber  },
          { label: "IN PROGRESS", count: 1, color: COLORS.sky    },
          { label: "COMPLETED",   count: 2, color: COLORS.emerald },
        ].map((s) => (
          <div key={s.label} style={{
            background: s.color + "15", border: `1px solid ${s.color}40`,
            borderRadius: 12, padding: "16px 20px", display: "flex", alignItems: "center", gap: 16,
          }}>
            <div style={{ fontSize: 32, fontWeight: 700, color: s.color }}>{s.count}</div>
            <div style={{ fontSize: 12, fontWeight: 700, color: s.color, letterSpacing: "0.05em" }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Intervention Cards */}
      <div style={{ display: "flex", flexDirection: "column", gap: 12, marginBottom: 24 }}>
        {INTERVENTIONS.map((iv) => (
          <div key={iv.id} style={{
            background: COLORS.white, border: `1px solid ${COLORS.slate200}`,
            borderRadius: 14, padding: "18px 24px",
            display: "flex", justifyContent: "space-between", alignItems: "center",
          }}>
            <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
              <div style={{
                width: 44, height: 44, borderRadius: "50%", background: COLORS.indigoLight,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 16, fontWeight: 700, color: COLORS.indigo,
              }}>
                {iv.student.split(" ").map((n) => n[0]).join("")}
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: 15, color: COLORS.text, marginBottom: 3 }}>{iv.student}</div>
                <div style={{ fontSize: 13, color: COLORS.textMuted }}>{iv.type} · {iv.course}</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
              <div style={{ fontSize: 12, color: COLORS.textMuted }}>{iv.date}</div>
              <Badge variant={iv.status}>{iv.status.replace("_", " ")}</Badge>
              <button style={{
                border: `1px solid ${COLORS.slate200}`, background: COLORS.white,
                color: COLORS.textMuted, borderRadius: 8, padding: "7px 14px",
                fontSize: 12, cursor: "pointer", fontWeight: 600,
              }}>Update</button>
            </div>
          </div>
        ))}
      </div>

      {/* DB Context */}
      <div style={{ background: COLORS.indigoLight, border: `1px solid ${COLORS.indigo}40`, borderRadius: 12, padding: 20 }}>
        <div style={{ fontWeight: 700, fontSize: 14, color: COLORS.indigoDark, marginBottom: 6 }}>
          Database Backend — How This Works
        </div>
        <div style={{ fontSize: 13, color: COLORS.slate, lineHeight: 1.7 }}>
          Each intervention record is stored in the{" "}
          <code style={{ background: COLORS.white, padding: "1px 6px", borderRadius: 4, fontFamily: "monospace", fontSize: 12 }}>INTERVENTIONS</code>{" "}
          table linked to{" "}
          <code style={{ background: COLORS.white, padding: "1px 6px", borderRadius: 4, fontFamily: "monospace", fontSize: 12 }}>RISK_FLAGS</code>.
          When a student's attempt triggers the{" "}
          <code style={{ background: COLORS.white, padding: "1px 6px", borderRadius: 4, fontFamily: "monospace", fontSize: 12 }}>trg_consecutive_fail_flag</code>{" "}
          PL/SQL trigger (3+ consecutive failures), the system auto-inserts a flag row and calls{" "}
          <code style={{ background: COLORS.white, padding: "1px 6px", borderRadius: 4, fontFamily: "monospace", fontSize: 12 }}>sp_generate_risk_report</code>{" "}
          which populates this view via REF CURSOR.
        </div>
      </div>
    </div>
  );
}
