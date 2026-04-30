import { useState } from "react";
import COLORS from "./data/colors";
import Sidebar from "./components/Sidebar";
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
    <div style={{ display: "flex", minHeight: "100vh", background: COLORS.slate100, fontFamily: "'Segoe UI', system-ui, sans-serif" }}>
      <Sidebar activePage={activePage} setActivePage={setActivePage} />
      <div style={{ flex: 1, overflowY: "auto" }}>
        <Topbar />
        <div style={{ padding: 32 }}>
          {PAGES[activePage]}
        </div>
      </div>
    </div>
  );
}
