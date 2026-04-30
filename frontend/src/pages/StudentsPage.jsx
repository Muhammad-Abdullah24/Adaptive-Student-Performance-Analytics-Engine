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
          <h2 style={{ fontSize: 22, fontWeight: 700, color: COLORS.text, margin: 0 }}>Student Registry</h2>
          <p style={{ color: COLORS.textMuted, fontSize: 14, margin: "6px 0 0" }}>Performance snapshot with risk classification</p>
        </div>
        <button style={{
          background: COLORS.indigo, color: COLORS.white, border: "none",
          borderRadius: 10, padding: "10px 20px", fontSize: 13, fontWeight: 600, cursor: "pointer",
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
      <div style={{ background: COLORS.white, border: `1px solid ${COLORS.slate200}`, borderRadius: 16, overflow: "hidden" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
          <thead>
            <tr style={{ background: COLORS.slateLight }}>
              {["Student ID", "Name", "Dept", "Semester", "CGPA", "Risk Level", "Absences", "Trend", ""].map((h) => (
                <th key={h} style={{ padding: "12px 16px", textAlign: "left", fontWeight: 600, color: COLORS.textMuted, fontSize: 12, letterSpacing: "0.05em" }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={9} style={{ padding: "32px 16px", textAlign: "center", color: COLORS.textMuted, fontSize: 14 }}>
                  No students match the current filter.
                </td>
              </tr>
            ) : (
            filtered.map((s, i) => (
              <tr
                key={s.id}
                onClick={() => setSelected(selected?.id === s.id ? null : s)}
                style={{
                  borderTop: `1px solid ${COLORS.slate200}`,
                  background: i % 2 === 0 ? COLORS.white : "#FAFAFA",
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
            ))
            )}
          </tbody>
        </table>
      </div>

      {/* Detail Panel */}
      {selected && (
        <div style={{ marginTop: 20, background: COLORS.white, border: `2px solid ${COLORS.indigo}`, borderRadius: 16, padding: 24 }}>
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
