-- =====================================================================
-- CP3 - Task 1: indexes for the Urban Company DBMS workload
-- Run after sql/01_schema.sql and after loading the seed data.
-- Existing PRIMARY KEY / UNIQUE indexes are retained; do not duplicate them.
-- All indexes below are based on the predicates, joins and ordering in
-- queries/workload_30.sql. Recheck EXPLAIN (ANALYZE, BUFFERS) after creation.
-- =====================================================================

-- R18 prerequisite: pg_trgm enables GIN trigram matching for ILIKE.
-- If your database role cannot create extensions, ask the DB owner to run this once.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
SET search_path TO uc, public;

-- R02, R19, R25: locate professionals by city; R02 also filters ACTIVE
-- and sorts by rating. R25 can use the city_id leading key as well.
CREATE INDEX IF NOT EXISTS idx_professionals_city_status_rating
    ON professionals (city_id, status, rating DESC NULLS LAST, pro_id)
    INCLUDE (full_name);

-- R02: the existing pro_skills PRIMARY KEY is (pro_id, category_id),
-- which is useful for a lookup from a professional. This reverse-order
-- index helps start from the requested category and find matching pros.
CREATE INDEX IF NOT EXISTS idx_pro_skills_category_pro
    ON pro_skills (category_id, pro_id);

-- R02, R04, W03: equality on pro_id followed by a scheduled_start range.
-- INCLUDE columns cover the overlap check, service join, displayed fields,
-- and status test without making them part of the search key.
CREATE INDEX IF NOT EXISTS idx_bookings_pro_scheduled_start
    ON bookings (pro_id, scheduled_start)
    INCLUDE (scheduled_end, service_id, pincode, status);

-- R03: customer equality + scheduled_start lower bound/order. Included
-- columns cover the selected booking fields and joins to services/pros.
CREATE INDEX IF NOT EXISTS idx_bookings_customer_scheduled_start
    ON bookings (customer_id, scheduled_start)
    INCLUDE (booking_id, service_id, pro_id, status);

-- R05: only REQUESTED bookings are needed, ordered/filtered by start time.
-- The partial index is smaller than indexing every booking.
CREATE INDEX IF NOT EXISTS idx_bookings_requested_start
    ON bookings (scheduled_start)
    INCLUDE (booking_id, service_id, city_id)
    WHERE status = 'REQUESTED';

-- R07: one professional's completed bookings in a completed_at range.
CREATE INDEX IF NOT EXISTS idx_bookings_completed_pro_completed_at
    ON bookings (pro_id, completed_at)
    INCLUDE (price, discount, tip)
    WHERE status = 'COMPLETED';

-- R08: pending payouts for one week, sorted by net payout descending.
CREATE INDEX IF NOT EXISTS idx_payouts_pending_week_net
    ON payouts (week_start, net_payout DESC)
    INCLUDE (payout_id, pro_id, jobs)
    WHERE status = 'PENDING';

-- R09, R20, R25: completed bookings in a scheduled_start range. This
-- covering index supplies each query's required grouping/join/measure
-- columns while keeping non-completed rows out of the index.
CREATE INDEX IF NOT EXISTS idx_bookings_completed_scheduled_start
    ON bookings (scheduled_start)
    INCLUDE (service_id, started_at, price, discount, pro_id, scheduled_end)
    WHERE status = 'COMPLETED';

-- R10, R19: group/find bookings by professional. Excluding NULL pro_id
-- entries matches both queries' effective professional-based lookup.
CREATE INDEX IF NOT EXISTS idx_bookings_pro_nonnull_stats
    ON bookings (pro_id)
    INCLUDE (status, scheduled_start, completed_at)
    WHERE pro_id IS NOT NULL;

-- R11: select the June reschedules by created_at, then join each booking.
CREATE INDEX IF NOT EXISTS idx_reschedules_created_booking
    ON reschedules (created_at, booking_id)
    INCLUDE (requested_by);

-- R12: only positive discounts contribute; booked_at is used as a range
-- after rewriting EXTRACT(YEAR ...) into a sargable timestamp range.
CREATE INDEX IF NOT EXISTS idx_bookings_discounted_booked_at
    ON bookings (booked_at)
    INCLUDE (discount)
    WHERE discount > 0;

-- R13: NOT EXISTS checks whether a professional has a customer-cancelled
-- booking. The partial index stores only those relevant non-NULL pro_ids.
CREATE INDEX IF NOT EXISTS idx_bookings_customer_cancelled_pro
    ON bookings (pro_id)
    WHERE status = 'CANCELLED_BY_CUSTOMER' AND pro_id IS NOT NULL;

-- R14: Bengaluru (city_id) filter, service join, and scheduled timestamp
-- used to derive weekday/hour. The key order starts with city_id equality.
CREATE INDEX IF NOT EXISTS idx_bookings_city_service_scheduled
    ON bookings (city_id, service_id, scheduled_start);

-- R15: June reviews are found by created_at, then joined to bookings.
CREATE INDEX IF NOT EXISTS idx_reviews_created_booking
    ON reviews (created_at, booking_id)
    INCLUDE (rating_for_pro);

-- R16: city equality + booked_at range, with pincode needed for grouping.
CREATE INDEX IF NOT EXISTS idx_bookings_city_booked_at
    ON bookings (city_id, booked_at)
    INCLUDE (pincode);

-- R17: only completed bookings from 2026 contribute to retention counts.
CREATE INDEX IF NOT EXISTS idx_bookings_completed_booked_at
    ON bookings (booked_at)
    INCLUDE (customer_id, service_id)
    WHERE status = 'COMPLETED';

-- R18: a normal B-tree cannot serve ILIKE '%late%'. pg_trgm provides
-- trigram matching. The extension must be available to the DB user.
CREATE INDEX IF NOT EXISTS idx_reviews_comment_trgm
    ON reviews USING GIN (comment gin_trgm_ops)
    WHERE comment IS NOT NULL;

-- R22: newest-first deep pagination. The index supplies the ORDER BY and
-- included columns; OFFSET still has to walk past the first 100,000 rows.
CREATE INDEX IF NOT EXISTS idx_bookings_booked_at_desc_page
    ON bookings (booked_at DESC)
    INCLUDE (booking_id, customer_id, service_id, status);

-- R24: only rows with a positive cancellation fee are relevant to the
-- monthly aggregation; scheduled_start is the date-range/grouping column.
CREATE INDEX IF NOT EXISTS idx_bookings_cancellation_fee_start
    ON bookings (scheduled_start)
    INCLUDE (cancellation_fee)
    WHERE cancellation_fee > 0;

-- R25: date-range access to availability; the existing PK starts with
-- pro_id and is not ideal for a work_date-first range scan.
CREATE INDEX IF NOT EXISTS idx_pro_availability_work_date_pro
    ON pro_availability (work_date, pro_id)
    INCLUDE (start_time, end_time);

-- W02: find the smallest booking_id among REQUESTED rows without scanning
-- every booking. Separate from R05 because W02 needs booking_id order.
CREATE INDEX IF NOT EXISTS idx_bookings_requested_id
    ON bookings (booking_id)
    WHERE status = 'REQUESTED';

-- W04: completed bookings in a completed_at range, grouped by pro_id.
CREATE INDEX IF NOT EXISTS idx_bookings_completed_at_pro_payout
    ON bookings (completed_at, pro_id)
    INCLUDE (price, discount, tip)
    WHERE status = 'COMPLETED';

-- W05: only assigned jobs that have not started can be changed to NO_SHOW.
CREATE INDEX IF NOT EXISTS idx_bookings_assigned_unstarted_end
    ON bookings (scheduled_end)
    WHERE status = 'ASSIGNED' AND started_at IS NULL;

-- Note: R01 and R06/R23 do not need new indexes: R01 touches tiny lookup
-- tables (60 services / 10 categories); customers.phone already has a UNIQUE
-- index (R06); and bookings.booking_id already has its PRIMARY KEY index (R23).
-- The pro_skills PRIMARY KEY also supports R21's (pro_id, category_id) lookup.

ANALYZE;
