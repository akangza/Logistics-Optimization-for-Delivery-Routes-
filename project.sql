create database DHL;
use dhl;
show tables;

/**Task 1: Data Cleaning & Preparation **/
select * from orders;
describe orders;
select * from shipments;
select * from routes;
select * from warehouses;
select * from delivery_agents;

-- Identify and delete duplicate Order_ID or Shipment_ID records.
SELECT  Order_ID, COUNT(*) FROM Orders GROUP BY Order_ID HAVING COUNT(*) > 1;
SELECT  Shipment_ID, COUNT(*) FROM Shipments GROUP BY Shipment_ID HAVING COUNT(*) > 1;

DELETE FROM orders WHERE order_id IN 
(SELECT order_id FROM (SELECT order_id FROM orders GROUP BY order_id HAVING COUNT(*) > 1) t );

-- Replace null or missing Delay_Hours values in the Shipments Table with the average delay for that Route_ID.
SELECT Shipment_ID, Route_ID, Delay_Hours FROM Shipments 
WHERE Delay_Hours IS NULL;

UPDATE Shipments s
JOIN (SELECT Route_ID, AVG(Delay_Hours) AS Avg_Delay
    FROM Shipments
    WHERE Delay_Hours IS NOT NULL
    GROUP BY Route_ID) r
ON s.Route_ID = r.Route_ID
SET s.Delay_Hours = ROUND(r.Avg_Delay, 2)
WHERE s.Delay_Hours IS NULL;

-- Convert all date columns (Order_Date, Pickup_Date, Delivery_Date) into YYYY-MM-DD HH:MM:SS format using SQL date functions.
select * from orders;
describe orders;
ALTER TABLE Orders MODIFY Order_Date DATETIME;

select * from shipments;
describe shipments;
ALTER TABLE shipments MODIFY Pickup_Date DATETIME;
ALTER TABLE shipments MODIFY Delivery_Date DATETIME;

-- Ensure that no Delivery_Date occurs before Pickup_Date (flag such records).
SELECT Shipment_ID, Pickup_Date, Delivery_Date,
CASE
	WHEN Delivery_Date < Pickup_Date then 'Invalid'
	ELSE 'Valid'
END AS Check_Dates
FROM Shipments;

-- Validate referential integrity between Orders, Routes, Warehouses, and Shipments.
DESCRIBE Orders;
ALTER TABLE Orders MODIFY Order_ID VARCHAR(50) NOT NULL, 
MODIFY Customer_ID VARCHAR(50)  NOT NULL, 
MODIFY Route_ID VARCHAR(50)  NOT NULL,
MODIFY Warehouse_ID VARCHAR(50)  NOT NULL,
ADD PRIMARY KEY(Order_ID);

DESCRIBE Routes;
ALTER TABLE Routes MODIFY Route_ID VARCHAR(50) NOT NULL, 
ADD PRIMARY KEY(Route_ID);

DESCRIBE Warehouses;
ALTER TABLE Warehouses MODIFY Warehouse_ID VARCHAR(50) NOT NULL, 
ADD PRIMARY KEY(Warehouse_ID);

DESCRIBE Shipments;
ALTER TABLE Shipments 
MODIFY Shipment_ID VARCHAR(50) NOT NULL,
MODIFY Order_ID VARCHAR(50) NOT NULL, 
MODIFY Agent_ID VARCHAR(50) NOT NULL,
MODIFY Route_ID VARCHAR(50) NOT NULL,
MODIFY Warehouse_ID VARCHAR(50) NOT NULL,
ADD PRIMARY KEY(Shipment_ID);

DESCRIBE Delivery_agents;
ALTER TABLE Delivery_agents MODIFY Agent_ID VARCHAR(50), 
ADD PRIMARY KEY(Agent_ID);

ALTER TABLE Orders
ADD FOREIGN KEY(Route_ID) REFERENCES Routes(Route_ID),
ADD FOREIGN KEY(Warehouse_ID) REFERENCES Warehouses(Warehouse_ID);

ALTER TABLE Shipments
ADD FOREIGN KEY (Order_ID) REFERENCES Orders (Order_ID),
ADD FOREIGN KEY (Agent_ID) REFERENCES Delivery_agents (Agent_ID),
ADD FOREIGN KEY (Route_ID) REFERENCES Routes (Route_ID),
ADD FOREIGN KEY (Warehouse_ID) REFERENCES Warehouses (Warehouse_ID);

-- Task 2 Delivery Delay Analysis
-- Calculate delivery delay (in hours) for each shipment using Delivery_Date – Pickup_Date. 
SELECT Shipment_ID, Delivery_Date, Pickup_Date, 
ROUND(TIMESTAMPDIFF(SECOND, Pickup_Date, Delivery_Date)/3600, 2) AS Delivery_Delay
FROM Shipments;

--  Find the Top 10 delayed routes based on average delay hours.
SELECT r.Route_ID, r.Source_City, r.Destination_City,
ROUND(avg(Delay_Hours),2) AS Avg_Delay_Hours
FROM Shipments s INNER JOIN Routes r
ON s.Route_ID = r.Route_ID
WHERE s.Delay_Hours IS NOT NULL
GROUP BY r.Route_ID, r.Source_City, r.Destination_City
ORDER BY Avg_Delay_Hours DESC LIMIT 10;

-- Use SQL window functions to rank shipments by delay within each Warehouse_ID.
SELECT Warehouse_ID, Shipment_ID, Delay_Hours, 
RANK() OVER(PARTITION BY Warehouse_ID ORDER BY Delay_Hours DESC) AS Shipment_Rank
FROM Shipments 
ORDER BY Warehouse_ID;

--  Identify the average delay per Delivery_Type (Express / Standard) to compare service-level efficiency.
SELECT o.Delivery_Type, ROUND(AVG(s.Delay_Hours),2) as Average_Delay
FROM Orders o INNER JOIN Shipments s
ON o.Order_ID = s.Order_ID
GROUP BY o.Delivery_Type;

-- Task 3: Route Optimization Insights
-- For each route, calculate: Average transit time (in hours) across all shipments.
SELECT r.Route_ID, r.Source_City, r.Destination_City,
ROUND(AVG(TIMESTAMPDIFF(SECOND, s.Pickup_Date, s.Delivery_Date) / 3600),2) AS Average_Transit_Time
FROM Shipments s INNER JOIN Routes r
ON s.Route_ID = r.Route_ID
GROUP BY r.Route_ID, r.Source_City, r.Destination_City
ORDER BY Average_Transit_Time DESC;

-- Average delay (in hours) per route.
SELECT s.Route_ID, r.Source_City, r.Destination_City,
ROUND(AVG(s.delay_hours),2) AS Average_Delay_Hours 
FROM Shipments s INNER JOIN Routes r
ON s.Route_ID = r.Route_ID
GROUP BY r.Route_ID, r.Source_City, r.Destination_City
ORDER BY Average_Delay_Hours DESC;

-- Distance-to-time efficiency ratio = Distance_KM / Avg_Transit_Time_Hours.
SELECT Route_ID, Source_City, Destination_City, Distance_KM, Avg_Transit_Time_Hours,
ROUND(Distance_KM / Avg_Transit_Time_Hours,2) AS Distance_to_Time_Efficiency_Ratio 
FROM Routes ORDER BY Distance_to_Time_Efficiency_Ratio DESC;

-- Identify 3 routes with the worst efficiency ratio (lowest distance-to-time)
SELECT Route_ID, Source_City, Destination_City, Distance_KM, Avg_Transit_Time_Hours,
ROUND(Distance_KM / Avg_Transit_Time_Hours,2) AS Distance_to_Time_Efficiency_Ratio 
FROM Routes
ORDER BY Distance_to_Time_Efficiency_Ratio ASC LIMIT 3;

-- Find routes with >20% of shipments delayed beyond expected transit time. 
SELECT s.Route_ID,  r.Source_City, r.Destination_City,
r.Avg_Transit_Time_Hours AS Expected_Transit_Time,
COUNT(*) AS Total_Shipments,
SUM((TIMESTAMPDIFF(SECOND, s.Pickup_Date, s.Delivery_Date) / 3600)> r.Avg_Transit_Time_Hours) AS Delayed_Shipments,
ROUND(AVG(TIMESTAMPDIFF(SECOND, s.Pickup_Date, s.Delivery_Date) / 3600),1) AS Actual_Avg_Transit_Time,
ROUND(SUM((TIMESTAMPDIFF(SECOND, s.Pickup_Date, s.Delivery_Date) / 3600)> r.Avg_Transit_Time_Hours) * 100.0 / COUNT(*),2) AS `Shipments Delayed %`
FROM Shipments s INNER JOIN Routes r 
ON s.Route_ID = r.Route_ID
GROUP BY s.Route_ID, r.Avg_Transit_Time_Hours
HAVING `Shipments Delayed %` > 20.00
ORDER BY `Shipments Delayed %` DESC;

-- Task 4: Warehouse Performance
-- Find the top 3 warehouses with the highest average delay in shipments dispatched.
SELECT s.Warehouse_ID, w.City, w.Country,
ROUND(AVG(s.Delay_Hours),2) as Average_Delay_Hours 
FROM Shipments s INNER JOIN Warehouses w
ON s.Warehouse_ID = w.Warehouse_ID
GROUP BY s.Warehouse_ID, w.City, w.Country
ORDER BY Average_Delay_Hours DESC LIMIT 3;

-- Calculate total shipments vs delayed shipments for each warehouse.
SELECT Warehouse_ID, 
COUNT(*) AS Total_Shipments, 
SUM(CASE 
		WHEN Delay_Hours > 0 THEN 1 
		ELSE 0 
	END) AS Delayed_Shipments
FROM Shipments GROUP BY Warehouse_ID;

-- Use CTEs to identify warehouses where average delay exceeds the global average delay. 
WITH Warehouse_Avg_Delay AS(
	SELECT Warehouse_ID, ROUND(AVG(Delay_Hours),2) AS Average_Delay_Hours 
    FROM Shipments GROUP BY  Warehouse_ID
),
Global_Avg_Delay AS(
	SELECT ROUND(AVG(Delay_Hours),2) AS Global_Average_Delay 
    FROM Shipments
)
SELECT * FROM Warehouse_Avg_Delay CROSS JOIN Global_Avg_Delay
WHERE Average_Delay_Hours > Global_Average_Delay ;

-- Rank all warehouses based on on-time delivery percentage.
WITH On_Time_Delivery AS(
	SELECT Warehouse_ID, COUNT(*) AS Total_Shipments, SUM(Delay_Hours = 0) AS On_Time_Shipments, 
	ROUND((SUM(Delay_Hours = 0) / COUNT(*)) * 100,2) AS `on-time delivery %`
	FROM Shipments GROUP BY Warehouse_ID
)
SELECT *, RANK() OVER(ORDER BY `on-time delivery %` DESC) as Warehouse_Rank
FROM On_Time_Delivery;

-- Task 5: Delivery Agent Performance 
-- Rank delivery agents (per route) by on-time delivery percentage. 
WITH On_Time_Delivery AS(
	SELECT Route_ID, Agent_ID, COUNT(*) AS Total_Shipments, SUM(Delay_Hours = 0) AS On_Time_Shipments, 
	ROUND((SUM(Delay_Hours = 0) / COUNT(*)) * 100,2) AS `on-time delivery %`
	FROM Shipments GROUP BY Route_ID, Agent_ID
)
SELECT *, RANK() OVER(PARTITION BY ROUTE_ID ORDER BY `on-time delivery %` DESC) as Agent_Rank 
FROM On_Time_Delivery;

-- Find agents whose on-time % is below 85%. 
WITH On_Time AS(
	SELECT Agent_ID, COUNT(*) AS Total_Shipments, SUM(Delay_Hours = 0) AS On_Time_Shipments, 
	ROUND((SUM(Delay_Hours = 0) / COUNT(*)) * 100,2) AS on_time_percent
	FROM Shipments GROUP BY Agent_ID
)
SELECT * FROM On_Time WHERE on_time_percent < 85 ORDER BY on_time_percent DESC;

-- Compare the average rating and experience (in years) of the top 5 vs bottom 5 agents using subqueries. 
SELECT p.Agent_ID, d.Agent_Name, d.Avg_Rating, d.Experience_Years, p.On_Time_Percent
FROM (
	SELECT Agent_ID, 
    ROUND(SUM(Delay_Hours = 0) / COUNT(*) * 100, 2) AS On_Time_Percent
    FROM Shipments
    GROUP BY Agent_ID 
    ORDER BY ROUND(SUM(Delay_Hours = 0) / COUNT(*) * 100, 2) DESC LIMIT 5
) p
JOIN delivery_agents d ON p.Agent_ID = d.Agent_ID

UNION ALL

SELECT p.Agent_ID, d.Agent_Name, d.Avg_Rating, d.Experience_Years, p.On_Time_Percent
FROM (
	SELECT Agent_ID, 
    ROUND(SUM(Delay_Hours = 0) / COUNT(*) * 100, 2) AS On_Time_Percent
    FROM Shipments
    GROUP BY Agent_ID 
    ORDER BY ROUND(SUM(Delay_Hours = 0) / COUNT(*) * 100, 2) ASC LIMIT 5
) p
JOIN delivery_agents d ON p.Agent_ID = d.Agent_ID;

-- Task 6: Shipment Tracking Analytics 
-- For each shipment, display the latest status (Delivered, In Transit, or Returned) along with the latest Delivery_Date. 
select * from shipments;
SELECT Shipment_ID, Delivery_Status, Delivery_Date FROM Shipments;

-- Identify routes where the majority of shipments are still “In Transit” or “Returned”. 
SELECT Route_ID, COUNT(*) AS Total_Shipments,
SUM(Delivery_Status IN ('In Transit','Returned')) AS In_Transit_OR_Returned
FROM Shipments
GROUP BY Route_ID
HAVING In_Transit_OR_Returned > COUNT(*)/2;

-- Find the most frequent delay reasons (if available in delay-related columns or flags).
SELECT Delay_Reason , COUNT(Delay_Reason) as Delayed_Shipments 
FROM Shipments 
WHERE Delay_Hours > 0 
GROUP BY Delay_Reason ORDER BY Delayed_Shipments DESC;

-- Identify orders with exceptionally high delay (>120 hours) to investigate potential bottlenecks.
SELECT Order_ID, Delay_Hours, Delay_Reason
FROM Shipments 
WHERE Delay_Hours > 120 
ORDER BY Delay_Hours DESC;

-- Task 7: Advanced KPI Reporting
-- Create SQL queries to calculate and summarize the following KPIs: Average Delivery Delay per Source_Country. 
SELECT r.Source_Country, 
ROUND(AVG(s.Delay_Hours),2) AS Average_Delivery_Delay 
FROM Routes r INNER JOIN Shipments s 
ON r.Route_ID = s.Route_ID
GROUP BY r.Source_Country 
ORDER BY Average_Delivery_Delay DESC;

-- On-Time Delivery % = (Total On-Time Deliveries / Total Deliveries) * 100.
SELECT SUM(CASE WHEN Delay_Hours = 0 THEN 1 ELSE 0 END) AS On_Time_Deliveries , 
COUNT(*) AS Total_Deliveries,
ROUND(SUM(CASE WHEN Delay_Hours = 0 THEN 1 ELSE 0 END)/COUNT(*) * 100,2) AS `On-Time Delivery %`
FROM Shipments;

-- Average Delay (in hours) per Route_ID.
SELECT Route_ID, 
ROUND(AVG(delay_hours),2) AS Average_Delay_Hours 
FROM Shipments 
GROUP BY Route_ID
ORDER BY Average_Delay_Hours DESC;

-- Warehouse Utilization % = (Shipments_Handled / Capacity_per_day) * 100.
WITH daily_shipments AS (
    SELECT Warehouse_ID, DATE(Pickup_Date),
	COUNT(*) AS Shipments_Per_Day
    FROM Shipments
    GROUP BY Warehouse_ID, DATE(Pickup_Date)
)
SELECT w.Warehouse_ID, ROUND(AVG(s.Shipments_Per_Day), 2) AS Avg_Shipments_Handled_Per_Day, 
w.Capacity_per_day,
ROUND((AVG(s.Shipments_Per_Day) / w.Capacity_per_day) * 100 , 2) AS `Warehouse Utilization % `
FROM daily_shipments s INNER JOIN Warehouses w 
ON s.Warehouse_ID = w.Warehouse_ID
GROUP BY s.Warehouse_ID, w.Capacity_per_day;
