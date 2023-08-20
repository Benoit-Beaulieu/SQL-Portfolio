-- Has weekly delivery volume been increasing or decreasing since launch?
SELECT COUNT(DISTINCT(dpd.delivery_id)) AS order_volume,
       timestamp_trunc(when_the_Courier_arrived_at_dropoff, week) AS week
  FROM Skillful_Data.Project_Data AS dpd
 GROUP BY week
 ORDER BY week DESC;

-- How many customers have placed at least two orders?
SELECT dpd.customer_id AS customer, 
       COUNT(DISTINCT(dpd.delivery_id)) AS volume 
  FROM Skillful_Data.Project_Data AS dpd
 GROUP BY customer
HAVING volume >= 2
 ORDER BY customer; 

-- What are the top-5 most popular place categories?
SELECT DISTINCT(dpd.place_category) AS category,
       COUNT(DISTINCT(dpd.delivery_id)) AS volume
  FROM Skillful_Data.Project_Data AS dpd 
 WHERE dpd.place_category IS NOT NULL
 GROUP BY category
 ORDER BY volume DESC 
 LIMIT 5;

-- Which place category has the fastest delivery time?
SELECT dpd.place_category,
       AVG(TIMESTAMP_DIFF(when_the_Courier_arrived_at_dropoff, when_the_delivery_started, MINUTE)) AS delivery_time
  FROM Skillful_Data.Project_Data AS dpd
 WHERE dpd.place_category IS NOT NULL 
 GROUP BY dpd.place_category
 ORDER BY delivery_time;

-- Which borough placed the highest amount of orders?
SELECT zi.borough, 
       COUNT(pd.delivery_id) AS num_orders
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Zone_Information AS zi 
    ON CAST(pd.Dropoff_Zone_ID AS INTEGER) = CAST(zi.zone_id AS INTEGER)
 GROUP BY zi.borough 
 ORDER BY num_orders DESC;

-- How many deliveries started in Manhattan?
 SELECT COUNT(DISTINCT(pd.delivery_id)) AS num_orders,
        zi.borough
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Zone_Information AS zi 
    ON CAST(pd.Pickup_Zone_ID AS INTEGER) = CAST(zi.zone_id AS INTEGER)
 GROUP BY zi.borough
 ORDER BY num_orders DESC;

-- What is the average rating by vehicle type?
 SELECT pd.vehicle_type, 
        AVG(dr.Total_Rating) AS avg_rating
  FROM Skillful_Data.Project_Data AS pd
  JOIN Skillful_Data.Ratings AS dr 
    ON pd.delivery_id = dr.delivery_id
 GROUP BY pd.vehicle_type
 ORDER BY avg_rating DESC; 

-- Which zones had the longest wait times?
SELECT zi.zone_name,
       COUNT(DISTINCT(pd.delivery_id)) AS num_deliveries, 
       AVG(TIMESTAMP_DIFF(pd.when_the_Courier_left_pickup, pd.when_the_Courier_arrived_at_pickup, MINUTE)) AS avg_wait_time
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Zone_Information AS zi 
    ON CAST(zi.zone_id AS INTEGER) = pd.Pickup_Zone_ID
 WHERE pd.when_the_Courier_arrived_at_pickup IS NOT NULL
 GROUP BY zi.zone_name
 ORDER BY avg_wait_time DESC; 

-- Which place category has the best total rating?
SELECT pd.place_category, 
       AVG(rd.Total_Rating) AS total_rating
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Ratings AS rd 
    ON pd.delivery_id = rd.delivery_id 
 GROUP BY pd.place_category
 ORDER BY total_rating DESC;

-- How many deliveries are greater than 50-minutes?
SELECT
       CASE
            WHEN timestamp_Diff(when_the_Courier_arrived_at_dropoff,when_the_delivery_started, MINUTE) > 50 THEN '> 50 mins'
       ELSE 'trip shorter than 50mins'
        END AS trip_category,
       COUNT(DISTINCT delivery_id) as num_trips
FROM
    Skillful_Data.Project_Data
GROUP BY trip_category;

-- How much revenue did couriers generate during their first week?
WITH tb1 AS (
SELECT courier_id, 
       MIN(TIMESTAMP_TRUNC(when_the_delivery_started, WEEK)) AS first_delivery_week
  FROM Skillful_Data.Project_Data
 GROUP BY courier_id
 )
SELECT tb1.first_delivery_week,
       COUNT(DISTINCT(pd.courier_id)) AS num_couriers,
       SUM(pd.total) AS total_revenue
  FROM Skillful_Data.Project_Data AS pd 
  JOIN tb1
    ON tb1.courier_id = pd.courier_id 
 GROUP BY tb1.first_delivery_week 
 ORDER BY tb1.first_delivery_week;