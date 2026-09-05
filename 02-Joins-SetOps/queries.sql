-- Customers with zero invoices (LEFT JOIN anti-join pattern)
-- Verified correct despite returning 0 rows: COUNT(*) FROM customer = 59,
-- COUNT(DISTINCT customer_id) FROM invoice = 59 — every customer has bought
-- something in this dataset, so an empty result here is the true answer,
-- not a broken query.
SELECT invoice.customer_id
FROM customer
LEFT JOIN invoice
    ON customer.customer_id = invoice.customer_id
WHERE invoice.invoice_id IS NULL;

-- Every track's name and album title, keeping every track even if it has
-- no album or was never sold (LEFT JOIN chain anchored on track — track sits
-- in the middle, with direct FKs to both album and invoice_line).
SELECT name, title
FROM track
LEFT JOIN album
    ON track.album_id = album.album_id
LEFT JOIN invoice_line
    ON invoice_line.track_id = track.track_id;

-- FULL JOIN anti-join (both directions at once): playlists with zero tracks,
-- and tracks never added to any playlist. playlist_track's playlist_id and
-- track_id are its composite PK, so they're NULL together or populated
-- together here — OR happens to behave like AND in this specific query,
-- though OR is still the correct general pattern.
SELECT track.name, track.track_id
FROM playlist
FULL JOIN playlist_track ON playlist.playlist_id = playlist_track.playlist_id
FULL JOIN track ON track.track_id = playlist_track.track_id
WHERE playlist_track.playlist_id IS NULL
   OR playlist_track.track_id IS NULL;

-- FULL JOIN anti-join: genres with no tracks, and tracks with no genre
-- assigned (track.genre_id is nullable). Unlike the playlist_track case
-- above, the two NULL checks here are genuinely independent (no shared
-- composite key), so OR is essential — AND would return nothing.
-- Returned 0 rows: every genre has at least one track and every track has
-- a genre in this Chinook dataset — same "empty result is the true answer"
-- lesson as the first anti-join query above.
SELECT track.name, track.genre_id
FROM track
FULL JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name IS NULL
   OR track.name IS NULL;

-- EXCEPT: any invoice billing country with no matching customer country.
-- Order matters for EXCEPT (unlike UNION/INTERSECT) — invoice.billing_country
-- must be the first SELECT since we're asking "does a billing country exist
-- that customer.country doesn't have."
-- Returned 0 rows: every billing country traces back to an actual customer
-- in that country — referential integrity holding, not a broken query.
SELECT billing_country FROM invoice
EXCEPT
SELECT country FROM customer;

-- UNION: every distinct country that's either a customer's country or an
-- invoice's billing country, deduplicated. Returned 24 rows.
SELECT customer.country FROM customer
UNION
SELECT invoice.billing_country FROM invoice;

-- INTERSECT: countries that are both a customer's country AND an invoice's
-- billing country. Also returned the same 24 rows as the UNION above —
-- expected, since the EXCEPT query proved neither set has anything the
-- other lacks (0 rows both directions), meaning the two sets are identical.
SELECT customer.country FROM customer
INTERSECT
SELECT invoice.billing_country FROM invoice;

-- CROSS JOIN: Cartesian product, every playlist paired with every genre,
-- no relationship or ON clause needed. 18 playlists x 25 genres = 450 rows,
-- confirmed by the actual result (predicted correctly before running).
SELECT playlist_id FROM playlist
CROSS JOIN genre;
