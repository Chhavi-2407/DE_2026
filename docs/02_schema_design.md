# Schema Design

## 1. Overview

The Urban Company Home Services database is designed using a relational database model consisting of 11 tables. The database manages customers, service professionals, service categories, services, bookings, availability, rescheduling, reviews, and payouts.

The main objective of the schema design is to organize data efficiently, minimize unnecessary duplication, maintain data consistency, and enforce relationships between different entities.

The database uses primary keys, foreign keys, UNIQUE constraints, NOT NULL constraints, and CHECK constraints to maintain data integrity. Normalization principles are applied to organize the database into well-structured relations.

## 2. Entities and Their Purpose

The database consists of the following 11 entities:

| Table | Purpose |
|---|---|
| `cities` | Stores city names and their corresponding states. |
| `customers` | Stores customer details, contact information, city, subscription validity, and registration date. |
| `service_categories` | Stores different categories of home services. |
| `services` | Stores individual services, their categories, duration, base price, and active status. |
| `professionals` | Stores professional details, contact information, city, rating, KYC verification, and current status. |
| `pro_skills` | Maps professionals to the service categories in which they are qualified. |
| `pro_availability` | Stores the available dates and time slots of professionals. |
| `bookings` | Stores customer bookings, assigned professionals, scheduling details, payment information, and booking status. |
| `reschedules` | Maintains the history of booking schedule changes. |
| `reviews` | Stores ratings and feedback associated with bookings. |
| `payouts` | Stores weekly earnings, commission, net payout, and payment status of professionals. |

## 3. Relationships and Cardinalities

The relationships between entities are implemented using foreign keys.

| Relationship | Cardinality | Explanation |
|---|---|---|
| Cities to Customers | One-to-Many (1:N) | One city can have multiple customers, while each customer belongs to one city. |
| Cities to Professionals | One-to-Many (1:N) | One city can have multiple professionals, while each professional belongs to one city. |
| Cities to Bookings | One-to-Many (1:N) | One city can be associated with multiple bookings, while each booking references one city. |
| Service Categories to Services | One-to-Many (1:N) | One category can contain multiple services, while each service belongs to one category. |
| Professionals to Service Categories | Many-to-Many (M:N) | A professional can have multiple skills, and a category can be associated with multiple professionals. This relationship is implemented through `pro_skills`. |
| Professionals to Availability | One-to-Many (1:N) | One professional can have multiple availability slots. |
| Customers to Bookings | One-to-Many (1:N) | One customer can create multiple bookings, while each booking belongs to one customer. |
| Services to Bookings | One-to-Many (1:N) | One service can be selected in multiple bookings, while each booking references one service. |
| Professionals to Bookings | One-to-Many (1:N) | One professional can be assigned multiple bookings. A booking can have no assigned professional before allocation. |
| Bookings to Reschedules | One-to-Many (1:N) | One booking can have multiple reschedule records. |
| Bookings to Reviews | One-to-One (1:0..1) | A booking can have at most one review because `booking_id` is the primary key of the reviews table. |
| Professionals to Payouts | One-to-Many (1:N) | One professional can have multiple weekly payout records. |

## 4. Primary Keys and Candidate Keys

A primary key uniquely identifies every record in a table. Candidate keys are minimal sets of attributes that can uniquely identify a record.

The following primary keys are defined in the database:

| Table | Primary Key |
|---|---|
| `cities` | `city_id` |
| `customers` | `customer_id` |
| `service_categories` | `category_id` |
| `services` | `service_id` |
| `professionals` | `pro_id` |
| `pro_skills` | (`pro_id`, `category_id`) |
| `pro_availability` | (`pro_id`, `work_date`, `start_time`) |
| `bookings` | `booking_id` |
| `reschedules` | `reschedule_id` |
| `reviews` | `booking_id` |
| `payouts` | `payout_id` |

### Additional Candidate Keys

The following attributes also act as candidate keys under the declared constraints:

- `customers.phone`: UNIQUE and NOT NULL.
- `service_categories.category_name`: UNIQUE and NOT NULL.
- `services.service_name`: UNIQUE and NOT NULL.

The `customers.email` column has a UNIQUE constraint but allows NULL values. Therefore, it is not treated as a candidate key for the entire customers relation.

The composite primary keys in `pro_skills` and `pro_availability` ensure that each combination of the selected attributes identifies a unique record.

The proposed primary keys were checked against the dataset for duplicate and missing values before being finalized.

## 5. Functional Dependencies

A functional dependency describes a relationship in which one attribute or a group of attributes determines another attribute or group of attributes.

The main functional dependencies identified in the database are:

| Table | Functional Dependency |
|---|---|
| `cities` | `city_id → city_name, state` |
| `customers` | `customer_id → full_name, phone, email, city_id, plus_valid_until, created_at` |
| `customers` | `phone → customer_id, full_name, email, city_id, plus_valid_until, created_at` |
| `service_categories` | `category_id → category_name` |
| `service_categories` | `category_name → category_id` |
| `services` | `service_id → category_id, service_name, duration_min, base_price, is_active` |
| `services` | `service_name → service_id, category_id, duration_min, base_price, is_active` |
| `professionals` | `pro_id → full_name, phone, city_id, gender, joined_on, rating, kyc_verified, status` |
| `pro_skills` | `(pro_id, category_id) → certified_on` |
| `pro_availability` | `(pro_id, work_date, start_time) → end_time` |
| `bookings` | `booking_id → all other booking attributes` |
| `reschedules` | `reschedule_id → all other reschedule attributes` |
| `reviews` | `booking_id → rating_for_pro, comment, rating_for_customer, created_at` |
| `payouts` | `payout_id → pro_id, week_start, jobs, gross_earnings, commission, net_payout, status, paid_at` |

These functional dependencies help identify candidate keys and determine how attributes should be distributed among relations.

## 6. Normalization

Normalization is the process of organizing database relations to reduce unnecessary data duplication and prevent insertion, deletion, and update anomalies.

The schema is analyzed using the following normal forms.

### 6.1 First Normal Form (1NF)

A relation satisfies 1NF when:

- Every attribute contains atomic values.
- Each cell contains a single value.
- There are no repeating groups or multivalued attributes stored in a single column.

In this database, professional skills are stored as separate records in the `pro_skills` table rather than storing multiple skills in a single column of the `professionals` table.

Similarly, professional availability slots are stored as individual records in `pro_availability`.

Therefore, the relations are designed to satisfy 1NF.

### 6.2 Second Normal Form (2NF)

A relation satisfies 2NF when:

- It is already in 1NF.
- Every non-prime attribute is fully functionally dependent on every candidate key.
- There are no partial dependencies on a proper subset of a candidate key.

For example, the `pro_skills` table has a composite primary key consisting of `pro_id` and `category_id`.

The attribute `certified_on` depends on the complete combination of both columns rather than depending on only one part of the key.

Similarly, `end_time` in `pro_availability` depends on the complete composite key consisting of `pro_id`, `work_date`, and `start_time`.

Thus, the composite-key relations avoid partial dependencies under the identified functional dependencies.

The remaining tables use single-column primary keys, so partial dependencies on a subset of those primary keys are not possible.

### 6.3 Third Normal Form (3NF)

A relation satisfies 3NF when:

- It is already in 2NF.
- For every non-trivial functional dependency X → A, either X is a superkey or A is a prime attribute.

In simpler terms, non-key attributes should not depend transitively on candidate keys through other non-key attributes.

For example, customer information is stored in the `customers` table using `city_id` rather than repeating `city_name` and `state` in every customer record.

The city details are maintained separately in the `cities` table.

The functional dependencies are:

`customer_id → city_id`

`city_id → city_name, state`

Separating city information avoids repeating the same city details across multiple customer records.

Similarly, service category information is maintained separately in `service_categories`, and individual services reference categories through `category_id`.

This reduces unnecessary duplication and helps prevent update anomalies.

### 6.4 Boyce-Codd Normal Form (BCNF)

BCNF is a stricter form of 3NF.

A relation satisfies BCNF if, for every non-trivial functional dependency X → Y, X must be a superkey.

A superkey is an attribute or combination of attributes that uniquely identifies a record.

During the schema analysis, the identified functional dependencies and candidate keys were examined to check for BCNF violations.

The declared primary keys, composite keys, and applicable UNIQUE constraints were considered while identifying candidate keys.

Based on the functional dependencies identified and the documented business assumptions, no BCNF violations were found that required further decomposition.

This conclusion is limited to the identified dependencies. Additional business rules may introduce further functional dependencies that require separate analysis.

## 7. Redundant and Derived Attributes

Some attributes can be derived or calculated from other information. However, they are retained in the schema for historical, operational, and reporting purposes.

| Attribute | Table | Reason for Retaining |
|---|---|---|
| `net_payout` | `payouts` | Can be calculated as gross earnings minus commission. It is retained as part of the weekly payout record and validated using a CHECK constraint. |
| `jobs` | `payouts` | Could be calculated by counting relevant bookings, but storing it preserves the weekly payout summary. |
| `scheduled_end` | `bookings` | Could be estimated using service duration, but storing it preserves the actual scheduled end time. |
| `price` | `bookings` | May originate from the service base price, but storing it preserves the price applicable when the booking was made. |

These attributes support historical accuracy and operational reporting.

The database also avoids storing city names and service category names repeatedly in customer, professional, and service records. Instead, foreign keys are used to reference their respective master tables.

## 8. Integrity Constraints

The database uses different types of integrity constraints to maintain valid and consistent records.

### 8.1 Primary Key Constraints

Primary keys ensure that every record is uniquely identifiable and that primary key values cannot be NULL.

Examples:
- `customer_id` in `customers`.
- `booking_id` in `bookings`.
- Composite key (`pro_id`, `category_id`) in `pro_skills`.

### 8.2 Foreign Key Constraints

Foreign keys maintain valid relationships between related tables.

Examples:
- `customers.city_id` references `cities.city_id`.
- `services.category_id` references `service_categories.category_id`.
- `bookings.customer_id` references `customers.customer_id`.
- `bookings.service_id` references `services.service_id`.
- `payouts.pro_id` references `professionals.pro_id`.

Foreign key integrity checks were performed on the loaded dataset. All checked relationships had zero invalid references.

### 8.3 UNIQUE Constraints

UNIQUE constraints prevent duplicate values in selected columns.

Examples:
- `customers.phone`
- `customers.email`
- `service_categories.category_name`
- `services.service_name`

### 8.4 NOT NULL Constraints

NOT NULL constraints ensure that mandatory attributes always contain values.

For example, customer names, phone numbers, booking dates, and service prices are mandatory in their respective tables.

### 8.5 CHECK Constraints

CHECK constraints enforce business rules at the database level.

Important rules include:

- Service duration must be greater than zero.
- Service base price cannot be negative.
- Professional ratings must be between 1 and 5 when provided.
- Booking scheduled end time must be later than scheduled start time.
- Booking actual completion time cannot be earlier than its start time when both are available.
- Booking discount cannot exceed booking price.
- Booking monetary amounts cannot be negative.
- Review ratings must be between 1 and 5.
- Professional availability end time must be later than start time.
- Payout commission cannot exceed gross earnings.
- Net payout must equal gross earnings minus commission, within a tolerance of 0.01.

A total of 26 CHECK constraints were verified in the PostgreSQL database.

Additional data validation queries were executed to verify booking schedules, monetary values, payout calculations, and other business rules.

## 9. Conclusion

The Urban Company Home Services database uses a structured relational design consisting of 11 interconnected tables.

The schema separates independent entities, establishes relationships through foreign keys, and uses appropriate primary keys and integrity constraints to maintain consistency.

Normalization principles from 1NF to 3NF were applied to reduce unnecessary duplication and prevent common data anomalies. BCNF was also analyzed using the identified functional dependencies and candidate keys.

The resulting database supports customer management, service management, professional skill mapping, availability management, booking operations, rescheduling, reviews, and professional payouts.