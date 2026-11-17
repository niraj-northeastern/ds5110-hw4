-- T1b. How many ratings are above BOTH the user's mean and the movie's mean?
-- Required columns (one row):
--   n_ratings, n_above_both, share_above_both, share_above_both_20plus
-- share_above_both_20plus: the same share, counting only ratings of movies
-- that have at least 20 ratings.
-- Build on T1a in a CTE; filter or count outside it.
--
-- Prediction (commit before running): share_above_both is about ______.

WITH ctx AS (
  SELECT user_id, movie_id, rating,
         AVG(rating) OVER (PARTITION BY user_id)  AS user_mean,
         AVG(rating) OVER (PARTITION BY movie_id) AS movie_mean,
         COUNT(*)    OVER (PARTITION BY movie_id) AS movie_n
  FROM ratings),
flagged AS (
  SELECT movie_n,
         CASE WHEN rating > user_mean AND rating > movie_mean THEN 1 ELSE 0 END AS above_both
  FROM ctx)
SELECT COUNT(*)                                          AS n_ratings,
       SUM(above_both)                                   AS n_above_both,
       AVG(above_both)                                   AS share_above_both,
       AVG(CASE WHEN movie_n >= 20 THEN above_both END)  AS share_above_both_20plus
FROM flagged;
