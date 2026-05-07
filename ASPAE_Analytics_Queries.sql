-- ============================================================
-- ASPAE_Analytics_Queries.sql | Oracle 21c XE — Advanced Analytics
-- CS-236 ADBMS · NUST SEECS · Spring 2026
-- M. Abdullah (502895) · M. Umer Farooq (508162)
-- Run after ASPAE_Oracle_Schema.sql (seed data must be present).
-- Each query is annotated with the Oracle/SQL feature it demonstrates.
-- ============================================================

-- ============================================================
-- CATEGORY A: WINDOW FUNCTIONS
-- ============================================================

-- A1: RANK() — Top 3 students per course by average score
-- Demonstrates: RANK() OVER (PARTITION BY ... ORDER BY ...)
-- ---------------------------------------------------------------
SELECT * FROM (
  SELECT
    s.cms_id,
    s.name                                                          AS student_name,
    c.course_code,
    ROUND(AVG(aa.score), 2)                                         AS avg_score,
    RANK() OVER (PARTITION BY c.course_id ORDER BY AVG(aa.score) DESC) AS course_rank,
    ROUND(AVG(AVG(aa.score)) OVER (PARTITION BY c.course_id), 2)    AS course_avg
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN STUDENTS    s ON aa.student_id    = s.student_id
  JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
  JOIN COURSES     c ON a.course_id      = c.course_id
  WHERE aa.status = 'GRADED'
  GROUP BY s.student_id, s.cms_id, s.name, c.course_id, c.course_code
)
WHERE course_rank <= 3
ORDER BY course_code, course_rank;

-- A2: DENSE_RANK() + NTILE() — Student quartile placement per dept
-- Demonstrates: DENSE_RANK(), NTILE(4), multiple window functions
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  d.dept_code,
  s.cgpa,
  DENSE_RANK() OVER (PARTITION BY d.dept_id ORDER BY s.cgpa DESC)  AS dept_rank,
  NTILE(4)     OVER (PARTITION BY d.dept_id ORDER BY s.cgpa DESC)  AS quartile,
  ROUND(AVG(s.cgpa) OVER (PARTITION BY d.dept_id), 2)              AS dept_avg_cgpa,
  ROUND(MAX(s.cgpa) OVER (PARTITION BY d.dept_id), 2)              AS dept_max_cgpa,
  ROUND(MIN(s.cgpa) OVER (PARTITION BY d.dept_id), 2)              AS dept_min_cgpa
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
ORDER BY d.dept_code, dept_rank;

-- A3: LAG() / LEAD() — Detect CGPA improvement or regression
-- Demonstrates: LAG(), LEAD(), per-row comparison
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  s.cgpa                                                            AS current_cgpa,
  LAG(s.cgpa, 1) OVER (PARTITION BY s.dept_id ORDER BY s.student_id) AS prev_student_cgpa,
  LEAD(s.cgpa,1) OVER (PARTITION BY s.dept_id ORDER BY s.student_id) AS next_student_cgpa,
  ROUND(s.cgpa - LAG(s.cgpa,1) OVER
        (PARTITION BY s.dept_id ORDER BY s.student_id), 2)         AS delta_vs_prev,
  CASE
    WHEN s.cgpa > LAG(s.cgpa,1) OVER
         (PARTITION BY s.dept_id ORDER BY s.student_id) THEN 'IMPROVED'
    WHEN s.cgpa < LAG(s.cgpa,1) OVER
         (PARTITION BY s.dept_id ORDER BY s.student_id) THEN 'DECLINED'
    ELSE 'SAME'
  END                                                               AS trend_vs_prev
FROM STUDENTS s
ORDER BY s.dept_id, s.student_id;

-- A4: Rolling 3-attempt average per student
-- Demonstrates: AVG() OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
-- ---------------------------------------------------------------
SELECT
  s.name,
  aa.student_id,
  a.title                                                            AS assessment,
  aa.score,
  aa.end_time,
  ROW_NUMBER() OVER (PARTITION BY aa.student_id ORDER BY aa.end_time DESC) AS rn,
  ROUND(AVG(aa.score) OVER (
    PARTITION BY aa.student_id
    ORDER BY aa.end_time DESC
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 2)                                                              AS rolling_3_avg,
  ROUND(AVG(aa.score) OVER (
    PARTITION BY aa.student_id
    ORDER BY aa.end_time DESC
    ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
  ), 2)                                                              AS rolling_5_avg
FROM ASSESSMENT_ATTEMPTS aa
JOIN STUDENTS    s ON aa.student_id    = s.student_id
JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
WHERE aa.status = 'GRADED'
ORDER BY aa.student_id, aa.end_time DESC;

-- A5: Cumulative pass count per student over time (running total)
-- Demonstrates: SUM() OVER (... ORDER BY ... ROWS UNBOUNDED PRECEDING)
-- ---------------------------------------------------------------
SELECT
  s.name,
  aa.student_id,
  a.title,
  aa.score,
  a.passing_marks,
  CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END           AS passed,
  SUM(CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END) OVER (
    PARTITION BY aa.student_id
    ORDER BY aa.end_time
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )                                                                   AS cumulative_passes,
  SUM(CASE WHEN aa.score < a.passing_marks THEN 1 ELSE 0 END) OVER (
    PARTITION BY aa.student_id
    ORDER BY aa.end_time
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )                                                                   AS cumulative_fails
FROM ASSESSMENT_ATTEMPTS aa
JOIN STUDENTS    s ON aa.student_id    = s.student_id
JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
WHERE aa.status = 'GRADED'
ORDER BY aa.student_id, aa.end_time;

-- A6: PERCENT_RANK() and CUME_DIST() — Score distribution per course
-- Demonstrates: PERCENT_RANK(), CUME_DIST() window functions
-- ---------------------------------------------------------------
SELECT
  s.name,
  c.course_code,
  aa.score,
  ROUND(PERCENT_RANK() OVER (PARTITION BY c.course_id ORDER BY aa.score), 4) AS percentile_rank,
  ROUND(CUME_DIST()    OVER (PARTITION BY c.course_id ORDER BY aa.score), 4) AS cumulative_dist,
  CASE
    WHEN PERCENT_RANK() OVER (PARTITION BY c.course_id ORDER BY aa.score DESC) <= 0.1
    THEN 'Top 10%'
    WHEN PERCENT_RANK() OVER (PARTITION BY c.course_id ORDER BY aa.score DESC) <= 0.25
    THEN 'Top 25%'
    ELSE 'General'
  END                                                                         AS performance_tier
FROM ASSESSMENT_ATTEMPTS aa
JOIN STUDENTS    s ON aa.student_id    = s.student_id
JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
JOIN COURSES     c ON a.course_id      = c.course_id
WHERE aa.status = 'GRADED'
ORDER BY c.course_code, percentile_rank DESC;

-- ============================================================
-- CATEGORY B: CTEs (Common Table Expressions)
-- ============================================================

-- B1: Simple CTE — Students with unresolved critical flags
-- Demonstrates: WITH clause, single-level CTE
-- ---------------------------------------------------------------
WITH critical_flags AS (
  SELECT
    rf.flag_id,
    rf.student_id,
    rf.course_id,
    rf.flag_type,
    rf.severity,
    rf.description,
    rf.created_at
  FROM RISK_FLAGS rf
  WHERE rf.severity IN ('CRITICAL','HIGH')
    AND rf.resolved  = 'N'
)
SELECT
  s.cms_id,
  s.name,
  d.dept_code,
  cf.flag_type,
  cf.severity,
  cf.description,
  cf.created_at,
  c.course_code
FROM critical_flags cf
JOIN STUDENTS    s ON cf.student_id = s.student_id
JOIN DEPARTMENTS d ON s.dept_id     = d.dept_id
LEFT JOIN COURSES c ON cf.course_id = c.course_id
ORDER BY CASE cf.severity WHEN 'CRITICAL' THEN 1 ELSE 2 END, cf.created_at;

-- B2: Multi-CTE — Risk pipeline with rolling average & threshold breach
-- Demonstrates: Chained CTEs, reuse of CTE output in subsequent CTE
-- ---------------------------------------------------------------
WITH attempt_history AS (
  -- Step 1: ordered attempt history with row number
  SELECT
    aa.student_id,
    aa.score,
    a.passing_marks,
    a.course_id,
    aa.end_time,
    ROW_NUMBER() OVER (
      PARTITION BY aa.student_id, a.course_id
      ORDER BY aa.end_time DESC
    ) AS rn
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
  WHERE aa.status = 'GRADED'
),
rolling_avg AS (
  -- Step 2: compute 3-attempt rolling average
  SELECT
    student_id,
    course_id,
    score,
    end_time,
    rn,
    ROUND(AVG(score) OVER (
      PARTITION BY student_id, course_id
      ORDER BY rn
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_avg_3
  FROM attempt_history
  WHERE rn <= 10
),
breach_students AS (
  -- Step 3: identify students whose rolling avg is below passing threshold
  SELECT DISTINCT student_id, course_id
  FROM rolling_avg ra
  JOIN ASSESSMENTS a ON ra.course_id = a.course_id
  WHERE ra.rolling_avg_3 < (
    SELECT AVG(a2.passing_marks) FROM ASSESSMENTS a2 WHERE a2.course_id = ra.course_id
  )
)
SELECT
  s.cms_id,
  s.name,
  s.risk_level,
  c.course_code,
  ra.rolling_avg_3,
  ra.end_time                        AS last_attempt
FROM breach_students bs
JOIN rolling_avg ra ON bs.student_id = ra.student_id AND bs.course_id = ra.course_id AND ra.rn = 1
JOIN STUDENTS s     ON bs.student_id = s.student_id
JOIN COURSES  c     ON bs.course_id  = c.course_id
ORDER BY ra.rolling_avg_3;

-- B3: Recursive CTE — Simulated semester progression (1 → 8)
-- Demonstrates: CONNECT BY or recursive WITH for hierarchical data
-- ---------------------------------------------------------------
WITH sem_ladder(sem_level, label) AS (
  SELECT 1, 'Freshman Year - Semester 1' FROM DUAL
  UNION ALL
  SELECT sem_level + 1,
    CASE sem_level + 1
      WHEN 2 THEN 'Freshman Year - Semester 2'
      WHEN 3 THEN 'Sophomore Year - Semester 3'
      WHEN 4 THEN 'Sophomore Year - Semester 4'
      WHEN 5 THEN 'Junior Year - Semester 5'
      WHEN 6 THEN 'Junior Year - Semester 6'
      WHEN 7 THEN 'Senior Year - Semester 7'
      WHEN 8 THEN 'Senior Year - Semester 8'
      ELSE 'Unknown'
    END
  FROM sem_ladder
  WHERE sem_level < 8
)
SELECT
  sl.sem_level,
  sl.label,
  COUNT(s.student_id)             AS students_in_sem,
  ROUND(AVG(s.cgpa), 2)           AS avg_cgpa,
  COUNT(CASE WHEN s.risk_level IN ('HIGH','CRITICAL') THEN 1 END) AS at_risk
FROM sem_ladder sl
LEFT JOIN STUDENTS s ON s.semester = sl.sem_level
GROUP BY sl.sem_level, sl.label
ORDER BY sl.sem_level;

-- ============================================================
-- CATEGORY C: CORRELATED SUBQUERIES
-- ============================================================

-- C1: Students below their department CGPA average
-- Demonstrates: correlated subquery in WHERE clause
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  s.cgpa,
  d.dept_code,
  ROUND((SELECT AVG(s2.cgpa) FROM STUDENTS s2
         WHERE  s2.dept_id = s.dept_id), 2)          AS dept_avg,
  ROUND((SELECT AVG(s3.cgpa) FROM STUDENTS s3
         WHERE  s3.dept_id = s.dept_id) - s.cgpa, 2) AS gap
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
WHERE s.cgpa < (
  SELECT AVG(s4.cgpa) FROM STUDENTS s4 WHERE s4.dept_id = s.dept_id
)
ORDER BY gap DESC;

-- C2: Courses where class average is below university average
-- Demonstrates: correlated subquery vs aggregate scalar subquery
-- ---------------------------------------------------------------
SELECT
  c.course_code,
  c.title,
  ROUND((SELECT AVG(aa2.score)
         FROM   ASSESSMENT_ATTEMPTS aa2
         JOIN   ASSESSMENTS a2 ON aa2.assessment_id = a2.assessment_id
         WHERE  a2.course_id = c.course_id
           AND  aa2.status   = 'GRADED'), 2)          AS course_avg,
  ROUND((SELECT AVG(aa3.score) FROM ASSESSMENT_ATTEMPTS aa3
         WHERE aa3.status = 'GRADED'), 2)             AS university_avg,
  ROUND((SELECT AVG(aa3.score) FROM ASSESSMENT_ATTEMPTS aa3 WHERE aa3.status = 'GRADED')
       -(SELECT AVG(aa2.score) FROM ASSESSMENT_ATTEMPTS aa2
         JOIN   ASSESSMENTS a2 ON aa2.assessment_id = a2.assessment_id
         WHERE  a2.course_id = c.course_id AND aa2.status = 'GRADED'), 2) AS deficit
FROM COURSES c
WHERE (SELECT AVG(aa4.score)
       FROM   ASSESSMENT_ATTEMPTS aa4
       JOIN   ASSESSMENTS a4 ON aa4.assessment_id = a4.assessment_id
       WHERE  a4.course_id = c.course_id AND aa4.status = 'GRADED')
    < (SELECT AVG(aa5.score) FROM ASSESSMENT_ATTEMPTS aa5 WHERE aa5.status = 'GRADED')
ORDER BY deficit DESC;

-- C3: At-risk students with NO active intervention — NOT EXISTS
-- Demonstrates: NOT EXISTS correlated subquery
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  s.cgpa,
  s.risk_level,
  d.dept_code,
  (SELECT COUNT(*) FROM RISK_FLAGS rf
   WHERE  rf.student_id = s.student_id AND rf.resolved = 'N') AS open_flags
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
WHERE s.risk_level IN ('HIGH','CRITICAL')
  AND NOT EXISTS (
    SELECT 1 FROM INTERVENTIONS iv
    WHERE  iv.student_id = s.student_id
      AND  iv.status NOT IN ('CANCELLED','COMPLETED')
  )
ORDER BY CASE s.risk_level WHEN 'CRITICAL' THEN 1 ELSE 2 END, s.cgpa;

-- C4: Topics with mastery below the topic's own course average
-- Demonstrates: correlated scalar subquery in SELECT + WHERE
-- ---------------------------------------------------------------
SELECT
  tp.student_id,
  s.name,
  t.topic_name,
  t.difficulty_level,
  c.course_code,
  tp.mastery_pct,
  ROUND((SELECT AVG(tp2.mastery_pct)
         FROM   TOPIC_PERFORMANCE tp2
         WHERE  tp2.topic_id = tp.topic_id), 2)          AS topic_avg_mastery,
  ROUND((SELECT AVG(tp2.mastery_pct) FROM TOPIC_PERFORMANCE tp2
         WHERE  tp2.topic_id = tp.topic_id) - tp.mastery_pct, 2) AS gap
FROM TOPIC_PERFORMANCE tp
JOIN STUDENTS s ON tp.student_id = s.student_id
JOIN TOPICS   t ON tp.topic_id   = t.topic_id
JOIN COURSES  c ON tp.course_id  = c.course_id
WHERE tp.mastery_pct < (
  SELECT AVG(tp3.mastery_pct) FROM TOPIC_PERFORMANCE tp3
  WHERE  tp3.topic_id = tp.topic_id
)
ORDER BY gap DESC;

-- C5: Students who have attempted EVERY assessment in their enrolled courses
-- Demonstrates: NOT EXISTS double negation (relational division)
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  c.course_code
FROM STUDENTS s
JOIN ENROLLMENTS e ON s.student_id = e.student_id AND e.status = 'ACTIVE'
JOIN COURSES c     ON e.course_id  = c.course_id
WHERE NOT EXISTS (
  SELECT 1 FROM ASSESSMENTS a
  WHERE  a.course_id = c.course_id
    AND  a.is_published = 1
    AND  NOT EXISTS (
      SELECT 1 FROM ASSESSMENT_ATTEMPTS aa
      WHERE  aa.student_id    = s.student_id
        AND  aa.assessment_id = a.assessment_id
        AND  aa.status        = 'GRADED'
    )
)
ORDER BY c.course_code, s.name;

-- ============================================================
-- CATEGORY D: JOINS & SET OPERATIONS
-- ============================================================

-- D1: Multi-table JOIN — Full student performance profile
-- Demonstrates: 5-table JOIN with aggregation
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  d.dept_code,
  i.name                                     AS instructor,
  c.course_code,
  e.section,
  COUNT(aa.attempt_id)                       AS attempts,
  ROUND(AVG(aa.score), 2)                    AS avg_score,
  ROUND(MAX(aa.score), 2)                    AS best,
  SUM(CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END) AS passes,
  s.risk_level
FROM STUDENTS s
JOIN DEPARTMENTS d   ON s.dept_id       = d.dept_id
JOIN ENROLLMENTS e   ON s.student_id    = e.student_id  AND e.status = 'ACTIVE'
JOIN COURSES     c   ON e.course_id     = c.course_id
JOIN INSTRUCTORS i   ON c.instructor_id = i.instructor_id
LEFT JOIN ASSESSMENT_ATTEMPTS aa ON aa.student_id    = s.student_id AND aa.status = 'GRADED'
LEFT JOIN ASSESSMENTS         a  ON aa.assessment_id = a.assessment_id AND a.course_id = c.course_id
GROUP BY s.student_id, s.cms_id, s.name, d.dept_code, i.name, c.course_code, e.section, s.risk_level
ORDER BY d.dept_code, avg_score DESC NULLS LAST;

-- D2: SELF JOIN — Students in the same department with risk disparity
-- Demonstrates: self-join to compare tuples in same relation
-- ---------------------------------------------------------------
SELECT
  s1.cms_id                         AS student_a,
  s1.name                           AS name_a,
  s1.cgpa                           AS cgpa_a,
  s2.cms_id                         AS student_b,
  s2.name                           AS name_b,
  s2.cgpa                           AS cgpa_b,
  ROUND(ABS(s1.cgpa - s2.cgpa), 2)  AS cgpa_gap,
  d.dept_code
FROM STUDENTS s1
JOIN STUDENTS    s2 ON s1.dept_id = s2.dept_id AND s1.student_id < s2.student_id
JOIN DEPARTMENTS d  ON s1.dept_id = d.dept_id
WHERE s1.risk_level IN ('HIGH','CRITICAL')
  AND s2.risk_level = 'LOW'
  AND ABS(s1.cgpa - s2.cgpa) > 1.5
ORDER BY cgpa_gap DESC;

-- D3: OUTER JOIN — Courses with no high-risk enrollments (LEFT JOIN + NULL check)
-- Demonstrates: LEFT OUTER JOIN with IS NULL filter
-- ---------------------------------------------------------------
SELECT
  c.course_code,
  c.title,
  i.name                AS instructor,
  COUNT(e.enrollment_id) AS total_enrolled
FROM COURSES c
JOIN INSTRUCTORS i ON c.instructor_id = i.instructor_id
LEFT JOIN ENROLLMENTS e ON c.course_id  = e.course_id AND e.status = 'ACTIVE'
LEFT JOIN STUDENTS    s ON e.student_id = s.student_id
                       AND s.risk_level IN ('HIGH','CRITICAL')
WHERE s.student_id IS NULL
GROUP BY c.course_id, c.course_code, c.title, i.name
ORDER BY c.course_code;

-- D4: UNION — Combined risk event feed (flags + session absences)
-- Demonstrates: UNION ALL with column aliasing and ORDER BY
-- ---------------------------------------------------------------
SELECT
  'RISK_FLAG'                         AS event_source,
  s.name                              AS student_name,
  rf.flag_type                        AS event_detail,
  rf.severity,
  TO_CHAR(rf.created_at,'DD-Mon-YYYY HH24:MI') AS event_time
FROM RISK_FLAGS rf
JOIN STUDENTS s ON rf.student_id = s.student_id
UNION ALL
SELECT
  'ABSENCE',
  s.name,
  'Absent — ' || NVL(c.course_code, 'General'),
  'N/A',
  TO_CHAR(sl.logged_at,'DD-Mon-YYYY HH24:MI')
FROM SESSION_LOGS sl
JOIN STUDENTS s          ON sl.student_id = s.student_id
LEFT JOIN COURSES c      ON sl.course_id  = c.course_id
WHERE sl.event_type = 'ABSENCE'
ORDER BY event_time DESC
FETCH FIRST 25 ROWS ONLY;

-- D5: INTERSECT — Students enrolled in both CS-236 AND CS-301
-- Demonstrates: INTERSECT set operator
-- ---------------------------------------------------------------
SELECT s.cms_id, s.name, s.risk_level
FROM   STUDENTS s
JOIN   ENROLLMENTS e ON s.student_id = e.student_id
JOIN   COURSES     c ON e.course_id  = c.course_id AND c.course_code = 'CS-236'
INTERSECT
SELECT s.cms_id, s.name, s.risk_level
FROM   STUDENTS s
JOIN   ENROLLMENTS e ON s.student_id = e.student_id
JOIN   COURSES     c ON e.course_id  = c.course_id AND c.course_code = 'CS-301';

-- D6: MINUS — Students in CS-236 NOT in CS-301
-- Demonstrates: MINUS (Oracle set operator, equivalent to EXCEPT)
-- ---------------------------------------------------------------
SELECT s.cms_id, s.name, s.risk_level
FROM   STUDENTS s
JOIN   ENROLLMENTS e ON s.student_id = e.student_id
JOIN   COURSES     c ON e.course_id  = c.course_id AND c.course_code = 'CS-236'
MINUS
SELECT s.cms_id, s.name, s.risk_level
FROM   STUDENTS s
JOIN   ENROLLMENTS e ON s.student_id = e.student_id
JOIN   COURSES     c ON e.course_id  = c.course_id AND c.course_code = 'CS-301';

-- ============================================================
-- CATEGORY E: AGGREGATION & GROUPING EXTENSIONS
-- ============================================================

-- E1: GROUP BY ROLLUP — Risk distribution with subtotals
-- Demonstrates: ROLLUP for hierarchical aggregation
-- ---------------------------------------------------------------
SELECT
  NVL(d.dept_code, 'ALL DEPTS')              AS dept_code,
  NVL(s.risk_level, 'ALL LEVELS')            AS risk_level,
  COUNT(s.student_id)                        AS student_count,
  ROUND(AVG(s.cgpa), 2)                      AS avg_cgpa
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
GROUP BY ROLLUP(d.dept_code, s.risk_level)
ORDER BY d.dept_code NULLS LAST, s.risk_level NULLS LAST;

-- E2: GROUP BY CUBE — Full cross-tab of dept × risk × semester
-- Demonstrates: CUBE for all combinations of grouping
-- ---------------------------------------------------------------
SELECT
  NVL(d.dept_code,    'ALL')          AS dept_code,
  NVL(s.risk_level,   'ALL')          AS risk_level,
  NVL(TO_CHAR(s.semester), 'ALL')     AS semester,
  COUNT(*)                            AS students,
  ROUND(AVG(s.cgpa), 2)               AS avg_cgpa
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
GROUP BY CUBE(d.dept_code, s.risk_level, s.semester)
ORDER BY 1 NULLS LAST, 2 NULLS LAST, 3 NULLS LAST;

-- E3: GROUPING SETS — Custom aggregation groupings
-- Demonstrates: GROUPING SETS for selective subtotals
-- ---------------------------------------------------------------
SELECT
  NVL(d.dept_code,  '—')     AS dept_code,
  NVL(c.course_code,'—')     AS course_code,
  NVL(s.risk_level, '—')     AS risk_level,
  COUNT(DISTINCT s.student_id) AS students,
  ROUND(AVG(s.cgpa), 2)        AS avg_cgpa,
  GROUPING(d.dept_code)        AS is_dept_total,
  GROUPING(c.course_code)      AS is_course_total,
  GROUPING(s.risk_level)       AS is_risk_total
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id  = d.dept_id
JOIN ENROLLMENTS e ON s.student_id = e.student_id AND e.status = 'ACTIVE'
JOIN COURSES     c ON e.course_id  = c.course_id
GROUP BY GROUPING SETS (
  (d.dept_code, c.course_code),
  (d.dept_code, s.risk_level),
  (c.course_code),
  ()
)
ORDER BY is_dept_total, is_course_total, is_risk_total, d.dept_code NULLS LAST;

-- E4: HAVING with correlated condition — Courses with pass rate below 75%
-- Demonstrates: HAVING clause with aggregated threshold filter
-- ---------------------------------------------------------------
SELECT
  c.course_code,
  c.title,
  COUNT(aa.attempt_id)                                              AS total_attempts,
  SUM(CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END)     AS passed,
  SUM(CASE WHEN aa.score <  a.passing_marks THEN 1 ELSE 0 END)     AS failed,
  ROUND(100 * SUM(CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END)
           / NULLIF(COUNT(aa.attempt_id), 0), 2)                   AS pass_rate_pct
FROM COURSES c
JOIN ASSESSMENTS         a  ON a.course_id      = c.course_id
JOIN ASSESSMENT_ATTEMPTS aa ON aa.assessment_id  = a.assessment_id AND aa.status = 'GRADED'
GROUP BY c.course_id, c.course_code, c.title
HAVING ROUND(100 * SUM(CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END)
                  / NULLIF(COUNT(aa.attempt_id), 0), 2) < 75
ORDER BY pass_rate_pct ASC;

-- ============================================================
-- CATEGORY F: MATERIALIZED VIEW & INLINE VIEW QUERIES
-- ============================================================

-- F1: Query against MV_COURSE_SUMMARY (materialized view)
-- Demonstrates: Fast read from pre-aggregated Oracle MV
-- ---------------------------------------------------------------
SELECT
  course_code,
  course_title,
  dept_code,
  instructor_name,
  enrolled_students,
  avg_score,
  pass_rate_pct,
  high_risk_students
FROM MV_COURSE_SUMMARY
ORDER BY pass_rate_pct ASC;

-- F2: Inline view — Identify top and bottom courses by average
-- Demonstrates: Inline view (subquery in FROM clause) as derived table
-- ---------------------------------------------------------------
SELECT
  tier,
  course_code,
  course_title,
  avg_score
FROM (
  SELECT
    course_code, course_title, avg_score,
    CASE
      WHEN RANK() OVER (ORDER BY avg_score DESC) <= 2 THEN 'TOP'
      WHEN RANK() OVER (ORDER BY avg_score ASC)  <= 2 THEN 'BOTTOM'
      ELSE 'MID'
    END AS tier
  FROM MV_COURSE_SUMMARY
)
WHERE tier IN ('TOP','BOTTOM')
ORDER BY tier, avg_score DESC;

-- ============================================================
-- CATEGORY G: ANALYTICAL / DIAGNOSTIC QUERIES
-- ============================================================

-- G1: Consecutive fail detection — Window-based grouping trick
-- Demonstrates: ROW_NUMBER gap-and-islands technique
-- ---------------------------------------------------------------
WITH pass_fail_seq AS (
  SELECT
    aa.student_id,
    s.name,
    c.course_code,
    aa.end_time,
    CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END         AS passed,
    ROW_NUMBER() OVER (PARTITION BY aa.student_id, c.course_id
                       ORDER BY aa.end_time)                         AS seq
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN STUDENTS    s ON aa.student_id    = s.student_id
  JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
  JOIN COURSES     c ON a.course_id      = c.course_id
  WHERE aa.status = 'GRADED'
),
islands AS (
  SELECT
    student_id, name, course_code, end_time, passed, seq,
    seq - ROW_NUMBER() OVER (PARTITION BY student_id, course_code, passed
                             ORDER BY seq) AS grp
  FROM pass_fail_seq
)
SELECT
  student_id,
  name,
  course_code,
  COUNT(*) AS consecutive_fails,
  MIN(end_time) AS streak_start,
  MAX(end_time) AS streak_end
FROM islands
WHERE passed = 0
GROUP BY student_id, name, course_code, grp
HAVING COUNT(*) >= 3
ORDER BY consecutive_fails DESC;

-- G2: Absence breach report per student-course
-- Demonstrates: aggregation + HAVING with table-level threshold comparison
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  d.dept_code,
  c.course_code,
  c.max_absences                              AS allowed_absences,
  COUNT(sl.session_id)                        AS actual_absences,
  COUNT(sl.session_id) - c.max_absences       AS breach_count,
  s.risk_level
FROM SESSION_LOGS sl
JOIN STUDENTS    s ON sl.student_id = s.student_id
JOIN DEPARTMENTS d ON s.dept_id     = d.dept_id
JOIN COURSES     c ON sl.course_id  = c.course_id
WHERE sl.event_type = 'ABSENCE'
GROUP BY s.student_id, s.cms_id, s.name, d.dept_code,
         c.course_id, c.course_code, c.max_absences, s.risk_level
HAVING COUNT(sl.session_id) > c.max_absences
ORDER BY breach_count DESC;

-- G3: Topic mastery gap analysis — weakest topics university-wide
-- Demonstrates: aggregation + ORDER BY + FETCH FIRST (Oracle 12c+)
-- ---------------------------------------------------------------
SELECT
  t.topic_name,
  t.difficulty_level,
  c.course_code,
  ROUND(AVG(tp.mastery_pct), 2)                         AS avg_mastery,
  COUNT(tp.student_id)                                  AS students_assessed,
  SUM(CASE WHEN tp.mastery_pct < 60 THEN 1 ELSE 0 END)  AS below_60_count,
  ROUND(100 * SUM(CASE WHEN tp.mastery_pct < 60 THEN 1 ELSE 0 END)
           / COUNT(tp.student_id), 2)                   AS below_60_pct
FROM TOPIC_PERFORMANCE tp
JOIN TOPICS  t ON tp.topic_id  = t.topic_id
JOIN COURSES c ON tp.course_id = c.course_id
GROUP BY t.topic_id, t.topic_name, t.difficulty_level, c.course_id, c.course_code
ORDER BY below_60_pct DESC
FETCH FIRST 10 ROWS ONLY;

-- G4: Instructor effectiveness — avg student improvement after intervention
-- Demonstrates: complex multi-table join with before/after comparison subqueries
-- ---------------------------------------------------------------
SELECT
  inst.name                                              AS instructor,
  COUNT(DISTINCT iv.intervention_id)                     AS interventions_assigned,
  COUNT(DISTINCT CASE WHEN iv.status = 'COMPLETED' THEN iv.intervention_id END) AS completed,
  ROUND(AVG(CASE WHEN iv.closed_at IS NOT NULL
            THEN iv.closed_at - iv.assigned_date END), 1) AS avg_days_to_close,
  COUNT(DISTINCT CASE WHEN s.risk_level = 'LOW' THEN iv.student_id END) AS now_low_risk
FROM INTERVENTIONS iv
JOIN INSTRUCTORS inst ON iv.instructor_id = inst.instructor_id
JOIN STUDENTS    s    ON iv.student_id    = s.student_id
GROUP BY inst.instructor_id, inst.name
ORDER BY completed DESC;

-- G5: Assessment difficulty vs average score — corroboration query
-- Demonstrates: aggregation across joined tables, derived metric comparison
-- ---------------------------------------------------------------
SELECT
  a.type                                                    AS assessment_type,
  t.difficulty_level,
  COUNT(aa.attempt_id)                                      AS total_attempts,
  ROUND(AVG(aa.score), 2)                                   AS avg_raw_score,
  ROUND(AVG(aa.score / a.total_marks * 100), 2)             AS avg_pct_score,
  ROUND(MIN(aa.score), 2)                                   AS min_score,
  ROUND(MAX(aa.score), 2)                                   AS max_score,
  ROUND(STDDEV(aa.score), 2)                                AS score_stddev
FROM ASSESSMENT_ATTEMPTS aa
JOIN ASSESSMENTS a  ON aa.assessment_id = a.assessment_id
JOIN QUESTIONS   q  ON q.assessment_id  = a.assessment_id
JOIN TOPICS      t  ON q.topic_id       = t.topic_id
WHERE aa.status = 'GRADED'
GROUP BY a.type, t.difficulty_level
ORDER BY a.type, t.difficulty_level;

-- G6: Session activity heat map — logins per hour of day
-- Demonstrates: EXTRACT(), GROUP BY derived expression, analytical aggregation
-- ---------------------------------------------------------------
SELECT
  EXTRACT(HOUR FROM logged_at)   AS hour_of_day,
  COUNT(*)                       AS login_count,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_daily_logins,
  RPAD('█', ROUND(COUNT(*) / MAX(COUNT(*)) OVER () * 30), '█') AS bar_chart
FROM SESSION_LOGS
WHERE event_type = 'LOGIN'
GROUP BY EXTRACT(HOUR FROM logged_at)
ORDER BY hour_of_day;

-- ============================================================
-- CATEGORY H: PL/SQL BLOCK ANALYTICS
-- ============================================================

-- H1: Anonymous PL/SQL block — Print risk tier counts using DBMS_OUTPUT
-- Demonstrates: PL/SQL cursor, IF/ELSIF, DBMS_OUTPUT
-- ---------------------------------------------------------------
SET SERVEROUTPUT ON;
DECLARE
  v_low      NUMBER; v_medium NUMBER;
  v_high     NUMBER; v_critical NUMBER; v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_low      FROM STUDENTS WHERE risk_level = 'LOW';
  SELECT COUNT(*) INTO v_medium   FROM STUDENTS WHERE risk_level = 'MEDIUM';
  SELECT COUNT(*) INTO v_high     FROM STUDENTS WHERE risk_level = 'HIGH';
  SELECT COUNT(*) INTO v_critical FROM STUDENTS WHERE risk_level = 'CRITICAL';
  v_total := v_low + v_medium + v_high + v_critical;

  DBMS_OUTPUT.PUT_LINE('====== RISK TIER SUMMARY ======');
  DBMS_OUTPUT.PUT_LINE('LOW      : ' || v_low      || '  (' || ROUND(v_low*100/v_total,1)      || '%)');
  DBMS_OUTPUT.PUT_LINE('MEDIUM   : ' || v_medium   || '  (' || ROUND(v_medium*100/v_total,1)   || '%)');
  DBMS_OUTPUT.PUT_LINE('HIGH     : ' || v_high     || '  (' || ROUND(v_high*100/v_total,1)     || '%)');
  DBMS_OUTPUT.PUT_LINE('CRITICAL : ' || v_critical || '  (' || ROUND(v_critical*100/v_total,1) || '%)');
  DBMS_OUTPUT.PUT_LINE('TOTAL    : ' || v_total);
  DBMS_OUTPUT.PUT_LINE('===============================');
END;
/

-- H2: Cursor FOR loop — Bulk print students needing intervention
-- Demonstrates: explicit cursor, FOR loop, record access
-- ---------------------------------------------------------------
DECLARE
  CURSOR c_at_risk IS
    SELECT s.cms_id, s.name, s.cgpa, s.risk_level, d.dept_code
    FROM   STUDENTS s JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
    WHERE  s.risk_level IN ('HIGH','CRITICAL')
    ORDER  BY CASE s.risk_level WHEN 'CRITICAL' THEN 1 ELSE 2 END, s.cgpa;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== AT-RISK STUDENTS REQUIRING INTERVENTION ===');
  FOR rec IN c_at_risk LOOP
    DBMS_OUTPUT.PUT_LINE(
      RPAD(rec.cms_id, 10) ||
      RPAD(rec.name,   20) ||
      RPAD(rec.dept_code, 6) ||
      'CGPA: ' || TO_CHAR(rec.cgpa, '0.99') ||
      '  RISK: ' || rec.risk_level
    );
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('===============================================');
END;
/

-- H3: REF CURSOR demo — call sp_generate_risk_report
-- Demonstrates: REF CURSOR consumption from a stored procedure
-- ---------------------------------------------------------------
DECLARE
  p_cursor SYS_REFCURSOR;
  v_cms    VARCHAR2(20); v_name VARCHAR2(100);
  v_cgpa   NUMBER; v_risk VARCHAR2(10); v_dept VARCHAR2(10);
BEGIN
  sp_generate_risk_report(
    p_risk_levels => 'HIGH,CRITICAL',
    p_dept_code   => NULL,
    p_page_no     => 1,
    p_page_size   => 10,
    p_out_cursor  => p_cursor
  );
  DBMS_OUTPUT.PUT_LINE(RPAD('CMS_ID',10) || RPAD('NAME',22) || RPAD('DEPT',6) || 'CGPA  RISK');
  LOOP
    FETCH p_cursor INTO v_cms, v_name, v_cgpa, v_risk, v_dept;
    EXIT WHEN p_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(
      RPAD(v_cms,10) || RPAD(v_name,22) || RPAD(v_dept,6) ||
      TO_CHAR(v_cgpa,'0.99') || '  ' || v_risk
    );
  END LOOP;
  CLOSE p_cursor;
END;
/

-- H4: BULK COLLECT — High-performance read of at-risk student IDs
-- Demonstrates: BULK COLLECT INTO, FORALL, collection processing
-- ---------------------------------------------------------------
DECLARE
  TYPE t_ids   IS TABLE OF STUDENTS.student_id%TYPE;
  TYPE t_names IS TABLE OF STUDENTS.name%TYPE;
  TYPE t_cgpas IS TABLE OF STUDENTS.cgpa%TYPE;
  v_ids   t_ids;
  v_names t_names;
  v_cgpas t_cgpas;
BEGIN
  SELECT student_id, name, cgpa
  BULK COLLECT INTO v_ids, v_names, v_cgpas
  FROM   STUDENTS
  WHERE  risk_level IN ('HIGH','CRITICAL')
  ORDER  BY cgpa;

  DBMS_OUTPUT.PUT_LINE('BULK COLLECT fetched ' || v_ids.COUNT || ' at-risk students.');
  FOR i IN 1..v_ids.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE(
      v_ids(i) || '  ' || RPAD(v_names(i), 20) || '  CGPA: ' || v_cgpas(i)
    );
  END LOOP;
END;
/

-- ============================================================
-- CATEGORY I: STORED PROCEDURE / TRIGGER INVOCATION DEMOS
-- ============================================================

-- I1: Call sp_enroll_student and print result
-- ---------------------------------------------------------------
DECLARE
  v_msg VARCHAR2(500);
BEGIN
  sp_enroll_student(
    p_student_id    => 1,
    p_course_id     => 3,
    p_semester_label=> 'Spring 2026',
    p_section       => 'C',
    p_out_msg       => v_msg
  );
  DBMS_OUTPUT.PUT_LINE('sp_enroll_student → ' || v_msg);
END;
/

-- I2: Call sp_compute_topic_score for student 2, course 1
-- ---------------------------------------------------------------
DECLARE
  v_msg VARCHAR2(500);
BEGIN
  sp_compute_topic_score(
    p_student_id => 2,
    p_course_id  => 1,
    p_out_msg    => v_msg
  );
  DBMS_OUTPUT.PUT_LINE('sp_compute_topic_score → ' || v_msg);
END;
/

-- I3: Call sp_assign_intervention for student 8 (flag_id 3)
-- ---------------------------------------------------------------
DECLARE
  v_msg VARCHAR2(500);
BEGIN
  sp_assign_intervention(
    p_student_id    => 8,
    p_flag_id       => 3,
    p_instructor_id => 6,
    p_int_type      => 'ATTENDANCE_WARNING',
    p_description   => 'Usman Shah formal review after 9 absences.',
    p_due_date      => DATE'2026-05-15',
    p_out_msg       => v_msg
  );
  DBMS_OUTPUT.PUT_LINE('sp_assign_intervention → ' || v_msg);
END;
/

-- I4: Trigger demonstration — Insert a failing attempt for student 3
--     trg_consecutive_fail_flag should fire if 3+ consecutive fails exist
-- ---------------------------------------------------------------
DECLARE
  v_msg VARCHAR2(500);
BEGIN
  sp_submit_attempt(
    p_student_id    => 3,
    p_assessment_id => 3,
    p_score         => 8,
    p_out_msg       => v_msg
  );
  DBMS_OUTPUT.PUT_LINE('sp_submit_attempt → ' || v_msg);
END;
/

-- Verify any new risk flags created by trigger
SELECT flag_id, student_id, course_id, flag_type, severity, created_at
FROM   RISK_FLAGS
WHERE  student_id = 3
ORDER  BY created_at DESC;

-- End of ASPAE_Analytics_Queries.sql
