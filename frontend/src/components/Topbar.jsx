import COLORS from "../data/colors";
import { Badge } from "./UI";

export default function Topbar() {
  return (
    <div style={{
      background: COLORS.white, borderBottom: `1px solid ${COLORS.slate200}`,
      padding: "16px 32px", display: "flex", justifyContent: "space-between",
      alignItems: "center", position: "sticky", top: 0, zIndex: 10,
    }}>
      <div style={{ fontSize: 13, color: COLORS.textMuted }}>
        CS-236 Advanced Database Management Systems · Dr. Ayesha Hakim
      </div>
      <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
        <Badge variant="success">Oracle 21c XE</Badge>
        <Badge variant="info">MySQL 8.0</Badge>
        <Badge variant="default">14 Tables</Badge>
      </div>
    </div>
  );
}
