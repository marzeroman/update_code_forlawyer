-- Create 'Lawmange' Database
CREATE DATABASE IF NOT EXISTS lawmange;

-- Switch to 'Lawmange' Database
USE lawmange;

-- Create 'Admins' Table
CREATE TABLE Admin (
    AdminID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    OwnerID INT,
    FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID)
);

-- Create 'Owners' Table
CREATE TABLE Owners (
    OwnerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL
);

-- Add 'OwnerID' column to Lawyers table
ALTER TABLE Lawyers
ADD COLUMN OwnerID INT,
ADD FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID);

-- Add 'OwnerID' column to Clients table
ALTER TABLE Clients
ADD COLUMN OwnerID INT,
ADD FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID);

-- Create 'Cases' Table
CREATE TABLE Cases (
    CaseID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    Description TEXT,
    Status ENUM('open', 'closed') NOT NULL,
    LawyerID INT,
    ClientID INT,
    OwnerID INT,
    FOREIGN KEY (LawyerID) REFERENCES Lawyers(LawyerID),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID)
);

-- Add 'OwnerID' column to Files table
ALTER TABLE Files
ADD COLUMN OwnerID INT,
ADD FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID);

-- Create 'Files' Table
CREATE TABLE Files (
    FileID INT AUTO_INCREMENT PRIMARY KEY,
    FileName VARCHAR(255) NOT NULL,
    CaseID INT,
    UploadDate DATE NOT NULL,
    Size DECIMAL(10,2) NOT NULL, -- Size in MB
    OwnerID INT,
    FOREIGN KEY (CaseID) REFERENCES Cases(CaseID), -- Establishing the one-to-many relationship
    FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID)
);

-- Add 'OwnerID' column to Users table
ALTER TABLE Users
ADD COLUMN OwnerID INT,
ADD FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID);

-- Create 'Implementation' Table
CREATE TABLE Implementation (
    ImplementationID INT AUTO_INCREMENT PRIMARY KEY,
    CaseID INT,
    Description TEXT,
    FOREIGN KEY (CaseID) REFERENCES Cases(CaseID)
);

-- Create 'Sessions' Table
CREATE TABLE Sessions (
    SessionID INT AUTO_INCREMENT PRIMARY KEY,
    CaseID INT,
    Date DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    Notes TEXT,
    FOREIGN KEY (CaseID) REFERENCES Cases(CaseID)
);

-- Create 'Lawyer_Tier_Limits' Table
CREATE TABLE Lawyer_Tier_Limits (
    Type ENUM('gold', 'silver', 'copper') PRIMARY KEY,
    MaxUsers INT NOT NULL,
    MaxCases INT NOT NULL,
    MaxStorage INT NOT NULL -- Storage in MB
);

-- Create 'Lawyers' Table
CREATE TABLE Lawyers (
    LawyerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Address TEXT,
    Status ENUM('active', 'suspended') NOT NULL,
    PhoneNumber VARCHAR(20),
    Gender ENUM('male', 'female', 'other') NOT NULL,
    StartDate DATE NOT NULL,
    ExpireDate DATE NOT NULL,
    Type ENUM('gold', 'silver', 'copper') NOT NULL,
    AdminID INT,
    OwnerID INT,
    FOREIGN KEY (AdminID) REFERENCES Admin(AdminID),
    FOREIGN KEY (Type) REFERENCES Lawyer_Tier_Limits(Type),
    FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID)
);

-- Create 'Clients' Table
CREATE TABLE Clients (
    ClientID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    LawyerID INT,
    OwnerID INT,
    FOREIGN KEY (LawyerID) REFERENCES Lawyers(LawyerID),
    FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID)
);

-- Create 'Notifications' Table
CREATE TABLE Notifications (
    NotificationID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT,
    LawyerID INT,
    Message TEXT NOT NULL,
    DateCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    IsRead BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (LawyerID) REFERENCES Lawyers(LawyerID)
);

-- Create 'Calendar' Table
CREATE TABLE Calendar (
    EventID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    Description TEXT,
    Date DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    Location VARCHAR(255),
    LawyerID INT,
    UserID INT,
    FOREIGN KEY (LawyerID) REFERENCES Lawyers(LawyerID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- Create 'Bills' Table
CREATE TABLE Bills (
    BillID INT AUTO_INCREMENT PRIMARY KEY,
    CaseID INT,
    Amount DECIMAL(10,2) NOT NULL,
    Description TEXT,
    IssueDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    Paid BOOLEAN DEFAULT FALSE,
    LawyerID INT,
    FOREIGN KEY (CaseID) REFERENCES Cases(CaseID),
    FOREIGN KEY (LawyerID) REFERENCES Lawyers(LawyerID)
);

-- Create stored procedure for dynamically creating lawyer tables
DELIMITER //

CREATE PROCEDURE CreateLawyerTable(
    IN p_name VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255),
    IN p_address TEXT,
    IN p_status ENUM('active', 'suspended'),
    IN p_phoneNumber VARCHAR(20),
    IN p_gender ENUM('male', 'female', 'other'),
    IN p_startDate DATE,
    IN p_expireDate DATE,
    IN p_type ENUM('gold', 'silver', 'copper'),
    IN p_ownerID INT
)
BEGIN
    DECLARE v_lawyerTableName VARCHAR(255);
    
    -- Generate a unique table name for the lawyer
    SET v_lawyerTableName = CONCAT('Lawyer_', REPLACE(p_name, ' ', '_'), '_', p_email);

    -- Create the dynamic SQL query to create a new table for the lawyer
    SET @sql = CONCAT(
        'CREATE TABLE IF NOT EXISTS ', v_lawyerTableName, ' (
            LawyerID INT AUTO_INCREMENT PRIMARY KEY,
            Name VARCHAR(255) NOT NULL,
            Email VARCHAR(255) UNIQUE NOT NULL,
            Password VARCHAR(255) NOT NULL,
            Address TEXT,
            Status ENUM(\'active\', \'suspended\') NOT NULL,
            PhoneNumber VARCHAR(20),
            Gender ENUM(\'male\', \'female\', \'other\') NOT NULL,
            StartDate DATE NOT NULL,
            ExpireDate DATE NOT NULL,
            Type ENUM(\'gold\', \'silver\', \'copper\') NOT NULL,
            OwnerID INT,
            FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID)
        );'
    );

    -- Execute the dynamic SQL query to create the lawyer's table
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Insert lawyer's information into the newly created table
    SET @sql = CONCAT(
        'INSERT INTO ', v_lawyerTableName, ' (Name, Email, Password, Address, Status, PhoneNumber, Gender, StartDate, ExpireDate, Type, OwnerID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);'
    );

    -- Execute the dynamic SQL query to insert lawyer's information
    PREPARE stmt FROM @sql;
    EXECUTE stmt USING p_name, p_email, p_password, p_address, p_status, p_phoneNumber, p_gender, p_startDate, p_expireDate, p_type, p_ownerID;
    DEALLOCATE PREPARE stmt;

END//

DELIMITER ;

-- Insert predefined limits for each lawyer tier
INSERT INTO Lawyer_Tier_Limits (Type, MaxUsers, MaxCases, MaxStorage) VALUES
('gold', 3, 150, 20480), -- 20 GB in MB
('silver', 2, 100, 15360), -- 15 GB in MB
('copper', 1, 50, 10240); -- 10 GB in MB
