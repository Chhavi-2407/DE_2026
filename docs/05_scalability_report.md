# CP4 – Large Dataset and Scalability Report

## 1. Objective

This phase evaluates the Urban Company Home Services database using a substantially larger dataset.

The objectives are to:
- Load and validate the large dataset.
- Execute the optimized workload against the large database.
- Measure all 30 queries over three runs.
- Identify queries that become expensive at larger scale.
- Demonstrate range partitioning and partition pruning.
- Discuss further scalability strategies.

## 2. Benchmark Environment

| Property | Value |
|---|---|
| Database | PostgreSQL 18.4 |
| Large database | `uc_large` |
| Schema | `uc` |
| Operating system | macOS |
| Architecture | Apple Silicon (aarch64) |
| Processor | Apple M4 |
| Memory | 16 GB |
| Workload | 30 queries (R01–R25, W01–W05) |
| Runs per query | 3 |
| Measurement | EXPLAIN (ANALYZE, BUFFERS) |
| Indexes | `sql/05_indexes.sql` |
| Optimized queries | `sql/06_optimized_queries.sql` |

The benchmark was executed using:

```bash
./benchmarks/run_benchmark.sh uc_large large 3 sql/06_optimized_queries.sql
```

The results are stored in `benchmarks/results/large/`.

## 3. Dataset Growth and Validation

The large dataset contains 7,525,447 rows across 11 tables.

| Table | Rows |
|---|---:|
| cities | 10 |
| service_categories | 10 |
| services | 60 |
| professionals | 50,000 |
| customers | 800,000 |
| pro_skills | 100,001 |
| pro_availability | 1,397,530 |
| bookings | 3,000,000 |
| reschedules | 106,306 |
| reviews | 1,535,227 |
| payouts | 536,303 |
| **Total** | **7,525,447** |

The original baseline dataset contained 376,932 rows.

Therefore:

- Baseline rows: 376,932
- Large dataset rows: 7,525,447
- Approximate growth factor: 19.96x

The large dataset was loaded into a separate database named `uc_large`. The original `uc_baseline` database was preserved.

The large database was created using the existing schema and a temporary copy of the load script with the data directory changed from `seed_data/` to `large_data/`.

All 11 tables were successfully populated.

The optimized indexes were applied and ANALYZE was executed.

## 4. Large Dataset Benchmark Results

All measurements below are average execution times from three runs, in milliseconds.

| Query | Type | Average (ms) |
|---|---|---:|
| R01 | READ | 0.100 |
| R02 | READ | 1.534 |
| R03 | READ | 0.242 |
| R04 | READ | 0.159 |
| R05 | READ | 0.454 |
| R06 | READ | 0.205 |
| R07 | READ | 0.195 |
| R08 | READ | 21.555 |
| R09 | READ | 29.429 |
| R10 | READ | 391.501 |
| R11 | READ | 16.162 |
| R12 | READ | 40.716 |
| R13 | READ | 46.520 |
| R14 | READ | 225.242 |
| R15 | READ | 165.486 |
| R16 | READ | 4.923 |
| R17 | READ | 523.616 |
| R18 | READ | 0.539 |
| R19 | READ | 311.322 |
| R20 | READ | 48.952 |
| R21 | READ | 342.284 |
| R22 | READ | 12.578 |
| R23 | READ | 0.231 |
| R24 | READ | 7.980 |
| R25 | READ | 92.976 |
| W01 | WRITE | 3.478 |
| W02 | WRITE | 1.212 |
| W03 | WRITE | 0.093 |
| W04 | WRITE | 102.891 |
| W05 | WRITE | 756.474 |

The complete benchmark summary, including medians, minimums, maximums and scan nodes, is available in:

`benchmarks/results/large/summary.csv`

Individual execution plans are stored in the same directory.

## 5. Performance Target Evaluation

The project defines the following target groups:

| Category | Queries | Target |
|---|---|---:|
| Real-time / application-facing | R01–R07, R23, W01–W03 | Under 5 ms |
| Interactive | R08, R11, R13, R16, R18, R22, W05 | Under 250 ms |
| Analytics | R09, R10, R12, R14, R15, R17, R19, R20, R21, R24, R25 | Under 5,000 ms |
| Batch | W04 | Under 1,000 ms |

### Results

**Real-time / application-facing**

All queries in this group meet the target based on their measured average execution times. W01 is the slowest in this group at 3.478 ms.

**Interactive**

R08, R11, R13, R16, R18 and R22 meet the 250 ms target.

W05 does not meet the target. Its average execution time is 756.474 ms, with a maximum of 1,653.119 ms across the three runs.

**Analytics**

All 11 analytics queries meet the 5,000 ms target.

R17 is the slowest analytics query at 523.616 ms, followed by R10 at 391.501 ms and R21 at 342.284 ms.

**Batch**

W04 meets the 1,000 ms target with an average execution time of 102.891 ms.

## 6. Important Scalability Observations

### 6.1 Fast application-facing queries

R01–R07 and R23 remain below 5 ms on average.

The execution plans show useful index access, including:
- Professional city/status/rating index.
- Customer and professional booking indexes.
- Requested booking and completed booking partial indexes.
- Primary key and unique indexes.

These indexes support frequent lookups and date-range filtering.

### 6.2 Aggregation becomes more expensive

R10, R14, R17, R19 and R21 perform larger aggregation or join operations.

R17 takes 523.616 ms. It processes completed bookings and groups information by customer and service category.

R10 takes 391.501 ms and uses a sequential scan on bookings.

These queries remain within the analytics target, but they are candidates for further query-plan investigation as the dataset grows.

### 6.3 W05 is an interactive workload bottleneck

W05 averages 756.474 ms and has a maximum observed time of 1,653.119 ms.

Its execution plan uses `idx_bookings_assigned_unstarted_end`.

Despite index usage, the update still has to locate and modify qualifying rows. Index access alone does not guarantee that a large update will be inexpensive.

Possible future improvements include:
- Running the update in smaller batches.
- Reviewing the number of rows affected.
- Monitoring lock duration and transaction size.
- Reviewing whether the partial index matches the exact update predicate.

These are recommendations for future testing, not changes already implemented.

### 6.4 Variability between executions

W05 has a wide range between its minimum and maximum execution times.

This indicates that average execution time alone does not fully describe workload behavior.

The median, minimum and maximum values in `summary.csv` should also be considered when evaluating production responsiveness.

## 7. Storage Analysis

The large database occupies approximately 2.3 GB in total relation storage, including indexes and associated storage.

Major table sizes observed:

| Table | Approximate total size |
|---|---:|
| bookings | 1,820 MB |
| reviews | 198 MB |
| pro_availability | 167 MB |
| customers | 156 MB |
| payouts | 52 MB |
| reschedules | 15 MB |
| pro_skills | 8.8 MB |
| professionals | 8.3 MB |
| services | 40 kB |
| service_categories | 40 kB |
| cities | 24 kB |

Bookings is the largest table and is an important candidate for future storage optimization and partitioning.

Indexes also consume storage. Their benefits should therefore be evaluated against the extra disk space and write-maintenance cost.

## 8. Range Partitioning Demonstration

### 8.1 Booking date distribution

The original `uc.bookings` table contains 3,000,000 bookings.

| Year | Booking count |
|---|---:|
| 2025 | 2,005,495 |
| 2026 (January–June) | 994,505 |
| **Total** | **3,000,000** |

The earliest booking timestamp is 1 January 2025, and the latest is 30 June 2026.

### 8.2 Partitioning design

A separate demonstration table named `uc.bookings_partition_demo` was created using range partitioning on `booked_at`.

The demonstration contains:
- `bookings_partition_demo_2025`
- `bookings_partition_demo_2026`
- `bookings_partition_demo_default`

The partition boundaries use the observed timestamp ranges and the `+05:30` time zone.

The demonstration table uses a composite primary key:

`PRIMARY KEY (booking_id, booked_at)`

### 8.3 Why the original table was not directly partitioned

The original bookings table has:

`PRIMARY KEY (booking_id)`

It is also referenced by the `reschedules` and `reviews` tables through foreign keys on `booking_id`.

PostgreSQL requires a partitioned table's unique or primary key constraint to include the partition key. Directly partitioning the existing table by `booked_at` would therefore require changes to the key design and dependent foreign keys.

To avoid changing the existing schema and relationships, the project uses a separate proof-of-concept table.

The demonstration copies 5,000 rows from each year, for 10,000 rows in total. It does not replace or modify the original 3-million-row bookings table.

### 8.4 Partition pruning verification

The following query was tested:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM uc.bookings_partition_demo
WHERE booked_at >= '2026-01-01 00:00:00+05:30'
  AND booked_at < '2027-01-01 00:00:00+05:30';
```

The execution plan showed:

```text
Seq Scan on bookings_partition_demo_2026
```

The 2025 and default partitions were not scanned.

Measured results:

| Metric | Result |
|---|---:|
| Rows in 2025 partition | 5,000 |
| Rows in 2026 partition | 5,000 |
| Rows returned by test query | 5,000 |
| Execution time | 0.550 ms |
| Planning time | 0.083 ms |

This confirms that PostgreSQL successfully pruned irrelevant partitions for the selected date range.

The result demonstrates partition pruning on the sample table. It is not a full-scale performance comparison against the original 3-million-row table.

The partitioning implementation is available in `sql/08_partitioning.sql`.

## 9. Further Scalability Strategies

The following strategies are proposed for future production-scale deployment. They were not implemented or benchmarked as part of this phase.

### 9.1 Partitioning

Range partitioning by booking date can help manage a large historical bookings table.

Potential benefits:
- Partition pruning for date-specific queries.
- Easier archival of old booking data.
- Maintenance operations on individual partitions.
- More manageable data lifecycle policies.

A production migration must redesign primary keys and dependent foreign keys to satisfy partitioning constraints.

### 9.2 Sharding

If a single PostgreSQL instance becomes insufficient, the data could be distributed across multiple database nodes.

Possible sharding keys include:
- City ID.
- Customer ID.
- A carefully designed combination of city and customer identifiers.

City-based sharding may help local service workloads, but cross-city reports and global queries would become more complex.

### 9.3 Read replicas

Read replicas can distribute read-heavy workloads across additional PostgreSQL instances.

Potential benefits:
- Reduced read pressure on the primary database.
- Better support for analytics and reporting.
- Separation of read traffic from transactional writes.

Replication lag must be considered for queries that require the latest committed data.

### 9.4 Caching

Frequently requested information, such as service categories, city-level service listings and professional discovery results, could be cached.

A cache can reduce repeated database reads.

The implementation would need appropriate expiration and invalidation rules to prevent stale availability, booking or pricing information.

### 9.5 Maintenance

For a larger PostgreSQL database, regular maintenance should include:
- ANALYZE to maintain planner statistics.
- VACUUM to reclaim reusable row space and maintain visibility information.
- Monitoring index growth and unused indexes.
- Monitoring slow queries and execution plans.
- Tracking table and index storage growth.
- Reviewing autovacuum behavior and transaction health.

## 10. Conclusion

The large dataset benchmark successfully loaded 7,525,447 rows and executed all 30 workload queries three times.

The dataset is approximately 19.96 times larger than the baseline dataset.

All real-time/application-facing queries, all analytics queries and the batch query met their defined average execution-time targets.

W05 was the main exception, averaging 756.474 ms against the 250 ms interactive target.

The partitioning proof of concept also confirmed that PostgreSQL can prune irrelevant yearly partitions when filtering by booking timestamp.

The results show that the existing indexes and optimized queries support many operations efficiently at this dataset size. However, large updates and aggregation-heavy queries deserve continued monitoring.

Further work involving production partitioning, batching, read replicas, sharding and caching could support future growth.
