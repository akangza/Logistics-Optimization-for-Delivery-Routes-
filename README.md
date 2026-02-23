# Logistics Optimization for Delivery Routes – DHL
## Project Overview
This project analyzes global logistics operations of DHL using SQL to evaluate delivery delays, route efficiency, warehouse performance, and agent effectiveness. The objective is to uncover patterns in transit delays, hub utilization, uncover operational bottlenecks and improve on-time delivery performance across DHL’s global logistics network.

## Project Objective
To build a SQL-driven logistics analytics system to analyze shipment performance, optimize routes, 
and enhance delivery efficiency across DHL’s global network.
The project aims to: 
* Identify delay patterns and operational inefficiencies. 
* Optimize hub and route combinations for improved transit times. 
* Analyze agent- and warehouse-level performance.

## Dataset Description
* Orders Table : The Orders dataset contains order-level delivery details including order date, route, warehouse and payment type.
* Routes Table : The Routes dataset includes route-level transportation details, covering the source and destination cities, countries, total distance, and average transit time (in hours).
* Warehouses Table : The Warehouses dataset provides location-level information about DHL major hubs and sortation centers.
* Delivery Agents Table : The Delivery Agents dataset contains agent-level performance data, including agent ID, name, assigned zone and country, experience, and customer rating.
* Shipment Tracking Table : The Shipments dataset includes shipment-level tracking information with timestamps for pickup and delivery, delay duration, and feedback ratings.

## Tools & Technology 
* MySQL Workbench
* SQL : Joins, CTEs, Window Functions, Aggregations
* Relational Database Modeling for Data Clenaing and Preparation

## Key Insights
* High percentage of shipments exceed expected transit time, indicating systemic route inefficiencies.
* Significant gap between expected vs actual transit time suggests unrealistic benchmarks.
* Low overall on-time delivery % points to operational bottlenecks across routes and hubs.
* Certain warehouses and international routes contribute disproportionately to delays.
* Agent ratings remain high despite poor on-time %, implying process-driven issues rather than individual performance gaps.

## Recommendations
* Adjust expected transit times using historical performance data.
* Prioritize high-delay routes and hubs for operational optimization.
* Improve warehouse capacity planning and workload balancing.
* Implement performance-based route assignment for delivery agents.
* Establish continuous KPI monitoring for On-Time %, Delay %, and Warehouse Utilization.

## Conclusion
This analysis highlights systemic operational inefficiencies across routes, hubs, and delivery workflows impacting on-time performance. By optimizing transit benchmarks, warehouse capacity, and route management, DHL can significantly enhance reliability and global service efficiency.
