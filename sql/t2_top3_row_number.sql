-- T2 (version 1, ROW_NUMBER). The three highest-rated movies for each
-- occupation, among movies rated at least 20 times by users with that occupation.
-- Required columns: occupation, pos, movie_id, title, n, mean_rating
-- Order the window so that the result is the same on every run (state your
-- tie-breaker in WRITEUP.md).
--
-- Prediction (commit before running): ______ rows.

WITH occ_movie AS (
  SELECT u.occupation, r.movie_id, COUNT(*) AS n, AVG(r.rating) AS mean_rating
  FROM ratings AS r
  JOIN users AS u USING (user_id)
  GROUP BY u.occupation, r.movie_id
  HAVING COUNT(*) >= 20),
ranked AS (
  SELECT occupation, movie_id, n, mean_rating,
         ROW_NUMBER() OVER (PARTITION BY occupation
                            ORDER BY mean_rating DESC, n DESC, movie_id ASC) AS pos
  FROM occ_movie)
SELECT k.occupation, k.pos, k.movie_id, m.title, k.n, k.mean_rating
FROM ranked AS k
JOIN movies AS m USING (movie_id)
WHERE k.pos <= 3
ORDER BY k.occupation, k.pos;
