# KoreBank Database System

A relational database for a commercial bank, built in Microsoft SQL Server. The schema models the core operations of a lending and financial intermediation business: customers and accounts, transactions, loan origination and booking, cards, and an audit trail.

The project covers the full path from design through to a working implementation with sample data and analytical queries.

## What the database covers

KoreBank is a commercial bank that operates within Nigeria financial ecosystem, whose business is lending and financial intermediation. The database supports:

- onboarding customers and capturing KYC, next of kin and account signatories
- opening and managing accounts and fixed deposits
- recording transactions across channels (mobile, ATM, internet banking, POS, branch) and payment rails (NIP, NEFT, RTGS, internal ledger)
- managing the loan lifecycle from application through to booking, with collateral
- issuing cards
- logging changes for audit

## Architecture

The database is organised into seven schemas, each owning one domain:

| Schema | Purpose | Tables |
|--------|---------|--------|
| Product | Account and loan product catalogue | AccountProduct, LoanType, LoanProduct |
| Org | Branches, locations and staff | Location, Branch, Employee |
| Core | Customers, accounts and deposits | Customer, NextOfKin, Account, AccountSignatory, FixedDeposit |
| TransOperation | Transactions and payment infrastructure | TransactionChannel, PaymentRail, Bank, Transaction, Beneficiary |
| Credit | Loan origination and security | loanPipeline, Loan, Collateral |
| Channel | Cards | Card |
| Audit | Change log | AuditLog |

21 tables in total.

## Design decisions

A few choices worth noting:
- **Country Finanacial ecosystem:** This Database was built base on the Nigeria Banking ecosystem and infrastructure, accounting for the information in `TransOperation.PaymentRail` table
- **Pipeline separated from booking:**: Loan applications live in `Credit.loanPipeline`; only approved applications should be booked into `Credit.Loan`. Holding the two apart makes it possible to detect loans booked without approval.
- **Separation of duties:** `CHECK` constraints enforce that the reviewer and approver of a loan differ (`ReviewedByID <> ApprovedByID`), and that the person who books a loan and the person who authorises it differ (`CreatedByID <> AuthorisedByID`).
- **Self referencing staff hierarchy:** `Org.Employee.SupervisorID` references the same table, modelling reporting lines.
- **Deferred foreign keys:** `Org.Branch.ManagerID` and `TransOperation.Transaction.BeneficiaryID` are added after their target tables exist, resolving the circular dependency between branches, employees and beneficiaries.
- **Domain integrity:** `CHECK` constraints restrict the permitted values for account types, KYC status, transaction types, card schemes and similar fields. Sensitive card data (CVV, PIN) is stored only as a hash placeholder, never in plain text.
- **Audit trail:** `Audit.AuditLog` records inserts, updates and deletes alongside the old and new values.

## Sample data

Every table is seeded with at least ten rows of representative data. The data includes two deliberate anomalies: loans booked from applications that were either rejected or still under review. These support the fraud and reconciliation queries below.

## Queries included

The script closes with analytical and integrity queries:

1. **Loan exposure by product.** Aggregate query using `GROUP BY`, `HAVING` and aliases to summarise bookings, total principal, average rate, and the largest and smallest loan per product.
2. **Branch balance summary.** Total deposits, average balance and active versus dormant account counts per branch.
3. **Wildcard searches.** `LIKE` queries for customers by name, staff by role and email domain, and transactions by description.
4. **Fraud check (inner joins).** Surfaces loans present in the booking table whose pipeline status is not 'Approved'.
5. **Reconciliation (full outer join).** Matches every application against every booking and flags ghost bookings, applications approved but not yet booked, and bookings made without approval.

## Running the script

Requirements: Microsoft SQL Server and a client such as SQL Server Management Studio or Azure Data Studio.

1. Open `korebank.sql`.
2. Execute the whole script. It creates the database, schemas, tables, constraints, sample data and queries in order.
3. The closing `SELECT` statements return the analytical results.

The script builds the `KoreBank` database from scratch, so drop any existing copy before rerunning.

## Repository structure
```
korebank-sql-database/
├── README.md
├── korebank.sql            full schema, sample data and queries
├── erd/
│   └── ERD KORE BANK-Page-2.drawio    entity relationship diagram
└── data-dictionary.md      documentation of every table and its fields
```
## Built with

Microsoft SQL Server, T-SQL
