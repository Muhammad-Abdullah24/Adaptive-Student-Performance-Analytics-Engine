import { useState } from "react";
import Topbar  from "./components/Topbar";

import OverviewPage       from "./pages/OverviewPage";
import StudentsPage       from "./pages/StudentsPage";
import CoursesPage        from "./pages/CoursesPage";
import AnalyticsPage      from "./pages/AnalyticsPage";
import InterventionsPage  from "./pages/InterventionsPage";
import DatabasePage       from "./pages/DatabasePage";

const PAGES = {
  overview:      <OverviewPage      />,
  students:      <StudentsPage      />,
  courses:       <CoursesPage       />,
  analytics:     <AnalyticsPage     />,
  interventions: <InterventionsPage />,
  database:      <DatabasePage      />,
};

export default function App() {
  const [activePage, setActivePage] = useState("overview");

  return (
    <div style={{
      minHeight: "100vh", display: "flex", flexDirection: "column",
      background: "#EDEEF5",
      backgroundImage: "radial-gradient(rgba(15,23,42,0.045) 1px, transparent 1px)",
      backgroundSize: "22px 22px",
      fontFamily: "'Inter', 'Segoe UI', system-ui, sans-serif",
    }}>
      <Topbar activePage={activePage} setActivePage={setActivePage} />
      <div style={{ flex: 1, padding: "28px 32px" }}>
        {PAGES[activePage]}
      </div>
    </div>
  );
}
