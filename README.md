# ASPAE — Adaptive Student Performance Analytics Engine
**CS-236 ADBMS Project | NUST-SEECS | Spring 2026**
Muhammad Abdullah (502895) · Muhammad Umer Farooq (508162)

---

## Project Structure

```
aspae/
├── frontend/               ← React app (create-react-app)
│   ├── public/
│   │   └── index.html
│   └── src/
│       ├── App.js          ← Root component, page routing
│       ├── index.js        ← React entry point
│       ├── data/
│       │   ├── colors.js   ← Color constants
│       │   └── mockData.js ← Static demo data
│       ├── components/
│       │   ├── Sidebar.jsx ← Navigation sidebar with live clock
│       │   ├── Topbar.jsx  ← Top header bar
│       │   └── UI.jsx      ← Reusable: Badge, MiniBar, StatCard, BarChart, RiskGauge
│       └── pages/
│           ├── OverviewPage.jsx      ← Stats, risk gauge, topic mastery, live log
│           ├── StudentsPage.jsx      ← Searchable table, detail panel, risk filter
│           ├── CoursesPage.jsx       ← Pass rate donuts, class averages
│           ├── AnalyticsPage.jsx     ← Window fn, correlated subquery, CTE visuals
│           ├── InterventionsPage.jsx ← Tracker + DB context explanation
│           └── DatabasePage.jsx      ← Schema, procedures, triggers, SQL queries
│
└── backend/                ← Node.js + Express REST API
    ├── server.js           ← Entry point, middleware, route mounting
    ├── .env.example        ← Copy to .env and add your Oracle credentials
    ├── db/
    │   └── connection.js   ← Oracle connection pool (oracledb)
    └── routes/
        ├── students.js     ← GET /api/students, POST /api/students/enroll
        ├── courses.js      ← GET /api/courses, GET /api/courses/:code/students
        ├── analytics.js    ← risk-report, topic-mastery, below-dept-avg, rolling-avg
        └── interventions.js← GET/POST /api/interventions, PATCH /:id/status
```

---

## Setup Instructions

### Prerequisites
- Node.js 18+
- Oracle 21c XE installed and running
- XEPDB1 pluggable database with ASPAE schema loaded (run ASPAE_Oracle_Schema.sql first)

---

### 1. Frontend

```bash
cd frontend
npm install
npm start
```
Runs on http://localhost:3000

---

### 2. Backend

```bash
cd backend
npm install

# Create your .env file
cp .env.example .env
# Edit .env and fill in DB_USER, DB_PASSWORD, DB_CONNECTION_STRING

npm run dev     # development (nodemon)
# or
npm start       # production
```
Runs on http://localhost:5000

Test the connection:
```
GET http://localhost:5000/api/health
```

---

## API Endpoints

| Method | Endpoint                            | Description                              |
|--------|-------------------------------------|------------------------------------------|
| GET    | /api/health                         | Health check                             |
| GET    | /api/students                       | All students (filter: ?dept=CS&risk=HIGH)|
| GET    | /api/students/:id                   | Single student with topic performance    |
| POST   | /api/students/enroll                | Enroll student (calls sp_enroll_student) |
| GET    | /api/courses                        | All courses with stats (from MV)         |
| GET    | /api/courses/:courseCode/students   | Enrolled students for a course           |
| GET    | /api/analytics/risk-report          | REF CURSOR risk report (filter: ?dept=CS)|
| GET    | /api/analytics/topic-mastery        | Topic mastery aggregates                 |
| GET    | /api/analytics/below-dept-avg       | Correlated subquery — below avg students |
| GET    | /api/analytics/rolling-avg          | CTE rolling average per student          |
| GET    | /api/interventions                  | All interventions with student info      |
| POST   | /api/interventions                  | Create new intervention                  |
| PATCH  | /api/interventions/:id/status       | Update intervention status               |

---

## Database Notes

- Run `ASPAE_Oracle_Schema.sql` on Oracle 21c XE (XEPDB1) before starting backend
- Run `ASPAE_MySQL_Reporting.sql` on MySQL 8.0 for the reporting layer
- Always `SET SERVEROUTPUT ON` in SQL Developer sessions
- The frontend currently runs with mock data — wire up `fetch()` calls to the backend API to go fully live
