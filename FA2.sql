--Use other DB in order to Delete existing DB

USE MASTER
GO 

-- Delete DB 

IF db_id('FA2') IS NOT NULL
BEGIN
    ALTER DATABASE FA2 SET single_user WITH ROLLBACK IMMEDIATE
	DROP DATABASE FA2 
END
GO 

-- Create DB

CREATE DATABASE FA2
GO 
USE FA2
GO

--Change owner of DB(to Public)

ALTER DATABASE FA2 SET TRUSTWORTHY ON; 
GO 
EXEC dbo.sp_changedbowner @loginame = N'sa', @map = false 
GO 
sp_configure 'show advanced options', 1; 
GO 
RECONFIGURE; 
GO 
sp_configure 'clr enabled', 1; 
GO 
RECONFIGURE; 
GO

--Create the tables

CREATE PROCEDURE CreateTheTables @schemaName nvarchar(100)
AS
  EXEC('CREATE SCHEMA [' + @schemaName + '] AUTHORIZATION [dbo]')
  DECLARE @sql nvarchar(MAX)

  SET @sql = '
		CREATE TABLE ' + @schemaName + '.Campus(
		CampusID int primary key,
		PhoneNumber nvarchar(10),
		CampusName nvarchar(30))'

    EXEC(@sql) 
	SET @sql = '
		CREATE TABLE ' + @schemaName + '.Teacher(
		TeacherID int primary key,
		TeacherName nvarchar(50),
		CampusID int,
		Course nvarchar(30),
		Description nvarchar(MAX))'

	EXEC(@sql) 
	SET @sql = '
		CREATE TABLE ' + @schemaName + '.Student(
		StudentID int primary key,
		StudentName varchar(50),
		Mark int,
		Course nvarchar(30))
		'
  EXEC(@sql) 
GO

CREATE VIEW rndView
AS
SELECT RAND() rndResult
GO

--Generate Marks for student
CREATE FUNCTION dbo.GenerateStudentMarks()
RETURNS INT 

AS
BEGIN
 DECLARE @RETURN int
 DECLARE @Upper INT;
 DECLARE @Lower INT;
 DECLARE @Random float;

  SELECT @Random = rndResult
  FROM rndView

  SET @Lower = 50 
  SET @Upper = 99 
  SET @RETURN= (ROUND(((@Upper - @Lower -1) * @Random + @Lower), 0))

  RETURN(@Return)
END
GO

CREATE PROCEDURE CreateDummyData @schemaName nvarchar(100)
AS
  DECLARE @sql nvarchar(MAX)
  DECLARE @len int
  DECLARE @pos int
  DECLARE @count int
  SET @pos = 0
  SET @len = 0
  SET @count = 1

--Add Campus to table
SET @sql = N'INSERT INTO ' + @schemaName + N'.Campus VALUES (@parID, @parNumber, @parName)';

	EXEC sp_executesql @sql, 
        N'@parID int, @parNumber nvarchar(10), @parName nvarchar(30)',
        @parID = @count,
        @parNumber = '0726543211',
        @parName = @schemaName

--Add Students
SET @count = 4

WHILE @count > 0
BEGIN
--INSERT VALUES INTO Teacher table 
    DECLARE @Mark int
	DECLARE @student nvarchar(30)

--Generate a random mark for student by calling the GenerateStudentMarks() function
	SET @Mark = dbo.GenerateStudentMarks()
	SET @sql = N'INSERT INTO ' + @schemaName + N'.Student VALUES (@parID, @parStudent, @parMark, @parCourse)';

	SET @student = 'student' + CAST(@count as nvarchar)
	EXEC sp_executesql @sql, 
        N'@parID int, @parStudent nvarchar(30), @parMark int, @parCourse nvarchar(30)',
        @parID = @count,
        @parStudent = @student, 
        @parMark = @Mark,
		@parCourse = 'MCSE DA'

--Increase counter
    SET @count = @count - 1
END


--Add Teachers
SET @count = 4

WHILE @count > 0
BEGIN
--INSERT VALUES INTO Teacher table 
	SET @sql = N'INSERT INTO ' + @schemaName + N'.Student VALUES (@parID, @parTeacherName, @parCampusID, @parCourse, @parDescription)';

	DECLARE @Teacher nvarchar(30)
	DECLARE @Description nvarchar(50)
	SET @Teacher = 'Teacher' + CAST(@count as nvarchar)
	SET @Description = 'Teaches MCSE DA at ' + @schemaName + ' campus'

	EXEC sp_executesql @sql, 
        N'@parID int, @parTeacherName nvarchar(50), @parCampusID int, @parCourse nvarchar(30), @parDescription nvarchar(MAX)',
        @parID = @count,
        @parTeacherName = @Teacher, 
		@parCampusID = 1,
		@parCourse = 'MCSE DA',
		@parDescription = @Description

--Increase counter
    SET @count = @count - 1
END
GO

--Create Schema's

DECLARE @len int
DECLARE @pos int
DECLARE @schemaName varchar(30)
DECLARE @sql varchar(500)
DECLARE @schemaList varchar(500)
SET @pos = 0
SET @len = 0
SET @schemaList = 'Auckland_Park,Bloemfontein,Boksburg,Cape_Town,Durban,Nelspruit,Polokwane,Potchefstroom,Port_Elizabeth,Pretoria,Randburg,Sandton,Roodepoort,Stellenbosch,Vereeniging,'

WHILE CHARINDEX(',', @schemaList, @pos+1)>0
BEGIN
    SET @len = CHARINDEX(',', @schemaList, @pos+1) - @pos
    SET @schemaName = SUBSTRING(@schemaList, @pos, @len)
    
-- Call the stored procedure to create the tables and records
	EXEC CreateTheTables @schemaName
	EXEC CreateDummyData @schemaName

    SET @pos = CHARINDEX(',', @schemaList, @pos+@len) +1
END
GO


--Show Results for teacher:
SELECT *
FROM Nelspruit.Student

SELECT * 
FROM Stellenbosch.Student

