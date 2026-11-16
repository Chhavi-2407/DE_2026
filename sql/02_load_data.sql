-- Set schema
SET search_path TO uc;

-- 1. Cities
\copy uc.cities FROM 'seed_data/cities.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 2. Service Categories
\copy uc.service_categories FROM 'seed_data/service_categories.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 3. Customers
\copy uc.customers FROM 'seed_data/customers.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 4. Professionals
\copy uc.professionals FROM 'seed_data/professionals.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 5. Services
\copy uc.services FROM 'seed_data/services.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 6. Professional Skills
\copy uc.pro_skills FROM 'seed_data/pro_skills.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 7. Professional Availability
\copy uc.pro_availability FROM 'seed_data/pro_availability.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 8. Bookings
\copy uc.bookings FROM 'seed_data/bookings.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 9. Reschedules
\copy uc.reschedules FROM 'seed_data/reschedules.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 10. Reviews
\copy uc.reviews FROM 'seed_data/reviews.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 11. Payouts
\copy uc.payouts FROM 'seed_data/payouts.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');
