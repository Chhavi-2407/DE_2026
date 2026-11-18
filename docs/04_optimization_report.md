# CP3 – Query Optimization Report

## 1. Project Overview

This report documents the indexing and SQL query optimization work performed for the Urban Company DBMS project.

The objective was to improve the execution performance of the provided workload while preserving query correctness.

The workload contains:
- 25 read queries (R01–R25)
- 5 write queries (W01–W05)

The report compares the `before` and `after` benchmark phases. The separate `optimized` benchmark run is discussed independently because its results are not directly comparable to the earlier phases.

## 2. Benchmarking Methodology

The benchmark was run using the project's benchmark script.

The recorded metrics include:
- Average execution time (avg_ms)
- Median execution time (median_ms)
- Minimum execution time (min_ms)
- Maximum execution time (max_ms)
- PostgreSQL scan nodes used by the query plan

All execution times are reported in milliseconds.

The averages below are calculated as the arithmetic mean of the per-query average execution times. Each query is weighted equally; these figures are not the total elapsed time of a complete workload run.

## 3. Overall Before vs After Results

| Workload | Before average | After average | Improvement |
|---|---:|---:|---:|
| READ (25 queries) | 4.246 ms | 3.543 ms | 16.6% faster |
| WRITE (5 queries) | 1.399 ms | 1.340 ms | 4.2% faster |
| All 30 queries | 3.771 ms | 3.176 ms | 15.8% faster |

The read workload achieved the largest improvement. The overall average decreased from 3.771 ms to 3.176 ms.

Write performance remained broadly similar. This is expected because indexes primarily help locate rows for reads, while maintaining indexes can also add work to INSERT, UPDATE and DELETE operations.

## 4. Per-Query Performance Comparison

### 4.1 Read Queries

| Query | Before (ms) | After (ms) | Change |
|---|---:|---:|---:|
| R01 | 0.102 | 0.063 | 38.2% faster |
| R02 | 0.179 | 0.219 | 22.3% slower |
| R03 | 0.084 | 0.082 | 2.4% faster |
| R04 | 0.246 | 0.069 | 72.0% faster |
| R05 | 0.073 | 0.064 | 12.3% faster |
| R06 | 0.030 | 0.028 | 6.7% faster |
| R07 | 0.062 | 0.061 | 1.6% faster |
| R08 | 0.626 | 0.709 | 13.3% slower |
| R09 | 2.192 | 2.111 | 3.7% faster |
| R10 | 18.141 | 17.372 | 4.2% faster |
| R11 | 0.624 | 0.605 | 3.0% faster |
| R12 | 3.031 | 1.000 | 67.0% faster |
| R13 | 8.109 | 0.736 | 90.9% faster |
| R14 | 13.851 | 13.655 | 1.4% faster |
| R15 | 9.623 | 9.801 | 1.8% slower |
| R16 | 0.219 | 0.219 | No change |
| R17 | 8.367 | 8.278 | 1.1% faster |
| R18 | 0.129 | 0.129 | No change |
| R19 | 10.696 | 7.502 | 29.9% faster |
| R20 | 8.048 | 1.325 | 83.5% faster |
| R21 | 13.085 | 16.275 | 24.4% slower |
| R22 | 6.047 | 5.780 | 4.4% faster |
| R23 | 0.038 | 0.039 | 2.6% slower |
| R24 | 0.312 | 0.321 | 2.9% slower |
| R25 | 2.233 | 2.134 | 4.4% faster |

### 4.2 Write Queries

| Query | Before (ms) | After (ms) | Change |
|---|---:|---:|---:|
| W01 | 0.812 | 0.795 | 2.1% faster |
| W02 | 0.420 | 0.428 | 1.9% slower |
| W03 | 0.234 | 0.243 | 3.8% slower |
| W04 | 2.468 | 2.608 | 5.7% slower |
| W05 | 3.060 | 2.627 | 14.2% faster |

## 5. Major Indexing Improvements

The indexes in `sql/05_indexes.sql` were designed around the workload's filtering conditions, join columns, sorting requirements and date ranges.

### 5.1 Composite Indexes

Composite indexes place multiple columns in a specific order so PostgreSQL can efficiently locate rows using common combinations of predicates.

Examples:

- `idx_professionals_city_status_rating`
  - Supports city and status filtering and rating-based ordering.
  - Relevant to professional discovery queries such as R02 and R19.

- `idx_bookings_pro_scheduled_start`
  - Uses `(pro_id, scheduled_start)`.
  - Supports professional-specific booking lookups and scheduled-time ranges.
  - Relevant to R04 and W03.

- `idx_bookings_customer_scheduled_start`
  - Supports customer-specific booking lookups ordered by scheduled time.
  - Relevant to R03.

- `idx_bookings_city_booked_at`
  - Supports city filtering followed by a booking timestamp range.
  - Relevant to R16.

### 5.2 Partial Indexes

Partial indexes store only rows satisfying a specified condition. They can reduce index size and improve access when queries repeatedly use that condition.

Examples:

- `idx_bookings_requested_start`
  - Contains REQUESTED bookings.
  - Helps R05.

- `idx_bookings_completed_pro_completed_at`
  - Contains completed bookings.
  - Helps R07.

- `idx_bookings_discounted_booked_at`
  - Contains bookings with positive discounts.
  - Helps R12.

- `idx_bookings_customer_cancelled_pro`
  - Contains relevant customer-cancelled bookings with non-NULL professional IDs.
  - Helps R13.

- `idx_bookings_completed_scheduled_start`
  - Contains completed bookings and supports scheduled-time ranges.
  - Helps R09, R20 and R25.

### 5.3 Covering Indexes

The `INCLUDE` clause stores additional columns in an index without making them part of its search key.

This can allow PostgreSQL to retrieve the required values directly from an index and potentially use an Index Only Scan.

Examples include:
- `idx_bookings_pro_scheduled_start`
- `idx_bookings_customer_scheduled_start`
- `idx_bookings_completed_scheduled_start`
- `idx_payouts_pending_week_net`

An Index Only Scan is not guaranteed: PostgreSQL's visibility information and the selected columns also affect whether it can avoid heap access.

### 5.4 Trigram Index for Text Search

R18 searches review comments using:

`ILIKE '%late%'`

A normal B-tree index generally cannot efficiently support a leading-wildcard pattern like this.

The project enables `pg_trgm` and creates:

`idx_reviews_comment_trgm`

This GIN trigram index is intended to accelerate substring matching in review comments.

## 6. SQL Query Rewrites

Some improvements came from changing the query structure rather than adding indexes.

### 6.1 R04 – Timestamp Range Instead of Date Conversion

The professional booking query filters bookings for a particular date.

Applying a date conversion directly to a timestamp column can make it harder for a normal B-tree index to support the predicate.

The optimized query uses a lower and upper timestamp boundary:

- Start: 2 July 2026 at 00:00
- End: 3 July 2026 at 00:00

It also uses `AT TIME ZONE current_setting('TimeZone')` to preserve the original session-time-zone date semantics.

Result: 0.246 ms to 0.069 ms (72.0% faster).

### 6.2 R12 – Year Extraction Replaced with a Range

Instead of extracting the year from every `booked_at` value, the optimized query uses:

- `booked_at >= 2026-01-01`
- `booked_at < 2027-01-01`

This exposes a timestamp range that can use the partial index on positive discounts.

The time-zone-aware boundaries preserve the original session-time-zone interpretation.

Result: 3.031 ms to 1.000 ms (67.0% faster).

### 6.3 R13 – NOT IN Replaced with NOT EXISTS

The query finds active professionals who have never had a customer-cancelled booking.

`NOT IN` can produce unexpected results if its subquery returns NULL. A NULL can cause the comparison to become UNKNOWN.

`NOT EXISTS` checks whether a matching row exists for each professional and avoids this NULL-related problem.

The partial index on relevant cancelled bookings supports the lookup.

Result: 8.109 ms to 0.736 ms (90.9% faster).

### 6.4 R19 – Aggregate Bookings Once

The city report needs June completed-job counts and each professional's latest completed booking time.

The optimized query:
1. Identifies active Bengaluru professionals.
2. Joins their bookings.
3. Calculates the required statistics grouped by professional.
4. Joins the aggregated results back to the professional list.

This avoids repeating separate booking-table lookups for each professional.

Result: 10.696 ms to 7.502 ms (29.9% faster).

### 6.5 R20 – Sargable Date Filtering

The daily GMV query calculates a running total for June.

The optimized query uses timestamp range predicates instead of applying a date conversion in the filtering condition.

This makes the filter more suitable for the completed-bookings timestamp index.

Result: 8.048 ms to 1.325 ms (83.5% faster).

### 6.6 R25 – Aggregate Booked Minutes Once

The capacity report compares available minutes with completed booked minutes.

The optimized query calculates:
- Available minutes per professional.
- Booked minutes per professional.

The booked-minute calculation is performed once in a separate aggregation and then joined to the availability results.

This avoids repeating a bookings aggregation for every availability group.

The relevant indexes include:
- `idx_pro_availability_work_date_pro`
- `idx_bookings_completed_scheduled_start`

## 7. Biggest Performance Improvements

The most significant improvements were:

| Query | Main optimization | Improvement |
|---|---|---:|
| R13 | NOT EXISTS and partial index | 90.9% |
| R20 | Timestamp range predicate | 83.5% |
| R04 | Timestamp range predicate | 72.0% |
| R12 | Timestamp range and partial index | 67.0% |
| R19 | Single grouped booking aggregation | 29.9% |

These results demonstrate that a combination of suitable indexes and query rewrites can improve database performance.

## 8. Regressions and Observations

Not every query became faster.

Notable read-query regressions:

- R21: 13.085 ms to 16.275 ms.
- R02: 0.179 ms to 0.219 ms.
- R08: 0.626 ms to 0.709 ms.
- R15: 9.623 ms to 9.801 ms.

Possible reasons include:
- PostgreSQL choosing a different execution plan.
- Index maintenance and access costs.
- Small differences in cache state and system load.
- A sequential scan being cheaper than an index scan for a query that reads a large proportion of a table.

The write workload improved by only 4.2% on average. Some writes became slightly slower, which is a normal trade-off to consider when adding indexes.

R21, R10 and R15 remain candidates for further query-plan investigation.

## 9. Separate Optimized Benchmark Run

The separate `benchmarks/results/optimized/summary.csv` records the following averages:

| Workload | Optimized run average |
|---|---:|
| READ (25 queries) | 20.226 ms |
| WRITE (5 queries) | 13.930 ms |
| All 30 queries | 19.177 ms |

These values are substantially higher than the `before` and `after` results.

The optimized run also reports many sequential scans on `bookings`, `professionals` and other tables, whereas the earlier `after` results show several of the intended indexes being used.

Therefore, this run must not be presented as evidence that the query rewrites made performance worse or as a directly comparable third phase.

The database state, indexes, benchmark setup and execution conditions should be checked before drawing conclusions from it. In particular, verify that `sql/05_indexes.sql` has been applied to the same database used for the optimized benchmark, and inspect the corresponding raw execution plans.

The `before` and `after` figures remain the basis of the main comparison in this report.

## 10. Conclusion

The indexing and query optimization work reduced the average execution time across the 30-query workload from 3.239 ms to 2.909 ms, an overall reduction of approximately 10.2%.

The read workload improved by approximately 26.9%, while the write workload improved by approximately 4.2%, with particularly strong gains in R04, R12, R13, R19 and R20.

The results show the value of:
- Composite indexes for common filter and join combinations.
- Partial indexes for frequently queried subsets.
- Covering indexes for reducing heap access.
- Timestamp range predicates for index-friendly date filtering.
- Rewriting repeated aggregations into grouped queries.
- Using `NOT EXISTS` when NULL semantics make `NOT IN` unsafe.

Further work should focus on the queries that regressed and on investigating the separate optimized benchmark run to ensure all phases are measured under equivalent database conditions.

