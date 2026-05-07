import { useEffect, useState } from "react";

function NavIcon({ id, active }) {
  const stroke = active ? "#A5B4FC" : "#475569";
  const paths = {
    overview:      <><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></>,
    students:      <><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></>,
    courses:       <><path d="M4 19.5A2.5 2.5 0 016.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 014 19.5v-15A2.5 2.5 0 016.5 2z"/></>,
    analytics:     <><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></>,
    interventions: <><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></>,
    database:      <><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/></>,
  };
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      {paths[id]}
    </svg>
  );
}

const NAV = [
  { id: "overview",      label: "Overview"        },
  { id: "students",      label: "Students"        },
  { id: "courses",       label: "Courses"         },
  { id: "analytics",     label: "Analytics"       },
  { id: "interventions", label: "Interventions"   },
  { id: "database",      label: "DB Architecture" },
];

export default function Sidebar({ activePage, setActivePage }) {
  const [time, setTime] = useState(new Date());
  useEffect(() => {
    const t = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  return (
    <div style={{
      width: 240, background: "#080F1E", display: "flex",
      flexDirection: "column", flexShrink: 0,
      position: "sticky", top: 0, height: "100vh",
      borderRight: "1px solid rgba(255,255,255,0.05)",
    }}>

      {/* Logo */}
      <div style={{ padding: "26px 22px 18px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 11 }}>
          <img src="/logo.png" alt="logo" style={{ width: 34, height: 34, borderRadius: 10, objectFit: "cover", flexShrink: 0 }} />
          <div>
            <div style={{ color: "#E2E8F0", fontWeight: 700, fontSize: 13, letterSpacing: "-0.01em" }}>Student Analytics</div>
            <div style={{ color: "#2D3F5C", fontSize: 9, letterSpacing: "0.09em", textTransform: "uppercase", marginTop: 2 }}>Performance Dashboard</div>
          </div>
        </div>

        <div style={{
          marginTop: 14, display: "flex", alignItems: "center", justifyContent: "space-between",
          background: "rgba(255,255,255,0.03)", borderRadius: 9, padding: "7px 11px",
          border: "1px solid rgba(255,255,255,0.05)",
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#22C55E", display: "inline-block", boxShadow: "0 0 6px rgba(34,197,94,0.7)" }} />
            <span style={{ fontSize: 9, color: "#3D5478", letterSpacing: "0.1em", fontWeight: 700 }}>LIVE</span>
          </div>
          <span style={{ fontSize: 10, color: "#2D3F5C", fontFamily: "'JetBrains Mono', monospace" }}>
            {time.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}
          </span>
        </div>
      </div>

      <div style={{ height: 1, background: "rgba(255,255,255,0.04)", margin: "0 18px" }} />

      <div style={{ padding: "12px 22px 6px", fontSize: 9, fontWeight: 700, color: "#1A2D4A", letterSpacing: "0.12em", textTransform: "uppercase" }}>Menu</div>

      <nav style={{ flex: 1, padding: "2px 10px", display: "flex", flexDirection: "column", gap: 1 }}>
        {NAV.map((n) => {
          const active = activePage === n.id;
          return (
            <button
              key={n.id}
              onClick={() => setActivePage(n.id)}
              style={{
                display: "flex", alignItems: "center", gap: 11,
                padding: "9px 12px", borderRadius: 9, border: "none", cursor: "pointer",
                background: active ? "rgba(99,102,241,0.13)" : "transparent",
                borderLeft: `2px solid ${active ? "#6366F1" : "transparent"}`,
                fontSize: 13, textAlign: "left", width: "100%",
                transition: "background 0.12s ease",
              }}
            >
              <NavIcon id={n.id} active={active} />
              <span style={{ color: active ? "#C7D2FE" : "#3D5478", fontWeight: active ? 600 : 400 }}>{n.label}</span>
            </button>
          );
        })}
      </nav>

      <div style={{ height: 1, background: "rgba(255,255,255,0.04)", margin: "0 18px 14px" }} />

      {/* User */}
      <div style={{ padding: "0 12px 22px" }}>
        <div style={{
          display: "flex", gap: 10, alignItems: "center",
          padding: "9px 11px", background: "rgba(255,255,255,0.03)",
          borderRadius: 11, border: "1px solid rgba(255,255,255,0.05)",
        }}>
          <div style={{
            width: 30, height: 30, borderRadius: 8,
            background: "linear-gradient(135deg, #4F46E5, #7C3AED)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 11, fontWeight: 700, color: "#fff", flexShrink: 0,
          }}>MA</div>
          <div>
            <div style={{ color: "#94A3B8", fontSize: 12, fontWeight: 600 }}>M. Abdullah</div>
            <div style={{ color: "#1E3A5F", fontSize: 9, letterSpacing: "0.07em", textTransform: "uppercase", marginTop: 1 }}>Admin · 502895</div>
          </div>
        </div>
      </div>
    </div>
  );
}
