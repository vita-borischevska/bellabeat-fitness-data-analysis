-- ====================================================================
-- Project: Bellabeat Fitbit Data Analysis
-- Engine:  DuckDB
-- Author:  Vita Borychevska
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. DATA INGESTION
-- --------------------------------------------------------------------

CREATE OR REPLACE TABLE daily_activity AS 
SELECT *
FROM read_csv_auto('/Users/vitaborychevska/Desktop/Bellabeats data/mturkfitbit_export_3.12.16-4.11.16/Fitabase_Data_3.12.16-4.11.16/dailyActivity_merged.csv');

CREATE OR REPLACE TABLE minute_sleep AS
SELECT *
FROM read_csv_auto('/Users/vitaborychevska/Desktop/Bellabeats data/mturkfitbit_export_3.12.16-4.11.16/Fitabase_Data_3.12.16-4.11.16/minuteSleep_merged.csv');

-- Quick inspection
SELECT * FROM daily_activity LIMIT 10;
DESCRIBE daily_activity;
SELECT COUNT(*) AS total_raw_records FROM daily_activity;
SELECT COUNT(DISTINCT Id) AS total_unique_users FROM daily_activity;

-- --------------------------------------------------------------------
-- 2. DATA AUDIT & INTEGRITY CHECKS
-- --------------------------------------------------------------------

-- Null count verification across core metrics
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(Id) AS id_missing,
    COUNT(*) - COUNT(ActivityDate) AS date_missing,
    COUNT(*) - COUNT(TotalSteps) AS steps_missing, 
    COUNT(*) - COUNT(TotalDistance) AS distance_missing,
    COUNT(*) - COUNT(Calories) AS calories_missing,
    COUNT(*) - COUNT(VeryActiveMinutes) AS very_active_missing,
    COUNT(*) - COUNT(FairlyActiveMinutes) AS fairly_active_missing,
    COUNT(*) - COUNT(LightlyActiveMinutes) AS lightly_active_missing,
    COUNT(*) - COUNT(SedentaryMinutes) AS sedentary_missing
FROM daily_activity;

-- Duplicate check by user and date
SELECT
    Id,
    ActivityDate,
    COUNT(*) AS duplicate_records
FROM daily_activity
GROUP BY Id, ActivityDate
HAVING COUNT(*) > 1;

-- Logging frequency per user
SELECT 
    Id,
    COUNT(ActivityDate) AS days_recorded
FROM daily_activity
GROUP BY Id
ORDER BY days_recorded;

-- Summary stats of tracking duration per user
SELECT
    MIN(days_recorded) AS min_days_recorded,
    MAX(days_recorded) AS max_days_recorded,
    ROUND(AVG(days_recorded), 1) AS avg_days_recorded
FROM (
    SELECT Id, COUNT(ActivityDate) AS days_recorded
    FROM daily_activity
    GROUP BY Id
);

-- Value range checks for anomalies
SELECT
    MIN(TotalSteps) AS min_steps,
    MAX(TotalSteps) AS max_steps,
    ROUND(AVG(TotalSteps), 0) AS avg_steps
FROM daily_activity;

SELECT
    MIN(TotalDistance) AS min_distance,
    MAX(TotalDistance) AS max_distance,
    ROUND(AVG(TotalDistance), 2) AS avg_distance
FROM daily_activity;

SELECT
    MIN(Calories) AS min_calories,
    MAX(Calories) AS max_calories,
    ROUND(AVG(Calories), 0) AS avg_calories
FROM daily_activity;

-- Check for unrealistic negative values
SELECT *
FROM daily_activity
WHERE TotalSteps < 0 
   OR TotalDistance < 0 
   OR Calories < 0;

-- --------------------------------------------------------------------
-- 3. DATA CLEANING & REFINEMENT
-- --------------------------------------------------------------------

-- Create refined activity table
CREATE OR REPLACE TABLE daily_activity_clean AS 
SELECT 
    Id,
    ActivityDate,
    TotalSteps,
    TotalDistance,
    Calories,
    VeryActiveMinutes,
    FairlyActiveMinutes,
    LightlyActiveMinutes,
    SedentaryMinutes
FROM daily_activity;

-- Aggregate sleep minutes into sleep sessions
CREATE OR REPLACE TABLE sleep_clean AS 
SELECT 
    Id,
    logId,
    COUNT(*) AS sleep_minutes
FROM minute_sleep
GROUP BY Id, logId;

-- User-level average daily sleep
CREATE OR REPLACE TABLE sleep_daily AS
SELECT
    Id,
    ROUND(AVG(sleep_minutes) / 60, 1) AS average_sleep_hours
FROM sleep_clean
GROUP BY Id;

-- Filter for reliable sleep users (at least 10 logged sessions)
CREATE OR REPLACE TABLE sleep_reliable AS
SELECT
    Id,
    AVG(sleep_minutes) AS avg_sleep_minutes
FROM sleep_clean
GROUP BY Id
HAVING COUNT(logId) >= 10;

-- --------------------------------------------------------------------
-- 4. EXPLORATORY & STATISTICAL ANALYSIS
-- --------------------------------------------------------------------

-- Overall cohort baseline metrics
SELECT
    ROUND(AVG(TotalSteps), 0) AS avg_steps,
    ROUND(AVG(TotalDistance), 2) AS avg_distance_km,
    ROUND(AVG(Calories), 0) AS avg_calories,
    ROUND(AVG(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes), 0) AS avg_active_minutes,
    ROUND(AVG(SedentaryMinutes), 0) AS avg_sedentary_minutes,
    ROUND(AVG(SedentaryMinutes) / 60, 1) AS avg_sedentary_hours
FROM daily_activity_clean;

-- Correlation between total steps and calories burned
SELECT CORR(TotalSteps, Calories) AS step_calorie_correlation
FROM daily_activity_clean;

-- Correlation between steps and sleep hours (all users)
SELECT CORR(average_steps, average_sleep_hours) AS steps_sleep_correlation
FROM (
    SELECT
        a.Id,
        ROUND(AVG(a.TotalSteps), 0) AS average_steps,
        s.average_sleep_hours
    FROM daily_activity_clean a
    JOIN sleep_daily s ON a.Id = s.Id
    GROUP BY a.Id, s.average_sleep_hours
);

-- Correlation between steps and sleep hours (reliable cohort: >= 10 logs)
SELECT CORR(average_steps, average_sleep_hours) AS clean_steps_sleep_correlation
FROM (
    SELECT
        a.Id,
        AVG(a.TotalSteps) AS average_steps,
        s.avg_sleep_minutes / 60 AS average_sleep_hours
    FROM daily_activity_clean a
    JOIN sleep_reliable s ON a.Id = s.Id
    GROUP BY a.Id, s.avg_sleep_minutes
);

-- --------------------------------------------------------------------
-- 5. VISUALIZATION TABLES (EXPORT PREPARATION)
-- --------------------------------------------------------------------

-- 1. User segmentation by step volume
CREATE OR REPLACE TABLE viz_activity_segments AS 
WITH user_activity AS (
    SELECT
        Id,
        ROUND(AVG(TotalSteps), 0) AS avg_steps
    FROM daily_activity_clean
    GROUP BY Id
)
SELECT
    CASE 
        WHEN avg_steps < 5000 THEN 'Low Activity'
        WHEN avg_steps BETWEEN 5000 AND 10000 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END AS activity_level,
    COUNT(*) AS number_of_users
FROM user_activity
GROUP BY activity_level;

-- 2. Day-of-week behavioral trends
CREATE OR REPLACE TABLE viz_weekday_activity AS
SELECT
    DAYNAME(ActivityDate) AS weekday,
    ROUND(AVG(TotalSteps), 0) AS average_steps,
    ROUND(AVG(Calories), 0) AS average_calories
FROM daily_activity_clean
GROUP BY weekday
ORDER BY average_steps DESC;

-- 3. Sedentary time summary
CREATE OR REPLACE TABLE viz_sedentary AS 
SELECT
    ROUND(AVG(SedentaryMinutes), 0) AS average_sedentary_minutes,
    ROUND(AVG(SedentaryMinutes) / 60, 1) AS average_sedentary_hours
FROM daily_activity_clean;

-- 4. User-level step and calorie totals
CREATE OR REPLACE TABLE viz_user_steps_calories AS
SELECT
    Id,
    ROUND(AVG(TotalSteps), 0) AS average_steps,
    ROUND(AVG(Calories), 0) AS average_calories
FROM daily_activity_clean
GROUP BY Id;

-- 5. Reliable sleep averages
CREATE OR REPLACE TABLE viz_sleep AS
SELECT
    Id,
    ROUND(avg_sleep_minutes / 60, 1) AS average_sleep_hours
FROM sleep_reliable;

-- 6. Step volume vs. sleep duration comparison
CREATE OR REPLACE TABLE viz_activity_sleep AS
SELECT
    a.Id,
    ROUND(AVG(a.TotalSteps), 0) AS average_steps,
    ROUND(s.avg_sleep_minutes / 60, 1) AS average_sleep_hours
FROM daily_activity_clean a
JOIN sleep_reliable s ON a.Id = s.Id
GROUP BY a.Id, s.avg_sleep_minutes;

-- --------------------------------------------------------------------
-- 6. CSV EXPORTS (FOR TABLEAU DASHBOARDS)
-- --------------------------------------------------------------------

COPY viz_activity_segments 
TO '/Users/vitaborychevska/Desktop/FItbit_Analysis_Project/SQL/viz_activity_segments.csv' 
WITH (FORMAT CSV, HEADER);

COPY viz_weekday_activity 
TO '/Users/vitaborychevska/Desktop/FItbit_Analysis_Project/SQL/viz_weekday_activity.csv' 
WITH (FORMAT CSV, HEADER);

COPY viz_sedentary 
TO '/Users/vitaborychevska/Desktop/FItbit_Analysis_Project/SQL/viz_sedentary.csv' 
WITH (FORMAT CSV, HEADER);

COPY viz_user_steps_calories 
TO '/Users/vitaborychevska/Desktop/FItbit_Analysis_Project/SQL/viz_user_steps_calories.csv' 
WITH (FORMAT CSV, HEADER);

COPY viz_sleep 
TO '/Users/vitaborychevska/Desktop/FItbit_Analysis_Project/SQL/viz_sleep.csv' 
WITH (FORMAT CSV, HEADER);

COPY viz_activity_sleep 
TO '/Users/vitaborychevska/Desktop/FItbit_Analysis_Project/SQL/viz_activity_sleep.csv' 
WITH (FORMAT CSV, HEADER);
