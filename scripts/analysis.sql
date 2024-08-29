-- I will use the QUALIFY function in bigquery with can help me to filter using window function

-- 1. Find the total number of trips for each day
SELECT COUNT(DISTINCT trip_id) AS number_of_trips, trip_date
FROM `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`  
GROUP BY trip_date
ORDER BY trip_date desc

-- 2. Calculate the average trip duration for each day
SELECT ROUND(AVG(duration_minutes),2) AS average_trip_duratio_min, trip_date
FROM `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`  
GROUP BY trip_date
ORDER BY trip_date desc

-- 3. Identify the top 5 stations with the highest number of trip starts
SELECT  count(1) as total_number_of_trips_start ,start_station_name
FROM `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`  
GROUP BY start_station_name 
ORDER BY 1 desc
LIMIT 5

-- 4. Find the average number of trips per hour of the day.
-- (Assume we consider some hours of the day have missing data on certain days, i.e. avg = total trip with certain hours / total days even it has no records in some days)
SELECT 
    trip_hour,
    ROUND(COUNT(trip_id) / (SELECT COUNT(DISTINCT(trip_date)) 
                      FROM `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`),2)
    AS avg_number_per_hour
FROM 
    `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`
GROUP BY 
    trip_hour
ORDER BY 
    trip_hour

-- 5. Determine the most common trip route (start station to end station)
SELECT 
    start_station_name, 
    end_station_name, 
FROM 
        `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`
GROUP BY 
        start_station_name, end_station_name
QUALIFY RANK() OVER (ORDER BY COUNT(*) DESC) = 1

-- 6. Calculate the number of trips each month
SELECT 
    FORMAT_DATE('%Y-%m', trip_date) AS year_month, COUNT(*) AS number_of_trip_each_month
FROM 
    `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`
GROUP BY year_month
ORDER BY 2 DESC

-- 7. Find the station with the longest average trip duration
-- Assume group by start station
SELECT 
    start_station_name
FROM 
        `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`
GROUP BY 
        start_station_name
QUALIFY RANK() OVER (ORDER BY AVG(DURATION_MINUTES) DESC) =1

-- 8. Find the busiest hour of the day (most trips started)
SELECT 
    trip_date,
    trip_hour AS busiest_hour_of_day
FROM
    `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`
GROUP BY 
    trip_hour,trip_date
QUALIFY RANK() OVER (PARTITION BY trip_date ORDER BY COUNT(trip_id) DESC) = 1
ORDER BY 
    trip_date DESC

-- 9. Identify the day with the highest number of trips.
SELECT 
    trip_date
FROM
    `zeals-interview.zeals_biglake_dataset.bikeshare_trips_biglake`
GROUP BY 
    trip_date
QUALIFY RANK() OVER (ORDER BY COUNT(DISTINCT trip_id) DESC) = 1
ORDER BY 
    trip_date DESC
