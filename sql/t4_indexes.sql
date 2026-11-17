-- T4. At most TWO CREATE INDEX statements, chosen for the four app queries
-- in run.py (A_profile, B_movie_page, C_recent, D_month). run.py applies them to a
-- copy of the database and measures plans, time and size before and after.
--
-- Prediction (commit before running), for each app query:
--   plan before: ______    plan after: ______

CREATE INDEX idx_ratings_movie_rating ON ratings (movie_id, rating);
CREATE INDEX idx_ratings_timestamp    ON ratings (timestamp);
