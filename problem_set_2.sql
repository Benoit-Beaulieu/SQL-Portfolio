-- Does the order experience rating differ by time of day?
WITH daytime AS (
SELECT
       CASE
            WHEN EXTRACT(HOUR FROM when_the_delivery_started) > 5 AND EXTRACT (HOUR FROM when_the_delivery_started) < 12 THEN 'Breakfast'
            WHEN EXTRACT(HOUR FROM when_the_delivery_started) >= 12 AND EXTRACT (HOUR FROM when_the_delivery_started) < 17 THEN 'Lunch' 
            ELSE 'Dinner'  
            END  AS time_of_day
      , COUNT(DISTINCT delivery_id) AS num_deliveries
 FROM Skillful_Data.Project_Data AS pd 
GROUP BY time_of_day
)
SELECT daytime.*,
       COUNT(DISTINCT rd.delivery_id) AS num_ratings
  FROM daytime
  JOIN Skillful_Data.Ratings AS rd 
    ON daytime.delivery_id = rd.delivery_id;

-- What is the average rating of a users first delivery?
WITH first_delivery AS(
SELECT pd.customer_id, 
       COUNT(DISTINCT delivery_id) AS num_orders,
       MIN(pd.when_the_delivery_started) AS first_delivery_date, 
  FROM Skillful_Data.Project_Data AS pd
 GROUP BY customer_id 
 )
 SELECT first_delivery.first_delivery_date, 
        rd.Total_Rating
   FROM first_delivery 
   JOIN Skillful_Data.Ratings AS rd
     ON first_delivery.delivery_id = dr.delivery_id;
