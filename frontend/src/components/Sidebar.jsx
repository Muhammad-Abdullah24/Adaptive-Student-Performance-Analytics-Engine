import { useEffect, useState } from "react";
import COLORS from "../data/colors";

const NAV_ITEMS = [
  { id: "overview",      label: "Overview",       icon: "◉"  },
  { id: "students",      label: "Students",        icon: "👥" },
  { id: "courses",       label: "Courses",         icon: "📚" },
  { id: "analytics",     label: "Analytics",       icon: "📈" },
  { id: "interventions", label: "Interventions",   icon: "🚨" },
  { id: "database",      label: "DB Architecture", icon: "🗄️" },
];

export default function Sidebar({ activePage, setActivePage }) {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const t = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  return (
    <div style={{
      width: 240, background: COLORS.text, display: "flex",
      flexDirection: "column", padding: "24px 0", flexShrink: 0,
      position: "sticky", top: 0, height: "100vh",
    }}>
      {/* Logo */}
      <div style={{ padding: "0 24px 28px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 6 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10, background: COLORS.indigo,
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 18, fontWeight: 700, color: COLORS.white,
          }}>A</div>
          <div>
            <div style={{ color: COLORS.white, fontWeight: 700, fontSize: 14, lineHeight: 1.2 }}>ASPAE</div>
            <div style={{ color: "#94A3B8", fontSize: 10 }}>Analytics Engine</div>
          </div>
        </div>
        <div style={{
          fontSize: 11, color: "#64748B", marginTop: 12,
          background: "#1E293B", borderRadius: 8, padding: "8px 10px",
        }}>
          <div style={{ color: "#22C55E", fontWeight: 600, marginBottom: 2 }}>● LIVE</div>
          <div style={{ color: "#94A3B8" }}>{time.toLocaleTimeString()}</div>
          <div style={{ color: "#64748B" }}>Spring 2026 · NUST-SEECS</div>
        </div>
      </div>

      {/* Nav Links */}
      <div style={{ flex: 1, padding: "0 12px", display: "flex", flexDirection: "column", gap: 2 }}>
        {NAV_ITEMS.map((n) => (
          <button
            key={n.id}
            onClick={() => setActivePage(n.id)}
            style={{
              display: "flex", alignItems: "center", gap: 12,
              padding: "11px 14px", borderRadius: 10, border: "none", cursor: "pointer",
              background: activePage === n.id ? COLORS.indigo : "transparent",
              color: activePage === n.id ? COLORS.white : "#94A3B8",
              fontSize: 14, fontWeight: activePage === n.id ? 700 : 400,
              textAlign: "left", width: "100%",
            }}
          >
            <span style={{ fontSize: 15 }}>{n.icon}</span>
            {n.label}
          </button>
        ))}
      </div>

      {/* User */}
      <div style={{ padding: "16px 24px", borderTop: "1px solid #1E293B", marginTop: 8 }}>
        <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
          <div style={{
            width: 34, height: 34, borderRadius: "50%", background: COLORS.indigo,
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 13, fontWeight: 700, color: COLORS.white,
          }}>MA</div>
          <div>
            <div style={{ color: COLORS.white, fontSize: 13, fontWeight: 600 }}>M. Abdullah</div>
            <div style={{ color: "#64748B", fontSize: 11 }}>Admin · 502895</div>
          </div>
        </div>
      </div>
    </div>
  );
}
