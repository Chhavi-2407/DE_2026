-- Phase 5: Range partitioning demonstration
-- The original uc.bookings table is not modified.
-- This demonstration uses a separate table with a composite primary key.

DROP TABLE IF EXISTS uc.bookings_partition_demo CASCADE;

CREATE TABLE uc.bookings_partition_demo (
    booking_id INTEGER NOT NULL,
    booked_at TIMESTAMPTZ NOT NULL,
    customer_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    pro_id INTEGER,
    city_id INTEGER NOT NULL,
    status VARCHAR(30) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (booking_id, booked_at)
)
PARTITION BY RANGE (booked_at);

-- 2025 partition
CREATE TABLE uc.bookings_partition_demo_2025
PARTITION OF uc.bookings_partition_demo
FOR VALUES FROM ('2025-01-01 00:00:00+05:30')
TO ('2026-01-01 00:00:00+05:30');

-- 2026 partition
CREATE TABLE uc.bookings_partition_demo_2026
PARTITION OF uc.bookings_partition_demo
FOR VALUES FROM ('2026-01-01 00:00:00+05:30')
TO ('2027-01-01 00:00:00+05:30');

-- Catch dates outside the defined yearly ranges
CREATE TABLE uc.bookings_partition_demo_default
PARTITION OF uc.bookings_partition_demo
DEFAULT;

-- Copy 5,000 representative rows from each year.
-- The source table remains unchanged.
INSERT INTO uc.bookings_partition_demo
    (booking_id, booked_at, customer_id, service_id,
     pro_id, city_id, status, price)
SELECT
    booking_id, booked_at, customer_id, service_id,
    pro_id, city_id, status, price
FROM uc.bookings
WHERE booked_at >= '2025-01-01 00:00:00+05:30'
  AND booked_at <  '2026-01-01 00:00:00+05:30'
ORDER BY booked_at
LIMIT 5000;

INSERT INTO uc.bookings_partition_demo
    (booking_id, booked_at, customer_id, service_id,
     pro_id, city_id, status, price)
SELECT
    booking_id, booked_at, customer_id, service_id,
    pro_id, city_id, status, price
FROM uc.bookings
WHERE booked_at >= '2026-01-01 00:00:00+05:30'
  AND booked_at <  '2027-01-01 00:00:00+05:30'
ORDER BY booked_at
LIMIT 5000;

ANALYZE uc.bookings_partition_demo;

-- Verify rows stored in each partition
SELECT
    tableoid::regclass AS partition_name,
    COUNT(*) AS row_count
FROM uc.bookings_partition_demo
GROUP BY tableoid
ORDER BY partition_name;

-- Demonstrate partition pruning for a 2026 date-range query
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM uc.bookings_partition_demo
WHERE booked_at >= '2026-01-01 00:00:00+05:30'
  AND booked_at <  '2027-01-01 00:00:00+05:30';
