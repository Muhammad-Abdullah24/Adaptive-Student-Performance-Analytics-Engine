export const STUDENTS = [
  { id: "S001", name: "Aisha Malik",   cgpa: 3.72, risk: "low",      dept: "CS", semester: 6, absences: 2,  trend: "up"     },
  { id: "S002", name: "Omar Tariq",    cgpa: 2.41, risk: "critical",  dept: "CS", semester: 4, absences: 11, trend: "down"   },
  { id: "S003", name: "Zara Hussain",  cgpa: 3.15, risk: "medium",   dept: "EE", semester: 5, absences: 5,  trend: "stable" },
  { id: "S004", name: "Bilal Khan",    cgpa: 1.89, risk: "critical",  dept: "CS", semester: 3, absences: 16, trend: "down"   },
  { id: "S005", name: "Fatima Noor",   cgpa: 3.90, risk: "low",      dept: "CE", semester: 7, absences: 0,  trend: "up"     },
  { id: "S006", name: "Hassan Raza",   cgpa: 2.78, risk: "medium",   dept: "EE", semester: 4, absences: 7,  trend: "stable" },
  { id: "S007", name: "Sana Ijaz",     cgpa: 3.55, risk: "low",      dept: "CS", semester: 6, absences: 3,  trend: "up"     },
  { id: "S008", name: "Usman Shah",    cgpa: 2.10, risk: "high",     dept: "CE", semester: 5, absences: 9,  trend: "down"   },
];

export const COURSES = [
  { id: "CS-236", name: "Adv. Database Mgmt", students: 47, avg: 68.4, passRate: 79, instructor: "Dr. Ayesha Hakim"  },
  { id: "CS-343", name: "Web Technologies",   students: 52, avg: 74.1, passRate: 88, instructor: "Dr. Naima Iltaf"   },
  { id: "CS-301", name: "Operating Systems",  students: 44, avg: 61.2, passRate: 70, instructor: "Dr. Irfan Khan"    },
  { id: "EE-201", name: "Circuit Analysis",   students: 61, avg: 71.8, passRate: 83, instructor: "Dr. Sara Ahmed"    },
  { id: "CS-401", name: "Machine Learning",   students: 38, avg: 65.3, passRate: 73, instructor: "Dr. Zain Ul Abdin" },
];

export const TOPIC_DATA = [
  { topic: "SQL Joins",          mastery: 82, difficulty: "medium" },
  { topic: "Normalization",      mastery: 58, difficulty: "hard"   },
  { topic: "B+ Trees",           mastery: 44, difficulty: "hard"   },
  { topic: "Triggers & PL/SQL",  mastery: 71, difficulty: "medium" },
  { topic: "Window Functions",   mastery: 39, difficulty: "hard"   },
  { topic: "Indexing & Hashing", mastery: 67, difficulty: "medium" },
  { topic: "Transaction Mgmt",   mastery: 75, difficulty: "easy"   },
  { topic: "ERD Design",         mastery: 88, difficulty: "easy"   },
];

export const WEEKLY_ATTEMPTS = [
  { week: "W1", attempts: 124, avg: 63 },
  { week: "W2", attempts: 198, avg: 67 },
  { week: "W3", attempts: 176, avg: 65 },
  { week: "W4", attempts: 234, avg: 71 },
  { week: "W5", attempts: 289, avg: 74 },
  { week: "W6", attempts: 312, avg: 72 },
  { week: "W7", attempts: 267, avg: 69 },
  { week: "W8", attempts: 341, avg: 76 },
];

export const RISK_DIST = { critical: 8, high: 14, medium: 22, low: 56 };

export const INTERVENTIONS = [
  { id: 1, student: "Omar Tariq",  type: "Academic Warning",    date: "2026-04-10", status: "pending",     course: "CS-236" },
  { id: 2, student: "Bilal Khan",  type: "Counseling Referral", date: "2026-04-08", status: "completed",   course: "CS-301" },
  { id: 3, student: "Usman Shah",  type: "Attendance Warning",  date: "2026-04-12", status: "in_progress", course: "CE-301" },
  { id: 4, student: "Hassan Raza", type: "Tutoring Assigned",   date: "2026-04-11", status: "completed",   course: "EE-201" },
];

export const SESSION_LOG = [
  { time: "09:14", student: "Fatima Noor",  event: "Submitted Quiz 4 — Score: 94/100",                 type: "success" },
  { time: "09:22", student: "Omar Tariq",   event: "3rd consecutive failed attempt — RISK FLAG raised", type: "danger"  },
  { time: "09:31", student: "Aisha Malik",  event: "Topic mastery threshold reached: SQL Joins",        type: "success" },
  { time: "09:45", student: "Bilal Khan",   event: "Absence recorded — total: 16 (limit: 15)",          type: "danger"  },
  { time: "10:02", student: "Zara Hussain", event: "Assignment submission: 2 days late",                type: "warning" },
  { time: "10:18", student: "Hassan Raza",  event: "Session started: Week 8 materials",                 type: "info"    },
  { time: "10:33", student: "Sana Ijaz",    event: "Perfect score — Transactions Quiz: 100/100",        type: "success" },
];
