# HW4 Write-up - Windows and Plans


## T1. A rating in context

### Prediction
Every person has a different taste in movies and personal baseline. Rating of 3(mid) from someone who usually gives low ratings(1s or 2s) can mean multiple things including but not limited to - they are a harsh critic and the movie deserves a high grade for how well made it actually is.
Whereas the grade 3 from someone who usually gives high ratings( 4s or 5s) could mean they didn't enjoy the movie as much as they expected, or simply not aligning with their taste, thereby grading the movie as mid.

## T2. Top three per occupation

### Prediction
a. Given 21 occupations and if every occupation as at least 3 movies with rating from that occupation, the total number of rows could be 63

b. In case of ties, RANK function assigns same ranks and skips the next rank. The RANK would return at least 63 rows if there are no ties, if ties exist then more than version 1. Ties add rows at the cutoff point, if there is a time at the 5th position it would lead to a ranking of 5,5.

c. From a quick look at the dataset, it seems the homemaker has less number of rows in users table. This occupation could come up less, assuming homemakers don't rate movies often or don't watch more movies compared to other professions.  


## T3. Sessions and frames

### Prediction
I expect most users to have few sessions because MovieLens ratings are often submitted in bursts. Removing the explicit ROWS frame should not change session assignments, since ratings with the same timestamp should remain in the same session.

For T3b, I expect the running means to differ for ratings sharing the same timestamp because the default RANGE frame processes tied timestamps together, while ROWS processes them individually.


## T4. Two indexes for four queries

### Prediction
I expect the movie_id, rating index to improve B_movie_page, and the timestamp index to improve C_recent. A_profile should remain unchanged because neither new index targets user_id.

D_month may still scan the timestamp index because applying a function to timestamp prevents an efficient range lookup. Rewriting it as a timestamp range should allow the index to be searched directly.
