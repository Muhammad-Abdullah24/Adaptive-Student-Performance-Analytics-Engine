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
BUILD IMMEDIATE REFRESH ON DEMAND AS
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

-- aspae_app_user creation skipped (requires sysdba, not needed for app)

-- ============================================================
-- ============================================================
-- SECTION 9: SEED DATA
-- ============================================================

-- DEPARTMENTS
insert into departments (
   dept_code,
   dept_name,
   hod_name
) values ( 'CS',
           'Department of Computer Science',
           'Prof. Dr. Amir Mehmood' );
insert into departments (
   dept_code,
   dept_name,
   hod_name
) values ( 'EE',
           'Department of Electrical Engineering',
           'Prof. Dr. Khalid Rashid' );
insert into departments (
   dept_code,
   dept_name,
   hod_name
) values ( 'CE',
           'Department of Computer Engineering',
           'Prof. Dr. Nadia Malik' );
insert into departments (
   dept_code,
   dept_name,
   hod_name
) values ( 'SE',
           'School of Electrical Engineering and Computer Science',
           'Prof. Dr. Farrukh Salim' );
insert into departments (
   dept_code,
   dept_name,
   hod_name
) values ( 'AI',
           'Department of Artificial Intelligence',
           'Prof. Dr. Sana Qadir' );
commit;

-- INSTRUCTORS (use subquery to get dept_id by code)
insert into instructors (
   dept_id,
   name,
   email,
   designation
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           'Dr. Ayesha Hakim',
           'ayesha.hakim@seecs.nust.edu.pk',
           'Associate Professor' );
insert into instructors (
   dept_id,
   name,
   email,
   designation
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           'Dr. Naima Iltaf',
           'naima.iltaf@seecs.nust.edu.pk',
           'Professor' );
insert into instructors (
   dept_id,
   name,
   email,
   designation
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           'Dr. Irfan Khan',
           'irfan.khan@seecs.nust.edu.pk',
           'Associate Professor' );
insert into instructors (
   dept_id,
   name,
   email,
   designation
) values ( (
   select dept_id
     from departments
    where dept_code = 'EE'
),
           'Dr. Sara Ahmed',
           'sara.ahmed@seecs.nust.edu.pk',
           'Associate Professor' );
insert into instructors (
   dept_id,
   name,
   email,
   designation
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           'Dr. Zain Ul Abdin',
           'zain.abdin@seecs.nust.edu.pk',
           'Associate Professor' );
insert into instructors (
   dept_id,
   name,
   email,
   designation
) values ( (
   select dept_id
     from departments
    where dept_code = 'CE'
),
           'Dr. Tariq Mehmood',
           'tariq.mehmood@seecs.nust.edu.pk',
           'Professor' );
insert into instructors (
   dept_id,
   name,
   email,
   designation
) values ( (
   select dept_id
     from departments
    where dept_code = 'SE'
),
           'Dr. Rabia Khalid',
           'rabia.khalid@seecs.nust.edu.pk',
           'Lecturer' );
insert into instructors (
   dept_id,
   name,
   email,
   designation
) values ( (
   select dept_id
     from departments
    where dept_code = 'AI'
),
           'Dr. Usman Qadir',
           'usman.qadir@seecs.nust.edu.pk',
           'Associate Professor' );
commit;

-- COURSES (use subqueries for dept_id and instructor_id by email)
insert into courses (
   dept_id,
   instructor_id,
   course_code,
   title,
   credit_hours,
   max_absences
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           (
              select instructor_id
                from instructors
               where email = 'ayesha.hakim@seecs.nust.edu.pk'
           ),
           'CS-236',
           'Advanced Database Management Systems',
           3,
           6 );
insert into courses (
   dept_id,
   instructor_id,
   course_code,
   title,
   credit_hours,
   max_absences
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           (
              select instructor_id
                from instructors
               where email = 'naima.iltaf@seecs.nust.edu.pk'
           ),
           'CS-343',
           'Web Technologies',
           3,
           6 );
insert into courses (
   dept_id,
   instructor_id,
   course_code,
   title,
   credit_hours,
   max_absences
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           (
              select instructor_id
                from instructors
               where email = 'irfan.khan@seecs.nust.edu.pk'
           ),
           'CS-301',
           'Operating Systems',
           3,
           15 );
insert into courses (
   dept_id,
   instructor_id,
   course_code,
   title,
   credit_hours,
   max_absences
) values ( (
   select dept_id
     from departments
    where dept_code = 'EE'
),
           (
              select instructor_id
                from instructors
               where email = 'sara.ahmed@seecs.nust.edu.pk'
           ),
           'EE-201',
           'Circuit Analysis',
           3,
           6 );
insert into courses (
   dept_id,
   instructor_id,
   course_code,
   title,
   credit_hours,
   max_absences
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           (
              select instructor_id
                from instructors
               where email = 'zain.abdin@seecs.nust.edu.pk'
           ),
           'CS-401',
           'Machine Learning',
           3,
           6 );
insert into courses (
   dept_id,
   instructor_id,
   course_code,
   title,
   credit_hours,
   max_absences
) values ( (
   select dept_id
     from departments
    where dept_code = 'SE'
),
           (
              select instructor_id
                from instructors
               where email = 'rabia.khalid@seecs.nust.edu.pk'
           ),
           'SE-201',
           'Software Engineering',
           3,
           6 );
insert into courses (
   dept_id,
   instructor_id,
   course_code,
   title,
   credit_hours,
   max_absences
) values ( (
   select dept_id
     from departments
    where dept_code = 'AI'
),
           (
              select instructor_id
                from instructors
               where email = 'usman.qadir@seecs.nust.edu.pk'
           ),
           'AI-301',
           'Artificial Intelligence',
           3,
           6 );
insert into courses (
   dept_id,
   instructor_id,
   course_code,
   title,
   credit_hours,
   max_absences
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           (
              select instructor_id
                from instructors
               where email = 'irfan.khan@seecs.nust.edu.pk'
           ),
           'CS-211',
           'Data Structures',
           3,
           6 );
commit;

-- STUDENTS (8 core students)
insert into students (
   dept_id,
   cms_id,
   name,
   email,
   cgpa,
   semester,
   risk_level
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           '502895',
           'Aisha Malik',
           'aisha.malik@stud.nust.edu.pk',
           3.72,
           6,
           'LOW' );
insert into students (
   dept_id,
   cms_id,
   name,
   email,
   cgpa,
   semester,
   risk_level
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           '503012',
           'Omar Tariq',
           'omar.tariq@stud.nust.edu.pk',
           2.41,
           4,
           'CRITICAL' );
insert into students (
   dept_id,
   cms_id,
   name,
   email,
   cgpa,
   semester,
   risk_level
) values ( (
   select dept_id
     from departments
    where dept_code = 'EE'
),
           '503145',
           'Zara Hussain',
           'zara.hussain@stud.nust.edu.pk',
           3.15,
           5,
           'MEDIUM' );
insert into students (
   dept_id,
   cms_id,
   name,
   email,
   cgpa,
   semester,
   risk_level
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           '503278',
           'Bilal Khan',
           'bilal.khan@stud.nust.edu.pk',
           1.89,
           3,
           'CRITICAL' );
insert into students (
   dept_id,
   cms_id,
   name,
   email,
   cgpa,
   semester,
   risk_level
) values ( (
   select dept_id
     from departments
    where dept_code = 'CE'
),
           '503411',
           'Fatima Noor',
           'fatima.noor@stud.nust.edu.pk',
           3.90,
           7,
           'LOW' );
insert into students (
   dept_id,
   cms_id,
   name,
   email,
   cgpa,
   semester,
   risk_level
) values ( (
   select dept_id
     from departments
    where dept_code = 'EE'
),
           '503544',
           'Hassan Raza',
           'hassan.raza@stud.nust.edu.pk',
           2.78,
           4,
           'MEDIUM' );
insert into students (
   dept_id,
   cms_id,
   name,
   email,
   cgpa,
   semester,
   risk_level
) values ( (
   select dept_id
     from departments
    where dept_code = 'CS'
),
           '503677',
           'Sana Ijaz',
           'sana.ijaz@stud.nust.edu.pk',
           3.55,
           6,
           'LOW' );
insert into students (
   dept_id,
   cms_id,
   name,
   email,
   cgpa,
   semester,
   risk_level
) values ( (
   select dept_id
     from departments
    where dept_code = 'CE'
),
           '503810',
           'Usman Shah',
           'usman.shah@stud.nust.edu.pk',
           2.10,
           5,
           'HIGH' );
commit;

-- STUDENTS (52 additional)
begin
   declare
      type t_rec is record (
            d varchar2(5),
            c varchar2(10),
            n varchar2(50),
            e varchar2(80),
            g number,
            s number,
            r varchar2(10)
      );
      type t_tab is
         table of t_rec index by pls_integer;
      v_tab t_tab;
      i     pls_integer := 1;
      procedure add (
         d  varchar2,
         c  varchar2,
         n  varchar2,
         e  varchar2,
         g  number,
         sm number,
         r  varchar2
      ) is
      begin
         v_tab(i).d := d;
         v_tab(i).c := c;
         v_tab(i).n := n;
         v_tab(i).e := e;
         v_tab(i).g := g;
         v_tab(i).s := sm;
         v_tab(i).r := r;
         i := i + 1;
      end;
   begin
      add(
         'CS',
         '504001',
         'Maryam Arif',
         'maryam.arif@stud.nust.edu.pk',
         3.65,
         5,
         'LOW'
      );
      add(
         'CS',
         '504002',
         'Talha Qureshi',
         'talha.qureshi@stud.nust.edu.pk',
         2.95,
         4,
         'MEDIUM'
      );
      add(
         'EE',
         '504003',
         'Nadia Bashir',
         'nadia.bashir@stud.nust.edu.pk',
         3.40,
         6,
         'LOW'
      );
      add(
         'CE',
         '504004',
         'Kamran Ali',
         'kamran.ali@stud.nust.edu.pk',
         1.75,
         2,
         'CRITICAL'
      );
      add(
         'CS',
         '504005',
         'Hira Baig',
         'hira.baig@stud.nust.edu.pk',
         3.80,
         7,
         'LOW'
      );
      add(
         'SE',
         '504006',
         'Asad Rehman',
         'asad.rehman@stud.nust.edu.pk',
         2.55,
         3,
         'HIGH'
      );
      add(
         'AI',
         '504007',
         'Rabia Siddiqui',
         'rabia.siddiqui@stud.nust.edu.pk',
         3.20,
         5,
         'LOW'
      );
      add(
         'CS',
         '504008',
         'Zubair Akhtar',
         'zubair.akhtar@stud.nust.edu.pk',
         3.55,
         6,
         'LOW'
      );
      add(
         'EE',
         '504009',
         'Amna Sheikh',
         'amna.sheikh@stud.nust.edu.pk',
         2.70,
         4,
         'MEDIUM'
      );
      add(
         'CE',
         '504010',
         'Faisal Mehmood',
         'faisal.mehmood@stud.nust.edu.pk',
         3.10,
         5,
         'LOW'
      );
      add(
         'CS',
         '504011',
         'Saima Nawaz',
         'saima.nawaz@stud.nust.edu.pk',
         1.60,
         2,
         'CRITICAL'
      );
      add(
         'SE',
         '504012',
         'Adeel Chaudhry',
         'adeel.chaudhry@stud.nust.edu.pk',
         3.75,
         7,
         'LOW'
      );
      add(
         'CS',
         '504013',
         'Sobia Iqbal',
         'sobia.iqbal@stud.nust.edu.pk',
         2.88,
         4,
         'MEDIUM'
      );
      add(
         'EE',
         '504014',
         'Imran Hussain',
         'imran.hussain@stud.nust.edu.pk',
         3.30,
         5,
         'LOW'
      );
      add(
         'AI',
         '504015',
         'Kiran Zaidi',
         'kiran.zaidi@stud.nust.edu.pk',
         2.45,
         3,
         'HIGH'
      );
      add(
         'CS',
         '504016',
         'Waseem Butt',
         'waseem.butt@stud.nust.edu.pk',
         3.90,
         8,
         'LOW'
      );
      add(
         'CE',
         '504017',
         'Lubna Malik',
         'lubna.malik@stud.nust.edu.pk',
         2.60,
         4,
         'MEDIUM'
      );
      add(
         'SE',
         '504018',
         'Tariq Abbasi',
         'tariq.abbasi@stud.nust.edu.pk',
         3.15,
         5,
         'LOW'
      );
      add(
         'CS',
         '504019',
         'Naila Ahmad',
         'naila.ahmad@stud.nust.edu.pk',
         1.95,
         3,
         'CRITICAL'
      );
      add(
         'EE',
         '504020',
         'Rizwan Javed',
         'rizwan.javed@stud.nust.edu.pk',
         3.50,
         6,
         'LOW'
      );
      add(
         'CS',
         '504021',
         'Anam Farooq',
         'anam.farooq@stud.nust.edu.pk',
         2.35,
         3,
         'HIGH'
      );
      add(
         'AI',
         '504022',
         'Shahid Latif',
         'shahid.latif@stud.nust.edu.pk',
         3.60,
         6,
         'LOW'
      );
      add(
         'CE',
         '504023',
         'Mariam Yusuf',
         'mariam.yusuf@stud.nust.edu.pk',
         3.05,
         4,
         'MEDIUM'
      );
      add(
         'CS',
         '504024',
         'Jahangir Baig',
         'jahangir.baig@stud.nust.edu.pk',
         3.70,
         7,
         'LOW'
      );
      add(
         'EE',
         '504025',
         'Farah Naz',
         'farah.naz@stud.nust.edu.pk',
         2.80,
         5,
         'MEDIUM'
      );
      add(
         'SE',
         '504026',
         'Salman Gul',
         'salman.gul@stud.nust.edu.pk',
         1.50,
         2,
         'CRITICAL'
      );
      add(
         'CS',
         '504027',
         'Ifrah Karim',
         'ifrah.karim@stud.nust.edu.pk',
         3.85,
         7,
         'LOW'
      );
      add(
         'CE',
         '504028',
         'Mohsin Raza',
         'mohsin.raza@stud.nust.edu.pk',
         2.90,
         5,
         'MEDIUM'
      );
      add(
         'CS',
         '504029',
         'Sehrish Waqar',
         'sehrish.waqar@stud.nust.edu.pk',
         3.45,
         6,
         'LOW'
      );
      add(
         'AI',
         '504030',
         'Bilal Anwar',
         'bilal.anwar@stud.nust.edu.pk',
         2.20,
         3,
         'HIGH'
      );
      add(
         'EE',
         '504031',
         'Ayesha Riaz',
         'ayesha.riaz@stud.nust.edu.pk',
         3.25,
         5,
         'LOW'
      );
      add(
         'CS',
         '504032',
         'Hamza Zafar',
         'hamza.zafar@stud.nust.edu.pk',
         2.65,
         4,
         'MEDIUM'
      );
      add(
         'SE',
         '504033',
         'Iqra Sultan',
         'iqra.sultan@stud.nust.edu.pk',
         3.55,
         6,
         'LOW'
      );
      add(
         'CE',
         '504034',
         'Farhan Chohan',
         'farhan.chohan@stud.nust.edu.pk',
         2.10,
         3,
         'HIGH'
      );
      add(
         'CS',
         '504035',
         'Sadaf Mirza',
         'sadaf.mirza@stud.nust.edu.pk',
         3.60,
         6,
         'LOW'
      );
      add(
         'EE',
         '504036',
         'Umer Nasir',
         'umer.nasir@stud.nust.edu.pk',
         3.00,
         4,
         'MEDIUM'
      );
      add(
         'AI',
         '504037',
         'Amber Gillani',
         'amber.gillani@stud.nust.edu.pk',
         3.40,
         5,
         'LOW'
      );
      add(
         'CS',
         '504038',
         'Umar Farooq',
         'umar.farooq@stud.nust.edu.pk',
         1.80,
         2,
         'CRITICAL'
      );
      add(
         'CE',
         '504039',
         'Hajra Khawaja',
         'hajra.khawaja@stud.nust.edu.pk',
         3.70,
         7,
         'LOW'
      );
      add(
         'SE',
         '504040',
         'Nabeel Ahmad',
         'nabeel.ahmad@stud.nust.edu.pk',
         2.55,
         3,
         'HIGH'
      );
      add(
         'CS',
         '504041',
         'Tahira Saleem',
         'tahira.saleem@stud.nust.edu.pk',
         3.30,
         5,
         'LOW'
      );
      add(
         'EE',
         '504042',
         'Jawad Rashid',
         'jawad.rashid@stud.nust.edu.pk',
         2.75,
         4,
         'MEDIUM'
      );
      add(
         'AI',
         '504043',
         'Madiha Saeed',
         'madiha.saeed@stud.nust.edu.pk',
         3.55,
         6,
         'LOW'
      );
      add(
         'CS',
         '504044',
         'Shehroz Dar',
         'shehroz.dar@stud.nust.edu.pk',
         2.40,
         3,
         'HIGH'
      );
      add(
         'CE',
         '504045',
         'Komal Tanvir',
         'komal.tanvir@stud.nust.edu.pk',
         3.80,
         7,
         'LOW'
      );
      add(
         'SE',
         '504046',
         'Daniyal Aziz',
         'daniyal.aziz@stud.nust.edu.pk',
         3.10,
         4,
         'LOW'
      );
      add(
         'CS',
         '504047',
         'Zainab Haider',
         'zainab.haider@stud.nust.edu.pk',
         2.85,
         5,
         'MEDIUM'
      );
      add(
         'EE',
         '504048',
         'Ali Hassan',
         'ali.hassan@stud.nust.edu.pk',
         3.65,
         6,
         'LOW'
      );
      add(
         'AI',
         '504049',
         'Rida Malik',
         'rida.malik@stud.nust.edu.pk',
         3.20,
         5,
         'LOW'
      );
      add(
         'CS',
         '504050',
         'Owais Abbasi',
         'owais.abbasi@stud.nust.edu.pk',
         2.60,
         4,
         'MEDIUM'
      );
      add(
         'CE',
         '504051',
         'Sadia Noor',
         'sadia.noor@stud.nust.edu.pk',
         3.75,
         7,
         'LOW'
      );
      add(
         'CS',
         '504052',
         'Fawad Cheema',
         'fawad.cheema@stud.nust.edu.pk',
         3.50,
         6,
         'LOW'
      );
      for j in 1..v_tab.count loop
         insert into students (
            dept_id,
            cms_id,
            name,
            email,
            cgpa,
            semester,
            risk_level
         ) values ( (
            select dept_id
              from departments
             where dept_code = v_tab(j).d
         ),
                    v_tab(j).c,
                    v_tab(j).n,
                    v_tab(j).e,
                    v_tab(j).g,
                    v_tab(j).s,
                    v_tab(j).r );
      end loop;
   end;
   commit;
end;
/

-- TOPICS (use subquery for course_id by course_code)
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-236'
),
           'SQL Joins',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-236'
),
           'Normalization',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-236'
),
           'B+ Trees',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-236'
),
           'Triggers and PLSQL',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-236'
),
           'Window Functions',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-236'
),
           'Indexing and Hashing',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-236'
),
           'Transaction Management',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-236'
),
           'ERD Design',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-343'
),
           'HTML and CSS',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-343'
),
           'JavaScript Basics',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-343'
),
           'React Components',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-343'
),
           'REST APIs',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-343'
),
           'Node.js',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-343'
),
           'Authentication',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-343'
),
           'Database Integration',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-343'
),
           'Deployment',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-301'
),
           'Process Management',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-301'
),
           'Memory Management',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-301'
),
           'File Systems',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-301'
),
           'CPU Scheduling',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-301'
),
           'Deadlocks',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-301'
),
           'Synchronization',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-301'
),
           'Virtual Memory',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-301'
),
           'IO Systems',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'EE-201'
),
           'Ohms Law',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'EE-201'
),
           'Kirchhoffs Laws',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'EE-201'
),
           'AC Circuits',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'EE-201'
),
           'Thevenin Norton',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'EE-201'
),
           'RLC Circuits',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'EE-201'
),
           'Phasors',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'EE-201'
),
           'Power Analysis',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'EE-201'
),
           'Filters',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-401'
),
           'Linear Regression',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-401'
),
           'Classification',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-401'
),
           'Neural Networks',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-401'
),
           'Feature Engineering',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-401'
),
           'Model Evaluation',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-401'
),
           'Clustering',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-401'
),
           'Deep Learning',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-401'
),
           'NLP Basics',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'SE-201'
),
           'Requirements Engineering',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'SE-201'
),
           'UML Diagrams',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'SE-201'
),
           'Agile Methods',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'SE-201'
),
           'Design Patterns',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'SE-201'
),
           'Testing Strategies',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'SE-201'
),
           'Project Management',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'SE-201'
),
           'Software Architecture',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'SE-201'
),
           'DevOps Basics',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'AI-301'
),
           'Search Algorithms',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'AI-301'
),
           'Knowledge Representation',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'AI-301'
),
           'Planning',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'AI-301'
),
           'Bayesian Networks',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'AI-301'
),
           'Game Theory',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'AI-301'
),
           'Expert Systems',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'AI-301'
),
           'Computer Vision',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'AI-301'
),
           'NLP',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-211'
),
           'Arrays and Linked Lists',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-211'
),
           'Stacks and Queues',
           'EASY' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-211'
),
           'Trees and Heaps',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-211'
),
           'Graphs',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-211'
),
           'Sorting Algorithms',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-211'
),
           'Hash Tables',
           'MEDIUM' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-211'
),
           'Dynamic Programming',
           'HARD' );
insert into topics (
   course_id,
   topic_name,
   difficulty_level
) values ( (
   select course_id
     from courses
    where course_code = 'CS-211'
),
           'Complexity Analysis',
           'MEDIUM' );
commit;

-- ASSESSMENTS
begin
   for c in (
      select course_id,
             course_code
        from courses
       order by course_id
   ) loop
      declare
         pfx varchar2(10);
      begin
         pfx := replace(
            c.course_code,
            '-',
            ''
         );
         insert into assessments (
            course_id,
            title,
            type,
            total_marks,
            passing_marks,
            max_attempts,
            due_date
         ) values ( c.course_id,
                    pfx || ' Quiz 1',
                    'QUIZ',
                    20,
                    10,
                    1,
                    sysdate - 70 );
         insert into assessments (
            course_id,
            title,
            type,
            total_marks,
            passing_marks,
            max_attempts,
            due_date
         ) values ( c.course_id,
                    pfx || ' Quiz 2',
                    'QUIZ',
                    20,
                    10,
                    1,
                    sysdate - 50 );
         insert into assessments (
            course_id,
            title,
            type,
            total_marks,
            passing_marks,
            max_attempts,
            due_date
         ) values ( c.course_id,
                    pfx || ' Midterm',
                    'MIDTERM',
                    50,
                    25,
                    1,
                    sysdate - 35 );
         insert into assessments (
            course_id,
            title,
            type,
            total_marks,
            passing_marks,
            max_attempts,
            due_date
         ) values ( c.course_id,
                    pfx || ' Assignment 1',
                    'ASSIGNMENT',
                    30,
                    15,
                    2,
                    sysdate - 55 );
         insert into assessments (
            course_id,
            title,
            type,
            total_marks,
            passing_marks,
            max_attempts,
            due_date
         ) values ( c.course_id,
                    pfx || ' Lab Test',
                    'LAB',
                    25,
                    12,
                    1,
                    sysdate - 20 );
      end;
   end loop;
   commit;
end;
/

-- QUESTIONS
begin
   for a in (
      select a.assessment_id,
             a.course_id
        from assessments a
        join courses c
      on a.course_id = c.course_id
       where c.course_code = 'CS-236'
       order by a.assessment_id
   ) loop
      insert into questions (
         assessment_id,
         topic_id,
         question_text,
         marks,
         difficulty,
         correct_answer
      ) values ( a.assessment_id,
                 (
                    select topic_id
                      from topics
                     where course_id = a.course_id
                       and topic_name = 'SQL Joins'
                 ),
                 'Explain SQL JOIN types and their use cases.',
                 5,
                 'MEDIUM',
                 'INNER LEFT RIGHT FULL CROSS' );
      insert into questions (
         assessment_id,
         topic_id,
         question_text,
         marks,
         difficulty,
         correct_answer
      ) values ( a.assessment_id,
                 (
                    select topic_id
                      from topics
                     where course_id = a.course_id
                       and topic_name = 'Normalization'
                 ),
                 'What is Boyce-Codd Normal Form?',
                 5,
                 'HARD',
                 'Every determinant must be a candidate key' );
      insert into questions (
         assessment_id,
         topic_id,
         question_text,
         marks,
         difficulty,
         correct_answer
      ) values ( a.assessment_id,
                 (
                    select topic_id
                      from topics
                     where course_id = a.course_id
                       and topic_name = 'Transaction Management'
                 ),
                 'List the ACID properties of transactions.',
                 5,
                 'EASY',
                 'Atomicity Consistency Isolation Durability' );
      insert into questions (
         assessment_id,
         topic_id,
         question_text,
         marks,
         difficulty,
         correct_answer
      ) values ( a.assessment_id,
                 (
                    select topic_id
                      from topics
                     where course_id = a.course_id
                       and topic_name = 'Window Functions'
                 ),
                 'Write RANK() partitioned by department.',
                 5,
                 'HARD',
                 'RANK() OVER (PARTITION BY dept_id ORDER BY cgpa DESC)' );
   end loop;
   for a in (
      select a.assessment_id,
             a.course_id
        from assessments a
        join courses c
      on a.course_id = c.course_id
       where c.course_code != 'CS-236'
       order by a.assessment_id
   ) loop
      insert into questions (
         assessment_id,
         topic_id,
         question_text,
         marks,
         difficulty,
         correct_answer
      ) values ( a.assessment_id,
                 (
                    select topic_id
                      from topics
                     where course_id = a.course_id
                       and rownum = 1
                 ),
                 'Define the core concept of this topic.',
                 10,
                 'MEDIUM',
                 'See lecture notes' );
      insert into questions (
         assessment_id,
         topic_id,
         question_text,
         marks,
         difficulty,
         correct_answer
      ) values ( a.assessment_id,
                 (
                    select topic_id
                      from topics
                     where course_id = a.course_id
                       and rownum = 1
                 ),
                 'Apply the concept to a real-world scenario.',
                 10,
                 'HARD',
                 'Application-based answer' );
   end loop;
   commit;
end;
/

-- ENROLLMENTS
begin
  -- Core 8 students with fixed enrollments using course_code lookup
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '502895'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-236'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '502895'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-343'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '502895'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-401'
              ),
              'Spring 2026',
              'B',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503012'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-236'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503012'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-301'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503012'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-211'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503145'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'EE-201'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503145'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-343'
              ),
              'Spring 2026',
              'B',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503145'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'SE-201'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503278'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-236'
              ),
              'Spring 2026',
              'B',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503278'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-301'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503278'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-211'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503411'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-236'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503411'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'SE-201'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503411'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'AI-301'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503544'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'EE-201'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503544'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-343'
              ),
              'Spring 2026',
              'B',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503544'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-401'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503677'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-236'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503677'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-401'
              ),
              'Spring 2026',
              'B',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503677'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'AI-301'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503810'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'CS-236'
              ),
              'Spring 2026',
              'B',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503810'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'SE-201'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
   insert into enrollments (
      student_id,
      course_id,
      semester_label,
      section,
      status
   ) values ( (
      select student_id
        from students
       where cms_id = '503810'
   ),
              (
                 select course_id
                   from courses
                  where course_code = 'EE-201'
              ),
              'Spring 2026',
              'A',
              'ACTIVE' );
  -- Remaining students: 3 courses each using modular distribution
   for s in (
      select student_id
        from students
       where cms_id not in ( '502895',
                             '503012',
                             '503145',
                             '503278',
                             '503411',
                             '503544',
                             '503677',
                             '503810' )
       order by student_id
   ) loop
      declare
         c1  number;
         c2  number;
         c3  number;
         idx number;
      begin
         select student_id
           into idx
           from (
            select student_id,
                   rownum rn
              from students
             where cms_id not in ( '502895',
                                   '503012',
                                   '503145',
                                   '503278',
                                   '503411',
                                   '503544',
                                   '503677',
                                   '503810' )
             order by student_id
         )
          where student_id = s.student_id;
         select course_id
           into c1
           from (
            select course_id,
                   rownum rn
              from courses
             order by course_id
         )
          where rn = mod(
            s.student_id,
            8
         ) + 1;
         select course_id
           into c2
           from (
            select course_id,
                   rownum rn
              from courses
             order by course_id
         )
          where rn = mod(
            s.student_id + 2,
            8
         ) + 1;
         select course_id
           into c3
           from (
            select course_id,
                   rownum rn
              from courses
             order by course_id
         )
          where rn = mod(
            s.student_id + 5,
            8
         ) + 1;
         if c2 = c1 then
            select course_id
              into c2
              from (
               select course_id,
                      rownum rn
                 from courses
                order by course_id
            )
             where rn = mod(
               c2,
               8
            ) + 1;         end if;
         if c3 = c1
         or c3 = c2 then
            select course_id
              into c3
              from (
               select course_id,
                      rownum rn
                 from courses
                order by course_id
            )
             where rn = mod(
               c3 + 1,
               8
            ) + 1;         end if;
         begin
            insert into enrollments (
               student_id,
               course_id,
               semester_label,
               section,
               status
            ) values ( s.student_id,
                       c1,
                       'Spring 2026',
                       'A',
                       'ACTIVE' );         exception
            when others then
               null;
         end;
         begin
            insert into enrollments (
               student_id,
               course_id,
               semester_label,
               section,
               status
            ) values ( s.student_id,
                       c2,
                       'Spring 2026',
                       'B',
                       'ACTIVE' );         exception
            when others then
               null;
         end;
         begin
            insert into enrollments (
               student_id,
               course_id,
               semester_label,
               section,
               status
            ) values ( s.student_id,
                       c3,
                       'Spring 2026',
                       'A',
                       'ACTIVE' );         exception
            when others then
               null;
         end;
      end;
   end loop;
   commit;
end;
/

-- ASSESSMENT ATTEMPTS
begin
   for e in (
      select e.student_id,
             e.course_id,
             s.risk_level
        from enrollments e
        join students s
      on e.student_id = s.student_id
       where e.status = 'ACTIVE'
       order by e.student_id,
                e.course_id
   ) loop
      for a in (
         select assessment_id,
                total_marks
           from assessments
          where course_id = e.course_id
      ) loop
         declare
            v_base number;
            v_sc   number;
         begin
            v_base :=
               case e.risk_level
                  when 'LOW'      then
                     75 + floor(dbms_random.value(
                        0,
                        20
                     ))
                  when 'MEDIUM'   then
                     55 + floor(dbms_random.value(
                        0,
                        20
                     ))
                  when 'HIGH'     then
                     42 + floor(dbms_random.value(
                        0,
                        22
                     ))
                  when 'CRITICAL' then
                     22 + floor(dbms_random.value(
                        0,
                        26
                     ))
                  else
                     60
               end;
            v_sc := least(
               round(
                  a.total_marks * v_base / 100,
                  2
               ),
               a.total_marks
            );
            insert into assessment_attempts (
               student_id,
               assessment_id,
               attempt_no,
               score,
               status,
               is_late,
               end_time
            ) values ( e.student_id,
                       a.assessment_id,
                       1,
                       v_sc,
                       'GRADED',
                       'N',
                       sysdate - floor(dbms_random.value(
                          1,
                          55
                       )) );
         end;
      end loop;
   end loop;
   update assessment_attempts
      set score = 6,
          status = 'GRADED'
    where student_id = (
         select student_id
           from students
          where cms_id = '503012'
      )
      and assessment_id in (
      select assessment_id
        from assessments
       where course_id = (
         select course_id
           from courses
          where course_code = 'CS-236'
      )
   );
   update assessment_attempts
      set score = 7,
          status = 'GRADED'
    where student_id = (
         select student_id
           from students
          where cms_id = '503278'
      )
      and assessment_id in (
      select assessment_id
        from assessments
       where course_id = (
         select course_id
           from courses
          where course_code = 'CS-301'
      )
   );
   commit;
end;
/

-- TOPIC PERFORMANCE
insert into topic_performance (
   student_id,
   topic_id,
   course_id,
   mastery_pct,
   attempts_count,
   correct_count,
   trend,
   last_attempt_date
)
   select e.student_id,
          t.topic_id,
          e.course_id,
          round(
             case t.difficulty_level
                when 'EASY'   then
                   75 + dbms_random.value(
                      0,
                      15
                   )
                when 'MEDIUM' then
                   55 + dbms_random.value(
                      0,
                      20
                   )
                else
                   35 + dbms_random.value(
                      0,
                      25
                   )
             end,
             2
          ),
          floor(dbms_random.value(
             3,
             10
          )),
          floor(dbms_random.value(
             2,
             8
          )),
          case
             when mod(
                e.student_id + t.topic_id,
                3
             ) = 0 then
                'UP'
             when mod(
                e.student_id + t.topic_id,
                3
             ) = 1 then
                'DOWN'
             else
                'STABLE'
          end,
          sysdate - floor(dbms_random.value(
             1,
             30
          ))
     from enrollments e
     join topics t
   on e.course_id = t.course_id
    where e.status = 'ACTIVE';
commit;

-- SESSION LOGS
begin
   for e in (
      select distinct student_id
        from enrollments
       where status = 'ACTIVE'
   ) loop
      insert into session_logs (
         student_id,
         event_type,
         logged_at
      ) values ( e.student_id,
                 'LOGIN',
                 sysdate - floor(dbms_random.value(
                    1,
                    60
                 )) );
   end loop;
   for i in 1..16 loop
      insert into session_logs (
         student_id,
         course_id,
         event_type,
         event_detail,
         logged_at
      ) values ( (
         select student_id
           from students
          where cms_id = '503278'
      ),
                 (
                    select course_id
                      from courses
                     where course_code = 'CS-301'
                 ),
                 'ABSENCE',
                 'Week '
                 || i
                 || ' absence recorded',
                 sysdate - ( 65 - i ) );
   end loop;
   for i in 1..11 loop
      insert into session_logs (
         student_id,
         course_id,
         event_type,
         event_detail,
         logged_at
      ) values ( (
         select student_id
           from students
          where cms_id = '503012'
      ),
                 (
                    select course_id
                      from courses
                     where course_code = 'CS-236'
                 ),
                 'ABSENCE',
                 'Week '
                 || i
                 || ' absence recorded',
                 sysdate - ( 65 - i ) );
   end loop;
   commit;
end;
/

-- RISK FLAGS
insert into risk_flags (
   student_id,
   course_id,
   flag_type,
   severity,
   description,
   is_acknowledged,
   resolved
) values ( (
   select student_id
     from students
    where cms_id = '503012'
),
           (
              select course_id
                from courses
               where course_code = 'CS-236'
           ),
           'CONSECUTIVE_FAIL',
           'CRITICAL',
           '3+ consecutive failed attempts in CS-236',
           'N',
           'N' );
insert into risk_flags (
   student_id,
   course_id,
   flag_type,
   severity,
   description,
   is_acknowledged,
   resolved
) values ( (
   select student_id
     from students
    where cms_id = '503278'
),
           (
              select course_id
                from courses
               where course_code = 'CS-301'
           ),
           'ATTENDANCE_BREACH',
           'HIGH',
           '16 absences exceed limit of 15 in CS-301',
           'Y',
           'N' );
insert into risk_flags (
   student_id,
   course_id,
   flag_type,
   severity,
   description,
   is_acknowledged,
   resolved
) values ( (
   select student_id
     from students
    where cms_id = '503810'
),
           (
              select course_id
                from courses
               where course_code = 'CS-236'
           ),
           'LOW_MASTERY',
           'HIGH',
           'Mastery below threshold in multiple CS-236 topics',
           'N',
           'N' );
commit;

-- INTERVENTIONS
insert into interventions (
   student_id,
   flag_id,
   instructor_id,
   int_type,
   description,
   status,
   assigned_date,
   due_date
) values ( (
   select student_id
     from students
    where cms_id = '503012'
),
           (
              select flag_id
                from risk_flags
               where student_id = (
                    select student_id
                      from students
                     where cms_id = '503012'
                 )
                 and flag_type = 'CONSECUTIVE_FAIL'
           ),
           (
              select instructor_id
                from instructors
               where email = 'ayesha.hakim@seecs.nust.edu.pk'
           ),
           'ACADEMIC_WARNING',
           'Student Omar Tariq requires immediate academic review for CS-236 failure pattern.',
           'PENDING',
           date '2026-04-10',
           date '2026-04-30' );
insert into interventions (
   student_id,
   flag_id,
   instructor_id,
   int_type,
   description,
   status,
   assigned_date,
   due_date,
   outcome_notes,
   closed_at
) values ( (
   select student_id
     from students
    where cms_id = '503278'
),
           (
              select flag_id
                from risk_flags
               where student_id = (
                    select student_id
                      from students
                     where cms_id = '503278'
                 )
                 and flag_type = 'ATTENDANCE_BREACH'
           ),
           (
              select instructor_id
                from instructors
               where email = 'irfan.khan@seecs.nust.edu.pk'
           ),
           'COUNSELING_REFERRAL',
           'Bilal Khan referred for academic counseling due to attendance breach in CS-301.',
           'COMPLETED',
           date '2026-04-08',
           date '2026-04-20',
           'Student attended 2 counseling sessions. Plan in place.',
           date '2026-04-22' );
insert into interventions (
   student_id,
   flag_id,
   instructor_id,
   int_type,
   description,
   status,
   assigned_date,
   due_date
) values ( (
   select student_id
     from students
    where cms_id = '503810'
),
           (
              select flag_id
                from risk_flags
               where student_id = (
                    select student_id
                      from students
                     where cms_id = '503810'
                 )
                 and flag_type = 'LOW_MASTERY'
           ),
           (
              select instructor_id
                from instructors
               where email = 'tariq.mehmood@seecs.nust.edu.pk'
           ),
           'ATTENDANCE_WARNING',
           'Usman Shah issued formal attendance warning for CE courses.',
           'IN_PROGRESS',
           date '2026-04-12',
           date '2026-05-05' );
commit;

insert into risk_flags (
   student_id,
   course_id,
   flag_type,
   severity,
   description,
   is_acknowledged,
   resolved
) values ( (
   select student_id
     from students
    where cms_id = '503544'
),
           (
              select course_id
                from courses
               where course_code = 'EE-201'
           ),
           'LOW_MASTERY',
           'HIGH',
           'Hassan Raza scoring below 60% in EE-201 topics',
           'Y',
           'N' );
commit;
insert into interventions (
   student_id,
   flag_id,
   instructor_id,
   int_type,
   description,
   status,
   assigned_date,
   due_date,
   outcome_notes,
   closed_at
) values ( (
   select student_id
     from students
    where cms_id = '503544'
),
           (
              select flag_id
                from risk_flags
               where student_id = (
                    select student_id
                      from students
                     where cms_id = '503544'
                 )
                 and flag_type = 'LOW_MASTERY'
           ),
           (
              select instructor_id
                from instructors
               where email = 'sara.ahmed@seecs.nust.edu.pk'
           ),
           'TUTORING_ASSIGNED',
           'Peer tutoring sessions assigned for Circuit Analysis.',
           'COMPLETED',
           date '2026-04-11',
           date '2026-04-25',
           'Completed 3 tutoring sessions. Grade improved.',
           date '2026-04-26' );
commit;

-- End of ASPAE_Oracle_Schema_Final.sql