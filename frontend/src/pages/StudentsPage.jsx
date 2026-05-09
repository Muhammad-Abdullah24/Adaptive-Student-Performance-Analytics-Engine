import { useState, useEffect } from "react";
import COLORS from "../data/colors";
import { Badge } from "../components/UI";

const API = "http://localhost:5000/api";

export default function StudentsPage() {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState("");
  const [filterRisk, setFilterRisk] = useState("all");
  const [filterDept, setFilterDept] = useState("all");
  const [selected, setSelected] = useState(null);

  useEffect(() => {
    const params = new URLSearchParams();
    if (filterRisk !== "all") params.append("risk", filterRisk.toUpperCase());
    if (filterDept !== "all") params.append("dept", filterDept.toUpperCase());

    setLoading(true);
    fetch(`${API}/students?${params}`)
      .then((r) => r.json())
      .then((d) => { setStudents(d.data || []); setLoading(false); })
      .catch(() => { setError("Failed to load students"); setLoading(false); });
  }, [filterRisk, filterDept]);

  const filtered = students.filter((s) => {
    const q = search.toLowerCase();
    return s.NAME?.toLowerCase().includes(q) || s.CMS_ID?.includes(search);
  });

  const depts = ["all", "CS", "EE", "CE", "SE", "AI"];

  return (
    <div>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 24 }}>
        <div>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: COLORS.textMuted, marginBottom: 5 }}>Records</div>
          <h2 style={{ fontSize: 24, fontWeight: 700, color: COLORS.text, margin: 0, letterSpacing: "-0.02em" }}>
            Student Registry <span style={{ fontSize: 14, fontWeight: 400, color: COLORS.textMuted }}>({filtered.length} students)</span>
          </h2>
        </div>
      </div>

      {/* Filters */}
      <div style={{ display: "flex", gap: 12, marginBottom: 12, flexWrap: "wrap" }}>
        <input
          placeholder="Search by name or CMS ID..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ border: `1px solid ${COLORS.slate200}`, borderRadius: 10, padding: "10px 16px", fontSize: 14, flex: 1, minWidth: 200, outline: "none", background: COLORS.white, color: COLORS.text }}
        />
      </div>
      <div style={{ display: "flex", gap: 8, marginBottom: 8, flexWrap: "wrap" }}>
        <span style={{ fontSize: 12, color: COLORS.textMuted, alignSelf: "center" }}>Risk:</span>
        {["all", "critical", "high", "medium", "low"].map((r) => (
          <button key={r} onClick={() => setFilterRisk(r)} style={{
            border: `1px solid ${filterRisk === r ? COLORS.indigo : COLORS.slate200}`,
            background: filterRisk === r ? COLORS.indigoLight : COLORS.white,
            color: filterRisk === r ? COLORS.indigo : COLORS.textMuted,
            borderRadius: 8, padding: "6px 12px", fontSize: 12, cursor: "pointer", fontWeight: 600, textTransform: "capitalize",
          }}>{r}</button>
        ))}
      </div>
      <div style={{ display: "flex", gap: 8, marginBottom: 20, flexWrap: "wrap" }}>
        <span style={{ fontSize: 12, color: COLORS.textMuted, alignSelf: "center" }}>Dept:</span>
        {depts.map((d) => (
          <button key={d} onClick={() => setFilterDept(d)} style={{
            border: `1px solid ${filterDept === d ? COLORS.indigo : COLORS.slate200}`,
            background: filterDept === d ? COLORS.indigoLight : COLORS.white,
            color: filterDept === d ? COLORS.indigo : COLORS.textMuted,
            borderRadius: 8, padding: "6px 12px", fontSize: 12, cursor: "pointer", fontWeight: 600,
          }}>{d}</button>
        ))}
      </div>

      {/* States */}
      {loading && <div style={{ textAlign: "center", padding: 40, color: COLORS.textMuted }}>Loading students...</div>}
      {error && <div style={{ textAlign: "center", padding: 40, color: COLORS.rose }}>{error}</div>}

      {/* Table */}
      {!loading && !error && (
        <div style={{ background: COLORS.white, borderRadius: 18, overflow: "hidden", boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 6px 24px rgba(15,23,42,0.05)", border: "1px solid rgba(15,23,42,0.06)" }}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
            <thead>
              <tr style={{ background: "#F8F9FF", borderBottom: `1px solid rgba(15,23,42,0.06)` }}>
                {["CMS ID", "Name", "Dept", "Semester", "CGPA", "Risk Level", "Open Flags", ""].map((h) => (
                  <th key={h} style={{ padding: "13px 16px", textAlign: "left", fontWeight: 700, color: COLORS.textMuted, fontSize: 10, letterSpacing: "0.08em", textTransform: "uppercase" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((s) => (
                <tr key={s.STUDENT_ID} onClick={() => setSelected(selected?.STUDENT_ID === s.STUDENT_ID ? null : s)}
                  style={{ borderTop: `1px solid rgba(15,23,42,0.04)`, background: COLORS.white, cursor: "pointer" }}>
                  <td style={{ padding: "14px 16px", fontWeight: 600, color: COLORS.indigo }}>{s.CMS_ID}</td>
                  <td style={{ padding: "14px 16px", fontWeight: 600, color: COLORS.text }}>{s.NAME}</td>
                  <td style={{ padding: "14px 16px", color: COLORS.textMuted }}>{s.DEPT_CODE}</td>
                  <td style={{ padding: "14px 16px", color: COLORS.textMuted }}>{s.SEMESTER}</td>
                  <td style={{ padding: "14px 16px" }}>
                    <span style={{ fontWeight: 700, fontSize: 15, color: s.CGPA >= 3 ? COLORS.emerald : s.CGPA >= 2 ? COLORS.amber : COLORS.rose }}>
                      {Number(s.CGPA).toFixed(2)}
                    </span>
                  </td>
                  <td style={{ padding: "14px 16px" }}>
                    <Badge variant={s.RISK_LEVEL?.toLowerCase()}>{s.RISK_LEVEL}</Badge>
                  </td>
                  <td style={{ padding: "14px 16px" }}>
                    <span style={{ color: s.OPEN_FLAGS > 0 ? COLORS.rose : COLORS.text, fontWeight: s.OPEN_FLAGS > 0 ? 700 : 400 }}>
                      {s.OPEN_FLAGS}
                    </span>
                  </td>
                  <td style={{ padding: "14px 16px", color: COLORS.indigo, fontSize: 12, fontWeight: 600 }}>
                    {selected?.STUDENT_ID === s.STUDENT_ID ? "▲ Close" : "View →"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Detail Panel */}
      {selected && (
        <div style={{ marginTop: 20, background: COLORS.white, borderRadius: 18, padding: 26, boxShadow: "0 1px 3px rgba(15,23,42,0.05), 0 8px 30px rgba(79,70,229,0.08)", border: "1px solid rgba(79,70,229,0.15)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 20 }}>
            <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
              <div style={{ width: 56, height: 56, borderRadius: "50%", background: COLORS.indigoLight, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, fontWeight: 700, color: COLORS.indigo }}>
                {selected.NAME?.split(" ").map((n) => n[0]).join("")}
              </div>
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: COLORS.text }}>{selected.NAME}</div>
                <div style={{ color: COLORS.textMuted, fontSize: 14 }}>{selected.CMS_ID} · {selected.DEPT_CODE} · Semester {selected.SEMESTER}</div>
              </div>
            </div>
            <Badge variant={selected.RISK_LEVEL?.toLowerCase()}>{selected.RISK_LEVEL} RISK</Badge>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
            {[
              { label: "CGPA", val: Number(selected.CGPA).toFixed(2) },
              { label: "Open Flags", val: selected.OPEN_FLAGS },
              { label: "Department", val: selected.DEPT_CODE },
              { label: "Semester", val: selected.SEMESTER },
            ].map((m) => (
              <div key={m.label} style={{ background: COLORS.slateLight, borderRadius: 10, padding: "14px 16px" }}>
                <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600, letterSpacing: "0.05em", marginBottom: 6 }}>{m.label}</div>
                <div style={{ fontSize: 20, fontWeight: 700, color: COLORS.text }}>{m.val}</div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}