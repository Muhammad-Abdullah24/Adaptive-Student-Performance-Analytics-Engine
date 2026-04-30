const express  = require("express");
const router   = express.Router();
const oracledb = require("oracledb");
const { getConnection } = require("../db/connection");

// GET /api/courses
// Returns all courses with aggregated stats from materialized view
router.get("/", async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const sql = `
      SELECT
        mv.course_id,
        mv.course_code,
        mv.title,
        mv.enrolled_students,
        mv.avg_score,
        mv.pass_rate_pct,
        mv.flagged_students,
        i.name AS instructor_name
      FROM mv_course_summary mv
      JOIN COURSES c     ON mv.course_id    = c.course_id
      LEFT JOIN INSTRUCTORS i ON c.instructor_id = i.instructor_id
      ORDER BY mv.pass_rate_pct ASC
    `;

    const result = await conn.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    res.json({ success: true, data: result.rows });

  } catch (err) {
    console.error("GET /courses error:", err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/courses/:courseCode/students
// Returns all students enrolled in a specific course this semester
router.get("/:courseCode/students", async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const sql = `
      SELECT
        s.cms_id, s.name, s.cgpa, s.risk_level,
        e.section, e.final_grade, e.letter_grade, e.status AS enrollment_status
      FROM ENROLLMENTS e
      JOIN STUDENTS s ON e.student_id = s.student_id
      JOIN COURSES  c ON e.course_id  = c.course_id
      WHERE c.course_code = :code
        AND e.status       = 'ACTIVE'
      ORDER BY s.name
    `;

    const result = await conn.execute(
      sql,
      { code: req.params.courseCode.toUpperCase() },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({ success: true, count: result.rows.length, data: result.rows });

  } catch (err) {
    console.error("GET /courses/:courseCode/students error:", err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
