-- this script was found via google but I cannot remmeber where at this point in time.
-- Collects information about all job runs on server
USE [testdb]; -- the stored procedure will be stored in this database
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE tables.name = 'Dim_Date')
BEGIN
	CREATE TABLE dbo.Dim_Date (
		Calendar_Date DATE NOT NULL CONSTRAINT PK_Dim_Date PRIMARY KEY CLUSTERED,
		Calendar_Date_String VARCHAR(10) NOT NULL,
		Calendar_Month TINYINT NOT NULL,
		Calendar_Day TINYINT NOT NULL,
		Calendar_Year SMALLINT NOT NULL,
		Calendar_Quarter TINYINT NOT NULL,
		Day_Name VARCHAR(9) NOT NULL,
		Day_of_Week TINYINT NOT NULL,
		Day_of_Week_in_Month TINYINT NOT NULL,
		Day_of_Week_in_Year TINYINT NOT NULL,
		Day_of_Week_in_Quarter TINYINT NOT NULL,
		Day_of_Quarter TINYINT NOT NULL,
		Day_of_Year SMALLINT NOT NULL,
		Week_of_Month TINYINT NOT NULL,
		Week_of_Quarter TINYINT NOT NULL,
		Week_of_Year TINYINT NOT NULL,
		Month_Name VARCHAR(9) NOT NULL,
		First_Date_of_Week DATE NOT NULL,
		Last_Date_of_Week DATE NOT NULL,
		First_Date_of_Month DATE NOT NULL,
		Last_Date_of_Month DATE NOT NULL,
		First_Date_of_Quarter DATE NOT NULL,
		Last_Date_of_Quarter DATE NOT NULL,
		First_Date_of_Year DATE NOT NULL,
		Last_Date_of_Year DATE NOT NULL,
		Is_Holiday BIT NOT NULL,
		Holiday_Name VARCHAR(50) NULL,
		Is_Weekday BIT NOT NULL,
		Is_Business_Day BIT NOT NULL,
		Previous_Business_Day DATE NULL,
		Next_Business_Day DATE NULL,
		Is_Leap_Year BIT NOT NULL,
		Days_in_Month TINYINT NOT NULL);
END
GO

IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'populate_dim_date')
BEGIN
	DROP PROCEDURE dbo.populate_dim_date;
END
GO

CREATE PROCEDURE dbo.populate_dim_date
	@Start_Date DATE ='2023-07-14', -- Start of date range to process 2023-07-17
	@End_Date DATE ='2023-07-17' -- End of date range to process
AS
BEGIN
	SET NOCOUNT ON;

	IF @Start_Date IS NULL OR @End_Date IS NULL
	BEGIN
		SELECT 'Start and end dates MUST be provided in order for this stored procedure to work.';
		RETURN;
	END

	IF @Start_Date > @End_Date
	BEGIN
		SELECT 'Start date must be less than or equal to the end date.';
		RETURN;
	END

	-- Remove all old data for the date range provided.
	DELETE FROM dbo.Dim_Date
	WHERE Dim_Date.Calendar_Date BETWEEN @Start_Date AND @End_Date;
	-- These variables dirrectly correspond to columns in Dim_Date
	DECLARE @Date_Counter DATE = @Start_Date;
	DECLARE @Calendar_Date_String VARCHAR(10);
	DECLARE @Calendar_Month TINYINT;
	DECLARE @Calendar_Day TINYINT;
	DECLARE @Calendar_Year SMALLINT;
	DECLARE @Calendar_Quarter TINYINT;
	DECLARE @Day_Name VARCHAR(9);
	DECLARE @Day_of_Week TINYINT;
	DECLARE @Day_of_Week_in_Month TINYINT;
	DECLARE @Day_of_Week_in_Year TINYINT;
	DECLARE @Day_of_Week_in_Quarter TINYINT;
	DECLARE @Day_of_Quarter TINYINT;
	DECLARE @Day_of_Year SMALLINT;
	DECLARE @Week_of_Month TINYINT;
	DECLARE @Week_of_Quarter TINYINT;
	DECLARE @Week_of_Year TINYINT;
	DECLARE @Month_Name VARCHAR(9);
	DECLARE @First_Date_of_Week DATE;
	DECLARE @Last_Date_of_Week DATE;
	DECLARE @First_Date_of_Month DATE;
	DECLARE @Last_Date_of_Month DATE;
	DECLARE @First_Date_of_Quarter DATE;
	DECLARE @Last_Date_of_Quarter DATE;
	DECLARE @First_Date_of_Year DATE;
	DECLARE @Last_Date_of_Year DATE;
	DECLARE @Is_Holiday BIT;
	DECLARE @Holiday_Name VARCHAR(50);
	DECLARE @Is_Weekday BIT;
	DECLARE @Is_Business_Day BIT;
	DECLARE @Is_Leap_Year BIT;
	DECLARE @Days_in_Month TINYINT;

	-- These variables are used internally within this proc for various calculations
	DECLARE @First_Date_of_Next_Year DATE;
	DECLARE @First_Date_of_Last_Year DATE;

	WHILE @Date_Counter <= @End_Date
	BEGIN
		SELECT @Calendar_Month = DATEPART(MONTH, @Date_Counter);
		SELECT @Calendar_Day = DATEPART(DAY, @Date_Counter);
		SELECT @Calendar_Year = DATEPART(YEAR, @Date_Counter);
		SELECT @Calendar_Quarter = DATEPART(QUARTER, @Date_Counter);
		SELECT @Calendar_Date_String = CAST(@Calendar_Month AS VARCHAR(10)) + '/' + CAST(@Calendar_Day AS VARCHAR(10)) + '/' + CAST(@Calendar_Year AS VARCHAR(10));
		SELECT @Day_of_Week = DATEPART(WEEKDAY, @Date_Counter);
		SELECT @Is_Business_Day = CASE
									WHEN @Day_of_Week IN (1, 7) THEN 0
									ELSE 1
								  END;
		SELECT @Day_Name = CASE @Day_of_Week
								WHEN 1 THEN 'Sunday'
								WHEN 2 THEN 'Monday'
								WHEN 3 THEN 'Tuesday'
								WHEN 4 THEN 'Wednesday'
								WHEN 5 THEN 'Thursday'
								WHEN 6 THEN 'Friday'
								WHEN 7 THEN 'Saturday'
							END;
		SELECT @Day_of_Quarter = DATEDIFF(DAY, DATEADD(QUARTER, DATEDIFF(QUARTER, 0 , @Date_Counter), 0), @Date_Counter) + 1;
		SELECT @Day_of_Year = DATEPART(DAYOFYEAR, @Date_Counter);
		SELECT @Week_of_Month = DATEDIFF(WEEK, DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date_Counter), 0)), 0), @Date_Counter ) + 1;
		SELECT @Week_of_Quarter = DATEDIFF(DAY, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Date_Counter), 0), @Date_Counter)/7 + 1;
		SELECT @Week_of_Year = DATEPART(WEEK, @Date_Counter);
		SELECT @Month_Name = CASE @Calendar_Month
								WHEN 1 THEN 'January'
								WHEN 2 THEN 'February'
								WHEN 3 THEN 'March'
								WHEN 4 THEN 'April'
								WHEN 5 THEN 'May'
								WHEN 6 THEN 'June'
								WHEN 7 THEN 'July'
								WHEN 8 THEN 'August'
								WHEN 9 THEN 'September'
								WHEN 10 THEN 'October'
								WHEN 11 THEN 'November'
								WHEN 12 THEN 'December'
							END;

		SELECT @First_Date_of_Week = DATEADD(DAY, -1 * @Day_of_Week + 1, @Date_Counter);
		SELECT @Last_Date_of_Week = DATEADD(DAY, 1 * (7 - @Day_of_Week), @Date_Counter);
		SELECT @First_Date_of_Month = DATEADD(DAY, -1 * DATEPART(DAY, @Date_Counter) + 1, @Date_Counter);
		SELECT @First_Date_of_Quarter = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Date_Counter), 0);
		SELECT @Last_Date_of_Quarter = DATEADD (DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Date_Counter) + 1, 0));
		SELECT @First_Date_of_Year = DATEADD(YEAR, DATEDIFF(YEAR, 0, @Date_Counter), 0);
		SELECT @Last_Date_of_Year = DATEADD(DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, @Date_Counter) + 1, 0));
		SELECT @Is_Weekday = CASE
								WHEN @Day_of_Week IN (1, 7)
									THEN 0
								ELSE 1
							 END;
		SELECT @Day_of_Week_in_Month = (@Calendar_Day + 6) / 7;
		SELECT @Day_of_Week_in_Year = (@Day_of_Year + 6) / 7;
		SELECT @Day_of_Week_in_Quarter = (@Day_of_Quarter + 6) / 7;
		SELECT @Is_Leap_Year = CASE
									WHEN @Calendar_Year % 4 <> 0 THEN 0
									WHEN @Calendar_Year % 100 <> 0 THEN 1
									WHEN @Calendar_Year % 400 <> 0 THEN 0
									ELSE 1
							   END;
		SELECT @First_Date_of_Next_Year = DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, 1, @Date_Counter)), 0);
		SELECT @First_Date_of_Last_Year = DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, -1, @Date_Counter)), 0);

		SELECT @Days_in_Month = CASE
									WHEN @Calendar_Month IN (4, 6, 9, 11) THEN 30
									WHEN @Calendar_Month IN (1, 3, 5, 7, 8, 10, 12) THEN 31
									WHEN @Calendar_Month = 2 AND @Is_Leap_Year = 1 THEN 29
									ELSE 28
								END;

		SELECT @Last_Date_of_Month = DATEADD(DAY, @Days_in_Month - 1, @First_Date_of_Month);
								
		INSERT INTO dbo.Dim_Date
			(Calendar_Date, Calendar_Date_String, Calendar_Month, Calendar_Day, Calendar_Year, Calendar_Quarter, Day_Name, Day_of_Week, Day_of_Week_in_Month,
				Day_of_Week_in_Year, Day_of_Week_in_Quarter, Day_of_Quarter, Day_of_Year, Week_of_Month, Week_of_Quarter, Week_of_Year, Month_Name,
				First_Date_of_Week, Last_Date_of_Week, First_Date_of_Month, Last_Date_of_Month, First_Date_of_Quarter, Last_Date_of_Quarter, First_Date_of_Year,
				Last_Date_of_Year, Is_Holiday, Holiday_Name, Is_Weekday, Is_Business_Day, Previous_Business_Day, Next_Business_Day, Is_Leap_Year, Days_in_Month)
		SELECT
			@Date_Counter AS Calendar_Date,
			@Calendar_Date_String AS Calendar_Date_String,
			@Calendar_Month AS Calendar_Month,
			@Calendar_Day AS Calendar_Day,
			@Calendar_Year AS Calendar_Year,
			@Calendar_Quarter AS Calendar_Quarter,
			@Day_Name AS Day_Name,
			@Day_of_Week AS Day_of_Week,
			@Day_of_Week_in_Month AS Day_of_Week_in_Month,
			@Day_of_Week_in_Year AS Day_of_Week_in_Year,
			@Day_of_Week_in_Quarter AS Day_of_Week_in_Quarter,
			@Day_of_Quarter AS Day_of_Quarter,
			@Day_of_Year AS Day_of_Year,
			@Week_of_Month AS Week_of_Month,
			@Week_of_Quarter AS Week_of_Quarter,
			@Week_of_Year AS Week_of_Year,
			@Month_Name AS Month_Name,
			@First_Date_of_Week AS First_Date_of_Week,
			@Last_Date_of_Week AS Last_Date_of_Week,
			@First_Date_of_Month AS First_Date_of_Month,
			@Last_Date_of_Month AS Last_Date_of_Month,
			@First_Date_of_Quarter AS First_Date_of_Quarter,
			@Last_Date_of_Quarter AS Last_Date_of_Quarter,
			@First_Date_of_Year AS First_Date_of_Year,
			@Last_Date_of_Year AS Last_Date_of_Year,
			0 AS Is_Holiday,
			NULL AS Holiday_Name,
			@Is_Weekday AS Is_Weekday,
			@Is_Business_Day AS Is_Business_Day, -- Will be populated with weekends to start.
			NULL AS Previous_Business_Day,
			NULL AS Next_Business_Day,
			@Is_Leap_Year AS Is_Leap_Year,
			@Days_in_Month AS Days_in_Month;

		SELECT @Date_Counter = DATEADD(DAY, 1, @Date_Counter);
	END

	-- Holiday Calculations, which are based on CommerceHub holidays.  Is_Business_Day is determined based on Federal holidays only.

	-- New Year's Day: 1st of January
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'New Year''s Day',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 1
	AND Dim_Date.Calendar_Day = 1
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Martin Luther King, Jr. Day: 3rd Monday in January, beginning in 1983
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Martin Luther King, Jr. Day',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 1
	AND Dim_Date.Day_of_Week = 2
	AND Dim_Date.Day_of_Week_in_Month = 3
	AND Dim_date.Calendar_Year >= 1983
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- President's Day: 3rd Monday in February
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'President''s Day',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 2
	AND Dim_Date.Day_of_Week = 2
	AND Dim_Date.Day_of_Week_in_Month = 3
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Valentine's Day: 14th of February
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Valentine''s Day'
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 2
	AND Dim_Date.Calendar_Day = 14
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Saint Patrick's Day: 17th of March
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Saint Patrick''s Day'
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 3
	AND Dim_Date.Calendar_Day = 17
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Mother's Day: 2nd Sunday in May
		UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Mother''s Day'
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 5
	AND Dim_Date.Day_of_Week = 1
	AND Dim_Date.Day_of_Week_in_Month = 2
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Memorial Day: Last Monday in May
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Memorial Day',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 5
	AND Dim_Date.Day_of_Week = 2
	AND Dim_Date.Day_of_Week_in_Month = (SELECT MAX(Dim_Date_Memorial_Day_Check.Day_of_Week_in_Month) FROM dbo.Dim_Date Dim_Date_Memorial_Day_Check WHERE Dim_Date_Memorial_Day_Check.Calendar_Month = Dim_Date.Calendar_Month
																									  AND Dim_Date_Memorial_Day_Check.Day_of_Week = Dim_Date.Day_of_Week
																									  AND Dim_Date_Memorial_Day_Check.Calendar_Year = Dim_Date.Calendar_Year)
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Father's Day: 3rd Sunday in June
		UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Father''s Day'
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 6
	AND Dim_Date.Day_of_Week = 1
	AND Dim_Date.Day_of_Week_in_Month = 3
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Independence Day (USA): 4th of July
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Independence Day (USA)',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 7
	AND Dim_Date.Calendar_Day = 4
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Labor Day: 1st Monday in September
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Labor Day',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 9
	AND Dim_Date.Day_of_Week = 2
	AND Dim_Date.Day_of_Week_in_Month = 1
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Columbus Day: 2nd Monday in October
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Columbus Day',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 10
	AND Dim_Date.Day_of_Week = 2
	AND Dim_Date.Day_of_Week_in_Month = 2
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Halloween: 31st of October
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Halloween'
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 10
	AND Dim_Date.Calendar_Day = 31
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Veteran's Day: 11th of November
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Veteran''s Day',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 11
	AND Dim_Date.Calendar_Day = 11
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Thanksgiving: 4th Thursday in November
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Thanksgiving',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 11
	AND Dim_Date.Day_of_Week = 5
	AND Dim_Date.Day_of_Week_in_Month = 4
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Election Day (USA): 1st Tuesday after November 1st, only in even-numbered years.  Always in the range of November 2-8.
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Election Day (USA)'
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 11
	AND Dim_Date.Day_of_Week = 3
	AND Dim_Date.Calendar_Day BETWEEN 2 AND 8
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Christmas: 25th of December
	UPDATE Dim_date
		SET Is_Holiday = 1,
			Holiday_Name = 'Christmas',
			Is_Business_Day = 0
	FROM dbo.Dim_date
	WHERE Dim_Date.Calendar_Month = 12
	AND Dim_Date.Calendar_Day = 25
	AND Dim_date.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Merge weekday and holiday data into our data set to determine business days over the time span specified in the parameters.
	-- Previous Business Day
	WITH CTE_Business_Days AS (
		SELECT
			Business_Days.Calendar_Date
		FROM dbo.Dim_Date Business_Days
		WHERE Business_Days.Is_Business_Day = 1
	)
	UPDATE Dim_Date_Current
		SET Previous_Business_Day = CTE_Business_Days.Calendar_Date
	FROM dbo.Dim_Date Dim_Date_Current
	INNER JOIN CTE_Business_Days
	ON CTE_Business_Days.Calendar_Date = (SELECT MAX(Previous_Business_Day.Calendar_Date) FROM CTE_Business_Days Previous_Business_Day
										  WHERE Previous_Business_Day.Calendar_Date < Dim_Date_Current.Calendar_Date)
	WHERE Dim_Date_Current.Calendar_Date BETWEEN @Start_Date AND @End_Date;

	-- Next Business Day
	WITH CTE_Business_Days AS (
		SELECT
			Business_Days.Calendar_Date
		FROM dbo.Dim_Date Business_Days
		WHERE Business_Days.Is_Business_Day = 1
	)
	UPDATE Dim_Date_Current
		SET Next_Business_Day = CTE_Business_Days.Calendar_Date
	FROM dbo.Dim_Date Dim_Date_Current
	INNER JOIN CTE_Business_Days
	ON CTE_Business_Days.Calendar_Date = (SELECT MIN(Next_Business_Day.Calendar_Date) FROM CTE_Business_Days Next_Business_Day
										  WHERE Next_Business_Day.Calendar_Date > Dim_Date_Current.Calendar_Date)
	WHERE Dim_Date_Current.Calendar_Date BETWEEN @Start_Date AND @End_Date;
END
GO

IF (SELECT COUNT(*) FROM dbo.Dim_Date) = 0
BEGIN
	EXEC dbo.populate_dim_date @Start_Date = '1/1/2000', @End_Date = '1/1/2030';
END
GO

IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'generate_job_schedule_data')
BEGIN
	DROP PROCEDURE dbo.generate_job_schedule_data;
END
GO

CREATE PROCEDURE dbo.generate_job_schedule_data
	@start_time_utc DATETIME = NULL, -- The date & time to begin returning data in UTC time.  If supplied, this time will supercede any local times provided.
	@end_time_utc DATETIME = NULL, -- The date & time to end returning data in UTC time.  If supplied, this time will supercede any local times provided.
	@start_time_local DATETIME = NULL, -- The date & time to begin returning data in the local server time
	@end_time_local DATETIME = NULL, -- The date & time to end returning data in the local server time
	@return_summarized_data BIT = 1, -- When 1, return an aggregate rollup of job runs, one row per job.  When 0, return a row per job run, which can be quite extensive.
	@include_startup_and_idle_jobs_in_summary_data BIT = 0 -- When 1, will include jobs that run at agent startup or when the computer is idle.
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @utc_offset INT;
	SELECT
		@utc_offset = DATEDIFF(HOUR, GETUTCDATE(), GETDATE());
		
	-- Check for degenerate cases with parameters and return if needed
	IF (@start_time_utc > @end_time_utc AND @start_time_utc IS NOT NULL AND @end_time_utc IS NOT NULL)
	OR (@start_time_local > @end_time_local AND @start_time_local IS NOT NULL AND @end_time_local IS NOT NULL)
	OR (@start_time_utc IS NOT NULL AND @end_time_utc IS NULL)
	OR (@start_time_utc IS NULL AND @end_time_utc IS NOT NULL)
	OR (@start_time_utc IS NULL AND @end_time_utc IS NULL AND @start_time_local IS NULL AND @end_time_local IS NULL)
	BEGIN
		RAISERROR('Invalid values provided for datetime parameters!', 16, 1);
		RETURN;
	END

	-- If utc times are provided, then convert to local for use in the rest of the proc
	IF @start_time_local IS NULL AND @end_time_local IS NULL
	BEGIN
		SELECT @start_time_local = DATEADD(HOUR, @utc_offset , @start_time_utc);
		SELECT @end_time_local = DATEADD(HOUR, @utc_offset, @end_time_utc);
	END

	DECLARE @end_date_local_int INT = CAST(REPLACE(CAST(CAST(@end_time_local AS DATE)AS VARCHAR(MAX)), '-', '') AS INT);

/*
Days Affected
*/

	DROP TABLE IF EXISTS #days_affected;
		
	CREATE TABLE #days_affected
		(calendar_date DATE NOT NULL PRIMARY KEY CLUSTERED);

	INSERT INTO #days_affected
		(calendar_date)
	SELECT
		Dim_Date.Calendar_Date
	FROM dbo.Dim_Date
	WHERE Dim_Date.Calendar_Date >= CAST(@start_time_local AS DATE)
	AND Dim_Date.Calendar_Date <= @end_time_local;

/*
Future Job Runs
*/

	DROP TABLE IF EXISTS #future_job_runs

	CREATE TABLE #future_job_runs
	(	job_id UNIQUEIDENTIFIER NOT NULL,
		schedule_uid UNIQUEIDENTIFIER NOT NULL,
		job_run_time_local DATETIME NOT NULL,
	PRIMARY KEY CLUSTERED (job_id, job_run_time_local));
/*
Job Summary
*/

	DROP TABLE IF EXISTS #job_summary
	
	CREATE TABLE #job_summary
	(	job_id UNIQUEIDENTIFIER NOT NULL,
		schedule_uid UNIQUEIDENTIFIER NOT NULL,
		job_name VARCHAR(128) NOT NULL,
		job_frequency VARCHAR(25) NOT NULL, -- ONE-TIME, DAILY, WEEKLY, MONTHLY, MONTHLY-RELATIVE, AGENT_STARTUP, COMPUTER_IDLE
		job_frequency_interval INT NOT NULL,
		job_frequency_subday_type VARCHAR(25) NOT NULL, -- UNUSED, AT_TIME, SECONDS, MINUTES, HOURS
		job_frequency_subday_interval INT NOT NULL,
		job_frequency_relative_interval VARCHAR(25) NOT NULL, -- UNUSED, FIRST, SECOND, THIRD, FOURTH, LAST
		job_frequency_recurrence_factor INT NOT NULL,
		job_start_date_local DATE NOT NULL,
		job_start_time_local TIME NOT NULL,
		job_start_datetime_local DATETIME NOT NULL,
		job_end_date_local DATE NOT NULL,
		job_end_time_local TIME NOT NULL,
		job_end_datetime_local DATETIME NOT NULL,
		job_date_created_local DATETIME NOT NULL,
		schedule_date_created_local DATETIME NOT NULL,
		job_schedule_description VARCHAR(250),
		job_count INT NOT NULL,
		PRIMARY KEY CLUSTERED (job_id, schedule_uid));

	INSERT INTO #job_summary
		(job_id, schedule_uid, job_name, job_frequency, job_frequency_interval, job_frequency_subday_type, job_frequency_subday_interval, job_frequency_relative_interval,
		 job_frequency_recurrence_factor, job_start_date_local, job_start_time_local, job_start_datetime_local, job_end_date_local, job_end_time_local,
		 job_end_datetime_local, job_date_created_local, schedule_date_created_local, job_schedule_description, job_count)
	SELECT
		sysjobs.job_id,
		sysschedules.schedule_uid,
		sysjobs.name AS job_name,
		CASE
			WHEN sysschedules.freq_type = 1 THEN 'One-Time'
			WHEN sysschedules.freq_type = 4 THEN 'Daily'
			WHEN sysschedules.freq_type = 8 THEN 'Weekly'
			WHEN sysschedules.freq_type = 16 THEN 'Monthly'
			WHEN sysschedules.freq_type = 32 THEN 'Monthly-Relative'
			WHEN sysschedules.freq_type = 64 THEN 'Agent Startup'
			WHEN sysschedules.freq_type = 128 THEN 'Computer Idle'
		END AS job_frequency,
		sysschedules.freq_interval AS job_frequency_interval,
		CASE
			WHEN sysschedules.freq_subday_type = 0 THEN 'UNUSED'
			WHEN sysschedules.freq_subday_type = 1 THEN 'AT_TIME'
			WHEN sysschedules.freq_subday_type = 2 THEN 'SECONDS'
			WHEN sysschedules.freq_subday_type = 4 THEN 'MINUTES'
			WHEN sysschedules.freq_subday_type = 8 THEN 'HOURS'
		END AS job_frequency_subday_type,
		sysschedules.freq_subday_interval AS job_frequency_subday_interval,
		CASE
			WHEN sysschedules.freq_relative_interval = 0 THEN 'UNUSED'
			WHEN sysschedules.freq_relative_interval = 1 THEN 'first'
			WHEN sysschedules.freq_relative_interval = 2 THEN 'second'
			WHEN sysschedules.freq_relative_interval = 4 THEN 'third'
			WHEN sysschedules.freq_relative_interval = 8 THEN 'fourth'
			WHEN sysschedules.freq_relative_interval = 16 THEN 'last'
		END AS job_frequency_relative_interval,
		sysschedules.freq_recurrence_factor AS job_frequency_recurrence_factor,
		CAST(msdb.dbo.agent_datetime(sysschedules.active_start_date, sysschedules.active_start_time) AS DATE) AS job_start_date_local,
		CAST(msdb.dbo.agent_datetime(sysschedules.active_start_date, sysschedules.active_start_time) AS TIME(0)) AS job_start_time_local,
		CAST(msdb.dbo.agent_datetime(sysschedules.active_start_date, sysschedules.active_start_time) AS DATETIME) AS job_start_datetime_local,
		CASE WHEN sysschedules.active_end_date = 99991231
			THEN CAST(@end_time_local AS DATE)
			ELSE CAST(msdb.dbo.agent_datetime(sysschedules.active_end_date, sysschedules.active_end_time) AS DATE)
		END AS job_end_date_local,
		CASE WHEN sysschedules.active_end_date = 99991231
			THEN CAST(msdb.dbo.agent_datetime(@end_date_local_int, sysschedules.active_end_time) AS TIME(0))
			ELSE CAST(msdb.dbo.agent_datetime(sysschedules.active_end_date, sysschedules.active_end_time) AS TIME)
		END AS job_end_time_local,
		CASE WHEN sysschedules.active_end_date = 99991231
			THEN @end_time_local
			ELSE CAST(msdb.dbo.agent_datetime(sysschedules.active_end_date, sysschedules.active_end_time) AS DATETIME)
		END AS job_end_datetime_local,
		sysjobs.date_created AS job_date_created_local,
		sysschedules.date_created AS schedule_date_created_local,
		'' AS job_schedule_description, -- To be populated later
		CASE
			WHEN sysschedules.freq_type = 1 THEN 1
			WHEN sysschedules.freq_type = 4 THEN 1
			WHEN sysschedules.freq_type = 8 THEN 1
			WHEN sysschedules.freq_type = 16 THEN 1
			WHEN sysschedules.freq_type = 32 THEN 1
			WHEN sysschedules.freq_type = 64 THEN 0
			WHEN sysschedules.freq_type = 128 THEN 0
		END AS job_count
	FROM msdb.dbo.sysjobschedules
	INNER JOIN msdb.dbo.sysjobs
	ON sysjobs.job_id = sysjobschedules.job_id
	INNER JOIN msdb.dbo.sysschedules
	ON sysschedules.schedule_id = sysjobschedules.schedule_id
	INNER JOIN msdb.dbo.syscategories
	ON syscategories.category_id = sysjobs.category_id
	WHERE sysschedules.enabled = 1
	AND sysjobs.enabled = 1
	AND syscategories.name NOT IN ('Notify on failures, but not missed runs', 'Do not notify on failures or missed runs')
	
	IF EXISTS (SELECT * FROM #job_summary WHERE job_frequency = 'ONE-TIME')
	BEGIN
		INSERT INTO #future_job_runs
			(job_id, schedule_uid, job_run_time_local)
		SELECT
			job_summary.job_id,
			job_summary.schedule_uid,
			job_summary.job_start_datetime_local AS job_run_time_local
		FROM #job_summary job_summary
		WHERE job_summary.job_frequency = 'ONE-TIME'
		AND job_summary.job_start_datetime_local BETWEEN @start_time_local AND @end_time_local
		AND job_summary.job_start_datetime_local >= job_summary.job_date_created_local
		AND job_summary.job_start_datetime_local >= job_summary.schedule_date_created_local;

		UPDATE job_summary
			SET job_schedule_description = 'One time, at ' + CAST(job_summary.job_start_datetime_local AS VARCHAR(MAX)) + ' local time.'
		FROM #job_summary job_summary
		WHERE job_summary.job_frequency = 'ONE-TIME';
	END

	DECLARE @job_counter UNIQUEIDENTIFIER;
	DECLARE @schedule_counter UNIQUEIDENTIFIER;
	DECLARE @datetime_counter DATETIME;
	DECLARE @job_frequency_subday_interval INT;
	DECLARE @active_start_datetime_local DATETIME;
	DECLARE @active_end_datetime_local DATETIME;
	DECLARE @active_start_time_local TIME;
	DECLARE @active_end_time_local TIME;
	DECLARE @job_frequency_interval INT;
	DECLARE @job_frequency_relative_interval VARCHAR(10);
	DECLARE @day_of_week_in_month TINYINT;

	-- Collect job schedule data one frequency type at a time.
	IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'DAILY')
	BEGIN
		-- Daily, once per day
		INSERT INTO #future_job_runs
			(job_id, schedule_uid, job_run_time_local)
		SELECT
			job_summary.job_id,
			job_summary.schedule_uid,
			CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) AS job_run_time_local
		FROM #job_summary job_summary
		CROSS JOIN #days_affected days_affected
		WHERE job_summary.job_frequency = 'DAILY'
		AND job_summary.job_date_created_local <= @start_time_local
		AND job_summary.schedule_date_created_local <= @start_time_local
		AND CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) BETWEEN @start_time_local AND @end_time_local
		AND CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) BETWEEN job_summary.job_start_datetime_local AND job_summary.job_end_datetime_local
		AND job_summary.job_frequency_subday_type IN ('UNUSED', 'AT_TIME')
		AND ((DATEPART(DW, days_affected.calendar_date) & job_summary.job_frequency_interval = 0 AND job_summary.job_frequency_interval > 1)
		      OR job_summary.job_frequency_interval = 1);
			 
		UPDATE job_summary
			SET job_schedule_description = 'Daily' + CASE WHEN job_summary.job_frequency_interval > 1 THEN ', every ' + CAST(job_summary.job_frequency_interval AS VARCHAR(MAX)) + ' days' ELSE '' END +			
			', at ' + LEFT(CAST(job_summary.job_start_time_local AS VARCHAR(MAX)), 8) + ' local time.'
		FROM #job_summary job_summary
		WHERE job_summary.job_frequency = 'DAILY'
		AND job_summary.job_frequency_subday_type IN ('UNUSED', 'AT_TIME');

		-- Daily, every N hours, minutes, or seconds
		IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'DAILY' AND job_summary.job_frequency_subday_type IN ('SECONDS', 'MINUTES', 'HOURS'))
		BEGIN
			DECLARE job_cursor CURSOR FOR
				SELECT
					job_summary.job_id,
					job_summary.schedule_uid,
					DATEADD(DAY, -1, CAST(CAST(@start_time_local AS DATE) AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME)) AS datetime_counter,
					CASE
						WHEN job_summary.job_frequency_subday_type = 'SECONDS' THEN job_summary.job_frequency_subday_interval
						WHEN job_summary.job_frequency_subday_type = 'MINUTES' THEN job_summary.job_frequency_subday_interval * 60
						WHEN job_summary.job_frequency_subday_type = 'HOURS' THEN job_summary.job_frequency_subday_interval * 3600
					END AS job_frequency_subday_interval,
					job_summary.job_start_datetime_local,
					job_summary.job_end_datetime_local,
					job_summary.job_start_time_local,
					job_summary.job_end_time_local,
					job_summary.job_frequency_interval
				FROM #job_summary job_summary
				WHERE job_summary.job_frequency = 'DAILY'
				AND job_summary.job_date_created_local <= @start_time_local
				AND job_summary.schedule_date_created_local <= @start_time_local
				AND job_summary.job_frequency_subday_type IN ('SECONDS', 'MINUTES', 'HOURS');
			OPEN job_cursor;
			FETCH NEXT FROM job_cursor INTO @job_counter, @schedule_counter, @datetime_counter, @job_frequency_subday_interval,
											@active_start_datetime_local, @active_end_datetime_local, @active_start_time_local,
											@active_end_time_local,	@job_frequency_interval;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				WHILE @datetime_counter < @start_time_local
				BEGIN
					SELECT @datetime_counter = DATEADD(SECOND, @job_frequency_subday_interval, @datetime_counter);
				END

				WHILE @datetime_counter <= @end_time_local
				BEGIN
					IF (@datetime_counter BETWEEN @active_start_datetime_local AND @active_end_datetime_local)
					AND ((@active_start_time_local <= @active_end_time_local AND CAST(@datetime_counter AS TIME) BETWEEN @active_start_time_local AND @active_end_time_local) OR
					(@active_start_time_local > @active_end_time_local AND 
					((CAST(@datetime_counter AS TIME) BETWEEN @active_start_time_local AND '23:59:59.999') OR CAST(@datetime_counter AS TIME) BETWEEN '00:00:00' AND @active_end_time_local)))
					AND ((DATEPART(DW, @datetime_counter) & @job_frequency_interval = 0 AND @job_frequency_interval > 1)
					      OR @job_frequency_interval = 1)
					BEGIN
						INSERT INTO #future_job_runs
							(job_id, schedule_uid, job_run_time_local)
						SELECT
							@job_counter,
							@schedule_counter,
							@datetime_counter AS job_run_time_local;
					END

					SELECT @datetime_counter = DATEADD(SECOND, @job_frequency_subday_interval, @datetime_counter);
				END

				UPDATE job_summary
					SET job_schedule_description = 'Daily' + CASE WHEN job_summary.job_frequency_interval > 1 THEN ', every ' + CAST(job_summary.job_frequency_interval AS VARCHAR(MAX)) + ' days' ELSE '' END +						
					', every ' + CASE WHEN @job_frequency_subday_interval >= 3600 THEN CAST(@job_frequency_subday_interval / 3600 AS VARCHAR(MAX)) + ' hour(s)'
																			   WHEN @job_frequency_subday_interval >= 60 THEN CAST(@job_frequency_subday_interval / 60 AS VARCHAR(MAX)) + ' minute(s)'
																			   ELSE CAST(@job_frequency_subday_interval AS VARCHAR(MAX)) + ' second(s)' END +
												   ' starting at ' + LEFT(CAST(job_summary.job_start_time_local AS VARCHAR(MAX)), 8) + ' local time' +
												   CASE WHEN @active_start_time_local <> '00:00:00' OR @active_end_time_local <> '23:59:59'
														THEN ', between the hours of ' + LEFT(CAST(@active_start_time_local AS VARCHAR(MAX)), 8) +
														' and ' + LEFT(CAST(@active_end_time_local AS VARCHAR(MAX)), 8) + ' local time' ELSE '' END +
												   CASE WHEN @active_start_datetime_local > @start_time_local OR @active_end_datetime_local < @end_time_local
														THEN ', between the dates of ' + CAST(CAST(@active_start_datetime_local AS DATE) AS VARCHAR(MAX)) +
														' and ' + CAST(CAST(@active_end_datetime_local AS DATE) AS VARCHAR(MAX)) ELSE '' END
				FROM #job_summary job_summary
				WHERE job_summary.job_id = @job_counter
				AND job_summary.schedule_uid = @schedule_counter;

				FETCH NEXT FROM job_cursor INTO @job_counter, @schedule_counter, @datetime_counter, @job_frequency_subday_interval,
												@active_start_datetime_local, @active_end_datetime_local, @active_start_time_local,
												@active_end_time_local,	@job_frequency_interval;
			END

			CLOSE job_cursor;
			DEALLOCATE job_cursor;
		END
	END

	IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'WEEKLY')
	BEGIN
		-- Schedules that are once per week.
		INSERT INTO #future_job_runs
			(job_id, schedule_uid, job_run_time_local)
		SELECT
			job_summary.job_id,
			job_summary.schedule_uid,
			CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) AS job_run_time_local
		FROM #job_summary job_summary
		CROSS JOIN #days_affected days_affected
		WHERE job_summary.job_frequency = 'WEEKLY'
		AND job_summary.job_date_created_local <= @start_time_local
		AND job_summary.schedule_date_created_local <= @start_time_local
		AND CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) BETWEEN @start_time_local AND @end_time_local
		AND CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) BETWEEN job_summary.job_start_datetime_local AND job_summary.job_end_datetime_local
		AND job_summary.job_frequency_subday_type IN ('UNUSED', 'AT_TIME')
		AND job_summary.job_frequency_interval & POWER(2, DATEPART(DW, days_affected.calendar_date) - 1) = POWER(2, DATEPART(DW, days_affected.calendar_date) - 1);

		UPDATE job_summary
			SET job_schedule_description = 'Weekly, on ' + LEFT(CASE WHEN job_summary.job_frequency_interval & 1 = 1 THEN 'Sunday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 2 = 2 THEN 'Monday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 4 = 4 THEN 'Tuesday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 8 = 8 THEN 'Wednesday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 16 = 16 THEN 'Thursday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 32 = 32 THEN 'Friday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 64 = 64 THEN 'Saturday, ' ELSE '' END, LEN(CASE WHEN job_summary.job_frequency_interval & 1 = 1 THEN 'Sunday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 2 = 2 THEN 'Monday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 4 = 4 THEN 'Tuesday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 8 = 8 THEN 'Wednesday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 16 = 16 THEN 'Thursday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 32 = 32 THEN 'Friday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 64 = 64 THEN 'Saturday, ' ELSE '' END) - 1) + 
											' at ' + LEFT(CAST(job_summary.job_start_time_local AS VARCHAR(MAX)), 8) + ' local time.'
		FROM #job_summary job_summary
		WHERE job_summary.job_frequency = 'WEEKLY'
		AND job_summary.job_frequency_subday_type IN ('UNUSED', 'AT_TIME');

		-- Schedules that are weekly, but every N seconds, minutes, or hours.
		IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'WEEKLY' AND job_summary.job_frequency_subday_type IN ('SECONDS', 'MINUTES', 'HOURS'))
		BEGIN
			DECLARE job_cursor CURSOR FOR
				SELECT
					job_summary.job_id,
					job_summary.schedule_uid,
					DATEADD(DAY, -1, CAST(CAST(@start_time_local AS DATE) AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME)),
					CASE
						WHEN job_summary.job_frequency_subday_type = 'SECONDS' THEN job_summary.job_frequency_subday_interval
						WHEN job_summary.job_frequency_subday_type = 'MINUTES' THEN job_summary.job_frequency_subday_interval * 60
						WHEN job_summary.job_frequency_subday_type = 'HOURS' THEN job_summary.job_frequency_subday_interval * 3600
					END,
					job_summary.job_frequency_interval,
					job_summary.job_start_datetime_local,
					job_summary.job_end_datetime_local,
					job_summary.job_start_time_local,
					job_summary.job_end_time_local
				FROM #job_summary job_summary
				WHERE job_summary.job_frequency = 'WEEKLY'
				AND job_summary.job_date_created_local <= @start_time_local
				AND job_summary.schedule_date_created_local <= @start_time_local
				AND job_summary.job_frequency_subday_type IN ('SECONDS', 'MINUTES', 'HOURS');				
			OPEN job_cursor;
			FETCH NEXT FROM job_cursor INTO @job_counter, @schedule_counter, @datetime_counter, @job_frequency_subday_interval, @job_frequency_interval,
											@active_start_datetime_local, @active_end_datetime_local, @active_start_time_local, @active_end_time_local;
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				WHILE @datetime_counter < @start_time_local
				BEGIN
					SELECT @datetime_counter = DATEADD(SECOND, @job_frequency_subday_interval, @datetime_counter);
				END
-- HERE!!!!!!
				WHILE @datetime_counter <= @end_time_local
				BEGIN
					IF @job_frequency_interval & POWER(2, DATEPART(DW, @datetime_counter) - 1) = POWER(2, DATEPART(DW, @datetime_counter) - 1)
					AND (@datetime_counter BETWEEN @active_start_datetime_local AND @active_end_datetime_local)
					AND ((@active_start_time_local <= @active_end_time_local AND CAST(@datetime_counter AS TIME) BETWEEN @active_start_time_local AND @active_end_time_local) OR
					(@active_start_time_local > @active_end_time_local AND 
					((CAST(@datetime_counter AS TIME) BETWEEN @active_start_time_local AND '23:59:59.999') OR CAST(@datetime_counter AS TIME) BETWEEN '00:00:00' AND @active_end_time_local)))
					BEGIN
						INSERT INTO #future_job_runs
							(job_id, schedule_uid, job_run_time_local)
						SELECT
							@job_counter,
							@schedule_counter,
							@datetime_counter AS job_run_time_local;
					END

					SELECT @datetime_counter = DATEADD(SECOND, @job_frequency_subday_interval, @datetime_counter);
				END

				UPDATE job_summary
					SET job_schedule_description = 'Weekly, on ' + LEFT(CASE WHEN job_summary.job_frequency_interval & 1 = 1 THEN 'Sunday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 2 = 2 THEN 'Monday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 4 = 4 THEN 'Tuesday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 8 = 8 THEN 'Wednesday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 16 = 16 THEN 'Thursday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 32 = 32 THEN 'Friday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 64 = 64 THEN 'Saturday, ' ELSE '' END, LEN(CASE WHEN job_summary.job_frequency_interval & 1 = 1 THEN 'Sunday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 2 = 2 THEN 'Monday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 4 = 4 THEN 'Tuesday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 8 = 8 THEN 'Wednesday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 16 = 16 THEN 'Thursday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 32 = 32 THEN 'Friday, ' ELSE '' END +
														   CASE WHEN job_summary.job_frequency_interval & 64 = 64 THEN 'Saturday, ' ELSE '' END) - 1) + 
											', every ' + CASE WHEN @job_frequency_subday_interval >= 3600 THEN CAST(@job_frequency_subday_interval / 3600 AS VARCHAR(MAX)) + ' hour(s)'
																			   WHEN @job_frequency_subday_interval >= 60 THEN CAST(@job_frequency_subday_interval / 60 AS VARCHAR(MAX)) + ' minute(s)'
																			   ELSE CAST(@job_frequency_subday_interval AS VARCHAR(MAX)) + ' second(s)' END +
												   ' starting at ' + LEFT(CAST(job_summary.job_start_time_local AS VARCHAR(MAX)), 8) + ' local time.' +
											CASE WHEN @active_start_time_local <> '00:00:00' OR @active_end_time_local <> '23:59:59'
												THEN ', between the hours of ' + LEFT(CAST(@active_start_time_local AS VARCHAR(MAX)), 8) +
												' and ' + LEFT(CAST(@active_end_time_local AS VARCHAR(MAX)), 8) ELSE '' END +
											CASE WHEN @active_start_datetime_local > @start_time_local OR @active_end_datetime_local < @end_time_local
												THEN ', between the dates of ' + CAST(CAST(@active_start_datetime_local AS DATE) AS VARCHAR(MAX)) +
												' and ' + CAST(CAST(@active_end_datetime_local AS DATE) AS VARCHAR(MAX)) ELSE '' END
				FROM #job_summary job_summary
				WHERE job_summary.job_id = @job_counter
				AND job_summary.schedule_uid = @schedule_counter;

				FETCH NEXT FROM job_cursor INTO @job_counter, @schedule_counter, @datetime_counter, @job_frequency_subday_interval, @job_frequency_interval,
												@active_start_datetime_local, @active_end_datetime_local, @active_start_time_local, @active_end_time_local;		
			END

			CLOSE job_cursor;
			DEALLOCATE job_cursor;
		END
	END

	IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'MONTHLY')
	BEGIN
		-- Monthly schedules that run once per month on a given day.
		INSERT INTO #future_job_runs
			(job_id, schedule_uid, job_run_time_local)
		SELECT
			job_summary.job_id,
			job_summary.schedule_uid,
			CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) AS job_run_time_local
		FROM #job_summary job_summary
		CROSS JOIN #days_affected days_affected
		WHERE job_summary.job_frequency = 'MONTHLY'
		AND job_summary.job_date_created_local <= @start_time_local
		AND job_summary.schedule_date_created_local <= @start_time_local
		AND CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) BETWEEN @start_time_local AND @end_time_local
		AND CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) BETWEEN job_summary.job_start_datetime_local AND job_summary.job_end_datetime_local
		AND job_summary.job_frequency_subday_type IN ('UNUSED', 'AT_TIME')
		AND DATEPART(DAY, days_affected.calendar_date) = job_summary.job_frequency_interval
		AND job_summary.job_frequency_relative_interval = 'UNUSED'
		AND job_summary.job_frequency_recurrence_factor = 1;

		UPDATE job_summary
			SET job_schedule_description = 'Monthly, on day ' + CAST(job_summary.job_frequency_interval AS VARCHAR(MAX)) + ' of the month' +
											' at ' + LEFT(CAST(job_summary.job_start_time_local AS VARCHAR(MAX)), 8) + ' local time.'
		FROM #job_summary job_summary
		WHERE job_summary.job_frequency = 'MONTHLY'
		AND job_summary.job_frequency_subday_type IN ('UNUSED', 'AT_TIME')
		AND job_summary.job_frequency_recurrence_factor = 1;

		-- Monthly schedules that run monthly on a given day, but multiple times.
		IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'MONTHLY' AND job_summary.job_frequency_subday_type IN ('SECONDS', 'MINUTES', 'HOURS') AND job_summary.job_frequency_recurrence_factor = 1)
		BEGIN
			DECLARE job_cursor CURSOR FOR
				SELECT
					job_summary.job_id,
					job_summary.schedule_uid,
					DATEADD(DAY, job_summary.job_frequency_interval - 1, DATEADD(DAY, -1 * DATEPART(DAY, CAST(@start_time_local AS DATE)) + 1, CAST(CAST(@start_time_local AS DATE) AS DATETIME))) + CAST(job_summary.job_start_time_local AS DATETIME),
					CASE
						WHEN job_summary.job_frequency_subday_type = 'SECONDS' THEN job_summary.job_frequency_subday_interval
						WHEN job_summary.job_frequency_subday_type = 'MINUTES' THEN job_summary.job_frequency_subday_interval * 60
						WHEN job_summary.job_frequency_subday_type = 'HOURS' THEN job_summary.job_frequency_subday_interval * 3600
					END,
					job_summary.job_frequency_interval,
					job_summary.job_start_datetime_local,
					job_summary.job_end_datetime_local,
					job_summary.job_start_time_local,
					job_summary.job_end_time_local
				FROM #job_summary job_summary
				WHERE job_summary.job_frequency = 'MONTHLY'
				AND job_summary.job_frequency_subday_type IN ('SECONDS', 'MINUTES', 'HOURS')
				AND job_summary.job_frequency_recurrence_factor = 1
				AND job_summary.job_frequency_relative_interval = 'UNUSED'
				AND job_summary.job_date_created_local <= @start_time_local
				AND job_summary.schedule_date_created_local <= @start_time_local;		
			OPEN job_cursor;
			FETCH NEXT FROM job_cursor INTO @job_counter, @schedule_counter, @datetime_counter, @job_frequency_subday_interval, @job_frequency_interval,
											@active_start_datetime_local, @active_end_datetime_local, @active_start_time_local, @active_end_time_local;
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				WHILE @datetime_counter < @start_time_local
				BEGIN
					SELECT @datetime_counter = DATEADD(SECOND, @job_frequency_subday_interval, @datetime_counter);
				END

				WHILE @datetime_counter <= @end_time_local
				BEGIN
					IF (@datetime_counter BETWEEN @active_start_datetime_local AND @active_end_datetime_local)
					AND DATEPART(DAY, @datetime_counter) = @job_frequency_interval
					AND ((@active_start_time_local <= @active_end_time_local AND CAST(@datetime_counter AS TIME) BETWEEN @active_start_time_local AND @active_end_time_local) OR
					(@active_start_time_local > @active_end_time_local AND ((CAST(@datetime_counter AS TIME) BETWEEN @active_start_time_local AND '23:59:59.999') OR CAST(@datetime_counter AS TIME) BETWEEN '00:00:00' AND @active_end_time_local)))
					BEGIN
						INSERT INTO #future_job_runs
							(job_id, schedule_uid, job_run_time_local)
						SELECT
							@job_counter,
							@schedule_counter,
							@datetime_counter AS job_run_time_local;
					END

					SELECT @datetime_counter = DATEADD(SECOND, @job_frequency_subday_interval, @datetime_counter);
				END

				UPDATE job_summary
					SET job_schedule_description = 'Monthly, on day ' + CAST(job_summary.job_frequency_interval AS VARCHAR(MAX)) + ' of the month' +
												', every ' + CASE WHEN @job_frequency_subday_interval >= 3600 THEN CAST(@job_frequency_subday_interval / 3600 AS VARCHAR(MAX)) + ' hour(s)'
																				   WHEN @job_frequency_subday_interval >= 60 THEN CAST(@job_frequency_subday_interval / 60 AS VARCHAR(MAX)) + ' minute(s)'
																				   ELSE CAST(@job_frequency_subday_interval AS VARCHAR(MAX)) + ' second(s)' END +
													   ' starting at ' + LEFT(CAST(job_summary.job_start_time_local AS VARCHAR(MAX)), 8) + ' local time.' +
												CASE WHEN @active_start_time_local <> '00:00:00' OR @active_end_time_local <> '23:59:59'
													THEN ', between the hours of ' + LEFT(CAST(@active_start_time_local AS VARCHAR(MAX)), 8) +
													' and ' + LEFT(CAST(@active_end_time_local AS VARCHAR(MAX)), 8) ELSE '' END +
												CASE WHEN @active_start_datetime_local > @start_time_local OR @active_end_datetime_local < @end_time_local
													THEN ', between the dates of ' + CAST(CAST(@active_start_datetime_local AS DATE) AS VARCHAR(MAX)) +
													' and ' + CAST(CAST(@active_end_datetime_local AS DATE) AS VARCHAR(MAX)) ELSE '' END
				FROM #job_summary job_summary
				WHERE job_summary.job_id = @job_counter
				AND job_summary.schedule_uid = @schedule_counter;

				FETCH NEXT FROM job_cursor INTO @job_counter, @schedule_counter, @datetime_counter, @job_frequency_subday_interval, @job_frequency_interval,
												@active_start_datetime_local, @active_end_datetime_local, @active_start_time_local, @active_end_time_local;		
			END

			CLOSE job_cursor;
			DEALLOCATE job_cursor;
		END
	END

	-- Pull data for schedules that occur on a specific day within the month (ie: 1st Friday, 3rd Tuesday, last Monday)
	IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'MONTHLY-RELATIVE')
	BEGIN
		-- Monthly schedules that run once per month on a given day.
		INSERT INTO #future_job_runs
			(job_id, schedule_uid, job_run_time_local)
		SELECT
			job_summary.job_id,
			job_summary.schedule_uid,
			CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) AS job_run_time_local
		FROM #job_summary job_summary
		CROSS JOIN #days_affected days_affected
		INNER JOIN dbo.Dim_Date
		ON days_affected.calendar_date = Dim_Date.Calendar_Date
		WHERE job_summary.job_frequency = 'MONTHLY-RELATIVE'
		AND job_summary.job_date_created_local <= @start_time_local
		AND job_summary.schedule_date_created_local <= @start_time_local
		AND CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) BETWEEN @start_time_local AND @end_time_local
		AND CAST(days_affected.calendar_date AS DATETIME) + CAST(job_summary.job_start_time_local AS DATETIME) BETWEEN job_summary.job_start_datetime_local AND job_summary.job_end_datetime_local
		AND job_summary.job_frequency_subday_type IN ('UNUSED', 'AT_TIME')
		AND Dim_Date.Day_of_Week = job_summary.job_frequency_interval
		AND job_summary.job_frequency_relative_interval IN ('FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST')
		AND Dim_Date.Day_of_Week_in_Month = CASE
												WHEN job_summary.job_frequency_relative_interval = 'FIRST' THEN 1
												WHEN job_summary.job_frequency_relative_interval = 'SECOND' THEN 2
												WHEN job_summary.job_frequency_relative_interval = 'THIRD' THEN 3
												WHEN job_summary.job_frequency_relative_interval = 'FOURTH' THEN 4
												WHEN job_summary.job_frequency_relative_interval = 'LAST' THEN (SELECT MAX(MAX_CHECK.Day_of_Week_in_Month) FROM Dim_Date MAX_CHECK
																												WHERE MAX_CHECK.Calendar_Month = Dim_Date.Calendar_Month
																												AND MAX_CHECK.Calendar_Year = Dim_Date.Calendar_Year
																												AND MAX_CHECK.Day_of_Week = Dim_Date.Day_of_Week)
											END
		AND job_summary.job_frequency_recurrence_factor = 1;
		
		UPDATE job_summary
			SET job_schedule_description = 'Monthly, on the ' + job_summary.job_frequency_relative_interval +
										   CASE WHEN job_summary.job_frequency_interval = 1 THEN ' Sunday' WHEN job_summary.job_frequency_interval = 2 THEN ' Monday'
												WHEN job_summary.job_frequency_interval = 3 THEN ' Tuesday' WHEN job_summary.job_frequency_interval = 4 THEN ' Wednesday'
												WHEN job_summary.job_frequency_interval = 5 THEN ' Thursday' WHEN job_summary.job_frequency_interval = 6 THEN ' Friday'
												WHEN job_summary.job_frequency_interval = 7 THEN ' Saturday' END + ' of the month' +
											' at ' + LEFT(CAST(job_summary.job_start_time_local AS VARCHAR(MAX)), 8) + ' local time.'
		FROM #job_summary job_summary
		WHERE job_summary.job_frequency = 'MONTHLY-RELATIVE'
		AND job_summary.job_frequency_subday_type IN ('UNUSED', 'AT_TIME')
		AND job_summary.job_frequency_recurrence_factor = 1;

		-- Monthly schedules that run monthly on a given day, but multiple times.
		IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'MONTHLY-RELATIVE' AND job_summary.job_frequency_subday_type IN ('SECONDS', 'MINUTES', 'HOURS') AND job_summary.job_frequency_recurrence_factor = 1)
		BEGIN
			DECLARE job_cursor CURSOR FOR
				SELECT
					job_summary.job_id,
					job_summary.schedule_uid,
					DATEADD(DAY, job_summary.job_frequency_interval - 1, DATEADD(DAY, -1 * DATEPART(DAY, CAST(@start_time_local AS DATE)) + 1, CAST(CAST(@start_time_local AS DATE) AS DATETIME))) + CAST(job_summary.job_start_time_local AS DATETIME),
					CASE
						WHEN job_summary.job_frequency_subday_type = 'SECONDS' THEN job_summary.job_frequency_subday_interval
						WHEN job_summary.job_frequency_subday_type = 'MINUTES' THEN job_summary.job_frequency_subday_interval * 60
						WHEN job_summary.job_frequency_subday_type = 'HOURS' THEN job_summary.job_frequency_subday_interval * 3600
					END,
					job_summary.job_frequency_interval,
					job_summary.job_start_datetime_local,
					job_summary.job_end_datetime_local,
					job_summary.job_start_time_local,
					job_summary.job_end_time_local,
					job_summary.job_frequency_relative_interval
				FROM #job_summary job_summary
				WHERE job_summary.job_frequency = 'MONTHLY-RELATIVE'
				AND job_summary.job_frequency_subday_type IN ('SECONDS', 'MINUTES', 'HOURS')
				AND job_summary.job_frequency_recurrence_factor = 1
				AND job_summary.job_frequency_relative_interval IN ('FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST')
				AND job_summary.job_date_created_local <= @start_time_local
				AND job_summary.schedule_date_created_local <= @start_time_local;		
			OPEN job_cursor;
			FETCH NEXT FROM job_cursor INTO @job_counter, @schedule_counter, @datetime_counter, @job_frequency_subday_interval, @job_frequency_interval,
											@active_start_datetime_local, @active_end_datetime_local, @active_start_time_local, @active_end_time_local, @job_frequency_relative_interval;
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				WHILE @datetime_counter < @start_time_local
				BEGIN
					SELECT @datetime_counter = DATEADD(SECOND, @job_frequency_subday_interval, @datetime_counter);
				END

				WHILE @datetime_counter <= @end_time_local
				BEGIN
					SELECT @day_of_week_in_month = (SELECT Dim_Date.Day_of_Week_in_Month FROM dbo.Dim_Date WHERE Dim_Date.Calendar_Date = CAST(@datetime_counter AS DATE));
					IF @job_frequency_interval = DATEPART(DW, @datetime_counter) AND
					(@datetime_counter BETWEEN @active_start_datetime_local AND @active_end_datetime_local)
					AND ((@active_start_time_local <= @active_end_time_local AND CAST(@datetime_counter AS TIME) BETWEEN @active_start_time_local AND @active_end_time_local) OR
					(@active_start_time_local > @active_end_time_local AND ((CAST(@datetime_counter AS TIME) BETWEEN @active_start_time_local AND '23:59:59.999') OR CAST(@datetime_counter AS TIME) BETWEEN '00:00:00' AND @active_end_time_local)))
					AND @day_of_week_in_month = CASE
													WHEN @job_frequency_relative_interval = 'FIRST' THEN 1
													WHEN @job_frequency_relative_interval = 'SECOND' THEN 2
													WHEN @job_frequency_relative_interval = 'THIRD' THEN 3
													WHEN @job_frequency_relative_interval = 'FOURTH' THEN 4
													WHEN @job_frequency_relative_interval = 'LAST' THEN (SELECT MAX(MAX_CHECK.Day_of_Week_in_Month) FROM Dim_Date MAX_CHECK
																													WHERE MAX_CHECK.Calendar_Month = DATEPART(MONTH, @datetime_counter)
																													AND MAX_CHECK.Calendar_Year = DATEPART(YEAR, @datetime_counter)
																													AND MAX_CHECK.Day_of_Week = DATEPART(DW, @datetime_counter))
												END
					BEGIN
						INSERT INTO #future_job_runs
							(job_id, schedule_uid, job_run_time_local)
						SELECT
							@job_counter,
							@schedule_counter,
							@datetime_counter AS job_run_time_local;
					END

					SELECT @datetime_counter = DATEADD(SECOND, @job_frequency_subday_interval, @datetime_counter);
				END

				UPDATE job_summary
					SET job_schedule_description = 'Monthly, on the ' + job_summary.job_frequency_relative_interval +
												   CASE WHEN job_summary.job_frequency_interval = 1 THEN ' Sunday' WHEN job_summary.job_frequency_interval = 2 THEN ' Monday'
														WHEN job_summary.job_frequency_interval = 3 THEN ' Tuesday' WHEN job_summary.job_frequency_interval = 4 THEN ' Wednesday'
														WHEN job_summary.job_frequency_interval = 5 THEN ' Thursday' WHEN job_summary.job_frequency_interval = 6 THEN ' Friday'
														WHEN job_summary.job_frequency_interval = 7 THEN ' Saturday' END + ' of the month' +
												', every ' + CASE WHEN @job_frequency_subday_interval >= 3600 THEN CAST(@job_frequency_subday_interval / 3600 AS VARCHAR(MAX)) + ' hour(s)'
																				   WHEN @job_frequency_subday_interval >= 60 THEN CAST(@job_frequency_subday_interval / 60 AS VARCHAR(MAX)) + ' minute(s)'
																				   ELSE CAST(@job_frequency_subday_interval AS VARCHAR(MAX)) + ' second(s)' END +
													   ' starting at ' + LEFT(CAST(job_summary.job_start_time_local AS VARCHAR(MAX)), 8) + ' local time' +
												CASE WHEN @active_start_time_local <> '00:00:00' OR @active_end_time_local <> '23:59:59'
													THEN ', between the hours of ' + LEFT(CAST(@active_start_time_local AS VARCHAR(MAX)), 8) +
													' and ' + LEFT(CAST(@active_end_time_local AS VARCHAR(MAX)), 8) ELSE '' END +
												CASE WHEN @active_start_datetime_local > @start_time_local OR @active_end_datetime_local< @end_time_local
													THEN ', between the dates of ' + CAST(CAST(@active_start_datetime_local AS DATE) AS VARCHAR(MAX)) +
													' and ' + CAST(CAST(@active_end_datetime_local AS DATE) AS VARCHAR(MAX)) ELSE '' END
				FROM #job_summary job_summary
				WHERE job_summary.job_id = @job_counter
				AND job_summary.schedule_uid = @schedule_counter;

				FETCH NEXT FROM job_cursor INTO @job_counter, @schedule_counter, @datetime_counter, @job_frequency_subday_interval, @job_frequency_interval,
												@active_start_datetime_local, @active_end_datetime_local, @active_start_time_local, @active_end_time_local, @job_frequency_relative_interval;
			END

			CLOSE job_cursor;
			DEALLOCATE job_cursor;
		END
	END

	IF @include_startup_and_idle_jobs_in_summary_data = 1
	BEGIN
		IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'COMPUTER IDLE')
		BEGIN
			INSERT INTO #future_job_runs
				(job_id, schedule_uid, job_run_time_local)
			SELECT
				job_summary.job_id,
				job_summary.schedule_uid,
				'1/1/1901' AS job_run_time_local
			FROM #job_summary job_summary
			WHERE job_summary.job_frequency = 'COMPUTER IDLE';

			UPDATE job_summary
				SET job_schedule_description = 'Runs when computer is idle.'
			FROM #job_summary job_summary
			WHERE job_summary.job_frequency = 'COMPUTER IDLE';
		END

		IF EXISTS (SELECT * FROM #job_summary job_summary WHERE job_summary.job_frequency = 'AGENT STARTUP')
		BEGIN
			INSERT INTO #future_job_runs
				(job_id, schedule_uid, job_run_time_local)
			SELECT
				job_summary.job_id,
				job_summary.schedule_uid,
				'1/1/1901' AS job_run_time_local
			FROM #job_summary job_summary
			WHERE job_summary.job_frequency = 'AGENT STARTUP';

			UPDATE job_summary
				SET job_schedule_description = 'Runs when SQL Server Agent starts.'
			FROM #job_summary job_summary
			WHERE job_summary.job_frequency = 'AGENT STARTUP';
		END
	END

	DELETE future_job_runs
	FROM #future_job_runs future_job_runs
	WHERE future_job_runs.job_run_time_local NOT BETWEEN @start_time_local AND @end_time_local;
	
	IF @return_summarized_data = 1
	BEGIN
		SELECT
			 job_summary.job_id,
			 job_summary.job_name,
			 MIN(job_run_time_local) AS first_job_run_time_local,
			 MAX(job_run_time_local) AS last_job_run_time_local,
			 SUM(job_summary.job_count) AS count_of_events_during_time_period,
			 job_summary.job_schedule_description
		FROM #future_job_runs future_job_runs
		INNER JOIN #job_summary job_summary
		ON future_job_runs.job_id = job_summary.job_id
		AND job_summary.schedule_uid = future_job_runs.schedule_uid
		GROUP BY job_summary.job_id, job_summary.job_name, job_summary.job_schedule_description
		ORDER BY job_summary.job_name, job_summary.job_schedule_description;
	END
	ELSE
	BEGIN
		SELECT
			job_summary.job_id,
			job_summary.job_name,
			future_job_runs.job_run_time_local,
			job_summary.job_schedule_description
		FROM #future_job_runs future_job_runs
		INNER JOIN #job_summary job_summary
		ON future_job_runs.job_id = job_summary.job_id
		AND job_summary.schedule_uid = future_job_runs.schedule_uid
		ORDER BY job_summary.job_name, job_summary.job_schedule_description;
	END

	DROP TABLE #days_affected;
	DROP TABLE #job_summary;
	DROP TABLE #future_job_runs;
END
GO

EXEC dbo.generate_job_schedule_data
	@start_time_utc = NULL,
	@end_time_utc = NULL,
	@start_time_local = '1/21/2019 00:00:00',
	@end_time_local = '1/21/2019 02:00:00',
	@return_summarized_data = 1,
	@include_startup_and_idle_jobs_in_summary_data = 0;

EXEC dbo.generate_job_schedule_data
	@start_time_utc = NULL,
	@end_time_utc = NULL,
	@start_time_local = '1/21/2019 00:00:00',
	@end_time_local = '1/21/2019 02:00:00',
	@return_summarized_data = 1,
	@include_startup_and_idle_jobs_in_summary_data = 1;

EXEC dbo.generate_job_schedule_data
	@start_time_utc = '1/21/2019 05:00:00',
	@end_time_utc = '1/21/2019 07:00:00',
	@start_time_local = NULL,
	@end_time_local = NULL,
	@return_summarized_data = 1,
	@include_startup_and_idle_jobs_in_summary_data = 1;

EXEC dbo.generate_job_schedule_data
	@start_time_utc = '1/21/2019 05:00:00',
	@end_time_utc = '1/21/2019 07:00:00',
	@start_time_local = NULL,
	@end_time_local = NULL,
	@return_summarized_data = 0,
	@include_startup_and_idle_jobs_in_summary_data = 0;