-- Set schema
SET search_path TO urban_company;

-- 1. Cities
\copy urban_company.cities FROM 'seed_data/cities.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 2. Service Categories
\copy urban_company.service_categories FROM 'seed_data/service_categories.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 3. Customers
\copy urban_company.customers FROM 'seed_data/customers.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 4. Professionals
\copy urban_company.professionals FROM 'seed_data/professionals.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 5. Services
\copy urban_company.services FROM 'seed_data/services.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 6. Professional Skills
\copy urban_company.pro_skills FROM 'seed_data/pro_skills.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 7. Professional Availability
\copy urban_company.pro_availability FROM 'seed_data/pro_availability.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 8. Bookings
\copy urban_company.bookings FROM 'seed_data/bookings.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 9. Reschedules
\copy urban_company.reschedules FROM 'seed_data/reschedules.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 10. Reviews
\copy urban_company.reviews FROM 'seed_data/reviews.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');

-- 11. Payouts
\copy urban_company.payouts FROM 'seed_data/payouts.csv' WITH (FORMAT CSV, HEADER TRUE, NULL '');