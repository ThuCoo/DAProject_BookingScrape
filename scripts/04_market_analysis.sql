USE da_projects;


GO
SELECT *
FROM   dbo.bookings;

-- Q1. How many properties in each borough?
SELECT   borough,
         COUNT(DISTINCT property_id) AS total_properties
FROM     dbo.bookings
GROUP BY borough;

-- Q2. What is the price range of each borough?
SELECT DISTINCT borough,
                MIN(price) OVER (PARTITION BY borough) AS min_price,
                CAST (AVG(CAST (price AS DECIMAL (10, 2))) OVER (PARTITION BY borough) AS DECIMAL (10, 2)) AS avg_price,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) OVER (PARTITION BY borough) AS median_price,
                MAX(price) OVER (PARTITION BY borough) AS max_price
FROM   dbo.bookings;

-- Q3. How many properties are in each price range?
WITH     avg_pricing
AS       (SELECT   property_id,
                   CAST (ROUND(AVG(CAST (price AS DECIMAL (10, 2))), 2) AS FLOAT) AS avg_price
          FROM     dbo.bookings
          GROUP BY property_id),
         price_segment
AS       (SELECT property_id,
                 CASE WHEN avg_price < 300 THEN '0-299' WHEN avg_price < 600 THEN '300-599' WHEN avg_price < 900 THEN '600-899' ELSE '900+' END AS price_range
          FROM   avg_pricing)
SELECT   price_range,
         COUNT(DISTINCT property_id) AS total_properties
FROM     price_segment
GROUP BY price_range;

-- Q4. What is the price range over time.
SELECT   borough,
         check_in_date,
         MIN(price) AS min_price,
         CAST (ROUND(AVG(CAST (price AS DECIMAL (10, 2))), 2) AS FLOAT) AS avg_price,
         MAX(price) AS max_price
FROM     dbo.bookings
GROUP BY borough, check_in_date
ORDER BY borough, check_in_date;

-- Q5. What is the average price thorough the week in each borough?
SELECT   borough,
         check_in_weekday,
         CAST (ROUND(AVG(CAST (price AS DECIMAL (10, 2))), 2) AS FLOAT) AS avg_price
FROM     dbo.bookings
GROUP BY borough, DATEDIFF(DAY, '19000101', check_in_date) % 7, check_in_weekday
ORDER BY borough, DATEDIFF(DAY, '19000101', check_in_date) % 7;

-- Q6. Compare average score, price and reviews between each rating type.
SELECT   rating,
         ROUND(AVG(score), 2) AS avg_score,
         CAST (ROUND(AVG(CAST (price AS DECIMAL (10, 2))), 2) AS FLOAT) AS avg_price,
         CAST (ROUND(AVG(CAST (reviews AS DECIMAL (10, 2))), 2) AS FLOAT) AS avg_reviews
FROM     dbo.bookings
WHERE    rating != 'No Reviews'
GROUP BY rating
ORDER BY avg_score DESC;

-- Q7. Top 3 highest rating property of each borough and their prices.
WITH     ranked_scraped
AS       (SELECT *,
                 RANK() OVER (PARTITION BY property_id ORDER BY scraped_at DESC) AS last_scraped
          FROM   dbo.bookings),
         latest_prop -- Get items' latest scraped data
AS       (SELECT   borough,
                   property_id,
                   name,
                   score,
                   MAX(reviews) AS reviews,
                   AVG(CAST (price AS DECIMAL (10, 2))) AS avg_price
          FROM     ranked_scraped AS r
          WHERE    last_scraped = 1
          GROUP BY borough, r.property_id, name, score),
         top_prop
AS       (SELECT *,
                 DENSE_RANK() OVER (PARTITION BY borough ORDER BY score DESC, reviews DESC) AS score_ranking
          FROM   latest_prop
          WHERE  reviews > 50)
SELECT   borough,
         name,
         score,
         reviews,
         CAST (ROUND(avg_price, 2) AS FLOAT) AS prop_avg_price
FROM     top_prop
WHERE    score_ranking <= 3
ORDER BY borough, score_ranking ASC;

-- Q8. Good rating properties with below average price.
WITH     ranked_scraped
AS       (SELECT *,
                 RANK() OVER (PARTITION BY property_id ORDER BY scraped_at DESC) AS last_scraped
          FROM   dbo.bookings),
         latest_prop -- Get items' latest scraped data
AS       (SELECT   borough,
                   property_id,
                   name,
                   score,
                   AVG(CAST (price AS DECIMAL (10, 2))) AS avg_price
          FROM     ranked_scraped AS r
          WHERE    last_scraped = 1
          GROUP BY borough, r.property_id, name, score),
         borough_avg
AS       (SELECT   borough,
                   AVG(CAST (avg_price AS DECIMAL (10, 2))) AS borough_avg_price
          FROM     latest_prop
          GROUP BY borough)
SELECT   l.property_id,
         l.name,
         CAST (ROUND(l.avg_price, 2) AS FLOAT) AS price,
         l.score
FROM     latest_prop AS l
         INNER JOIN
         borough_avg AS b
         ON b.borough = l.borough
WHERE    l.score > 7
         AND l.avg_price < b.borough_avg_price
ORDER BY l.avg_price ASC, l.score DESC;

-- Business Case & What-If Opportunity Sizing (For Product Spec)
WITH   borough_medians
AS     (SELECT property_id,
               borough,
               score,
               price,
               PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) OVER (PARTITION BY borough) AS borough_median_price
        FROM   dbo.bookings)
SELECT CAST (ROUND((SUM(CASE WHEN price < borough_median_price THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS FLOAT) AS pct_underpriced_top_rated,
       ROUND(AVG(CASE WHEN price < borough_median_price THEN borough_median_price - price END), 2) AS avg_nightly_lift,
       ROUND(AVG(CASE WHEN price < borough_median_price THEN (borough_median_price - price) * 8 END), 2) AS monthly_weekend_lift
FROM   borough_medians
WHERE  score >= 8.5;