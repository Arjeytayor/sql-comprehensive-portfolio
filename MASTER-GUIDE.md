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

