# Problem Understanding

## Project: Urban Company Home Services Database

### 1. Business Overview

Urban Company is a home services platform that connects customers with service professionals. Customers can book different services such as cleaning, repair, beauty, and other home-related services. Professionals provide these services, while the platform manages bookings, scheduling, payments, reviews, and payouts.

### 2. Problem Statement

The platform generates and maintains a large amount of data related to customers, professionals, services, bookings, availability, reschedules, reviews, and payments.

Managing this data through separate CSV files can make it difficult to maintain relationships between records, ensure data consistency, avoid duplication, and retrieve information efficiently.

Therefore, a properly structured relational database is required to organize this information and maintain data integrity through appropriate constraints and relationships.

### 3. Main Entities and Data

The database manages the following major entities:

- **Customers:** Customer details such as name, phone number, email, and city.
- **Professionals:** Details of service providers, including contact information, city, rating, KYC verification status, and professional status.
- **Services:** Available services, their categories, duration, base prices, and active status.
- **Bookings:** Booking details connecting customers, services, and professionals, along with scheduling and payment information.
- **Reschedules:** Records of booking schedule changes.
- **Reviews:** Ratings and feedback associated with bookings.
- **Payouts:** Weekly earnings, commission, and payout details of professionals.
- **Cities and Service Categories:** Supporting information used to organize customers, professionals, and services.

### 4. Main Database Requirements

The database should support the following business operations:

1. Finding available services and suitable professionals for a customer's booking.
2. Retrieving customer booking history and booking details.
3. Helping professionals view their assigned jobs and weekly earnings.
4. Identifying unassigned bookings for dispatch.
5. Analyzing cancellations, late starts, no-shows, customer ratings, and review feedback.
6. Generating financial reports related to booking prices, discounts, cancellation fees, payment methods, professional commissions, and payouts.
7. Supporting operational reports related to demand, rescheduling, customer retention, and professional utilization.

### 5. Project Objective

The objective is to design a relational database for the Urban Company home services platform using the provided CSV datasets. The database should have a well-defined schema, appropriate primary and foreign keys, meaningful constraints, and normalized tables.

The initial focus is on data correctness, consistency, and proper schema design. The database will later be evaluated and optimized for query performance as the project progresses.