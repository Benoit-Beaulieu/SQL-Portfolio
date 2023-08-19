-- FINDINGS
-- Manhattan has 69 zones featuring 875 merchants. 
-- 520 of these merchants have zero revenue  
--- (i.e. all of the orders placed with these merchants have had to be refunded. None have zero revenue due to zero order volume) 
--- 355 of these merchants generate revenue. 
---- 219 have CWT less than 18.9 minutes (~70% of revenue generated within Manhattan) 
---- 136 have CWT more than 18.9 minutes (~30% of revenue generated within Manhattan)
-- There are 24 pickup-dropoff zone combinations within Manhattan that have greater than 25 orders since launch (some as high as 77). 
--- These combinations represent 18% of all orders within Manhattan, have generated 13% of revenue since launch, and have an average delivery time of 39.97 minutes (both revenue and delivery times within Manhattan)
-- When excluding merchants with CWT that exceed 18.9 minutes, CWT improve by 48%, a 12-minute reduction in time couriers spend waiting at a merchant. 
-- TBD whether or not order-batching would be cost-effective and/or significantly reduce delivery times 

-- SUPPORTING QUERIES

-- The following query investigates revenue by zone within the borough of Manhattan.
-- Manhattan generates 70% of Junipers revenue, leading our team to focus on this borough in particular.
SELECT COUNT(DISTINCT pd.pickup_place) AS num_merchants, SUM(pd.total) AS revenue,
       zi.zone_name,
       AVG(dr.delivery_time) AS delivery_time_rating
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Zone_Information AS zi
    ON pd.Pickup_Zone_ID = CAST(zi.zone_id AS INTEGER)
  JOIN Skillful_Data.Ratings AS dr
    ON pd.delivery_id = dr.delivery_id
 WHERE zi.borough LIKE 'M%'
 GROUP BY zi.zone_name 
 ORDER BY revenue DESC;

-- The query below investigates zone combinations within Manhattan, to discover whether or not there are certain pickup and dropoff combinations with enough order volume to implement delivery batching
WITH zone_combinations AS (

SELECT zi1.zone_id AS pickup_zone_id, 
       zi1.zone_name AS pickup_zone,
       zi2.zone_id AS dropoff_zone_id,
       zi2.zone_name AS dropoff_zone,
       COUNT(DISTINCT pd.delivery_id) AS volume, 
       SUM(pd.total) AS total_revenue,
       AVG(TIMESTAMP_DIFF(when_the_Courier_arrived_at_dropoff, when_the_delivery_started, SECOND) / 60.0) AS avg_delivery_time,
  FROM Skillful_Data.Project_Data AS pd
  JOIN Skillful_Data.Zone_Information AS zi1
    ON CAST(pd.pickup_zone_id AS INTEGER) = CAST(zi1.zone_id AS INTEGER)
  JOIN Skillful_Data.Zone_Information AS zi2
    ON CAST(pd.dropoff_zone_id AS INTEGER) = CAST(zi2.zone_id AS INTEGER)
 WHERE zi1.borough LIKE 'M%'
       AND zi2.borough LIKE 'M%'
 GROUP BY 1,2,3,4
 ORDER BY 5 DESC 
) 
SELECT zc.*
  FROM zone_combinations AS zc 
 WHERE zc.volume > 25
 ORDER BY zc.avg_delivery_time 

-- The query below identifies top performing merchants, idenfitied as merchants with no refunded orders, and who have a below average courier-wait-time (CWT)
WITH merchant_info AS (
SELECT DISTINCT pd.pickup_place AS merchant, AVG(pd.total) AS avg_order_value,
       AVG(dr.delivery_time) AS avg_delivery_time_rating, 
       AVG(TIMESTAMP_DIFF(when_the_Courier_left_pickup, when_the_Courier_arrived_at_pickup, SECOND) / 60.0) AS avg_time_at_pickup_minutes,
       zi.zone_name, zi.borough
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Ratings AS dr 
    ON pd.delivery_id = dr.delivery_id
  JOIN Skillful_Data.Zone_Information AS zi 
    ON pd.Pickup_Zone_ID = CAST(zi.zone_id AS INTEGER) 
 WHERE zi.borough LIKE 'M%' 
 GROUP BY pd.pickup_place, zi.zone_name, zi.borough
 ORDER BY avg_time_at_pickup_minutes
)

SELECT DISTINCT mi.merchant, mi.avg_order_value, mi.zone_name, mi.avg_time_at_pickup_minutes, mi.borough
  FROM merchant_info AS mi 
  WHERE mi.avg_order_value > 0.00 
        AND mi.avg_time_at_pickup_minutes < 18.9
 ORDER BY mi.avg_time_at_pickup_minutes DESC; 

-- When investigating zones with the highest revenue, Yorkville East stood out. This query investigates the merchants within that zone, and identified a single liquour store responsible for the entire zone's revenue.
-- The revenue from this liqour store represented the majoriy of revenue generated in Manhattan, confirming our team's hypothesis that Juniper has a concentrated merchant mix.
SELECT DISTINCT pd.pickup_place, SUM(pd.total) AS revenue,
       AVG(dr.delivery_time) AS delivery_time_rating, 
       zi.zone_name
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Zone_Information AS zi
    ON pd.Pickup_Zone_ID = CAST(zi.zone_id AS INTEGER)
  JOIN Skillful_Data.Ratings AS dr
    ON pd.delivery_id = dr.delivery_id
 WHERE zi.zone_name LIKE 'Yorkville E%'
 GROUP BY pd.pickup_place, zi.zone_name
 ORDER BY revenue DESC; 

-- The query below simply looks into delivery time by courier vehicle type, to discover whether there is a significant discrepancy between each.
SELECT DISTINCT vehicle_type,
       AVG(timestamp_DIFF(when_the_Courier_arrived_at_dropoff, when_the_delivery_started, minute)) AS avg_delivery_time_minutes, 
       AVG(item_quantity) AS avg_num_items
  FROM Skillful_Data.Project_Data AS pd
 GROUP BY 1;

-- This query looks into the number of merchants per zone witthin the borough of Manhattan that generate zero revenue
-- The goal of this query is to identify zones where a better merchant mix might need to be implemented 
WITH tb1 AS (

SELECT pd.pickup_place AS merchant, AVG(pd.total) AS avg_order_value,
       AVG(dr.delivery_time) AS avg_delivery_time_rating, zi.zone_name
  FROM Skillful_Data.Project_Data  AS pd 
  JOIN Skillful_Data.Ratings AS dr 
    ON pd.delivery_id = dr.delivery_id
  JOIN Skillful_Data.Zone_Information AS zi 
    ON pd.Pickup_Zone_ID = CAST(zi.zone_id AS INTEGER) 
 WHERE zi.borough LIKE 'M%' 
 GROUP BY pd.pickup_place, zi.zone_name
 ORDER BY avg_delivery_time_rating
)
SELECT tb1.zone_name, COUNT(DISTINCT tb1.merchant) AS num_merchants_zero_rev
  FROM tb1 
 WHERE avg_order_value = 0.00
 GROUP BY tb1.zone_name
 ORDER BY num_merchants_zero_rev DESC;


-- The following query counts the number of merchants per zone within Manhattan that might generate zero revenue due to receiving zero orders
WITH tb1 AS (

SELECT pd.pickup_place AS merchant, AVG(pd.total) AS avg_order_value, COUNT(DISTINCT pd.delivery_id) AS order_volume,
       AVG(dr.delivery_time) AS avg_delivery_time_rating, zi.zone_name
  FROM Skillful_Data.Project_Data  AS pd 
  JOIN Skillful_Data.Ratings AS dr 
    ON pd.delivery_id = dr.delivery_id
  JOIN Skillful_Data.Zone_Information AS zi 
    ON pd.Pickup_Zone_ID = CAST(zi.zone_id AS INTEGER) 
 WHERE zi.borough LIKE 'M%' 
 GROUP BY pd.pickup_place, zi.zone_name
 ORDER BY avg_delivery_time_rating
)
SELECT tb1.zone_name, COUNT(DISTINCT tb1.merchant) AS num_merchants
  FROM tb1 
 WHERE tb1.order_volume = 0.00
 GROUP BY tb1.zone_name

-- The following three queries investigates how merchants with below or above average CWT's influence overall CWT
-- Again, these queries focus on merchants within Manhattan, and those tha have order values greater than zero. 

-- Avg time at pickup EXCLUDING above avg CWT merchants
WITH merchant_info AS (
SELECT DISTINCT pd.pickup_place AS merchant, AVG(pd.total) AS avg_order_value,
       AVG(dr.delivery_time) AS avg_delivery_time_rating, 
       AVG(TIMESTAMP_DIFF(when_the_Courier_left_pickup, when_the_Courier_arrived_at_pickup, SECOND) / 60.0) AS avg_time_at_pickup_minutes,
       zi.zone_name
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Ratings AS dr 
    ON pd.delivery_id = dr.delivery_id
  JOIN Skillful_Data.Zone_Information AS zi 
    ON pd.Pickup_Zone_ID = CAST(zi.zone_id AS INTEGER) 
 WHERE zi.borough LIKE 'M%' 
 GROUP BY pd.pickup_place, zi.zone_name
 ORDER BY avg_time_at_pickup_minutes
)

SELECT AVG(mi.avg_time_at_pickup_minutes) AS avg_pickup_time
  FROM merchant_info AS mi 
 WHERE mi.avg_order_value > 0.00 
       AND mi.avg_time_at_pickup_minutes < 18.9

-- Avg time at pickup INCLUDING above avg CWT merchants
WITH merchant_info AS (
SELECT DISTINCT pd.pickup_place AS merchant, AVG(pd.total) AS avg_order_value,
       AVG(dr.delivery_time) AS avg_delivery_time_rating, 
       AVG(TIMESTAMP_DIFF(when_the_Courier_left_pickup, when_the_Courier_arrived_at_pickup, SECOND) / 60.0) AS avg_time_at_pickup_minutes,
       zi.zone_name
  FROM Skillful_Data.Project_Data AS pd 
  JOIN Skillful_Data.Ratings AS dr 
    ON pd.delivery_id = dr.delivery_id
  JOIN Skillful_Data.Zone_Information AS zi 
    ON pd.Pickup_Zone_ID = CAST(zi.zone_id AS INTEGER) 
 WHERE zi.borough LIKE 'M%' 
 GROUP BY pd.pickup_place, zi.zone_name
 ORDER BY avg_time_at_pickup_minutes
)

SELECT  AVG(mi.avg_time_at_pickup_minutes) AS avg_pickup_time
  FROM merchant_info AS mi 
 WHERE mi.avg_order_value > 0.00 
       AND mi.avg_time_at_pickup_minutes > 18.9
