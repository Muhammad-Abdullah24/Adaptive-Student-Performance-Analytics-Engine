import COLORS from "../data/colors";
import { COURSES } from "../data/mockData";
import { MiniBar } from "../components/UI";

export default function CoursesPage() {
  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: COLORS.text, margin: 0 }}>Course Analytics</h2>
        <p style={{ color: COLORS.textMuted, fontSize: 14, margin: "6px 0 0" }}>Instructor view — Pass rates, averages, and enrollment</p>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {COURSES.map((c) => (
          <div key={c.id} style={{
            background: COLORS.white, border: `1px solid ${COLORS.slate200}`,
            borderRadius: 16, padding: 24,
            display: "grid", gridTemplateColumns: "1fr auto", gap: 20, alignItems: "center",
          }}>
            <div>
              <div style={{ display: "flex", gap: 12, alignItems: "center", marginBottom: 8 }}>
                <span style={{
                  background: COLORS.indigoLight, color: COLORS.indigo,
                  padding: "3px 10px", borderRadius: 6, fontSize: 12, fontWeight: 700,
                }}>{c.id}</span>
                <span style={{ fontSize: 16, fontWeight: 700, color: COLORS.text }}>{c.name}</span>
              </div>
              <div style={{ fontSize: 13, color: COLORS.textMuted, marginBottom: 14 }}>
                {c.instructor} · {c.students} students enrolled
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, maxWidth: 400 }}>
                <div>
                  <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600, marginBottom: 4 }}>CLASS AVERAGE</div>
                  <div style={{ fontSize: 18, fontWeight: 700, color: COLORS.text, marginBottom: 6 }}>{c.avg}%</div>
                  <MiniBar value={c.avg} height={5} />
                </div>
                <div>
                  <div style={{ fontSize: 11, color: COLORS.textMuted, fontWeight: 600, marginBottom: 4 }}>PASS RATE</div>
                  <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 6, color: c.passRate >= 80 ? COLORS.emerald : c.passRate >= 70 ? COLORS.amber : COLORS.rose }}>
                    {c.passRate}%
                  </div>
                  <MiniBar value={c.passRate} color={COLORS.emerald} height={5} />
                </div>
              </div>
            </div>

            {/* Pass Rate Donut */}
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
              <div style={{
                width: 80, height: 80, borderRadius: "50%",
                background: `conic-gradient(${COLORS.emerald} ${c.passRate * 3.6}deg, ${COLORS.slate200} 0deg)`,
                display: "flex", alignItems: "center", justifyContent: "center",
              }}>
                <div style={{
                  width: 58, height: 58, borderRadius: "50%", background: COLORS.white,
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 14, fontWeight: 700, color: COLORS.text,
                }}>{c.passRate}%</div>
              </div>
              <div style={{ fontSize: 11, color: COLORS.textMuted }}>Pass Rate</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
