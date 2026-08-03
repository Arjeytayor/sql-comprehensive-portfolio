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