import { useEffect, useState } from "react";

const NAV = [
  { id: "overview",      label: "Overview"        },
  { id: "students",      label: "Students"        },
  { id: "courses",       label: "Courses"         },
  { id: "analytics",     label: "Analytics"       },
  { id: "interventions", label: "Interventions"   },
  { id: "database",      label: "DB Architecture" },
];

export default function Topbar({ activePage, setActivePage }) {
  const [time, setTime] = useState(new Date());
  useEffect(() => {
    const t = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  return (
    <div style={{
      height: 58, background: "#080F1E",
      display: "flex", alignItems: "center",
      padding: "0 32px", gap: 24, flexShrink: 0,
      position: "sticky", top: 0, zIndex: 100,
      borderBottom: "1px solid rgba(255,255,255,0.06)",
    }}>

      {/* Logo */}
      <div style={{ display: "flex", alignItems: "center", gap: 10, flexShrink: 0 }}>
        <img src="/logo.png" alt="logo" style={{ width: 28, height: 28, borderRadius: 8, objectFit: "cover" }} />
        <div>
          <div style={{ color: "#E2E8F0", fontWeight: 700, fontSize: 13, letterSpacing: "-0.01em", lineHeight: 1.2 }}>Student Analytics</div>
          <div style={{ color: "#1E3A5F", fontSize: 8, letterSpacing: "0.1em", textTransform: "uppercase" }}>Performance Dashboard</div>
        </div>
      </div>

      <div style={{ width: 1, height: 20, background: "rgba(255,255,255,0.08)", flexShrink: 0 }} />

      {/* Nav links */}
      <nav style={{ display: "flex", gap: 2, flex: 1 }}>
        {NAV.map((n) => {
          const active = activePage === n.id;
          return (
            <button
              key={n.id}
              onClick={() => setActivePage && setActivePage(n.id)}
              style={{
                border: "none", cursor: "pointer",
                background: active ? "rgba(99,102,241,0.15)" : "transparent",
                color: active ? "#C7D2FE" : "#475569",
                fontSize: 13, fontWeight: active ? 600 : 400,
                padding: "6px 14px", borderRadius: 8,
                transition: "all 0.12s ease",
              }}
            >{n.label}</button>
          );
        })}
      </nav>

      {/* Right: LIVE clock + user */}
      <div style={{ display: "flex", alignItems: "center", gap: 14, flexShrink: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
          <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#22C55E", display: "inline-block", boxShadow: "0 0 6px rgba(34,197,94,0.7)" }} />
          <span style={{ fontSize: 9, color: "#3D5478", letterSpacing: "0.1em", fontWeight: 700 }}>LIVE</span>
          <span style={{ fontSize: 11, color: "#2D4060", fontFamily: "'JetBrains Mono', monospace", marginLeft: 3 }}>
            {time.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
          </span>
        </div>

        <div style={{ width: 1, height: 20, background: "rgba(255,255,255,0.08)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: 9 }}>
          <div style={{
            width: 28, height: 28, borderRadius: 8,
            background: "linear-gradient(135deg, #4F46E5, #7C3AED)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 11, fontWeight: 700, color: "#fff",
          }}>MA</div>
          <div>
            <div style={{ color: "#94A3B8", fontSize: 12, fontWeight: 600, lineHeight: 1.2 }}>M. Abdullah</div>
            <div style={{ color: "#1E3A5F", fontSize: 8, letterSpacing: "0.07em", textTransform: "uppercase" }}>Admin · 502895</div>
          </div>
        </div>
      </div>
    </div>
  );
}
