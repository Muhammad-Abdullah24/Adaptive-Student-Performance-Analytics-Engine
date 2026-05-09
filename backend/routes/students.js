const express           = require("express");
const router            = express.Router();
const oracledb          = require("oracledb");
const { getConnection } = require("../db/connection");
const { client, cacheOrFetch } = require("../cache/redisClient");

// GET /api/students
// Returns all students with their department code and open risk flag count
// Cache key includes dept and risk filters so each combination is cached separately
router.get("/", async (req, res) => {
  try {
    const { dept, risk } = req.query;
    const cacheKey = `students:dept:${dept || "all"}:risk:${risk || "all"}`;

    const result = await cacheOrFetch(cacheKey, 60, async () => {
      let conn;
      try {
        conn = await getConnection();

        const conditions = ["1=1"];
        const binds      = {};

        if (dept) { conditions.push("d.dept_code = :dept"); binds.dept = dept.toUpperCase(); }
        if (risk) { conditions.push("s.risk_level = :risk"); binds.risk = risk.toUpperCase(); }

        const sql = `
          SELECT
            s.student_id,
            s.cms_id,
            s.name,
            s.cgpa,
            s.risk_level,
            s.semester,
            d.dept_code,
            COUNT(rf.flag_id) AS open_flags
          FROM STUDENTS s
          JOIN DEPARTMENTS d     ON s.dept_id    = d.dept_id
          LEFT JOIN RISK_FLAGS rf ON s.student_id = rf.student_id
                                  AND rf.is_acknowledged = 'N'
          WHERE ${conditions.join(" AND ")}
          GROUP BY s.student_id, s.cms_id, s.name, s.cgpa, s.risk_level, s.semester, d.dept_code
          ORDER BY
            CASE s.risk_level
              WHEN 'CRITICAL' THEN 1
              WHEN 'HIGH'     THEN 2
              WHEN 'MEDIUM'   THEN 3
              ELSE 4
            END,
            s.cgpa ASC
        `;

        const dbResult = await conn.execute(sql, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        return dbResult.rows;
      } finally {
        if (conn) await conn.close();
      }
    });

    res.json({ success: true, count: result.length, data: result });

  } catch (err) {
    console.error("GET /students error:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/students/:id
// Returns full student detail with topic performance
// Each student gets their own cache entry keyed by ID
router.get("/:id", async (req, res) => {
  try {
    const cacheKey = `student:${req.params.id}`;

    const result = await cacheOrFetch(cacheKey, 120, async () => {
      let conn;
      try {
        conn = await getConnection();

        const studentSql = `
          SELECT s.*, d.dept_code, d.dept_name
          FROM STUDENTS s
          JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
          WHERE s.student_id = :id
        `;

        const topicSql = `
          SELECT t.topic_name, tp.mastery_pct, tp.trend, tp.last_attempt_date
          FROM TOPIC_PERFORMANCE tp
          JOIN TOPICS t ON tp.topic_id = t.topic_id
          WHERE tp.student_id = :id
          ORDER BY tp.mastery_pct ASC
        `;

        const [studentResult, topicResult] = await Promise.all([
          conn.execute(studentSql, { id: req.params.id }, { outFormat: oracledb.OUT_FORMAT_OBJECT }),
          conn.execute(topicSql,   { id: req.params.id }, { outFormat: oracledb.OUT_FORMAT_OBJECT }),
        ]);

        if (!studentResult.rows.length) return null; // signal not found

        return {
          student: studentResult.rows[0],
          topics:  topicResult.rows,
        };
      } finally {
        if (conn) await conn.close();
      }
    });

    if (!result) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    res.json({ success: true, ...result });

  } catch (err) {
    console.error("GET /students/:id error:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/students/enroll
// Calls sp_enroll_student stored procedure
// After a successful enroll, we delete all student list cache entries so the
// next GET /students goes back to Oracle and gets fresh data
router.post("/enroll", async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { studentId, courseId, semesterLabel, section } = req.body;

    const result = await conn.execute(
      `BEGIN
         sp_enroll_student(:studentId, :courseId, :semesterLabel, :section, :outMsg);
       END;`,
      {
        studentId:     studentId,
        courseId:      courseId,
        semesterLabel: semesterLabel,
        section:       section || null,
        outMsg:        { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 },
      }
    );

    await conn.commit();
    const msg = result.outBinds.outMsg;
    const ok  = msg.startsWith("SUCCESS");

    if (ok) {
      // Delete all student list cache entries (they include dept/risk filter combinations)
      // The * pattern finds every key that starts with "students:"
      const keys = await client.keys("students:*");
      if (keys.length > 0) await client.del(...keys);

      // Also delete the specific student's detail cache in case it was already cached
      await client.del(`student:${studentId}`);
    }

    res.status(ok ? 200 : 400).json({ success: ok, message: msg });

  } catch (err) {
    console.error("POST /students/enroll error:", err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;