-- ============================================================
-- ASPAE_MySQL_Reporting.sql | MySQL 8.0 Reporting Layer
-- CS-236 ADBMS · NUST SEECS · Spring 2026
-- M. Abdullah (502895) · M. Umer Farooq (508162)
-- Run against the aspae_reporting schema (MySQL 8.0+).
-- Fully re-runnable: DROPs objects before re-creating.
-- ============================================================

-- ============================================================
-- SECTION 0: DATABASE / SESSION SETUP
-- ============================================================
CREATE DATABASE IF NOT EXISTS aspae_reporting
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE aspae_reporting;

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- ============================================================
-- SECTION 1: CLEANUP  (drop in dependency order)
-- ============================================================
DROP PROCEDURE  IF EXISTS sp_dept_risk_summary;
DROP PROCEDURE  IF EXISTS sp_course_performance_report;
DROP PROCEDURE  IF EXISTS sp_student_trend_report;
DROP PROCEDURE  IF EXISTS sp_intervention_status_report;
DROP PROCEDURE  IF EXISTS sp_bulk_risk_update;

DROP VIEW IF EXISTS vw_at_risk_no_intervention;
DROP VIEW IF EXISTS vw_student_course_summary;
DROP VIEW IF EXISTS vw_course_statistics;
DROP VIEW IF EXISTS vw_dept_performance;
DROP VIEW IF EXISTS vw_intervention_detail;
DROP VIEW IF EXISTS vw_topic_mastery_rank;
DROP VIEW IF EXISTS vw_rolling_avg_attempts;

DROP TABLE IF EXISTS RPT_INTERVENTION_LOG;
DROP TABLE IF EXISTS RPT_RISK_SNAPSHOTS;
DROP TABLE IF EXISTS RPT_COURSE_SUMMARY;
DROP TABLE IF EXISTS RPT_STUDENT_PERFORMANCE;
DROP TABLE IF EXISTS INTERVENTIONS;
DROP TABLE IF EXISTS RISK_FLAGS;
DROP TABLE IF EXISTS SESSION_LOGS;
DROP TABLE IF EXISTS TOPIC_PERFORMANCE;
DROP TABLE IF EXISTS ATTEMPT_RESPONSES;
DROP TABLE IF EXISTS ASSESSMENT_ATTEMPTS;
DROP TABLE IF EXISTS QUESTIONS;
DROP TABLE IF EXISTS ASSESSMENTS;
DROP TABLE IF EXISTS ENROLLMENTS;
DROP TABLE IF EXISTS TOPICS;
DROP TABLE IF EXISTS STUDENTS;
DROP TABLE IF EXISTS COURSES;
DROP TABLE IF EXISTS INSTRUCTORS;
DROP TABLE IF EXISTS DEPARTMENTS;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- SECTION 2: MIRROR TABLES  (read-only ETL replica)
-- Mirrors Oracle OLTP tables for MySQL reporting.
-- In production these are populated by a nightly ETL job.
-- ============================================================

CREATE TABLE DEPARTMENTS (
  dept_id   SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  dept_code VARCHAR(10)  NOT NULL UNIQUE,
  dept_name VARCHAR(100) NOT NULL,
  hod_name  VARCHAR(100),
  created_at DATE DEFAULT (CURDATE())
) ENGINE=InnoDB;

CREATE TABLE INSTRUCTORS (
  instructor_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  dept_id       SMALLINT UNSIGNED NOT NULL,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  designation   VARCHAR(50),
  FOREIGN KEY (dept_id) REFERENCES DEPARTMENTS(dept_id)
) ENGINE=InnoDB;

CREATE TABLE COURSES (
  course_id    SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  dept_id      SMALLINT UNSIGNED NOT NULL,
  instructor_id SMALLINT UNSIGNED,
  course_code  VARCHAR(20) NOT NULL UNIQUE,
  title        VARCHAR(150) NOT NULL,
  credit_hours TINYINT DEFAULT 3,
  max_absences TINYINT DEFAULT 6,
  FOREIGN KEY (dept_id)       REFERENCES DEPARTMENTS(dept_id),
  FOREIGN KEY (instructor_id) REFERENCES INSTRUCTORS(instructor_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE STUDENTS (
  student_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  dept_id    SMALLINT UNSIGNED NOT NULL,
  cms_id     VARCHAR(20)  NOT NULL UNIQUE,
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(150) NOT NULL UNIQUE,
  cgpa       DECIMAL(4,2) DEFAULT 0.00 CHECK (cgpa BETWEEN 0 AND 4),
  semester   TINYINT CHECK (semester BETWEEN 1 AND 8),
  risk_level ENUM('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'LOW',
  created_at DATE DEFAULT (CURDATE()),
  updated_at DATE DEFAULT (CURDATE()),
  FOREIGN KEY (dept_id) REFERENCES DEPARTMENTS(dept_id)
) ENGINE=InnoDB;

CREATE TABLE TOPICS (
  topic_id         SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id        SMALLINT UNSIGNED NOT NULL,
  topic_name       VARCHAR(150) NOT NULL,
  difficulty_level ENUM('EASY','MEDIUM','HARD'),
  FOREIGN KEY (course_id) REFERENCES COURSES(course_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ENROLLMENTS (
  enrollment_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id    SMALLINT UNSIGNED NOT NULL,
  course_id     SMALLINT UNSIGNED NOT NULL,
  semester_label VARCHAR(20) NOT NULL,
  section        VARCHAR(5),
  status         ENUM('ACTIVE','DROPPED','COMPLETED','FAILED') DEFAULT 'ACTIVE',
  final_grade    DECIMAL(5,2),
  enrolled_at    DATE DEFAULT (CURDATE()),
  UNIQUE KEY uq_enroll (student_id, course_id, semester_label),
  FOREIGN KEY (student_id) REFERENCES STUDENTS(student_id),
  FOREIGN KEY (course_id)  REFERENCES COURSES(course_id)
) ENGINE=InnoDB;

CREATE TABLE ASSESSMENTS (
  assessment_id  SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id      SMALLINT UNSIGNED NOT NULL,
  title          VARCHAR(150) NOT NULL,
  type           ENUM('QUIZ','ASSIGNMENT','MID','FINAL','LAB') NOT NULL,
  total_marks    DECIMAL(6,2) NOT NULL,
  passing_marks  DECIMAL(6,2) NOT NULL,
  weight_pct     DECIMAL(5,2),
  due_date       DATE,
  is_published   TINYINT(1) DEFAULT 0,
  FOREIGN KEY (course_id) REFERENCES COURSES(course_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE QUESTIONS (
  question_id   SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  assessment_id SMALLINT UNSIGNED NOT NULL,
  topic_id      SMALLINT UNSIGNED,
  question_text TEXT NOT NULL,
  marks         DECIMAL(5,2) DEFAULT 1,
  difficulty    ENUM('EASY','MEDIUM','HARD') DEFAULT 'MEDIUM',
  FOREIGN KEY (assessment_id) REFERENCES ASSESSMENTS(assessment_id) ON DELETE CASCADE,
  FOREIGN KEY (topic_id)      REFERENCES TOPICS(topic_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE ASSESSMENT_ATTEMPTS (
  attempt_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id    SMALLINT UNSIGNED NOT NULL,
  assessment_id SMALLINT UNSIGNED NOT NULL,
  attempt_no    TINYINT DEFAULT 1,
  score         DECIMAL(6,2),
  status        ENUM('IN_PROGRESS','SUBMITTED','GRADED','VOID') DEFAULT 'IN_PROGRESS',
  is_late       TINYINT(1) DEFAULT 0,
  start_time    DATETIME,
  end_time      DATETIME,
  FOREIGN KEY (student_id)    REFERENCES STUDENTS(student_id),
  FOREIGN KEY (assessment_id) REFERENCES ASSESSMENTS(assessment_id),
  INDEX idx_attempt_student   (student_id),
  INDEX idx_attempt_status    (status),
  INDEX idx_attempt_end_time  (end_time)
) ENGINE=InnoDB;

CREATE TABLE ATTEMPT_RESPONSES (
  response_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  attempt_id    INT UNSIGNED NOT NULL,
  question_id   SMALLINT UNSIGNED NOT NULL,
  answer_text   TEXT,
  marks_awarded DECIMAL(5,2),
  is_correct    TINYINT(1),
  FOREIGN KEY (attempt_id)  REFERENCES ASSESSMENT_ATTEMPTS(attempt_id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES QUESTIONS(question_id)
) ENGINE=InnoDB;

CREATE TABLE TOPIC_PERFORMANCE (
  perf_id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id        SMALLINT UNSIGNED NOT NULL,
  topic_id          SMALLINT UNSIGNED NOT NULL,
  course_id         SMALLINT UNSIGNED NOT NULL,
  mastery_pct       DECIMAL(5,2) DEFAULT 0,
  attempts_count    TINYINT DEFAULT 0,
  correct_count     TINYINT DEFAULT 0,
  trend             ENUM('UP','DOWN','STABLE') DEFAULT 'STABLE',
  last_attempt_date DATE,
  UNIQUE KEY uq_tp (student_id, topic_id),
  FOREIGN KEY (student_id) REFERENCES STUDENTS(student_id),
  FOREIGN KEY (topic_id)   REFERENCES TOPICS(topic_id),
  FOREIGN KEY (course_id)  REFERENCES COURSES(course_id)
) ENGINE=InnoDB;

CREATE TABLE SESSION_LOGS (
  session_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id   SMALLINT UNSIGNED NOT NULL,
  course_id    SMALLINT UNSIGNED,
  event_type   ENUM('LOGIN','LOGOUT','SUBMISSION','ABSENCE','MATERIAL_VIEW') NOT NULL,
  event_detail VARCHAR(300),
  logged_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES STUDENTS(student_id),
  FOREIGN KEY (course_id)  REFERENCES COURSES(course_id) ON DELETE SET NULL,
  INDEX idx_session_student (student_id),
  INDEX idx_session_event   (event_type),
  INDEX idx_session_logged  (logged_at)
) ENGINE=InnoDB;

CREATE TABLE RISK_FLAGS (
  flag_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id      SMALLINT UNSIGNED NOT NULL,
  course_id       SMALLINT UNSIGNED,
  flag_type       ENUM('LOW_CGPA','CONSECUTIVE_FAIL','ATTENDANCE_BREACH','LOW_MASTERY') NOT NULL,
  severity        ENUM('LOW','MEDIUM','HIGH','CRITICAL') NOT NULL,
  description     VARCHAR(500),
  is_acknowledged TINYINT(1) DEFAULT 0,
  resolved        TINYINT(1) DEFAULT 0,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  resolved_at     DATETIME,
  FOREIGN KEY (student_id) REFERENCES STUDENTS(student_id),
  FOREIGN KEY (course_id)  REFERENCES COURSES(course_id) ON DELETE SET NULL,
  INDEX idx_flag_student  (student_id),
  INDEX idx_flag_severity (severity),
  INDEX idx_flag_resolved (resolved)
) ENGINE=InnoDB;

CREATE TABLE INTERVENTIONS (
  intervention_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id      SMALLINT UNSIGNED NOT NULL,
  flag_id         INT UNSIGNED,
  instructor_id   SMALLINT UNSIGNED,
  int_type        ENUM('ACADEMIC_WARNING','COUNSELING_REFERRAL','TUTORING_ASSIGNED','ATTENDANCE_WARNING','GRADE_REVIEW') NOT NULL,
  description     TEXT,
  status          ENUM('PENDING','IN_PROGRESS','COMPLETED','CANCELLED') DEFAULT 'PENDING',
  assigned_date   DATE,
  due_date        DATE,
  outcome_notes   TEXT,
  closed_at       DATE,
  FOREIGN KEY (student_id)    REFERENCES STUDENTS(student_id),
  FOREIGN KEY (flag_id)       REFERENCES RISK_FLAGS(flag_id) ON DELETE SET NULL,
  FOREIGN KEY (instructor_id) REFERENCES INSTRUCTORS(instructor_id) ON DELETE SET NULL,
  INDEX idx_iv_student (student_id),
  INDEX idx_iv_status  (status)
) ENGINE=InnoDB;

-- ============================================================
-- SECTION 3: REPORTING SUMMARY TABLES
-- Pre-aggregated snapshots for fast dashboard queries.
-- Populated by stored procedures (run nightly or on-demand).
-- ============================================================

CREATE TABLE RPT_STUDENT_PERFORMANCE (
  rpt_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  snapshot_date   DATE NOT NULL,
  student_id      SMALLINT UNSIGNED NOT NULL,
  cms_id          VARCHAR(20),
  student_name    VARCHAR(100),
  dept_code       VARCHAR(10),
  semester        TINYINT,
  cgpa            DECIMAL(4,2),
  risk_level      ENUM('LOW','MEDIUM','HIGH','CRITICAL'),
  total_attempts  INT DEFAULT 0,
  avg_score       DECIMAL(5,2),
  pass_count      INT DEFAULT 0,
  fail_count      INT DEFAULT 0,
  absence_count   INT DEFAULT 0,
  active_interventions TINYINT DEFAULT 0,
  INDEX idx_rpt_date    (snapshot_date),
  INDEX idx_rpt_risk    (risk_level),
  INDEX idx_rpt_student (student_id)
) ENGINE=InnoDB;

CREATE TABLE RPT_COURSE_SUMMARY (
  rpt_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  snapshot_date DATE NOT NULL,
  course_id     SMALLINT UNSIGNED NOT NULL,
  course_code   VARCHAR(20),
  course_title  VARCHAR(150),
  dept_code     VARCHAR(10),
  instructor    VARCHAR(100),
  enrolled_cnt  INT DEFAULT 0,
  avg_score     DECIMAL(5,2),
  pass_rate     DECIMAL(5,2),
  fail_rate     DECIMAL(5,2),
  high_risk_cnt INT DEFAULT 0,
  INDEX idx_rpt_course_date (snapshot_date),
  INDEX idx_rpt_course_code (course_code)
) ENGINE=InnoDB;

CREATE TABLE RPT_RISK_SNAPSHOTS (
  snap_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  snapshot_date DATE NOT NULL,
  dept_code     VARCHAR(10),
  risk_low      INT DEFAULT 0,
  risk_medium   INT DEFAULT 0,
  risk_high     INT DEFAULT 0,
  risk_critical INT DEFAULT 0,
  total_students INT DEFAULT 0,
  INDEX idx_snap_date (snapshot_date),
  INDEX idx_snap_dept (dept_code)
) ENGINE=InnoDB;

CREATE TABLE RPT_INTERVENTION_LOG (
  log_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  snapshot_date   DATE NOT NULL,
  total_pending   INT DEFAULT 0,
  total_inprogress INT DEFAULT 0,
  total_completed INT DEFAULT 0,
  total_cancelled INT DEFAULT 0,
  avg_days_to_close DECIMAL(6,2),
  INDEX idx_il_date (snapshot_date)
) ENGINE=InnoDB;

-- ============================================================
-- SECTION 4: SEED DATA
-- ============================================================

-- Departments
INSERT INTO DEPARTMENTS (dept_code, dept_name, hod_name) VALUES
  ('CS',  'Computer Science',             'Prof. Tariq Javid'),
  ('EE',  'Electrical Engineering',       'Prof. Sara Memon'),
  ('CE',  'Computer Engineering',         'Prof. Asim Rafiq'),
  ('ME',  'Mechanical Engineering',       'Prof. Junaid Akbar'),
  ('BBA', 'Business Administration',      'Prof. Hira Baig');

-- Instructors
INSERT INTO INSTRUCTORS (dept_id, name, email, designation) VALUES
  (1, 'Dr. Ayesha Hakim',   'ayesha.hakim@nust.edu.pk',   'Associate Professor'),
  (1, 'Dr. Naima Iltaf',    'naima.iltaf@nust.edu.pk',    'Assistant Professor'),
  (1, 'Dr. Irfan Khan',     'irfan.khan@nust.edu.pk',     'Associate Professor'),
  (2, 'Dr. Sara Ahmed',     'sara.ahmed@nust.edu.pk',     'Assistant Professor'),
  (1, 'Dr. Zain Ul Abdin',  'zain.abdin@nust.edu.pk',     'Lecturer'),
  (3, 'Dr. Farrukh Niazi',  'farrukh.niazi@nust.edu.pk',  'Associate Professor'),
  (4, 'Dr. Kamran Liaquat', 'kamran.liaquat@nust.edu.pk', 'Senior Lecturer'),
  (5, 'Dr. Amna Riaz',      'amna.riaz@nust.edu.pk',      'Assistant Professor');

-- Courses
INSERT INTO COURSES (dept_id, instructor_id, course_code, title, credit_hours, max_absences) VALUES
  (1, 1, 'CS-236', 'Advanced Database Management Systems', 3, 6),
  (1, 2, 'CS-343', 'Web Technologies',                    3, 6),
  (1, 3, 'CS-301', 'Operating Systems',                   3, 6),
  (2, 4, 'EE-201', 'Circuit Analysis',                    3, 8),
  (1, 5, 'CS-401', 'Machine Learning',                    3, 6),
  (3, 6, 'CE-301', 'Digital Logic Design',                3, 8),
  (4, 7, 'ME-201', 'Engineering Mechanics',               3, 8),
  (5, 8, 'BBA-311','Business Analytics',                  3, 6);

-- Students (8 named + bulk for 60 total)
INSERT INTO STUDENTS (dept_id, cms_id, name, email, cgpa, semester, risk_level) VALUES
  (1, '502001', 'Aisha Malik',   'aisha.malik@seecs.nust.edu.pk',   3.72, 6, 'LOW'),
  (1, '502002', 'Omar Tariq',    'omar.tariq@seecs.nust.edu.pk',    2.41, 4, 'CRITICAL'),
  (2, '502003', 'Zara Hussain',  'zara.hussain@seecs.nust.edu.pk',  3.15, 5, 'MEDIUM'),
  (1, '502004', 'Bilal Khan',    'bilal.khan@seecs.nust.edu.pk',    1.89, 3, 'CRITICAL'),
  (3, '502005', 'Fatima Noor',   'fatima.noor@seecs.nust.edu.pk',   3.90, 7, 'LOW'),
  (2, '502006', 'Hassan Raza',   'hassan.raza@seecs.nust.edu.pk',   2.78, 4, 'MEDIUM'),
  (1, '502007', 'Sana Ijaz',     'sana.ijaz@seecs.nust.edu.pk',     3.55, 6, 'LOW'),
  (3, '502008', 'Usman Shah',    'usman.shah@seecs.nust.edu.pk',    2.10, 5, 'HIGH');

-- Bulk student insert (9–60)
DROP PROCEDURE IF EXISTS _seed_students;
DELIMITER $$
CREATE PROCEDURE _seed_students()
BEGIN
  DECLARE i INT DEFAULT 9;
  DECLARE dept_ids  JSON DEFAULT '[1,1,2,3,4,5,1,2,3,1]';
  DECLARE semesters JSON DEFAULT '[2,3,4,5,6,7,3,4,5,6]';
  DECLARE risks     JSON DEFAULT '["LOW","LOW","MEDIUM","LOW","MEDIUM","HIGH","LOW","MEDIUM","HIGH","LOW"]';
  WHILE i <= 60 DO
    INSERT IGNORE INTO STUDENTS (dept_id, cms_id, name, email, cgpa, semester, risk_level)
    VALUES (
      JSON_UNQUOTE(JSON_EXTRACT(dept_ids,  CONCAT('$[', MOD(i,10), ']'))),
      CONCAT('5020', LPAD(i, 2, '0')),
      CONCAT('Student_', i, ' Test'),
      CONCAT('student', i, '@seecs.nust.edu.pk'),
      ROUND(1.50 + (MOD(i * 37, 250) / 100.0), 2),
      JSON_UNQUOTE(JSON_EXTRACT(semesters, CONCAT('$[', MOD(i,10), ']'))),
      JSON_UNQUOTE(JSON_EXTRACT(risks,     CONCAT('$[', MOD(i,10), ']')))
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL _seed_students();
DROP PROCEDURE IF EXISTS _seed_students;

-- Topics (8 per course for CS-236 and CS-343, fewer for others)
INSERT INTO TOPICS (course_id, topic_name, difficulty_level) VALUES
  (1,'ERD Design',                'EASY'),   (1,'Normalization (1NF-BCNF)','HARD'),
  (1,'SQL Joins',                 'MEDIUM'), (1,'Indexing & Hashing',     'MEDIUM'),
  (1,'Transaction Management',    'EASY'),   (1,'B+ Trees',               'HARD'),
  (1,'Window Functions',          'HARD'),   (1,'Triggers & PL/SQL',      'MEDIUM'),
  (2,'HTML5 & CSS3',              'EASY'),   (2,'JavaScript ES6',         'MEDIUM'),
  (2,'React Fundamentals',        'MEDIUM'), (2,'REST APIs',              'MEDIUM'),
  (2,'Node.js & Express',         'HARD'),   (2,'Databases for Web',      'MEDIUM'),
  (2,'Authentication & Security', 'HARD'),   (2,'Deployment & CI/CD',     'HARD'),
  (3,'Process Scheduling',        'MEDIUM'), (3,'Memory Management',      'HARD'),
  (3,'File Systems',              'MEDIUM'), (3,'Deadlocks',              'HARD'),
  (3,'Virtual Memory',            'HARD'),   (3,'IPC & Threads',          'MEDIUM'),
  (3,'I/O Systems',               'EASY'),   (3,'OS Security',            'MEDIUM'),
  (4,'KVL & KCL',                 'EASY'),   (4,'Thevenin Theorem',       'MEDIUM'),
  (4,'AC Circuits',               'HARD'),   (4,'Op-Amps',                'HARD'),
  (4,'Frequency Response',        'HARD'),   (4,'Filters',                'MEDIUM'),
  (4,'Power Analysis',            'MEDIUM'), (4,'Transistors',            'HARD');

-- Assessments (5 per course for first 4 courses)
INSERT INTO ASSESSMENTS (course_id, title, type, total_marks, passing_marks, weight_pct, due_date, is_published) VALUES
  (1,'CS-236 Quiz 1',       'QUIZ',      20, 10,  5, '2026-02-14', 1),
  (1,'CS-236 Assignment 1', 'ASSIGNMENT',25, 13,  8, '2026-02-28', 1),
  (1,'CS-236 Mid Exam',     'MID',       50, 25, 20, '2026-03-15', 1),
  (1,'CS-236 Quiz 2',       'QUIZ',      20, 10,  5, '2026-04-01', 1),
  (1,'CS-236 Final Exam',   'FINAL',    100, 50, 40, '2026-05-10', 1),
  (2,'CS-343 Quiz 1',       'QUIZ',      20, 10,  5, '2026-02-10', 1),
  (2,'CS-343 Assignment 1', 'ASSIGNMENT',30, 15, 10, '2026-02-25', 1),
  (2,'CS-343 Mid Exam',     'MID',       50, 25, 20, '2026-03-12', 1),
  (2,'CS-343 Quiz 2',       'QUIZ',      20, 10,  5, '2026-03-30', 1),
  (2,'CS-343 Final Exam',   'FINAL',    100, 50, 40, '2026-05-08', 1),
  (3,'CS-301 Quiz 1',       'QUIZ',      20, 10,  5, '2026-02-12', 1),
  (3,'CS-301 Assignment 1', 'ASSIGNMENT',25, 13,  8, '2026-02-27', 1),
  (3,'CS-301 Mid Exam',     'MID',       50, 25, 20, '2026-03-14', 1),
  (3,'CS-301 Quiz 2',       'QUIZ',      20, 10,  5, '2026-04-03', 1),
  (3,'CS-301 Final Exam',   'FINAL',    100, 50, 40, '2026-05-12', 1),
  (4,'EE-201 Quiz 1',       'QUIZ',      20, 10,  5, '2026-02-15', 1),
  (4,'EE-201 Assignment 1', 'ASSIGNMENT',30, 15, 10, '2026-03-01', 1),
  (4,'EE-201 Mid Exam',     'MID',       50, 25, 20, '2026-03-16', 1),
  (4,'EE-201 Quiz 2',       'QUIZ',      20, 10,  5, '2026-04-05', 1),
  (4,'EE-201 Final Exam',   'FINAL',    100, 50, 40, '2026-05-15', 1);

-- Enrollments for named students
INSERT INTO ENROLLMENTS (student_id, course_id, semester_label, section, status) VALUES
  (1,1,'Spring 2026','A','ACTIVE'),(1,2,'Spring 2026','A','ACTIVE'),(1,5,'Spring 2026','A','ACTIVE'),
  (2,1,'Spring 2026','A','ACTIVE'),(2,3,'Spring 2026','A','ACTIVE'),
  (3,4,'Spring 2026','A','ACTIVE'),(3,2,'Spring 2026','B','ACTIVE'),
  (4,3,'Spring 2026','A','ACTIVE'),(4,1,'Spring 2026','B','ACTIVE'),
  (5,5,'Spring 2026','A','ACTIVE'),(5,6,'Spring 2026','A','ACTIVE'),
  (6,4,'Spring 2026','A','ACTIVE'),(6,2,'Spring 2026','A','ACTIVE'),
  (7,1,'Spring 2026','A','ACTIVE'),(7,5,'Spring 2026','B','ACTIVE'),
  (8,6,'Spring 2026','A','ACTIVE'),(8,4,'Spring 2026','A','ACTIVE');

-- Assessment Attempts (seed for 8 named students)
DROP PROCEDURE IF EXISTS _seed_attempts;
DELIMITER $$
CREATE PROCEDURE _seed_attempts()
BEGIN
  DECLARE done   INT DEFAULT 0;
  DECLARE v_sid  SMALLINT;
  DECLARE v_cid  SMALLINT;
  DECLARE v_risk ENUM('LOW','MEDIUM','HIGH','CRITICAL');
  DECLARE v_aid  SMALLINT;
  DECLARE v_tot  DECIMAL(6,2);
  DECLARE v_pass DECIMAL(6,2);
  DECLARE v_base DECIMAL(5,2);
  DECLARE v_sc   DECIMAL(6,2);

  DECLARE cur_e CURSOR FOR
    SELECT e.student_id, e.course_id, s.risk_level
    FROM   ENROLLMENTS e JOIN STUDENTS s ON e.student_id = s.student_id
    WHERE  e.status = 'ACTIVE';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur_e;
  read_loop: LOOP
    FETCH cur_e INTO v_sid, v_cid, v_risk;
    IF done THEN LEAVE read_loop; END IF;

    -- For each assessment in that course
    BEGIN
      DECLARE done2 INT DEFAULT 0;
      DECLARE cur_a CURSOR FOR
        SELECT assessment_id, total_marks, passing_marks
        FROM   ASSESSMENTS WHERE course_id = v_cid;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET done2 = 1;

      OPEN cur_a;
      read_loop2: LOOP
        FETCH cur_a INTO v_aid, v_tot, v_pass;
        IF done2 THEN LEAVE read_loop2; END IF;

        SET v_base = CASE v_risk
          WHEN 'LOW'      THEN 75 + RAND() * 20
          WHEN 'MEDIUM'   THEN 55 + RAND() * 20
          WHEN 'HIGH'     THEN 40 + RAND() * 22
          WHEN 'CRITICAL' THEN 22 + RAND() * 26
          ELSE 60 END;
        SET v_sc = LEAST(ROUND(v_tot * v_base / 100, 2), v_tot);

        INSERT IGNORE INTO ASSESSMENT_ATTEMPTS
          (student_id, assessment_id, attempt_no, score, status, is_late, end_time)
        VALUES
          (v_sid, v_aid, 1, v_sc, 'GRADED', 0,
           DATE_SUB(NOW(), INTERVAL FLOOR(1 + RAND() * 54) DAY));
      END LOOP read_loop2;
      CLOSE cur_a;
    END;
  END LOOP read_loop;
  CLOSE cur_e;

  -- Force consecutive fails for Omar Tariq (sid=2) to demo trigger context
  UPDATE ASSESSMENT_ATTEMPTS SET score = 6
  WHERE  student_id = 2
    AND  assessment_id IN (SELECT assessment_id FROM ASSESSMENTS WHERE course_id = 1);

  -- Force consecutive fails for Bilal Khan (sid=4)
  UPDATE ASSESSMENT_ATTEMPTS SET score = 7
  WHERE  student_id = 4
    AND  assessment_id IN (SELECT assessment_id FROM ASSESSMENTS WHERE course_id = 3);
END$$
DELIMITER ;
CALL _seed_attempts();
DROP PROCEDURE IF EXISTS _seed_attempts;

-- Topic Performance seed
INSERT IGNORE INTO TOPIC_PERFORMANCE (student_id, topic_id, course_id, mastery_pct, attempts_count, correct_count, trend, last_attempt_date)
SELECT
  e.student_id, t.topic_id, e.course_id,
  ROUND(CASE t.difficulty_level
    WHEN 'EASY'   THEN 75 + RAND() * 15
    WHEN 'MEDIUM' THEN 55 + RAND() * 20
    ELSE               35 + RAND() * 25 END, 2),
  FLOOR(3 + RAND() * 7),
  FLOOR(2 + RAND() * 6),
  ELT(1 + MOD(e.student_id + t.topic_id, 3), 'UP', 'DOWN', 'STABLE'),
  DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 29) DAY)
FROM ENROLLMENTS e
JOIN TOPICS t ON e.course_id = t.course_id
WHERE e.status = 'ACTIVE';

-- Session Logs
INSERT INTO SESSION_LOGS (student_id, event_type, logged_at)
SELECT student_id, 'LOGIN', DATE_SUB(NOW(), INTERVAL FLOOR(1 + RAND() * 59) DAY)
FROM   STUDENTS;

-- Bilal Khan (sid=4) — 16 absences in CS-301 (course_id=3)
INSERT INTO SESSION_LOGS (student_id, course_id, event_type, event_detail, logged_at) VALUES
  (4,3,'ABSENCE','Week 1 absence',DATE_SUB(NOW(),INTERVAL 64 DAY)),
  (4,3,'ABSENCE','Week 2 absence',DATE_SUB(NOW(),INTERVAL 57 DAY)),
  (4,3,'ABSENCE','Week 3 absence',DATE_SUB(NOW(),INTERVAL 50 DAY)),
  (4,3,'ABSENCE','Week 4 absence',DATE_SUB(NOW(),INTERVAL 43 DAY)),
  (4,3,'ABSENCE','Week 5 absence',DATE_SUB(NOW(),INTERVAL 36 DAY)),
  (4,3,'ABSENCE','Week 6 absence',DATE_SUB(NOW(),INTERVAL 29 DAY)),
  (4,3,'ABSENCE','Week 7 absence',DATE_SUB(NOW(),INTERVAL 22 DAY)),
  (4,3,'ABSENCE','Week 8 absence',DATE_SUB(NOW(),INTERVAL 15 DAY)),
  (4,3,'ABSENCE','Week 9 absence',DATE_SUB(NOW(),INTERVAL 8 DAY)),
  (4,3,'ABSENCE','Week 10 absence',DATE_SUB(NOW(),INTERVAL 7 DAY)),
  (4,3,'ABSENCE','Week 11 absence',DATE_SUB(NOW(),INTERVAL 6 DAY)),
  (4,3,'ABSENCE','Week 12 absence',DATE_SUB(NOW(),INTERVAL 5 DAY)),
  (4,3,'ABSENCE','Week 13 absence',DATE_SUB(NOW(),INTERVAL 4 DAY)),
  (4,3,'ABSENCE','Week 14 absence',DATE_SUB(NOW(),INTERVAL 3 DAY)),
  (4,3,'ABSENCE','Week 15 absence',DATE_SUB(NOW(),INTERVAL 2 DAY)),
  (4,3,'ABSENCE','Week 16 absence',DATE_SUB(NOW(),INTERVAL 1 DAY));

-- Risk Flags
INSERT INTO RISK_FLAGS (student_id, course_id, flag_type, severity, description, is_acknowledged, resolved) VALUES
  (2, 1, 'CONSECUTIVE_FAIL', 'CRITICAL', '3+ consecutive failed attempts in CS-236', 0, 0),
  (4, 3, 'ATTENDANCE_BREACH','HIGH',     '16 absences exceed limit of 6 in CS-301',  1, 0),
  (8, 4, 'LOW_MASTERY',      'HIGH',     'Mastery below threshold in EE-201 topics',  0, 0),
  (6, 4, 'LOW_MASTERY',      'HIGH',     'Hassan Raza scoring below 60% in EE-201',   1, 0);

-- Interventions
INSERT INTO INTERVENTIONS (student_id, flag_id, instructor_id, int_type, description, status, assigned_date, due_date) VALUES
  (2, 1, 1, 'ACADEMIC_WARNING',    'Omar Tariq requires immediate academic review for CS-236 failure pattern.', 'PENDING',     '2026-04-10', '2026-04-30');
INSERT INTO INTERVENTIONS (student_id, flag_id, instructor_id, int_type, description, status, assigned_date, due_date, outcome_notes, closed_at) VALUES
  (4, 2, 3, 'COUNSELING_REFERRAL', 'Bilal Khan referred for counseling due to attendance breach in CS-301.', 'COMPLETED',   '2026-04-08', '2026-04-20', 'Student attended 2 sessions. Plan in place.', '2026-04-22'),
  (6, 4, 4, 'TUTORING_ASSIGNED',   'Peer tutoring assigned for Circuit Analysis.', 'COMPLETED',   '2026-04-11', '2026-04-25', 'Completed 3 tutoring sessions. Grade improved.', '2026-04-26');
INSERT INTO INTERVENTIONS (student_id, flag_id, instructor_id, int_type, description, status, assigned_date, due_date) VALUES
  (8, 3, 6, 'ATTENDANCE_WARNING',  'Usman Shah issued formal attendance warning for CE courses.', 'IN_PROGRESS', '2026-04-12', '2026-05-05');

-- ============================================================
-- SECTION 5: REPORTING VIEWS
-- ============================================================

-- V1: Student–Course Summary (JOIN with aggregation)
CREATE OR REPLACE VIEW vw_student_course_summary AS
SELECT
  s.cms_id,
  s.name                                                      AS student_name,
  d.dept_code,
  c.course_code,
  c.title                                                     AS course_title,
  e.section,
  e.status                                                    AS enroll_status,
  COUNT(aa.attempt_id)                                        AS total_attempts,
  ROUND(AVG(aa.score), 2)                                     AS avg_score,
  MAX(aa.score)                                               AS best_score,
  MIN(aa.score)                                               AS lowest_score,
  SUM(CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END) AS passed,
  SUM(CASE WHEN aa.score <  a.passing_marks THEN 1 ELSE 0 END) AS failed,
  s.risk_level
FROM STUDENTS s
JOIN DEPARTMENTS d   ON s.dept_id       = d.dept_id
JOIN ENROLLMENTS e   ON s.student_id    = e.student_id
JOIN COURSES c       ON e.course_id     = c.course_id
LEFT JOIN ASSESSMENT_ATTEMPTS aa ON aa.student_id = s.student_id
LEFT JOIN ASSESSMENTS a           ON aa.assessment_id = a.assessment_id
                                  AND a.course_id = c.course_id
WHERE aa.status = 'GRADED' OR aa.status IS NULL
GROUP BY s.student_id, c.course_id, e.enrollment_id;

-- V2: Course-level statistics
CREATE OR REPLACE VIEW vw_course_statistics AS
SELECT
  c.course_code,
  c.title,
  d.dept_code,
  CONCAT(i.name, ' (', i.designation, ')') AS instructor,
  COUNT(DISTINCT e.student_id)              AS enrolled,
  ROUND(AVG(aa.score), 2)                   AS class_avg,
  ROUND(
    100.0 * SUM(CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END)
          / NULLIF(COUNT(aa.attempt_id), 0), 2)  AS pass_rate_pct,
  MAX(aa.score)                             AS highest_score,
  MIN(aa.score)                             AS lowest_score,
  COUNT(DISTINCT CASE WHEN s.risk_level IN ('HIGH','CRITICAL') THEN s.student_id END) AS high_risk_students
FROM COURSES c
JOIN DEPARTMENTS d          ON c.dept_id       = d.dept_id
LEFT JOIN INSTRUCTORS i     ON c.instructor_id  = i.instructor_id
JOIN ENROLLMENTS e          ON c.course_id      = e.course_id AND e.status = 'ACTIVE'
JOIN STUDENTS s             ON e.student_id     = s.student_id
LEFT JOIN ASSESSMENT_ATTEMPTS aa ON aa.student_id = s.student_id
LEFT JOIN ASSESSMENTS a       ON aa.assessment_id  = a.assessment_id
                              AND a.course_id = c.course_id
                              AND aa.status   = 'GRADED'
GROUP BY c.course_id;

-- V3: Department-level performance aggregation
CREATE OR REPLACE VIEW vw_dept_performance AS
SELECT
  d.dept_code,
  d.dept_name,
  d.hod_name,
  COUNT(DISTINCT s.student_id)                                          AS total_students,
  ROUND(AVG(s.cgpa), 2)                                                 AS avg_cgpa,
  COUNT(DISTINCT CASE WHEN s.risk_level = 'CRITICAL' THEN s.student_id END) AS critical_count,
  COUNT(DISTINCT CASE WHEN s.risk_level = 'HIGH'     THEN s.student_id END) AS high_count,
  COUNT(DISTINCT CASE WHEN s.risk_level = 'MEDIUM'   THEN s.student_id END) AS medium_count,
  COUNT(DISTINCT CASE WHEN s.risk_level = 'LOW'      THEN s.student_id END) AS low_count,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN s.risk_level IN ('HIGH','CRITICAL') THEN s.student_id END)
          / NULLIF(COUNT(DISTINCT s.student_id), 0), 2)                 AS at_risk_pct
FROM DEPARTMENTS d
JOIN STUDENTS s ON d.dept_id = s.dept_id
GROUP BY d.dept_id;

-- V4: At-risk students with NO active intervention (NOT EXISTS pattern)
CREATE OR REPLACE VIEW vw_at_risk_no_intervention AS
SELECT
  s.cms_id,
  s.name,
  s.cgpa,
  s.risk_level,
  d.dept_code,
  s.semester,
  COUNT(rf.flag_id) AS open_flags
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
LEFT JOIN RISK_FLAGS rf ON rf.student_id = s.student_id AND rf.resolved = 0
WHERE s.risk_level IN ('HIGH','CRITICAL')
  AND NOT EXISTS (
    SELECT 1 FROM INTERVENTIONS iv
    WHERE  iv.student_id = s.student_id
      AND  iv.status NOT IN ('CANCELLED','COMPLETED')
  )
GROUP BY s.student_id, d.dept_id
ORDER BY FIELD(s.risk_level,'CRITICAL','HIGH','MEDIUM','LOW'), s.cgpa;

-- V5: Intervention detail view
CREATE OR REPLACE VIEW vw_intervention_detail AS
SELECT
  iv.intervention_id,
  s.cms_id,
  s.name                           AS student_name,
  s.risk_level,
  d.dept_code,
  inst.name                        AS instructor_name,
  iv.int_type,
  iv.description,
  iv.status,
  iv.assigned_date,
  iv.due_date,
  iv.closed_at,
  DATEDIFF(IFNULL(iv.closed_at, CURDATE()), iv.assigned_date) AS days_open,
  rf.flag_type,
  rf.severity                      AS flag_severity,
  iv.outcome_notes
FROM INTERVENTIONS iv
JOIN STUDENTS s           ON iv.student_id    = s.student_id
JOIN DEPARTMENTS d        ON s.dept_id        = d.dept_id
LEFT JOIN INSTRUCTORS inst ON iv.instructor_id = inst.instructor_id
LEFT JOIN RISK_FLAGS rf    ON iv.flag_id       = rf.flag_id;

-- V6: Topic mastery rank per course using window function
CREATE OR REPLACE VIEW vw_topic_mastery_rank AS
SELECT
  c.course_code,
  t.topic_name,
  t.difficulty_level,
  s.name                  AS student_name,
  tp.mastery_pct,
  tp.trend,
  RANK() OVER (
    PARTITION BY tp.course_id, tp.topic_id
    ORDER BY tp.mastery_pct DESC
  )                       AS mastery_rank,
  ROUND(AVG(tp.mastery_pct) OVER (PARTITION BY tp.course_id, tp.topic_id), 2) AS topic_avg
FROM TOPIC_PERFORMANCE tp
JOIN STUDENTS s ON tp.student_id = s.student_id
JOIN TOPICS   t ON tp.topic_id   = t.topic_id
JOIN COURSES  c ON tp.course_id  = c.course_id;

-- V7: 3-attempt rolling average per student (CTE emulated in view)
CREATE OR REPLACE VIEW vw_rolling_avg_attempts AS
WITH ordered_attempts AS (
  SELECT
    s.name                                                       AS student_name,
    aa.student_id,
    aa.assessment_id,
    aa.score,
    aa.end_time,
    ROW_NUMBER() OVER (PARTITION BY aa.student_id ORDER BY aa.end_time DESC) AS rn
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN STUDENTS s ON aa.student_id = s.student_id
  WHERE aa.status = 'GRADED'
)
SELECT
  student_name,
  student_id,
  score,
  end_time,
  rn,
  ROUND(AVG(score) OVER (
    PARTITION BY student_id
    ORDER BY rn
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 2) AS rolling_3_avg
FROM ordered_attempts
WHERE rn <= 10;

-- ============================================================
-- SECTION 6: STORED PROCEDURES
-- ============================================================

-- SP1: Department-level risk summary
DROP PROCEDURE IF EXISTS sp_dept_risk_summary;
DELIMITER $$
CREATE PROCEDURE sp_dept_risk_summary(IN p_dept_code VARCHAR(10))
BEGIN
  /*
    Rubric note: demonstrates IF/CASE, aggregation, GROUP BY, ORDER BY,
    and JOIN across 2 tables. Called from dashboard to populate risk panel.
  */
  IF p_dept_code IS NULL OR p_dept_code = '' THEN
    -- All departments
    SELECT
      d.dept_code,
      d.dept_name,
      COUNT(*)                                                              AS total_students,
      SUM(s.risk_level = 'LOW')                                            AS low_cnt,
      SUM(s.risk_level = 'MEDIUM')                                         AS medium_cnt,
      SUM(s.risk_level = 'HIGH')                                           AS high_cnt,
      SUM(s.risk_level = 'CRITICAL')                                       AS critical_cnt,
      ROUND(AVG(s.cgpa), 2)                                                AS avg_cgpa,
      ROUND(100 * SUM(s.risk_level IN ('HIGH','CRITICAL')) / COUNT(*), 2)  AS at_risk_pct
    FROM STUDENTS s
    JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
    GROUP BY d.dept_id
    ORDER BY at_risk_pct DESC;
  ELSE
    SELECT
      d.dept_code,
      d.dept_name,
      COUNT(*)                                                              AS total_students,
      SUM(s.risk_level = 'LOW')                                            AS low_cnt,
      SUM(s.risk_level = 'MEDIUM')                                         AS medium_cnt,
      SUM(s.risk_level = 'HIGH')                                           AS high_cnt,
      SUM(s.risk_level = 'CRITICAL')                                       AS critical_cnt,
      ROUND(AVG(s.cgpa), 2)                                                AS avg_cgpa,
      ROUND(100 * SUM(s.risk_level IN ('HIGH','CRITICAL')) / COUNT(*), 2)  AS at_risk_pct
    FROM STUDENTS s
    JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
    WHERE d.dept_code = p_dept_code
    GROUP BY d.dept_id;
  END IF;
END$$
DELIMITER ;

-- SP2: Course performance report with percentile
DROP PROCEDURE IF EXISTS sp_course_performance_report;
DELIMITER $$
CREATE PROCEDURE sp_course_performance_report(IN p_course_code VARCHAR(20))
BEGIN
  /*
    Rubric note: Demonstrates window functions (NTILE, RANK), CTEs, multi-table
    JOIN, conditional aggregation. Returns per-student rank within the course.
  */
  WITH course_scores AS (
    SELECT
      s.cms_id,
      s.name,
      s.risk_level,
      ROUND(AVG(aa.score), 2)                                        AS avg_score,
      COUNT(aa.attempt_id)                                           AS attempts,
      SUM(aa.score >= a.passing_marks)                               AS passes,
      RANK() OVER (ORDER BY AVG(aa.score) DESC)                      AS score_rank,
      NTILE(4) OVER (ORDER BY AVG(aa.score) DESC)                    AS quartile
    FROM STUDENTS s
    JOIN ENROLLMENTS e          ON s.student_id    = e.student_id
    JOIN COURSES c              ON e.course_id      = c.course_id
    JOIN ASSESSMENT_ATTEMPTS aa ON aa.student_id    = s.student_id
    JOIN ASSESSMENTS a          ON aa.assessment_id = a.assessment_id
                               AND a.course_id      = c.course_id
    WHERE c.course_code = p_course_code
      AND aa.status     = 'GRADED'
    GROUP BY s.student_id
  )
  SELECT *, CASE quartile WHEN 1 THEN 'Top 25%' WHEN 2 THEN 'Upper Mid'
                          WHEN 3 THEN 'Lower Mid' ELSE 'Bottom 25%' END AS quartile_label
  FROM course_scores
  ORDER BY score_rank;
END$$
DELIMITER ;

-- SP3: Student trend report (rolling average over last N attempts)
DROP PROCEDURE IF EXISTS sp_student_trend_report;
DELIMITER $$
CREATE PROCEDURE sp_student_trend_report(IN p_cms_id VARCHAR(20), IN p_window INT)
BEGIN
  /*
    Rubric note: CTE + window function (ROW_NUMBER, AVG OVER ROWS BETWEEN),
    correlated reference to input parameter, date arithmetic.
  */
  SET p_window = IFNULL(p_window, 3);
  WITH numbered AS (
    SELECT
      aa.attempt_id,
      a.title                  AS assessment,
      c.course_code,
      aa.score,
      aa.end_time,
      ROW_NUMBER() OVER (
        PARTITION BY c.course_id
        ORDER BY aa.end_time DESC
      )                        AS rn
    FROM ASSESSMENT_ATTEMPTS aa
    JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
    JOIN COURSES c     ON a.course_id      = c.course_id
    JOIN STUDENTS s    ON aa.student_id    = s.student_id
    WHERE s.cms_id    = p_cms_id
      AND aa.status   = 'GRADED'
  )
  SELECT
    course_code,
    assessment,
    score,
    end_time,
    rn,
    ROUND(AVG(score) OVER (
      PARTITION BY course_code
      ORDER BY rn
      ROWS BETWEEN (p_window - 1) PRECEDING AND CURRENT ROW
    ), 2) AS rolling_avg
  FROM numbered
  ORDER BY course_code, rn;
END$$
DELIMITER ;

-- SP4: Intervention status report
DROP PROCEDURE IF EXISTS sp_intervention_status_report;
DELIMITER $$
CREATE PROCEDURE sp_intervention_status_report()
BEGIN
  /*
    Rubric note: Aggregation with CASE, DATEDIFF date arithmetic,
    GROUP BY ROLLUP for subtotals.
  */
  SELECT
    IFNULL(iv.status, 'TOTAL')     AS intervention_status,
    COUNT(*)                       AS total,
    ROUND(AVG(DATEDIFF(
      IFNULL(iv.closed_at, CURDATE()), iv.assigned_date)), 1) AS avg_days_open,
    SUM(s.risk_level = 'CRITICAL') AS critical_students,
    SUM(s.risk_level = 'HIGH')     AS high_students
  FROM INTERVENTIONS iv
  JOIN STUDENTS s ON iv.student_id = s.student_id
  GROUP BY iv.status WITH ROLLUP;
END$$
DELIMITER ;

-- SP5: Bulk risk level update based on latest CGPA thresholds
DROP PROCEDURE IF EXISTS sp_bulk_risk_update;
DELIMITER $$
CREATE PROCEDURE sp_bulk_risk_update(OUT p_updated INT)
BEGIN
  /*
    Rubric note: Demonstrates bulk UPDATE with CASE expression — simulates the
    ETL step that re-classifies risk labels after CGPA synchronisation.
  */
  UPDATE STUDENTS
  SET risk_level = CASE
    WHEN cgpa < 1.50 THEN 'CRITICAL'
    WHEN cgpa < 2.00 THEN 'HIGH'
    WHEN cgpa < 2.80 THEN 'MEDIUM'
    ELSE                   'LOW'
  END,
  updated_at = CURDATE();

  SET p_updated = ROW_COUNT();
END$$
DELIMITER ;

-- ============================================================
-- SECTION 7: REPORTING POPULATION PROCEDURE
-- Populates RPT_* snapshot tables — run nightly.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_refresh_reports;
DELIMITER $$
CREATE PROCEDURE sp_refresh_reports()
BEGIN
  DECLARE v_today DATE DEFAULT CURDATE();

  -- Student performance snapshot
  INSERT INTO RPT_STUDENT_PERFORMANCE
    (snapshot_date, student_id, cms_id, student_name, dept_code,
     semester, cgpa, risk_level, total_attempts, avg_score,
     pass_count, fail_count, absence_count, active_interventions)
  SELECT
    v_today,
    s.student_id, s.cms_id, s.name, d.dept_code,
    s.semester, s.cgpa, s.risk_level,
    COUNT(DISTINCT aa.attempt_id),
    ROUND(AVG(aa.score), 2),
    SUM(CASE WHEN aa.score >= a.passing_marks THEN 1 ELSE 0 END),
    SUM(CASE WHEN aa.score <  a.passing_marks THEN 1 ELSE 0 END),
    (SELECT COUNT(*) FROM SESSION_LOGS sl
     WHERE  sl.student_id = s.student_id AND sl.event_type = 'ABSENCE'),
    (SELECT COUNT(*) FROM INTERVENTIONS iv
     WHERE  iv.student_id = s.student_id AND iv.status NOT IN ('COMPLETED','CANCELLED'))
  FROM STUDENTS s
  JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
  LEFT JOIN ASSESSMENT_ATTEMPTS aa ON aa.student_id    = s.student_id AND aa.status = 'GRADED'
  LEFT JOIN ASSESSMENTS a          ON aa.assessment_id = a.assessment_id
  GROUP BY s.student_id, d.dept_id;

  -- Course summary snapshot
  INSERT INTO RPT_COURSE_SUMMARY
    (snapshot_date, course_id, course_code, course_title, dept_code,
     instructor, enrolled_cnt, avg_score, pass_rate, fail_rate, high_risk_cnt)
  SELECT
    v_today, c.course_id, c.course_code, c.title, d.dept_code,
    i.name,
    COUNT(DISTINCT e.student_id),
    ROUND(AVG(aa.score), 2),
    ROUND(100 * SUM(aa.score >= a.passing_marks) / NULLIF(COUNT(aa.attempt_id),0), 2),
    ROUND(100 * SUM(aa.score <  a.passing_marks) / NULLIF(COUNT(aa.attempt_id),0), 2),
    COUNT(DISTINCT CASE WHEN s.risk_level IN ('HIGH','CRITICAL') THEN s.student_id END)
  FROM COURSES c
  JOIN DEPARTMENTS d          ON c.dept_id       = d.dept_id
  LEFT JOIN INSTRUCTORS i     ON c.instructor_id  = i.instructor_id
  JOIN ENROLLMENTS e          ON c.course_id      = e.course_id AND e.status = 'ACTIVE'
  JOIN STUDENTS s             ON e.student_id     = s.student_id
  LEFT JOIN ASSESSMENT_ATTEMPTS aa ON aa.student_id = s.student_id AND aa.status = 'GRADED'
  LEFT JOIN ASSESSMENTS a       ON aa.assessment_id = a.assessment_id AND a.course_id = c.course_id
  GROUP BY c.course_id;

  -- Risk distribution snapshot per dept
  INSERT INTO RPT_RISK_SNAPSHOTS
    (snapshot_date, dept_code, risk_low, risk_medium, risk_high, risk_critical, total_students)
  SELECT
    v_today, d.dept_code,
    SUM(s.risk_level = 'LOW'),
    SUM(s.risk_level = 'MEDIUM'),
    SUM(s.risk_level = 'HIGH'),
    SUM(s.risk_level = 'CRITICAL'),
    COUNT(*)
  FROM STUDENTS s
  JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
  GROUP BY d.dept_id;

  -- Intervention log snapshot
  INSERT INTO RPT_INTERVENTION_LOG
    (snapshot_date, total_pending, total_inprogress, total_completed, total_cancelled, avg_days_to_close)
  SELECT
    v_today,
    SUM(status = 'PENDING'),
    SUM(status = 'IN_PROGRESS'),
    SUM(status = 'COMPLETED'),
    SUM(status = 'CANCELLED'),
    ROUND(AVG(CASE WHEN closed_at IS NOT NULL
              THEN DATEDIFF(closed_at, assigned_date) END), 2)
  FROM INTERVENTIONS;

  SELECT CONCAT('Snapshots created for ', v_today) AS result;
END$$
DELIMITER ;

-- Run the snapshot once for demo data
CALL sp_refresh_reports();

-- ============================================================
-- SECTION 8: KEY REPORTING QUERIES
-- All queries run directly against the populated schema.
-- ============================================================

-- Q1: Students below department CGPA average (Correlated Subquery)
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  s.cgpa,
  d.dept_code,
  ROUND((SELECT AVG(s2.cgpa) FROM STUDENTS s2
         WHERE  s2.dept_id = s.dept_id), 2)  AS dept_avg,
  ROUND((SELECT AVG(s3.cgpa) FROM STUDENTS s3
         WHERE  s3.dept_id = s.dept_id) - s.cgpa, 2) AS gap_below_avg
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
WHERE s.cgpa < (
  SELECT AVG(s4.cgpa) FROM STUDENTS s4 WHERE s4.dept_id = s.dept_id
)
ORDER BY gap_below_avg DESC;

-- Q2: Top 3 students per course — Window RANK()
-- ---------------------------------------------------------------
SELECT * FROM (
  SELECT
    s.name,
    c.course_code,
    ROUND(AVG(aa.score), 2)                                  AS avg_score,
    RANK() OVER (PARTITION BY c.course_id ORDER BY AVG(aa.score) DESC) AS rnk,
    ROUND(AVG(AVG(aa.score)) OVER (PARTITION BY c.course_id), 2)       AS course_avg
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN STUDENTS    s ON aa.student_id    = s.student_id
  JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
  JOIN COURSES     c ON a.course_id      = c.course_id
  WHERE aa.status = 'GRADED'
  GROUP BY s.student_id, c.course_id
) ranked
WHERE rnk <= 3
ORDER BY course_code, rnk;

-- Q3: At-risk students with no active intervention — NOT EXISTS
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  s.cgpa,
  s.risk_level,
  d.dept_code,
  COUNT(rf.flag_id) AS unresolved_flags
FROM STUDENTS s
JOIN DEPARTMENTS d ON s.dept_id = d.dept_id
LEFT JOIN RISK_FLAGS rf ON rf.student_id = s.student_id AND rf.resolved = 0
WHERE s.risk_level IN ('HIGH','CRITICAL')
  AND NOT EXISTS (
    SELECT 1 FROM INTERVENTIONS iv
    WHERE  iv.student_id = s.student_id
      AND  iv.status NOT IN ('CANCELLED','COMPLETED')
  )
GROUP BY s.student_id, d.dept_id
ORDER BY FIELD(s.risk_level,'CRITICAL','HIGH'), s.cgpa;

-- Q4: 3-attempt rolling average per student — CTE + Window
-- ---------------------------------------------------------------
WITH ordered AS (
  SELECT
    s.name,
    aa.student_id,
    aa.score,
    aa.end_time,
    ROW_NUMBER() OVER (PARTITION BY aa.student_id ORDER BY aa.end_time DESC) AS rn
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN STUDENTS s ON aa.student_id = s.student_id
  WHERE aa.status = 'GRADED'
)
SELECT
  name,
  student_id,
  score,
  end_time,
  rn,
  ROUND(AVG(score) OVER (
    PARTITION BY student_id
    ORDER BY rn
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 2) AS rolling_3_avg
FROM ordered
WHERE rn <= 10
ORDER BY student_id, rn;

-- Q5: Topic mastery gap analysis — avg mastery vs threshold
-- ---------------------------------------------------------------
SELECT
  c.course_code,
  t.topic_name,
  t.difficulty_level,
  ROUND(AVG(tp.mastery_pct), 2)                       AS avg_mastery,
  COUNT(tp.student_id)                                AS students_assessed,
  SUM(tp.mastery_pct < 60)                            AS below_threshold,
  ROUND(100 * SUM(tp.mastery_pct < 60) / COUNT(*), 2) AS below_threshold_pct,
  ROUND(MAX(tp.mastery_pct), 2)                       AS max_mastery,
  ROUND(MIN(tp.mastery_pct), 2)                       AS min_mastery
FROM TOPIC_PERFORMANCE tp
JOIN TOPICS  t ON tp.topic_id  = t.topic_id
JOIN COURSES c ON tp.course_id = c.course_id
GROUP BY t.topic_id
ORDER BY below_threshold_pct DESC;

-- Q6: Consecutive fail detection — LEAD/LAG subquery
-- ---------------------------------------------------------------
WITH attempt_pass_fail AS (
  SELECT
    aa.student_id,
    s.name,
    c.course_code,
    aa.attempt_id,
    aa.score,
    a.passing_marks,
    aa.end_time,
    CASE WHEN aa.score < a.passing_marks THEN 0 ELSE 1 END AS passed,
    ROW_NUMBER() OVER (PARTITION BY aa.student_id, c.course_id ORDER BY aa.end_time) AS seq
  FROM ASSESSMENT_ATTEMPTS aa
  JOIN STUDENTS    s ON aa.student_id    = s.student_id
  JOIN ASSESSMENTS a ON aa.assessment_id = a.assessment_id
  JOIN COURSES     c ON a.course_id      = c.course_id
  WHERE aa.status = 'GRADED'
),
consecutive_groups AS (
  SELECT *,
    seq - ROW_NUMBER() OVER (PARTITION BY student_id, course_code, passed ORDER BY seq) AS grp
  FROM attempt_pass_fail
)
SELECT
  student_id,
  name,
  course_code,
  COUNT(*) AS consecutive_fails
FROM consecutive_groups
WHERE passed = 0
GROUP BY student_id, course_code, grp
HAVING COUNT(*) >= 3
ORDER BY consecutive_fails DESC;

-- Q7: Absence breach summary per student-course
-- ---------------------------------------------------------------
SELECT
  s.cms_id,
  s.name,
  c.course_code,
  c.max_absences                         AS allowed,
  COUNT(sl.session_id)                   AS actual_absences,
  COUNT(sl.session_id) - c.max_absences  AS over_limit
FROM SESSION_LOGS sl
JOIN STUDENTS s ON sl.student_id = s.student_id
JOIN COURSES  c ON sl.course_id  = c.course_id
WHERE sl.event_type = 'ABSENCE'
GROUP BY s.student_id, c.course_id
HAVING actual_absences > c.max_absences
ORDER BY over_limit DESC;

-- Q8: Instructor workload and average class performance
-- ---------------------------------------------------------------
SELECT
  i.name                             AS instructor,
  i.designation,
  d.dept_code,
  COUNT(DISTINCT c.course_id)        AS courses_taught,
  SUM(e_cnt.enrolled)                AS total_students,
  ROUND(AVG(c_avg.class_avg), 2)     AS overall_avg_score
FROM INSTRUCTORS i
JOIN DEPARTMENTS d ON i.dept_id = d.dept_id
JOIN COURSES c     ON c.instructor_id = i.instructor_id
JOIN (
  SELECT course_id, COUNT(*) AS enrolled
  FROM   ENROLLMENTS WHERE status = 'ACTIVE'
  GROUP  BY course_id
) e_cnt ON e_cnt.course_id = c.course_id
JOIN (
  SELECT a.course_id, ROUND(AVG(aa.score),2) AS class_avg
  FROM   ASSESSMENT_ATTEMPTS aa
  JOIN   ASSESSMENTS a ON aa.assessment_id = a.assessment_id
  WHERE  aa.status = 'GRADED'
  GROUP  BY a.course_id
) c_avg ON c_avg.course_id = c.course_id
GROUP BY i.instructor_id
ORDER BY overall_avg_score DESC;

-- Q9: Materialized-style pre-aggregated report verification
-- ---------------------------------------------------------------
SELECT
  snapshot_date,
  course_code,
  course_title,
  dept_code,
  instructor,
  enrolled_cnt,
  avg_score,
  pass_rate,
  fail_rate,
  high_risk_cnt
FROM RPT_COURSE_SUMMARY
ORDER BY pass_rate ASC;

-- Q10: UNION — combined risk event feed (flags + absences)
-- ---------------------------------------------------------------
SELECT 'RISK_FLAG'  AS event_type, s.name, rf.flag_type AS detail,
       rf.severity, rf.created_at AS event_time
FROM   RISK_FLAGS rf JOIN STUDENTS s ON rf.student_id = s.student_id
UNION ALL
SELECT 'ABSENCE', s.name, CONCAT('Course ', sl.course_id), 'N/A', sl.logged_at
FROM   SESSION_LOGS sl JOIN STUDENTS s ON sl.student_id = s.student_id
WHERE  sl.event_type = 'ABSENCE'
ORDER  BY event_time DESC
LIMIT  20;

-- End of ASPAE_MySQL_Reporting.sql
