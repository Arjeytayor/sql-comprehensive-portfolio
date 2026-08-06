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

**What it can't do:**
- Only works on an actual date/timestamp-typed column — not on a plain text or integer column pretending to hold a date.
- The extracted result is invisible to other items in the *same* `SELECT` list if aliased — see the `AS year` / `COUNT(year)` trap logged in MASTER-GUIDE Entry #12. Only `GROUP BY`/`ORDER BY` can reference that alias, not a sibling `SELECT` expression.

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

**Other forms it supports (not yet used here):**
- `COUNT(column)` — count of non-`NULL` values in a specific column (different from `COUNT(*)` whenever that column has `NULL`s).
- `COUNT(DISTINCT column)` — count of unique non-`NULL` values only.

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
