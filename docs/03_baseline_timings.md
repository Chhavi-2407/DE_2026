# CP2 – Baseline Query Timings

## 1. Benchmark Environment

- Database: PostgreSQL 18.4
- Database name: `uc_baseline`
- Schema: `uc`
- Dataset: Urban Company Home Services
- Total data rows: 376,932
- Workload: 30 fixed queries (R01–R25 and W01–W05)
- Runs per query: 3
- Measurement: `EXPLAIN (ANALYZE, BUFFERS)`
- Indexing: Only indexes automatically created for PRIMARY KEY and UNIQUE constraints. No additional indexes were created.

The benchmark was executed using:

```bash
PATH="/Applications/Postgres.app/Contents/Versions/18/bin:$PATH" ./benchmarks/run_benchmark.sh uc_baseline baseline
```

The reported average is calculated from three executions of each query.

## 2. Query Timing Results

All times are in milliseconds (ms).

| Query | Type | Run 1 | Run 2 | Run 3 | Average |
|---|---|---:|---:|---:|---:|
| R01 | READ | 0.085 | 0.097 | 0.085 | 0.089 |
| R02 | READ | 13.182 | 12.818 | 12.661 | 12.887 |
| R03 | READ | 10.683 | 10.793 | 12.646 | 11.374 |
| R04 | READ | 9.860 | 9.470 | 9.577 | 9.636 |
| R05 | READ | 14.910 | 16.041 | 16.681 | 15.877 |
| R06 | READ | 0.046 | 0.045 | 0.074 | 0.055 |
| R07 | READ | 10.510 | 11.491 | 11.738 | 11.246 |
| R08 | READ | 3.052 | 2.952 | 2.944 | 2.983 |
| R09 | READ | 12.444 | 12.105 | 12.284 | 12.278 |
| R10 | READ | 35.952 | 36.179 | 38.362 | 36.831 |
| R11 | READ | 1.250 | 1.269 | 1.495 | 1.338 |
| R12 | READ | 14.922 | 23.324 | 36.281 | 24.842 |
| R13 | READ | 15.710 | 16.366 | 16.047 | 16.041 |
| R14 | READ | 40.349 | 41.399 | 43.124 | 41.624 |
| R15 | READ | 26.308 | 26.288 | 28.497 | 27.031 |
| R16 | READ | 9.851 | 10.177 | 11.069 | 10.366 |
| R17 | READ | 33.286 | 34.944 | 33.311 | 33.847 |
| R18 | READ | 31.093 | 31.624 | 31.473 | 31.397 |
| R19 | READ | 6274.466 | 6375.507 | 6464.634 | 6371.536 |
| R20 | READ | 16.736 | 16.093 | 16.766 | 16.532 |
| R21 | READ | 30.171 | 28.794 | 28.203 | 29.056 |
| R22 | READ | 59.248 | 63.126 | 62.367 | 61.580 |
| R23 | READ | 0.084 | 0.086 | 0.090 | 0.087 |
| R24 | READ | 18.806 | 19.748 | 18.363 | 18.972 |
| R25 | READ | 4088.985 | 4113.889 | 4154.392 | 4119.089 |
| W01 | WRITE | 1.249 | 1.100 | 1.121 | 1.157 |
| W02 | WRITE | 20.449 | 20.495 | 21.969 | 20.971 |
| W03 | WRITE | 12.483 | 12.586 | 12.814 | 12.628 |
| W04 | WRITE | 15.577 | 15.887 | 16.269 | 15.911 |
| W05 | WRITE | 13.349 | 13.322 | 13.697 | 13.456 |

## 3. Execution Plan Observations

| Query | Observed scan nodes |
|---|---|
| R01 | Seq Scan: services, service_categories |
| R02 | Seq Scan: pro_skills, professionals, service_categories, bookings; Index Scan: pro_availability |
| R03 | Seq Scan: bookings, services; Index Scan: professionals |
| R04 | Seq Scan: bookings, services |
| R05 | Seq Scan: bookings |
| R06 | Index Scan: customers_phone_key |
| R07 | Seq Scan: bookings |
| R08 | Seq Scan: payouts, professionals |
| R09 | Seq Scan: bookings, services, service_categories |
| R10 | Seq Scan: bookings |
| R11 | Seq Scan: reschedules; Index Scan: bookings_pkey, services_pkey |
| R12 | Seq Scan: bookings |
| R13 | Seq Scan: professionals, bookings |
| R14 | Seq Scan: bookings, services |
| R15 | Seq Scan: bookings, reviews |
| R16 | Seq Scan: bookings |
| R17 | Seq Scan: bookings, services |
| R18 | Seq Scan: reviews |
| R19 | Seq Scan: professionals, bookings |
| R20 | Seq Scan: bookings |
| R21 | Seq Scan: bookings, services, pro_skills |
| R22 | Seq Scan: bookings |
| R23 | Seq Scan: services; Index Scan: bookings_pkey |
| R24 | Seq Scan: bookings |
| R25 | Index Scan: professionals_pkey; Seq Scan: pro_availability, bookings |
| W01 | No scan; INSERT operation |
| W02 | Index Scan: bookings_pkey |
| W03 | Seq Scan: bookings |
| W04 | Seq Scan: bookings |
| W05 | Seq Scan: bookings |

## 4. Query Performance Analysis

### Fast queries

- **R06 (0.055 ms):** Customer lookup by phone is very fast because the phone column has a UNIQUE constraint. PostgreSQL uses the automatically created `customers_phone_key` index.
- **R23 (0.087 ms):** Booking detail lookup uses the primary key index on `bookings`. The additional join to the small services table is inexpensive.
- **R01 (0.089 ms):** The services and service_categories tables contain only 60 and 10 rows respectively. Sequential scans on these small tables are inexpensive.
- **R11 (1.338 ms):** The query uses primary key indexes for bookings and services. Although reschedules is sequentially scanned, the overall query remains fast.
- **W01 (1.157 ms):** A single-row INSERT is relatively inexpensive because it does not need to scan existing table rows.

### Moderate queries

- **R02 (12.887 ms):** Multiple joins and the NOT EXISTS check against bookings increase the work. The availability primary key index is used, but bookings still requires a sequential scan.
- **R03 (11.374 ms):** Filtering bookings by customer and joining services and professionals requires scanning bookings because there is no secondary index on the customer filter.
- **R04 (9.636 ms):** The DATE function applied to scheduled_start and the absence of a supporting secondary index contribute to the sequential scan of bookings.
- **R05 (15.877 ms):** Filtering requested and unassigned bookings by status and scheduled time requires scanning bookings.
- **R07 (11.246 ms):** Earnings aggregation filters bookings by professional, completion status and time range. No supporting secondary index exists.
- **R08 (2.983 ms):** The payouts and professionals tables are smaller than bookings, so their sequential scans are relatively inexpensive.
- **R09 (12.278 ms):** Joining bookings with services and categories, followed by aggregation, requires scanning and processing many rows.
- **R12 (24.842 ms):** Monthly discount aggregation processes bookings with date and discount conditions. Extracting the year from a timestamp also makes a simple timestamp index less useful.
- **R13 (16.041 ms):** The NOT IN subquery checks booking cancellation information while considering active professionals. Both professionals and bookings are sequentially scanned.
- **R15 (27.031 ms):** Review averages require aggregation and a join between reviews and bookings.
- **R16 (10.366 ms):** Grouping June bookings by pincode and ranking the results requires processing matching booking rows.
- **R17 (33.847 ms):** Joining bookings with services and grouping by customer and category involves substantial aggregation.
- **R18 (31.397 ms):** Searching review comments with ILIKE and a leading wildcard (`%late%`) cannot efficiently use a normal B-tree index. PostgreSQL scans reviews.
- **R20 (16.532 ms):** The daily GMV calculation groups bookings by date and computes a running total using a window function.
- **R21 (29.056 ms):** The query checks completed bookings against professional skills using NOT EXISTS. Sequential scans and the anti-join condition increase processing work.
- **R24 (18.972 ms):** Monthly cancellation fee aggregation filters and groups bookings by date and fee, requiring a sequential scan.
- **W02 (20.971 ms):** The primary key index locates the target booking, but the update still incurs row modification and related database work.
- **W03 (12.628 ms):** Updating assigned bookings for a professional and date range requires scanning bookings because there is no supporting secondary index.
- **W04 (15.911 ms):** Inserting grouped payout records requires scanning and aggregating qualifying completed bookings.
- **W05 (13.456 ms):** Updating old assigned bookings to NO_SHOW requires checking booking status, slot end time and started_at. The query uses a sequential scan.

### Slower queries

- **R10 (36.831 ms):** Calculating no-show rates for professionals requires grouping bookings by professional, filtering groups with HAVING and sorting aggregate results.
- **R14 (41.624 ms):** Grouping Bengaluru bookings by service category, weekday and hour requires processing many booking rows and performing date/time calculations.
- **R22 (61.580 ms):** Deep OFFSET pagination (`OFFSET 100000 LIMIT 25`) requires PostgreSQL to process and skip a large number of rows before returning the requested page.
- **R19 (6371.536 ms):** This is the slowest query. It uses two correlated subqueries to calculate completed job counts and latest completion times for each active Bengaluru professional. The execution plan shows each subquery scanning bookings 357 times. Repeated full-table scans cause very high execution time.
- **R25 (4119.089 ms):** This query calculates professional utilization using available minutes and booked minutes. Its correlated subquery performs a sequential scan of bookings 357 times, once for each professional in the aggregation. This repeated scanning is the main performance bottleneck.

## 5. Overall Findings

1. R19 is the slowest query, with an average execution time of 6371.536 ms.
2. R25 is the second slowest query, with an average execution time of 4119.089 ms.
3. R06 is the fastest query at 0.055 ms because PostgreSQL uses the UNIQUE phone index.
4. R23 is also very fast at 0.087 ms because it uses the booking primary key index.
5. Sequential scans are common because the baseline intentionally has no additional secondary indexes.
6. Correlated subqueries in R19 and R25 repeatedly scan the large bookings table, resulting in significant execution time.
7. Queries involving aggregation, joins, date calculations, pattern matching and deep pagination generally require more processing.
8. The baseline provides a reference point for comparing query performance after future database tuning.

## 6. Conclusion

The baseline benchmark successfully executed all 30 workload queries, with each query measured three times. The results show that primary key and UNIQUE indexes help specific lookups, while large-table scans and repeated correlated subqueries are major performance bottlenecks.

No additional indexes or query optimizations were applied during this phase. These measurements will serve as the reference for evaluating the improvements achieved in the subsequent database tuning phase.
