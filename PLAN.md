# Comprehensive SQL Portfolio Plan — Beginner to Expert

**Owner:** Muhammed Ajetayo Abdulazeez
**Start date:** 2026-07-27 | **Reference pace:** 8 weeks (self-paced — same as the Power BI portfolio, where 8-week phases were often cleared in 2)
**Engine:** PostgreSQL, installed locally (server only, no pgAdmin — ~300-400MB, growing to ~1-1.5GB with data by the capstone). Switched from the original cloud-Neon plan on 2026-07-28 after freeing ~2.3GB of Downloads clutter (6.82GB → 9.15GB free), giving enough headroom for a local install.
**Goal:** One comprehensive, published SQL project proving Beginner → Expert range (querying → joins → window functions → schema design → performance tuning → transactions/procedures → a full analytics capstone), with progress tracked on GitHub, a DataLemur practice profile, a new page on the existing Google Site, and 2 LinkedIn posts.

---

## Phase 0: Setup (Day 1)

**Tasks**
- Install PostgreSQL locally — server only, skip pgAdmin/Stack Builder in the installer to keep footprint lean (use VS Code + SQLTools as the client instead)
- Install VS Code extensions: **SQLTools** + **SQLTools PostgreSQL/CockroachDB Driver** (a few MB)
- Connect VS Code to `localhost` (default port 5432), confirm `SELECT version();` returns a result
- Create GitHub repo: `sql-comprehensive-portfolio` (one repo, one folder per module — this is a skill-ladder project, not 3 separate domain projects like the Power BI portfolio)
- Create free DataLemur account (public profile URL) — this is the "practice platform" progress tracker running in parallel to the project itself
- Load Chinook sample database locally (single `.sql` script, run once via VS Code/SQLTools) — used for Modules 1–3
- Add a new "SQL" page to the existing Google Site (alongside Healthcare/Finance/Energy)

**CTA (do this now):** Get PostgreSQL installed and Chinook loaded today — everything else depends on having a live local database to query against.

**KPIs**
- [ ] `SELECT version();` returns a result in VS Code via SQLTools
- [ ] Chinook tables visible locally (11 tables, e.g. `Track`, `Invoice`, `Customer`)
- [ ] GitHub repo created with empty module folders
- [ ] DataLemur profile created

---

## Phase 1: Beginner — SQL Fundamentals (Week 1)

**Tasks**
- `SELECT`, `WHERE`, `ORDER BY`, `DISTINCT`, `LIMIT`/`OFFSET`
- Data types, `NULL` handling (`IS NULL`, `COALESCE`, `NULLIF`)
- Aggregates: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`
- `GROUP BY` / `HAVING` vs `WHERE` (the classic beginner trip-up: filter rows before grouping, filter groups after)
- String functions (`CONCAT`, `LOWER/UPPER`, `TRIM`, `LIKE`/`ILIKE`), date functions (`DATE_TRUNC`, `EXTRACT`, `AGE`)
- Practice: 15–20 DataLemur/LeetCode-style easy questions against Chinook

**CTA:** Write every query as a saved `.sql` file in `01-Fundamentals/` as you go — don't just run-and-discard in a scratch tab. This becomes your GitHub commit history and proof of range later.

**KPIs**
- [x] ≥20 fundamentals queries saved in `01-Fundamentals/queries.sql` (or one file per topic) — 22 queries saved as of 2026-08-05
- [x] Can explain, in your own words, why `HAVING` exists when `WHERE` already filters — demonstrated across MASTER-GUIDE Entries #2–#3
- [ ] ≥10 DataLemur easy questions solved (profile shows it publicly) — 7/10 as of 2026-08-24 (plus 2 "Ace the Data Science Interview" questions solved 2026-08-23, tracked separately — different platform, doesn't count toward this DataLemur-profile-specific KPI)
- [x] First GitHub commit pushed (plain `git commit -m "..."`, no co-author trailer)

---

## Phase 2: Intermediate — Joins & Set Operations (Week 2)

**Tasks**
- `INNER`, `LEFT`, `RIGHT`, `FULL OUTER`, `CROSS`, and self joins
- Multi-table joins (3+ tables) against Chinook (e.g. Customer → Invoice → InvoiceLine → Track → Album → Artist)
- `UNION` / `UNION ALL` / `INTERSECT` / `EXCEPT`
- Subqueries: scalar, correlated, `IN`/`EXISTS`/`NOT EXISTS`
- Common bug to deliberately hit and fix once: a join that silently fans out row counts (many-to-many without aggregation) — worth understanding this failure mode early since it's the #1 source of "why is my SUM wrong" bugs

**CTA:** Build one multi-table query chaining 4+ tables from scratch without looking up syntax — this is the week's real fluency test.

**KPIs**
- [ ] ≥15 join/subquery queries saved in `02-Joins-SetOps/`
- [ ] One deliberately-broken-then-fixed fan-out example documented (before/after row counts) — good interview story material
- [ ] ≥10 more DataLemur/LeetCode medium questions solved
- [ ] Module committed to GitHub

---

## Phase 3: Intermediate-Advanced — Window Functions & CTEs (Week 3)

**Tasks**
- `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE`
- `LAG`/`LEAD` (e.g. month-over-month change in sales)
- Running totals and moving averages (`SUM() OVER (ORDER BY ... ROWS BETWEEN ...)`)
- Basic CTEs (`WITH ... AS`), then a recursive CTE (e.g. employee-manager hierarchy if Chinook's `Employee` table has `ReportsTo`, or a generated date series)
- Rewrite 3 of your Phase 2 subqueries as CTEs to compare readability

**CTA:** This module is the real "am I past beginner" checkpoint — don't rush it. Build the running-total query and the recursive CTE by hand before checking references.

**KPIs**
- [ ] Top-N-per-group query working (e.g. top 3 best-selling tracks per genre) using `RANK()`/`ROW_NUMBER()` + a filtering CTE
- [ ] Running total and month-over-month `LAG` query both validated against a manual spot-check
- [ ] One working recursive CTE
- [ ] ≥10 window-function DataLemur/LeetCode questions solved
- [ ] Module committed to GitHub

---

## Phase 4: Advanced — Database Design From Scratch (Week 4)

**Tasks**
- Design your own schema (not given data this time — you design it): recommended theme is a **Job Application Tracker** (companies, roles, applications, interview stages, contacts) — genuinely useful to you right now, and "I built the database I use to run my own job search" is a strong interview story
- Sketch the ER diagram first (paper, draw.io, or dbdiagram.io — free, no install)
- Apply normalization: identify 1NF/2NF/3NF violations in a deliberately-bad first draft, then fix them
- Write the DDL: `CREATE TABLE` with primary keys, foreign keys, `NOT NULL`, `CHECK`, `UNIQUE`, `DEFAULT`
- Seed it with your own real (or realistic fake) data via `INSERT`

**CTA:** Draw the ER diagram before writing a single `CREATE TABLE` — designing on paper first is the actual skill being tested here, not the DDL syntax.

**KPIs**
- [ ] ER diagram image saved in `04-Database-Design/`
- [ ] Schema in 3NF, documented with a one-paragraph note on what was fixed from the bad first draft
- [ ] ≥5 tables, correct PK/FK relationships, at least one `CHECK` constraint
- [ ] Seeded with ≥30 realistic rows across tables
- [ ] Module committed to GitHub

---

## Phase 5: Advanced — Query Performance & Optimization (Week 5)

**Tasks**
- `EXPLAIN` / `EXPLAIN ANALYZE` — read a query plan, identify a sequential scan vs index scan
- Create indexes (single-column, composite) on the Job Tracker schema and on a larger Chinook query; measure before/after
- Understand when an index does *not* help (low-cardinality columns, small tables)
- Query rewriting: turn a correlated subquery into a join or CTE and compare plans

**CTA:** This is the same muscle as your Power BI performance-tuning chapter (Finance project, Performance Analyzer before/after) — get a real before/after number, don't estimate it.

**KPIs**
- [ ] `EXPLAIN ANALYZE` output captured (screenshot or pasted text) before and after adding an index
- [ ] Documented % improvement on at least one query
- [ ] One example of a query where indexing did *not* help, with an honest explanation why (mirrors the "aggregation table didn't speed up visuals" honest finding from the Finance project)
- [ ] Module committed to GitHub

---

## Phase 6: Expert — Transactions, Views, Functions (Week 6)

**Tasks**
- Transactions: `BEGIN`/`COMMIT`/`ROLLBACK`, and why (demonstrate an operation that must be all-or-nothing on the Job Tracker schema, e.g. moving an application between stages + logging the change)
- Views vs materialized views — build one of each
- A PL/pgSQL function (e.g. a function that returns application-to-interview conversion rate)
- A trigger (e.g. auto-update a `last_updated` timestamp on row change)

**CTA:** Build the transaction demo first — deliberately trigger a failure mid-transaction and show the rollback protects data integrity. That's the whole point of this module.

**KPIs**
- [ ] One working transaction demo with a deliberate rollback
- [ ] One view + one materialized view, both queried and compared
- [ ] One PL/pgSQL function callable and returning correct output
- [ ] One trigger tested end-to-end
- [ ] Module committed to GitHub

---

## Phase 7: Expert Capstone — E-Commerce Analytics (Weeks 7–8)

**Tasks**
- Load the **Olist Brazilian E-Commerce** dataset (Kaggle, free, ~100K orders across 9 relational tables — customers, orders, order items, payments, reviews, products, sellers, geolocation)
- Design/confirm the relational model on load (this dataset is already fairly normalized — good contrast to the Job Tracker schema you designed yourself)
- Write 20–30 business-question queries spanning everything from Modules 1–6: e.g. monthly revenue trend, repeat-customer rate, RFM-style customer segmentation (window functions + CTEs), late-delivery rate by seller/region, top categories by revenue and by review score, cohort retention by first-order month
- Apply Module 5's performance lessons: `EXPLAIN ANALYZE` the 2–3 slowest queries, add indexes, document before/after
- Optional full-circle idea (not required): this dataset could later become a 4th Power BI dashboard — connect Power BI directly to the local Postgres database instead of a CSV, closing the loop between your SQL and BI skills

**CTA:** Pick 5 business questions on Day 1 of this phase and write them down before touching SQL — designing the questions is as much the skill as answering them.

**KPIs**
- [ ] Olist dataset fully loaded, relationships verified (row counts spot-checked against Kaggle's documented totals)
- [ ] ≥20 business-question queries written and validated, saved in `07-Capstone-Ecommerce-Analytics/`
- [ ] ≥1 window-function-based analysis (RFM or cohort retention)
- [ ] ≥1 documented performance improvement (before/after `EXPLAIN ANALYZE`)
- [ ] README for the capstone: problem framing, schema diagram, 5 key findings, performance notes
- [ ] Capstone pushed to GitHub

---

## Phase 8: Publish & Promote

**Tasks**
1. Write the top-level repo README: skill-ladder table of contents linking every module folder, with the capstone as the flagship
2. Google Site: finish the new "SQL" page — capstone write-up (Problem → Schema → Key Queries → Findings → Performance), GitHub link, DataLemur profile link
3. LinkedIn — 2 posts (fewer than the 3-per-project Power BI cadence, since this is one project, not three):
   - Post 1, mid-project: a window-function or query-performance "before/after" win (visually simple, high engagement — screenshots of `EXPLAIN ANALYZE` numbers work well)
   - Post 2, on completion: capstone findings + full portfolio recap linking all 4 projects now (3 Power BI dashboards + this SQL project) as one cohesive "self-taught data analyst" story
4. Optional: a short Dev.to/Medium write-up on the RFM or cohort-retention capstone query — same SEO logic as the Power BI project's optional Medium post idea

**CTA:** Post LinkedIn #1 as soon as Phase 5's before/after numbers exist — don't wait for full completion to start showing progress.

**KPIs**
- [ ] Repo README complete with module-by-module links
- [ ] Google Site "SQL" page live
- [ ] DataLemur profile linked from both GitHub README and Google Site
- [ ] 2 LinkedIn posts published
- [ ] Portfolio now shows 4 total projects (3 Power BI + 1 SQL) cross-linked

---

## Weekly rhythm (same as Power BI project — adjust freely, pace is self-set)
- **Start of session:** pick the next unchecked KPI block
- **Mid-session:** commit progress to GitHub (even WIP) — plain `git commit -m "..."`, no co-author trailer
- **End of session:** tick KPIs, note blockers, update progress log

## Risk register
| Risk | Phase | Mitigation |
|---|---|---|
| Local disk space runs low again | any | Check free space before Phase 7 (Olist load); PostgreSQL data dir lives under its install path, not Documents |
| Recursive CTE / window function conceptual difficulty | 3 | Build by hand before checking references; this phase is deliberately not rushed |
| Olist dataset size on local install | 7 | ~100K rows is small for Postgres even locally (well under 1GB with indexes); not expected to be an issue |
| Scope creep on capstone business questions | 7 | Cap at 30 queries; depth over breadth |
