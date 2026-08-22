-- Customers from Brazil, sorted by last name
SELECT first_name, last_name, email
FROM customer
WHERE country = 'Brazil'
ORDER BY last_name ASC;

-- Top 5 most expensive tracks
SELECT name, unit_price
FROM track
ORDER BY unit_price DESC
LIMIT 5;

-- Tracks ranked 6th-10th by price (tiebreaker on name needed since many tracks tie at 1.99)
SELECT name, unit_price
FROM track
ORDER BY unit_price DESC, name ASC
LIMIT 5 OFFSET 5;

-- Total number of tracks
SELECT COUNT(*) from track;

select first_name,last_name,email
from customer
where country= 'Brazil'
order by last_name asc;


select name,unit_price from track
order by unit_price desc,name ASC
limit 5;


select name,unit_price from track
order by unit_price desc, name ASC
limit 5 offset 5;

select table_name from information_schema.tables where table_schema = 'public'



SELECT COUNT(*) FROM track INNER JOIN genre ON track.genre_id = genre.genre_id
GROUP BY genre_id;


select count(*) as track_count, genre.name, genre.genre_id
    from track
     inner join genre
  on track.genre_id = genre.genre_id
  group by genre.name
  having count(*) > 100
  order by track_count desc

 
 select AVG(milliseconds) as track_duration,genre.genre_id,genre.name
  from track
        inner join genre
  on track.genre_id = genre.genre_id
  GROUP BY genre.genre_id
  having count(*) > 50
  order by track_duration desc


select sum(total) as total_spent, customer.first_name,customer.last_name
from invoice
    inner join customer 
on invoice.customer_id = customer.customer_id
group by customer.customer_id
having sum(total) > 40
order by total_spent DESC



select count(album.artist_id) as title_count,artist.name
from album
 inner join artist
on album.artist_id = artist.artist_id
group by artist.artist_id
having count(album.artist_id) > 5
order by title_count DESC


select count(*) as track_count,playlist.name
  from playlist_track
        inner join playlist
  on playlist_track.playlist_id = playlist.playlist_id
  group by playlist.playlist_id
  having count(*) > 20
  order by track_count desc


select first_name,last_name, coalesce(company, 'Independent') as company
from customer;


Select first_name,last_name,
   Case when
  company is null then 'Independent'
  else company
  end as company_name
  from customer;


  select concat (first_name,' ',last_name)
  from customer
  where email like '%gmail.com%';

  select concat (first_name,' ',last_name)
  from customer
  where email like '%gmail.com';

select upper(name),name from track;


  select upper(name) as name_upper,name from track;

select name from artist
      where name ilike 'B%';

select concat(city,', ',country) as city_country from customer;

select composer from track
where composer is null or trim(composer) = ''

select invoice_date from invoice;

select EXTRACT(year FROM invoice_date) AS year,
  count(*)
from invoice
group by year
having count(*) > 30
order by year desc;

select EXTRACT(month FROM invoice_date) AS month,
count(*)
from invoice
group by month
order by month desc;


-- Time elapsed since each invoice
select age(invoice_date) as date_days
from invoice;

-- Invoices from more than 4 years ago
select age(invoice_date) as date_days
from invoice
where age(invoice_date) > '4 years';

select age(timestamp invoice_date) as date_days from invoice

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'invoice';

select age(invoice_date) as date_days from invoice


select age(invoice_date) as date_days from invoice
where age(invoice_date) > '4 years'

select age(invoice_date) as date_days from invoice
where age(invoice_date) > interval '4 years'

select invoice_date + interval '6 months' as date_days from invoice;

-- DataLemur (not Chinook) — candidates(candidate_id, skill) table, no duplicates assumed
-- Find candidates who have all of Python, Tableau, and PostgreSQL
select candidate_id from candidates
group by candidate_id
having count(case when skill in ('Python','Tableau','PostgreSQL') then 1 end) = 3
order by candidate_id asc;

-- General-purpose version, safe even if duplicate skill rows exist
select candidate_id from candidates
where skill in ('Python','Tableau','PostgreSQL')
group by candidate_id
having count(distinct skill) = 3
order by candidate_id asc;

-- DataLemur (not Chinook) — pages(page_id, page_name), page_likes(user_id, page_id, liked_date)
-- Find pages with zero likes (LEFT JOIN + IS NULL anti-join pattern)
select pages.page_id
from pages
left join page_likes
on pages.page_id = page_likes.page_id
where page_likes.page_id is null
order by pages.page_id asc;

-- DataLemur (not Chinook) — parts_assembly(part, finish_date, assembly_step)
-- Find unfinished parts (no finish_date) — WHERE not GROUP BY, ISNULL as Postgres's one-word IS NULL
SELECT part, assembly_step
FROM parts_assembly
WHERE finish_date ISNULL

-- DataLemur (not Chinook) — posts(user_id, post_id, post_content, post_date)
-- Days between each user's first and last 2021 post, users with 2+ posts only
-- MIN/MAX per group (not CASE WHEN — cross-row comparison, not per-row); ::date cast + subtraction for a flat integer, not AGE()
SELECT user_id, MAX(post_date::date) - MIN(post_date::date) AS days_between
FROM posts
WHERE EXTRACT(YEAR FROM post_date) = 2021
GROUP BY user_id
HAVING COUNT(*) >= 2;

-- DataLemur (not Chinook) — messages(message_id, sender_id, receiver_id, content, sent_date)
-- Top 2 senders by message count in August 2022 — ORDER BY + LIMIT for "top N", compound EXTRACT filter with AND
SELECT sender_id, COUNT(message_id) AS message_count
FROM messages
WHERE EXTRACT(year FROM sent_date) = 2022
  AND EXTRACT(month FROM sent_date) = 8
GROUP BY sender_id
ORDER BY message_count DESC
LIMIT 2;

-- DataLemur (not Chinook) — job_listings(job_id, company_id, title, description)
-- Count of companies that have posted duplicate job listings (same title+description within the same company)
WITH companies_dup AS (
  SELECT company_id, title, description, COUNT(*) AS posting_count
  FROM job_listings
  GROUP BY company_id, title, description
  HAVING COUNT(*) > 1
)
SELECT COUNT(DISTINCT company_id) AS duplicate_companies
FROM companies_dup;
