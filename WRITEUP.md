# HW4 Write-up - Windows and Plans

> All numbers below come from `python run.py all` (see `output/`).

## T1. A rating in context

### Prediction
Every person has a different taste in movies and personal baseline. Rating of 3(mid) from someone who usually gives low ratings(1s or 2s) can mean multiple things including but not limited to - they are a harsh critic and the movie deserves a high grade for how well made it actually is.
Whereas the grade 3 from someone who usually gives high ratings( 4s or 5s) could mean they didn't enjoy the movie as much as they expected, or simply not aligning with their taste, thereby grading the movie as mid.

### Result
- T1a: 100,000 rows (one per rating). Plan: one `SCAN ratings`, two `USE TEMP B-TREE FOR ORDER BY` (one sort per partition key). `output/t1.json`
- T1b: n_ratings = 100000, n_above_both = 45232, share_above_both = 0.4523, share_above_both_20plus = 0.4604. `output/t1b.csv`
- T1c: chain 269 rows, rewrite 269 rows, `same_rows: true`.

### Explanation
T1a returns 100,000 rows. One query can calculate two window averages because each window uses its own partition: one by user_id and one by movie_id.

T1b shows 45.23% of ratings are above both means, increasing slightly to 46.04% for movies with 20+ ratings. A movie with only one rating has a movie mean equal to that rating, so that rating can never be strictly above the movie mean. Removing such low-count movies can therefore affect the share.

T1c returned 269 identical rows. The window function replaces the separate genre aggregation and join-back steps by calculating the genre mean directly alongside each movie.


## T2. Top three per occupation

### Prediction
a. Given 21 occupations and if every occupation as at least 3 movies with rating from that occupation, the total number of rows could be 63

b. In case of ties, RANK function assigns same ranks and skips the next rank. The RANK would return at least 63 rows if there are no ties, if ties exist then more than version 1. Ties add rows at the cutoff point, if there is a time at the 5th position it would lead to a ranking of 5,5.

c. From a quick look at the dataset, it seems the homemaker has less number of rows in users table. This occupation could come up less, assuming homemakers don't rate movies often or don't watch more movies compared to other professions.  

### Result
- ROW_NUMBER: 27 rows. Tie-breaker: `mean_rating DESC, n DESC, movie_id ASC`.
- RANK: 28 rows.
- Tie: educator - Dr. Strangelove (474, n=21) and Rear Window (603, n=28), both 4.571429, both RANK 3.
- Fewer than 3 rows: executive (2), technician (1). No rows at all: artist, doctor, entertainment, healthcare, homemaker, lawyer, marketing, none, retired, salesman, scientist. `output/t2.json`

### Explanation
ROW_NUMBER() returned 27 rows, while RANK() returned 28 because educator had two movies tied at rank 3 with a 4.571429 mean.

Executive had only 2 qualifying movies and technician 1; several occupations had none because not enough movies met the 20-rating requirement.

For a “top picks for your profession” page, I would use ROW_NUMBER() because it guarantees exactly three picks when three qualifying movies exist.

DENSE_RANK() would be appropriate if the rule were “show the top three distinct rating levels.” ROW_NUMBER() would incorrectly break ties, while RANK() could skip the next rating level after a tie.

## T3. Sessions and frames

### Prediction
I expect most users to have few sessions because MovieLens ratings are often submitted in bursts. Removing the explicit ROWS frame should not change session assignments, since ratings with the same timestamp should remain in the same session.

For T3b, I expect the running means to differ for ratings sharing the same timestamp because the default RANGE frame processes tied timestamps together, while ROWS processes them individually.


### Result
- 2,793 sessions; session sizes sum to 100,000. Median 11 ratings/session, max 737. 562 users have one session; median sessions/user = 1. `output/t3.json`
- Default-frame variant identical: `true`.
- T3b: 49,787 rows disagree; all 49,787 share a timestamp with another rating by the same user (75,772 such rows in total). Last values agree for 943 / 943 users. `output/t3b_disagreements_head.csv`

### Explanation
The data produced 2,793 sessions, with a median of 11 ratings/session.

The default-frame session result was identical. ROWS processes records individually, while the default RANGE treats equal timestamps as peers. When tied ratings occur, the new-session flag is included for the peer group, so they still receive the same session number.

The 30-minute rule is approximate: a 31-minute break could split one real session, while two separate activities less than 30 minutes apart could be combined.

For T3b, 49,787 rows differed, all involving shared timestamps. RANGE includes tied rows together, while ROWS processes them sequentially. Final means still matched for 943/943 users because both eventually include every rating.

## T4. Two indexes for four queries

### Prediction
I expect the movie_id, rating index to improve B_movie_page, and the timestamp index to improve C_recent. A_profile should remain unchanged because neither new index targets user_id.

D_month may still scan the timestamp index because applying a function to timestamp prevents an efficient range lookup. Rewriting it as a timestamp range should allow the index to be searched directly.

### Result
Indexes: `ratings(movie_id, rating)` and `ratings(timestamp)`.

| Query | Plan before | Plan after | ms before | ms after |
|---|---|---|---|---|
| A_profile | SEARCH autoindex (user_id=?) + USE TEMP B-TREE FOR ORDER BY | unchanged | 0.118 | 0.115 |
| B_movie_page | SCAN ratings | SEARCH COVERING INDEX idx_ratings_movie_rating (movie_id=?) | 3.989 | 0.012 |
| C_recent | SCAN ratings | SEARCH COVERING INDEX idx_ratings_timestamp (timestamp>?) | 3.077 | 0.045 |
| D_month | SCAN ratings | SCAN ratings USING COVERING INDEX idx_ratings_timestamp | 29.588 | 27.330 |
| D_rewrite | SCAN ratings | SEARCH COVERING INDEX idx_ratings_timestamp (timestamp>? AND timestamp<?) | 5.093 | 0.406 |

DB size: 3,629,056 → 6,168,576 bytes (+2,539,520 bytes for both indexes). Timings are ms per query over 500 runs (`output/t4.json`) and vary by machine.

### Explanation
I chose ratings(movie_id, rating) for B and ratings(timestamp) for C and the D rewrite.

A_profile: Already uses SQLite’s automatic primary-key index on (user_id, movie_id), which starts with user_id, so the new indexes do not improve its lookup. USE TEMP B-TREE FOR ORDER BY means SQLite must additionally sort the matching rows by timestamp.
B_movie_page: Changes from a table scan to a covering-index search.
C_recent: Changes from a scan to an indexed timestamp range search.
D_month: Remains a scan because strftime() transforms the indexed column, preventing a direct range search.
D_rewrite: timestamp >= ? AND timestamp < ? operates directly on the raw column, allowing an indexed range search.

The two indexes add 2,539,520 bytes, increasing the database from 3,629,056 to 6,168,576 bytes.

Considering D_rewrite does not change the index choice because the timestamp index already selected for C_recent also serves the rewritten month query efficiently.

## T5. Recommendation (120–200 words)
I recommend adding the ratings(movie_id, rating) and ratings(timestamp) indexes. The first improves movie-page queries by allowing SQLite to find ratings for a specific movie directly instead of scanning the full ratings table. The second improves recent-rating queries and the rewritten monthly query by allowing SQLite to search a timestamp range efficiently.

I would not add another index for A_profile. SQLite already uses the automatic primary-key index, which starts with user_id, so the two available indexes are better used for queries that otherwise require full scans. I would also rewrite D_month to use timestamp >= ? AND timestamp < ?, since applying strftime() to the timestamp prevents SQLite from performing an index search.

The T4 plans confirm these improvements: B and C change from SCAN to SEARCH, and the rewritten D query also uses SEARCH. The main trade-off is storage: the indexes add 2,539,520 bytes, increasing the database from about 3.63 MB to 6.17 MB. They may also slightly slow inserts and updates because SQLite must maintain both indexes.