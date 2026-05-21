USE [SUPPLY_CHAIN];

-- Total Revenue / Total Sales
SELECT SUM (Sales) as Total_Revenue  FROM [order details] 

-- Total Profit
SELECT SUM([Order_Item_Profit_Ratio]*[Sales]) AS Total_Profit FROM [order details]

-- Total Orders
SELECT COUNT (DISTINCT [Order_Id]) AS Total_Orders FROM [order details]

-- Annual Revenue
SELECT YEAR (O.[order_date_DateOrders]) AS Order_Year,
		SUM(OD.Sales) AS Revenue
FROM [dbo].[order] O
JOIN [dbo].[order details] OD
ON OD.Order_Id = O.Order_Id
GROUP BY YEAR (O.[order_date_DateOrders])

-- Monthly Revenue
SELECT
    YEAR(o.order_date_DateOrders) AS Order_Year,
    MONTH(o.order_date_DateOrders) AS Order_Month,
    SUM(od.Sales) AS Revenue
FROM [order details] od
JOIN [order] o
ON od.Order_Id = o.Order_Id
GROUP BY
    YEAR(o.order_date_DateOrders),
    MONTH(o.order_date_DateOrders)
ORDER BY Order_Year, Order_Month

-- Top Products by Sales
SELECT TOP 10 
		P.[Product_Name],
		SUM(OD.Sales) AS Total_Sales
FROM [product] P
JOIN [order details] OD
ON OD.[Product_Card_Id]=P.[Product_Card_Id]
GROUP BY P.[Product_Name]
ORDER BY SUM(OD.Sales) DESC

-- Top Products by Profit
SELECT TOP 10 
		P.Product_Name,
		SUM(OD.[Order_Item_Profit_Ratio]*OD.Sales) AS Total_Profit
FROM [product] P
JOIN [order details] OD
ON OD.Product_Card_Id = P.Product_Card_Id
GROUP BY P.Product_Name
ORDER BY SUM(OD.[Order_Item_Profit_Ratio]*OD.Sales) DESC

-- Top Products by Quantity
SELECT TOP 10
	P.Product_Name,
	SUM(OD.[Order_Item_Quantity]) AS Total_Quantity
FROM [product] P
JOIN [order details] OD
ON OD.Product_Card_Id = P.Product_Card_Id 
GROUP BY P.Product_Name
ORDER BY SUM(OD.[Order_Item_Quantity]) DESC

-- Revenue by Country
SELECT TOP 10 
		O.Order_Country,
		SUM(OD.Sales) AS Total_Revenue
FROM [order] O
JOIN [order details] OD
ON OD.[Order_Id] = O.[Order_Id]
GROUP BY O.[Order_Country]
ORDER BY SUM(OD.Sales) DESC

-- Product Margin Status
SELECT P.[Product_Name],
	SUM (OD.[Sales]) AS Total_Sales,
	SUM (OD.[Order_Item_Profit_Ratio]*OD.[Sales]) AS Total_Profit,
	(SUM(OD.[Order_Item_Profit_Ratio]*OD.[Sales])/SUM(OD.[Sales]))*100 AS Profit_Margin_Percent,
	CASE 
		WHEN (SUM(OD.[Order_Item_Profit_Ratio]*OD.[Sales])/SUM(OD.[Sales]))*100<10
		THEN 'Low Margin'
		ELSE 'Healthy Margin'
	END AS Margin_Status
FROM [product] P
JOIN [order details] OD
ON P.[Product_Card_Id] = OD.[Product_Card_Id]
GROUP BY P.[Product_Name]
ORDER BY Profit_Margin_Percent DESC

-- Customer Sales Ranking
WITH Customer_Sales AS 
	(SELECT C.[Customer_Id], 
			C.[Customer_Fname], 
			C.[Customer_Lname],
			SUM (OD.[Sales]) AS Total_Sales
	FROM [dbo].[customer] C
	JOIN [dbo].[order] O
	ON C.Customer_Id = O.Customer_Id
	JOIN [dbo].[order details] OD
	ON OD.Order_Id = O.Order_Id
	GROUP BY C.[Customer_Id], 
			 C.[Customer_Fname], 
			 C.[Customer_Lname])
SELECT * , RANK () OVER (ORDER BY Total_Sales DESC) AS Customer_Rank
FROM Customer_Sales

-- Customer Segment
SELECT
    c.Customer_Segment,
    SUM(od.Sales) AS Total_Sales,
    SUM(od.Order_Item_Profit_Ratio * od.Sales) AS Total_Profit,
    AVG(od.Sales) AS Avg_Order_Value
FROM [order details] od
JOIN [order] o
ON od.Order_Id = o.Order_Id
JOIN customer c
ON o.Customer_Id = c.Customer_Id
GROUP BY c.Customer_Segment
ORDER BY Total_Sales DESC

-- Late Delivery Rate
SELECT
    (SELECT COUNT(*) FROM [order]) AS Total_Orders, 
    COUNT(*) AS Late_Orders,                        
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM [order])) AS Late_Delivery_Rate
FROM [order]
WHERE Delivery_Status = 'Late delivery'

-- Discount Impact
SELECT
    CASE
        WHEN od.Order_Item_Discount <= 0.1 THEN 'Low Discount'
        WHEN od.Order_Item_Discount <= 0.3 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS Discount_Group,
    AVG(od.Sales) AS Avg_Sales,
    AVG(od.Order_Item_Profit_Ratio * od.Sales) AS Avg_Profit
FROM [order details] od
GROUP BY
    CASE
        WHEN od.Order_Item_Discount <= 0.1 THEN 'Low Discount'
        WHEN od.Order_Item_Discount <= 0.3 THEN 'Medium Discount'
        ELSE 'High Discount'
    END

-- Top Products Per Category
WITH Product_Sales AS
(SELECT
		p.Product_Category_Id,
        p.Product_Name,
        SUM(od.Sales) AS Total_Sales,
        ROW_NUMBER() OVER
        (PARTITION BY p.Product_Category_Id
            ORDER BY SUM(od.Sales) DESC) AS rn
FROM [order details] od
JOIN product p
ON od.Product_Card_Id = p.Product_Card_Id
GROUP BY
        p.Product_Category_Id,
        p.Product_Name)
SELECT *
FROM Product_Sales
WHERE rn <= 3