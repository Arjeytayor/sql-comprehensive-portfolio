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

