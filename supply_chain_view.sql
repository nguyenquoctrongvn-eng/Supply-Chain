USE [SUPPLY_CHAIN]

CREATE VIEW v_BI_Order AS
SELECT 
    od.Order_Id,
    o.Customer_Id,
    od.Product_Card_Id,
    o.order_date_DateOrders AS Order_Date,
    YEAR(o.order_date_DateOrders) AS Order_Year,
    MONTH(o.order_date_DateOrders) AS Order_Month,
    o.Order_Country,
    o.Delivery_Status,
    od.Sales AS Revenue,
    (od.Order_Item_Profit_Ratio * od.Sales) AS Profit,
    od.Order_Item_Quantity AS Quantity,
    CASE
        WHEN od.Order_Item_Discount <= 0.1 THEN 'Low Discount'
        WHEN od.Order_Item_Discount <= 0.3 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS Discount_Group
FROM [order details] od
JOIN [order] o ON od.Order_Id = o.Order_Id;

ALTER VIEW v_BI_Product AS
SELECT 
    p.Product_Card_Id,
    p.Product_Category_Id,
    p.Product_Name,
	od.[Category_Name],
    SUM(od.Sales) AS Total_Sales,
    SUM(od.Order_Item_Profit_Ratio * od.Sales) AS Total_Profit,
    SUM(od.Order_Item_Quantity) AS Total_Quantity,
    (SUM(od.Order_Item_Profit_Ratio * od.Sales) / NULLIF(SUM(od.Sales), 0)) * 100 AS Profit_Margin_Percent,
    CASE 
        WHEN (SUM(od.Order_Item_Profit_Ratio * od.Sales) / NULLIF(SUM(od.Sales), 0)) * 100 < 10 THEN 'Low Margin'
        ELSE 'Healthy Margin'
    END AS Margin_Status
FROM [product] p
JOIN [order details] od ON p.Product_Card_Id = od.Product_Card_Id
GROUP BY p.Product_Card_Id, p.Product_Category_Id, p.Product_Name,od.[Category_Name];

CREATE VIEW v_BI_Customer AS
SELECT 
    c.Customer_Id,
    CONCAT(c.Customer_Fname, ' ', c.Customer_Lname) AS Customer_Full_Name,
    c.Customer_Segment,
    c.Customer_City,
	c.Customer_Country
FROM [customer] c;

CREATE OR ALTER VIEW v_BI_Order_Monthly_Growth AS
WITH Monthly_Revenue AS (
    SELECT 
        YEAR(o.order_date_DateOrders) AS Order_Year,
        MONTH(o.order_date_DateOrders) AS Order_Month,
        FORMAT(o.order_date_DateOrders, 'yyyy-MM') AS Year_Month,
        SUM(od.Sales) AS Current_Month_Revenue
    FROM [order details] od
    JOIN [order] o ON od.Order_Id = o.Order_Id
    GROUP BY YEAR(o.order_date_DateOrders), MONTH(o.order_date_DateOrders), FORMAT(o.order_date_DateOrders, 'yyyy-MM')
),
Growth_Calculation AS (
    SELECT 
        Order_Year,
        Order_Month,
        Year_Month,
        Current_Month_Revenue,
        LAG(Current_Month_Revenue, 1) OVER (ORDER BY Order_Year, Order_Month) AS Previous_Month_Revenue
    FROM Monthly_Revenue
)
SELECT 
    Order_Year,
    Order_Month,
    Year_Month,
    Current_Month_Revenue AS Revenue,
    Previous_Month_Revenue,
    ISNULL(
        (Current_Month_Revenue - Previous_Month_Revenue) / NULLIF(Previous_Month_Revenue, 0) * 100, 
        0
    ) AS MoM_Growth_Percent
FROM Growth_Calculation;