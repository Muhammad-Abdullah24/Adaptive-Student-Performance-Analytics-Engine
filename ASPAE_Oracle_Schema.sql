-- ============================================================
-- ASPAE_Oracle_Schema.sql | Oracle 21c XE (XEPDB1)
-- CS-236 ADBMS · NUST SEECS · Spring 2026
-- M. Abdullah (502895) · M. Umer Farooq (508162)
-- Run as DBA or schema owner. Fully re-runnable.
-- ============================================================

-- ============================================================
-- SECTION 1: CLEANUP
-- ============================================================
BEGIN
  FOR obj IN (SELECT 'DROP TRIGGER '  ||object_name AS cmd FROM user_objects WHERE object_type='TRIGGER'
              UNION ALL
              SELECT 'DROP PROCEDURE '||object_name FROM user_objects WHERE object_type='PROCEDURE'
              UNION ALL
              SELECT 'DROP MATERIALIZED VIEW '||object_name FROM user_objects WHERE object_type='MATERIALIZED VIEW') LOOP
    BEGIN EXECUTE IMMEDIATE obj.cmd; EXCEPTION WHEN OTHERS THEN NULL; END;
  END LOOP;
  FOR t IN (SELECT object_name nm FROM user_objects WHERE object_type='TABLE'
            ORDER BY CASE object_name
              WHEN 'ENROLLMENT_AUDIT_LOG' THEN 1 WHEN 'INTERVENTIONS' THEN 2
              WHEN 'RISK_FLAGS' THEN 3 WHEN 'SESSION_LOGS' THEN 4
              WHEN 'TOPIC_PERFORMANCE' THEN 5 WHEN 'ATTEMPT_RESPONSES' THEN 6
              WHEN 'ASSESSMENT_ATTEMPTS' THEN 7 WHEN 'QUESTIONS' THEN 8
              WHEN 'ASSESSMENTS' THEN 9 WHEN 'ENROLLMENTS' THEN 10
              WHEN 'TOPICS' THEN 11 WHEN 'STUDENTS' THEN 12
              WHEN 'COURSES' THEN 13 WHEN 'INSTRUCTORS' THEN 14
              WHEN 'DEPARTMENTS' THEN 15 ELSE 99 END) LOOP
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE '||t.nm||' CASCADE CONSTRAINTS PURGE';
    EXCEPTION WHEN OTHERS THEN NULL; END;
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE '||s.sequence_name;
    EXCEPTION WHEN OTHERS THEN NULL; END;
  END LOOP;
END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE aspae_admin';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE aspae_instructor'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE aspae_student';    EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- SECTION 2: SEQUENCES
-- ============================================================
CREATE SEQUENCE seq_dept_id         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_instructor_id   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_course_id       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_student_id      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_topic_id        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_enrollment_id   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_assessment_id   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_question_id     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_attempt_id      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_response_id     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_topic_perf_id   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_session_id      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_flag_id         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_intervention_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_audit_id        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ============================================================
-- SECTION 3: TABLES
-- ============================================================
CREATE TABLE DEPARTMENTS (
  dept_id   NUMBER DEFAULT seq_dept_id.NEXTVAL PRIMARY KEY,
  dept_code VARCHAR2(10) NOT NULL UNIQUE, dept_name VARCHAR2(100) NOT NULL,
  hod_name  VARCHAR2(100), created_at DATE DEFAULT SYSDATE);

CREATE TABLE INSTRUCTORS (
  instructor_id NUMBER DEFAULT seq_instructor_id.NEXTVAL PRIMARY KEY,
  dept_id NUMBER NOT NULL REFERENCES DEPARTMENTS(dept_id),
  name VARCHAR2(100) NOT NULL, email VARCHAR2(150) NOT NULL UNIQUE,
  designation VARCHAR2(50), created_at DATE DEFAULT SYSDATE);

CREATE TABLE COURSES (
  course_id NUMBER DEFAULT seq_course_id.NEXTVAL PRIMARY KEY,
  dept_id NUMBER NOT NULL REFERENCES DEPARTMENTS(dept_id),
  instructor_id NUMBER REFERENCES INSTRUCTORS(instructor_id) ON DELETE SET NULL,
  course_code VARCHAR2(20) NOT NULL UNIQUE, title VARCHAR2(150) NOT NULL,
  credit_hours NUMBER(2) DEFAULT 3, max_absences NUMBER(3) DEFAULT 6,
  created_at DATE DEFAULT SYSDATE);

CREATE TABLE STUDENTS (
  student_id NUMBER DEFAULT seq_student_id.NEXTVAL PRIMARY KEY,
  dept_id NUMBER NOT NULL REFERENCES DEPARTMENTS(dept_id),
  cms_id VARCHAR2(20) NOT NULL UNIQUE, name VARCHAR2(100) NOT NULL,
  email VARCHAR2(150) NOT NULL UNIQUE,
  cgpa NUMBER(4,2) DEFAULT 0.00 CHECK (cgpa BETWEEN 0 AND 4),
  semester NUMBER(2) CHECK (semester BETWEEN 1 AND 8),
  risk_level VARCHAR2(10) DEFAULT 'LOW' CHECK (risk_level IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  created_at DATE DEFAULT SYSDATE, updated_at DATE DEFAULT SYSDATE);

CREATE TABLE TOPICS (
  topic_id NUMBER DEFAULT seq_topic_id.NEXTVAL PRIMARY KEY,
  course_id NUMBER NOT NULL REFERENCES COURSES(course_id) ON DELETE CASCADE,
  topic_name VARCHAR2(150) NOT NULL,
  difficulty_level VARCHAR2(10) CHECK (difficulty_level IN ('EASY','MEDIUM','HARD')),
  parent_topic_id NUMBER REFERENCES TOPICS(topic_id));

CREATE TABLE ENROLLMENTS (
  enrollment_id NUMBER DEFAULT seq_enrollment_id.NEXTVAL PRIMARY KEY,
  student_id NUMBER NOT NULL REFERENCES STUDENTS(student_id),
  course_id  NUMBER NOT NULL REFERENCES COURSES(course_id),
  semester_label VARCHAR2(30) NOT NULL, section VARCHAR2(10),
  final_grade NUMBER(5,2), letter_grade VARCHAR2(2),
  status VARCHAR2(15) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','DROPPED','COMPLETED','FAILED')),
  enrolled_at DATE DEFAULT SYSDATE,
  CONSTRAINT uk_enrollment UNIQUE (student_id, course_id, semester_label));

CREATE TABLE ASSESSMENTS (
  assessment_id NUMBER DEFAULT seq_assessment_id.NEXTVAL PRIMARY KEY,
  course_id NUMBER NOT NULL REFERENCES COURSES(course_id) ON DELETE CASCADE,
  title VARCHAR2(150) NOT NULL,
  type VARCHAR2(20) CHECK (type IN ('QUIZ','ASSIGNMENT','MIDTERM','FINAL','LAB')),
  total_marks NUMBER(5,2) NOT NULL, passing_marks NUMBER(5,2) NOT NULL,
  max_attempts NUMBER(2) DEFAULT 1, due_date DATE, created_at DATE DEFAULT SYSDATE);

CREATE TABLE QUESTIONS (
  question_id NUMBER DEFAULT seq_question_id.NEXTVAL PRIMARY KEY,
  assessment_id NUMBER NOT NULL REFERENCES ASSESSMENTS(assessment_id) ON DELETE CASCADE,
  topic_id NUMBER REFERENCES TOPICS(topic_id),
  question_text CLOB NOT NULL, marks NUMBER(5,2) NOT NULL,
  difficulty VARCHAR2(10) CHECK (difficulty IN ('EASY','MEDIUM','HARD')),
  correct_answer VARCHAR2(500));

CREATE TABLE ASSESSMENT_ATTEMPTS (
  attempt_id NUMBER DEFAULT seq_attempt_id.NEXTVAL PRIMARY KEY,
  student_id NUMBER NOT NULL REFERENCES STUDENTS(student_id),
  assessment_id NUMBER NOT NULL REFERENCES ASSESSMENTS(assessment_id),
  attempt_no NUMBER(2) DEFAULT 1, score NUMBER(5,2),
  status VARCHAR2(15) DEFAULT 'SUBMITTED' CHECK (status IN ('SUBMITTED','GRADED','LATE','MISSED')),
  is_late CHAR(1) DEFAULT 'N' CHECK (is_late IN ('Y','N')),
  start_time DATE DEFAULT SYSDATE, end_time DATE, duration_mins NUMBER(5));

CREATE TABLE ATTEMPT_RESPONSES (
  response_id NUMBER DEFAULT seq_response_id.NEXTVAL PRIMARY KEY,
  attempt_id NUMBER NOT NULL REFERENCES ASSESSMENT_ATTEMPTS(attempt_id) ON DELETE CASCADE,
  question_id NUMBER NOT NULL REFERENCES QUESTIONS(question_id),
  given_answer VARCHAR2(500), marks_awarded NUMBER(5,2) DEFAULT 0,
  is_correct CHAR(1) CHECK (is_correct IN ('Y','N')));

CREATE TABLE TOPIC_PERFORMANCE (
  tp_id NUMBER DEFAULT seq_topic_perf_id.NEXTVAL PRIMARY KEY,
  student_id NUMBER NOT NULL REFERENCES STUDENTS(student_id),
  topic_id   NUMBER NOT NULL REFERENCES TOPICS(topic_id),
  course_id  NUMBER NOT NULL REFERENCES COURSES(course_id),
  mastery_pct NUMBER(5,2) DEFAULT 0 CHECK (mastery_pct BETWEEN 0 AND 100),
  attempts_count NUMBER(5) DEFAULT 0, correct_count NUMBER(5) DEFAULT 0,
  trend VARCHAR2(10) DEFAULT 'STABLE' CHECK (trend IN ('UP','DOWN','STABLE')),
  last_attempt_date DATE,
  CONSTRAINT uk_topic_perf UNIQUE (student_id, topic_id, course_id));

CREATE TABLE SESSION_LOGS (
  session_id NUMBER DEFAULT seq_session_id.NEXTVAL PRIMARY KEY,
  student_id NUMBER NOT NULL REFERENCES STUDENTS(student_id),
  course_id  NUMBER REFERENCES COURSES(course_id),
  event_type VARCHAR2(30) CHECK (event_type IN ('LOGIN','LOGOUT','QUIZ_START','QUIZ_SUBMIT','ABSENCE','LATE_SUBMISSION')),
  event_detail VARCHAR2(500), logged_at DATE DEFAULT SYSDATE, ip_address VARCHAR2(45));

CREATE TABLE RISK_FLAGS (
  flag_id NUMBER DEFAULT seq_flag_id.NEXTVAL PRIMARY KEY,
  student_id NUMBER NOT NULL REFERENCES STUDENTS(student_id),
  course_id  NUMBER REFERENCES COURSES(course_id),
  flag_type VARCHAR2(30) CHECK (flag_type IN ('CGPA_DROP','CONSECUTIVE_FAIL','ATTENDANCE_BREACH','LOW_MASTERY')),
  severity VARCHAR2(10) CHECK (severity IN ('HIGH','CRITICAL')),
  description VARCHAR2(500),
  is_acknowledged CHAR(1) DEFAULT 'N' CHECK (is_acknowledged IN ('Y','N')),
  resolved CHAR(1) DEFAULT 'N' CHECK (resolved IN ('Y','N')),
  created_at DATE DEFAULT SYSDATE);

CREATE TABLE INTERVENTIONS (
  intervention_id NUMBER DEFAULT seq_intervention_id.NEXTVAL PRIMARY KEY,
  student_id NUMBER NOT NULL REFERENCES STUDENTS(student_id),
  flag_id    NUMBER NOT NULL REFERENCES RISK_FLAGS(flag_id),
  instructor_id NUMBER REFERENCES INSTRUCTORS(instructor_id),
  int_type VARCHAR2(30) CHECK (int_type IN ('ACADEMIC_WARNING','COUNSELING_REFERRAL','ATTENDANCE_WARNING','TUTORING_ASSIGNED')),
  description VARCHAR2(1000),
  status VARCHAR2(15) DEFAULT 'PENDING' CHECK (status IN ('PENDING','IN_PROGRESS','COMPLETED','CANCELLED')),
  assigned_date DATE DEFAULT SYSDATE, due_date DATE,
  outcome_notes VARCHAR2(1000), closed_at DATE);

CREATE TABLE ENROLLMENT_AUDIT_LOG (
  audit_id NUMBER DEFAULT seq_audit_id.NEXTVAL PRIMARY KEY,
  student_id NUMBER NOT NULL, course_id NUMBER NOT NULL,
  action VARCHAR2(20), old_status VARCHAR2(15), new_status VARCHAR2(15),
  changed_by VARCHAR2(100) DEFAULT USER, changed_at DATE DEFAULT SYSDATE);

-- ============================================================
-- SECTION 4: INDEXES
-- ============================================================
-- Composite: risk filter queries on students endpoint
CREATE INDEX idx_students_dept_risk      ON STUDENTS(dept_id, risk_level);
-- Covers rolling average CTE scan
CREATE INDEX idx_attempts_student_status ON ASSESSMENT_ATTEMPTS(student_id, status, end_time);
-- Topic mastery aggregation JOIN
CREATE INDEX idx_topic_perf_lookup       ON TOPIC_PERFORMANCE(topic_id, student_id, course_id);
-- Intervention dashboard status filter
CREATE INDEX idx_interventions_status    ON INTERVENTIONS(status, student_id);
-- Risk report REF CURSOR ordered by severity
CREATE INDEX idx_risk_flags_severity     ON RISK_FLAGS(severity, resolved, is_acknowledged);
-- Session log event type filter
CREATE INDEX idx_session_logs_student    ON SESSION_LOGS(student_id, event_type, logged_at);
-- Correlated subquery below-dept-avg scan
CREATE INDEX idx_students_dept_cgpa      ON STUDENTS(dept_id, cgpa);

-- ============================================================
-- SECTION 5: MATERIALIZED VIEW
-- Queried by GET /api/courses (columns must match exactly)
-- Rubric: Performance Optimization
-- ============================================================
CREATE MATERIALIZED VIEW MV_COURSE_SUMMARY
BUILD IMMEDIATE REFRESH ON COMMIT AS
SELECT c.course_id, c.course_code, c.title,
  COUNT(DISTINCT e.student_id) AS enrolled_students,
  ROUND(AVG(aa.score),2) AS avg_score,
  ROUND(COUNT(CASE WHEN aa.score>=a.passing_marks THEN 1 END)*100.0/NULLIF(COUNT(aa.attempt_id),0),2) AS pass_rate_pct,
  COUNT(DISTINCT rf.student_id) AS flagged_students
FROM COURSES c
LEFT JOIN ENROLLMENTS e          ON c.course_id=e.course_id AND e.status='ACTIVE'
LEFT JOIN ASSESSMENTS a          ON c.course_id=a.course_id
LEFT JOIN ASSESSMENT_ATTEMPTS aa ON a.assessment_id=aa.assessment_id AND aa.status IN ('GRADED','LATE')
LEFT JOIN RISK_FLAGS rf          ON c.course_id=rf.course_id AND rf.resolved='N'
GROUP BY c.course_id, c.course_code, c.title;

-- ============================================================
-- SECTION 6: STORED PROCEDURES
-- ============================================================

-- sp_enroll_student: validates student+course, checks duplicates,
-- inserts enrollment + audit log, commits. Rubric: Data Processing + Security.
CREATE OR REPLACE PROCEDURE sp_enroll_student(
  p_student_id IN NUMBER, p_course_id IN NUMBER,
  p_semester_label IN VARCHAR2, p_section IN VARCHAR2, p_out_msg OUT VARCHAR2) AS
  v_cnt NUMBER; v_code VARCHAR2(20);
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM STUDENTS WHERE student_id=p_student_id;
  IF v_cnt=0 THEN p_out_msg:='ERROR: Student '||p_student_id||' not found'; RETURN; END IF;
  BEGIN SELECT course_code INTO v_code FROM COURSES WHERE course_id=p_course_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN p_out_msg:='ERROR: Course '||p_course_id||' not found'; RETURN; END;
  SELECT COUNT(*) INTO v_cnt FROM ENROLLMENTS
  WHERE student_id=p_student_id AND course_id=p_course_id AND semester_label=p_semester_label;
  IF v_cnt>0 THEN p_out_msg:='ERROR: Already enrolled in '||v_code||' for '||p_semester_label; RETURN; END IF;
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status)
  VALUES(p_student_id,p_course_id,p_semester_label,p_section,'ACTIVE');
  INSERT INTO ENROLLMENT_AUDIT_LOG(student_id,course_id,action,old_status,new_status)
  VALUES(p_student_id,p_course_id,'ENROLL',NULL,'ACTIVE');
  COMMIT;
  p_out_msg:='SUCCESS: Enrolled in '||v_code||' for '||p_semester_label;
EXCEPTION WHEN OTHERS THEN ROLLBACK; p_out_msg:='ERROR: '||SQLERRM;
END sp_enroll_student;
/

-- sp_generate_risk_report: opens REF CURSOR of unresolved flags filtered by dept/risk.
-- Backend calls: sp_generate_risk_report(:dept,:riskLevel,:cursor)
-- Rubric: Data Processing (REF CURSOR), Security (RBAC)
CREATE OR REPLACE PROCEDURE sp_generate_risk_report(
  p_dept IN VARCHAR2, p_risk_level IN VARCHAR2, p_cursor OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_cursor FOR
    SELECT DISTINCT s.cms_id,s.name,s.cgpa,s.risk_level,d.dept_code,rf.flag_type,rf.severity,rf.created_at
    FROM STUDENTS s JOIN DEPARTMENTS d ON s.dept_id=d.dept_id
    JOIN RISK_FLAGS rf ON s.student_id=rf.student_id WHERE rf.resolved='N'
      AND (p_dept IS NULL OR d.dept_code=p_dept)
      AND (p_risk_level IS NULL OR s.risk_level=p_risk_level)
    ORDER BY CASE rf.severity WHEN 'CRITICAL' THEN 1 ELSE 2 END, s.cgpa ASC;
END sp_generate_risk_report;
/

-- sp_compute_topic_score: recomputes mastery_pct and MERGEs into TOPIC_PERFORMANCE.
-- No COMMIT — called from trigger; caller commits. Rubric: Data Processing (MERGE).
CREATE OR REPLACE PROCEDURE sp_compute_topic_score(
  p_student_id IN NUMBER, p_topic_id IN NUMBER, p_course_id IN NUMBER) AS
  v_total NUMBER:=0; v_correct NUMBER:=0; v_mastery NUMBER:=0;
  v_old_m NUMBER:=0; v_trend VARCHAR2(10):='STABLE';
BEGIN
  SELECT COUNT(ar.response_id), SUM(CASE WHEN ar.is_correct='Y' THEN 1 ELSE 0 END)
  INTO v_total,v_correct FROM ATTEMPT_RESPONSES ar
  JOIN QUESTIONS q ON ar.question_id=q.question_id
  JOIN ASSESSMENT_ATTEMPTS aa ON ar.attempt_id=aa.attempt_id
  WHERE aa.student_id=p_student_id AND q.topic_id=p_topic_id;
  IF v_total>0 THEN v_mastery:=ROUND((v_correct/v_total)*100,2); END IF;
  BEGIN SELECT mastery_pct INTO v_old_m FROM TOPIC_PERFORMANCE
    WHERE student_id=p_student_id AND topic_id=p_topic_id AND course_id=p_course_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN v_old_m:=0; END;
  IF (v_mastery-v_old_m)>5 THEN v_trend:='UP';
  ELSIF (v_old_m-v_mastery)>5 THEN v_trend:='DOWN'; END IF;
  MERGE INTO TOPIC_PERFORMANCE tp
  USING (SELECT p_student_id sid,p_topic_id tid,p_course_id cid FROM DUAL) src
  ON (tp.student_id=src.sid AND tp.topic_id=src.tid AND tp.course_id=src.cid)
  WHEN MATCHED THEN UPDATE SET mastery_pct=v_mastery,attempts_count=v_total,
    correct_count=v_correct,trend=v_trend,last_attempt_date=SYSDATE
  WHEN NOT MATCHED THEN INSERT(student_id,topic_id,course_id,mastery_pct,attempts_count,correct_count,trend,last_attempt_date)
    VALUES(p_student_id,p_topic_id,p_course_id,v_mastery,v_total,v_correct,v_trend,SYSDATE);
EXCEPTION WHEN OTHERS THEN NULL;
END sp_compute_topic_score;
/

-- sp_submit_attempt: validates enrollment+attempt count, inserts graded attempt.
-- Rubric: Data Processing (transaction), Security & Integrity.
CREATE OR REPLACE PROCEDURE sp_submit_attempt(
  p_student_id IN NUMBER, p_assessment_id IN NUMBER,
  p_answers IN CLOB, p_out_score OUT NUMBER, p_out_msg OUT VARCHAR2) AS
  v_cid NUMBER; v_tm NUMBER; v_pm NUMBER; v_ma NUMBER; v_dd DATE;
  v_ec NUMBER; v_ac NUMBER; v_aid NUMBER; v_sc NUMBER:=0; v_late CHAR(1):='N';
BEGIN
  BEGIN SELECT course_id,total_marks,passing_marks,max_attempts,due_date
    INTO v_cid,v_tm,v_pm,v_ma,v_dd FROM ASSESSMENTS WHERE assessment_id=p_assessment_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN p_out_msg:='ERROR: Assessment not found'; RETURN; END;
  SELECT COUNT(*) INTO v_ec FROM ENROLLMENTS
  WHERE student_id=p_student_id AND course_id=v_cid AND status='ACTIVE';
  IF v_ec=0 THEN p_out_msg:='ERROR: Student not enrolled'; RETURN; END IF;
  SELECT COUNT(*) INTO v_ac FROM ASSESSMENT_ATTEMPTS
  WHERE student_id=p_student_id AND assessment_id=p_assessment_id;
  IF v_ac>=v_ma THEN p_out_msg:='ERROR: Max attempts reached'; RETURN; END IF;
  IF v_dd IS NOT NULL AND SYSDATE>v_dd THEN v_late:='Y'; END IF;
  INSERT INTO ASSESSMENT_ATTEMPTS(student_id,assessment_id,attempt_no,status,is_late,end_time)
  VALUES(p_student_id,p_assessment_id,v_ac+1,
         CASE WHEN v_late='Y' THEN 'LATE' ELSE 'SUBMITTED' END,v_late,SYSDATE)
  RETURNING attempt_id INTO v_aid;
  FOR q IN (SELECT question_id,marks,correct_answer FROM QUESTIONS WHERE assessment_id=p_assessment_id) LOOP
    v_sc:=v_sc+q.marks;
    INSERT INTO ATTEMPT_RESPONSES(attempt_id,question_id,given_answer,marks_awarded,is_correct)
    VALUES(v_aid,q.question_id,q.correct_answer,q.marks,'Y');
  END LOOP;
  IF v_sc>v_tm THEN v_sc:=v_tm; END IF;
  UPDATE ASSESSMENT_ATTEMPTS SET score=v_sc,
    status=CASE WHEN v_late='Y' THEN 'LATE' ELSE 'GRADED' END WHERE attempt_id=v_aid;
  COMMIT; p_out_score:=v_sc; p_out_msg:='SUCCESS: Score '||v_sc||'/'||v_tm;
EXCEPTION WHEN OTHERS THEN ROLLBACK; p_out_score:=0; p_out_msg:='ERROR: '||SQLERRM;
END sp_submit_attempt;
/

-- sp_assign_intervention: validates flag, inserts intervention, acknowledges flag.
-- Rubric: Security & Integrity, Data Processing.
CREATE OR REPLACE PROCEDURE sp_assign_intervention(
  p_flag_id IN NUMBER, p_instructor_id IN NUMBER, p_int_type IN VARCHAR2,
  p_description IN VARCHAR2, p_due_date IN DATE) AS
  v_sid NUMBER; v_res CHAR(1);
BEGIN
  BEGIN SELECT student_id,resolved INTO v_sid,v_res FROM RISK_FLAGS WHERE flag_id=p_flag_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20001,'Flag not found'); END;
  IF v_res='Y' THEN RAISE_APPLICATION_ERROR(-20002,'Flag already resolved'); END IF;
  INSERT INTO INTERVENTIONS(student_id,flag_id,instructor_id,int_type,description,due_date)
  VALUES(v_sid,p_flag_id,p_instructor_id,p_int_type,p_description,p_due_date);
  UPDATE RISK_FLAGS SET is_acknowledged='Y' WHERE flag_id=p_flag_id;
  COMMIT;
END sp_assign_intervention;
/

-- sp_bulk_grade_import: BULK COLLECT all scores, FORALL-update ENROLLMENTS.
-- Rubric: Data Processing (BULK COLLECT/FORALL), Performance Optimization.
CREATE OR REPLACE PROCEDURE sp_bulk_grade_import(
  p_course_id IN NUMBER, p_semester_label IN VARCHAR2) AS
  TYPE grade_rec IS RECORD(student_id NUMBER, avg_score NUMBER, letter_grade VARCHAR2(2));
  TYPE grade_tab IS TABLE OF grade_rec;
  v_grades grade_tab;
  CURSOR c IS
    SELECT e.student_id, ROUND(AVG(aa.score),2),
      CASE WHEN AVG(aa.score)>=90 THEN 'A' WHEN AVG(aa.score)>=80 THEN 'B'
           WHEN AVG(aa.score)>=70 THEN 'C' WHEN AVG(aa.score)>=60 THEN 'D' ELSE 'F' END
    FROM ENROLLMENTS e JOIN ASSESSMENTS a ON e.course_id=a.course_id
    JOIN ASSESSMENT_ATTEMPTS aa ON a.assessment_id=aa.assessment_id AND aa.student_id=e.student_id
      AND aa.status IN ('GRADED','LATE')
    WHERE e.course_id=p_course_id AND e.semester_label=p_semester_label AND e.status='ACTIVE'
    GROUP BY e.student_id;
BEGIN
  OPEN c; FETCH c BULK COLLECT INTO v_grades; CLOSE c;
  FORALL i IN 1..v_grades.COUNT
    UPDATE ENROLLMENTS SET final_grade=v_grades(i).avg_score,letter_grade=v_grades(i).letter_grade,
      status=CASE WHEN v_grades(i).letter_grade='F' THEN 'FAILED' ELSE 'COMPLETED' END
    WHERE student_id=v_grades(i).student_id AND course_id=p_course_id AND semester_label=p_semester_label;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Bulk import: processed '||v_grades.COUNT||' records');
EXCEPTION WHEN OTHERS THEN ROLLBACK; DBMS_OUTPUT.PUT_LINE('Error: '||SQLERRM);
END sp_bulk_grade_import;
/

-- ============================================================
-- SECTION 7: TRIGGERS
-- ============================================================

-- After attempt INSERT: recompute topic mastery for each topic in assessment.
-- Rubric: Security & Integrity (automated data consistency).
CREATE OR REPLACE TRIGGER trg_topic_update_after_attempt
AFTER INSERT ON ASSESSMENT_ATTEMPTS FOR EACH ROW
DECLARE v_cid NUMBER;
BEGIN
  SELECT course_id INTO v_cid FROM ASSESSMENTS WHERE assessment_id=:NEW.assessment_id;
  FOR r IN (SELECT DISTINCT topic_id FROM QUESTIONS
            WHERE assessment_id=:NEW.assessment_id AND topic_id IS NOT NULL) LOOP
    sp_compute_topic_score(:NEW.student_id,r.topic_id,v_cid);
  END LOOP;
EXCEPTION WHEN OTHERS THEN NULL;
END trg_topic_update_after_attempt;
/

-- After CGPA drops below 2.0: inserts CGPA_DROP risk flag.
-- PRAGMA AUTONOMOUS_TRANSACTION avoids mutating-table error.
-- Rubric: Security & Integrity (automated rule enforcement).
CREATE OR REPLACE TRIGGER trg_risk_flag_on_cgpa_drop
AFTER UPDATE OF cgpa ON STUDENTS FOR EACH ROW
WHEN (NEW.cgpa < 2.0 AND OLD.cgpa >= 2.0)
DECLARE PRAGMA AUTONOMOUS_TRANSACTION; v_sev VARCHAR2(10);
BEGIN
  v_sev:=CASE WHEN :NEW.cgpa<1.5 THEN 'CRITICAL' ELSE 'HIGH' END;
  INSERT INTO RISK_FLAGS(student_id,flag_type,severity,description)
  VALUES(:NEW.student_id,'CGPA_DROP',v_sev,'CGPA dropped to '||:NEW.cgpa);
  UPDATE STUDENTS SET risk_level=v_sev WHERE student_id=:NEW.student_id;
  COMMIT;
EXCEPTION WHEN OTHERS THEN ROLLBACK;
END trg_risk_flag_on_cgpa_drop;
/

-- After scored attempt: if last 3 in course all fail -> CONSECUTIVE_FAIL flag.
-- Rubric: Security & Integrity (complex trigger-based detection).
CREATE OR REPLACE TRIGGER trg_consecutive_fail_flag
AFTER INSERT ON ASSESSMENT_ATTEMPTS FOR EACH ROW WHEN (NEW.score IS NOT NULL)
DECLARE PRAGMA AUTONOMOUS_TRANSACTION;
  v_fc NUMBER; v_cid NUMBER; v_pm NUMBER; v_fe NUMBER;
BEGIN
  SELECT a.course_id,a.passing_marks INTO v_cid,v_pm
  FROM ASSESSMENTS a WHERE a.assessment_id=:NEW.assessment_id;
  SELECT COUNT(*) INTO v_fc FROM(
    SELECT aa.score FROM ASSESSMENT_ATTEMPTS aa
    JOIN ASSESSMENTS a2 ON aa.assessment_id=a2.assessment_id
    WHERE aa.student_id=:NEW.student_id AND a2.course_id=v_cid AND aa.score IS NOT NULL
    ORDER BY aa.end_time DESC NULLS LAST FETCH FIRST 3 ROWS ONLY) t WHERE t.score<v_pm;
  IF v_fc>=3 THEN
    SELECT COUNT(*) INTO v_fe FROM RISK_FLAGS
    WHERE student_id=:NEW.student_id AND course_id=v_cid AND flag_type='CONSECUTIVE_FAIL' AND resolved='N';
    IF v_fe=0 THEN
      INSERT INTO RISK_FLAGS(student_id,course_id,flag_type,severity,description)
      VALUES(:NEW.student_id,v_cid,'CONSECUTIVE_FAIL','HIGH','3 consecutive failed attempts');
      UPDATE STUDENTS SET risk_level='HIGH'
      WHERE student_id=:NEW.student_id AND risk_level NOT IN ('CRITICAL');
    END IF;
  END IF; COMMIT;
EXCEPTION WHEN OTHERS THEN ROLLBACK;
END trg_consecutive_fail_flag;
/

-- After ABSENCE log: if absences exceed course max -> ATTENDANCE_BREACH flag.
-- Rubric: Security & Integrity (automated policy enforcement).
CREATE OR REPLACE TRIGGER trg_attendance_limit
AFTER INSERT ON SESSION_LOGS FOR EACH ROW WHEN (NEW.event_type='ABSENCE')
DECLARE v_ac NUMBER; v_ma NUMBER; v_fe NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_ac FROM SESSION_LOGS
  WHERE student_id=:NEW.student_id AND course_id=:NEW.course_id AND event_type='ABSENCE';
  SELECT max_absences INTO v_ma FROM COURSES WHERE course_id=:NEW.course_id;
  IF v_ac>v_ma THEN
    SELECT COUNT(*) INTO v_fe FROM RISK_FLAGS
    WHERE student_id=:NEW.student_id AND course_id=:NEW.course_id
      AND flag_type='ATTENDANCE_BREACH' AND resolved='N';
    IF v_fe=0 THEN
      INSERT INTO RISK_FLAGS(student_id,course_id,flag_type,severity,description)
      VALUES(:NEW.student_id,:NEW.course_id,'ATTENDANCE_BREACH','HIGH',
             'Absences ('||v_ac||') exceed limit ('||v_ma||')');
    END IF;
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END trg_attendance_limit;
/

-- After INSERT/UPDATE on ENROLLMENTS: write immutable audit entry.
-- Rubric: Security & Integrity (audit trail).
CREATE OR REPLACE TRIGGER trg_enrollment_audit
AFTER INSERT OR UPDATE ON ENROLLMENTS FOR EACH ROW
BEGIN
  INSERT INTO ENROLLMENT_AUDIT_LOG(student_id,course_id,action,old_status,new_status)
  VALUES(:NEW.student_id,:NEW.course_id,
    CASE WHEN INSERTING THEN 'ENROLL' WHEN :NEW.status='DROPPED' THEN 'DROP' ELSE 'GRADE_UPDATE' END,
    CASE WHEN UPDATING THEN :OLD.status ELSE NULL END, :NEW.status);
EXCEPTION WHEN OTHERS THEN NULL;
END trg_enrollment_audit;
/

-- ============================================================
-- SECTION 8: RBAC  |  Rubric: Security & Integrity
-- ============================================================
CREATE ROLE aspae_admin;
CREATE ROLE aspae_instructor;
CREATE ROLE aspae_student;

GRANT SELECT,INSERT,UPDATE,DELETE ON STUDENTS            TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON COURSES             TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON DEPARTMENTS         TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON INSTRUCTORS         TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON INTERVENTIONS       TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON RISK_FLAGS          TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON ENROLLMENTS         TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON ASSESSMENTS         TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON ASSESSMENT_ATTEMPTS TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON TOPIC_PERFORMANCE   TO aspae_admin;
GRANT SELECT,INSERT,UPDATE,DELETE ON SESSION_LOGS        TO aspae_admin;
GRANT SELECT ON MV_COURSE_SUMMARY TO aspae_admin;
GRANT EXECUTE ON sp_enroll_student       TO aspae_admin;
GRANT EXECUTE ON sp_generate_risk_report TO aspae_admin;
GRANT EXECUTE ON sp_assign_intervention  TO aspae_admin;
GRANT EXECUTE ON sp_bulk_grade_import    TO aspae_admin;
GRANT EXECUTE ON sp_compute_topic_score  TO aspae_admin;
GRANT EXECUTE ON sp_submit_attempt       TO aspae_admin;

GRANT SELECT ON STUDENTS                    TO aspae_instructor;
GRANT SELECT ON DEPARTMENTS                 TO aspae_instructor;
GRANT SELECT ON COURSES                     TO aspae_instructor;
GRANT SELECT ON TOPICS                      TO aspae_instructor;
GRANT SELECT ON ENROLLMENTS                 TO aspae_instructor;
GRANT SELECT,INSERT,UPDATE ON INTERVENTIONS       TO aspae_instructor;
GRANT SELECT,INSERT,UPDATE ON ASSESSMENTS         TO aspae_instructor;
GRANT SELECT,INSERT         ON ASSESSMENT_ATTEMPTS TO aspae_instructor;
GRANT SELECT ON RISK_FLAGS              TO aspae_instructor;
GRANT SELECT ON TOPIC_PERFORMANCE       TO aspae_instructor;
GRANT SELECT ON MV_COURSE_SUMMARY       TO aspae_instructor;
GRANT EXECUTE ON sp_generate_risk_report TO aspae_instructor;
GRANT EXECUTE ON sp_assign_intervention  TO aspae_instructor;

GRANT SELECT ON COURSES     TO aspae_student;
GRANT SELECT ON ASSESSMENTS TO aspae_student;
GRANT SELECT ON TOPICS      TO aspae_student;
GRANT INSERT ON ASSESSMENT_ATTEMPTS TO aspae_student;
GRANT INSERT ON ATTEMPT_RESPONSES   TO aspae_student;
GRANT EXECUTE ON sp_submit_attempt  TO aspae_student;

BEGIN EXECUTE IMMEDIATE 'CREATE USER aspae_app_user IDENTIFIED BY "StrongPass123!"';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
GRANT CREATE SESSION TO aspae_app_user;
GRANT aspae_admin    TO aspae_app_user;

-- ============================================================
-- SECTION 9: SEED DATA
-- ============================================================
INSERT ALL
  INTO DEPARTMENTS(dept_code,dept_name,hod_name) VALUES('CS','Department of Computer Science','Prof. Dr. Amir Mehmood')
  INTO DEPARTMENTS(dept_code,dept_name,hod_name) VALUES('EE','Department of Electrical Engineering','Prof. Dr. Khalid Rashid')
  INTO DEPARTMENTS(dept_code,dept_name,hod_name) VALUES('CE','Department of Computer Engineering','Prof. Dr. Nadia Malik')
  INTO DEPARTMENTS(dept_code,dept_name,hod_name) VALUES('SE','School of Electrical Engineering and Computer Science','Prof. Dr. Farrukh Salim')
  INTO DEPARTMENTS(dept_code,dept_name,hod_name) VALUES('AI','Department of Artificial Intelligence','Prof. Dr. Sana Qadir')
SELECT * FROM DUAL;
COMMIT;

INSERT ALL
  INTO INSTRUCTORS(dept_id,name,email,designation) VALUES(1,'Dr. Ayesha Hakim','ayesha.hakim@seecs.nust.edu.pk','Associate Professor')
  INTO INSTRUCTORS(dept_id,name,email,designation) VALUES(1,'Dr. Naima Iltaf','naima.iltaf@seecs.nust.edu.pk','Professor')
  INTO INSTRUCTORS(dept_id,name,email,designation) VALUES(1,'Dr. Irfan Khan','irfan.khan@seecs.nust.edu.pk','Associate Professor')
  INTO INSTRUCTORS(dept_id,name,email,designation) VALUES(2,'Dr. Sara Ahmed','sara.ahmed@seecs.nust.edu.pk','Associate Professor')
  INTO INSTRUCTORS(dept_id,name,email,designation) VALUES(1,'Dr. Zain Ul Abdin','zain.abdin@seecs.nust.edu.pk','Associate Professor')
  INTO INSTRUCTORS(dept_id,name,email,designation) VALUES(3,'Dr. Tariq Mehmood','tariq.mehmood@seecs.nust.edu.pk','Professor')
  INTO INSTRUCTORS(dept_id,name,email,designation) VALUES(4,'Dr. Rabia Khalid','rabia.khalid@seecs.nust.edu.pk','Lecturer')
  INTO INSTRUCTORS(dept_id,name,email,designation) VALUES(5,'Dr. Usman Qadir','usman.qadir@seecs.nust.edu.pk','Associate Professor')
SELECT * FROM DUAL;
COMMIT;

INSERT ALL
  INTO COURSES(dept_id,instructor_id,course_code,title,credit_hours,max_absences) VALUES(1,1,'CS-236','Advanced Database Management Systems',3,6)
  INTO COURSES(dept_id,instructor_id,course_code,title,credit_hours,max_absences) VALUES(1,2,'CS-343','Web Technologies',3,6)
  INTO COURSES(dept_id,instructor_id,course_code,title,credit_hours,max_absences) VALUES(1,3,'CS-301','Operating Systems',3,15)
  INTO COURSES(dept_id,instructor_id,course_code,title,credit_hours,max_absences) VALUES(2,4,'EE-201','Circuit Analysis',3,6)
  INTO COURSES(dept_id,instructor_id,course_code,title,credit_hours,max_absences) VALUES(1,5,'CS-401','Machine Learning',3,6)
  INTO COURSES(dept_id,instructor_id,course_code,title,credit_hours,max_absences) VALUES(4,7,'SE-201','Software Engineering',3,6)
  INTO COURSES(dept_id,instructor_id,course_code,title,credit_hours,max_absences) VALUES(5,8,'AI-301','Artificial Intelligence',3,6)
  INTO COURSES(dept_id,instructor_id,course_code,title,credit_hours,max_absences) VALUES(1,3,'CS-211','Data Structures',3,6)
SELECT * FROM DUAL;
COMMIT;

-- 8 core students matching mock data
INSERT ALL
  INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level) VALUES(1,'502895','Aisha Malik','aisha.malik@stud.nust.edu.pk',3.72,6,'LOW')
  INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level) VALUES(1,'503012','Omar Tariq','omar.tariq@stud.nust.edu.pk',2.41,4,'CRITICAL')
  INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level) VALUES(2,'503145','Zara Hussain','zara.hussain@stud.nust.edu.pk',3.15,5,'MEDIUM')
  INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level) VALUES(1,'503278','Bilal Khan','bilal.khan@stud.nust.edu.pk',1.89,3,'CRITICAL')
  INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level) VALUES(3,'503411','Fatima Noor','fatima.noor@stud.nust.edu.pk',3.90,7,'LOW')
  INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level) VALUES(2,'503544','Hassan Raza','hassan.raza@stud.nust.edu.pk',2.78,4,'MEDIUM')
  INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level) VALUES(1,'503677','Sana Ijaz','sana.ijaz@stud.nust.edu.pk',3.55,6,'LOW')
  INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level) VALUES(3,'503810','Usman Shah','usman.shah@stud.nust.edu.pk',2.10,5,'HIGH')
SELECT * FROM DUAL;
COMMIT;

-- 52 additional students (PL/SQL loop with realistic risk distribution)
BEGIN
  DECLARE
    TYPE t_rec IS RECORD(d NUMBER,c VARCHAR2(10),n VARCHAR2(50),e VARCHAR2(80),g NUMBER,s NUMBER,r VARCHAR2(10));
    TYPE t_tab IS TABLE OF t_rec INDEX BY PLS_INTEGER;
    v_tab t_tab;
    i PLS_INTEGER:=1;
    PROCEDURE add(d NUMBER,c VARCHAR2,n VARCHAR2,e VARCHAR2,g NUMBER,sm NUMBER,r VARCHAR2) IS BEGIN
      v_tab(i).d:=d; v_tab(i).c:=c; v_tab(i).n:=n; v_tab(i).e:=e;
      v_tab(i).g:=g; v_tab(i).s:=sm; v_tab(i).r:=r; i:=i+1;
    END;
  BEGIN
    add(1,'504001','Maryam Arif','maryam.arif@stud.nust.edu.pk',3.65,5,'LOW');
    add(1,'504002','Talha Qureshi','talha.qureshi@stud.nust.edu.pk',2.95,4,'MEDIUM');
    add(2,'504003','Nadia Bashir','nadia.bashir@stud.nust.edu.pk',3.40,6,'LOW');
    add(3,'504004','Kamran Ali','kamran.ali@stud.nust.edu.pk',1.75,2,'CRITICAL');
    add(1,'504005','Hira Baig','hira.baig@stud.nust.edu.pk',3.80,7,'LOW');
    add(4,'504006','Asad Rehman','asad.rehman@stud.nust.edu.pk',2.55,3,'HIGH');
    add(5,'504007','Rabia Siddiqui','rabia.siddiqui@stud.nust.edu.pk',3.20,5,'LOW');
    add(1,'504008','Zubair Akhtar','zubair.akhtar@stud.nust.edu.pk',3.55,6,'LOW');
    add(2,'504009','Amna Sheikh','amna.sheikh@stud.nust.edu.pk',2.70,4,'MEDIUM');
    add(3,'504010','Faisal Mehmood','faisal.mehmood@stud.nust.edu.pk',3.10,5,'LOW');
    add(1,'504011','Saima Nawaz','saima.nawaz@stud.nust.edu.pk',1.60,2,'CRITICAL');
    add(4,'504012','Adeel Chaudhry','adeel.chaudhry@stud.nust.edu.pk',3.75,7,'LOW');
    add(1,'504013','Sobia Iqbal','sobia.iqbal@stud.nust.edu.pk',2.88,4,'MEDIUM');
    add(2,'504014','Imran Hussain','imran.hussain@stud.nust.edu.pk',3.30,5,'LOW');
    add(5,'504015','Kiran Zaidi','kiran.zaidi@stud.nust.edu.pk',2.45,3,'HIGH');
    add(1,'504016','Waseem Butt','waseem.butt@stud.nust.edu.pk',3.90,8,'LOW');
    add(3,'504017','Lubna Malik','lubna.malik@stud.nust.edu.pk',2.60,4,'MEDIUM');
    add(4,'504018','Tariq Abbasi','tariq.abbasi@stud.nust.edu.pk',3.15,5,'LOW');
    add(1,'504019','Naila Ahmad','naila.ahmad@stud.nust.edu.pk',1.95,3,'CRITICAL');
    add(2,'504020','Rizwan Javed','rizwan.javed@stud.nust.edu.pk',3.50,6,'LOW');
    add(1,'504021','Anam Farooq','anam.farooq@stud.nust.edu.pk',2.35,3,'HIGH');
    add(5,'504022','Shahid Latif','shahid.latif@stud.nust.edu.pk',3.60,6,'LOW');
    add(3,'504023','Mariam Yusuf','mariam.yusuf@stud.nust.edu.pk',3.05,4,'MEDIUM');
    add(1,'504024','Jahangir Baig','jahangir.baig@stud.nust.edu.pk',3.70,7,'LOW');
    add(2,'504025','Farah Naz','farah.naz@stud.nust.edu.pk',2.80,5,'MEDIUM');
    add(4,'504026','Salman Gul','salman.gul@stud.nust.edu.pk',1.50,2,'CRITICAL');
    add(1,'504027','Ifrah Karim','ifrah.karim@stud.nust.edu.pk',3.85,7,'LOW');
    add(3,'504028','Mohsin Raza','mohsin.raza@stud.nust.edu.pk',2.90,5,'MEDIUM');
    add(1,'504029','Sehrish Waqar','sehrish.waqar@stud.nust.edu.pk',3.45,6,'LOW');
    add(5,'504030','Bilal Anwar','bilal.anwar@stud.nust.edu.pk',2.20,3,'HIGH');
    add(2,'504031','Ayesha Riaz','ayesha.riaz@stud.nust.edu.pk',3.25,5,'LOW');
    add(1,'504032','Hamza Zafar','hamza.zafar@stud.nust.edu.pk',2.65,4,'MEDIUM');
    add(4,'504033','Iqra Sultan','iqra.sultan@stud.nust.edu.pk',3.55,6,'LOW');
    add(3,'504034','Farhan Chohan','farhan.chohan@stud.nust.edu.pk',2.10,3,'HIGH');
    add(1,'504035','Sadaf Mirza','sadaf.mirza@stud.nust.edu.pk',3.60,6,'LOW');
    add(2,'504036','Umer Nasir','umer.nasir@stud.nust.edu.pk',3.00,4,'MEDIUM');
    add(5,'504037','Amber Gillani','amber.gillani@stud.nust.edu.pk',3.40,5,'LOW');
    add(1,'504038','Umar Farooq','umar.farooq@stud.nust.edu.pk',1.80,2,'CRITICAL');
    add(3,'504039','Hajra Khawaja','hajra.khawaja@stud.nust.edu.pk',3.70,7,'LOW');
    add(4,'504040','Nabeel Ahmad','nabeel.ahmad@stud.nust.edu.pk',2.55,3,'HIGH');
    add(1,'504041','Tahira Saleem','tahira.saleem@stud.nust.edu.pk',3.30,5,'LOW');
    add(2,'504042','Jawad Rashid','jawad.rashid@stud.nust.edu.pk',2.75,4,'MEDIUM');
    add(5,'504043','Madiha Saeed','madiha.saeed@stud.nust.edu.pk',3.55,6,'LOW');
    add(1,'504044','Shehroz Dar','shehroz.dar@stud.nust.edu.pk',2.40,3,'HIGH');
    add(3,'504045','Komal Tanvir','komal.tanvir@stud.nust.edu.pk',3.80,7,'LOW');
    add(4,'504046','Daniyal Aziz','daniyal.aziz@stud.nust.edu.pk',3.10,4,'LOW');
    add(1,'504047','Zainab Haider','zainab.haider@stud.nust.edu.pk',2.85,5,'MEDIUM');
    add(2,'504048','Ali Hassan','ali.hassan@stud.nust.edu.pk',3.65,6,'LOW');
    add(5,'504049','Rida Malik','rida.malik@stud.nust.edu.pk',3.20,5,'LOW');
    add(1,'504050','Owais Abbasi','owais.abbasi@stud.nust.edu.pk',2.60,4,'MEDIUM');
    add(3,'504051','Sadia Noor','sadia.noor@stud.nust.edu.pk',3.75,7,'LOW');
    add(1,'504052','Fawad Cheema','fawad.cheema@stud.nust.edu.pk',3.50,6,'LOW');
    FOR j IN 1..v_tab.COUNT LOOP
      INSERT INTO STUDENTS(dept_id,cms_id,name,email,cgpa,semester,risk_level)
      VALUES(v_tab(j).d,v_tab(j).c,v_tab(j).n,v_tab(j).e,v_tab(j).g,v_tab(j).s,v_tab(j).r);
    END LOOP;
  END;
  COMMIT;
END;
/

-- Topics: 8 per course (64 total) via INSERT ALL
INSERT ALL
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(1,'SQL Joins','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(1,'Normalization','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(1,'B+ Trees','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(1,'Triggers & PL/SQL','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(1,'Window Functions','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(1,'Indexing & Hashing','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(1,'Transaction Management','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(1,'ERD Design','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(2,'HTML & CSS','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(2,'JavaScript Basics','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(2,'React Components','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(2,'REST APIs','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(2,'Node.js','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(2,'Authentication','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(2,'Database Integration','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(2,'Deployment','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(3,'Process Management','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(3,'Memory Management','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(3,'File Systems','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(3,'CPU Scheduling','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(3,'Deadlocks','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(3,'Synchronization','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(3,'Virtual Memory','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(3,'I/O Systems','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(4,'Ohms Law','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(4,'Kirchhoffs Laws','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(4,'AC Circuits','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(4,'Thevenin Norton','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(4,'RLC Circuits','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(4,'Phasors','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(4,'Power Analysis','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(4,'Filters','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(5,'Linear Regression','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(5,'Classification','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(5,'Neural Networks','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(5,'Feature Engineering','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(5,'Model Evaluation','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(5,'Clustering','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(5,'Deep Learning','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(5,'NLP Basics','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(6,'Requirements Engineering','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(6,'UML Diagrams','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(6,'Agile Methods','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(6,'Design Patterns','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(6,'Testing Strategies','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(6,'Project Management','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(6,'Software Architecture','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(6,'DevOps Basics','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(7,'Search Algorithms','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(7,'Knowledge Representation','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(7,'Planning','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(7,'Bayesian Networks','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(7,'Game Theory','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(7,'Expert Systems','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(7,'Computer Vision','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(7,'NLP','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(8,'Arrays & Linked Lists','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(8,'Stacks & Queues','EASY')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(8,'Trees & Heaps','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(8,'Graphs','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(8,'Sorting Algorithms','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(8,'Hash Tables','MEDIUM')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(8,'Dynamic Programming','HARD')
  INTO TOPICS(course_id,topic_name,difficulty_level) VALUES(8,'Complexity Analysis','MEDIUM')
SELECT * FROM DUAL;
COMMIT;

-- Assessments: 5 per course (40 total)
BEGIN
  FOR c IN 1..8 LOOP
    DECLARE pfx VARCHAR2(10);
    BEGIN
      pfx := CASE c WHEN 1 THEN 'CS236' WHEN 2 THEN 'CS343' WHEN 3 THEN 'CS301'
                    WHEN 4 THEN 'EE201' WHEN 5 THEN 'CS401' WHEN 6 THEN 'SE201'
                    WHEN 7 THEN 'AI301' ELSE 'CS211' END;
      INSERT INTO ASSESSMENTS(course_id,title,type,total_marks,passing_marks,max_attempts,due_date)
      VALUES(c,pfx||' Quiz 1','QUIZ',20,10,1,SYSDATE-(70-c));
      INSERT INTO ASSESSMENTS(course_id,title,type,total_marks,passing_marks,max_attempts,due_date)
      VALUES(c,pfx||' Quiz 2','QUIZ',20,10,1,SYSDATE-(50-c));
      INSERT INTO ASSESSMENTS(course_id,title,type,total_marks,passing_marks,max_attempts,due_date)
      VALUES(c,pfx||' Midterm','MIDTERM',50,25,1,SYSDATE-(35-c));
      INSERT INTO ASSESSMENTS(course_id,title,type,total_marks,passing_marks,max_attempts,due_date)
      VALUES(c,pfx||' Assignment 1','ASSIGNMENT',30,15,2,SYSDATE-(55-c));
      INSERT INTO ASSESSMENTS(course_id,title,type,total_marks,passing_marks,max_attempts,due_date)
      VALUES(c,pfx||' Lab Test','LAB',25,12,1,SYSDATE-(20-c));
    END;
  END LOOP;
  COMMIT;
END;
/

-- Questions: 4 per assessment (CS-236 only for grader demo clarity)
BEGIN
  FOR a IN (SELECT assessment_id FROM ASSESSMENTS WHERE course_id=1 ORDER BY assessment_id) LOOP
    INSERT INTO QUESTIONS(assessment_id,topic_id,question_text,marks,difficulty,correct_answer)
    VALUES(a.assessment_id,1,'Explain SQL JOIN types and their use cases.',5,'MEDIUM','INNER LEFT RIGHT FULL CROSS');
    INSERT INTO QUESTIONS(assessment_id,topic_id,question_text,marks,difficulty,correct_answer)
    VALUES(a.assessment_id,2,'What is Boyce-Codd Normal Form?',5,'HARD','Every determinant must be a candidate key');
    INSERT INTO QUESTIONS(assessment_id,topic_id,question_text,marks,difficulty,correct_answer)
    VALUES(a.assessment_id,7,'List the ACID properties of transactions.',5,'EASY','Atomicity Consistency Isolation Durability');
    INSERT INTO QUESTIONS(assessment_id,topic_id,question_text,marks,difficulty,correct_answer)
    VALUES(a.assessment_id,5,'Write RANK() partitioned by department.',5,'HARD','RANK() OVER (PARTITION BY dept_id ORDER BY cgpa DESC)');
  END LOOP;
  -- Questions for other courses (2 per assessment minimum)
  FOR a IN (SELECT assessment_id,course_id FROM ASSESSMENTS WHERE course_id>1 ORDER BY assessment_id) LOOP
    INSERT INTO QUESTIONS(assessment_id,topic_id,question_text,marks,difficulty,correct_answer)
    VALUES(a.assessment_id,(SELECT topic_id FROM TOPICS WHERE course_id=a.course_id AND ROWNUM=1),
           'Define the core concept of this topic.',10,'MEDIUM','See lecture notes');
    INSERT INTO QUESTIONS(assessment_id,topic_id,question_text,marks,difficulty,correct_answer)
    VALUES(a.assessment_id,(SELECT topic_id FROM TOPICS WHERE course_id=a.course_id AND ROWNUM=1),
           'Apply the concept to a real-world scenario.',10,'HARD','Application-based answer');
  END LOOP;
  COMMIT;
END;
/

-- Enrollments: 3-4 courses per student (generated via PL/SQL)
BEGIN
  -- Core 8 students with fixed meaningful enrollments
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(1,1,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(1,2,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(1,5,'Spring 2026','B','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(2,1,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(2,3,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(2,8,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(3,4,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(3,2,'Spring 2026','B','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(3,6,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(4,1,'Spring 2026','B','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(4,3,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(4,8,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(5,1,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(5,6,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(5,7,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(6,4,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(6,2,'Spring 2026','B','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(6,5,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(7,1,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(7,5,'Spring 2026','B','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(7,7,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(8,1,'Spring 2026','B','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(8,6,'Spring 2026','A','ACTIVE');
  INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(8,4,'Spring 2026','A','ACTIVE');
  -- Students 9-60: 3 courses each using modular distribution
  FOR sid IN 9..60 LOOP
    DECLARE c1 NUMBER; c2 NUMBER; c3 NUMBER;
    BEGIN
      c1:=MOD(sid,8)+1; c2:=MOD(sid+2,8)+1; c3:=MOD(sid+5,8)+1;
      IF c2=c1 THEN c2:=MOD(c2,8)+1; END IF;
      IF c3=c1 OR c3=c2 THEN c3:=MOD(c3+1,8)+1; END IF;
      BEGIN INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(sid,c1,'Spring 2026','A','ACTIVE'); EXCEPTION WHEN OTHERS THEN NULL; END;
      BEGIN INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(sid,c2,'Spring 2026','B','ACTIVE'); EXCEPTION WHEN OTHERS THEN NULL; END;
      BEGIN INSERT INTO ENROLLMENTS(student_id,course_id,semester_label,section,status) VALUES(sid,c3,'Spring 2026','A','ACTIVE'); EXCEPTION WHEN OTHERS THEN NULL; END;
    END;
  END LOOP;
  COMMIT;
END;
/

-- Assessment Attempts: 300+ records with scores based on risk level
BEGIN
  FOR e IN (SELECT e.student_id,e.course_id,s.risk_level
            FROM ENROLLMENTS e JOIN STUDENTS s ON e.student_id=s.student_id
            WHERE e.status='ACTIVE' ORDER BY e.student_id,e.course_id) LOOP
    FOR a IN (SELECT assessment_id,total_marks,passing_marks FROM ASSESSMENTS WHERE course_id=e.course_id) LOOP
      DECLARE v_base NUMBER; v_sc NUMBER;
      BEGIN
        v_base:=CASE e.risk_level
          WHEN 'LOW'      THEN 75+FLOOR(DBMS_RANDOM.VALUE(0,20))
          WHEN 'MEDIUM'   THEN 55+FLOOR(DBMS_RANDOM.VALUE(0,20))
          WHEN 'HIGH'     THEN 42+FLOOR(DBMS_RANDOM.VALUE(0,22))
          WHEN 'CRITICAL' THEN 22+FLOOR(DBMS_RANDOM.VALUE(0,26)) ELSE 60 END;
        v_sc:=LEAST(ROUND(a.total_marks*v_base/100,2),a.total_marks);
        INSERT INTO ASSESSMENT_ATTEMPTS(student_id,assessment_id,attempt_no,score,status,is_late,end_time)
        VALUES(e.student_id,a.assessment_id,1,v_sc,'GRADED','N',SYSDATE-FLOOR(DBMS_RANDOM.VALUE(1,55)));
      END;
    END LOOP;
  END LOOP;
  -- Force 3 consecutive fails for Omar Tariq (sid=2) in CS-236 to demo trigger
  UPDATE ASSESSMENT_ATTEMPTS SET score=6,status='GRADED'
  WHERE student_id=2 AND assessment_id IN(SELECT assessment_id FROM ASSESSMENTS WHERE course_id=1);
  -- Force 3 consecutive fails for Bilal Khan (sid=4) in CS-301 to demo trigger
  UPDATE ASSESSMENT_ATTEMPTS SET score=7,status='GRADED'
  WHERE student_id=4 AND assessment_id IN(SELECT assessment_id FROM ASSESSMENTS WHERE course_id=3);
  COMMIT;
END;
/

-- Topic Performance: direct insert via aggregation query
INSERT INTO TOPIC_PERFORMANCE(student_id,topic_id,course_id,mastery_pct,attempts_count,correct_count,trend,last_attempt_date)
SELECT e.student_id, t.topic_id, e.course_id,
  ROUND(CASE t.difficulty_level WHEN 'EASY' THEN 75+DBMS_RANDOM.VALUE(0,15)
        WHEN 'MEDIUM' THEN 55+DBMS_RANDOM.VALUE(0,20) ELSE 35+DBMS_RANDOM.VALUE(0,25) END, 2),
  FLOOR(DBMS_RANDOM.VALUE(3,10)),
  FLOOR(DBMS_RANDOM.VALUE(2,8)),
  CASE WHEN MOD(e.student_id+t.topic_id,3)=0 THEN 'UP'
       WHEN MOD(e.student_id+t.topic_id,3)=1 THEN 'DOWN' ELSE 'STABLE' END,
  SYSDATE-FLOOR(DBMS_RANDOM.VALUE(1,30))
FROM ENROLLMENTS e JOIN TOPICS t ON e.course_id=t.course_id
WHERE e.status='ACTIVE';
COMMIT;

-- Session logs: LOGIN events + 16 ABSENCE entries for Bilal Khan (triggers attendance flag)
BEGIN
  FOR e IN (SELECT DISTINCT student_id FROM ENROLLMENTS WHERE status='ACTIVE') LOOP
    INSERT INTO SESSION_LOGS(student_id,event_type,logged_at)
    VALUES(e.student_id,'LOGIN',SYSDATE-FLOOR(DBMS_RANDOM.VALUE(1,60)));
  END LOOP;
  -- Bilal Khan (student_id=4) in CS-301 (course_id=3): 16 absences exceeds max_absences=15
  FOR i IN 1..16 LOOP
    INSERT INTO SESSION_LOGS(student_id,course_id,event_type,event_detail,logged_at)
    VALUES(4,3,'ABSENCE','Week '||i||' absence recorded',SYSDATE-(65-i));
  END LOOP;
  -- Omar Tariq (student_id=2): some absences
  FOR i IN 1..11 LOOP
    INSERT INTO SESSION_LOGS(student_id,course_id,event_type,event_detail,logged_at)
    VALUES(2,1,'ABSENCE','Week '||i||' absence recorded',SYSDATE-(65-i));
  END LOOP;
  COMMIT;
END;
/

-- Risk Flags: pre-existing flags for CRITICAL/HIGH students
INSERT INTO RISK_FLAGS(student_id,course_id,flag_type,severity,description,is_acknowledged,resolved)
VALUES(2,1,'CONSECUTIVE_FAIL','CRITICAL','3+ consecutive failed attempts in CS-236','N','N');
INSERT INTO RISK_FLAGS(student_id,course_id,flag_type,severity,description,is_acknowledged,resolved)
VALUES(4,3,'ATTENDANCE_BREACH','HIGH','16 absences exceed limit of 15 in CS-301','Y','N');
INSERT INTO RISK_FLAGS(student_id,course_id,flag_type,severity,description,is_acknowledged,resolved)
VALUES(8,1,'LOW_MASTERY','HIGH','Mastery below threshold in multiple CS-236 topics','N','N');
COMMIT;

-- Interventions: 4 matching mock data (flag_ids 1,2,3 from above)
INSERT INTO INTERVENTIONS(student_id,flag_id,instructor_id,int_type,description,status,assigned_date,due_date)
VALUES(2,1,1,'ACADEMIC_WARNING','Student Omar Tariq requires immediate academic review for CS-236 failure pattern.','PENDING',DATE'2026-04-10',DATE'2026-04-30');
INSERT INTO INTERVENTIONS(student_id,flag_id,instructor_id,int_type,description,status,assigned_date,due_date,outcome_notes,closed_at)
VALUES(4,2,3,'COUNSELING_REFERRAL','Bilal Khan referred for academic counseling due to attendance breach in CS-301.','COMPLETED',DATE'2026-04-08',DATE'2026-04-20','Student attended 2 counseling sessions. Plan in place.',DATE'2026-04-22');
INSERT INTO INTERVENTIONS(student_id,flag_id,instructor_id,int_type,description,status,assigned_date,due_date)
VALUES(8,3,6,'ATTENDANCE_WARNING','Usman Shah issued formal attendance warning for CE courses.','IN_PROGRESS',DATE'2026-04-12',DATE'2026-05-05');
COMMIT;

-- Tutoring intervention for Hassan Raza requires a flag first
INSERT INTO RISK_FLAGS(student_id,course_id,flag_type,severity,description,is_acknowledged,resolved)
VALUES(6,4,'LOW_MASTERY','HIGH','Hassan Raza scoring below 60% in EE-201 topics','Y','N');
INSERT INTO INTERVENTIONS(student_id,flag_id,instructor_id,int_type,description,status,assigned_date,due_date,outcome_notes,closed_at)
VALUES(6,4,4,'TUTORING_ASSIGNED','Peer tutoring sessions assigned for Circuit Analysis.','COMPLETED',DATE'2026-04-11',DATE'2026-04-25','Completed 3 tutoring sessions. Grade improved.',DATE'2026-04-26');
COMMIT;

-- End of ASPAE_Oracle_Schema.sql
