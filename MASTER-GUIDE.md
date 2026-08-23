# SQL Master Guide — Practice Question Breakdowns

Personal reference doc. Every practice question (DataLemur, LeetCode, etc.) that gave real trouble gets a full entry here — broken down slow, granular, no skipped steps. Come back here before re-attempting a similar pattern instead of re-learning it from scratch.

**How each entry is structured:**
1. The question (short version)
2. Why it needs the technique it needs — what breaks without it
3. A real-world/daily-life narrative version of the same problem shape
4. The concept, explained from zero
5. The logic used to solve it — the actual step-by-step reasoning, from reading the question to the final query
6. A hand-trace through the actual sample data — no abstract hand-waving
7. Full solution
8. The reusable pattern — the thing to recognize next time
9. Best practices / general approach — "if you see this kind of question, here's how to go about it" checklist for future problems

---

## Index

| # | Topic | Source | Concept |
|---|---|---|---|
| 1 | CTEs & two-level aggregation | DataLemur — Twitter Tweets Histogram | `WITH` clause, grouping on top of a grouped result |
| 2 | JOIN roles, GROUP BY dependency, clause execution order | Chinook — Genres with more than 100 tracks | `INNER JOIN`, `GROUP BY` on a primary key, why `HAVING` can't see `SELECT` aliases |
| 3 | WHERE vs HAVING mechanics, reusable JOIN/GROUP BY/HAVING checklist | Chinook — Average track duration per genre (>50 tracks) | Row-filter vs. group-filter, `AVG()`, the general-purpose checklist for this whole query shape |
| 4 | Ambiguous columns after JOIN, primary vs foreign key, "many-side" columns in SELECT | Chinook — Artists with more than 5 albums | Table-prefixing every shared column name, PK vs FK terminology, why a raw many-side column can't sit next to a GROUP BY |
| 5 | FROM/JOIN role is about relationship, not row-count; duplicate GROUP BY keys with identical display names | Chinook — Playlists with more than 20 tracks | Why "pile you're counting" beats "bigger table" as the FROM/JOIN rule, why grouping by an ID can output two rows with the same visible name |
| 6 | NULL replacement: WHERE vs. COALESCE vs. CASE WHEN | Chinook — Customers with no company on file | Why filtering (`WHERE`) and substituting (`COALESCE`/`CASE`) answer different questions; two ways to express the same substitution logic |
| 7 | CONCAT syntax, LIKE/ILIKE wildcard mechanics, `IS` vs. pattern operators | Chinook — Full name + Gmail customers | Parentheses/separator arguments for `CONCAT`, `%`/`_` wildcard placement, case-sensitivity of `LIKE` vs. `ILIKE`, why quoted text needs a pattern operator, not `IS` |
| 8 | Matching SELECT output to what the question literally asks for | Chinook — Track names in uppercase alongside original | A working function call can still under-deliver on the actual question; re-reading the question after writing a query that "runs fine" |
| 9 | Wildcard placement (`%` vs. `_`) for "starts with," plus re-confirming LIKE/ILIKE case rules | Chinook — Artists starting with "B" (case-insensitive) | Why `_` (single character) is the wrong tool for "starts with," why `%` goes *after* the anchor letter, not around it |
| 10 | Reusing CONCAT with a different separator | Chinook — City, country combined | Same function, different literal-text argument between values — confirms the pattern transfers, not just the one example |
| 11 | TRIM for blank-vs-NULL, and why the combining operator must be OR not AND | Chinook — Tracks with NULL or blank composer | `''` vs. `NULL` are different kinds of "nothing"; why `TRIM(NULL)` never produces `''`, and why that makes `AND` silently fail |
| 12 | EXTRACT for date parts, alias visibility across SELECT/GROUP BY/HAVING/ORDER BY | Chinook — Invoices per year, more than 30, busiest year first | Why a SELECT-list alias can't be referenced by another item in the *same* SELECT list, but can be used in `ORDER BY`; `COUNT(*)` for "how many rows," not `COUNT(alias)` |
| 13 | Confirming EXTRACT transfers across date parts; distrust of a stale result panel | Chinook — Invoices per month, across all years, busiest month first | Same EXTRACT/GROUP BY/COUNT(*)/ORDER BY skeleton with `month` instead of `year`; re-running fresh instead of trusting a remembered/pasted result |
| 14 | AGE for elapsed time, INTERVAL literals, casting syntax mix-ups | Chinook — Time since each invoice; invoices more than 4 years old | `AGE(column)` returns a structured `interval`, not a number; `timestamp column` is not valid cast syntax; comparing an `interval` needs an `INTERVAL` literal (or a string Postgres can infer as one) |
| 15 | WHERE needs a boolean, not a computed value; `timestamp + interval` vs `interval + interval` | Chinook — Each invoice's date shifted 6 months forward | A date-shift belongs in `SELECT`, never `WHERE`; result type follows operand types — starting from the real date column gives a date back, starting from `AGE()`'s output only ever gives another interval |
| 16 | Conditional aggregation — `CASE WHEN`/`IN` nested inside `COUNT`, `COUNT` vs `COUNT(DISTINCT ...)` | DataLemur — Candidates with all required skills | `IN` as OR-shorthand; reading a nested expression inside-out; why plain `COUNT` silently over-counts on duplicate rows and `COUNT(DISTINCT ...)` is the safe general version |
| 17 | `LEFT JOIN` + `IS NULL` anti-join pattern; why `INNER JOIN` can't find "no match" rows | DataLemur — Facebook pages with zero likes | `LEFT JOIN` keeps every left-table row even with no match, filling `NULL` on the right side; `INNER JOIN` drops unmatched rows before there's anything left to filter; ambiguous-column fix (Entry #4) reapplied post-JOIN |
| 18 | `WHERE` vs `GROUP BY` vs `CASE WHEN` as a filter; clause order; `ISNULL` as Postgres's one-word `IS NULL` | DataLemur — Unfinished parts | Filtering (keep/discard rows) is a `WHERE` job, not `GROUP BY` (collapses rows) or a standalone `CASE WHEN` (produces a value, not a boolean gate); correct clause order; `SELECT *` vs matching the asked-for columns; Postgres-only `ISNULL`/`NOTNULL` legacy syntax |
| 19 | `MIN`/`MAX` per group, `AGE` vs `date - date`, why `CASE WHEN` can't substitute for a cross-row comparison | DataLemur — Facebook posts, days between first and last post of 2021 | `MIN`/`MAX` compare across a whole group, `CASE WHEN` only ever looks at one row; `EXTRACT(...) = year` for a row-level year filter in `WHERE`; `AGE()`'s calendar-broken-down interval vs. `::date` cast + subtraction for a flat integer day count; `WHERE` can't see `SELECT`-list aliases (reapplied from Entry #13) |
| 20 | `ORDER BY` + `LIMIT` for "top N"; compound `EXTRACT` filters joined with `AND`; third repeat of `WHERE`-before-`GROUP BY` (self-caught) | DataLemur — Microsoft Teams power users, top 2 senders in August 2022 | "Top N" is a sort-then-cut operation (`ORDER BY` + `LIMIT`), never a `WHERE`/`HAVING` threshold guess; `EXTRACT` takes exactly one part per call, so "this month of this year" needs two `EXTRACT(...) = value` conditions `AND`ed together, not one call with two parts |
| 21 | First CTE since Entry #1; `COUNT(DISTINCT entity_id)` must wrap the *entity's own ID column*, never an attribute that merely looks unique in the sample data; a repeated ID across CTE rows isn't "more duplicate" | DataLemur — LinkedIn duplicate job listings, count of companies with duplicate postings | `GROUP BY` on N columns = one row per distinct N-tuple, `COUNT(*)` in that row = repeat count of that tuple in the source table; a CTE's carried-through column isn't guaranteed unique per row; `title`/`description` can coincidentally collide across unrelated companies, silently undercounting; primary key vs. foreign key, reapplied (Entry #4) — `company_id` is a FK in `job_listings` but still the correct entity-ID to `DISTINCT` on |
| 22 | The `GROUP BY` granularity rule stated explicitly for the first time; a self-referencing JOIN condition silently becomes a cross join | Ace the Data Science Interview — Top 3 cities by completed trade orders | `GROUP BY` must contain *exactly* the non-aggregated `SELECT` columns and nothing more — every extra column re-splits rows that should collapse together; `ON table.col = table.col` (same table both sides) is always true, so every row matches every row; `COUNT(*)` vs `COUNT(column)` equivalence when no `NULL`s are possible; `RANK()` for tie-preserving "top N" vs `LIMIT`'s arbitrary cutoff (forward reference, not yet used in a submitted query) |
| 23 | `GROUP BY` vs. a column also sitting inside the aggregate it's grouped alongside; grouping by a raw timestamp vs. `EXTRACT`; `ROUND`'s second argument; grouping by a `SELECT`-list alias | Ace the Data Science Interview — Average star rating by month and product | A column can't sit *inside* an aggregate and *in* `GROUP BY` at the same time without defeating the aggregation entirely; a `timestamp` column groups by the exact instant, not the calendar month, unless `EXTRACT` reduces it first; `ROUND(x, n)` — one argument silently rounds to a whole number, the second argument is what actually sets the decimal places; grouping by a `SELECT`-list alias is legal in Postgres (execution-order exception, ties back to Entry #12) |

---

## 1. CTEs & Two-Level Aggregation — Twitter Tweets Histogram

### The question
Given a `tweets` table (`tweet_id`, `user_id`, `msg`, `tweet_date`), build a **histogram**: for each possible "number of tweets in 2022," count how many users posted exactly that many tweets.

Output: `tweet_bucket` (a tweet count, e.g. 1, 2, 3...) and `users_num` (how many users had exactly that many tweets).

### Why does this need two steps? (the part that trips people up)
Read the question again slowly: *"count how many users fall into each group, where the group is defined by how many tweets that user posted."*

There are two different things being counted here, at two different levels:

- **Level 1:** count tweets, *per user*
- **Level 2:** count users, *per tweet-count*

A single `GROUP BY` can only group by things that already exist as columns in your rows (`user_id`, `tweet_date`, etc.) — it cannot group by "the count I'm about to calculate in this same step," because that count doesn't exist yet at the time SQL is deciding how to group. You can't reference an aggregate result to group by it in the same breath you're computing that aggregate.

So: you cannot do this in one flat `GROUP BY`. You need to **compute Level 1 first, fully finish it, turn its output into something that looks like a normal table, and only then do Level 2 on top of that finished result.**

That "turn it into something you can query again" step is exactly what a CTE gives you.

### Real-world version of this same problem

Forget tweets for a second. Imagine you run a small provision store, and you keep a notebook where every sale gets one line: customer name, date.

At the end of the month, one page of that notebook looks like:

| Customer | Date |
|---|---|
| Ngozi | 3rd |
| Tunde | 5th |
| Ngozi | 12th |
| Amaka | 14th |
| Bello | 20th |
| Ngozi | 25th |
| Bello | 27th |

Now you want to answer a business question: *"How many of my customers bought from me just once this month? How many bought exactly twice? How many are regulars who bought 3+ times?"* You want this because a customer who bought once is someone to win back, and a customer who bought 3 times is someone to maybe give a loyalty discount to.

Notice — you can't answer this by staring at the notebook page directly, because the notebook is one line *per sale*, not one line *per customer*. To answer the question you have to, in your head, do exactly two passes:

- **Pass 1 (count purchases per customer):** Ngozi → 3, Tunde → 1, Amaka → 1, Bello → 2
- **Pass 2 (count customers per purchase-count):** "1 purchase" → 2 customers (Tunde, Amaka). "2 purchases" → 1 customer (Bello). "3 purchases" → 1 customer (Ngozi).

That is the *exact same shape* as the Twitter question — "tweets per user, then users per tweet-count" is just "purchases per customer, then customers per purchase-count" wearing a different costume. Any time you catch yourself mentally doing "first tally per person, then tally the tallies," that's this pattern, and the fix is the same: CTE for Pass 1, outer `GROUP BY` for Pass 2.

Worth remembering: this exact "purchase frequency per customer" idea is also the **F (Frequency) in RFM segmentation** — the technique planned for the Olist e-commerce capstone (Module 7). So this isn't just a practice-question trick, it's a real building block you'll reuse there.

### What is a CTE, really? (baby-level, zero assumed knowledge)

CTE = **Common Table Expression**. Forget the fancy name. Here's the actual mental model:

> A CTE is a `SELECT` query that you run first, give a name to, and then treat as if it were a real table for the rest of your query.

The syntax is:
```sql
WITH some_name AS (
    -- any normal SELECT query goes in here
    SELECT ...
    FROM ...
    GROUP BY ...
)
-- now, below, you can write SELECT ... FROM some_name
-- exactly like some_name was a real table sitting in the database
SELECT ...
FROM some_name
```

That's it. `WITH x AS (query)` just means: *"Run this query, call the result `x`, and let me use `x` in the next query like it's a table."* It only exists for the duration of this one statement — it's not saved anywhere.

**Why this solves our problem:** it lets us do our two levels of counting as two *separate, sequential* steps instead of one impossible step:
- Step 1 (inside the CTE): count tweets per user → produces a little table with one row per user
- Step 2 (the outer query): treat that little table as input, and now group *it* by the count column

### The logic used to solve it (the actual reasoning trace)

This is the thought process step by step, in the order you'd actually think it through — not the tidy final answer, the messy-but-correct path to get there:

1. **Read the question and underline the two things being counted.** Here: "tweets" and "users." Notice they're being counted at *different levels* — tweets per user, then users per tweet-count. Whenever two different nouns are each being counted, at two different levels, that's your first clue this needs two passes.
2. **Find the filter first.** "In 2022" is a filter on `tweet_date`. Filters always get handled in the innermost query, before any grouping — filter first, then aggregate, never the other way around.
3. **Ask: "If I could only write one plain `SELECT ... GROUP BY` right now, what's the most basic useful thing I could compute?"** Here, that's "tweets per user" — `SELECT user_id, COUNT(*) FROM tweets WHERE ... GROUP BY user_id`. This becomes your CTE.
4. **Mentally test that query against the sample rows** (or actually run it) before writing anything else. Confirm it gives one row per user with a sane-looking count. Don't move to step 5 until this checks out.
5. **Now ask: "What do I still need that this doesn't give me yet?"** The question wants counts of *users*, grouped by *tweet-count*. The CTE's output has a `tweet_count` column sitting right there — so the outer query is just another plain `GROUP BY`, this time grouping by that column instead of `user_id`.
6. **Wrap step 3's query in `WITH name AS (...)`, then write the outer `SELECT ... GROUP BY` on top of it**, using the CTE's column names as if they were real table columns (because inside the outer query, they are).
7. **Sanity-check the final output against the example given in the question.** If it doesn't match, the bug is almost always in step 2 (wrong filter) or step 3 (grouped by the wrong column) — check those two first before anything else.

### Walking through it with the actual sample data

Given rows (from the problem):

| tweet_id | user_id | tweet_date |
|---|---|---|
| 214252 | 111 | 12/30/2021 |
| 739252 | 111 | 01/01/2022 |
| 846402 | 111 | 02/14/2022 |
| 241425 | 254 | 03/01/2022 |
| 231574 | 148 | 03/23/2022 |

**First, filter to 2022 only** (the 2021 row for user 111 drops out):

| tweet_id | user_id | tweet_date |
|---|---|---|
| 739252 | 111 | 01/01/2022 |
| 846402 | 111 | 02/14/2022 |
| 241425 | 254 | 03/01/2022 |
| 231574 | 148 | 03/23/2022 |

**Step 1 — inside the CTE:** `GROUP BY user_id, COUNT(*)`. This collapses the 4 rows above into one row per distinct `user_id`, counting how many rows each user had:

| user_id | tweet_count |
|---|---|
| 111 | 2 |
| 254 | 1 |
| 148 | 1 |

This 3-row result is the CTE's output. In the query, this is what `user_tweet_counts` (or whatever you name it) *is* — a little in-memory table with exactly these 3 rows and 2 columns.

**Step 2 — the outer query:** now we group *this* table by `tweet_count` (not by `user_id` anymore — `user_id` isn't even needed at this level):

- Rows where `tweet_count = 1`: user 254, user 148 → that's **2 users**
- Rows where `tweet_count = 2`: user 111 → that's **1 user**

Final result:

| tweet_bucket | users_num |
|---|---|
| 1 | 2 |
| 2 | 1 |

This matches the example output in the problem exactly — same numbers, because we hand-traced the same data.

### Full solution

```sql
WITH user_tweet_counts AS (
    SELECT
        user_id,
        COUNT(*) AS tweet_count
    FROM tweets
    WHERE tweet_date >= '2022-01-01'
      AND tweet_date < '2023-01-01'
    GROUP BY user_id
)
SELECT
    tweet_count AS tweet_bucket,
    COUNT(*) AS users_num
FROM user_tweet_counts
GROUP BY tweet_count
ORDER BY tweet_bucket;
```

Note on the date filter: `tweet_date >= '2022-01-01' AND tweet_date < '2023-01-01'` is safer than `WHERE EXTRACT(YEAR FROM tweet_date) = 2022` — it doesn't need to compute anything on every row, so it can use an index on `tweet_date` if one exists (relevant later in Module 5, Query Performance).

### The pattern to remember

**"Count of a count" always means two levels, always means a CTE (or subquery) first.**

Any time a question asks you to group by something that is *itself the result of a previous aggregation* — "group users by how many orders they placed," "group days by how many signups happened," "group products by how many times they were returned" — the shape is always:

```sql
WITH first_level AS (
    SELECT grouping_column, COUNT(*)/SUM(...)/etc AS the_metric
    FROM ...
    GROUP BY grouping_column
)
SELECT the_metric, COUNT(*)
FROM first_level
GROUP BY the_metric
```

Recognize that shape in the question wording ("group X by how many Y each X has") and the CTE structure should come to you automatically instead of needing to be worked out from scratch each time.

### Best practices / general approach — if you see this kind of question again

- **Trigger words that signal "two-level aggregation, use a CTE":** "histogram of," "distribution of," "group X by how many Y," "for each count, how many...". The moment you see these, don't try to force a single `GROUP BY` — go straight to planning a CTE.
- **Always filter before you aggregate, and filter in the innermost query.** Applying a filter after grouping (or in the outer query) either doesn't work or silently gives wrong numbers, because the outer query no longer has access to the raw rows.
- **Test the decision "do I need one level or two?" with this question:** *"Is the column I want to `GROUP BY` already sitting in the raw table, or do I have to calculate it first?"* If you have to calculate it first (like `tweet_count` here), that calculation needs its own step — a CTE — before you can group by it.
- **Name CTEs for what they contain, not generically.** `user_tweet_counts` tells you what's in it at a glance; `cte1` or `temp` doesn't. This matters more as queries get longer and you have 2-3 CTEs stacked.
- **Add `ORDER BY` on the final bucket/axis column even when the question doesn't ask for it.** A histogram read out of order (2, 1, 3...) is harder to sanity-check and looks unpolished in an interview setting.
- **Watch for the "ranges" variant of this same question** — e.g. "group users by 0-5 tweets, 6-10 tweets, 11+" instead of exact counts. That's the same two-level shape, but the outer `GROUP BY` needs a `CASE WHEN` (or Postgres's `width_bucket()`) instead of grouping on the raw count directly. Same pattern, one extra twist — don't be thrown by it.

---

## 2. JOIN Roles, GROUP BY Dependency & Clause Execution Order — Genres With More Than 100 Tracks

### The question
Using the Chinook database (`track` table, `genre` table), find every genre with **more than 100 tracks** in it. Show the genre's name and its track count, highest count first.

### Why does this need more than "just write a JOIN"? (what breaks without it)
This question looks like a one-liner, but it stacks four separate ideas on top of each other, and getting any one wrong breaks the whole query:

1. **Two tables, two different jobs.** `track` holds one row per actual track (that's what you're counting). `genre` only exists to translate a `genre_id` number into a readable `name`. Mixing up which table goes in `FROM` vs. `JOIN` — or worse, joining a table to itself — silently produces nonsense or an outright error.
2. **A count needs a group to count *within*.** You can't get "tracks per genre" without first telling SQL what a "genre" group even is (`GROUP BY`).
3. **`HAVING` must compare an aggregate, not a bare number.** `HAVING > 100` doesn't mean anything to SQL — more than *what*? It always needs the form `HAVING <aggregate expression> > 100`.
4. **SQL clauses execute in a different order than you type them.** This is the one that causes the sneakiest bugs, because the query still *looks* right. You type `SELECT ... FROM ... GROUP BY ... HAVING ... ORDER BY`, but under the hood the engine actually works through `FROM/JOIN → GROUP BY → HAVING → SELECT → ORDER BY`. Since `SELECT` — where you name your aliases with `AS` — runs *after* `HAVING`, an alias defined in `SELECT` does not exist yet when `HAVING` is evaluated. Try to use it there and you get an error, even though the alias is sitting right there in the query text, a few lines below.

### Real-world version of this same problem
Imagine a school library. Every book is logged one-at-a-time in a big check-out ledger: book title, and a category code (Fiction, Science, History...). There's a separate small card catalog that just translates each category code into its full category name.

The librarian wants to know: *"Which categories have more than 100 books, and how many exactly, biggest category first?"*

To answer that, she has to:
- Start from the ledger (the big pile of individual books — that's what she's counting), and for each entry, look up its category's full name in the card catalog (a lookup, not something to count from).
- Pile all the Fiction entries together, all the Science entries together, etc. (grouping).
- Throw out any pile with 100 or fewer books (filtering the *piles*, not the individual books — that's the `HAVING` idea, and it can only happen once the piles already exist).
- Then, and only then, write the final report with each category's name and count, sorted biggest-first.

Notice the librarian can't sort or filter "the report" before she's actually built the report — she has to finish counting each pile *first*. That ordering — count first, judge the piles second, format/sort last — is exactly why `GROUP BY`/`HAVING` happen before `SELECT`/`ORDER BY` under the hood.

### The concepts, explained from zero

**JOIN roles.** In `FROM track INNER JOIN genre ON track.genre_id = genre.genre_id`: the table after `FROM` is where your rows come from — the pile you're actually counting or listing. The table after `JOIN` is a *side lookup* — you're reaching sideways to grab one extra fact (the name) to attach to each row. Ask "which table has one row per thing I care about counting?" — that one goes in `FROM`.

**GROUP BY + primary key dependency.** When you `GROUP BY genre.genre_id`, SQL knows `genre_id` is `genre`'s primary key — meaning exactly one row in `genre` exists per `genre_id`, so exactly one `name` goes with it too. Because of that one-to-one guarantee, SQL lets you also `SELECT genre.name` even though you didn't group by it — it's "along for the ride" safely. But if you `GROUP BY genre.name` instead and then try to `SELECT genre.genre_id`, SQL has no such guarantee in the other direction (nothing declares `name` unique), so it refuses. Rule of thumb: **group by the primary key of the lookup table, not its descriptive name column.**

**Logical clause order vs. written clause order.** These are two separate things:
- *Written* (syntax) order — fixed, always: `SELECT → FROM → JOIN/ON → WHERE → GROUP BY → HAVING → ORDER BY`.
- *Logical* (execution) order — different: `FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY`.

`SELECT` sits near the top when you type it, but it's second-to-last to actually run. That's why aliases created in `SELECT` (via `AS`) aren't visible to `WHERE` or `HAVING` (both run earlier), but *are* visible to `ORDER BY` (which runs after `SELECT`).

### The logic used to solve it (the actual reasoning trace)

1. **Name the two tables and lock in their roles before typing anything.** "`track` = the pile I'm counting → `FROM`. `genre` = the lookup for the name → `JOIN`." Say this out loud every time; don't re-derive it query to query.
2. **Write the join.** `FROM track INNER JOIN genre ON track.genre_id = genre.genre_id` — match the shared column, one side named per table.
3. **Decide the grouping column.** You want one row per genre → `GROUP BY genre.genre_id` (the primary key, so `name` can safely tag along in `SELECT`).
4. **Write the count** as its own expression, `COUNT(*)`, and give it an alias with `AS` for later readability — but remember that alias doesn't exist yet as far as `HAVING` is concerned.
5. **Write `HAVING` using the raw aggregate**, `HAVING COUNT(*) > 100` — never the alias, because `HAVING` runs before `SELECT` creates it.
6. **Write `ORDER BY` using the alias**, since `ORDER BY` runs after `SELECT` and the alias exists by then.
7. **Sanity check column ambiguity**: any column name that exists in *both* joined tables (here, both `genre_id` and `name` exist on both sides after the join, or could be confused with `track.name`) needs a table prefix everywhere it's used.

### Hand-trace through a small example

Say `track` has 8 rows total, and `genre` has 3 rows:

| genre_id | name |
|---|---|
| 1 | Rock |
| 2 | Jazz |
| 3 | Metal |

`track` (just genre_id shown, one row per track):
`1, 1, 1, 1, 1, 2, 3, 1` → six tracks in genre 1, one in genre 2, one in genre 3.

After `JOIN`: 8 rows, each track tagged with its genre's name.
After `GROUP BY genre.genre_id`: 3 groups — Rock (6 rows), Jazz (1 row), Metal (1 row).
After `HAVING COUNT(*) > 100`... in this tiny example nothing survives (all groups are under 100) — but swap in the real Chinook numbers and the same mechanic gives Rock (1297), Latin (579), Metal (374), Alternative & Punk (332), Jazz (130) as the actual result, sorted by `ORDER BY track_count DESC`.

### Full solution

```sql
SELECT
    COUNT(*) AS track_count,
    genre.name,
    genre.genre_id
FROM track
INNER JOIN genre
    ON track.genre_id = genre.genre_id
GROUP BY genre.genre_id
HAVING COUNT(*) > 100
ORDER BY track_count DESC;
```

### The pattern to remember

**"Count grouped-by-a-lookup's-name, filtered on the count" always means:** raw table in `FROM`, lookup table in `JOIN`, group by the lookup's primary key (not its name column), `HAVING` uses the raw aggregate, `ORDER BY` can use the alias. Any time a question is "how many X per category, only show categories above N," this exact skeleton applies — just swap `track`/`genre` for whatever the raw/lookup pair is.

### Best practices / general approach — if you see this kind of question again

- **Before typing anything, say out loud which table is the "pile to count" and which is the "lookup."** The pile goes in `FROM`; the lookup goes in `JOIN`. Never join a table to itself — if both sides of your `JOIN` say the same table name, that's an immediate sign a table got mixed up with the wrong role.
- **`GROUP BY` the lookup table's primary key, not its display column.** This lets you safely `SELECT` other columns from that table without extra fuss.
- **`HAVING` never sees `SELECT` aliases — always repeat the aggregate expression there** (`HAVING COUNT(*) > 100`, not `HAVING alias_name > 100`). `ORDER BY` is the opposite — it runs after `SELECT`, so aliases *are* safe to use there.
- **Any column name that exists in more than one joined table needs a `table.column` prefix everywhere**, not just in the `ON` clause — including `GROUP BY`, `SELECT`, and anywhere else it appears.
- **When stuck on clause order, write out both orders side by side** — written (`SELECT...ORDER BY`) vs. logical (`FROM...ORDER BY`) — and check which one actually answers "has this alias been created yet?"

### Mistakes I actually made this time (and why)

Real wrong turns from working through this exact question, kept here so they're recognizable faster if the same instinct fires again:

- **Joined a table to itself** (`genre INNER JOIN genre`, and separately `track INNER JOIN track`) instead of `track` to `genre`. This came from not locking in table roles *before* typing — the fix that stuck was saying out loud first: "track = pile I'm counting, genre = lookup," every time, before writing `FROM`/`JOIN`.
- **Got the `ON` comparison backwards** — wrote `genre.name = track.genre_id` (comparing a name to an id) instead of `genre.genre_id = track.genre_id`. A join condition only ever makes sense when it compares two columns of the *same kind* (id-to-id, not name-to-id).
- **Wrote a three-part reference**, `track.genre.name` — not valid. A column reference is always exactly `table.column`, never `table.othertable.column`.
- **Wrote `HAVING > 100` with no aggregate function** — more than once, across different attempts. `HAVING` (like `WHERE`) always needs a full comparison: some expression, then the operator, then the value. `> 100` alone isn't a complete expression.
- **Reverted `HAVING` back to the alias (`HAVING track_count > 100`) twice** — including once immediately *after* correctly explaining out loud why `HAVING` can't see `SELECT` aliases. Knowing the rule in the abstract and actually applying it under your own pen turned out to be two different things; the fix was re-deriving it concretely each time by asking "has `SELECT` even run yet at this point?" instead of trusting memory of the rule.
- **Referenced `ORDER BY tracks`** — an alias that was never actually created anywhere in the query. Any name used in `ORDER BY`/`HAVING` has to be traceable to something that actually exists by that point, not just something that sounds plausible.
- **Assumed joining `track` to `genre` meant `COUNT(*)` was now counting genres, not tracks.** Tested by mentally running the join *without* `GROUP BY` first — since a join produces one output row per matched pair, and every track matches exactly one genre, the row count after the join tracks the number of *tracks*, not genres. Worth re-running this exact mental check anytime it's unclear what a `COUNT(*)` is actually counting after a join.
- **Suggested `GROUP BY track.name`** when looking for the grouping column — `track.name` is the individual track's own title, unrelated to genre grouping entirely. This came from grabbing a plausible-sounding column instead of checking "does this column define the group I actually want (one row per genre)?"
- **`GROUP BY genre.name` while also `SELECT`ing `genre.genre_id`** — works by luck sometimes but isn't guaranteed safe, because `name` isn't declared unique. The fix: group by the lookup table's *primary key* (`genre.genre_id`), which licenses selecting any other column from that same table (like `name`) for free.
- **Wrote an alias using dot notation**, `AS genre.count` — invalid; an alias is a brand-new made-up name, not a reference to an existing table's column, so it never takes a `table.` prefix.

---

## 3. WHERE vs HAVING Mechanics & the Reusable JOIN/GROUP BY/HAVING Checklist — Average Track Duration Per Genre

### The question
Using Chinook, find the average track length (`milliseconds`) per genre — show the genre's name and the average, but only for genres with **more than 50 tracks**, longest average first.

### Why this one matters beyond just "another GROUP BY question"
This is the same skeleton as entry #2 (JOIN + GROUP BY + HAVING), deliberately reused with a different aggregate (`AVG` instead of `COUNT`) to test whether the reasoning actually transfers — or whether it was memorized as one specific query instead of a general pattern. It also forced a much clearer answer to a question that's been fuzzy: **what is `WHERE` actually doing, mechanically, that's different from an aggregate function like `COUNT(*)`?**

### The concept, explained from zero: WHERE vs. an aggregate function

Both `WHERE` and something like `COUNT(*)` go through rows one at a time — that part is the same. What differs is what happens *during* that pass:

- **`WHERE` makes a decision, per row.** For every row, it checks a condition against that row's own column value and either **keeps** the row or **throws it away**. Example: `WHERE milliseconds > 30000` — for each track, "is this specific track's length over 30 seconds? Yes → keep. No → discard."
- **An aggregate function like `COUNT(*)` makes no decision at all — it only tallies.** By the time `COUNT(*)` runs, `WHERE` has already finished deciding which rows survive (and `GROUP BY` has already sorted survivors into groups). `COUNT(*)` just walks through whatever rows are left in front of it and adds 1 for each one — no condition, no judgment call, just accumulation.

So: **`WHERE` filters (picks which rows exist going forward); an aggregate function measures (reports a number about whichever rows already made it through).** That's why "more than 50 tracks" can only ever be a `HAVING` condition — it depends on a *count*, and counts don't exist until aggregation has already happened, which is after `WHERE` has already run. `WHERE` literally cannot see a count, because the count isn't computed yet at the point `WHERE` runs.

**When would this question actually need a `WHERE`?** Only if there were a *row-level* condition to apply *before* grouping — e.g. "only tracks released after 2015" or "only tracks longer than 30 seconds." This question has no such condition, so `WHERE` is correctly absent — not because `WHERE` is unnecessary in general, just unnecessary *this time*.

### WHERE + COUNT(*) together — what that combination is actually for

Easy to over-think this as some kind of "before/after elimination" technique. It's usually much simpler than that.

- **The order is never a choice.** `WHERE` always runs before `COUNT(*)`, every time, automatically — not something to decide based on intent.
- **The ordinary, most common reason to combine them: counting only the rows that meet a condition.** Example — *"How many tracks are in the Rock genre?"*
  ```sql
  SELECT COUNT(*)
  FROM track
  JOIN genre ON track.genre_id = genre.genre_id
  WHERE genre.name = 'Rock';
  ```
  `WHERE` throws out every non-Rock row; `COUNT(*)` tallies whatever's left. That's it — a filtered count, no comparison involved.
- **A separate, less common technique: measuring the *effect* of a filter.** Run `COUNT(*)` once with no `WHERE` (total rows) and once with a `WHERE` (filtered rows), then compare the two numbers to see how many rows got eliminated. This is a genuine, useful pattern (good for sanity-checking a filter, or reporting "X% of rows matched") — but it's a specific, deliberate before/after comparison, not the general reason `WHERE` and `COUNT(*)` show up together. Most of the time, there's no comparison happening at all — just a straightforward filtered count.

### The reusable checklist (in my own words, refined)

1. **`SELECT` the things we need** — figure out what columns/aggregates should show up in the output (this is planned first, even though it's revisited last).
2. **`FROM` (the table you're counting/averaging over)** — this names your starting pile of rows. Not itself a "join" — just where the rows come from.
3. **`INNER JOIN` (the lookup table)** — a separate step, reaching sideways to attach a name/description you don't have in the `FROM` table.
4. **`ON` — the condition matching both tables** (same-kind columns: id-to-id).
5. **`GROUP BY` the lookup table's primary key** (a real column — never an alias, never just "a column that sounds related").
6. **`HAVING` — an aggregate function plus the condition it must clear** (never the alias from `SELECT`, since `HAVING` runs before `SELECT` exists).
7. **`ORDER BY` the alias** (safe here, since `ORDER BY` runs after `SELECT`).
8. **`WHERE` only shows up if there's a row-level condition to apply before any grouping happens** — it's not a mandatory clause, just one that's absent when there's nothing to filter at the row level.

### Full solution

```sql
SELECT
    AVG(milliseconds) AS track_duration,
    genre.genre_id,
    genre.name
FROM track
INNER JOIN genre
    ON track.genre_id = genre.genre_id
GROUP BY genre.genre_id
HAVING COUNT(*) > 50
ORDER BY track_duration DESC;
```

Notice this `HAVING` uses `COUNT(*)` (counting rows in the group) while `ORDER BY` uses `track_duration` (the average) — two different aggregates doing two different jobs in the same query. Keeping straight *which aggregate answers which part of the question* is the actual skill this query is testing.

### Mistakes I actually made this time (and why)

- **Wrote `WHERE tracks > 50` twice**, even after correctly explaining in the abstract that `HAVING` is for post-grouping conditions. This is the same "know the rule vs. apply the rule live" gap as entry #2's `HAVING`-alias slip — the fix, again, is to consciously ask "is this a per-row fact or a per-group fact?" every time, instead of trusting memory.
- **Wrote `GROUP BY track_duration`** — mistaking the *alias for the computed average* for a real column to group by. This is a new variant of the `GROUP BY` confusion: not just "primary key vs. name column" anymore, but "a made-up alias for a calculated result is never a valid `GROUP BY` target," since it doesn't exist yet at that point in execution.
- **Relapsed once to `GROUP BY genre.name`** (the exact mistake logged in entry #2) before self-correcting by recalling the earlier note. Recovery was faster this time, but the instinct to reach for `name` over `genre_id` hasn't fully died out yet — worth deliberately re-testing this in a future question.
- **Needed two corrections to put `SELECT` first** in the written clause order — third time this exact correction has been needed across two sessions. This one clause-ordering habit is still the single most-repeated correction in this guide so far and deserves focused, deliberate drilling on its own (e.g. writing several unrelated queries where the *only* thing being practiced is "type `SELECT` first, every time," until it stops needing a reminder).

---

## 4. Ambiguous Columns After JOIN, Primary vs. Foreign Key, and "Many-Side" Columns in SELECT — Artists With More Than 5 Albums

### The question
Using Chinook, find how many albums each artist has released — show the artist's name and album count, only for artists with more than 5 albums, most albums first.

### Why this one matters — two new failure modes, on top of the now-solid basics
This was the first question where the core skeleton (JOIN roles, `GROUP BY` on a primary key, raw aggregate in `HAVING`, alias in `ORDER BY`) came out **correct on the first attempt** — real evidence the pattern has transferred, not just been memorized for one table pair. But two new things broke that hadn't shown up before:

1. **A raw "many-side" column sitting in `SELECT` next to a `GROUP BY`.** `album.title` was included in `SELECT` even though the query groups by `artist.artist_id`. Since one artist can have *many* different album titles, there's no single title to show per artist-group — Postgres has no way to collapse many titles into one row's worth of output.
2. **An ambiguous column reference.** `album` and `artist` both have a column literally named `artist_id` (one's a primary key, one's a foreign key, but the *name* is identical). Writing bare `artist_id` anywhere — in `COUNT()` or `HAVING` — leaves Postgres unable to tell which table's copy you mean.

### The concept, explained from zero

**Primary key vs. foreign key — the correct terms.** `artist.artist_id` is `artist`'s **primary key**: it uniquely identifies exactly one artist row. `album.artist_id` is a **foreign key**: it's a *copy* of that same id number, sitting inside `album`, pointing back to which artist made this album. It is not unique in `album` — many album rows can (and do) share the same `artist_id`, which is exactly why grouping by it works to collapse many albums into one artist-group. ("Secondary key" is not a real SQL term — the correct word is foreign key.)

**Why a many-side column can't sit in SELECT alongside GROUP BY.** Once you `GROUP BY artist.artist_id`, every column in `SELECT` has to have exactly *one* value per group — either it's the grouped column itself (or something functionally tied to it, like `artist.name`), or it's wrapped in an aggregate (`COUNT`, `SUM`, etc.) that reduces many values down to one number. `album.title` is neither — one artist can have many different titles, so there's no single correct value to display. Test before adding any column to SELECT: *"Does every row in this group share the exact same value for this column? If not, it needs to be aggregated, or it doesn't belong here at all."*

**"Ambiguous column" always means the same thing.** Whenever Postgres reports a column reference as ambiguous, it means that exact column name exists in more than one table involved in the query, and nothing tells Postgres which one you mean. The fix is always the same: add the `table.` prefix, everywhere that column name appears — not just in `ON`, but in `COUNT()`, `HAVING`, `GROUP BY`, anywhere.

### Full solution

```sql
SELECT
    COUNT(album.artist_id) AS title_count,
    artist.name
FROM album
INNER JOIN artist
    ON album.artist_id = artist.artist_id
GROUP BY artist.artist_id
HAVING COUNT(album.artist_id) > 5
ORDER BY title_count DESC;
```

### What went right, for the first time, without prompting
- `FROM album INNER JOIN artist` — roles correct immediately, no reversal, on a completely new table pair.
- `HAVING COUNT(album.artist_id) > 5` — raw aggregate used immediately, no alias slip, first attempt.
- `GROUP BY artist.artist_id` — lookup table's primary key, correct immediately.

### Mistakes made this time (new ones, not repeats)
- **Included `album.title` in `SELECT`** alongside a `GROUP BY artist.artist_id` — the "many-side column" mistake described above. Different flavor from earlier `GROUP BY` mistakes: this wasn't about picking the wrong column to group by, it was about including an *extra, ungroupable* column that didn't belong in the output at all.
- **Wrote bare `artist_id`** in `COUNT()` and `HAVING` after joining two tables that both have a column by that name — triggered Postgres's actual "ambiguous column" error. Fixed immediately, without needing a second reminder, once the table-prefix rule was pointed back to.
- **Used the term "secondary key"** instead of "foreign key" — not a real SQL term; corrected to the standard vocabulary (primary key / foreign key) so future reading and documentation makes sense.

---

## 5. FROM/JOIN Role Is About Relationship, Not Row-Count, Plus Duplicate GROUP BY Keys With Identical Names — Playlists With More Than 20 Tracks

### The question
Using Chinook, find every playlist with more than 20 tracks in it — show the playlist name and the track count, most tracks first.

### Why this one matters
The core skeleton (JOIN roles, GROUP BY on a primary key, raw aggregate in HAVING, alias in ORDER BY) came out clean on the very first attempt against a brand-new table pair (`playlist_track` / `playlist`) — further confirmation the pattern has transferred. But two new things surfaced once the query actually ran and once I tried to explain *why* the FROM/JOIN choice was correct:

1. **The rule I reached for by instinct was wrong, even though the answer was right.** I said "pick the table with large data as FROM and join it to the table with small data for lookup." That happened to work here, but it's the wrong reason — and a wrong reason is a rule that eventually breaks on a case where it doesn't hold.
2. **A real query result with two rows that look identical** ("Music" showing 3,290 twice, "TV Shows" showing 213 twice) — not a bug, but a data quirk that needed explaining.

### Real-world version of this same problem
Think of a school's list of after-school clubs. There's a big sign-up sheet — one line per student per club they joined — and a separate small poster listing each club's official name. Two different clubs on the poster can coincidentally share the exact same name (say, two separate "Chess Club" entries run by two different teachers, each with its own roster). If you count sign-up sheet entries "per club," you don't get one combined "Chess Club" number — you get two separate numbers, one per actual club, that just happen to display under the same word. The sign-up sheet (many rows, one per membership) is what you count from; the poster (one row per named club) is only there to hand you the label.

### The concept, explained from zero

**FROM vs. JOIN — the correct rule is about relationship, not size.** It is tempting to say "put the bigger table in FROM." That's usually true, but it's true *as a side effect*, not as the reason. The actual rule: **FROM holds the table where each row represents one instance of the thing you're counting or measuring. JOIN holds the table that exists only to attach a shared label/fact to those instances.** In this question, `playlist_track` has one row per track-in-a-playlist link — that's the thing being counted — so it's `FROM`. `playlist` has one row per playlist, existing only to supply the `name` — so it's `JOIN`. Row count usually follows from this relationship (the "many" side naturally has more rows), but row count is a *symptom*, not the test to apply. Anchor on "what does one row of this table actually represent?", not on which table looks bigger.

**Grouping by an ID can produce two output rows with an identical-looking name.** `GROUP BY playlist.playlist_id` groups by the real, unique identifier — not by `name`. If the `playlist` table happens to contain two separate rows both named "Music" (different `playlist_id`s, e.g. 1 and 8), each one is its own group, and each surfaces as its own row in the output, even though the displayed `name` column looks identical between them. This is not a query bug — it's the data itself having two distinct rows that share a label. The fix, if you ever *do* want them merged, would be to `GROUP BY playlist.name` instead — but that reintroduces the earlier risk (name isn't guaranteed to be the right grouping key) and wasn't what this question asked for.

### The logic used to solve it (the actual reasoning trace)

1. **Name the two tables and ask which one is "the pile you're counting" vs. "the label-supplier."** `playlist_track` = one row per track-in-a-playlist (the pile). `playlist` = one row per playlist, holding the name (the label-supplier).
2. **FROM = the pile, JOIN = the label-supplier.** `FROM playlist_track INNER JOIN playlist`.
3. **ON — match the shared column.** `ON playlist_track.playlist_id = playlist.playlist_id`.
4. **GROUP BY the lookup table's primary key.** `GROUP BY playlist.playlist_id` — licenses selecting `playlist.name` in SELECT for free.
5. **HAVING uses the raw aggregate.** `HAVING COUNT(*) > 20`.
6. **SELECT the things actually asked for** — the question said show the **name**, not the id, so `playlist.name` belongs in SELECT, not `playlist.playlist_id`.
7. **ORDER BY the alias**, matched exactly to how it was spelled in SELECT — a typo here (`tarck_count` vs. `track_count`) breaks the query even though every other clause is correct.

### Hand-trace through a small example

Say `playlist` has 2 rows, and `playlist_track` has 25 rows total:

| playlist_id | name |
|---|---|
| 1 | Music |
| 2 | Workout |

`playlist_track` (just `playlist_id` shown, one row per track-in-playlist link): 22 rows tagged `1`, 3 rows tagged `2`.

After `JOIN`: 25 rows, each tagged with its playlist's name.
After `GROUP BY playlist.playlist_id`: 2 groups — Music (22), Workout (3).
After `HAVING COUNT(*) > 20`: only Music survives.

Now imagine a second "Music" playlist existed with `playlist_id = 9` and its own 21 tracks. That would form a *third* group, entirely separate from `playlist_id = 1`, and the final output would show "Music" twice with two different counts — exactly the shape that showed up in the real Chinook results.

### Full solution

```sql
SELECT
    COUNT(*) AS track_count,
    playlist.name
FROM playlist_track
INNER JOIN playlist
    ON playlist_track.playlist_id = playlist.playlist_id
GROUP BY playlist.playlist_id
HAVING COUNT(*) > 20
ORDER BY track_count DESC;
```

### The pattern to remember

**FROM/JOIN placement is decided by "what does one row of this table represent?" — not by which table looks bigger.** The counting table (one row per instance of the thing being measured) goes in `FROM`; the label-supplying table (one row per named category) goes in `JOIN`. Row-count size is a consequence of this, never the test itself.

**Grouping by an ID, not a name, means duplicate-looking labels in the output are expected, not a bug** — always sanity-check duplicate-looking rows against the actual ID column before assuming something broke.

### Best practices / general approach — if you see this kind of question again

- **Test FROM/JOIN choice with "what does one row of this table represent?"**, not "which table has more rows?" — the two usually agree, but only the first one is actually the reason.
- **If two output rows show the same name but different counts, check whether you grouped by an ID** — that's very likely two distinct records that happen to share a display label, not a query error.
- **Match SELECT to what the question literally asks for** — "show the playlist name" means `playlist.name` belongs in SELECT, not the id, even if the id was fine to use for grouping.
- **Proofread `ORDER BY` aliases letter-for-letter against the `SELECT` alias** — a typo here (`tarck_count` vs. `track_count`) causes an undefined-column error that has nothing to do with the query's logic.

### Mistakes made this time (new ones, not repeats)

- **Selected `playlist.playlist_id` in SELECT instead of `playlist.name`** — the id was fine for `GROUP BY`, but the question asked to *display* the name, a different requirement entirely.
- **Typo'd the `ORDER BY` alias** (`tarck_count` instead of `track_count`) — caught before running, but would have thrown an undefined-column error.
- **After getting FROM/JOIN correct on the first pass, flipped it backward** (`FROM playlist INNER JOIN playlist_track`) when asked to restate the reasoning in the abstract — evidence the correct answer had been pattern-matched for this specific pair, not yet fully internalized as a transferable rule. Self-corrected once walked back through "which table hands the name vs. which table counts rows."
- **Reached for "bigger table = FROM" as the underlying rule** — works by coincidence in every example seen so far, but is the wrong justification; the real test is what a single row of the table represents, not its row count.

---

## 6. NULL Replacement: WHERE vs. COALESCE vs. CASE WHEN — Customers With No Company On File

### The question
Using Chinook, for every customer, show first name, last name, and company — but if `company` is `NULL`, show "Independent" instead.

### Why this one is a genuinely different shape from the JOIN/GROUP BY questions
Every prior entry in this guide was about *collapsing many rows into fewer, filtered groups* (JOIN + GROUP BY + HAVING). This question doesn't group or filter anything — it wants **every single customer row, unchanged in count**, with one column's *value* transformed conditionally. That's a completely different job: value substitution, not row reduction. The trap is reaching for `WHERE`, since `WHERE` is the tool that's been used the most so far — but `WHERE` removes rows; it never changes what a surviving row's value looks like.

### Real-world version of this same problem
Think of a paper contact list where some entries have "Company: ___" left blank. If someone asks *"print me the full list, and where company's blank just write 'Independent' instead of leaving it empty,"* that's not asking you to throw away the blank entries — every name still needs to appear on the printed list. You're not choosing who's included; you're deciding what to *write* in one specific slot when it would otherwise be empty. Filtering (who's on the list) and substituting (what one field says) are two different jobs, and only one of them was actually asked for here.

### The concepts, explained from zero

**Why `WHERE company IS NULL` doesn't solve this.** `WHERE` runs at the row-filtering stage — for every row, it asks a yes/no question and either keeps the row or throws it away entirely. `WHERE company IS NULL` keeps *only* the rows where company is missing and discards every customer who actually has one — the opposite of "show everyone, everyone." Even if you fixed the quoting on it (see below), it still answers a different question: *"which customers have no company?"* rather than *"show all customers, filling in a default where needed."*

**Why `IS NULL` is never quoted.** `NULL` is a special SQL keyword representing "no value," not a piece of text. Writing `IS "NULL"` (double quotes) tells Postgres you mean a column/identifier literally named `NULL` — not the concept of missingness. Writing `IS 'NULL'` (single quotes) would check for the literal four-character string `"NULL"` as data, which is also wrong. The comparison keyword is always bare: `IS NULL` / `IS NOT NULL`, no quotes at all, because it's a language keyword, not a value.

**COALESCE — the direct tool for "use this value if that one is null."** `COALESCE(company, 'Independent')` reads: *"give me `company`'s value — but if that's `NULL`, give me `'Independent'` instead."` It doesn't touch the row count at all; it only changes what shows up in that one column, for that one row, at display time.

**CASE WHEN — the general-purpose version of the same idea.** `CASE WHEN company IS NULL THEN 'Independent' ELSE company END` says the exact same thing in a longer, more explicit form: an if/then/else that must be closed with `END` before it can be given an alias (`AS company_name`). `COALESCE` is really just shorthand for this exact "null → fallback" shape of `CASE`. `CASE` earns its keep once you need more than one condition (e.g. different fallback text depending on *which* field is missing, or ranges of values) — for a single null-check, `COALESCE` is the cleaner choice.

**Both live inside one `SELECT`, not two.** A `CASE` expression is just another column-like item in the `SELECT` list — it needs a comma before/after it exactly like any other column, and everything (plain columns plus the `CASE`) has to sit inside a single `SELECT ... FROM customer`, not split into two separate `SELECT ... FROM customer` statements. An alias created in one `SELECT` statement does not exist in a second, separate `SELECT` statement — each statement is independent and only knows about its own columns.

### The logic used to solve it (the actual reasoning trace)

1. **Read the question and notice it never asks to exclude anyone** — "for every customer" is the tell that this is a substitution job, not a filtering job. That rules out `WHERE` immediately.
2. **Identify what needs to change**: only the `company` column's *displayed value*, only when it's `NULL`. Everything else (`first_name`, `last_name`) passes through untouched.
3. **Reach for `COALESCE(column, fallback_value)`** as the direct tool for "null → use this instead."
4. **Alias the result** with `AS` so the output column has a clean, intentional name.
5. **(Alternative) Reach for `CASE WHEN column IS NULL THEN fallback ELSE column END`** as the longer-form equivalent — useful to know since `CASE` generalizes to cases `COALESCE` can't handle.
6. **Keep every piece — plain columns and the `CASE`/`COALESCE` expression — inside one `SELECT` list**, comma-separated, with a single `FROM customer` at the end.

### Full solution

```sql
-- Option 1: COALESCE (direct, idiomatic for a single null-check)
select first_name, last_name, coalesce(company, 'Independent') as company
from customer;

-- Option 2: CASE WHEN (general-purpose, same result)
select first_name, last_name,
    case when company is null then 'Independent'
         else company
    end as company_name
from customer;
```

Both return the identical output: every customer's real company name where one exists, and "Independent" everywhere `company` was `NULL`.

### The pattern to remember

**"Show everyone, but change what displays for missing values" is a substitution problem, not a filtering problem — reach for `COALESCE` or `CASE WHEN`, never `WHERE`.** `WHERE` decides *who's in the result set*; `COALESCE`/`CASE` decide *what a value looks like* for whoever's already there. If the question would still make sense with "and don't lose anyone" tacked onto the end, that's the signal it's a substitution job.

### Best practices / general approach — if you see this kind of question again

- **Ask first: "does this question want fewer rows, or the same rows with different-looking values?"** The first is `WHERE`/`HAVING` territory; the second is `COALESCE`/`CASE` territory.
- **Never quote `NULL`** in a comparison — `IS NULL` / `IS NOT NULL`, bare, always. Quoting it turns it into an identifier or a literal string, not the missing-value keyword.
- **`CASE` always needs `END` before an alias can follow it** — treat `CASE ... END` as one inseparable unit, the same way an `IF` block needs a closing brace before anything can follow it.
- **Only one `SELECT ... FROM` per query** — every output column, whether a plain column or a `CASE`/`COALESCE` expression, belongs in the same comma-separated list, not spread across multiple statements.
- **Default to `COALESCE` for a single "if null, use X" case** — reach for `CASE WHEN` only once the logic needs more than one condition or more than two outcomes.

### Mistakes made this time (new ones, not repeats)

- **Tried `WHERE company IS "NULL"` first** — wrong tool (filters rows instead of substituting a value) *and* wrong syntax (`NULL` quoted as if it were an identifier). Corrected by working out what that query would actually return (only no-company customers) versus what the question asked for (every customer).
- **Typo'd `coalese` instead of `coalesce`** — caught on inspection before running.
- **Split the `CASE` version across two separate `SELECT ... FROM customer` statements**, expecting the alias from the first to carry into the second — aliases don't persist across separate statements; everything needed in the output has to live in one `SELECT` list.
- **Left off `END`** before `AS company_name` on the first `CASE` attempt — `CASE` is not closed until `END` appears, so nothing can follow it (like an alias) until that happens.
- **Wrote `first name` / `last name` with a space** instead of the actual column names (`first_name` / `last_name`) — an easy slip once attention shifts to the new `CASE` logic.
- **Left a duplicate, non-existent `company_name` column reference in `SELECT`**, sitting alongside the `CASE ... AS company_name` that was actually defining it — `company_name` isn't a real column in `customer`; it only comes into existence via the `CASE` expression's alias, so it can only appear once.
- **Missing comma** between `last_name` and the `CASE` expression — every item in a `SELECT` list, including a multi-line `CASE`, still needs the same comma separator as any other column.

---

## 7. CONCAT Syntax, LIKE/ILIKE Wildcard Mechanics, and IS vs. Pattern Operators — Full Name + Gmail Customers

### The question
Using Chinook, show every customer's first and last name combined into one column, but only for customers whose email contains "gmail.com".

### Why this one is a genuinely different shape again
Entries 1-6 were all about *which rows survive* or *what a null value displays as*. This question introduces two new jobs at once: **gluing two text columns into one** (`CONCAT`), and **matching text by pattern instead of by exact value** (`LIKE`/`ILIKE`). Neither of these existed anywhere in the earlier entries, so every syntax rule here had to be built from zero rather than reused.

### Real-world version of this same problem
Imagine a printed directory that lists "First Name" and "Last Name" in two separate columns, but you want a single mailing label that reads "Jane Smith" — you're not changing any data, you're gluing two fields together with a space in between for display. Separately, imagine flipping through that same directory looking for anyone whose email ends in a specific provider's domain, without caring about the exact address — you're not checking for one exact match, you're checking for a *shape* the text has to fit. Those are two unrelated jobs (formatting output vs. pattern-matching input) that this single question happens to need together.

### The concepts, explained from zero

**`CONCAT(a, b, c, ...)` joins values, but inserts nothing between them automatically.** `CONCAT(first_name, last_name)` with no separator glues `"François"` and `"Tremblay"` straight together into `"FrançoisTremblay"` — no space appears unless you put one there yourself, as its own literal-text argument: `CONCAT(first_name, ' ', last_name)`. The whole argument list needs parentheses around it — `concat first_name, last_name` with no parentheses is a syntax error, not just untidy formatting.

**`LIKE`/`ILIKE` compare text against a pattern, not an exact value — that's what the wildcards are for.**
- `%` matches *any run of characters, including zero* — it's the "whatever else is here" wildcard.
- `_` matches *exactly one character* — useful for fixed-length gaps, not used in this question but part of the same toolkit.
- Placement changes what's being asserted: `'text%'` = starts with `text`; `'%text'` = ends with `text`; `'%text%'` = contains `text` anywhere. These are three different claims about the string, even though they look like small punctuation differences.

**`LIKE` is case-sensitive; `ILIKE` is case-insensitive.** `LIKE '%GMAIL%'` will not match `gmail.com` in real data — the casing has to match literally. `ILIKE` runs the identical wildcard logic but ignores letter case entirely, so `'%GMAIL%'`, `'%Gmail%'`, and `'%gmail%'` all match the same rows under `ILIKE`.

**`IS` is not a general comparison operator — it only ever checks against `NULL`, `TRUE`, `FALSE`, or `UNKNOWN`.** Writing `WHERE email IS gmail.com` is invalid for two independent reasons: `IS` doesn't accept a text value on its right side at all, and `gmail.com` with no quotes is read as an identifier reference (a nonexistent column/table name), not as text. Fixing only the quoting (`IS 'gmail.com'`) still fails, because `IS` never does text equality — that job belongs to `=` for exact matches or `LIKE`/`ILIKE` for pattern matches.

**Double-quoted text is read as an identifier in Postgres, not as string data.** `WHERE email LIKE "gmail.com"` fails because Postgres treats double-quoted text as a reference to a column or table literally named `gmail.com` — which doesn't exist — producing a "column does not exist" error rather than a pattern-matching failure. This is the exact same mechanism that broke `WHERE company IS "NULL"` back in Entry #6 — double quotes always mean identifier, single quotes always mean text literal, no exceptions.

### The logic used to solve it (the actual reasoning trace)

1. **Split the question into its two separate jobs before writing anything**: (a) combine two columns into one display value, (b) filter rows by a text pattern. Trying to solve both at once in your head is where the confusion starts.
2. **For the combine job, reach for `CONCAT`** and remember it needs its own separator argument — decide up front what should sit between the two names (here, a single space, `' '`).
3. **For the filter job, ask: exact match, or pattern match?** "Contains gmail.com" is a pattern claim (something else could come before it), not an exact-value claim — that rules out `=` and rules in `LIKE`/`ILIKE`.
4. **Decide wildcard placement by rephrasing the question in plain English first**: "contains" → wildcard on both sides, `'%gmail.com%'`. "Ends with" and "starts with" would each only need one side wildcarded.
5. **Decide `LIKE` vs. `ILIKE` based on whether case should matter** — this question didn't specify, so either is defensible, but knowing which one enforces case-sensitivity was the actual thing being tested.
6. **Combine both pieces in one `SELECT ... WHERE ...` statement** — the `CONCAT` goes in `SELECT`, the pattern match goes in `WHERE`, and neither depends on the other.

### Full solution

```sql
SELECT CONCAT(first_name, ' ', last_name) AS full_name
FROM customer
WHERE email LIKE '%gmail.com%';
```

Returns 8 rows: François Tremblay, Helena Holý, Heather Leacock, Frank Ralston, Julia Barnett, Martha Silk, Dominique Lefebvre, Phil Hughes — identical whether the pattern is written `'%gmail.com%'` (contains) or `'%gmail.com'` (ends with), confirmed by actually re-running both live, since a domain like "gmail.com" can only ever appear at the very end of a real email address.

### The pattern to remember

**`CONCAT` glues values with no automatic spacing — every separator is a deliberate argument.** **`LIKE`/`ILIKE` compare against a pattern shape (built from `%` and `_`), never an exact value — `IS` and `=` are for exact matches only, and `IS` specifically only ever compares against `NULL`/`TRUE`/`FALSE`/`UNKNOWN`.** Whenever a question says "contains," "starts with," or "ends with," that's the signal to reach for `LIKE`/`ILIKE` with wildcards placed to match that exact phrasing.

### Best practices / general approach — if you see this kind of question again

- **Never assume `CONCAT` adds a space** — if the output needs one, write it as its own `' '` argument.
- **Translate "contains / starts with / ends with" into wildcard placement before typing the pattern** — get the English phrasing right first, the `%` placement follows directly from it.
- **Default to `LIKE` unless the question implies case shouldn't matter** — reach for `ILIKE` only when case-insensitivity is actually wanted.
- **Never quote a value with double quotes expecting it to behave like text** — double quotes mean identifier in Postgres, always; text literals are always single-quoted.
- **`IS` is reserved for `NULL`/`TRUE`/`FALSE`/`UNKNOWN`** — any other comparison, exact or pattern-based, needs `=` or `LIKE`/`ILIKE` instead.

### Mistakes made this time (new ones, not repeats)

- **Wrote `select concat first_name,last_name`** — missing the parentheses around the argument list entirely.
- **Wrote `CONCAT(first_name, last_name)` with no separator** — produced names glued together with no space, since `CONCAT` never inserts one automatically.
- **Wrote `WHERE email IS gmail.com`** — wrong operator (`IS` doesn't do text comparison at all) and unquoted text (read as a nonexistent identifier).
- **Tried `"gmail.com"` (double-quoted)** — read as an identifier reference by Postgres, producing a column/table-not-found style error rather than a text mismatch.
- **Tried `'gmail.com'` (single-quoted) with `IS`** — valid as text, but still wrong, since `IS` never performs text equality regardless of quoting.
- **Initially stated ILIKE was the case-sensitive one** — backward; `LIKE` is case-sensitive, `ILIKE` is case-insensitive. Self-corrected once the two were explicitly contrasted.
- **First wrote `'%gmail.com'` (ends-with) when the question asked "contains"** — happened to return the same rows here because a domain can only trail a real email address, but the wildcard placement didn't actually match the English phrasing of the question until corrected to `'%gmail.com%'`.

---

## 8. Matching SELECT Output to What the Question Literally Asks For — Track Names in Uppercase Alongside Original

### The question
Show every track's name in all uppercase, alongside its original name.

### Why this one matters despite being "just one function"
`UPPER()` itself was correct and used without hesitation on the first try — genuine evidence the string-function category is starting to stick. The actual lesson here isn't about the function at all: it's that **a query can run without errors, return a plausible-looking result, and still fail the question**, if the output doesn't contain everything that was actually asked for. This is a different failure mode from every earlier entry — not a syntax mistake, not a wrong table, not a wrong clause — just under-reading the question after the query "worked."

### Real-world version of this same problem
Imagine being asked to hand someone a printout with a phone number both formatted and in its raw form, "so they can compare the two." Handing over a printout with only the formatted version technically answers *part* of the request — it even looks complete — but it silently drops the "alongside the original" half of the ask. Nothing about the printout looks broken; the gap only shows up when you re-read the original request side-by-side with what you actually produced.

### The concept, explained from zero

**`UPPER(column)` converts text to all-uppercase, and only returns that one transformed value** — it doesn't remember or carry along the original alongside it automatically. If a question asks for the transformed value *and* the original, both have to be named explicitly in the `SELECT` list, comma-separated, exactly like any other pair of columns: `SELECT UPPER(name), name FROM track;`. The function call is just one item in the list; it doesn't entitle you to the source column for free.

**"Runs successfully" and "answers the question" are two different checks.** A query with no syntax errors that returns real rows has only cleared the first bar. The second check — does the output actually contain everything the question named — has to be done deliberately, by re-reading the question after the query executes, not assumed from the query having worked.

### The logic used to solve it (the actual reasoning trace)

1. **Identify the transformation needed**: "in all uppercase" → `UPPER()`. This part came immediately and correctly.
2. **Write the first-pass query and run it**: `SELECT UPPER(name) FROM track;` — runs cleanly, returns a full column of uppercase names.
3. **Re-read the original question against the actual output** — the question says "alongside its original name," and the output has only one column. That's the gap, not a syntax problem.
4. **Add the missing column to the same `SELECT` list**: `SELECT UPPER(name), name FROM track;` — both values now appear per row, side by side.

### Full solution

```sql
SELECT UPPER(name) AS name_upper, name
FROM track;
```

(An alias like `name_upper` isn't strictly required — `SELECT UPPER(name), name FROM track;` runs identically and was accepted as correct — but naming the transformed column makes the two side-by-side columns unambiguous in the output headers.)

### The pattern to remember

**A working query is not proof the question was fully answered — re-read the question against the actual columns in the output, every time, before moving on.** Any time a question uses the word "alongside," "compared to," "as well as," or "next to," that's a signal the output needs *multiple* columns, and it's worth explicitly counting how many things were asked for before calling the query done.

### Best practices / general approach — if you see this kind of question again

- **Count the deliverables in the question before writing `SELECT`** — "uppercase name, alongside original name" is two deliverables, not one, even though it reads as a single sentence.
- **After a query runs successfully, re-read the question one more time against the actual result columns** — a clean run is not the same as a complete answer.
- **Watch for comparison/pairing language ("alongside," "vs.," "next to," "compared with") as a trigger that multiple columns are required in the output.**

### Mistakes made this time (new ones, not repeats)

- **First query only selected `UPPER(name)`**, omitting the plain `name` column the question explicitly asked to show "alongside" the uppercase version — caught by re-reading the question against the query's actual output, not by any error message, since the query itself was syntactically correct.

---

## 9. Wildcard Placement (% vs. _) for "Starts With," Plus Re-Confirming LIKE/ILIKE Case Rules — Artists Starting With "B"

### The question
Find every artist whose name starts with the letter "B", case-insensitive.

### Why this one matters despite being "just another LIKE question"
Entry #7 already covered `LIKE`/`ILIKE` mechanics once, on a "contains" question. This entry is the same toolkit applied to a **different wildcard shape** ("starts with" instead of "contains"), and it surfaced a mistake that hadn't shown up yet: reaching for `_` (single-character wildcard) as if it were a general-purpose "mark where the letter goes" tool, rather than understanding it strictly means *exactly one character, no more, no less*.

### Real-world version of this same problem
Think of a phone book sorted A-Z, and someone asks "give me everyone in the B section." You wouldn't scan for people who merely *have* a B somewhere in their name (that's a different, much broader request) — you'd only check the very first letter of each name. "Starts with" is a claim about *position* (what's the first character), not about *presence* (does this letter show up anywhere at all).

### The concept, explained from zero

**`_` matches exactly one character — it is not a stand-in for "the letter goes here, and other stuff can surround it."** `'_B'` reads literally as "exactly one arbitrary character, immediately followed by the letter B, and then nothing else" — it would only match a two-character name like "AB" or "xB", not "Black Sabbath" or "BackBeat." The instinct to reach for `_` came from thinking of it as a flexible marker for "somewhere around here" — but `_` is the *least* flexible wildcard: one slot, one character, always.

**`%` matches any run of characters, including zero — that's the tool for "and then anything else follows."** A "starts with B" claim has two parts: (1) B is the very first character, and (2) after that, literally anything of any length (or nothing at all) can follow. Part 1 is satisfied by writing `B` literally, first, with nothing before it. Part 2 is satisfied by `%` immediately after it: `'B%'`.

**Wildcard placement always mirrors the plain-English shape of the claim being made:**
- "Starts with B" → the anchor (`B`) comes first, `%` trails after it → `'B%'`.
- "Ends with B" → `%` leads, anchor trails → `'%B'`.
- "Contains B" → anchor is sandwiched, `%` on both sides → `'%B%'`.
- "Exactly one character, then B" (a genuinely different, narrower claim) → `'_B'` — this is correct only when the question truly means "any single character, followed immediately by B," not as a general substitute for "somewhere."

**LIKE vs. ILIKE case rules, re-confirmed after an earlier reversal.** Restated correctly this time: `LIKE` is case-sensitive (exact letter case must match), `ILIKE` ignores case entirely. Since the question explicitly asked for case-insensitive matching, `ILIKE` was the correct choice — `LIKE 'B%'` would have missed any artist name that happened to be lowercase-first, even though none actually existed in this particular result set.

### The logic used to solve it (the actual reasoning trace)

1. **Translate "starts with" into a plain-English two-part claim**: (1) first character is B, (2) anything can follow.
2. **Write the anchor literally, in position**: `B` as the first character of the pattern, no wildcard before it.
3. **Attach `%` immediately after the anchor** to cover "anything (or nothing) follows": `'B%'`.
4. **Reject `_` once tested against what it actually matches** — walking through `'_B'` character-by-character revealed it demands exactly one character before B and nothing after, which doesn't match the question's actual shape at all.
5. **Choose `ILIKE` over `LIKE`** because the question explicitly said case-insensitive.
6. **Wrap the pattern in single quotes** — corrected from an initial unquoted `%B%`, which would have been read as a broken expression rather than a text pattern (same underlying rule as Entry #7: single quotes for text literals, always).

### Full solution

```sql
SELECT name
FROM artist
WHERE name ILIKE 'B%';
```

Returns 21 artists, all genuinely starting with "B" (BackBeat, Billy Cobham, Black Sabbath, Body Count, Bruce Dickinson, Buddy Guy, Bebel Gilberto, Baby Consuelo, Banda Black Rio, Barão Vermelho, Battlestar Galactica, Battlestar Galactica (Classic), Big & Rich, Black Eyed Peas, Ben Harper, and several full-orchestra names starting with "Berliner"/"Britten"/"Barry"/"Boston").

### The pattern to remember

**Wildcard placement is a direct translation of where the "anything goes" part of the claim sits in plain English — anchor text stays literal and fixed, `%` covers the open-ended part, and `_` is reserved for when the claim genuinely specifies an exact single-character gap, not as a general "somewhere around here" tool.**

### Best practices / general approach — if you see this kind of question again

- **Before writing the pattern, state the claim in plain English as "position + open-endedness"** — "starts with X" = X first, open after; "ends with X" = open before, X last; "contains X" = open on both sides.
- **Test `_` by asking "does this claim really mean exactly one character, or does it mean 'any number of characters'?"** — if the answer is "any number," `_` is the wrong tool regardless of how tempting it looks.
- **Re-check LIKE vs. ILIKE against the question's explicit wording every time** — "case-insensitive" in the question is a direct instruction to use `ILIKE`, not a detail to infer from the data.
- **Always single-quote the pattern string** — an unquoted pattern is a broken expression, not "a pattern SQL will figure out."

### Mistakes made this time (new ones, not repeats)

- **Wrote the pattern unquoted** (`like %B%`) — corrected by recalling the single-quote-for-text-literal rule from Entry #7.
- **Briefly restated LIKE/ILIKE case-sensitivity backward again** ("LIKE for case insensitive, ILIKE for case sensitive") before self-correcting once asked to walk back through the earlier confirmed rule — the same reversal from Entry #7, now surfaced a second time, suggesting this specific pairing needs one more deliberate cold-recall check before it's fully settled.
- **Reached for `_` as the tool for "starts with"** — treating it as a flexible placeholder for "the letter goes around here somewhere" rather than its actual strict meaning (exactly one character). Corrected by tracing what `'_B'` would literally require character-by-character, which made the mismatch with "starts with" obvious.
- **First pattern attempt was `'%B%'` (contains) instead of `'B%'` (starts with)** — matches a broader, wrong claim; corrected once the plain-English "anchor position + open-endedness" framing was applied.

---

## 10. Reusing CONCAT With a Different Separator — City, Country Combined

### The question
Show each customer's city and country combined into one column, formatted like `"Berlin, Germany"`.

### Why this one matters despite being "the same function again"
This is deliberately the same `CONCAT` skill from Entry #7, applied cold to a new pair of columns with a *different* separator (`', '` instead of `' '`). It came out correct on the first attempt, with no hesitation — real evidence that `CONCAT`'s "you must supply your own separator" rule generalized, rather than being memorized as "always put a space between names."

### The concept, reinforced
**The separator is just another literal-text argument — it changes based on what the output format actually needs, not a fixed part of `CONCAT`'s syntax.** Entry #7 needed `' '` (a single space) to glue a first and last name into one readable name. This question needed `', '` (comma-space) to glue city and country into the conventional "City, Country" format. Nothing about `CONCAT` itself changed — only the literal string passed as the middle argument, chosen to match the punctuation the output format called for.

### Full solution

```sql
SELECT CONCAT(city, ', ', country) AS city_country
FROM customer;
```

Returns 57 rows in the form "São José dos Campos, Brazil", "Berlin, Germany", "London, United Kingdom", etc. — comma-space separator applied consistently, exactly matching the requested format.

### The pattern to remember

**Any time a question specifies an exact output format (`"X, Y"`, `"X - Y"`, `"X (Y)"`), the punctuation between the pieces just becomes `CONCAT`'s next literal-text argument — read the required format first, then write that exact string as the separator.**

### Mistakes made this time

None — first attempt was correct, confirming the separator-argument rule from Entry #7 transferred cleanly to a new column pair and a new separator string.

---

## 11. TRIM for Blank-vs-NULL, and Why the Combining Operator Must Be OR Not AND — Tracks With NULL or Blank Composer

### The question
Find every track whose `composer` field is `NULL` or blank — trim any stray whitespace from `composer` first, in case blanks are hiding as spaces.

### Why this one is a genuinely new shape
Earlier entries dealt with `NULL` alone (Entry #6) or pattern-matching real text (Entries #7, #9). This question introduces a new function (`TRIM`) *and* a subtlety that doesn't show up until you actually reason about what `TRIM` does to a row that has no value at all — which is exactly where the first instinct (`AND`) quietly breaks.

### Real-world version of this same problem
Imagine sorting a stack of forms into "needs follow-up" if the "referred by" field is either left completely blank on the page, or has been filled in with just a few meaningless spaces (someone tapped the spacebar and walked away). You're not looking for two different kinds of problems that both have to be true on the same form — a single form is either missing the field entirely, *or* has it present-but-empty. It's never both at once, because a form that has nothing written can't simultaneously "have some spaces, once trimmed, that come out blank" — there's nothing there to trim in the first place.

### The concept, explained from zero

**`TRIM(column)` strips leading and trailing whitespace, leaving the middle untouched.** `TRIM('  John Lennon  ')` → `'John Lennon'`. `TRIM('    ')` (all spaces, nothing else) → `''` (empty string) — collapsing a "blank-looking" value down to something that's directly comparable with `= ''`.

**`NULL` and `''` are two different kinds of "nothing," and `TRIM` cannot convert one into the other.** `''` is an empty string — an actual value that exists, it simply has zero characters. `NULL` means no value was ever recorded — there's nothing there to even look at. `TRIM(NULL)` reflects this: you cannot strip whitespace off of something that isn't there, so `TRIM(NULL)` evaluates to `NULL`, never to `''`. This is the crux of the whole question.

**Why this makes `AND` fail silently, without an error.** Consider a row where `composer IS NULL`:
- The first half of `composer IS NULL AND TRIM(composer) = ''` is `TRUE`.
- The second half, `TRIM(composer) = ''`, requires comparing `NULL = ''` — which is never `TRUE` (comparisons against `NULL` come out unknown, not true or false) — so this half is not `TRUE`.
- `TRUE AND (not TRUE)` is not `TRUE` — the whole row gets thrown out, even though it's exactly the kind of row the question wants included.

`AND` doesn't error here — it just quietly excludes every genuinely-`NULL` composer row, which is worse than an error because the query *looks* like it worked.

**Why `OR` is correct instead.** With `composer IS NULL OR TRIM(composer) = ''`, a row only needs *one* side to be true. A `NULL` row satisfies the first half and is included, regardless of what the second half evaluates to. A row with `'    '` (only spaces) fails the first half (it's not `NULL`) but satisfies the second half once trimmed. Every row that's actually blank-or-missing gets caught by at least one side.

### The logic used to solve it (the actual reasoning trace)

1. **Split "NULL or blank" into two separate, testable conditions**: `composer IS NULL`, and `TRIM(composer) = ''` (after stripping stray whitespace).
2. **First attempt combined them with `AND`** — an assumption borrowed from ordinary English ("check for null-ness and blankness") rather than tested against an actual row.
3. **Tested that assumption against one concrete `NULL` row** by asking "what does `TRIM(NULL)` actually evaluate to?" — answer: `NULL`, not `''`, because there's nothing there to trim.
4. **Traced through what that means for the `AND`**: the second half can never be `TRUE` for a `NULL` row, so the whole `AND` condition can never be `TRUE` for that row — meaning every real `NULL` row would silently vanish from the results.
5. **Switched to `OR`**, since the question only needs *either* condition to hold per row, never both at once.

### Full solution

```sql
SELECT composer
FROM track
WHERE composer IS NULL OR TRIM(composer) = '';
```

Returns every track with a missing or blank-after-trimming composer — a large result set of empty-looking `composer` values, confirming the filter caught both the genuinely-`NULL` rows and any whitespace-only rows.

### The pattern to remember

**"X is missing, or X is present-but-blank" is always an `OR`, never an `AND` — because no single row can be both `NULL` and non-`NULL` (blank-but-present) at the same time. Test any `AND`/`OR` choice by picking one concrete row and asking whether both halves of the condition could actually be true for it simultaneously — if they can't, `AND` is wrong.**

### Best practices / general approach — if you see this kind of question again

- **Before combining two conditions with `AND` or `OR`, pick one concrete row and ask: "can both halves be true for this row at once?"** If yes, `AND` is likely right (or is at least possible); if no, `OR` is required.
- **Remember `TRIM(NULL)` is `NULL`, not `''`** — trimming can only act on a value that exists; it can't manufacture an empty string out of nothing.
- **"Blank" and "missing" are different states in SQL** — `''` is a real, zero-length value; `NULL` is the absence of any value. A check for one does not automatically catch the other.

### Mistakes made this time (new ones, not repeats)

- **First wrote `WHERE TRIM(column_name)` with no comparison at all** — `TRIM()` alone isn't a boolean condition; `WHERE` always needs something evaluated against a value (`= ''`, `IS NULL`, etc.), not just a bare function call.
- **Combined `composer IS NULL` and `TRIM(composer) = ''` with `AND`** — assumed from ordinary English phrasing ("null and blank") rather than tested against a concrete row; correctly reasoned to `OR` once asked to trace what `TRIM(NULL)` actually evaluates to and whether both halves could be true together.

---

## 12. EXTRACT for Date Parts, and Alias Visibility Across SELECT/GROUP BY/HAVING/ORDER BY — Invoices Per Year

### The question
Using Chinook, find how many invoices happened in each year — keep only years with more than 30 invoices, busiest year first.

### Why this one needs a new function, and re-tests an old rule from a new angle
Every earlier entry worked with text (`LIKE`, `CONCAT`, `TRIM`) or plain equality (`IS NULL`). This question is the first to touch a **date/timestamp** column, which introduces `EXTRACT` as a genuinely new function. It also drags the alias-visibility rule from Entry #2 (`HAVING` can't see `SELECT` aliases) back out, but in a new, sneakier shape: this time the trap wasn't `HAVING` at all — it was one item in the `SELECT` list trying to reference *another* item's alias, in that same list, before either had finished being built.

### Real-world version of this same problem
Think of a big ledger of receipts, each stamped with a full date like "14th March 2023, 10:42am." If someone asks "how many receipts came in each year, but only years with more than 30," you wouldn't retype every date by hand to pull out just the year — you'd point at the part of the stamp that already says "2023" and read off just that piece. That's `EXTRACT`: the date is already structured into named parts (year, month, day...), so getting the year is "read the label," not "cut apart some text."

### The concept, explained from zero

**`invoice_date` is a structured date/timestamp value, not plain text and not a number.** It's stored in a shape like `yyyy-mm-dd hh:mm:ss`, with year, month, day, hour, minute, and second already existing as distinct, named components — not characters at fixed positions to slice out, and not a bare integer to do math on.

**`EXTRACT(part FROM column)` reads off one of those named parts.** `EXTRACT(year FROM invoice_date)` returns just the year as a number, discarding month/day/time entirely. The keyword `FROM` inside the parentheses works the same way it does in `TRIM(BOTH 'x' FROM column)` — it's the same "which column this operates on" syntax shape, reused.

**A `SELECT`-list alias can't be referenced by another item in the *same* `SELECT` list.** `SELECT EXTRACT(year FROM invoice_date) AS year, COUNT(year) FROM invoice ...` fails with "column year does not exist" — not because `year` is a bad alias, but because Postgres evaluates each item in the `SELECT` list independently; `COUNT(year)` goes looking for a real column named `year` in the `invoice` table, finds none, and errors. This is the mirror image of Entry #2's `HAVING`-can't-see-`SELECT`-aliases rule: it's not just "later clauses can't see `SELECT` aliases," it's "nothing inside `SELECT` can see another `SELECT` item's alias either, since they're all built at the same time, not one after another."

**`COUNT(*)` counts rows, not a specific column's values.** Since the real goal was "how many invoices," not "how many values are in a column called year," the fix wasn't renaming anything — it was swapping `COUNT(year)` for `COUNT(*)`, which counts every row in the group regardless of column.

**`GROUP BY` and `ORDER BY` *can* use a `SELECT` alias, even though other `SELECT` items can't.** `GROUP BY year` and `ORDER BY year DESC` both worked using the alias, because Postgres specifically allows `GROUP BY`/`ORDER BY` to reference output column names as a convenience — different treatment from a plain expression sitting inside the `SELECT` list itself.

### The logic used to solve it (the actual reasoning trace)

1. **Translate "how many invoices happened in each year" into its two working pieces**: (a) pull just the year out of `invoice_date` — `EXTRACT(year FROM invoice_date)`; (b) count rows per year — `COUNT(*)` with a `GROUP BY`.
2. **First attempt tried `COUNT(year)`**, reusing the alias from the `EXTRACT` expression sitting right above it — ran, and immediately errored with "column year does not exist."
3. **Traced the error back to what `year` actually is**: an alias invented in this query, not a real column in `invoice` — so nothing in the same `SELECT` list can reference it yet.
4. **Swapped to `COUNT(*)`**, since the actual goal was "count rows," not "count values in a column called year."
5. **Added `ORDER BY count(*) DESC`** to put the busiest year first — worked directly, no alias needed since it referenced the raw aggregate expression.
6. **Tested whether `ORDER BY year DESC` (the alias) would also work**, reasoning it through first: `ORDER BY` runs after `SELECT`, so the alias should already exist by then — confirmed correct by running it.
7. **Added `HAVING count > 30`** — first attempt omitted the parentheses (`count` isn't a valid function call by itself), corrected to `HAVING count(*) > 30` by comparing it against every other `count(*)` already written correctly elsewhere in the same query.

### Hand-trace through the actual result

`invoice` has 5 distinct years, each holding roughly 80 invoices:

| year | count(*) |
|---|---|
| 2021 | 83 |
| 2022 | 83 |
| 2023 | 83 |
| 2024 | 83 |
| 2025 | 80 |

After `HAVING count(*) > 30`: all 5 years survive (every year comfortably clears 30).
After `ORDER BY year DESC`: rows re-sorted to 2025, 2024, 2023, 2022, 2021 — most recent year first.

### Full solution

```sql
select EXTRACT(year FROM invoice_date) AS year,
  count(*)
from invoice
group by year
having count(*) > 30
order by year desc;
```

### The pattern to remember

**`EXTRACT(part FROM date_column)` reads a named component off a structured date value — no slicing, no character counting, just naming the part you want.** **A `SELECT`-list alias is invisible to every other item in that same `SELECT` list (just like it's invisible to `WHERE`/`HAVING`), but becomes visible the moment a later clause — `GROUP BY`, `HAVING`'s aggregate aside, or `ORDER BY` — runs after `SELECT` has finished building.** When in doubt about whether an alias can be used somewhere, ask: "has `SELECT` already finished running by the time this clause executes?"

### Best practices / general approach — if you see this kind of question again

- **Recognize "per year / per month / per day" phrasing as an `EXTRACT` + `GROUP BY` question** — pull the date part first, then group and aggregate on it exactly like grouping on any other column.
- **Never reference one `SELECT`-list alias from inside another item in the same `SELECT` list** — if you need the same expression twice, repeat the full expression, don't assume the alias is live yet.
- **`COUNT(*)` for "how many rows" — `COUNT(column)` only when you specifically want to count non-`NULL` values in a real column.** If the column name being counted is actually just an invented alias, that's the tell something's wrong.
- **`GROUP BY` and `ORDER BY` are the two clauses that *do* accept `SELECT` aliases** — `WHERE`, `HAVING`, and other `SELECT` items do not. When stuck, ask "does this clause run before or after `SELECT` finishes?"
- **Any bare aggregate name used in a comparison (`having count > 30`) needs its parentheses** — `count` alone isn't a function call, `count(*)` is.

### Mistakes made this time (new ones, not repeats)

- **Guessed `EXTRACT` worked like character-slicing** (`LEFT`/`RIGHT`, counting characters) before confirming `invoice_date` was a structured date/timestamp value, not text — corrected by checking the actual column output shape first.
- **Wrote `count(year)`**, referencing the `EXTRACT(...) AS year` alias from the same `SELECT` list — triggered "column year does not exist," since that alias isn't a real column and isn't visible yet to a sibling `SELECT` item. Fixed by switching to `COUNT(*)`.
- **Wrote `having count > 30`** — omitted the parentheses that make `count` an actual function call. Caught by comparing it against the correctly-formed `count(*)` already used earlier in the same query.

---

## 13. Confirming EXTRACT Transfers Across Date Parts — Invoices Per Month, All Years Combined

### The question
Using Chinook, find how many invoices happened in each month, combining all 5 years together (so "January" means every January across every year, not broken out by year).

### Why this one matters despite reusing the exact same skeleton
This is a deliberate cold-transfer test: the entire query shape from Entry #12 (`EXTRACT` + `GROUP BY` + `COUNT(*)` + `ORDER BY`) was reapplied with only one change — `year` swapped for `month` — and it came out correct on the first attempt, no new syntax mistakes at all. The one real event worth logging wasn't a SQL error; it was **trusting a remembered/pasted result over re-running the query fresh**, which produced a false alarm.

### The concept, reinforced

**"Across all years" is a signal to *not* include year in the grouping at all.** The question could have been misread as "per month per year" (60 possible groups: Jan 2021, Jan 2022, ...), but "across all years" explicitly collapses that distinction — every January, regardless of year, belongs to one single "month 1" group. `GROUP BY month` alone (no `year` in the grouping) is what produces that collapse; the moment `year` gets added back into `GROUP BY`, the months start splitting apart by year again.

**A working pattern from one date part transfers directly to another.** Nothing about `EXTRACT(month FROM invoice_date)` needed to be re-derived from scratch — it's the identical function, identical `FROM` syntax, identical surrounding `GROUP BY`/`COUNT(*)`/`ORDER BY` shell as the year version, just naming a different part.

**Never trust a result you're recalling or re-pasting — always re-run fresh before trusting an unexpected pattern.** A first paste showed `ORDER BY month DESC` apparently returning ascending order (1 → 12), which looked like a genuine bug. Re-running the exact same query live showed it correctly descending (12 → 1) — the original paste was stale, not a real error. This is the same lesson from an earlier session's 59-row/8-row Gmail mixup: before concluding a query is broken, re-run it live and paste that exact fresh output, not a remembered or earlier-tab result.

### Full solution

```sql
select EXTRACT(month FROM invoice_date) AS month,
count(*)
from invoice
group by month
order by month desc;
```

Returns 12 rows (month 12 down to month 1), each showing invoice counts in the low-to-mid 30s per month, summing to 412 total invoices across all 5 years — consistent with the ~80-83 invoices per year from Entry #12.

### The pattern to remember

**"Combine X across all Y" means Y does not appear in `GROUP BY` at all — only group by the dimension actually named in the question.** And separately: **when a result looks wrong in a way that contradicts working logic, re-run the query live before trusting the paste — a stale or cached result panel produces symptoms that look exactly like a real bug.**

### Mistakes made this time

None in the SQL itself — the `EXTRACT`/`GROUP BY`/`COUNT(*)`/`ORDER BY` pattern transferred cleanly from `year` to `month` with no correction needed. The only "mistake" was a false alarm from pasting a stale result instead of a fresh one, resolved by re-running live.

---

## 14. AGE for Elapsed Time, INTERVAL Literals, and Casting Syntax Mix-Ups — Time Since Each Invoice; Invoices Older Than 4 Years

### The questions
1. Using Chinook, for each invoice, find how much time has passed between its `invoice_date` and today.
2. Using Chinook, find every invoice that happened more than 4 years ago — filtering with `AGE`, not a hardcoded date.

### Why this one needs new techniques, on top of an old rule from a new angle
Every earlier entry either filtered/grouped rows or substituted a display value — nothing so far needed to compute a *duration*. This pair of questions introduces two brand-new pieces (`AGE`, `INTERVAL`) and drags the `WHERE`-can't-see-`SELECT`-aliases rule (Entries #2, #3, #12) back out in yet another shape: this time inside a plain single-table query, no `JOIN`/`GROUP BY` involved at all — proof that rule isn't tied to aggregation queries specifically, it's tied to clause execution order, full stop.

### Real-world version of this same problem
Think of a filing cabinet of receipts, each stamped with a date. "How long ago was each receipt?" means holding today's date next to each stamp and reading off the gap — years, months, days — not just subtracting two numbers. Separately, "find every receipt from more than 4 years back" means picking a *length of time* (not a specific calendar date) as the cutoff and checking whether each receipt's gap is bigger than that length. Both are about a *span* of time, not a point in time — which is exactly what `AGE` and `INTERVAL` are built for.

### The concepts, explained from zero

**`AGE(column)` returns a structured `interval`, not a plain number.** `AGE(invoice_date)` computes the elapsed time between `invoice_date` and right now, but the result isn't a single number of days — it's an `interval` value broken into years/months/days (displayed here as `{"years":5,"months":7,"days":8}` by the query tool). That structure matters because it means the result can't be compared against a bare number like `4` — it needs another `interval` on the other side of any comparison.

**Casting syntax: `timestamp 'literal'` works only with a quoted string, never a column name.** The first attempt, `AGE(timestamp invoice_date)`, tried to "cast" the column by sticking the word `timestamp` in front of it — but that specific syntax shape (`typename 'string'`) is Postgres's way of writing a *literal* value of that type, e.g. `timestamp '2023-01-01'`. It's not a general casting operator, and it doesn't accept a bare column name where the quoted string goes — that produces a syntax error. (The general-purpose casts, `CAST(expr AS type)` or `expr::type`, weren't even needed here once it turned out `invoice_date` was already `timestamp without time zone` — confirmed directly via `information_schema.columns` rather than assumed.)

**Checking a column's actual type beats guessing.** Rather than guessing whether `invoice_date` needed a cast, running `SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'invoice';` gave a direct answer: already a `timestamp`. That made the whole cast attempt unnecessary — `AGE(invoice_date)` alone was correct.

**`WHERE` can't see a `SELECT`-list alias — same rule, new context.** `WHERE date_days < ...` failed for the same structural reason `HAVING alias_name` fails in Entries #2/#3, and the same reason `COUNT(year)` failed in Entry #12: `WHERE` runs before `SELECT` builds `date_days`, so that name doesn't exist yet at the point `WHERE` evaluates. The fix is always the same regardless of *which* clause or *which* alias — repeat the full expression (`AGE(invoice_date)`), don't reference the shorthand name.

**Double quotes vs. single quotes — the same trap as Entries #6 and #7, reoccurring.** `WHERE date_days < "years: 4"` used double quotes around what was meant to be a literal value. Double quotes are for identifiers in Postgres; single quotes are for literal text/values. `"years: 4"` would be read as a reference to a column/identifier literally named `years: 4`, not as data.

**`INTERVAL 'n unit'` is how a literal time span gets written.** `INTERVAL '4 years'` means exactly that — a 4-year-long span, comparable against another `interval` like the output of `AGE()`. Other units work the same way: `INTERVAL '3 months'`, `INTERVAL '10 days'`.

**Postgres can sometimes infer the cast without the `INTERVAL` keyword.** The final query used `AGE(invoice_date) > '4 years'` — no `INTERVAL` keyword at all — and it still worked, because Postgres saw the left side of `>` was already an `interval` and cast the right-side string to match. This is implicit type inference from context, not a general rule that quotes alone always work — writing `INTERVAL '4 years'` explicitly stays the clearer habit going forward.

**Direction of the comparison must match "more than," not "less than."** "More than 4 years ago" means the elapsed time (`AGE`) is *greater than* 4 years — `>`, not `<`. An early attempt had this backwards (`date_days < ...`), diagnosed afterward as plain tunnel vision rather than a misunderstanding of what `AGE` measures.

### The logic used to solve it (the actual reasoning trace)

1. **Question 1 — "how long ago was each invoice?"** translates directly to `AGE(invoice_date)` — one function call, no `GROUP BY`, no `JOIN`, just a per-row calculation.
2. **First attempt over-engineered a cast** (`AGE(timestamp invoice_date)`) before checking whether one was even needed — corrected by querying `information_schema.columns` and confirming `invoice_date` was already `timestamp without time zone`.
3. **Dropped the cast entirely**, ran `SELECT AGE(invoice_date) AS date_days FROM invoice;` — worked, returning one `interval` per row.
4. **Question 2 — "invoices more than 4 years old"** translates to reusing the same `AGE(invoice_date)` expression, this time inside a `WHERE` clause with a comparison against a 4-year span.
5. **First attempt referenced the `SELECT`-list alias inside `WHERE`** (`WHERE date_days < ...`) — self-diagnosed correctly before even running it, by applying the same execution-order rule from Entries #2/#3/#12: `WHERE` can't see `SELECT` aliases.
6. **Second attempt used double quotes and made-up interval text** (`WHERE date_days < "years: 4"`) — three separate issues at once (alias reuse, wrong quote type, invalid interval syntax), each individually diagnosed and fixed rather than patched all at once by guesswork.
7. **Learned the `INTERVAL 'n unit'` literal syntax fresh** (hadn't been used anywhere in this project before), then assembled the final corrected query: repeat the full `AGE(invoice_date)` expression in `WHERE`, single-quote the literal, use `'4 years'` (implicitly cast to `interval`), and flip the operator to `>` for "more than."

### Full solution

```sql
-- Question 1: time elapsed since each invoice
select age(invoice_date) as date_days
from invoice;

-- Question 2: invoices more than 4 years old
select age(invoice_date) as date_days
from invoice
where age(invoice_date) > '4 years';
```

### The pattern to remember

**`AGE(column)` measures a span, and spans compare against other spans (`INTERVAL` literals), not bare numbers.** Any question shaped like "how long ago," "how old," or "more than N years/months/days since X" is an `AGE` + `INTERVAL`-comparison question — compute the `AGE` first, then compare it against a matching `INTERVAL` value, remembering to repeat the full `AGE(...)` expression in `WHERE` rather than reaching for its `SELECT`-list alias.

### Best practices / general approach — if you see this kind of question again

- **Check a column's actual data type before assuming it needs a cast** — `information_schema.columns` gives a direct answer in seconds; guessing wastes a whole failed attempt.
- **`typename 'literal'` casting syntax (e.g. `timestamp '2023-01-01'`) only accepts a quoted string, never a bare column name** — that's not how you cast an existing column; use `CAST(col AS type)` or `col::type` if a real cast is ever needed.
- **`AGE()`'s output is an `interval`, not a number — always compare it against another `interval`**, written as `INTERVAL 'n unit'` (or a quoted string Postgres can infer as one from context).
- **The alias-visibility rule is not specific to `JOIN`/`GROUP BY` queries** — it's about clause execution order in general (`WHERE` always runs before `SELECT`), so it shows up even in the simplest single-table query.
- **"More than N [time unit] ago" means `AGE(...) > INTERVAL 'N unit'`** — double-check the comparison direction against the actual English phrasing before running, since this is an easy one to reverse under tunnel vision.

### Mistakes made this time (new ones, plus one repeat)

- **Tried `AGE(timestamp invoice_date)`** — invalid cast syntax, and an unnecessary cast in the first place since the column was already a `timestamp`. Fixed by checking the real column type directly instead of assuming.
- **Referenced the `SELECT`-list alias (`date_days`) inside `WHERE`** — the same alias-visibility mistake as Entries #2, #3, and #12, in a new (non-aggregating, single-table) context. Self-diagnosed correctly on sight this time, without needing it pointed out first.
- **Used double quotes around a literal value** (`"years: 4"`) — the same quote-type mix-up as Entries #6 and #7, self-acknowledged as an ongoing weak spot ("the quotes thing is difficult — I keep forgetting").
- **Wrote a made-up interval string** (`"years: 4"`) instead of the actual `INTERVAL 'n unit'` syntax — a genuinely new piece of syntax that hadn't been introduced yet, not a slip on something already known.
- **Used `<` instead of `>`** for "more than 4 years ago" — self-diagnosed as tunnel vision rather than a conceptual gap about what `AGE` measures.

---

## 15. WHERE Needs a Boolean, Not a Computed Value; `timestamp + interval` vs. `interval + interval` — Each Invoice's Date Shifted 6 Months Forward

### The question
Using Chinook, for each invoice, calculate what date it would be exactly 6 months after `invoice_date`.

### Why this one matters despite reusing familiar pieces
This question deliberately reuses `INTERVAL` (just introduced in Entry #14) in a completely different role: not comparing against `AGE()`, but doing arithmetic directly on a date to produce a new date. Two wrong turns surfaced along the way, both genuinely new failure modes rather than repeats.

### The concepts, explained from zero

**`WHERE` always needs a true/false answer, never a value to compute or display.** The first attempt, `WHERE invoice_date + interval '6 months';`, tried to put a date-shift calculation — something meant to be *seen in the output* — inside `WHERE`, which only ever decides which rows survive. Postgres's own error said it plainly: *"argument of WHERE must be type boolean, not type timestamp without time zone."* Same underlying idea as Entry #6 (filtering vs. substituting): a calculation that produces a value to display belongs in `SELECT`, not `WHERE`.

**`interval + interval` and `timestamp + interval` are not the same operation, even though both type-check.** The second attempt, `AGE(invoice_date) + INTERVAL '6 months'`, ran without any error — but `AGE(invoice_date)` is itself already an `interval` (an elapsed span), so adding `INTERVAL '6 months'` to it just produces a *bigger interval* (e.g., `5 years 7 months 8 days` becomes `6 years 1 month 8 days`). That's a valid calculation, just not the one the question asked for — it answers "what would this span be if it were 6 months longer," not "what calendar date is 6 months after the invoice." The fix: skip `AGE()` entirely and add the interval straight onto the real `timestamp` column, `invoice_date + INTERVAL '6 months'`, which returns an actual new date (`timestamp` type in, `timestamp` type out).

**The result type always follows the operand types, not the goal in your head.** `timestamp + interval = timestamp` (a point in time, shifted). `interval + interval = interval` (still just a duration, now a different length). Knowing this in advance means checking "what type is this column already?" before adding an interval to it, rather than discovering the mismatch from the shape of the output afterward.

### The logic used to solve it (the actual reasoning trace)

1. **First attempt put the whole calculation inside `WHERE`** — caught immediately by Postgres's own boolean-type error, which was specific enough to diagnose directly rather than needing a hint.
2. **Recognized the fix was "move this into `SELECT`,"** echoing Entry #6's WHERE-vs-substitution distinction, but reached for `AGE(invoice_date) + INTERVAL '6 months'` — reusing the `AGE()` wrapper out of habit from the immediately preceding entry, without checking whether it was still needed.
3. **That version ran and returned output**, but a check of the actual values (still shaped like `{"years":6,"months":1,"days":8}`, not a calendar date) revealed it hadn't answered the question — the same "a working query can still under-deliver on what was literally asked" lesson as Entry #8, here triggered by output *type* rather than output *content*.
4. **Dropped `AGE()` entirely**, added the interval directly to `invoice_date`, and got back genuine calendar dates (`2021-07-01`, `2021-07-02`, ...) — one date per invoice, each exactly 6 months later.

### Full solution

```sql
select invoice_date + interval '6 months' as date_days
from invoice;
```

### The pattern to remember

**A calculation meant to appear in the output goes in `SELECT`; a calculation meant to decide which rows survive goes in `WHERE` — and `WHERE` will refuse anything that isn't boolean, loudly and specifically.** Separately: **before adding an `INTERVAL` to something, check whether that something is already a `timestamp` (arithmetic gives a new date) or already an `interval` (arithmetic gives a bigger/smaller span) — the two look similar in a query but produce entirely different kinds of answers.**

### Best practices / general approach — if you see this kind of question again

- **"What date would it be N [unit] after/before X" is a `SELECT`-only date-arithmetic question** — `column + INTERVAL 'n unit'` or `column - INTERVAL 'n unit'`, no `AGE()` involved at all, since the goal is a new date, not an elapsed span.
- **Reserve `AGE()` for "how long ago" / "how much time has passed" questions** — reach for it only when the question wants a *duration*, not a *date*.
- **Postgres's boolean-type error on `WHERE` is a direct, trustworthy signal** — no need to guess; it names the exact type mismatch.
- **After any query runs successfully, glance at the actual shape of the output before trusting it** — an interval-shaped result (`{"years":...}`) versus a date-shaped result (`2021-07-01 00:00:00`) is visible at a glance and immediately confirms (or disproves) whether the right operand types were used.

### Mistakes made this time (new ones, not repeats)

- **Put a date-shift calculation inside `WHERE`** — a new variant of the "filtering vs. substituting/computing" confusion from Entry #6, this time producing a hard type error rather than silently wrong row counts.
- **Reused `AGE()` out of habit** from the immediately preceding question, producing `interval + interval` instead of `timestamp + interval` — caught by checking the output's shape against what the question literally asked for (a date, not a span), the same discipline as Entry #8.

---

## 16. Conditional Aggregation — `CASE WHEN`/`IN` Nested Inside `COUNT` — Candidates With All Required Skills

### The question
Given a `candidates` table (`candidate_id`, `skill`, one row per candidate per skill they have), find every candidate who has **all three** of `Python`, `Tableau`, and `PostgreSQL`. Output just `candidate_id`, sorted ascending. (Assumption given in the problem: no duplicate rows in the table.)

### Why this one matters
Every individual piece — `GROUP BY`, `HAVING`, `COUNT`, `CASE WHEN`, `IN` — had already been used separately in earlier entries. What was actually new was **nesting them three layers deep inside one expression**: `IN` inside a `CASE WHEN`, that `CASE` inside a `COUNT`, that `COUNT` inside a `HAVING`. Read as a whole it looks intimidating; read inside-out, each layer is a function already known.

### Real-world version of this same problem
A hiring manager has a checklist of 3 must-have skills and a stack of resumes, one skill sticky-note per resume-skill. For each candidate's pile of sticky notes, they flip through and mark a tally mark only on notes that match something on the checklist, ignoring the rest — then only keep candidates whose tally hits exactly 3 (all three checklist items found, not just "some"). That's the whole query: tally-mark-if-it-matches, per row, then keep only the piles that hit the full checklist count.

### The concept, explained from zero

**`IN (list)` is shorthand for a chain of `OR`s.** `skill IN ('Python','Tableau','PostgreSQL')` means exactly `skill = 'Python' OR skill = 'Tableau' OR skill = 'PostgreSQL'`. Nothing more exotic than that — same case-sensitivity as `=`/`LIKE` (not `ILIKE`), works anywhere a boolean is expected (`WHERE`, `HAVING`, inside a `CASE WHEN`).

**Reading a nested expression means working from the innermost layer outward:**
1. Innermost: `skill IN (...)` — per row, true or false.
2. Next: `CASE WHEN <that> THEN 1 END` — turns each row's true/false into a real value: `1` if true, `NULL` if false (no `ELSE` means "fall through to `NULL`," same rule as Entry #6).
3. Next: `COUNT(...)` — tallies only the non-`NULL` results per group. This is nothing new about `COUNT` itself — `COUNT(column)` has always skipped `NULL`s (Entry #10's "`COUNT(*)` vs `COUNT(column)`" distinction); the `CASE` is just deliberately feeding it a column that's `NULL` exactly where you don't want a row counted.
4. Outermost: `HAVING <that count> = 3` — keeps only groups where all 3 required skills were found.

**`HAVING` (like `WHERE`) always needs something that evaluates to true/false — a comparison is the normal way to get that**, but not the only shape (`IN`, `EXISTS`, `BETWEEN` all work too, same as in `WHERE`).

**Plain `COUNT(CASE WHEN ... THEN 1 END)` silently over-counts if a candidate has a duplicate skill row.** Traced by hand: candidate with rows `Python, Python, Tableau` (2 distinct skills, missing `PostgreSQL`) still produces `COUNT = 3` (three rows match the `IN` list, `CASE` returns `1, 1, 1`), wrongly passing `HAVING = 3` despite genuinely missing a required skill. The fix is `COUNT(DISTINCT ...)` — but `DISTINCT` needs something to distinguish *by*, so the `CASE` has to return the actual `skill` value (not a flat `1`) for `DISTINCT` to dedupe against: `COUNT(DISTINCT CASE WHEN skill IN (...) THEN skill END)`. This problem's stated assumption ("no duplicates in the table") is exactly what makes the simpler, non-`DISTINCT` version safe to submit here — it would not be safe in general.

### The logic used to solve it (the actual reasoning trace)

1. **Recognized the shape**: "has all of a required set of things" → need to count, per candidate, how many of the required items showed up, and compare that count to the size of the required list.
2. **First attempt wrote `CASE WHEN IN (...) THEN 1 END`** — missing the column being tested; `IN` needs something in front of it (`skill IN (...)`), not floating on its own.
3. **Also wrote the wrong table/column names initially** (`customers`/`customer_id` instead of `candidates`/`candidate_id`) — caught by comparing against the problem statement's actual schema.
4. **Fixed both, landed on the correct working query.**
5. **Hand-traced a duplicate-skill scenario afterward** (not required by this problem, but worth knowing) to see *why* the "no duplicates" assumption matters, and confirmed `COUNT(DISTINCT CASE WHEN ... THEN skill END)` (or filtering with `WHERE` first, then `COUNT(DISTINCT skill)`) is the version that's safe even with duplicates.

### Full solution

```sql
select candidate_id from candidates
group by candidate_id
having count(case when skill in ('Python','Tableau','PostgreSQL') then 1 end) = 3
order by candidate_id asc;
```

General-purpose (safe with duplicates) version:
```sql
select candidate_id from candidates
where skill in ('Python','Tableau','PostgreSQL')
group by candidate_id
having count(distinct skill) = 3
order by candidate_id asc;
```

### The pattern to remember

**"Does this group contain all of a required set of N items?" → count how many of those items are present per group (via `CASE WHEN ... IN (...)`, or by filtering first with `WHERE ... IN (...)`), then `HAVING COUNT(...) = N`.** Use `COUNT(DISTINCT ...)` whenever duplicate rows are possible — plain `COUNT` only stays safe under an explicit no-duplicates guarantee. Read any nested expression inside-out: innermost condition first, then what wraps it, then what wraps that.

### Best practices / general approach — if you see this kind of question again

- **"Has all of X, Y, Z" (not just "has any of them")** is a signal for count-and-compare-to-N, not a plain filter — a plain `WHERE ... IN (...)` alone would return candidates missing some of the required skills too.
- **`IN` always needs a column/expression directly in front of it** — `IN (...)` floating alone (inside a `CASE` or anywhere else) is a syntax error, not a warning.
- **Default to `COUNT(DISTINCT ...)` for this pattern unless a no-duplicates guarantee is explicitly given** — cheap insurance against silent over-counting.
- **When a nested expression looks intimidating, peel it from the inside out**: identify the innermost condition, then work outward one function at a time, rather than trying to read it left-to-right in one pass.

### Mistakes made this time (new ones, not repeats)

- **Wrote `CASE WHEN in (...) THEN 1 END`** — omitted the column (`skill`) that `IN` needed to test against.
- **Used the wrong table/column names from memory** (`customers`/`customer_id`) before correcting to the problem's actual `candidates`/`candidate_id`.
- **Initial working query didn't guard against duplicate skill rows** — correct under this problem's stated assumption, but not the general-purpose version; surfaced only after a deliberate hand-trace of a duplicate scenario.

---

## 17. `LEFT JOIN` + `IS NULL` Anti-Join Pattern — Facebook Pages With Zero Likes

### The question
Given `pages(page_id, page_name)` and `page_likes(user_id, page_id, liked_date)`, find every page's `page_id` that has **zero** likes. Sort ascending.

### Why this one matters
Every prior `JOIN` question used `INNER JOIN`, which only ever returns rows that *do* match on both sides. This question needed the opposite: rows from `pages` that have **no** corresponding row in `page_likes` at all. `INNER JOIN` can't produce that — it was never taught, so this is a genuinely new tool, not a variation on a known one.

### Real-world version of this same problem
A full class roster, and a sign-up sheet listing who submitted a particular homework assignment. To find "everyone who *didn't* submit," handing someone just the sign-up sheet is useless — anyone who never signed up simply never appears on it. What's actually needed is the *entire roster*, with each name checked against the sign-up sheet, keeping only the names that came up empty on that check.

### The concept, explained from zero

**`INNER JOIN` only keeps a row if it finds a match on both sides — no match, no row, on either side.** This was already known, but the new insight is what that implies: a page with 0 likes has 0 matching rows in `page_likes`, so `INNER JOIN` throws it out *before* any `WHERE` clause ever runs. There is nothing left by the time you'd try to check for "zero" — the row simply isn't in the result to check.

**`LEFT JOIN` keeps every row from the table named right after `FROM` (the "left" table), no matter what.** If a match exists, it attaches the matching row's data. If no match exists, the row still survives — but every column that would have come from the right-hand table comes back as `NULL`. So `pages LEFT JOIN page_likes` keeps all pages, including ones with zero likes; for those, `page_likes.user_id`, `page_likes.page_id`, and `page_likes.liked_date` are all `NULL`.

**`LEFT JOIN` alone isn't the full answer — it keeps *everyone*, matched and unmatched together.** The extra step is filtering afterward with `WHERE <right_table>.<column> IS NULL`, which only ever comes out true for the unmatched rows (a genuinely missing right-side value), never for a matched row (which always has real data there). This is the two-part "anti-join" recipe: `LEFT JOIN` to keep everything + `WHERE right_table.column IS NULL` to isolate only what didn't match.

**Which column to check `IS NULL` against matters.** `pages.page_id` is never `NULL` — it's the left/"always present" side of the join. `page_likes.page_id` is exactly the column that goes `NULL` when nothing matched. Checking the wrong side's column silently breaks the whole query (it would just never filter anything, since `pages.page_id` is always populated).

**Ambiguous columns reappear post-`JOIN`, same as Entry #4.** Once `page_id` exists in both `pages` and `page_likes`, a bare `PAGE_ID` in `SELECT`/`GROUP BY`/`ORDER BY` is ambiguous and errors — needs table-prefixing (`pages.page_id`), same fix as before, just triggered by a new query shape.

**No aggregation needed here.** This is a plain existence check ("does a match exist, yes/no"), not a count/sum/average — `GROUP BY` isn't required at all, even though it's tempting to reach for out of habit whenever a `JOIN` is involved.

### The logic used to solve it (the actual reasoning trace)

1. **First draft used `INNER JOIN`** (the only join known at the time) plus `WHERE page_id IS NULL` placed after `GROUP BY` — both a clause-order syntax error and a table-name typo (`PAGE_LIKE` vs `PAGE_LIKES`).
2. **Fixed the naming and clause order**, then reasoned explicitly that no aggregation was happening, so `GROUP BY` wasn't needed.
3. **Walked through what `INNER JOIN` actually does to an unmatched page** (page `20701`, zero likes) and concluded correctly, unprompted, that it gets dropped entirely — meaning no later `WHERE` could ever catch it.
4. **Learned `LEFT JOIN` from scratch** (new to Phase 2, pulled forward early), and identified correctly, on the first attempt, that `page_likes.page_id` (not `pages.page_id`) is the column that goes `NULL` on unmatched rows.
5. **Re-added `GROUP BY` out of habit** on the next draft despite having already reasoned it wasn't needed — caught and dropped in the final cleanup pass, alongside fixing the ambiguous-column reference on both `SELECT` and `GROUP BY`.

### Full solution

```sql
select pages.page_id
from pages
left join page_likes
on pages.page_id = page_likes.page_id
where page_likes.page_id is null
order by pages.page_id asc;
```

### The pattern to remember

**"Find rows in A with nothing matching in B" = `LEFT JOIN` (A first) + `WHERE B.column IS NULL`.** `INNER JOIN` can never do this job, because it deletes the exact rows you're trying to find before a `WHERE` clause gets a chance to look at them. Always check `IS NULL` against a column from the *right-hand* (joined) table, never the left table's own key — the left table's key is never `NULL` by construction.

### Best practices / general approach — if you see this kind of question again

- **"Has none of," "zero," "never," "no matching X"** is the trigger phrase for this pattern — reach for `LEFT JOIN` + `IS NULL`, not `INNER JOIN`.
- **Always check `IS NULL` on the joined (right-hand) table's column**, not the anchor table's — checking the wrong side silently returns nothing useful instead of erroring.
- **Re-apply the ambiguous-column fix (Entry #4) every time a shared column name survives past a `JOIN`** — table-prefix it in `SELECT`, `WHERE`, `GROUP BY`, and `ORDER BY` alike.
- **Don't reach for `GROUP BY` just because a `JOIN` is present** — only add it when something is actually being aggregated (counted, summed, averaged) per group; a plain existence check doesn't need it.

### Mistakes made this time (new ones, not repeats)

- **Used `INNER JOIN` where `LEFT JOIN` was required** — the core new lesson of this entry; not previously encountered since every earlier `JOIN` question only needed matched rows.
- **Typo'd the table name** (`PAGE_LIKE` vs. `PAGE_LIKES`) between the `JOIN` line and the `ON` line.
- **Placed `WHERE` after `GROUP BY`** — invalid clause order, caught by recalling the established `WHERE`-before-grouping rule from Entry #12.
- **Re-added an unnecessary `GROUP BY`** on a later draft after already having correctly reasoned it wasn't needed — a "knowing vs. doing" lapse, not a comprehension gap.

---

## 18. `WHERE` vs `GROUP BY` vs `CASE WHEN`, Clause Order, and `ISNULL` — Unfinished Parts

### The question
Given `parts_assembly(part, finish_date, assembly_step)`, where a part can appear across multiple rows (one per assembly step it's been through), find every row for a part that's still unfinished — defined as **lacking a `finish_date`**. Return just `part` and `assembly_step`, one row per unfinished step (a part can legitimately appear more than once in the output).

### Why this needs the technique it needs
The instinct on seeing "find parts matching a condition" is often to reach for `GROUP BY` (because the table has repeated `part` values) or `CASE WHEN` (because there's a condition to check). Neither is right here. The expected output keeps **multiple rows per part** (`bumper` appears twice — once for step 3, once for step 4) — `GROUP BY part` would collapse those into a single row per part and destroy exactly the information the question wants. And `CASE WHEN` produces a *value* per row (used inside `SELECT`, or inside an aggregate like `COUNT`) — it isn't a row-filtering clause on its own; used bare after `GROUP BY` the way it first was, it's not even syntactically legal.

### Real-world version of this same problem
A shared laundry basket where each garment gets a sticky note logged every time it goes through a stage — wash, dry, fold. Some garments have a note for every stage; others are missing the "folded" note because they're still mid-process. To find every garment still not fully done, you don't merge all its notes into one summary card (that's what `GROUP BY` would do) — you walk the pile of individual notes and pull out just the ones missing the "folded" stamp, keeping each note as its own separate slip, since a garment might have several unfinished notes at once.

### The concept, explained from zero

**`WHERE` filters individual rows, one at a time, before anything else happens to them.** It doesn't summarize, doesn't merge, doesn't reduce row count except by dropping rows that fail the condition. Exactly one output row per input row that passes.

**`GROUP BY` is a *reduction* tool — it deliberately merges multiple rows into one per group.** It exists for when you want fewer rows out than you had in (one row per distinct group value), almost always paired with an aggregate (`COUNT`, `SUM`, `AVG`...). If the question's expected output has *more* rows for a given key than one, `GROUP BY` on that key is the wrong tool — grouping is happening where none was asked for.

**`CASE WHEN` is an expression, not a clause.** It always sits somewhere a *value* is expected — inside `SELECT` (to label or transform a column), inside an aggregate like `COUNT(CASE WHEN ... THEN 1 END)` (Entry #16), or as part of a larger boolean expression. It is never a standalone thing you put after `GROUP BY` on its own line expecting it to filter rows — there's no clause called `CASE WHEN` in SQL's grammar; only `WHERE` and `HAVING` filter rows.

**SQL clause order is fixed:** `SELECT ... FROM ... WHERE ... GROUP BY ... HAVING ... ORDER BY`. This isn't stylistic — the database evaluates roughly in this order too (find the rows, filter them, optionally group what's left, optionally filter groups, then sort), so writing `GROUP BY` before `WHERE` is both a syntax error and backwards from how the logic actually needs to happen.

**`IS NULL` tests whether a value is missing** — "lacks a `finish_date`" translates directly to `finish_date IS NULL`.

**`SELECT *` returns every column in the table, whether or not the question asked for it.** The expected output here only shows `part` and `assembly_step` — `finish_date` isn't wanted in the result even though it's the column being filtered on. Filtering *on* a column and *displaying* that column are separate decisions.

### The logic used to solve it (the actual reasoning trace)

1. **First attempt:** `SELECT * FROM parts_assembly GROUP BY part CASE WHEN finish_date is null;` — `GROUP BY` reached for out of habit (the table has repeated `part` values), and `CASE WHEN` used as if it were a filter clause, with no `WHERE` anywhere.
2. **Second attempt:** moved to `WHERE`, but kept `GROUP BY part` positioned *before* `WHERE` — wrong clause order — and hadn't yet reconsidered whether `GROUP BY` belonged in the query at all.
3. **Recognized, by comparing against the expected output's two `bumper` rows, that grouping by `part` would collapse exactly the rows needed** — dropped `GROUP BY` entirely, fixed the clause order.
4. **Ran with `SELECT *`,** got the right *rows* but too many *columns* (`finish_date` showing up alongside `part`/`assembly_step`).
5. **Narrowed `SELECT *` down to `SELECT part, assembly_step`,** matching the expected output exactly.
6. **Final submitted form used `ISNULL` (one word, no space) instead of `IS NULL`** — confirmed correct on DataLemur.

### A hand-trace through the sample data
Sample rows: `bumper` has step 1 (finished), step 2 (finished), step 3 (no `finish_date`), step 4 (no `finish_date`). `battery` has steps 1–3, all finished.

- `WHERE finish_date IS NULL` (or `ISNULL`) checks each row **individually**: `bumper`/step 3 → `finish_date` missing → keep. `bumper`/step 4 → missing → keep. `bumper`/step 1 and 2 → present → discard. `battery`'s three rows → all present → discard.
- Result: two surviving rows, `bumper`/3 and `bumper`/4 — exactly the expected output, because nothing ever merged them into one.

### Full solution

```sql
SELECT part, assembly_step
FROM parts_assembly
WHERE finish_date ISNULL
```

### The pattern to remember

**"Find rows matching a per-row condition, keeping the same row shape" is a `WHERE` job — not `GROUP BY` (which merges rows) and not a bare `CASE WHEN` (which produces a value, not a filter).** Before reaching for `GROUP BY`, check whether the expected output actually has *fewer* rows per key than the input — if it has the *same or more*, grouping is the wrong move. Clause order is always `SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY`, matching the order operations logically have to happen in.

### Best practices / general approach — if you see this kind of question again

- **Compare row *counts* in the expected output against the input before choosing `GROUP BY`** — repeated key values in the source table don't automatically mean the answer wants them merged.
- **`CASE WHEN` always needs a home** — inside `SELECT`, inside an aggregate, or inside a larger expression. It's never a clause by itself.
- **Match `SELECT`'s column list to what the expected output actually shows**, not to every column touched by `WHERE` — filtering on a column doesn't obligate displaying it (echoes Entry #8).
- **`finish_date ISNULL` (one word) is valid Postgres — a historical alias for `IS NULL`** (same for `NOTNULL` / `IS NOT NULL`) — but it's non-standard SQL, specific to Postgres, and **dangerously similarly-named to a totally different function in other engines**: MySQL and SQL Server both have an `ISNULL(expr, replacement)` *function* that behaves like `COALESCE`, not a null test. Prefer writing `IS NULL` (two words) for anything meant to be portable or read unambiguously by someone coming from another engine.

### Mistakes made this time (new ones, not repeats)

- **Used `GROUP BY` where no grouping was wanted** — reached for out of habit because the table had repeated `part` values, not because the question asked for a merged summary.
- **Used bare `CASE WHEN` as if it were a row-filter clause** — it's an expression, not a clause; there's no such thing as a standalone `CASE WHEN` filter in SQL's grammar.
- **Placed `GROUP BY` before `WHERE`** — invalid clause order (same category of mistake as Entry #17's `WHERE`-after-`GROUP BY`, opposite direction).
- **Left `SELECT *` in place after fixing the row-filtering logic** — got the right rows before getting the right columns; two separate fixes, not one.

## 19. `MIN`/`MAX` Per Group, `AGE` vs. `date - date`, and Why `CASE WHEN` Can't Substitute — Facebook Posts Days Between First and Last

### The question
Given `posts(user_id, post_id, post_content, post_date)`, for every user who posted **at least twice in 2021**, find the number of days between that user's **first** and **last** post of 2021. Output `user_id` and `days_between`.

### Why this needs the technique it needs
This looks like it might reuse `CASE WHEN` (Entry #16 muscle memory — "there's a condition, so use `CASE WHEN`"), but there's no per-row condition to branch on here. The question needs two things `CASE WHEN` structurally cannot do: (1) compare *every* post a user made against every other one to find the earliest and latest — a cross-row comparison, not a single-row decision — and (2) reduce a calendar-style "X months Y days" span down to one flat number. Both are jobs for aggregate functions (`MIN`/`MAX`) and a plain arithmetic subtraction, not for an expression that only ever looks at one row at a time.

### Real-world version of this same problem
A fitness app logs a timestamp every time you check in at the gym, all year. At the end of the year it wants to tell you "you were active for a 47-day stretch, from your first visit to your last." It doesn't ask, row by row, "is this visit the first one? is this one the last one?" — it lays every visit date out, picks the earliest and the latest from the whole pile, and does one subtraction. If you'd only visited once, "days between first and last" wouldn't even mean anything — hence the "at least twice" requirement gating who shows up in the result at all.

### The concept, explained from zero

**`MIN(column)` / `MAX(column)` scan an entire group and return one extreme value** — the smallest or largest — collapsing many rows down to one. Like `COUNT`/`SUM`/`AVG`, they only make sense per group (`GROUP BY user_id` here): each user's pile of `post_date` values gets reduced to that one user's earliest and latest date.

**`CASE WHEN` cannot do this.** It evaluates one row at a time and returns a value based on that row's own columns — it has no way to "see" any other row to compare against. "Which of this user's posts is earliest" isn't answerable by inspecting a single post in isolation; it requires comparing across the whole group, which is exactly what aggregates like `MIN`/`MAX` exist for and `CASE WHEN` cannot do.

**`EXTRACT(YEAR FROM column) = 2021` in `WHERE`** filters individual rows down to just 2021 posts, before any grouping happens — the same `EXTRACT` function from Entry #12/§9, applied as a row-level equality test instead of feeding a `GROUP BY`.

**`HAVING COUNT(*) >= 2`** filters *groups* after they've formed — "at least twice" is a fact about the group (how many rows survived into it), not about any individual row, so it has to be a `HAVING` condition, not a `WHERE` one.

**`AGE(date1, date2)` (§13) returns a calendar-broken-down `interval`** — "7 mons 17 days" for a 7-month gap. That's structurally different from a plain integer day count, even though for a short, same-month gap it can *look* like one (a 2-day gap prints as "2 days," which is misleadingly close to the number `2`).

**`value::date` (§18) casts a `timestamp` down to a `date`, dropping the time-of-day.** Once both sides of a subtraction are `date` type, `date2 - date1` returns a **plain integer** — the flat number of days between them, with no calendar-unit breakdown and no interval type to unpack. This, not `AGE()`, is the right tool whenever the expected output is a single number.

**`WHERE` still can't see a `SELECT`-list alias** (same rule as Entry #13's `AGE`/`date_days` trap) — a year-alias defined in `SELECT` isn't available yet when `WHERE` runs, so the full `EXTRACT(...)` expression has to be repeated rather than referenced by name.

### The logic used to solve it (the actual reasoning trace)

1. **First attempt:** `SELECT user_id, age(post_date) FROM posts GROUP BY user_id;` — one-argument `AGE()` (compares to *right now*, not to another post) sitting on a bare, ungrouped `post_date` column next to `GROUP BY user_id` — the same "raw column beside a `GROUP BY`" problem from Entry #4.
2. **Learned `AGE` takes a two-argument form** for an explicit span between two dates, and reached for `MIN`/`MAX` to supply those two dates — but wrote `age(MIN(post_date), MAX(post_date))`, earliest minus latest, which subtracts backwards.
3. **Swapped the order** to `age(MAX(post_date), MIN(post_date))` — later minus earlier, correct direction.
4. **Tried to add the 2021 filter and the "2+ posts" condition**, but placed `HAVING post_date == 2021` *before* `FROM` (invalid clause order), used `==` (not valid SQL), used `HAVING` for what's actually a per-row condition, and dropped the "2+ posts" `HAVING` requirement entirely in the process.
5. **Moved the condition into `WHERE`** (correct clause) but kept `post_date == 2021` — still the wrong operator, and still comparing a full timestamp directly to a bare year number, which doesn't test the year at all.
6. **Attempted to wrap the year-check in `EXTRACT` while also nesting `AGE`/`MIN`/`MAX` in the same expression** — mismatched parentheses, functions nested inside each other without a clear purpose for each layer.
7. **Isolated just the `WHERE` line** and rebuilt it cleanly: `EXTRACT(YEAR FROM posts.post_date) = 2021` — but then referenced the `SELECT`-list alias `post_year` inside `WHERE` (`where post_year is 2021`), using `is` instead of `=`, and dropped the `MIN`/`MAX`/`AGE` piece from `SELECT` entirely while focused on this one line.
8. **Fixed both**: replaced `is` with `=`, and replaced the alias reference with the full `EXTRACT(...)` expression written out again — `WHERE` line now correct and self-contained.
9. **Rebuilt `SELECT`** as `AGE(MAX(post_date), MIN(post_date))`, added `HAVING COUNT(*) >= 2` in the correct position, and added the `AS days_between` alias — query now ran and returned syntactically valid results.
10. **Checked whether `CASE WHEN` could replace any of this** — correctly reasoned out, unprompted, that it couldn't: `MIN`/`MAX` need to compare across rows, and `CASE WHEN` only ever evaluates one row at a time.
11. **Noticed the output was shaped wrong**: `AGE()` returned `"months":X,"days":Y`, not a plain integer, even after adding `::date` casts *inside* the still-present `AGE()` call — the cast alone didn't fix it, because the problem was `AGE()` itself, not the operand types.
12. **Dropped `AGE()` entirely**, replacing it with `MAX(post_date::date) - MIN(post_date::date) AS days_between` — plain integer output (`206`, `307`), submitted and accepted.

### A hand-trace through the sample data
Sample rows: `151652` posted 07/10 and 07/12; `661093` posted 07/08 and 07/29; `004239` posted once (07/04) — only one post, doesn't qualify.

- `WHERE EXTRACT(YEAR FROM post_date) = 2021` keeps every row (all sample rows are already 2021) — this filter matters more once other years exist in the full dataset.
- `GROUP BY user_id` collects each user's posts into their own group: `151652` → {07/10, 07/12}, `661093` → {07/08, 07/29}, `004239` → {07/04}.
- `HAVING COUNT(*) >= 2` drops `004239` (only 1 row) — never reaches the `SELECT` output.
- For `151652`: `MAX(post_date::date)` = 07/12, `MIN(post_date::date)` = 07/10 → `07/12 - 07/10 = 2`.
- For `661093`: `MAX` = 07/29, `MIN` = 07/08 → `07/29 - 07/08 = 21`.
- Matches the example output exactly: `151652 → 2`, `661093 → 21`.

### Full solution

```sql
SELECT user_id, MAX(post_date::date) - MIN(post_date::date) AS days_between
FROM posts
WHERE EXTRACT(YEAR FROM post_date) = 2021
GROUP BY user_id
HAVING COUNT(*) >= 2;
```

### The pattern to remember

**"Find the earliest/latest value in a group" is a `MIN`/`MAX` job, not a `CASE WHEN` job** — `CASE WHEN` only ever sees one row at a time and has no mechanism to compare across rows. And **"give me a flat number of days" means `date - date` (cast with `::date` first), not `AGE()`** — `AGE()` answers a different question (a calendar-style span), and its output only coincidentally resembles a plain day count for gaps that stay inside one month.

### Best practices / general approach — if you see this kind of question again

- **Before reaching for `CASE WHEN`, ask whether the decision needs to compare a row against other rows, or just needs to look at that row alone.** Cross-row comparisons are `MIN`/`MAX`/`SUM`/other aggregates' job.
- **"Number of days" in the expected output is a strong signal to use `date - date`, not `AGE()`.** Reserve `AGE()` for when the expected output actually looks like a calendar span ("X years Y months").
- **Test a fix's *output shape*, not just whether the query runs.** Adding `::date` casts inside a still-present `AGE()` call ran fine and returned no error — but it didn't fix the actual problem, because the wrong function was still in use. A syntactically valid query can still return the wrong *kind* of value.
- **Build and verify one clause in isolation when a multi-clause query gets tangled** (as with isolating just the `WHERE` line here) rather than editing `SELECT`, `WHERE`, and `HAVING` all at once — easier to spot which piece is actually broken.
- **Re-confirm the `WHERE`-can't-see-`SELECT`-alias rule stays enforced** even under pressure to move fast — this is the second time (Entry #13, now #19) an alias got referenced too early.

### Mistakes made this time (new ones, not repeats)

- **Used `HAVING` for a per-row condition** (`post_date == 2021`) — that belongs in `WHERE`; `HAVING` is only for conditions on the *aggregated* result.
- **Used `==` instead of `=`** — not valid SQL, carried over from a different language's equality syntax.
- **Compared a raw timestamp directly to a bare year number** (`post_date = 2021`) without `EXTRACT` — type mismatch that doesn't test the year at all, not just a syntax slip.
- **Referenced a `SELECT`-list alias inside `WHERE`** (`where post_year is 2021`) — repeat of the Entry #13 `AGE`/`date_days` alias-timing trap, this time with a different function.
- **Dropped the "2+ posts" `HAVING` condition partway through**, twice, while focused on fixing something else in the query — lost track of a previously-added requirement mid-edit.
- **Assumed adding `::date` casts fixed the output shape without checking what `AGE()` still printed** — the casts were necessary but not sufficient; `AGE()` itself needed to be removed, not just fed differently-typed inputs.

## 20. `ORDER BY` + `LIMIT` for "Top N," Compound `EXTRACT` Filters with `AND` — Microsoft Teams Power Users

### The question
Given `messages(message_id, sender_id, receiver_id, content, sent_date)`, find the **top 2** users who sent the most messages in **August 2022**. Output `sender_id` and `message_count`, ordered by count descending.

### Why this needs the technique it needs
"Top 2" isn't a condition any single row or group can pass or fail on its own — it's a statement about *rank after sorting the whole result set*. There's no column to test with `WHERE` or `HAVING` that means "is this in the top 2" without first knowing everyone else's count too. That's what `ORDER BY` + `LIMIT` are for: sort by the value that defines "top," then cut the list off at the count wanted. Separately, "August 2022" is two calendar facts at once (the right year, *and* the right month) — `EXTRACT` only ever answers one such fact per call, so nailing down both requires two conditions joined with `AND`, not one call asking for both at once.

### Real-world version of this same problem
A sales-leaderboard app that has to announce "this month's top 2 reps." Nobody sets a sales-dollar cutoff and hopes exactly two people clear it — that would either crown zero people (bar set too high) or five (set too low). The only reliable way is to rank everyone by their total first, then read off the first two names from that ranked list. Same logic for "this specific month" — checking only the month number would also match every other year's August; checking only the year would match all twelve months of 2022. Both facts have to hold together.

### The concept, explained from zero

**`ORDER BY` defines what "top" or "bottom" even means** — without it, a result set has no inherent rank; rows just come back in whatever order the database happens to produce them.

**`LIMIT n` caps the row count to `n`, applied to whatever order already exists.** It doesn't inspect any column's value and can't express a condition like "count > 5" — it only answers "how many rows," never "which ones qualify." Used *after* `ORDER BY` has already put the highest counts first, `LIMIT 2` becomes "give me the top 2." Used without an `ORDER BY` in front of it, `LIMIT` returns some arbitrary 2 rows — not necessarily the highest anything.

**`EXTRACT(part FROM column)` takes exactly one part name per call** — never a comma-separated list like `EXTRACT(year, month FROM column)`. To test two calendar facts about the same column, write two separate `EXTRACT(...) = value` conditions and combine them with `AND` — both must hold simultaneously, the same combinator logic as Entry #11's `OR`/`AND` lesson, just aimed at two sub-parts of one column instead of two different columns.

**Clause order, once more:** `WHERE` still has to sit before `GROUP BY` — third time this exact ordering has come up (Entries #17, #18), worth treating as a known trouble spot to double-check deliberately rather than trusting habit.

### The logic used to solve it (the actual reasoning trace)

1. **First draft:** `SELECT sender_id, COUNT(message_id) AS message_count FROM messages GROUP BY sender_id ORDER BY message_count DESC;` — solid grouped-count-and-sort skeleton, but no August 2022 filter at all and no `LIMIT`, so it returned every sender ever, unfiltered by date.
2. **Added `LIMIT 2`** correctly on the first try, no trouble — clean use of the "sort then cut" idea once prompted to think about what caps the row count.
3. **Added a date filter, but three things wrong at once:** placed `WHERE` *after* `GROUP BY` (repeat of the Entries #17/#18 clause-order mistake), wrote `EXTRACT(year, month FROM sent_date)` as a single call with two comma-separated parts (not valid — `EXTRACT` only takes one), and compared the result to `08/2022` as a bare literal (evaluates as division — `08 / 2022` — not a date test at all).
4. **Self-diagnosed the clause-order slip out loud** ("I keep forgetting the order for the queries") before being told, and self-corrected all three problems in one pass: moved `WHERE` before `GROUP BY`, split the single `EXTRACT` call into two separate `EXTRACT(year ...) = 2022` and `EXTRACT(month ...) = 8` conditions, and joined them with `AND`. Query ran clean and matched the expected output shape.

### A hand-trace through the sample data
Sample rows: sender `3601` → 08/03 (to 4500), 06/14 (to 8752), 08/10 (to 4500); sender `4500` → 08/03 (to 3601).

- `WHERE EXTRACT(year FROM sent_date) = 2022 AND EXTRACT(month FROM sent_date) = 8` keeps the two 08/03 rows and the 08/10 row, drops the 06/14 row (year matches, month doesn't) before any grouping happens.
- `GROUP BY sender_id` buckets what's left: `3601` → 2 surviving rows, `4500` → 1 surviving row.
- `ORDER BY message_count DESC` puts `3601` first (2), `4500` second (1).
- `LIMIT 2` keeps both here since the sample only has two senders total — with more senders in the real dataset, anyone past rank 2 would be cut.
- Matches the example output: `3601 → 2`, `4500 → 1`.

### Full solution

```sql
SELECT sender_id, COUNT(message_id) AS message_count
FROM messages
WHERE EXTRACT(year FROM sent_date) = 2022
  AND EXTRACT(month FROM sent_date) = 8
GROUP BY sender_id
ORDER BY message_count DESC
LIMIT 2;
```

### The pattern to remember

**"Top N" = `ORDER BY` (defines what "top" means) + `LIMIT N` (cuts the list there) — never a `WHERE`/`HAVING` threshold guess.** A compound date condition ("this specific month of this specific year") = one `EXTRACT` call per calendar unit, `AND`ed together, since `EXTRACT` only ever returns one part per call.

### Best practices / general approach — if you see this kind of question again

- **Whenever a question says "top N" (or "bottom N," "the N highest/lowest"), reach for `ORDER BY` + `LIMIT` immediately** — don't try to guess a numeric threshold that happens to produce exactly N rows.
- **Any date filter needing more than one calendar unit pinned down at once (month + year, day + month, etc.) needs one `EXTRACT` per unit, `AND`ed together** — never a single `EXTRACT` call with multiple parts.
- **Clause order checklist, now including `LIMIT`:** `SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT`. `WHERE`-before-`GROUP BY` specifically has now slipped three times (Entries #17, #18, #20) — worth a deliberate pause to check this specific ordering every time a query has both clauses, rather than trusting habit.

### Mistakes made this time (new ones, not repeats)

- **Omitted the August 2022 filter entirely on the first draft** — the grouped-count-and-sort logic was right, but nothing yet restricted which rows counted.
- **Repeated the `WHERE`-after-`GROUP BY` clause-order mistake for the third time** (Entries #17, #18, now this one) — self-caught this time, unprompted, mid-fix, rather than needing it pointed out.
- **Combined two `EXTRACT` parts into one call** (`EXTRACT(year, month FROM sent_date)`) — not valid syntax; `EXTRACT` only ever takes one named part.
- **Wrote `08/2022` as a bare literal** — evaluates as division (`08 / 2022`), not a date comparison of any kind.

---

## 21. First Real CTE Since Entry #1, and Which Column `COUNT(DISTINCT ...)` Must Wrap — LinkedIn Duplicate Job Listings

### The question
Given `job_listings(job_id, company_id, title, description)`, find the count of companies that have posted duplicate job listings. A duplicate is defined as **two listings within the same company** that share an identical `title` and `description`. Output one number, `duplicate_companies`.

### Why this needs the technique it needs
This is Entry #1's exact two-level shape wearing a new costume: **Level 1** is "which specific postings got repeated, and by whom" — a `GROUP BY` on `company_id, title, description` with `COUNT(*)` and a `HAVING COUNT(*) > 1` filter, all computed from the raw `job_listings` rows. **Level 2** is "how many distinct companies show up among those repeats" — a second aggregate that can only run *after* Level 1 has already finished and produced its own finished result to count over. A single flat `GROUP BY`/`HAVING` can't do both at once, for the same reason as Entry #1: the thing Level 2 needs to count (rows of Level 1's output) doesn't exist yet while Level 1 is still being computed. That's what a CTE is for — finish Level 1, name its result, then run Level 2 on top of it as if it were a real table.

The second, subtler thing this question needs: once Level 1's result exists, which of its columns should `COUNT(DISTINCT ...)` wrap? The question asks for a count of **companies**, and `company_id`, `title`, and `description` all happen to look "unique enough" in the small sample data given — but only one of those three columns is actually guaranteed, by definition, to identify one specific company and no other, regardless of what any particular dataset happens to contain.

### Real-world version of this same problem
A landlord manages several rental listings across different property-management companies advertising on the same listings site. Two different, unrelated companies each independently list a "2-bedroom apartment, downtown" with the exact same boilerplate description — pure coincidence, they just wrote similar ads. Meanwhile, one single company accidentally posts the *same* "Studio apartment, riverside" listing twice by mistake.

If you tried to answer "how many companies have posted a duplicate listing" by counting **distinct listing descriptions** that appear more than once, you'd wrongly catch the two unrelated companies' coincidentally-similar "2-bedroom downtown" ads as if one company had duplicated itself — when really it's two different companies who just happen to describe a common apartment type similarly. The only column that correctly answers "how many *companies*" is the company's own ID — an attribute like the ad's wording can coincidentally repeat across totally unrelated companies, but a company's ID, by definition, never means two different companies.

### The concept, explained from zero

**CTE mechanics — recap from Entry #1, not new:** `WITH name AS (query)` runs `query` first, names its result `name`, and lets the rest of the statement treat `name` as a real table. See Entry #1 for the full from-zero breakdown if this part is rusty.

**What's genuinely new here: `GROUP BY` on *three* columns at once, with `COUNT(*)` alongside them in `SELECT`.** `GROUP BY company_id, title, description` collapses the raw table down to one row *per distinct combination* of those three values — not one row per company, not one row per title. `COUNT(*)` in that same `SELECT` then reports, for each surviving combination, how many raw rows in `job_listings` shared that exact combination. A combination that appears once is not a duplicate; `HAVING COUNT(*) > 1` throws those away, keeping only combinations that genuinely repeated.

**The part that actually caused the trouble: a column carried through a `GROUP BY` is not guaranteed unique per row in the result, even a column like `company_id` that identifies something real.** If one company duplicates *two different* listings (say, both a "Business Analyst" posting and, separately, an unrelated "Officer Security" posting), that one company produces **two separate rows** in the CTE's output — one row per distinct `(company_id, title, description)` group, not one row per company. So `company_id` repeats across rows of the CTE for a completely legitimate reason that has nothing to do with "this company is extra duplicate."

**Why `COUNT(DISTINCT company_id)`, specifically, and not `COUNT(DISTINCT title)` or plain `COUNT(company_id)`:**
- Plain `COUNT(company_id)` would count *rows*, not companies — the two-duplicate-groups company from above would get counted twice, inflating the answer for one company that only deserves to count once.
- `COUNT(DISTINCT title)` (or `description`) is wrong for a different reason: those are attributes, not identifiers. Two completely unrelated companies can coincidentally post a listing with the identical title text (this actually happens in this exact question's own sample data — see the hand-trace below), which would silently *undercount* by collapsing two real companies into what looks like one distinct title.
- `COUNT(DISTINCT company_id)` is correct because `company_id`'s entire purpose is to identify one specific company and no other — genuinely unique to that entity by definition, not just by coincidence of a small sample — while still correctly collapsing that one company down to a count of 1 even if it shows up on multiple CTE rows.

Worth being precise about one more thing: `company_id` is **not** the primary key of `job_listings` — a company can post many listings, so the same `company_id` legitimately repeats across many raw rows of that table (it's a foreign key here, same PK vs. FK distinction as Entry #4). The rule isn't "`DISTINCT` whatever column is a primary key of the table you're querying" — it's "`DISTINCT` whatever column is the ID of the entity the question is actually asking you to count," even when that column shows up as a foreign key, with repeats, in the table sitting in front of you.

### The logic used to solve it (the actual reasoning trace)
1. **Correctly guessed the outer aggregate early** — `count(distinct(company_id)) as duplicate_companies` — before the surrounding two-level structure was assembled. Right ending, no scaffolding around it yet.
2. **Needed a refresher on CTE syntax itself** ("what do you mean?") — Entry #1 was old enough to need re-explaining from the `WITH name AS (...)` shape up.
3. **First full attempt had two bugs at once:**
   ```sql
   WITH companies_dup AS
   (SELECT company_id, title, description, COUNT(*) AS duplicate_companies
   FROM job_listings
   GROUP BY company_id, title, description
   HAVING COUNT(*) > 1;)
   select c
   ```
   (a) the `;` sat *inside* the CTE's closing parenthesis, ending the entire statement before an outer `SELECT` could ever attach to it; (b) the CTE's own `COUNT(*)` was aliased `duplicate_companies` — the wrong semantic name at that level, since at that point the value means "how many times this one posting repeated," not "how many companies."
4. **Fixed both:** moved the `;` outside the CTE's parentheses (to the very end of the whole statement), renamed the inner alias to `posting_count`.
5. **Finished the outer query:** `count(distinct(company_id)) as duplicate_companies from companies_dup;` — correct (the extra parentheses around `company_id` are harmless, just non-standard style; see SQL-REFERENCE §10).
6. **Ran it, submitted, confirmed correct on DataLemur.**
7. **Post-submission misconception surfaced:** believed `COUNT(DISTINCT ...)` would give the same answer no matter which column of the CTE it wrapped — "if we point it to any row in the table on the CTE our answer is the same." Tested against a counterexample (two different companies each duplicating their own "Business Analyst" listing): `COUNT(DISTINCT company_id)` correctly gives 2, `COUNT(DISTINCT title)` wrongly collapses to 1.
8. **First attempt to explain *why* landed on "primary key"** — corrected, since `company_id` is actually a foreign key inside `job_listings`, not that table's primary key; the real rule is about identifying the *entity being counted*, not about which column happens to be a PK of the table in front of you.
9. **Stress-tested the fully-corrected understanding unprompted**, with a scenario of one company producing two different duplicate groups (BA duplicated 3×, Officer Security duplicated 4×) alongside a second company with one duplicate group — correctly predicted `COUNT(DISTINCT company_id)` would count the first company once and the second once (2 total), regardless of how many separate duplicate-groups a single company has. Landed on the closing insight unprompted: the question only cares *whether* a company duplicated something, not *how many* distinct things it duplicated or *how many times*.

### A hand-trace through the actual sample data
Given rows:

| job_id | company_id | title | description |
|---|---|---|---|
| 248 | 827 | Business Analyst | "Business analyst evaluates..." |
| 149 | 845 | Business Analyst | "Business analyst evaluates..." (same wording) |
| 945 | 345 | Data Analyst | "Data analyst reviews..." |
| 164 | 345 | Data Analyst | "Data analyst reviews..." (same wording) |
| 172 | 244 | Data Engineer | "Data engineer works..." |

**`GROUP BY company_id, title, description`:** job `248` (company `827`) and job `149` (company `845`) share identical `title`/`description` text — but different `company_id`, so they form **two separate groups**, each with `COUNT(*) = 1`. This is the exact real-data proof of the "coincidentally identical title across unrelated companies" trap from above — if `company_id` weren't part of the grouping, these two would wrongly merge into one fake "duplicate." Job `945` and job `164` (both company `345`) match on all three columns — **one group**, `COUNT(*) = 2`. Job `172` is alone — its own group, `COUNT(*) = 1`.

**`HAVING COUNT(*) > 1`:** drops both `COUNT(*) = 1` groups (the mismatched-company "Business Analyst" pair, and the lone "Data Engineer"). Only the company-`345` "Data Analyst" group survives, with `posting_count = 2`.

**Outer `COUNT(DISTINCT company_id) FROM companies_dup`:** exactly one row survived, `company_id = 345` → `duplicate_companies = 1`. Matches the question's stated expected output.

### Full solution
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

### The pattern to remember
**Two-level aggregation = a CTE that fully finishes Level 1, then a second, separate aggregate on top of it treating the CTE's output as a plain table (Entry #1's pattern, reused).** Layered on top: **whenever `COUNT(DISTINCT ...)` is meant to count a real-world entity ("how many companies," "how many users," "how many customers"), the column inside `DISTINCT` must be that entity's own ID column — never an attribute column that merely happens to look unique in the sample data in front of you.** And separately: a value repeating across multiple rows of a `GROUP BY` result isn't automatically meaningful — it can just mean "this same entity satisfied the condition more than once," which is exactly what `DISTINCT` exists to collapse back down to one.

### Best practices / general approach — if you see this kind of question again
- **"Count of [entity]" in the question wording is the signal to ask: which column *is* that entity's ID?** Don't default to whichever column looks unique in the sample rows given — a small example can make an attribute column look unique by coincidence.
- **`GROUP BY` on multiple columns together is still just "one row per distinct combination" — no different in kind from grouping on one column,** just a wider combination key. `COUNT(*)` still means the same thing: how many raw rows shared that exact combination.
- **A `;` always closes the entire statement, never just a `(...)` block it happens to sit inside.** In a CTE, that means the `;` belongs at the very end, after the outer query — never before the outer `SELECT` has been written.
- **Name a CTE's internal aliases for what they mean *inside* the CTE, not for what the outer query will eventually do with them** — a count of postings-per-group is not yet a count of companies, even though a count of companies is the ultimate goal of the whole query.
- **Primary key vs. foreign key (Entry #4) still matters here:** the correct entity-ID column to `DISTINCT` on can be a foreign key in the table you're actually querying — "is this column a PK in this table" and "is this column the right thing to count distinct values of" are two separate questions.

### Mistakes made this time (new ones, not repeats)
- **Needed a refresher on CTE syntax itself** before writing anything — the concept from Entry #1 hadn't stuck cold.
- **Placed the closing `;` inside the CTE's own parentheses**, ending the whole statement before the outer `SELECT` could attach — new mistake, not a repeat of any prior clause-order slip.
- **Aliased the CTE's internal `COUNT(*)` as `duplicate_companies`** — named it for what the outer query would eventually produce, not for what that value actually meant at that point in the query.
- **Believed, after a correct and confirmed-correct submission, that `COUNT(DISTINCT ...)` would give the same result regardless of which CTE column it wrapped** — a genuine conceptual gap that survived a passing submission, since this dataset's numbers happened to work out the same either way.
- **First attempt to name the correct reasoning called `company_id` "the primary key"** — imprecise; it's a foreign key in this table, and the real rule is about entity identity, not PK-ness of the current table.

---

## 22. The `GROUP BY` Granularity Rule, Stated Explicitly — Ace the Interview: Top 3 Cities by Completed Trade Orders

### The question
Given `trades(order_id, user_id, quantity, status, date, price)` and `users(user_id, city, email, signup_date)`, find the city and count of completed trade orders for that city, restricted to the **top 3 cities** by that count, descending.

### Why this needs the technique it needs
The output has to be **one row per city** — not one row per user, not one row per order. `trades` and `users` have to be joined first (the city lives on `users`, the order/status lives on `trades`), then every row belonging to the same city has to collapse into a single group before `COUNT` can tally it. That collapsing step is `GROUP BY`'s entire job — but `GROUP BY` doesn't automatically know "collapse down to one row per city." It collapses down to one row per *distinct combination of whatever columns you list*. List one column too many, and the grouping keeps that column intact as a separate axis, which quietly reopens exactly the split you were trying to close.

### Real-world version of this same problem
A delivery company wants to know which 3 warehouses shipped the most completed orders. If the report groups by warehouse *and* by driver, San Francisco's warehouse — which uses 12 different drivers — doesn't show up as "412 completed orders," it shows up as 12 separate tiny rows, one per driver, each reporting maybe 20-40 orders. San Francisco never gets the chance to compete for a top-3 spot as a warehouse, because the report never actually computed "San Francisco" as a single number — it computed "San Francisco-via-driver-A," "San Francisco-via-driver-B," and so on, each too small to rank highly on its own.

### The concept, explained from zero

**What `GROUP BY col1, col2, ...` actually collapses rows into:** one output row *per distinct combination* of every column named in the `GROUP BY` list — not one row per "the thing you're conceptually trying to count." If two rows share `city` but differ on any other column also named in `GROUP BY`, they land in different groups, even though they'd both intuitively belong under the same city.

**The rule this session crystallized:** `GROUP BY` should contain **exactly** the non-aggregated columns that appear in `SELECT` — nothing more, nothing that isn't also in `SELECT`. If `SELECT` only asks for `city` and `COUNT(status)`, then `GROUP BY` should only name `city`. Any additional column in `GROUP BY` — even one that seems harmless, even one that isn't in `SELECT` at all — re-introduces a split that the question never asked for, because `GROUP BY` doesn't distinguish "a column I need for grouping" from "a column I was just curious about."

**Why this one rule catches both of this session's `GROUP BY` mistakes at once:** Attempt 1 grouped by `users.city, trades.user_id, trades.status` — three columns — while `SELECT` only ultimately needed `city` and a count. `user_id` alone guarantees a new group per person (nobody shares a `user_id`), so a city with 3 different completed-order customers split into 3 rows of count 1 each, instead of 1 row of count 3. `status` added a second, redundant split on top of that, even though `WHERE status = 'Completed'` had already thrown away every non-`'Completed'` row before grouping ever ran — grouping by a column that's already constant to a single value across every remaining row can't cause visible harm by itself, but it's still an extra axis with no purpose, and it signals the same "throw every column I can see into `GROUP BY`" habit that *did* cause harm via `user_id`.

**The second, unrelated bug — a self-referencing `JOIN` condition:** `join users on trades.user_id = trades.user_id` names `trades` on *both* sides of the `=`. That condition is comparing a column to itself — always true, for every row, regardless of what's actually in `users`. Postgres has no way to know this was a typo instead of an intentional (if useless) condition; it just matches every row of `trades` against every row of `users`, because the stated condition never actually excludes any pairing. That's a **cross join wearing a JOIN's syntax** — the row count silently balloons, and every downstream `GROUP BY`/`COUNT` is now operating over `(user count) × (correct row count)` duplicated rows instead of the real ones. The fix is mechanical once spotted: a JOIN condition must always name a column from each of the *two different* tables being joined, never the same table twice.

### The logic used to solve it (the actual reasoning trace)
1. **First attempt correctly identified the join, the filter, and the aggregate** — `INNER JOIN`, `WHERE status = 'Completed'`, `COUNT`, `ORDER BY ... DESC LIMIT 3` — all the right pieces were present from the start. The bug was purely in *which* columns went into `GROUP BY` and `SELECT`, not in the overall shape of the query.
2. **`GROUP BY users.city, trades.user_id, trades.status`** produced a result where a city with several different completed-order customers came back as several rows of count 1, instead of collapsing to its true total — the tell that something was over-splitting.
3. **Also flagged: `trades.user_id` sitting in `SELECT`** even though the question's expected output was just `city` + a count — an extra column that doesn't belong in the final answer at all, separate from (but caused by) the same over-grouping instinct.
4. **Second attempt fixed the `SELECT`/`GROUP BY` mismatch but introduced the self-join bug** — `join users on trades.user_id = trades.user_id` — while also still carrying `user_id` in `SELECT` without it being present in `GROUP BY` (which strict SQL treats as an error: every non-aggregated `SELECT` column must appear in `GROUP BY`).
5. **Final draft dropped every extra column at once** — `SELECT city, COUNT(status)`, `GROUP BY users.city` only, and the join condition corrected to `users.user_id = trades.user_id` (two different tables, as it should always be). Submitted and confirmed correct.

### A hand-trace (illustrative — not the platform's actual sample data)
Given three completed trades all belonging to San Francisco, from three different users:

| order_id | user_id | status | city (via join) |
|---|---|---|---|
| 101 | 501 | Completed | San Francisco |
| 102 | 502 | Completed | San Francisco |
| 103 | 503 | Completed | San Francisco |

**`GROUP BY city, user_id, status`** (the buggy version): three distinct `(city, user_id, status)` combinations exist here — `(SF, 501, Completed)`, `(SF, 502, Completed)`, `(SF, 503, Completed)` — so this produces **three rows**, each `COUNT = 1`. San Francisco's true total (3) never appears anywhere in the output; it's scattered across three rows that each look unremarkable next to a city with one big legitimate count of 3.

**`GROUP BY city`** (the fix): all three rows share the same `city` value and nothing else is in the grouping list, so they collapse into **one row**: `San Francisco, COUNT = 3`. That's the number that can actually compete for a top-3 spot.

### Full solution
```sql
select city, count(status) as total_orders
from trades
join users on users.user_id = trades.user_id
where status = 'Completed'
group by users.city
order by total_orders desc
limit 3;
```

### The pattern to remember
**`GROUP BY` should contain exactly the non-aggregated columns that appear in `SELECT` — never more.** Before running a grouped query, check every column named in `GROUP BY` against the `SELECT` list: if a `GROUP BY` column isn't something the question actually needs broken out in the final output, it doesn't belong there, because it will silently re-split rows that were supposed to collapse together. Separately: **a `JOIN ... ON` condition must always name one column from each of the two tables being joined** — the same table appearing on both sides of the `=` is a red flag that reads as valid SQL but expresses "always true," not a real relationship.

### Best practices / general approach — if you see this kind of question again
- **Before writing `GROUP BY`, write out the exact `SELECT` list the question asks for first.** Every column in that list that isn't wrapped in an aggregate function is a mandatory `GROUP BY` entry; every column *not* in that list has no business being in `GROUP BY` either, no matter how "related" it feels.
- **If a grouped result has more rows than expected, or a value that should clearly be one number is instead scattered across several small rows, suspect over-grouping first** — check whether an extra column snuck into `GROUP BY`.
- **Read every `JOIN ... ON` condition and confirm it names a column from each side** — a same-table comparison is always syntactically valid, so nothing will error; it will just silently multiply rows.
- **`COUNT(*)` vs. `COUNT(column)`:** functionally identical here since `status` is never `NULL` on a row that survived `WHERE status = 'Completed'` — but `COUNT(*)` states the intent more clearly ("how many rows in this group"), while `COUNT(column)` reads as if it's deliberately checking that column for `NULL`s, which isn't actually the point of this particular count.
- **Ties for the last spot in a "top N" query:** `LIMIT 3` alone picks whichever 3 rows come out on top *after* `ORDER BY`, and if the 3rd and 4th place cities are tied on count, which one gets included is arbitrary — `LIMIT` has no concept of "these two are equally deserving." `RANK()` (a window function, not yet used in a submitted query here — flagged for later practice) numbers rows by value and **repeats a rank number across ties, then skips the number(s) that would have followed** (two rows tied for 3rd both get rank 3, and the next distinct value gets rank 5, not 4) — wrapped in a subquery/CTE and filtered with `WHERE rank <= 3`, it would keep *every* city tied for the cutoff spot instead of arbitrarily keeping just one. Also worth banking now: a window function's result isn't available yet by the time `WHERE` runs, so `RANK() ... WHERE rank <= 3` in the same query block errors — the rank has to be computed first (inside a subquery or CTE), then filtered on in an outer query.

### Mistakes made this time (new ones, not repeats)
- **Grouped by three columns (`city`, `user_id`, `status`) when only `city` belonged in `GROUP BY`** — the first concrete example, this project, of the general over-grouping trap rather than a specific prior repeat.
- **Carried `user_id` into `SELECT`** even though the question's expected output never asked for it — an extra column riding along with the over-grouping instinct.
- **Wrote a self-referencing JOIN condition** (`trades.user_id = trades.user_id`) — a new mistake shape, distinct from the ambiguous-column trap in Entry #4 (that was about *naming*; this is about the condition itself being logically vacuous).

---

## 23. `GROUP BY` vs. an Aggregated Column, and `ROUND`'s Second Argument — Ace the Interview: Average Star Rating by Month and Product

### The question
Given `reviews(review_id, user_id, submit_date, product_id, stars)`, find the average star rating, rounded to 2 decimal places, per product per month — output columns `mth`, `product_id`, `avg_stars`, sorted by month then product.

### Why this needs the technique it needs
Two different "shrink the data down" operations are needed here, and they can't be sloppy about which columns they touch. First, `submit_date` is a full timestamp (e.g. `2023-06-08 14:22:00`), but the question only cares about the **month** — so `EXTRACT(MONTH FROM submit_date)` has to run before grouping, or every review keeps its own distinct minute-level timestamp and nothing ever collapses into a shared month. Second, `stars` is the value being *averaged*, so it must appear only inside `AVG(stars)` — the moment `stars` also appears in `GROUP BY`, the query stops averaging across each month/product group and instead creates one group per distinct star rating too, which defeats the entire point of computing an average (an average of a group that's already been split down to a single star value is just that same value back).

### Real-world version of this same problem
A store manager wants "average rating per product per month" for a dashboard. If the report groups by `product_id`, `stars`, and the raw timestamp of each review, it doesn't produce an average at all — it produces a giant list of every individual 5-star review, every individual 4-star review, etc., each shown as its own row with "average = 5" or "average = 4," because each group only ever contains reviews that already share that exact star value. The manager doesn't get "this product averaged 4.2 stars in June" — they get a spreadsheet exploded back out into something close to the raw review list, with the averaging step having accomplished nothing.

### The concept, explained from zero

**Why a column can't sit inside an aggregate *and* in `GROUP BY` at the same time:** `GROUP BY` decides what counts as "the same group" — rows with identical values across every `GROUP BY` column land together. An aggregate function like `AVG()` then computes one summary value *per group*, by looking across every row in that group. If `stars` is itself one of the columns deciding what counts as "the same group," then by construction every row inside a single group already shares the exact same `stars` value — there's no variation left within a group for `AVG(stars)` to average over. The aggregate still runs and returns a number, so no error occurs — but that number is just the one shared `stars` value, repeated back, which reads as "the average" without doing any actual averaging.

**Why grouping by the raw `submit_date` column doesn't group by month:** A `timestamp` column's value is precise down to the second (or more). Two reviews submitted on `2023-06-08` and `2023-06-18` are both "June," conceptually — but as raw `submit_date` values they're completely different timestamps, so `GROUP BY submit_date` treats them as two separate groups, one per exact date, not one shared "June" group. `EXTRACT(MONTH FROM submit_date)` has to run *before* grouping — either computed once in `SELECT` and grouped by its alias, or repeated inline in `GROUP BY` — so that what actually gets compared for "same group" is the month number, not the full timestamp.

**`ROUND(numeric_expression, n)` — the second argument, now used deliberately:** `ROUND` with a single argument, `ROUND(x)`, rounds to the nearest whole number — `3.5` becomes `4`, decimal information gone entirely. `ROUND(x, n)`'s second argument specifies exactly how many decimal places to keep — `ROUND(x, 2)` keeps two digits after the decimal point (`3.5` stays recognizable as `3.50`, not collapsed to `4`). Leaving the second argument off isn't a smaller version of the same rounding — it's a different operation that throws away information the question explicitly asked to keep (2 decimal places).

**Why `AVG(stars)` needs `::numeric` before `ROUND(..., 2)` can take two arguments:** Postgres's `AVG()` over an integer column returns a `numeric` type already in most cases, but the two-argument form of `ROUND` — `ROUND(numeric, integer)` — specifically requires its first argument to be `numeric`; the single-argument `ROUND(double precision)` form exists separately and doesn't accept a second argument at all. The `::numeric` cast (§18) makes the type explicit and guarantees the two-argument form is the one Postgres resolves to, rather than erroring or silently falling back to a single-argument rounding.

**Grouping by a `SELECT`-list alias — legal here, unlike `WHERE`:** The final query groups by `mth`, which is the alias given to `EXTRACT(MONTH FROM submit_date)` earlier in the same `SELECT` list. Entry #12/#19 already established that `WHERE` can't see a `SELECT`-list alias, because `WHERE` runs *before* `SELECT` builds its output. `GROUP BY` is different — depending on the database, it can go either way, and **Postgres specifically permits grouping by a `SELECT`-list alias**, resolving it back to the underlying expression. It's a genuine exception worth knowing by name, not a contradiction of the earlier `WHERE` rule — different clauses, different execution-order relationships to `SELECT`.

### The logic used to solve it (the actual reasoning trace)
1. **First attempt grouped by `product_id, stars, submit_date`** — three columns, with `stars` doubly present (once raw in `GROUP BY`, once inside `AVG(stars)` in `SELECT`) and `submit_date` left as a full timestamp rather than reduced to a month first.
2. **`ROUND(avg(stars)::numeric)`** — called with only one argument, silently defaulting to a whole-number result instead of the requested 2 decimal places.
3. **No `ORDER BY`** present, so the question's explicit "sort by month then product" requirement wasn't met even though the values themselves might have been directionally right.
4. **Column order in `SELECT`** (`product_id`, `avg_stars`, `mth`) didn't match the order the question specified (`mth`, `product_id`, `avg_stars`) — a presentation-level mismatch on top of the logic bugs.
5. **Final draft fixed all four at once:** moved `EXTRACT(MONTH FROM submit_date) AS mth` to the front of `SELECT` to match the requested column order, grouped by `product_id, mth` only (dropping `stars` and the raw `submit_date` from `GROUP BY` entirely), used `ROUND(avg(stars)::numeric, 2)` for the 2-decimal-place requirement, and added `ORDER BY mth, product_id`. Submitted and confirmed correct.

### A hand-trace (illustrative — not the platform's actual sample data)
Given three June reviews, two for the same product on different days:

| review_id | product_id | submit_date | stars |
|---|---|---|---|
| 1 | 77 | 2023-06-08 | 3 |
| 2 | 77 | 2023-06-18 | 5 |
| 3 | 77 | 2023-06-25 | 4 |

**Buggy version — `GROUP BY product_id, stars, submit_date`:** all three rows have distinct `submit_date` values and distinct `stars` values, so all three form **separate groups**. Each group's `AVG(stars)` is computed over exactly one row, returning that row's own `stars` value back unchanged (`3`, `5`, `4`) — no averaging has actually happened, and June's true average (`(3+5+4)/3 = 4.0`) never appears anywhere.

**Fixed version — `GROUP BY product_id, mth`** (where `mth = EXTRACT(MONTH FROM submit_date) = 6` for all three rows): all three rows share `product_id = 77` and `mth = 6`, so they collapse into **one group** of three rows. `AVG(stars)` now genuinely averages across all three: `(3 + 5 + 4) / 3 = 4.0`, and `ROUND(4.0::numeric, 2)` reports it as `4.00`.

### Full solution
```sql
SELECT extract(MONTH from submit_date) as mth,
       product_id,
       round(avg(stars)::numeric, 2) as avg_stars
from reviews
group by product_id, mth
order by mth, product_id;
```

### The pattern to remember
**A column that's being aggregated (sitting inside `AVG`/`SUM`/`COUNT`/etc.) must never also appear raw in that same query's `GROUP BY`** — doing so guarantees each group already shares that column's value, making the aggregate a no-op that just echoes it back. Separately: **a `timestamp` column has to be reduced to the calendar unit the question actually cares about (via `EXTRACT` or similar) *before* it can be grouped by that unit** — grouping by the raw column groups by every distinct instant, not by day/month/year. And: **`ROUND(x, n)`'s second argument is not optional decoration — it's the entire mechanism for keeping decimal places**, and Postgres's two-argument `ROUND` specifically wants a `numeric` first argument, which is what the `::numeric` cast is for.

### Best practices / general approach — if you see this kind of question again
- **Cross-check every `GROUP BY` column against every aggregate function in the same `SELECT`** — if a column appears inside an aggregate, confirm it does *not* also appear raw in `GROUP BY`.
- **Any date/timestamp column being grouped "by month" (or year, day, etc.) needs `EXTRACT` (or equivalent) applied first** — never group by the raw column and expect it to behave like the reduced unit.
- **A rounding requirement stated as "to N decimal places" always means the two-argument `ROUND(x, n)` form** — the one-argument form is a different, coarser operation, not a smaller version of the same one.
- **Match `SELECT`'s column order to the order the question specifies**, not just the right columns in any order — output-matching discipline reapplied from Entry #8.
- **Grouping by a `SELECT`-list alias works in Postgres, but referencing that alias in `WHERE` does not** (Entries #12/#19) — same alias, different clause, different execution-order rule; don't assume one implies the other.

### Mistakes made this time (new ones, not repeats)
- **Grouped by the column being averaged (`stars`) in addition to averaging it** — a new mistake shape: not an over-grouping by an unrelated extra column (Entry #22's version), but grouping by the very column the aggregate needs to vary across.
- **Grouped by the raw `submit_date` timestamp instead of an `EXTRACT`-reduced month value** — first time this specific "aggregate at the wrong calendar granularity" mistake has shown up.
- **Called `ROUND` with only one argument** when the question specified 2 decimal places — new mistake, distinct from any prior `ROUND` use (first time `ROUND` has been used at all in this project).
- **`SELECT` column order didn't match the question's specified output order** — a presentation-discipline slip, not a logic bug, but still a repeat of the general "match output to what's asked" lesson from Entry #8 in a new concrete form.

