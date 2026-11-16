CREATE SCHEMA IF NOT EXISTS uc;
SET search_path TO uc;
-- Table 1: Cities
CREATE TABLE IF NOT EXISTS cities (
city_id INTEGER PRIMARY KEY,
city_name VARCHAR(100) NOT NULL,
state VARCHAR(100) NOT NULL
);
-- Table 2: Customers
CREATE TABLE IF NOT EXISTS customers(
customer_id INTEGER PRIMARY KEY,
full_name VARCHAR(150) NOT NULL,
phone VARCHAR(20) NOT NULL UNIQUE,
email VARCHAR(255) UNIQUE,
city_id INTEGER NOT NULL,
plus_valid_until DATE,
created_at TIMESTAMPTZ NOT NULL,
CONSTRAINT fk_customers_city FOREIGN KEY (city_id) REFERENCES
cities(city_id)
);
-- Table 3: Service Categories
CREATE TABLE IF NOT EXISTS service_categories(
category_id INTEGER PRIMARY KEY,
category_name VARCHAR(100) NOT NULL UNIQUE
);
-- Table 4: Services
CREATE TABLE IF NOT EXISTS services(
service_id INTEGER PRIMARY KEY,
category_id INTEGER NOT NULL,
service_name VARCHAR(150) NOT NULL UNIQUE,
duration_min INTEGER NOT NULL CHECK (duration_min > 0),
base_price NUMERIC(10, 2) NOT NULL CHECK (base_price >= 0),
is_active BOOLEAN NOT NULL,
CONSTRAINT fk_services_category FOREIGN KEY (category_id)
REFERENCES service_categories(category_id)
);
-- Table 5: Professionals
CREATE TABLE IF NOT EXISTS professionals (
pro_id INTEGER PRIMARY KEY,
full_name VARCHAR(150) NOT NULL,
phone VARCHAR(20) NOT NULL,
city_id INTEGER NOT NULL,
gender VARCHAR(1) NOT NULL CHECK (gender IN ('M', 'F')),
joined_on DATE NOT NULL,
rating NUMERIC(3,2) CHECK (rating BETWEEN 1 AND 5),
kyc_verified BOOLEAN NOT NULL,
status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE',
'OFFBOARDED', 'SUSPENDED')),
CONSTRAINT fk_professionals_city FOREIGN KEY (city_id)
REFERENCES cities(city_id)
);
-- Table 6: Professional Skills
CREATE TABLE IF NOT EXISTS pro_skills (
pro_id INTEGER NOT NULL,
category_id INTEGER NOT NULL,
certified_on DATE NOT NULL,
PRIMARY KEY (pro_id, category_id),
CONSTRAINT fk_pro_skills_professional FOREIGN KEY (pro_id)
REFERENCES professionals(pro_id),
CONSTRAINT fk_pro_skills_category FOREIGN KEY (category_id)
REFERENCES service_categories(category_id)
);
-- Table 7: Proffessional Availability
CREATE TABLE IF NOT EXISTS pro_availability (
    pro_id INTEGER NOT NULL,
work_date DATE NOT NULL,
start_time TIME NOT NULL,
end_time TIME NOT NULL,
PRIMARY KEY (pro_id, work_date, start_time),
CONSTRAINT fk_availability_professional FOREIGN KEY (pro_id)
REFERENCES professionals(pro_id),
CONSTRAINT chk_availability_time CHECK (end_time >
start_time)
);
-- Table 8: Bookings
CREATE TABLE IF NOT EXISTS bookings (
booking_id INTEGER PRIMARY KEY,
customer_id INTEGER NOT NULL,
service_id INTEGER NOT NULL,
pro_id INTEGER,
city_id INTEGER NOT NULL,
pincode VARCHAR(10) NOT NULL,
booked_at TIMESTAMPTZ NOT NULL,
scheduled_start TIMESTAMPTZ NOT NULL,
scheduled_end TIMESTAMPTZ NOT NULL,
started_at TIMESTAMPTZ,
completed_at TIMESTAMPTZ,
status VARCHAR(30) NOT NULL CHECK (status IN (
'ASSIGNED',
'CANCELLED_BY_CUSTOMER',
'CANCELLED_BY_PRO',
'COMPLETED',
'NO_SHOW',
'REQUESTED'
)),
price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
discount NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
cancellation_fee NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK
(cancellation_fee >= 0),
tip NUMERIC(10,2) CHECK (tip >= 0),
payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN
('CARD', 'CASH', 'UPI', 'WALLET')),
CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id)
REFERENCES customers(customer_id),
CONSTRAINT fk_bookings_service FOREIGN KEY (service_id)
REFERENCES services(service_id),
CONSTRAINT fk_bookings_professional FOREIGN KEY (pro_id)
REFERENCES professionals(pro_id),
CONSTRAINT fk_bookings_city FOREIGN KEY (city_id) REFERENCES
cities(city_id),
CONSTRAINT chk_booking_schedule CHECK (scheduled_end >
scheduled_start),
CONSTRAINT chk_booking_actual_time CHECK (
started_at IS NULL
OR completed_at IS NULL
OR completed_at >= started_at
),
CONSTRAINT chk_booking_discount CHECK (discount <= price)
);
-- Table 9: Reschedules
CREATE TABLE IF NOT EXISTS reschedules (
reschedule_id INTEGER PRIMARY KEY,
booking_id INTEGER NOT NULL,
old_start TIMESTAMPTZ NOT NULL,
new_start TIMESTAMPTZ NOT NULL,
requested_by VARCHAR(20) NOT NULL CHECK (requested_by IN
('CUSTOMER', 'PRO')),
reason TEXT NOT NULL,
created_at TIMESTAMPTZ NOT NULL,
CONSTRAINT fk_reschedules_booking
FOREIGN KEY (booking_id)
REFERENCES bookings(booking_id),
CONSTRAINT chk_reschedule_time
CHECK (new_start <> old_start)
);
-- Table 10: Reviews
CREATE TABLE IF NOT EXISTS reviews (
booking_id INTEGER PRIMARY KEY,
rating_for_pro INTEGER NOT NULL
CHECK (rating_for_pro BETWEEN 1 AND 5),
comment TEXT,
rating_for_customer INTEGER
CHECK (
rating_for_customer BETWEEN 1 AND 5
),
created_at TIMESTAMPTZ NOT NULL,
CONSTRAINT fk_reviews_booking
FOREIGN KEY (booking_id)
REFERENCES bookings(booking_id)
);
-- Table 11: Payouts
CREATE TABLE IF NOT EXISTS payouts (
payout_id INTEGER PRIMARY KEY,
pro_id INTEGER NOT NULL,
week_start DATE NOT NULL,
jobs INTEGER NOT NULL
CHECK (jobs > 0),
gross_earnings NUMERIC(12,2) NOT NULL
CHECK (gross_earnings >= 0),
commission NUMERIC(12,2) NOT NULL
CHECK (commission >= 0),
net_payout NUMERIC(12,2) NOT NULL
CHECK (net_payout >= 0),
status VARCHAR(20) NOT NULL
CHECK (status IN ('PAID', 'PENDING')),
paid_at TIMESTAMPTZ,
CONSTRAINT fk_payouts_professional
FOREIGN KEY (pro_id)
REFERENCES professionals(pro_id),
CONSTRAINT chk_payout_commission
CHECK (commission <= gross_earnings),
CONSTRAINT chk_payout_calculation
CHECK (
ABS(net_payout - (gross_earnings - commission)) <=
0.01
)
);