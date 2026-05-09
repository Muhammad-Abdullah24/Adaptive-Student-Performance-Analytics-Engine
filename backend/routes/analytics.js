const express           = require("express");
const router            = express.Router();
const oracledb          = require("oracledb");
const { getConnection } = require("../db/connection");
const { cacheOrFetch }  = require("../cache/redisClient");

// GET /api/analytics/risk-report
// Calls sp_generate_risk_report — returns students ordered by severity
// Cache key includes dept and riskLevel query params so different filters get their own cache entry
router.get("/risk-report", async (req, res) => {
  try {
    const { dept, riskLevel } = req.query;
    const cacheKey = `analytics:risk-report:dept:${dept || "all"}:risk:${riskLevel || "all"}`;

    const data = await cacheOrFetch(cacheKey, 60, async () => {
      let conn;
      try {
        conn = await getConnection();

        const result = await conn.execute(
          `BEGIN
             sp_generate_risk_report(:dept, :riskLevel, :cursor);
           END;`,
          {
            dept:      dept      || null,
            riskLevel: riskLevel || null,
            cursor:    { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
          }
        );

        const cursor = result.outBinds.cursor;
        const rows   = await cursor.getRows(100);
        const meta   = cursor.metaData.map((m) => m.name);
        await cursor.close();

        return rows.map((row) =>
          Object.fromEntries(meta.map((col, i) => [col, row[i]]))
        );
      } finally {
        if (conn) await conn.close();
      }
    });

    res.json({ success: true, count: data.length, data });

  } catch (err) {
    console.error("GET /analytics/risk-report error:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/analytics/topic-mastery
// Returns topic-level mastery aggregated across all students
// Cached for 5 minutes — this query is expensive and changes rarely
router.get("/topic-mastery", async (req, res) => {
  try {
    const data = await cacheOrFetch("analytics:topic-mastery", 300, async () => {
      let conn;
      try {
        conn = await getConnection();

        const sql = `
          SELECT
            t.topic_name,
            t.difficulty_level,
            c.course_code,
            ROUND(AVG(tp.mastery_pct), 2)   AS avg_mastery,
            COUNT(tp.student_id)            AS student_count,
            MIN(tp.mastery_pct)             AS min_mastery,
            MAX(tp.mastery_pct)             AS max_mastery
          FROM TOPIC_PERFORMANCE tp
          JOIN TOPICS  t ON tp.topic_id  = t.topic_id
          JOIN COURSES c ON tp.course_id = c.course_id
          GROUP BY t.topic_name, t.difficulty_level, c.course_code
          ORDER BY avg_mastery ASC
        `;

        const result = await conn.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        return result.rows;
      } finally {
        if (conn) await conn.close();
      }
    });

    res.json({ success: true, data });

  } catch (err) {
    console.error("GET /analytics/topic-mastery error:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/analytics/below-dept-avg
// Correlated subquery — students below their department's average CGPA
// Cached for 5 minutes
router.get("/below-dept-avg", async (req, res) => {
  try {
    const data = await cacheOrFetch("analytics:below-dept-avg", 300, async () => {
      let conn;
      try {
        conn = await getConnection();

        const sql = `
          SELECT
            s.cms_id, s.name, s.cgpa, d.dept_code,
            ROUND((SELECT AVG(s2.cgpa) FROM STUDENTS s2 WHERE s2.dept_id = s.dept_id), 2) AS dept_avg,
            ROUND(
              (SELECT AVG(s3.cgpa) FROM STUDENTS s3 WHERE s3.dept_id = s.dept_id) - s.cgpa, 2
            ) AS gap
          FROM STUDENTS s
          JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
          WHERE s.cgpa < (
            SELECT AVG(s4.cgpa) FROM STUDENTS s4 WHERE s4.dept_id = s.dept_id
          )
          ORDER BY gap DESC
        `;

        const result = await conn.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        return result.rows;
      } finally {
        if (conn) await conn.close();
      }
    });

    res.json({ success: true, data });

  } catch (err) {
    console.error("GET /analytics/below-dept-avg error:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/analytics/rolling-avg
// CTE + rolling window — 3-attempt rolling average per student
// Cached for 5 minutes
router.get("/rolling-avg", async (req, res) => {
  try {
    const data = await cacheOrFetch("analytics:rolling-avg", 300, async () => {
      let conn;
      try {
        conn = await getConnection();

        const sql = `
          WITH attempt_history AS (
            SELECT
              s.name, aa.student_id, aa.score, aa.end_time,
              ROW_NUMBER() OVER (
                PARTITION BY aa.student_id ORDER BY aa.end_time DESC
              ) AS rn
            FROM ASSESSMENT_ATTEMPTS aa
            JOIN STUDENTS s ON aa.student_id = s.student_id
            WHERE aa.status = 'GRADED'
          ),
          rolling_avg AS (
            SELECT
              name, student_id, score, end_time, rn,
              ROUND(AVG(score) OVER (
                PARTITION BY student_id
                ORDER BY rn ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
              ), 2) AS rolling_3_avg
            FROM attempt_history
            WHERE rn <= 10
          )
          SELECT * FROM rolling_avg ORDER BY student_id, rn
        `;

        const result = await conn.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        return result.rows;
      } finally {
        if (conn) await conn.close();
      }
    });

    res.json({ success: true, data });

  } catch (err) {
    console.error("GET /analytics/rolling-avg error:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;