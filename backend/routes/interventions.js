const express  = require("express");
const router   = express.Router();
const oracledb = require("oracledb");
const { getConnection } = require("../db/connection");

// GET /api/interventions
// Returns all interventions with student name and linked flag info
router.get("/", async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const sql = `
      SELECT
        iv.intervention_id,
        s.name           AS student_name,
        s.cms_id,
        iv.int_type,
        iv.status,
        iv.assigned_date,
        iv.due_date,
        c.course_code,
        rf.flag_type,
        rf.severity
      FROM INTERVENTIONS iv
      JOIN STUDENTS  s  ON iv.student_id = s.student_id
      JOIN RISK_FLAGS rf ON iv.flag_id   = rf.flag_id
      LEFT JOIN COURSES c ON rf.course_id = c.course_id
      ORDER BY
        CASE iv.status
          WHEN 'PENDING'     THEN 1
          WHEN 'IN_PROGRESS' THEN 2
          WHEN 'COMPLETED'   THEN 3
          ELSE 4
        END,
        iv.assigned_date DESC
    `;

    const result = await conn.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    res.json({ success: true, data: result.rows });

  } catch (err) {
    console.error("GET /interventions error:", err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/interventions
// Creates a new intervention manually (calls sp_assign_intervention)
router.post("/", async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { flagId, studentId, instructorId, intType, description, dueDate } = req.body;

    await conn.execute(
      `INSERT INTO INTERVENTIONS (flag_id, student_id, instructor_id, int_type, description, due_date)
       VALUES (:flagId, :studentId, :instructorId, :intType, :description, TO_DATE(:dueDate, 'YYYY-MM-DD'))`,
      { flagId, studentId, instructorId, intType, description, dueDate }
    );
    await conn.commit();

    res.json({ success: true, message: "Intervention created." });

  } catch (err) {
    console.error("POST /interventions error:", err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/interventions/:id/status
// Updates intervention status
router.patch("/:id/status", async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { status, outcomeNotes } = req.body;

    const validStatuses = ["PENDING", "IN_PROGRESS", "COMPLETED", "CANCELLED"];
    if (!validStatuses.includes(status.toUpperCase())) {
      return res.status(400).json({ success: false, message: "Invalid status value." });
    }

    await conn.execute(
      `UPDATE INTERVENTIONS
       SET status = :status,
           outcome_notes = :notes,
           closed_at = CASE WHEN :status IN ('COMPLETED','CANCELLED') THEN SYSDATE ELSE NULL END
       WHERE intervention_id = :id`,
      { status: status.toUpperCase(), notes: outcomeNotes || null, id: req.params.id }
    );
    await conn.commit();

    res.json({ success: true, message: "Status updated." });

  } catch (err) {
    console.error("PATCH /interventions/:id/status error:", err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
