# SQL Quick Reference

A running lookup table of every operator/function actually used in the [[SQL-Portfolio-Project]] so far. Unlike `MASTER-GUIDE.md` (which tells the story of each mistake and fix), this file is pure definition — what it does, every form it's been used in here, and what it can't do.

New sections get added only after a concept has actually been practiced in a real query, not before.

---

## Index

| # | Category | Item |
|---|----------|------|
| 1 | NULL Handling | `COALESCE` |
| 2 | NULL Handling | `CASE WHEN ... END` |
| 3 | String Function | `CONCAT` |
| 4 | String Operator | `LIKE` |
| 5 | String Operator | `ILIKE` |
| 6 | Comparison Operator | `IS NULL` / `IS NOT NULL` |
| 7 | Wildcard Reference | `%` and `_` placement, all four shapes |
| 8 | String Function | `TRIM` |
| 9 | Date Function | `EXTRACT` |
| 10 | Aggregate Function | `COUNT` |
| 11 | Clause | `ORDER BY` |
| 12 | Clause | `HAVING` |
| 13 | Date Function | `AGE` |
| 14 | Literal / Data Type | `INTERVAL` |
| 15 | Comparison Operator | `IN` |
| 16 | JOIN Type | `LEFT JOIN` |
| 17 | Aggregate Function | `MIN` / `MAX` |
| 18 | Operator | `::` (cast) |
| 19 | Clause | `LIMIT` |
| 20 | Clause | `WITH ... AS (...)` (CTE) |
| 21 | Clause | `GROUP BY` |
| 22 | Clause | `JOIN ... ON` (condition correctness) |
| 23 | Function | `ROUND` |

---

## 1. `COALESCE(column, fallback)` — NULL Handling

**What it does:** Returns the first non-NULL value in its argument list, left to right. With two arguments, it substitutes `fallback` only for rows where `column` is NULL — every other row keeps its own value.

**Form used so far:**
```sql
select first_name,last_name, coalesce(company, 'Independent') as company
from customer;
```
Substitutes `'Independent'` wherever `company` is NULL, leaves the real company name everywhere else. No rows are removed — same row count in and out.

**Other forms it supports (not yet used here):**
- More than two arguments: `COALESCE(a, b, c, 'default')` — walks the list, returns the first non-NULL.
- Can wrap a column from a JOINed table the same way.

**What it can't do:**
- It's not a filter. It never removes rows — if you want to *exclude* NULL rows instead of substituting a value, you need `WHERE column IS NULL` (or `IS NOT NULL`) instead.
- Doesn't fix "blank but not NULL" values — an empty string `''` or a string of spaces `'   '` is not NULL, so `COALESCE` will pass it straight through un-replaced. That needs `NULLIF` or `TRIM` combined with a NULL check (not yet covered).

---

## 2. `CASE WHEN condition THEN value ELSE value END` — NULL Handling / General Conditional

**What it does:** A general-purpose if/else for a single expression. Evaluates `WHEN` conditions top to bottom, returns the `THEN` value for the first one that's true, falls through to `ELSE` if none match. Must be closed with `END` before it can take an alias.

**Form used so far:**
```sql
Select first_name,last_name,
   Case when
  company is null then 'Independent'
  else company
  end as company_name
  from customer;
```
Same result as the `COALESCE` version above — `CASE WHEN` is the longhand way of writing what `COALESCE` does in the single-condition case.

**Other forms it supports (not yet used here):**
- Multiple `WHEN` branches: `CASE WHEN x THEN a WHEN y THEN b ELSE c END` — for more than one condition, which `COALESCE` cannot express.
- Can be used without `ELSE` (returns NULL if no branch matches) — riskier, not recommended until deliberately practiced.

**What it can't do:**
- Every `CASE` needs its own `END` — you cannot chain the alias onto the last `THEN`/`ELSE` value directly; forgetting `END` before `AS alias` is a syntax error (caught in Entry #6 of MASTER-GUIDE).
- Can't carry an alias across separate `SELECT` statements — the alias only exists inside the same statement it's defined in.

---

## 3. `CONCAT(value1, value2, ...)` — String Function

**What it does:** Joins two or more string values into one, in the order given. Does not insert spaces or separators automatically — every separator (including a literal space) must be passed in as its own argument.

**Form used so far:**
```sql
select concat (first_name,' ',last_name)
from customer
where email like '%gmail.com%';
```
`' '` here is a literal one-character string argument, not punctuation — it's what puts the space between first and last name in the output.

**Other forms it supports (not yet used here):**
- More than two values: `CONCAT(a, ' ', b, ', ', c)` for multi-part strings (e.g., "City, Country").
- Works with non-string columns too (numbers, dates get auto-converted to text).

**What it can't do:**
- Requires parentheses around its full argument list — `concat first_name,last_name` (no parens) is a syntax error, not a warning.
- Won't insert any separator you don't explicitly write — `CONCAT(first_name, last_name)` with no `' '` argument produces `"FrançoisTremblay"` glued together.

---

## 4. `LIKE 'pattern'` — String Operator (case-sensitive)

**What it does:** Pattern-matches a text column against a string containing wildcards. Case-sensitive — `'Gmail'` will not match `'gmail'`.

**Wildcards:**
- `%` — matches any sequence of characters (including zero characters).
- `_` — matches exactly one character.

**Forms used so far:**
```sql
where email like '%gmail.com%';   -- contains "gmail.com" anywhere
where email like '%gmail.com';    -- ends with "gmail.com"
```
Both returned the identical 8 rows here — confirmed by re-running both live — because in a real email address, the domain can only ever appear at the very end, so "ends with" and "contains" collapse to the same result for this particular column.

**Pattern shapes (general, from the practice questions):**
- `'text%'` — starts with `text`.
- `'%text'` — ends with `text`.
- `'%text%'` — contains `text` anywhere.
- `'_ext'` — exactly one character followed by `ext` (matches "text", not "ttext").

**What it can't do:**
- Case-sensitive only — `LIKE '%GMAIL%'` will *not* match `gmail.com` in this dataset. Use `ILIKE` if case shouldn't matter.
- Text literals must be single-quoted. Double-quoted strings (`"gmail.com"`) are read as **identifiers** in Postgres, not text — that raises a "column does not exist" style error, not a pattern-match failure. Confirmed directly: `IS "NULL"` and `email is gmail.com` both fail this way, for the same underlying reason (Postgres reads double quotes as identifier syntax, not string syntax).
- `LIKE`/`ILIKE` only work with an actual pattern operator — `WHERE email IS 'gmail.com'` is invalid because `IS` only ever compares against `NULL`, `TRUE`, `FALSE`, or `UNKNOWN`, never a text value.

---

## 5. `ILIKE 'pattern'` — String Operator (case-insensitive)

**What it does:** Identical to `LIKE` in every respect (same wildcards `%` and `_`, same pattern shapes) except it ignores letter case entirely — `'GMAIL'`, `'Gmail'`, and `'gmail'` all match the same rows.

**Form used so far:**
```sql
select name from artist
      where name ilike 'B%';
```
Returns every artist starting with "B" regardless of case (would also catch a lowercase-first name like "black sabbath" if one existed). Confirmed correct after an initial mix-up (twice, across two different questions) where `ILIKE` was mistakenly called the case-*sensitive* one. It's the opposite: `LIKE` = case-sensitive, `ILIKE` = case-insensitive.

**What it can't do:**
- Same limitations as `LIKE` — same quoting rules, same wildcard-only pattern matching, still can't be swapped in for `IS`/`=`.

---

## 6. `IS NULL` / `IS NOT NULL` — Comparison Operator

**What it does:** Tests whether a column's value is missing (`NULL`) or present. Unlike `=`, it works correctly with `NULL` because `NULL` isn't a value that can be equal to anything, including itself — `column = NULL` is always unknown/false, never true, which is exactly why a dedicated `IS NULL` operator exists instead of reusing `=`.

**Correct form (established in Entry #6, though the actual question needed COALESCE/CASE instead):**
```sql
where company is null;       -- keeps only rows where company is missing
where company is not null;   -- keeps only rows where company is present
```
This is a genuine, correct filter — it belongs on questions that ask "which rows are missing X," as opposed to "show every row, substituting a default for missing X" (that second phrasing is a `COALESCE`/`CASE WHEN` job, not an `IS NULL` job — see sections 1 and 2 above).

**What it can't do:**
- Never quoted — `IS "NULL"` (double quotes) is read as an identifier reference and errors out; `IS 'NULL'` (single quotes) is valid syntax but checks for the literal four-character text `"NULL"`, not the absence of a value. The keyword `NULL` is always written bare after `IS`.
- Only ever compares against `NULL`, `TRUE`, `FALSE`, or `UNKNOWN` — never a text value or number. `WHERE email IS 'gmail.com'` is invalid; that job belongs to `=` (exact match) or `LIKE`/`ILIKE` (pattern match).
- Doesn't substitute a value — it only decides whether a row survives. If the goal is "show every row, but display something else when this one is missing," use `COALESCE`/`CASE WHEN` instead.

**`ISNULL` / `NOTNULL` — one-word Postgres-only alias, now used:**
```sql
where finish_date ISNULL   -- exactly equivalent to: where finish_date IS NULL
```
Postgres documents `expr ISNULL` and `expr NOTNULL` as historical one-word equivalents of `expr IS NULL` / `expr IS NOT NULL`. Confirmed working (MASTER-GUIDE Entry #18) — same behavior as the two-word form, just non-standard SQL specific to Postgres.

**Cross-engine trap: don't confuse this with `ISNULL()` in other databases.** MySQL and SQL Server both have an `ISNULL(expr, replacement)` — a *two-argument function* that behaves like `COALESCE`, returning `replacement` when `expr` is `NULL`. Same spelling, completely different job (substitution vs. a boolean null-test), and not portable — code written with Postgres's one-word `ISNULL` operator will not mean the same thing, or may not even parse, on those other engines. Prefer `IS NULL` (two words) when portability or unambiguous reading matters.

---

## 7. Wildcard Placement Reference — `%` and `_`

**The two wildcards:**
- `%` — matches any run of characters, **including zero**. The "whatever else is here, of any length" wildcard.
- `_` — matches **exactly one** character, no more, no less. The "one specific unknown slot" wildcard — not a general stand-in for "somewhere around here."

**The four pattern shapes, translated from plain English:**

| English claim | Pattern | Example | Matches | Doesn't match |
|---|---|---|---|---|
| Starts with `B` | `'B%'` | `WHERE name ILIKE 'B%'` | "BackBeat", "Black Sabbath" | "The Beatles" (starts with "The", not "B") |
| Ends with `.com` | `'%.com'` | `WHERE email LIKE '%.com'` | "user@gmail.com" | "user@gmail.com.br" |
| Contains `gmail` | `'%gmail%'` | `WHERE email LIKE '%gmail%'` | "user@gmail.com", "gmail-support@x.com" | "user@yahoo.com" |
| Exactly one char, then `B` | `'_B'` | `WHERE code LIKE '_B'` | "AB", "xB" (exactly 2 characters total) | "Black Sabbath" (way more than 2 characters), "B" alone (needs one character before it) |

**Why `_` is the wrong tool for "starts with" (a real mistake, worth remembering):** `_B` was first reached for as a way to say "B goes here, roughly" when solving Entry #9's "starts with B" question. But `_` demands *exactly one* character in that slot and nothing else in the whole pattern — `'_B'` only ever matches 2-character strings like "AB" or "xB". It cannot match "Black Sabbath," because `_` isn't a flexible "somewhere around here" marker — it's the strictest wildcard available, pinned to one exact character. `%` is the one that means "any number of characters, including many or none" — that's what "starts with" actually needs after the anchor letter.

**Combining both wildcards is valid too (not yet used in a real question, but worth knowing):** `'_a%'` means "any one character, then a literal `a`, then anything after" — e.g. matches "bat" (`b` = the one character, `a` = literal, `t` = the rest) and "cabin" (`c` = the one character, `a` = literal, `bin` = the rest), but not "at" (nothing sits before the `a`). Useful once a pattern needs to pin down more than one position at a time.

---

## 8. `TRIM(column)` — String Function

**What it does:** Strips leading and trailing whitespace from a string, leaving the middle untouched. `TRIM('  John Lennon  ')` → `'John Lennon'`. On a string that's *only* whitespace, `TRIM('    ')` → `''` (empty string) — this is what makes it useful for catching "blank" values that are hiding as spaces rather than being genuinely empty.

**Form used so far:**
```sql
select composer from track
where composer is null or trim(composer) = ''
```
Catches every track whose composer is either genuinely missing (`NULL`) or present but blank once whitespace is stripped (`''` after trimming).

**Other forms it supports (not yet used here):**
- `TRIM(LEADING FROM column)` / `TRIM(TRAILING FROM column)` — strip only one side instead of both.
- `TRIM(BOTH 'x' FROM column)` — strip a specific character instead of whitespace (defaults to whitespace if no character is given).

**What it can't do:**
- **Cannot turn `NULL` into `''`.** `TRIM(NULL)` evaluates to `NULL`, never to an empty string — there's nothing there to strip whitespace off of. This is why a "missing or blank" check always needs `column IS NULL OR TRIM(column) = ''` (two separate conditions joined with `OR`), never `TRIM(column) = ''` alone (misses genuine `NULL` rows) and never joined with `AND` (see Entry #11 in MASTER-GUIDE — `AND` silently excludes every `NULL` row, since the second half can never be `TRUE` for one).
- Only strips whitespace (or a named character) from the two ends — doesn't collapse repeated spaces in the middle of a string (`'John   Lennon'` stays `'John   Lennon'` after `TRIM`).

---

## 9. `EXTRACT(part FROM column)` — Date Function

**What it does:** Reads off one named component (year, month, day, hour, minute, second...) from a structured date/timestamp value. Doesn't slice characters and doesn't do math — the date is already broken into these parts internally, `EXTRACT` just returns the one you name.

**Form used so far:**
```sql
select EXTRACT(year FROM invoice_date) AS year
from invoice;
```
Returns just the year (e.g. `2023`) for every invoice, discarding month/day/time entirely.

**Other forms it supports (not yet used here):**
- Other parts: `EXTRACT(month FROM column)`, `EXTRACT(day FROM column)`, `EXTRACT(hour FROM column)`, `EXTRACT(dow FROM column)` (day of week), etc.
- Can be used in `WHERE`/`HAVING` too, not just `SELECT`.

**Compound date filters — now used, one `EXTRACT` call per part, joined with `AND`:**
```sql
where EXTRACT(year from sent_date) = 2022
  and EXTRACT(month from sent_date) = 8
```
`EXTRACT(part FROM column)` only ever takes **one** part name — `EXTRACT(year, month FROM column)` is not valid syntax. Pinning down a specific month-of-a-specific-year needs two separate `EXTRACT(...) = value` conditions, both required to hold, hence `AND` rather than a single call. See MASTER-GUIDE Entry #20.

**`GROUP BY` on an `EXTRACT`ed calendar unit — now used, and the reason it's required:**
```sql
select extract(MONTH from submit_date) as mth, product_id, round(avg(stars)::numeric, 2) as avg_stars
from reviews
group by product_id, mth
```
`submit_date` is a full timestamp — precise to the second. `GROUP BY submit_date` (the raw column) groups by that exact instant, so two reviews on different days of the same month never share a group. `EXTRACT(MONTH FROM submit_date)` reduces the timestamp down to just the calendar unit the question cares about *first*, and grouping by that (here, via its alias `mth` — legal in Postgres, see §21) is what actually collapses same-month rows together. See MASTER-GUIDE Entry #23.

**What it can't do:**
- Only works on an actual date/timestamp-typed column — not on a plain text or integer column pretending to hold a date.
- Only ever extracts **one** named part per call — no comma-separated list of parts in a single `EXTRACT(...)`.
- The extracted result is invisible to other items in the *same* `SELECT` list if aliased — see the `AS year` / `COUNT(year)` trap logged in MASTER-GUIDE Entry #12. Only `GROUP BY`/`ORDER BY` can reference that alias, not a sibling `SELECT` expression.
- Grouping by the *raw* date/timestamp column instead of an `EXTRACT`ed part groups by the exact value, not the calendar unit — a distinct trap from the alias-visibility one above (Entry #23).

---

## 10. `COUNT(*)` / `COUNT(column)` — Aggregate Function

**What it does:** Tallies rows. `COUNT(*)` counts every row in a group, regardless of any column's value. `COUNT(column)` counts only the rows where that specific column is non-`NULL` — a narrower, different count.

**Form used so far:**
```sql
select EXTRACT(year FROM invoice_date) AS year,
  count(*)
from invoice
group by year;
```
Counts how many invoice rows fall into each year-group.

**`COUNT(CASE WHEN condition THEN 1 END)` — conditional aggregation, now used:**
```sql
having count(case when skill in ('Python','Tableau','PostgreSQL') then 1 end) = 3
```
`COUNT(column)`'s ordinary "skip the `NULL`s" behavior, deliberately exploited: the `CASE` returns `1` for rows matching some condition and `NULL` otherwise, so `COUNT` ends up tallying only the matching rows per group — no new `COUNT` behavior, just a `NULL`-producing expression feeding it. See MASTER-GUIDE Entry #16.

**`COUNT(DISTINCT ...)` — now used, safe version of the above when duplicate rows are possible:**
```sql
having count(distinct skill) = 3   -- after WHERE skill IN (...) has already filtered rows
-- or, without pre-filtering:
having count(distinct case when skill in (...) then skill end) = 3
```
Counts only *unique* non-`NULL` values — critical when a duplicate row could otherwise let a `CASE WHEN ... THEN 1` version over-count and pass a `HAVING` check it shouldn't (Entry #16's duplicate-`Python`-rows trace).

**`COUNT(DISTINCT entity_id_column)` on top of a CTE — which column goes inside `DISTINCT`, now used:**
```sql
select count(distinct company_id) as duplicate_companies
from companies_dup   -- a CTE that may list the same company on more than one row
```
The column inside `DISTINCT` must be the ID column of the real-world *entity* the question is asking to count — not any column that merely looks unique in the sample data you're staring at. A `title` or `description` column can coincidentally repeat across two unrelated entities (two different companies both posting a "Business Analyst" listing), silently collapsing a correct count of 2 down to a wrong count of 1. `DISTINCT` is also still required even on a column that *does* correctly identify the entity, because that entity's ID can legitimately repeat across multiple rows for reasons that have nothing to do with the count being asked for (one company appearing on two separate rows of a CTE because it duplicated two different job listings, not because it's "more duplicate"). See MASTER-GUIDE Entry #21.

**Other forms it supports (not yet used here):**
- `COUNT(column)` on a genuine table column (not a `CASE` expression) — count of non-`NULL` values in that column.

**What it can't do:**
- `COUNT(alias)` doesn't work if `alias` isn't a real column — Postgres looks for an actual column by that name and errors if it's just something invented earlier in the same `SELECT` list (see MASTER-GUIDE Entry #12).
- Like any aggregate, only meaningful alongside `GROUP BY` when you want a count *per group* — without `GROUP BY`, `COUNT(*)` collapses the whole table into a single number.

---

## 11. `ORDER BY column [ASC|DESC]` — Clause

**What it does:** Sorts the final result set. `ASC` (ascending, smallest/earliest first) is the default if omitted; `DESC` (descending, largest/latest first) has to be written explicitly.

**Form used so far:**
```sql
... order by year desc;
... order by count(*) desc;
```
Both work — one sorts by the `year` alias, the other by the raw `count(*)` aggregate expression.

**Other forms it supports (not yet used here):**
- Multiple sort keys: `ORDER BY column1 DESC, column2 ASC` — ties in the first column get broken by the second.
- Can sort by column position number (`ORDER BY 1`) — not recommended for readability.

**What it can't do:**
- Nothing exotic here, but worth remembering *why* it's flexible: `ORDER BY` runs after `SELECT` has finished building the output, so it can reference either a `SELECT`-list alias or the raw underlying expression — unlike `WHERE`/`HAVING`, or other items inside the same `SELECT` list, which run before the alias exists.

---

## 12. `HAVING aggregate_expression comparison` — Clause

**What it does:** Filters *groups* after `GROUP BY` has already formed them, based on an aggregate value (a count, sum, average...). This is different from `WHERE`, which filters individual rows *before* grouping happens.

**Form used so far:**
```sql
... group by year
having count(*) > 30
order by year desc;
```
Keeps only year-groups with more than 30 invoices.

**Other forms it supports (not yet used here):**
- Any aggregate, not just `COUNT`: `HAVING AVG(column) > x`, `HAVING SUM(column) < y`.
- Multiple conditions: `HAVING COUNT(*) > 30 AND AVG(total) > 5`.

**What it can't do:**
- Never sees a `SELECT`-list alias — always needs the raw aggregate expression repeated (`HAVING COUNT(*) > 30`, not `HAVING year_count > 30`), because `HAVING` runs before `SELECT` creates that alias.
- A bare aggregate name with no parentheses (`HAVING count > 30`) is not a valid function call — always needs `count(*)` or `count(column)`.
- Can't be used without `GROUP BY` to filter on a per-row basis — that job belongs to `WHERE`.

---

## 13. `AGE(timestamp)` — Date Function

**What it does:** Calculates the elapsed span between a timestamp/date value and right now (or between two explicit timestamps, if given two arguments), returning a structured `interval` value — years/months/days — not a single plain number.

**Form used so far:**
```sql
select age(invoice_date) as date_days from invoice;
```
Returns one `interval` per invoice — e.g. `{"years":5,"months":7,"days":8}` — representing how long ago that invoice happened relative to today.

**Other forms it supports (not yet used here):**
- Two-argument form: `AGE(timestamp1, timestamp2)` — elapsed span between two explicit dates, instead of one date and "now."

**What it can't do:**
- Only accepts an actual `date`/`timestamp`-typed column — check with `information_schema.columns` first if unsure. If the column is already `timestamp`/`date` typed, no cast is needed at all.
- Writing `AGE(timestamp invoice_date)` (the keyword `timestamp` directly in front of a column name) is **not** valid casting syntax — `timestamp '...'` only works in front of a quoted string literal, not a column reference.
- Its output is a structured `interval`, not a plain number — can't be compared against a bare number (`AGE(invoice_date) > 4`); it needs another `interval` on the other side of the comparison (see `INTERVAL` below).
- **`AGE` is the wrong tool when the question wants a single plain integer "number of days."** Its output is always calendar-broken-down (years/months/days), which only *looks* like a clean day count when the gap happens to stay inside one month. For a true flat day count, use `date - date` subtraction instead — see §18. (MASTER-GUIDE Entry #19.)

---

## 14. `INTERVAL 'n unit'` — Literal / Data Type

**What it does:** Writes a literal span of time (e.g., "4 years," "10 days") that can be compared against, added to, or subtracted from date/timestamp/interval values.

**Forms used so far:**
```sql
-- Comparison against AGE()
select age(invoice_date) as date_days from invoice
where age(invoice_date) > '4 years';

-- Date arithmetic: shifting an actual date forward
select invoice_date + interval '6 months' as date_days from invoice;
```
The first filters to only invoices whose elapsed `AGE` exceeds 4 years — this ran correctly even *without* writing the `INTERVAL` keyword explicitly, because Postgres inferred `'4 years'` should be cast to an `interval` from context (the other side of `>` was already an `interval`). Writing it explicitly as `INTERVAL '4 years'` is still the clearer, more deliberate habit.

The second computes, for every invoice, the actual calendar date 6 months later — `timestamp + interval` returns a **new timestamp**, a genuinely different result type than `interval + interval` (see "What it can't do" below).

**Other forms it supports (not yet used here):**
- Other units: `INTERVAL '3 months'`, `INTERVAL '10 days'`, `INTERVAL '2 hours'`.
- Subtracting instead of adding: `invoice_date - INTERVAL '1 year'`.

**What it can't do:**
- Needs a real recognized unit word inside the quotes — arbitrary text won't parse as a time span.
- Same alias rule as every other `WHERE` condition: `AGE(invoice_date)` had to be written out in full inside `WHERE`, not referenced via its `date_days` `SELECT`-list alias — `WHERE` runs before `SELECT` creates that alias.
- **`WHERE` always needs a boolean, never a computed value.** `WHERE invoice_date + interval '6 months'` errors with "argument of WHERE must be type boolean, not type timestamp without time zone" — a date-shift computation is something to *display* (`SELECT`), not a row-filter condition.
- **`interval + interval` is not the same as `timestamp + interval`.** `AGE(invoice_date) + INTERVAL '6 months'` type-checks and runs without error, but it adds 6 months onto the *elapsed-time span*, producing a bigger interval — not a calendar date. Only starting from the actual `timestamp` column (`invoice_date + INTERVAL '6 months'`) produces a real date as the result. The operand types decide the result type: `timestamp + interval = timestamp`, `interval + interval = interval`.

---

## 15. `column IN (val1, val2, ...)` — Comparison Operator

**What it does:** Shorthand for a chain of `OR`-ed equality checks. `skill IN ('Python','Tableau','PostgreSQL')` means exactly `skill = 'Python' OR skill = 'Tableau' OR skill = 'PostgreSQL'`. Case-sensitive, same as `=`/`LIKE` (not `ILIKE`).

**Form used so far:**
```sql
select candidate_id from candidates
group by candidate_id
having count(case when skill in ('Python','Tableau','PostgreSQL') then 1 end) = 3
order by candidate_id asc;
```
Used inside a `CASE WHEN` (per-row true/false, itself feeding a `COUNT`) rather than as a standalone row filter — see MASTER-GUIDE Entry #16 for the full nested breakdown.

**Other forms it supports (not yet used here):**
- Standalone row filter: `WHERE skill IN (...)` — throws out non-matching rows before any grouping happens (different mechanism than the `CASE WHEN` form: rows disappear entirely instead of surviving with a `NULL`).
- Subquery form: `WHERE column IN (SELECT ...)` — list comes from a query instead of a literal list (not yet covered).

**What it can't do:**
- Always needs a column/expression directly in front of it — `IN (...)` with nothing preceding it (e.g. bare inside a `CASE WHEN`) is a syntax error, not a silent no-op.
- `NOT IN` (not yet used) is dangerous if the list or the tested column can contain `NULL` — it can silently return zero rows instead of erroring. Plain `IN` doesn't have this trap.
- Doesn't dedupe or count anything by itself — it only answers true/false per row. Combining it with `COUNT`/`COUNT DISTINCT` for "has all of N required items" is a separate pattern layered on top (Entry #16).

---

## 16. `LEFT JOIN` — JOIN Type

**What it does:** Keeps every row from the table named right after `FROM` (the "left" table), regardless of whether a match exists in the joined table. Where no match exists, every column that would have come from the right-hand table is returned as `NULL` instead of the row being dropped. Contrast with `INNER JOIN` (used in every earlier entry), which drops a row entirely if either side has no match.

**Form used so far:**
```sql
select pages.page_id
from pages
left join page_likes
on pages.page_id = page_likes.page_id
where page_likes.page_id is null
order by pages.page_id asc;
```
Keeps every page, including ones with zero rows in `page_likes` (those rows come back with `page_likes.page_id`/`user_id`/`liked_date` all `NULL`), then `WHERE page_likes.page_id IS NULL` isolates just the unmatched ones — the "anti-join" pattern for "find rows in A with nothing matching in B." See MASTER-GUIDE Entry #17.

**Other forms it supports (not yet used here):**
- `RIGHT JOIN` — mirror image, keeps every row from the right-hand table instead.
- `FULL OUTER JOIN` — keeps unmatched rows from *both* sides at once.
- Can be used for its normal purpose too (just "attach optional related data, keep the anchor row either way"), not only for the anti-join `IS NULL` pattern.

**What it can't do:**
- Doesn't automatically isolate the unmatched rows — that always requires an explicit `WHERE <right_table>.<column> IS NULL` afterward. `LEFT JOIN` alone returns matched *and* unmatched rows mixed together.
- The `IS NULL` check must target a column from the **joined (right-hand) table**, never the anchor (left) table's own key — the left table's key is never `NULL` by construction, so checking it silently filters nothing.
- Same ambiguous-column risk as `INNER JOIN` once both tables share a column name (Entry #4) — every reference to that shared name needs table-prefixing.

---

## 17. `MIN(column)` / `MAX(column)` — Aggregate Function

**What it does:** Scans every value in a group and returns the smallest (`MIN`) or largest (`MAX`) one. Works on numbers, text (alphabetical order), and dates/timestamps (chronological order) alike. Unlike `CASE WHEN`, which decides something about one row at a time, `MIN`/`MAX` compare *across* every row in the group to pick out a single extreme value — there's no way to answer "which is earliest" by looking at just one row in isolation.

**Form used so far:**
```sql
select user_id, max(post_date::date) - min(post_date::date) as days_between
from posts
where extract(year from post_date) = 2021
group by user_id
having count(*) >= 2;
```
Per `user_id` group, `MIN(post_date)` pulls out that user's earliest 2021 post and `MAX(post_date)` their latest — the two values then feed into a subtraction (§18) to get the day gap. See MASTER-GUIDE Entry #19.

**What it can't do:**
- Like any aggregate, a bare column reference can't sit next to it in the same `SELECT` list under a `GROUP BY` unless that column is either the `GROUP BY` key itself or wrapped in another aggregate — `SELECT user_id, post_date, MAX(post_date) ... GROUP BY user_id` is invalid because `post_date` alone doesn't collapse down to one value per group.
- Doesn't replace `CASE WHEN` and isn't replaceable by it — `CASE WHEN` has no mechanism to compare a row against every other row in its group; that cross-row comparison is exactly what `MIN`/`MAX` exist to do.
- Same `WHERE`-can't-see-`SELECT`-aliases rule as everything else (§13's `AGE` note) — a `HAVING`/`WHERE` condition referencing a `MIN`/`MAX` needs the full aggregate expression, not a `SELECT`-list alias for it.

---

## 18. `value::type` — Cast Operator

**What it does:** Converts a value from one Postgres type to another. `expression::type` — the type name goes directly after the value, separated by two colons. Most commonly used here to narrow a `timestamp` (date + time-of-day) down to a plain `date` (date only), which **drops the time-of-day component entirely** rather than rounding or truncating it into the date.

**Form used so far:**
```sql
select max(post_date::date) - min(post_date::date) as days_between
from posts
group by user_id;
```
`post_date` is a `timestamp` column (e.g. `2021-07-12 19:00:00`). Casting each side to `::date` strips the time (`2021-07-12`), so subtracting the two dates isn't polluted by time-of-day differences between individual posts.

**The key gotcha this unlocked — `date - date` vs `timestamp - timestamp` vs `AGE`:**
- **`date - date`** (both sides cast to plain `date`) returns a **plain integer** — the literal count of days between them. No interval type, no calendar breakdown, just a number. This is what a question asking for a flat "number of days" wants.
- **`timestamp - timestamp`** (no cast) returns an `interval`, and if the two timestamps have different times-of-day, that interval carries extra hours/minutes noise (`2 days 7:00:00` instead of a clean `2`).
- **`AGE(timestamp1, timestamp2)`** (§13) also returns an `interval`, but a *calendar-broken-down* one (`7 mons 17 days`) — structurally different from a day count and not convertible to one by just reading off a field, since "7 months" isn't a fixed number of days.
- Rule of thumb: need a **single flat day count** → cast to `::date` and subtract. Need a **human-readable calendar age/span** → `AGE()`. They are not interchangeable, and reaching for `AGE()` when a plain integer is wanted produces the wrong *shape* of answer, not just a formatting difference. (MASTER-GUIDE Entry #19.)

**`::numeric` before a two-argument `ROUND` — now used:**
```sql
round(avg(stars)::numeric, 2) as avg_stars
```
Postgres's two-argument `ROUND(numeric, integer)` — the form that lets you specify decimal places — specifically requires a `numeric` first argument; a separate one-argument `ROUND(double precision)` form exists for whole-number rounding only. `::numeric` makes the type explicit so the two-argument form resolves correctly. See §23 (`ROUND`) and MASTER-GUIDE Entry #23.

**What it can't do:**
- `::date` on a value that's already just a `date` is a harmless no-op, but casting the wrong direction (e.g. trying to squeeze a `timestamp`'s time-of-day back out of an already-cast `date`) isn't possible — the time is gone, not hidden.
- Casting doesn't fix a type mismatch that's conceptually wrong (e.g. `'abc'::integer` still errors) — it only works between types that have a sensible conversion.

---

## 19. `LIMIT n` — Clause

**What it does:** Caps the number of rows the query returns to at most `n`, applied to whatever order the result set is already in. It doesn't test any column's value and isn't a substitute for `WHERE`/`HAVING` — it's purely positional ("stop after this many rows"), which makes it the tool for "top N" questions.

**Form used so far:**
```sql
select sender_id, count(message_id) as message_count
from messages
where extract(year from sent_date) = 2022
  and extract(month from sent_date) = 8
group by sender_id
order by message_count desc
limit 2;
```
`ORDER BY message_count DESC` defines what "top" means (highest count first); `LIMIT 2` then cuts the list off after the first 2 rows of that ordering. See MASTER-GUIDE Entry #20.

**What it can't do:**
- **Means nothing reliable without `ORDER BY` first.** `LIMIT` without a preceding `ORDER BY` returns *some* 2 rows, but which 2 is unspecified/arbitrary — it doesn't know "top" means "highest" unless `ORDER BY` already established the sort direction.
- Isn't a filtering condition — can't express "rows where count > 5" or any value-based test; that's still `WHERE`/`HAVING`'s job. `LIMIT` only ever answers "how many rows," never "which rows qualify."
- Goes at the very end of the clause sequence — after `ORDER BY`, last of all: `SELECT ... FROM ... WHERE ... GROUP BY ... HAVING ... ORDER BY ... LIMIT`.

---

## 20. `WITH name AS (...)` — Clause (Common Table Expression / CTE)

**What it does:** Runs the query inside the parentheses first, names its result, and lets everything below treat that result as if it were a real table — with real column names — for the rest of the statement. Exists only for the duration of that one statement; nothing is saved.

**Form used so far:**
```sql
WITH companies_dup AS (
  SELECT company_id, title, description, COUNT(*) AS posting_count
  FROM job_listings
  GROUP BY company_id, title, description
  HAVING COUNT(*) > 1
)
SELECT COUNT(DISTINCT company_id) AS duplicate_companies
FROM companies_dup;
```
Solves a two-level aggregation: the CTE finds every duplicated `(company, title, description)` group first, fully finishing that work; the outer query then runs a second, separate aggregate (`COUNT(DISTINCT ...)`) on top of the CTE's finished output. See MASTER-GUIDE Entries #1 and #21.

**What it can't do:**
- **The closing `)` ends the CTE's inner query, not the whole statement.** A `;` placed *inside* the parentheses (before that `)`) terminates the entire statement early and cuts off the outer `SELECT` that was meant to follow — the `;` belongs only at the very end, after the outer query.
- An alias given to a column *inside* the CTE (e.g. `COUNT(*) AS posting_count`) should describe what that value means at that level, not what the outer query will eventually do with it — naming the CTE's own `COUNT(*)` something like `duplicate_companies` is misleading, since at that point it's still "how many times this one posting repeated," not a count of companies.
- A column carried through from the CTE (like `company_id`) is not guaranteed unique per row in the CTE's own output — it can repeat across multiple rows for reasons unrelated to what's being counted (see the `COUNT(DISTINCT ...)` entry-identity note in §10).

---

## 21. `GROUP BY column1, column2, ...` — Clause

**What it does:** Collapses rows down to one output row **per distinct combination of every column named in the list** — not one row per "the thing you're conceptually trying to count." Aggregate functions (`COUNT`, `AVG`, `SUM`, `MIN`, `MAX`, ...) elsewhere in the same `SELECT` then compute their result *per group*, across whatever rows landed in that group.

**The granularity rule, now stated explicitly:**
```sql
select city, count(status) as total_orders
from trades join users on users.user_id = trades.user_id
where status = 'Completed'
group by users.city    -- exactly the one non-aggregated column in SELECT, nothing more
```
`GROUP BY` should contain **exactly** the non-aggregated columns that appear in `SELECT` — no more, no less. Every extra column named in `GROUP BY` (even one that isn't in `SELECT` at all) adds another axis that rows must match on to land in the same group, silently re-splitting a group that should have collapsed into one row. See MASTER-GUIDE Entry #22.

**The other half of the rule — a column can't be grouped by *and* aggregated at the same time:**
```sql
select product_id, extract(MONTH from submit_date) as mth, round(avg(stars)::numeric, 2) as avg_stars
from reviews
group by product_id, mth   -- NOT stars — stars is what AVG() is aggregating
```
If a column being fed into an aggregate (like `stars` into `AVG(stars)`) also appears raw in `GROUP BY`, every group ends up containing rows that already share that exact value — the aggregate still runs, but there's no variation left within a group to aggregate over, so it just echoes the single shared value back. See MASTER-GUIDE Entry #23.

**Grouping by a `SELECT`-list alias — legal in Postgres, unlike `WHERE`:**
```sql
select extract(MONTH from submit_date) as mth, ...
group by product_id, mth   -- "mth" here is the alias defined above, not a real column
```
`WHERE` runs before `SELECT` builds its output, so it can never see a `SELECT`-list alias (Entries #12/#19). `GROUP BY` sits in a different position in execution order, and Postgres specifically permits referencing a `SELECT`-list alias here, resolving it back to the underlying expression. A genuine exception, not a contradiction of the `WHERE` rule.

**What it can't do:**
- Doesn't know which columns "should" define a group beyond exactly what's listed — it has no concept of "group by city, but only really consider `user_id` if it matters." Every listed column matters equally, always.
- Can't coexist with a column that's also inside an aggregate in the same `SELECT` without defeating that aggregate (see above) — the two roles (grouping key vs. aggregated value) are mutually exclusive for a given column within one query.
- Doesn't reduce a timestamp column to a coarser calendar unit on its own — grouping by a raw `timestamp` groups by the exact instant; reducing to "just the month" requires `EXTRACT` (§9) run first.

---

## 22. `JOIN ... ON condition` — Condition Correctness

**What it does:** The `ON` condition decides which rows from each side get paired together. It must name a column from each of the **two different tables** being joined — that's what makes it an actual relationship rather than a vacuous statement.

**The bug this session caught — a self-referencing condition:**
```sql
-- wrong: both sides name the same table
join users on trades.user_id = trades.user_id
```
```sql
-- correct: one column from each table
join users on users.user_id = trades.user_id
```
`trades.user_id = trades.user_id` compares a column to itself. That's always true, for every single row, regardless of anything in `users` — Postgres has no way to distinguish this from an intentional (if pointless) condition, since it's syntactically valid. The result behaves like a cross join: every row of `trades` gets paired with every row of `users`, and every downstream `GROUP BY`/aggregate now runs over a massively inflated, duplicated row set instead of the real one. See MASTER-GUIDE Entry #22.

**What it can't do:**
- Doesn't error or warn on a same-table self-reference — it's valid syntax that happens to express "always true," so nothing about running it looks wrong until the row counts or aggregate totals come out inflated.
- Doesn't substitute for `WHERE` — a condition that's supposed to filter rows post-join still belongs in `WHERE`, not folded into `ON` (a separate concern from the same-table bug above, but worth keeping distinct).

---

## 23. `ROUND(numeric_expression, n)` — Function

**What it does:** Rounds a number. With one argument, `ROUND(x)` rounds to the nearest whole number, discarding all decimal places. With two arguments, `ROUND(x, n)` keeps exactly `n` digits after the decimal point.

**Form used so far:**
```sql
round(avg(stars)::numeric, 2) as avg_stars
```
`AVG(stars)` is cast `::numeric` first (§18) so Postgres resolves the two-argument `numeric, integer` form of `ROUND` rather than the separate one-argument `double precision` form. `2` keeps two decimal places, so `4.0` reports as `4.00`, not `4`. See MASTER-GUIDE Entry #23.

**What it can't do:**
- **One argument is not a smaller version of two arguments — it's a different operation.** `ROUND(3.567)` gives `4` (whole number, all decimal information discarded); `ROUND(3.567, 2)` gives `3.57`. Omitting the second argument when a question specifically asks for N decimal places produces the wrong *shape* of answer, not just a formatting difference.
- The two-argument form specifically wants a `numeric` first argument — calling it on a `double precision` value (e.g. an uncast `AVG()` result, depending on context) can resolve to the wrong overload or error; `::numeric` removes the ambiguity.
