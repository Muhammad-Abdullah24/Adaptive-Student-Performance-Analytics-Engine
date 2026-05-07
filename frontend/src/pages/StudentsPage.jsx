import { useState } from "react";
import COLORS from "../data/colors";
import { STUDENTS } from "../data/mockData";
import { Badge } from "../components/UI";

const trendIcon  = (t) => ({ up: "↗", down: "↘", stable: "→" }[t]);
const trendColor = (t) => ({ up: COLORS.emerald, down: COLORS.rose, stable: COLORS.amber }[t]);

export default function StudentsPage() {
  const [search,     setSearch]     = useState("");
  const [filterRisk, setFilterRisk] = useState("all");
  const [selected,   setSelected]   = useState(null);

  const filtered = STUDENTS.filter((s) => {
    const matchSearch = s.name.toLowerCase().includes(search.toLowerCase()) || s.id.includes(search);
    const matchRisk   = filterRisk === "all" || s.risk === filterRisk;
    return matchSearch && matchRisk;
  });

  return (
    <div>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 24 }}>
        <div>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 5 }}>Records</div>
          <h2 style={{ fontSize: 24, fontWeight: 700, color: COLORS.text, margin: 0, letterSpacing: "-0.02em" }}>Student Registry</h2>
        </div>
        <button style={{
          background: COLORS.indigo, color: COLORS.white, border: "none",
          borderRadius: 9, padding: "9px 18px", fontSize: 12, fontWeight: 600, cursor: "pointer", letterSpacing: "0.02em",
        }}>+ Enroll Student</button>
      </div>

      {/* Filters */}
      <div style={{ display: "flex", gap: 12, marginBottom: 20 }}>
        <input
          placeholder="Search by name or ID..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            border: `1px solid ${COLORS.slate200}`, borderRadius: 10, padding: "10px 16px",
            fontSize: 14, flex: 1, outline: "none", background: COLORS.white, color: COLORS.text,
          }}
        />
        {["all", "critical", "high", "medium", "low"].map((r) => (
          <button key={r} onClick={() => setFilterRisk(r)} style={{
            border: `1px solid ${filterRisk === r ? COLORS.indigo : COLORS.slate200}`,
            background: filterRisk === r ? COLORS.indigoLight : COLORS.white,
            color: filterRisk === r ? COLORS.indigo : COLORS.textMuted,
            borderRadius: 8, padding: "8px 14px", fontSize: 13, cursor: "pointer",
            fontWeight: 600, textTransform: "capitalize",
          }}>{r}</button>
        ))}
      </div>

      {/* Table */}
      <div style={{ background: COLORS.white, borderRadius: 18, overflow: "hidden", boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 6px 24px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
          <thead>
            <tr style={{ background: "#F8F9FF", borderBottom: `1px solid rgba(15,23,42,0.06)` }}>
              {["Student ID", "Name", "Dept", "Semester", "CGPA", "Risk Level", "Absences", "Trend", ""].map((h) => (
                <th key={h} style={{ padding: "13px 16px", textAlign: "left", fontWeight: 700, color: COLORS.textMuted, fontSize: 10, letterSpacing: "0.08em", textTransform: "uppercase" }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.map((s, i) => (
              <tr
                key={s.id}
                onClick={() => setSelected(selected?.id === s.id ? null : s)}
                style={{
                  borderTop: `1px solid rgba(15,23,42,0.04)`,
                  background: COLORS.white,
                  cursor: "pointer",
                }}
              >
                <td style={{ padding: "14px 16px", fontWeight: 600, color: COLORS.indigo }}>{s.id}</td>
                <td style={{ padding: "14px 16px", fontWeight: 600, color: COLORS.text }}>{s.name}</td>
                <td style={{ padding: "14px 16px", color: COLORS.textMuted }}>{s.dept}</td>
                <td style={{ padding: "14px 16px", color: COLORS.textMuted }}>{s.semester}</td>
                <td style={{ padding: "14px 16px" }}>
                  <span style={{ fontWeight: 700, fontSize: 15, color: s.cgpa >= 3 ? COLORS.emerald : s.cgpa >= 2 ? COLORS.amber : COLORS.rose }}>
                    {s.cgpa.toFixed(2)}
                  </span>
                </td>
                <td style={{ padding: "14px 16px" }}>
                  <Badge variant={s.risk}>{s.risk.charAt(0).toUpperCase() + s.risk.slice(1)}</Badge>
                </td>
                <td style={{ padding: "14px 16px" }}>
                  <span style={{ color: s.absences > 10 ? COLORS.rose : COLORS.text, fontWeight: s.absences > 10 ? 700 : 400 }}>
                    {s.absences}
                  </span>
                </td>
                <td style={{ padding: "14px 16px" }}>
                  <span style={{ color: trendColor(s.trend), fontWeight: 700, fontSize: 18 }}>{trendIcon(s.trend)}</span>
                </td>
                <td style={{ padding: "14px 16px", color: COLORS.indigo, fontSize: 12, fontWeight: 600 }}>
                  {selected?.id === s.id ? "▲ Close" : "View →"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Detail Panel */}
      {selected && (
        <div style={{ marginTop: 20, background: COLORS.white, borderRadius: 18, padding: 26, boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 8px 30px rgba(79,70,229,0.08)", border: "1px solid rgba(79,70,229,0.15)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 20 }}>
            <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
              <div style={{
                width: 56, height: 56, borderRadius: "50%", background: COLORS.indigoLight,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 20, fontWeight: 700, color: COLORS.indigo,
              }}>
                {selected.name.split(" ").map((n) => n[0]).join("")}
              </div>
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: COLORS.text }}>{selected.name}</div>
                <div style={{ color: COLORS.textMuted, fontSize: 14 }}>{selected.id} · {selected.dept} · Semester {selected.semester}</div>
              </div>
            </div>
            <Badge variant={selected.risk}>{selected.risk.toUpperCase()} RISK</Badge>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16, marginBottom: 16 }}>
            {[
              { label: "CGPA",               val: selected.cgpa.toFixed(2) },
              { label: "Absences",            val: selected.absences        },
              { label: "Department",          val: selected.dept            },
              { label: "Performance Trend",   val: selected.trend.toUpperCase() },
            ].map((m) => (
              <div key={m.label} style={{ background: COLORS.slateLight, borderRadius: 10, padding: "14px 16px" }}>
                <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600, letterSpacing: "0.05em", marginBottom: 6 }}>{m.label}</div>
                <div style={{ fontSize: 20, fontWeight: 700, color: COLORS.text }}>{m.val}</div>
              </div>
            ))}
          </div>

          <div style={{ display: "flex", gap: 12 }}>
            <button style={{
              background: COLORS.indigo, color: COLORS.white, border: "none",
              borderRadius: 8, padding: "10px 20px", fontSize: 13, fontWeight: 600, cursor: "pointer",
            }}>Generate Risk Report (PL/SQL)</button>
            <button style={{
              background: COLORS.roseLight, color: COLORS.roseDark,
              border: `1px solid ${COLORS.rose}`, borderRadius: 8,
              padding: "10px 20px", fontSize: 13, fontWeight: 600, cursor: "pointer",
            }}>Flag for Intervention</button>
          </div>
        </div>
      )}
    </div>
  );
}
