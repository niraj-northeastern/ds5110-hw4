-- T2 (version 2, RANK). The same question, with RANK() ordered by mean_rating
-- only, keeping rows with pos <= 3.
-- Required columns: occupation, pos, movie_id, title, n, mean_rating
--
-- Prediction (commit before running): ______ rows, which is (more / the same / fewer)
-- than version 1, because ______.

WITH occ_movie AS (
  SELECT u.occupation, r.movie_id, COUNT(*) AS n, AVG(r.rating) AS mean_rating
  FROM ratings AS r
  JOIN users AS u USING (user_id)
  GROUP BY u.occupation, r.movie_id
  HAVING COUNT(*) >= 20),
ranked AS (
  SELECT occupation, movie_id, n, mean_rating,
         RANK() OVER (PARTITION BY occupation ORDER BY mean_rating DESC) AS pos
  FROM occ_movie)
SELECT k.occupation, k.pos, k.movie_id, m.title, k.n, k.mean_rating
FROM ranked AS k
JOIN movies AS m USING (movie_id)
WHERE k.pos <= 3
ORDER BY k.occupation, k.pos, k.movie_id;
