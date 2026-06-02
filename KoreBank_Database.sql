
-- KORE BANK DATABASE
/* Bank Type: Commercial Bank 
Business: Lending & Financial Intermediation */
CREATE DATABASE KoreBank;
GO

USE KoreBank;
GO
-- 1. Bank Products schema- account product, loan type and loan products
CREATE SCHEMA Product
GO
CREATE TABLE Product.AccountProduct (
    AccountProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode CHAR(3) NOT NULL UNIQUE,
    accountName VARCHAR(100) NOT NULL UNIQUE,
    AccountType VARCHAR(100) NOT NULL CHECK (AccountType IN ('Savings','Current','Domiciliary','FixedDeposit')),
    DateCreated DATETIME NOT NULL DEFAULT GETDATE(),
    IsActive BIT NOT NULL DEFAULT 1,
    EffectiveTo DATE NULL 
);
GO

CREATE TABLE Product.LoanType (
    LoanTypeID INT IDENTITY (1,1) PRIMARY KEY,
    LoanTypeName VARCHAR(100) UNIQUE-- --eg Personal, Mortgage, SME, Agricultural, Auto, Overdraft, syndicate loan and others
);
GO
CREATE TABLE Product.LoanProduct(
    LoanProductID INT IDENTITY(1,1) PRIMARY KEY,
    LoanCode CHAR(3) NOT NULL UNIQUE,
    LoanName VARCHAR(100) NOT NULL,
    LoanTypeID INT NOT NULL, 
    DateCreated DATETIME NOT NULL DEFAULT GETDATE(),
    IsActive BIT NOT NULL DEFAULT 1,
    EffectiveTo DATE NULL 
    CONSTRAINT LoanProduct_Type FOREIGN KEY (LoanTypeID)
        REFERENCES Product.LoanType(LoanTypeID)
);
GO

-- 2. Organisation schema: braches, location and employees
CREATE SCHEMA Org
GO

CREATE TABLE Org.Location (--- branches location
    LocationID INT IDENTITY(1,1) PRIMARY KEY,
    Address VARCHAR (250) NOT NULL,
    City VARCHAR(100),
    State VARCHAR(100)
);
GO
CREATE TABLE Org.Branch (
    BranchID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    BranchName VARCHAR(100) UNIQUE NOT NULL,
    LocationID INT NOT NULL,
    PhoneNumber VARCHAR(11) UNIQUE NOT NULL,
    ManagerID  INT NULL,                 -- FK added after Employee
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT Branch_Location FOREIGN KEY (LocationID)
        REFERENCES org.Location (LocationID) 
);
GO
CREATE TABLE Org.Employee (
    EmployeeID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName  VARCHAR(100) NOT NULL,
    Email     VARCHAR(150) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(20) NULL,
    DateOfBirth DATE NOT NULL,
    Role VARCHAR(50)  NOT NULL,   -- e.g. 'Teller','Account officer','Relationship Manager'
    Level VARCHAR (100) NOT NULL,--eg banking office, Asistance banking Officer
    Salary DECIMAL(15,2)  NOT NULL,
    BranchID  INT NOT NULL,
    SupervisorID INT  NULL,   -- self-ref
    HireDate  DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Employee_Branch  FOREIGN KEY (BranchID)
        REFERENCES org.Branch (BranchID),
    CONSTRAINT FK_Employee_Supervisor FOREIGN KEY (SupervisorID)-- Self referecing
        REFERENCES org.Employee (EmployeeID)
);
GO 

-- Back-fill Branch.ManagerID FK now that Employee exists
ALTER TABLE Org.Branch
    ADD CONSTRAINT FK_Branch_Manager
        FOREIGN KEY (ManagerID) REFERENCES Org.Employee (EmployeeID);
GO

-- 3. core banking operations- Customer information, Next of kin information, account infornmation etc
CREATE SCHEMA Core
GO

CREATE TABLE Core.Customer (
    CustomerID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    IDType VARCHAR(100) NOT NULL CHECK (IDType IN ('Driving Liscence', 'NIN', 'International Passport', 'Voters Card', 'CAC documents')),
    IDNumber VARCHAR(20) NOT NULL UNIQUE,
    TIN VARCHAR(10) NULL UNIQUE,--Tax Identivication Number
    BVN VARCHAR(11) NOT NULL UNIQUE,-- Bank Verification Number
    DateOfBirth DATE NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(11) NOT NULL,
    Address VARCHAR(255) NOT NULL,
    City VARCHAR(100)   NOT NULL,
    State VARCHAR(100) NOT NULL,
    Occupation VARCHAR(200) NOT NULL,
    CustomerType VARCHAR(20) NOT NULL CHECK (CustomerType IN ('Individual','SME', 'Corporate')),
    KYCStatus VARCHAR(20) NOT NULL CHECK (KYCStatus IN ( 'Pending', 'Verified', 'Rejected','Suspended')),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE Core.NextOfKin (   --Customer's Next of Kin Information
    NextOfKinID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL UNIQUE,
    FirstName VARCHAR(200) NOT NULL,
    LastName VARCHAR(200) NOT NULL,
    Relationship VARCHAR(50) NOT NULL,
    Email VARCHAR(150) NULL,
    PhoneNumber VARCHAR(20) NOT NULL,
    CONSTRAINT FK_NextOfKin_Customer FOREIGN KEY (CustomerID)
        REFERENCES Core.Customer(CustomerID)
);
GO

CREATE TABLE Core.Account (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    AccountNumber VARCHAR(10) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    AccountOfficerID INT NOT NULL, 
    ProductID INT NOT NULL,
    Balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    Currency CHAR(3) NOT NULL DEFAULT 'NGN',
    Status  VARCHAR(10) NOT NULL CHECK (Status IN ('Active','Dormant','Frozen','Closed')),
    ProfitCenter INT NOT NULL,
    OpenedAt DATETIME NOT NULL DEFAULT GETDATE(),
    ClosedAt DATETIME NULL,
    CONSTRAINT FK_Account_Customer FOREIGN KEY (CustomerID)
        REFERENCES Core.Customer (CustomerID),
    CONSTRAINT FK_Account_Employee FOREIGN KEY (AccountOfficerID)
        REFERENCES org.Employee (EmployeeID),
    CONSTRAINT FK_Account_Branch FOREIGN KEY (ProfitCenter)
        REFERENCES org.Branch (BranchID),
    CONSTRAINT FK_Account_Product FOREIGN KEY (ProductID)
        REFERENCES Product.accountProduct (AccountProductID)
    ); 
GO

CREATE TABLE Core.AccountSignatory(
    SignatoryID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    AccountNumber VARCHAR(10)  NOT NULL,
    SignatoryName VARCHAR(200) NOT NULL,
    IDType VARCHAR(100) NOT NULL CHECK (IDType IN ('Driving Liscence', 'NIN', 'International Passport', 'Voters Card')),
    IDNumber VARCHAR(20) NOT NULL,
    BVN VARCHAR(11) NOT NULL,-- Bank Verification Number
    DateOfBirth DATE NOT NULL,
    Email VARCHAR(150) NOT NULL,
    PhoneNumber VARCHAR(11) NOT NULL,
    Address VARCHAR(255) NOT NULL,
    City VARCHAR(100)   NOT NULL,
    State VARCHAR(100) NOT NULL,
    Occupation VARCHAR(200) NOT NULL,
    IsVerified BIT NOT NULL DEFAULT 0,
    AddedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT Signatory_Account FOREIGN KEY (AccountNumber)
        REFERENCES Core.Account (AccountNumber) 
);
GO
CREATE TABLE Core.FixedDeposit (
    FixedDepositID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    DepositAmount DECIMAL(18,2) NOT NULL CHECK (DepositAmount > 0),
    InterestRate DECIMAL(6,4) NOT NULL,   -- annual rate
    TenorDays INT NOT NULL,
    StartDate DATETIME NOT NULL,
    MaturityDate DATE NOT NULL,
    MaturityAmount DECIMAL(18,2) NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active','Matured','Broken','Rolled-Over')) DEFAULT 'Active',
    AutoRollover BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_FD_Account FOREIGN KEY (AccountID)
        REFERENCES Core.Account (AccountID),
    CONSTRAINT Start_Maturity CHECK (MaturityDate > CAST(StartDate AS DATE))
);
GO

-- 4. Transaction operations- Transactions, payment channel, payment rail etc

CREATE SCHEMA TransOperation
CREATE TABLE TransOperation.TransactionChannel (
    ChannelCode VARCHAR(10) PRIMARY KEY,
    ChannelName VARCHAR(50) NOT NULL UNIQUE -- like mobile app, ATM, Internet banking, POS etc
);
GO
CREATE TABLE TransOperation.PaymentRail (
    RailCode VARCHAR(10) PRIMARY KEY, 
    RailName VARCHAR(50) NOT NULL UNIQUE---like NIP,NEFT, RTGS, internal ledger transfer
);
GO

CREATE TABLE TransOperation.Bank (
    BankCode CHAR(3) PRIMARY KEY,
    BankName VARCHAR(100) NOT NULL UNIQUE
);
GO

CREATE TABLE TransOperation.[Transaction] (
    TransactionID BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    TransactionRef VARCHAR(18) NOT NULL UNIQUE,
    AccountNumber VARCHAR(10) NOT NULL,
    DRCR VARCHAR(10) NOT NULL CHECK (DRCR IN ('DR', 'CR')), -- debit or credit transactions
    TransactionType VARCHAR(30) NOT NULL CHECK (TransactionType IN ('lodgement','Withdrawal','Transfer','LoanDisbursement',
        'LoanRepayment','FeeCharge','InterestCredit','Reversal')),
    Amount DECIMAL(18,2) NOT NULL,
    Currency CHAR(3) NOT NULL DEFAULT 'NGN',
    ExchangeRate DECIMAL(10,6) NULL DEFAULT 1.00,
    Description VARCHAR(255) NULL,
    InstrumentID VARCHAR(18) NULL,-- for cheques and other payment instructions
    ChannelCode VARCHAR(10) NOT NULL,
    RailCode VARCHAR(10) NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Pending','Completed','Failed','Reversed')),
    RunningBalance DECIMAL(18,2) NOT NULL,
    ProcessedByID INT NULL,
    AuthorisedByID INT NULL,
    TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
    ValueDate  DATE NOT NULL DEFAULT CAST (GETDATE() AS DATE),
    BeneficiaryID INT NULL,
    CONSTRAINT FK_Transaction_Account FOREIGN KEY (AccountNumber)
        REFERENCES Core.Account (AccountNumber),
    CONSTRAINT FK_Transaction_ProcessedBy FOREIGN KEY (ProcessedByID)
        REFERENCES Org.Employee (EmployeeID),
    CONSTRAINT FK_Transaction_AuthorisedBy FOREIGN KEY (AuthorisedByID)
        REFERENCES Org.Employee (EmployeeID),
    CONSTRAINT FK_Transaction_TransactionChannel FOREIGN KEY (ChannelCode)
        REFERENCES TransOperation.TransactionChannel (ChannelCode),
    CONSTRAINT FK_Transaction_PaymentRail FOREIGN KEY (RailCode)
        REFERENCES TransOperation.PaymentRail (RailCode)
);
GO
CREATE TABLE TransOperation.Beneficiary (
    BeneficiaryID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    BeneficiaryName VARCHAR(200) NOT NULL,
    AccountNumber VARCHAR(20) NOT NULL,
    BankCode CHAR(3) NOT NULL,   -- CBN bank code
    IsVerified BIT NOT NULL DEFAULT 0,
    AddedAt DATETIME NOT NULL DEFAULT GETDATE(), 
    CONSTRAINT FK_Beneficiary_Bank FOREIGN KEY (BankCode)
        REFERENCES TransOperation.Bank (BankCode)
);
GO
ALTER TABLE TransOperation.[Transaction]
    ADD CONSTRAINT FK_Trans_Ben
        FOREIGN KEY (BeneficiaryID) REFERENCES TransOperation.Beneficiary (BeneficiaryID);

-- 5. Credit: loan pipeline, loans and colateral information
CREATE SCHEMA Credit 
GO
CREATE TABLE Credit.loanPipeline(
    LoanID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    LoanProductID INT NOT NULL,
    StartDate DATETIME NOT NULL,
    PrincipalAmount DECIMAL(18,2) NOT NULL CHECK (PrincipalAmount > 0),
    TenorMonth INT NOT NULL, -- In Months
    InterestRate DECIMAL(6,4) NOT NULL CHECK (InterestRate > 0 AND InterestRate < 1),   -- annual rate e.g. 0.1800 = 18%,
    Moratorium INT DEFAULT 0,
    RepaymentSchedule VARCHAR(200) NOT NULL DEFAULT 'Monthly', -- eg Monthly, BulletPayment
    Status VARCHAR(15) NOT NULL, -- eg Approved, rejected, under review,
    ReviewedByID  INT  NOT NULL,
    ApprovedByID  INT  NOT NULL,
    ApprovedDate DATETIME NOT NULL
    CONSTRAINT FK_Loan_Customer FOREIGN KEY (CustomerID)
        REFERENCES Core.Customer (CustomerID),
    CONSTRAINT FK_Loan_loanProduct FOREIGN KEY (LoanProductID)
        REFERENCES Product.loanProduct (LoanProductID),
    CONSTRAINT FK_Loan_ReviewedBy  FOREIGN KEY (ReviewedByID)
        REFERENCES Org.Employee (EmployeeID),
    CONSTRAINT FK_Loan_ApprovedBy FOREIGN KEY (ApprovedByID)
        REFERENCES Org.Employee (EmployeeID),
    CONSTRAINT review_approve CHECK (ReviewedByID <> ApprovedByID)
);

CREATE TABLE Credit.Loan (
    BookingID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    LoanID INT NOT NULL UNIQUE,
    AccountNumber VARCHAR(10) NOT NULL,   -- disbursement / repayment account
    PrincipalAmountApproved DECIMAL(18,2) NOT NULL CHECK (PrincipalAmountApproved > 0),
    TenorMonthApproved INT NOT NULL, -- In Months
    InterestRateApproved DECIMAL(6,4) NOT NULL CHECK (InterestRateApproved > 0 AND InterestRateApproved < 1),   -- annual rate e.g. 0.1800 = 18%,
    MoratoriumApproved INT DEFAULT 0,
    RepaymentScheduleApproved VARCHAR(200) NOT NULL DEFAULT 'Monthly', -- eg Monthly, BulletPayment
    Status  VARCHAR(15) NOT NULL CHECK (Status IN ('Active','Paid','Defaulted','Written-Off')),
    DisbursementDate  DATE NOT NULL DEFAULT GETDATE(),
    MaturityDate DATE NOT NULL,
    CreatedByID  INT  NOT NULL,
    AuthorisedByID  INT  NOT NULL,
    CONSTRAINT FK_Loan_LoanPipeline FOREIGN KEY (loanID)
        REFERENCES credit.loanPipeline (LoanID),
    CONSTRAINT FK_Loan_Account FOREIGN KEY (AccountNumber)
        REFERENCES Core.Account (AccountNumber),
    CONSTRAINT FK_Loan_CreatedBy FOREIGN KEY (CreatedByID)
        REFERENCES Org.Employee (EmployeeID),
    CONSTRAINT FK_Loan_AuthorisedBy FOREIGN KEY (AuthorisedByID)
        REFERENCES Org.Employee (EmployeeID),  
    CONSTRAINT created_auth CHECK (CreatedByID <> AuthorisedByID)
);
GO

CREATE TABLE Credit.Collateral (
    CollateralID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    BookingID INT NOT NULL,
    CollateralType VARCHAR(30) NOT NULL, -- Mortgage, Vehicle, Equipment, StockShares,PersonalGuarantee, FixedDeposit etc
    Description VARCHAR(500) NOT NULL,
    IsPerfected BIT NOT NULL,
    PerfectionDate DATE NULL,
    BookValue DECIMAL(18,2) NOT NULL CHECK (BookValue > 0),
    ForceSaleValue DECIMAL(18,2) NOT NULL CHECK (ForceSaleValue > 0),
    ValuationDate DATE NOT NULL,
    Valuer VARCHAR(250) NOT NULL,
    IsReleased BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Collateral_Loan  FOREIGN KEY (BookingID)
        REFERENCES Credit.Loan (BookingID) 
);
GO


-- 6. Channel Schema: CARD

CREATE SCHEMA Channel
GO
CREATE TABLE channel.Card (
    CardID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    CardNumber VARCHAR(64) NOT NULL UNIQUE,   -- store masked / tokenised
    CardType VARCHAR(10) NOT NULL CHECK (CardType   IN ('Debit','Credit','Prepaid')),
    CardScheme VARCHAR(15) NOT NULL CHECK (CardScheme IN ('Visa','Mastercard','Verve')) DEFAULT 'Verve',
    IssuedAt DATETIME NOT NULL DEFAULT GETDATE(),
    ExpiryDate DATE NOT NULL,
    CVVHash VARCHAR(64)  NULL,   -- hashed, never plain text
    PINHash VARCHAR(64) NULL,  -- hashed, never plain text
    DailyLimit DECIMAL(15,2) NOT NULL DEFAULT 100000.00 CHECK (DailyLimit > 0),
    Status VARCHAR(10) NOT NULL CHECK (Status IN ('Active','Blocked','Expired','Lost')) DEFAULT 'Active',
    CONSTRAINT SR_Card_ExpiryAfterIssued CHECK (ExpiryDate > CAST(IssuedAt AS DATE)),
    CONSTRAINT FK_Card_Account      FOREIGN KEY (AccountID)
        REFERENCES Core.Account (AccountID)
);
GO

--7. Audit Schema- Contains Audit Log
CREATE SCHEMA Audit
GO
CREATE TABLE Audit.AuditLog (
    LogID BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NULL,
    TableName VARCHAR(100) NOT NULL,
    RecordID  VARCHAR(50) NOT NULL,
    ActionType VARCHAR(10) NOT NULL CHECK (ActionType IN ('INSERT','UPDATE','DELETE')),
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    IPAddress VARCHAR(45) NULL,
    ActionDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_AuditLog_Employee FOREIGN KEY (EmployeeID)
        REFERENCES Org.Employee (EmployeeID)
);
GO

-- Product.AccountProduct
INSERT INTO Product.AccountProduct (ProductCode, accountName, AccountType, IsActive)
VALUES
    ('SAV', 'Standard Savings Account','Savings',1),
    ('SCA', 'SME Current Account', 'Current', 1),
    ('PCA', 'Personal Current Account', 'Current', 1),
    ('DOM', 'Business Domiciliary Account','Domiciliary', 1),
    ('FXD', 'Fixed Deposit Classic', 'FixedDeposit', 1),
    ('STU', 'Student Savings Account','Savings', 1);
GO

-- Product.LoanType
INSERT INTO Product.LoanType (LoanTypeName)
VALUES
    ('Personal'),
    ('Mortgage'),
    ('SME'),
    ('Agricultural'),
    ('Auto'),
    ('Overdraft'),
    ('Syndicate');
GO

-- Product.LoanProduct
INSERT INTO Product.LoanProduct (LoanCode, LoanName, LoanTypeID, IsActive)
VALUES
    ('PL1', 'Quick Personal Loan', 1, 1),
    ('MG1', 'Home Mortgage Plan', 2, 1),
    ('SM1', 'SME Growth Facility',3, 1),
    ('AG1', 'Agric Booster Loan',4, 1),
    ('AU1', 'Auto Finance Loan', 5, 1),
    ('OD1', 'Salary Advance',6, 1);
GO

-- Org.Location
INSERT INTO Org.Location (Address, City, State)
VALUES
    ('12 Marina Street','Lagos Island','Lagos'),
    ('5 Adetokunbo Ademola', 'Victoria Island','Lagos'),
    ('Plot 22 Wuse Zone 4', 'Abuja', 'FCT'),
    ('44 Ahmadu Bello Way','Kaduna','Kaduna'),
    ('10 Ogui Road','Enugu','Enugu');
GO

-- Org.Branch  (ManagerID filled after Employee inserts)
INSERT INTO Org.Branch (BranchName, LocationID, PhoneNumber, IsActive)
VALUES
    ('Marina Main Branch', 1, '07011111111', 1),
    ('VI Business Branch', 2,'07022222222', 1),
    ('Abuja Central Branch',3,'07033333333', 1),
    ('Kaduna Branch',4,    '07044444444', 1),
    ('Enugu Branch',5, '07055555555', 1);
GO

-- Org.Employee  (SupervisorID NULL for top-level staff)
INSERT INTO Org.Employee (FirstName, LastName, Email, PhoneNumber, DateOfBirth, Role, Level, Salary, BranchID, SupervisorID, HireDate, IsActive)
VALUES
    ('Chidi', 'Okafor', 'chidi.okafor@korebank.com','08011111111', '1997-10-10','Branch Manager', 'Senior Manager',  750000.00, 1, NULL, '2015-03-01', 1),
    ('Ngozi', 'Eze', 'ngozi.eze@korebank.com', '08022222222','1897-12-10', 'Chief Credit Analyst', 'Senior Manager', 720000.00, 2, NULL, '2016-06-15', 1),
    ('Emeka', 'Nwosu', 'emeka.nwosu@korebank.com', '08033333333','1996-01-10', 'Branch Manager','Assistant Manager', 520000.00, 1, 1, '2018-01-10', 1),
    ('Fatima', 'Bello', 'fatima.bello@korebank.com', '08044444444', '2000-12-10','Account Officer', 'Banking Officer', 320000.00, 1, 3, '2019-05-20', 1),
    ('Tunde', 'Adeyemi', 'tunde.adeyemi@korebank.com',  '08055555555', '2000-12-10','Teller', 'Excecutive Trainee', 240000.00, 1, 3,   '2020-02-14', 1),
    ('Aisha', 'Musa', 'aisha.musa@korebank.com', '08066666666', '2000-02-15', 'Credit Analyst', 'Banking Officer', 310000.00, 2, 2, '2019-09-01', 1),
    ('Segun', 'Lawal', 'segun.lawal@korebank.com','08077777777', '2000-12-10','Credit Analyst', 'Senior Banking Officer', 480000.00, 3, NULL, '2017-11-05', 1),
    ('Yetunde', 'Akande', 'yetunde.akande@korebank.com', '08088888888','2002-12-10', 'Teller', 'Assistant Banking Officer', 230000.00, 2, 2, '2021-04-30', 1),
    ('Musa', 'Ibrahim', 'musa.ibrahim@korebank.com', '08099999999', '1996-08-10','Relationship Manager', 'Manager', 600000.00, 3, NULL,  '2016-08-22', 1),
    ('Kemi','Ogundimu', 'kemi.ogundimu@korebank.com', '08010101010','2000-12-10', 'Account Officer', 'Banking Officer', 300000.00, 4, NULL, '2022-01-03', 1);
GO

-- Back-fill Branch Managers
UPDATE Org.Branch SET ManagerID = 1 WHERE BranchID = 1;
UPDATE Org.Branch SET ManagerID = 2 WHERE BranchID = 2 ;
UPDATE Org.Branch SET ManagerID = 9 WHERE BranchID = 3;
GO

-- Core.Customer
INSERT INTO Core.Customer (FirstName, LastName, IDType, IDNumber, TIN, BVN, DateOfBirth, Email, PhoneNumber, Address, City, State, Occupation, CustomerType, KYCStatus)
VALUES
    ('Adebayo','Olatunde', 'NIN', 'NIN10000001', '1234567890', '12345678901', '1985-07-12', 'adebayo.olatunde@email.com', '08111111111', '15 Bode Thomas, Surulere', 'Lagos', 'Lagos', 'Engineer', 'Individual', 'Verified'),
    ('Chioma', 'Nwachukwu', 'International Passport','PA00000002',  '2345678901', '23456789012', '1990-02-28', 'chioma.nwachukwu@email.com',  '08122222222', '7 GRA Phase 2', 'Port Harcourt','Rivers','Accountant', 'Individual', 'Verified'),
    ('Garba', 'Usman', 'Voters Card', 'VC00000003',  '3456789012', '34567890123', '1978-11-03', 'garba.usman@email.com', '08133333333', '22 Murtala Mohammed Way', 'Kaduna', 'Kaduna', 'Trader','Individual', 'Verified'),
    ('Blessing','Obi', 'Driving Liscence', 'DL00000004',  '4567890123', '45678901234', '1995-04-19', 'blessing.obi@email.com', '08144444444', '3 Trans-Amadi Road', 'Port Harcourt','Rivers','Nurse', 'Individual', 'Verified'),
    ('Kunle', 'Adesanya', 'NIN', 'NIN10000005', '5678901234', '56789012345', '1982-09-07', 'kunle.adesanya@email.com', '08155555555', '90 Allen Avenue', 'Ikeja', 'Lagos',  'Business Owner', 'SME','Verified'),
    ('Zainab', 'Abdullahi', 'International Passport','PA00000006',  '6789012345', '67890123456', '1993-06-25', 'zainab.abdullahi@email.com', '08166666666', '11 Sokoto Road', 'Abuja', 'FCT','Civil Servant', 'Individual', 'Verified'),
    ('Ifeanyi', 'Chukwu', 'NIN', 'NIN10000007', '7890123456', '78901234567', '1975-01-30', 'ifeanyi.chukwu@email.com', '08177777777', '5 Enugu-Onitsha Road', 'Enugu',  'Enugu',  'Farmer', 'Individual', 'Verified'),
    ('Amina', 'Sule', 'Voters Card', 'VC00000008',  '8901234567', '89012345678', '1988-12-14', 'amina.sule@email.com', '08188888888', '18 Adeola Odeku Street', 'Lagos', 'Lagos', 'Lawyer', 'Individual', 'Verified'),
    ('Taiwo', 'Fashola', 'Driving Liscence', 'DL00000009',  '9012345678', '90123456789', '1970-08-08', 'taiwo.fashola@email.com', '08199999999', '32 Broad Street','Lagos','Lagos','Doctor', 'Individual', 'Verified'),
    ('Ngozi', 'Okonkwo', 'NIN', 'NIN10000010', '0123456789', '01234567890', '1999-03-22', 'ngozi.okonkwo@email.com', '08100001111', '9 Independence Layout', 'Enugu',  'Enugu', 'Student', 'Individual', 'Pending');

GO
INSERT INTO Core.NextOfKin(CustomerID, FirstName, LastName, Relationship, Email, PhoneNumber)
VALUES
    (1, 'Chinedu', 'Okafor', 'Brother', 'chinedu.okafor@gmail.com', '+2348012345678'),
    (2, 'Aisha', 'Abubakar', 'Sister', 'aisha.abubakar@yahoo.com', '+2348023456789'),
    (3, 'Oluwaseun', 'Adeyemi', 'Mother', 'seun.adeyemi@gmail.com', '+2348034567890'),
    (4, 'Emeka', 'Nwankwo', 'Father', 'emeka.nwankwo@yahoo.com', '+2348045678901'),
    (5, 'Fatima', 'Sule', 'Aunt', 'fatima.sule@gmail.com', '+2348056789012'),
    (6, 'Tunde', 'Balogun', 'Uncle', 'tunde.balogun@yahoo.com', '+2348067890123'),
    (7, 'Ngozi', 'Eze', 'Sister', 'ngozi.eze@gmail.com', '+2348078901234'),
    (8, 'Yusuf', 'Lawal', 'Brother', 'yusuf.lawal@yahoo.com', '+2348089012345'),
    (9, 'Blessing', 'Ojo', 'Cousin', 'blessing.ojo@gmail.com', '+2348090123456'),
    (10, 'Ibrahim', 'Mohammed', 'Guardian', 'ibrahim.mohammed@yahoo.com', '+2348101234567');
GO

-- Core.Account
INSERT INTO Core.Account (AccountNumber, CustomerID, AccountOfficerID, ProductID, Balance, Currency, Status, ProfitCenter)
VALUES
    ('1000000001', 1, 4, 1, 500000.00,'NGN', 'Active', 1),
    ('1000000002', 2, 6, 2, 1200000.00, 'NGN', 'Active', 2),
    ('1000000003', 3, 4, 1, 75000.00, 'NGN', 'Active', 1),
    ('1000000004', 4, 6, 1, 250000.00, 'NGN', 'Active', 2),
    ('1000000005', 5, 3, 2, 3500000.00, 'NGN', 'Active', 1),
    ('1000000006', 6, 9, 1, 180000.00, 'NGN', 'Active', 3),
    ('1000000007', 7, 4, 1, 45000.00, 'NGN', 'Dormant', 1),
    ('1000000008', 8, 3, 4, 2000000.00, 'NGN', 'Active', 1),
    ('1000000009', 9, 6, 2, 9800000.00, 'NGN', 'Active', 2),
    ('1000000010', 10,4, 1, 12000.00, 'NGN', 'Active', 1);
GO

INSERT INTO Core.AccountSignatory
(AccountNumber, SignatoryName, IDType, IDNumber, BVN, DateOfBirth, Email, PhoneNumber, Address, City, State, Occupation, IsVerified)
VALUES
('1000000001','Adebayo Olatunde','NIN','NIN10000001','12345678901','1985-07-12','adebayo.olatunde@email.com','08111111111','15 Bode Thomas','Lagos','Lagos','Engineer',1),
('1000000002','Chioma Nwachukwu','International Passport','PA00000002','23456789012','1990-02-28','chioma.nwachukwu@email.com','08122222222','GRA Phase 2','Port Harcourt','Rivers','Accountant',1),
('1000000003','Garba Usman','Voters Card','VC00000003','34567890123','1978-11-03','garba.usman@email.com','08133333333','Murtala Way','Kaduna','Kaduna','Trader',1),
('1000000004','Blessing Obi','Driving Liscence','DL00000004','45678901234','1995-04-19','blessing.obi@email.com','08144444444','Trans Amadi','Port Harcourt','Rivers','Nurse',1),
('1000000005','Kunle Adesanya','NIN','NIN10000005','56789012345','1982-09-07','kunle.adesanya@email.com','08155555555','Allen Avenue','Lagos','Lagos','Business Owner',1),
('1000000006','Zainab Abdullahi','International Passport','PA00000006','67890123456','1993-06-25','zainab.abdullahi@email.com','08166666666','Sokoto Road','Abuja','FCT','Civil Servant',1),
('1000000007','Ifeanyi Chukwu','NIN','NIN10000007','78901234567','1975-01-30','ifeanyi.chukwu@email.com','08177777777','Onitsha Road','Enugu','Enugu','Farmer',1),
('1000000008','Amina Sule','Voters Card','VC00000008','89012345678','1988-12-14','amina.sule@email.com','08188888888','Adeola Odeku','Lagos','Lagos','Lawyer',1),
('1000000009','Taiwo Fashola','Driving Liscence','DL00000009','90123456789','1970-08-08','taiwo.fashola@email.com','08199999999','Broad Street','Lagos','Lagos','Doctor',1),
('1000000010','Ngozi Okonkwo','NIN','NIN10000010','01234567890','1999-03-22','ngozi.okonkwo@email.com','08100001111','Independence Layout','Enugu','Enugu','Student',1);
GO

INSERT INTO Core.FixedDeposit
(AccountID, DepositAmount, InterestRate,TenorDays, StartDate, MaturityDate, MaturityAmount, Status, AutoRollover)
VALUES
(1,500000,0.12,365,'2024-01-01','2025-01-01', 560000,'Active',0),
(2,1000000,0.10,300,'2024-01-15','2025-01-15',1100000,'Active',1),
(3,200000,0.11,730,'2024-02-01','2025-02-01', 222000,'Active',0),
(4,300000,0.10,180, '2024-02-10','2025-02-10',330000,'Active',0),
(5,2000000,0.09,90, '2024-03-01', '2025-03-01',2180000,'Active',1),
(6,400000,0.12,180, '2024-03-15','2025-03-15', 448000,'Active',0),
(7,150000,0.11,365, '2024-04-01','2025-04-01', 166500,'Active',0),
(8,1800000,0.10,270, '2024-04-10','2025-04-10',1980000,'Active',1),
(9,2500000,0.095,210,'2024-05-01','2025-05-01', 2737500,'Active',0),
(10,100000,0.12,90,'2024-05-15','2025-05-15', 112000,'Active',0);
GO

-- TransOperation.TransactionChannel
INSERT INTO TransOperation.TransactionChannel (ChannelCode, ChannelName)
VALUES
    ('MOB', 'Mobile App'),
    ('ATM', 'ATM'),
    ('IB', 'Internet Banking'),
    ('POS', 'POS Terminal'),
    ('BRCH','Branch Counter');
GO

-- TransOperation.PaymentRail
INSERT INTO TransOperation.PaymentRail (RailCode, RailName)
VALUES
    ('NIP', 'NIP Instant Payment'),
    ('NEFT', 'NEFT'),
    ('RTGS', 'RTGS'),
    ('INTL', 'Internal Ledger Transfer');
GO

-- TransOperation.Bank
INSERT INTO TransOperation.Bank (BankCode, BankName)
VALUES
    ('058', 'GTBank'),
    ('044', 'Access Bank'),
    ('011', 'First Bank'),
    ('033', 'UBA'),
    ('232', 'Sterling Bank');
GO

-- TransOperation.Transaction  (10 records)
INSERT INTO TransOperation.[Transaction]
    (TransactionRef, AccountNumber, DRCR, TransactionType, Amount, Currency, Description, ChannelCode, RailCode, Status, RunningBalance, ProcessedByID, AuthorisedByID, TransactionDate, ValueDate)
VALUES
    ('TXN20240101001', '1000000001', 'CR', 'lodgement', 200000.00, 'NGN', 'Cash deposit','BRCH', 'INTL', 'Completed', 500000.00, 5, 3, '2024-01-05', '2024-01-05'),
    ('TXN20240101002', '1000000001', 'DR', 'Transfer', 50000.00, 'NGN', 'Rent payment', 'MOB',  'NIP', 'Completed', 450000.00, 5, 3,  '2024-01-10', '2024-01-10'),
    ('TXN20240101003', '1000000002', 'CR', 'lodgement', 500000.00, 'NGN', 'Business proceeds', 'BRCH', 'INTL', 'Completed', 1200000.00, 8, 2,  '2024-01-12', '2024-01-12'),
    ('TXN20240101004', '1000000003', 'DR', 'Withdrawal', 20000.00, 'NGN', 'ATM withdrawal', 'ATM', 'INTL', 'Completed', 75000.00, 5, 3, '2024-01-15', '2024-01-15'),
    ('TXN20240101005', '1000000005', 'CR', 'LoanDisbursement',1000000.00,'NGN', 'SME loan disbursement', 'BRCH', 'INTL', 'Completed', 3500000.00, 3, 1, '2024-02-01', '2024-02-01'),
    ('TXN20240101006', '1000000005', 'DR', 'LoanRepayment', 100000.00, 'NGN', 'Monthly loan repayment', 'MOB',  'NIP',  'Completed', 3400000.00,  3,  1, '2024-03-01', '2024-03-01'),
    ('TXN20240101007', '1000000008', 'DR', 'FeeCharge', 2500.00, 'NGN', 'Account maintenance fee', 'BRCH', 'INTL', 'Completed', 2000000.00, 5, 2, '2024-01-31', '2024-01-31'),
    ('TXN20240101008', '1000000009', 'CR', 'InterestCredit', 45000.00, 'NGN', 'Monthly interest credit', 'BRCH', 'INTL', 'Completed', 9800000.00, 8, 2, '2024-01-31', '2024-01-31'),
    ('TXN20240101009', '1000000006', 'DR', 'Transfer', 30000.00, 'NGN', 'Utility bill payment', 'IB',   'NIP',  'Completed', 180000.00, 9, 7, '2024-02-10','2024-02-10'),
    ('TXN20240101010', '1000000010', 'CR', 'lodgement', 10000.00, 'NGN', 'School fees deposit', 'BRCH', 'INTL', 'Completed', 12000.00, 5, 3, '2024-02-15','2024-02-15');
GO

INSERT INTO TransOperation.Beneficiary
(BeneficiaryName, AccountNumber, BankCode, IsVerified)
VALUES
('John Okeke', '2000000001', '058', 1),
('Mary Bello', ' 2000000002','044', 1);
GO

UPDATE TransOperation.[Transaction] SET BeneficiaryID = 2 WHERE TransactionID = 2;
UPDATE TransOperation.[Transaction] SET BeneficiaryID = 9 WHERE TransactionID = 9;
GO

-- Credit.LoanPipeline  (12 records – including some NOT approved, for fraud query)
INSERT INTO Credit.loanPipeline
    (CustomerID, LoanProductID, StartDate, PrincipalAmount, TenorMonth, InterestRate, Moratorium, RepaymentSchedule, Status, ReviewedByID, ApprovedByID, ApprovedDate)
VALUES
    (1, 1, '2024-01-15', 500000.00, 12, 0.180, 0,'Monthly', 'Approved', 7, 9, '2024-01-20'),
    (2, 3, '2024-01-20', 2000000.00, 24, 0.200, 1, 'Monthly', 'Approved', 7, 9, '2024-01-25'),
    (3, 1, '2024-02-01', 150000.00, 6, 0.220, 0, 'Monthly', 'Approved', 7, 9, '2024-02-05'),
    (4, 5, '2024-02-10', 800000.00, 36, 0.190, 0, 'Monthly', 'Approved', 7, 1, '2024-02-15'),
    (5, 3, '2024-02-15', 1000000.00, 18, 0.1800, 2, 'Monthly', 'Approved', 7, 1, '2024-02-20'),
    (6, 2, '2024-03-01', 5000000.00, 60, 0.1600, 3, 'Monthly', 'Approved', 7, 9, '2024-03-10'),
    (7, 4, '2024-03-05', 300000.00, 12, 0.2100, 0, 'Monthly', 'Rejected',  7, 9,'2024-03-08'),
    (8, 1, '2024-03-10', 200000.00, 6, 0.2200, 0, 'Monthly', 'Under Review', 7, 9, '2024-03-10'),
    (9, 2, '2024-03-15', 8000000.00, 120,0.1500, 6, 'Monthly', 'Under Review', 7, 1, '2024-03-15'),
    (10,1, '2024-03-20', 100000.00, 3, 0.2400, 0, 'Monthly', 'Rejected', 7, 9, '2024-03-22'),
    (1, 6, '2024-04-01', 250000.00, 3, 0.2000, 0, 'Monthly', 'Approved', 7, 9, '2024-04-03'),
    (2, 1, '2024-04-05', 400000.00, 12, 0.1900, 0, 'Monthly', 'Approved', 7, 1, '2024-04-08');
GO

-- Credit.Loan  (only Approved pipeline entries get booked — plus 2 fraudulent bookings
--              for LoanIDs 7 & 10 which were Rejected)
INSERT INTO Credit.Loan
    (LoanID, AccountNumber, PrincipalAmountApproved, TenorMonthApproved, InterestRateApproved, MoratoriumApproved, RepaymentScheduleApproved, Status, DisbursementDate, MaturityDate, CreatedByID, AuthorisedByID)
VALUES
    (1,  '1000000001', 500000.00, 12, 0.1800, 0, 'Monthly', 'Active', '2024-01-22', '2025-01-22', 3, 1),
    (2,  '1000000002', 2000000.00, 24, 0.2000, 1, 'Monthly', 'Active', '2024-01-27', '2026-01-27', 3, 1),
    (3,  '1000000003', 150000.00, 6, 0.2200, 0, 'Monthly', 'Paid', '2024-02-07', '2024-08-07', 3, 1),
    (4,  '1000000004', 800000.00, 36, 0.1900, 0, 'Monthly', 'Active', '2024-02-17', '2027-02-17', 3, 1),
    (5,  '1000000005', 1000000.00, 18, 0.1800, 2, 'Monthly', 'Active', '2024-02-22', '2025-08-22', 3, 1),
    (6,  '1000000006', 5000000.00, 60, 0.1600, 3, 'Monthly', 'Active', '2024-03-12', '2029-03-12', 9, 7),
    (7,  '1000000007', 300000.00, 12, 0.2100, 0, 'Monthly', 'Active', '2024-03-09', '2025-03-09', 3, 1),
    (10, '1000000010', 100000.00, 3, 0.2400, 0, 'Monthly', 'Active', '2024-03-23', '2024-06-23', 3, 1),
    (11, '1000000001', 250000.00, 3, 0.2000, 0, 'Monthly', 'Active', '2024-04-05', '2024-07-05', 3, 1),
    (12, '1000000002', 400000.00, 12, 0.1900, 0, 'Monthly', 'Active', '2024-04-10', '2025-04-10', 3, 1);
GO

-- Credit.Collateral
INSERT INTO Credit.Collateral
    (BookingID, CollateralType, Description, IsPerfected, PerfectionDate, BookValue, ForceSaleValue, ValuationDate, Valuer, IsReleased)
VALUES
    (1,  'PersonalGuarantee', 'Personal guarantee from employer', 1, '2024-01-22', 600000.00,  500000.00,  '2024-01-20', 'KoreBank Internal', 0),
    (2,  'StockShares', '10,000 units of Dangote Cement shares', 1, '2024-01-27', 2500000.00, 2000000.00, '2024-01-25', 'Vetiva Capital',    0),
    (4,  'Vehicle', '2020 Toyota Camry XLE', 1, '2024-02-17', 9500000.00, 7500000.00, '2024-02-15', 'AutoPro Valuers', 0),
    (5,  'FixedDeposit', 'FD lien on Account 1000000008', 1, '2024-02-22', 1200000.00, 1200000.00, '2024-02-20', 'KoreBank Internal', 0),
    (6,  'Mortgage', '5-bedroom duplex at Lekki Phase 1', 1, '2024-03-12', 80000000.00,60000000.00,'2024-03-08', 'Ecotech Surveyors', 0),
    (9,  'PersonalGuarantee', 'Director personal guarantee', 1, '2024-04-05', 300000.00,  250000.00,  '2024-04-04', 'KoreBank Internal', 0),
    (10, 'PersonalGuarantee', 'Next-of-kin guarantee',0, '2024-03-23', 120000.00,  100000.00,  '2024-03-22', 'KoreBank Internal', 0);
GO

INSERT INTO Channel.Card
(AccountID, CardNumber, CardType, CardScheme, ExpiryDate, CVVHash, PINHash, DailyLimit, Status)
VALUES
(1, '5399830000000001', 'Debit', 'Verve','2028-12-31','H1','P1',100000,'Active'),
(2, '5399830000000002', 'Debit','Mastercard', '2028-12-31','H2','P2',150000,'Active'),
(3, '5399830000000003', 'Debit','Visa', '2028-12-31','H3','P3',80000,'Active'),
(4, '5399830000000004', 'Debit','Verve', '2028-12-31','H4','P4',90000,'Active'),
(5, '5399830000000005', 'Credit','Visa', '2029-12-31','H5','P5',500000,'Active'),
(6, '5399830000000006', 'Debit','Mastercard', '2028-12-31','H6','P6',120000,'Active'),
(7, '5399830000000007','Debit','Verve','2028-12-31','H7','P7',70000,'Active'),
(8, '5399830000000008','Credit','Visa','2029-12-31','H8','P8',400000,'Active'),
(9, '5399830000000009','Debit','Mastercard','2028-12-31','H9','P9',200000,'Active'),
(10,'5399830000000010','Debit','Verve','2028-12-31','H10','P10',60000,'Active');
GO

INSERT INTO Audit.AuditLog
(EmployeeID, TableName, RecordID, ActionType, OldValues, NewValues, IPAddress)
VALUES
(1,'Core.Account', '1000000001','INSERT', NULL, 'Account created', '192.168.1.1'),
(2,'Core.Customer', '1','UPDATE','Pending','Verified','192.168.1.2'),
(3,'Credit.Loan', '1','INSERT',NULL,'Loan booked','192.168.1.3'),
(4,'Core.Account', '1000000002','UPDATE','Balance 1M','Balance 1.2M','192.168.1.4'),
(5,'TransOperation.Transaction', 'TXN20240101001','INSERT',NULL,'Transaction posted','192.168.1.5'),
(6,'Core.FixedDeposit','1', 'INSERT',NULL,'FD created','192.168.1.6'),
(7,'Core.AccountSignatory', '1','INSERT',NULL,'Signatory added','192.168.1.7'),
(8,'Channel.Card', '1','INSERT',NULL,'Card issued','192.168.1.8'),
(9,'Credit.Collateral', '1','UPDATE','Unperfected','Perfected','192.168.1.9'),
(10,'Core.Customer', '2','UPDATE','Email old','Email updated','192.168.1.10');
GO

/*Total loan exposure per loan product with average interest rate, total amount booked, largest and lowest amount booked. 
grouped by product name. products with more than 1 active loan are shown.*/

SELECT
    lp.LoanName  AS Loan_Product,
    lt.LoanTypeName  AS Loan_Category,
    COUNT(l.BookingID) AS Total_Bookings,
    SUM(l.PrincipalAmountApproved) AS [Total_Principal (NGN)],
    AVG(l.InterestRateApproved) * 100 AS [Avg_Interest_Rate (%)],
    MAX(l.PrincipalAmountApproved) AS Largest_Single_Loan,
    MIN(l.PrincipalAmountApproved) AS Smallest_Single_Loan
FROM Credit.Loan l
LEFT JOIN Credit.loanPipeline lpi ON l.LoanID = lpi.LoanID
INNER JOIN Product.LoanProduct lp  ON lpi.LoanProductID = lp.LoanProductID
INNER JOIN Product.LoanType lt  ON lp.LoanTypeID   = lt.LoanTypeID
WHERE l.Status NOT IN ('Written-Off', 'Paid')
GROUP BY
    lp.LoanName,
    lt.LoanTypeName
HAVING COUNT(l.BookingID) >= 1
ORDER BY [Total_Principal (NGN)] DESC;
GO

-- Account balance summary per branch: total deposits,  average balance, and number of active accounts

SELECT
    b.BranchName AS Branch,
    COUNT(a.AccountID) AS Total_Accounts,
    SUM(a.Balance) AS [Total_Deposits (NGN)],
    AVG(a.Balance) AS [Average_Balance (NGN)],
    MAX(a.Balance) AS Highest_Balance,
    SUM(CASE WHEN a.Status = 'Active' THEN 1 ELSE 0 END) AS [Active Accounts],
    SUM(CASE WHEN a.Status = 'Dormant' THEN 1 ELSE 0 END) AS [Dormant Accounts]
FROM Core.Account  a
JOIN Org.Branch b ON a.ProfitCenter = b.BranchID
GROUP BY  b.BranchName
ORDER BY  [Total_Deposits (NGN)] DESC;
GO

-- 3a.all customers whose first name starts with 'A'
SELECT
    CustomerID,
    FirstName + ' ' + LastName  AS FullName,
    Email,
    CustomerType,
    KYCStatus
FROM Core.Customer
WHERE FirstName LIKE 'A%';
GO

-- 3b. Employees whose email domain is '@korebank.com'and role contains the word 'Manager' anywhere
SELECT
    EmployeeID,
    FirstName + ' ' + LastName  AS FullName,
    Role,
    Level,
    Email
FROM  Org.Employee
WHERE Email LIKE '%@korebank.com'
  AND Role  LIKE '%Manager%';
GO

-- 3c. Transactions whose description contains the word 'loan' 
SELECT
    TransactionRef,
    AccountNumber,
    TransactionType,
    Amount,
    Description,
    TransactionDate
FROM  TransOperation.[Transaction]
WHERE Description LIKE '%loan%';
GO
-- FRAUD CHECK: Loans that were booked (exist in Credit.Loan)
-- but whose pipeline status is NOT 'Approved'.
-- These represent potentially fraudulent or unauthorised bookings.

SELECT
    l.BookingID  AS [Booking ID],
    l.LoanID AS [Loan ID],
    lpi.Status AS [Pipeline Status],  -- 'Rejected' or 'Under Review'
    c.FirstName + ' ' + c.LastName AS [Customer Name],
    lp.LoanName AS [Loan Product],
    lpi.PrincipalAmount AS [Amount Requested],
    l.PrincipalAmountApproved AS [Amount Booked],
    l.DisbursementDate AS [Disbursement Date],
    createdBy.FirstName + ' ' + createdBy.LastName AS [Booked By],
    authBy.FirstName   + ' ' + authBy.LastName AS [Authorised By],
    l.Status AS [Loan Status]
FROM  Credit.Loan l
INNER JOIN Credit.loanPipeline lpi ON l.LoanID = lpi.LoanID
INNER JOIN Core.Customer c ON lpi.CustomerID = c.CustomerID
INNER JOIN Product.LoanProduct lp ON lpi.LoanProductID = lp.LoanProductID
INNER JOIN Org.Employee createdBy ON l.CreatedByID = createdBy.EmployeeID
INNER JOIN Org.Employee authBy ON l.AuthorisedByID  = authBy.EmployeeID
WHERE lpi.Status <> 'Approved'   -- the smoking gun: booked without approval
ORDER BY l.DisbursementDate;
GO

-- FULL OUTER JOIN: Reconcile every pipeline application against every booked loan.
--Pipeline-only rows: approved/reviewed but never booked
-- Loan-only rows: booked with no pipeline record (ghost bookings)
-- Matched rows -normal flow
SELECT
    COALESCE(lpi.LoanID,  l.LoanID) AS Loan_ID,
    c.FirstName + ' ' + c.LastName AS Customer_Name,
    lpi.Status AS Pipeline_Status,
    lpi.PrincipalAmount AS Amount_Applied,
    l.BookingID AS Booking_ID,
    l.PrincipalAmountApproved AS Amount_Booked,
    l.DisbursementDate AS Disbursement_Date,
    l.Status AS Loan_Book_Status,
    CASE
        WHEN lpi.LoanID IS NULL THEN 'Ghost Booking – No Pipeline Record'
        WHEN l.BookingID IS NULL AND lpi.Status = 'Approved' THEN 'Approved – Awaiting Booking'
        WHEN l.BookingID IS NULL THEN 'Pipeline Only – Not Booked'
        WHEN lpi.Status <> 'Approved' AND l.BookingID IS NOT NULL THEN 'Fraudulent – Booked Without Approval'
        ELSE 'Normal'
    END AS Reconciliation_Flag
FROM Credit.loanPipeline lpi
FULL JOIN Credit.Loan l ON lpi.LoanID = l.LoanID
LEFT  JOIN  Core.Customer c ON COALESCE(lpi.CustomerID,
    (SELECT a.CustomerID FROM Core.Account a -- derive CustomerID from account when pipeline is missing
    WHERE a.AccountNumber = l.AccountNumber))
= c.CustomerID
ORDER BY
    CASE WHEN lpi.LoanID IS NULL OR (l.BookingID IS NOT NULL AND lpi.Status <> 'Approved')
         THEN 0 ELSE 1 END,   -- surface anomalies first
    COALESCE(lpi.LoanID, l.LoanID);
GO