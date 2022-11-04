USE [WideWorldImporters-Standard] -- I mannually inported the database, so the name of the database is slightly different
--SQL related assignments will be on the Wide World Importers Database unless otherwise mentioned.
--1.	List of Persons¡¯ full name, all their fax and phone numbers, as well as the phone number and fax of the company they are working for (if any). 
SELECT FullName, p.FaxNumber,p.PhoneNumber, CustomerName AS CompanyName
FROM Application.People p JOIN Sales.Customers c
ON p.PersonID = c.PrimaryContactPersonID;

--2.	If the customer's primary contact person has the same phone number as the customer¡¯s phone number, list the customer companies. 
SELECT CustomerName AS CompanyName
FROM Sales.Customers c JOIN Application.People p ON c.PrimaryContactPersonID = p.PersonID 
WHERE c.PhoneNumber = p.PhoneNumber;

--3.	List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.
SELECT  Customers.CustomerName
FROM Sales.Customers AS Customers
LEFT JOIN(SELECT A.CUSTOMERID 
FROM Sales.CustomerTransactions AS A
GROUP BY A.CustomerID
HAVING (MAX(A.TRANSACTIONDATE)<'2016-01-01') AND (MIN(A.TRANSACTIONDATE)<'2016-01-01')
	) AS T ON Customers.CustomerID = T.CustomerID

--4.	List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.
SELECT Stock.StockItemName,COUNT(Stock.StockItemName) AS Total_Quantity
FROM Purchasing.PurchaseOrders AS P
JOIN Purchasing.PurchaseOrderLines AS PL
ON PL.PurchaseOrderID = P.PurchaseOrderID 
JOIN Warehouse.StockItems_Archive AS Stock
ON PL.StockItemID = Stock.StockItemID
WHERE YEAR(P.OrderDate) ='2013'
GROUP BY Stock.StockItemName

--5.	List of stock items that have at least 10 characters in description.
SELECT StockItemName FROM Warehouse.StockItems
WHERE LEN(StockItemName) > 10

--6.	List of stock items that are not sold to the state of Alabama and Georgia in 2014.
SELECT DISTINCT (S.StockItemName)FROM Warehouse.StockItems AS S
except(SELECT DISTINCT(S.StockItemName)
FROM Warehouse.StockItems AS S
JOIN Sales.OrderLines AS OL
ON S.StockItemID = OL.StockItemID
JOIN Sales.Orders AS O
ON OL.OrderID = O.OrderID
JOIN Sales.Customers AS C
ON C.CustomerID = O.CustomerID
JOIN Application.Cities AS CT
ON C.DeliveryCityID = CT.CityID
JOIN Application.StateProvinces AS SP
ON CT.StateProvinceID = SP.StateProvinceID
WHERE SP.StateProvinceName IN ('Alabama' ,'Georgia')
AND YEAR(O.OrderDate) = 2014)

--7.	List of States and Avg dates for processing (confirmed delivery date ¨C order date).
SELECT SP.StateProvinceName,AVG(DATEDIFF(day, O.OrderDate, CONVERT(DATE,I.ConfirmedDeliveryTime))) AS AverageProcessDates 
FROM Sales.Invoices AS I
JOIN Sales.Orders AS O
ON I.OrderID = O.OrderID
JOIN Sales.Customers AS C
ON C.CustomerID = O.CustomerID
JOIN Application.Cities AS CT
ON CT.CityID = C.DeliveryCityID
JOIN Application.StateProvinces AS SP
ON CT.StateProvinceID = SP.StateProvinceID
GROUP BY SP.StateProvinceName
ORDER BY SP.StateProvinceName

--8.	List of States and Avg dates for processing (confirmed delivery date ¨C order date) by month.
SELECT MONTH(O.OrderDate) AS Month,SP.StateProvinceName,AVG(DATEDIFF(day, O.OrderDate, CONVERT(DATE,I.ConfirmedDeliveryTime))) AS AVGProcessDates
FROM Sales.Invoices AS I
JOIN Sales.Orders AS O ON I.OrderID = O.OrderID
JOIN Sales.Customers AS C ON C.CustomerID = O.CustomerID
JOIN Application.Cities AS CT ON CT.CityID = C.DeliveryCityID
JOIN Application.StateProvinces AS SP ON CT.StateProvinceID = SP.StateProvinceID
GROUP BY SP.StateProvinceName,MONTH(O.OrderDate)
ORDER BY MONTH(O.OrderDate),SP.StateProvinceName

--9.	List of StockItems that the company purchased more than sold in the year of 2015.
SELECT StockItemName = 
CASE WHEN PP.Q-SS.Q>0 THEN StockItemName END
FROM(SELECT PL.StockItemID,SUM(PL.ReceivedOuters) AS Q
FROM Purchasing.PurchaseOrderLines AS PL
JOIN Purchasing.PurchaseOrders AS P
ON PL.PurchaseOrderID = P.PurchaseOrderID
WHERE YEAR(P.OrderDate) = 2015
GROUP BY PL.StockItemID
) AS PP LEFT JOIN (SELECT SL.StockItemID,SUM(SL.PickedQuantity) AS Q
FROM Sales.OrderLines AS SL
JOIN Sales.Orders AS S
ON SL.OrderID = S.OrderID
WHERE YEAR(S.OrderDate) = 2015
GROUP BY SL.StockItemID
) AS SS ON PP.StockItemID = SS.StockItemID
JOIN Warehouse.StockItems AS Stock ON PP.StockItemID = Stock.StockItemID

--10.	List of Customers and their phone number, together with the primary contact person¡¯s name, to whom we did not sell more than 10  mugs (search by name) in the year 2016.
WITH temp AS(SELECT SO.CustomerID, SUM(SOL.Quantity) AS TotalQuantity FROM Sales.Orders SO JOIN Sales.OrderLines SOL ON 
SO.OrderID = SOL.OrderID WHERE YEAR(SO.OrderDate)='2016'
AND SOL.StockItemID IN (SELECT StockItemID FROM Warehouse.StockItems WHERE StockItemName LIKE '%mug%') GROUP BY SO.CustomerID
HAVING SUM(SOL.Quantity) <=10) 
SELECT temp2.CustomerID, temp2.PhoneNumber AS CustomerPhoneNum, AP.FullName AS PrimaryContactPerson 
FROM (SELECT temp.CustomerID, SC.PhoneNumber, 
SC.PrimaryContactPersonID, temp.TotalQuantity FROM temp JOIN Sales.Customers SC ON 
temp.CustomerID = SC.CustomerID) temp2 JOIN Application.People AP ON temp2.PrimaryContactPersonID = AP.PersonID 
ORDER BY CustomerID;



--11.	List all the cities that were updated after 2015-01-01.
select * from Application.Cities where ValidFrom > '2015-01-01';

--12.	List all the Order Detail (Stock Item name, delivery address, delivery state, city, country, customer name, 
-- customer contact person name, customer phone, quantity)
-- for the date of 2014-07-01. Info should be relevant to that date.
WITH temp AS(SELECT SOL.OrderLineID, SOL.StockItemID, SOL.Quantity, SO.CustomerID, SO.OrderDate FROM Sales.OrderLines SOL JOIN Sales.Orders SO ON
SO.OrderID = SOL.OrderID WHERE SO.OrderDate = '2014-07-01'),
temp2 AS(SELECT temp.OrderLineID, temp.StockItemID, temp.Quantity, SC.CustomerName, SC.PrimaryContactPersonID,
SC.AlternateContactPersonID, SC.PhoneNumber, 
SC.DeliveryAddressLine1, SC.DeliveryAddressLine2, SC.DeliveryCityID
FROM temp JOIN Sales.Customers SC ON SC.CustomerID = temp.CustomerID),
temp4
AS(SELECT temp2.StockItemID, temp2.DeliveryAddressLine1, temp2.DeliveryAddressLine2, temp3.StateProvinceName,
temp3.CityName, temp3.CountryID, temp2.CustomerName, temp2.PrimaryContactPersonID, temp2.AlternateContactPersonID,
temp2.PhoneNumber,temp2.Quantity FROM temp2 JOIN (SELECT AC.CityID, AC.CityName,SP.StateProvinceName, SP.CountryID FROM 
Application.StateProvinces SP JOIN Application.Cities AC ON SP.StateProvinceID = AC.StateProvinceID) temp3 ON 
temp2.DeliveryCityID = temp3.CityID),
temp5 AS(SELECT WS.StockItemName, temp4.DeliveryAddressLine1, temp4.DeliveryAddressLine2, temp4.StateProvinceName,
temp4.CityName, temp4.CountryID, temp4.CustomerName, temp4.PrimaryContactPersonID, temp4.AlternateContactPersonID,
temp4.PhoneNumber,temp4.Quantity FROM temp4 JOIN Warehouse.StockItems WS ON temp4.StockItemID = WS.StockItemID),
temp6 AS(SELECT temp5.StockItemName, temp5.DeliveryAddressLine1, temp5.DeliveryAddressLine2, temp5.StateProvinceName,
temp5.CityName, temp5.CountryID, temp5.CustomerName, AP.FullName AS PrimaryContactPersonName, temp5.AlternateContactPersonID,
temp5.PhoneNumber,temp5.Quantity FROM temp5 LEFT JOIN Application.People AP ON temp5.PrimaryContactPersonID
= AP.PersonID) SELECT temp6.StockItemName, temp6.DeliveryAddressLine1, temp6.DeliveryAddressLine2, temp6.StateProvinceName,
temp6.CityName, temp6.CountryID, temp6.CustomerName, temp6.PrimaryContactPersonName, AP.FullName AS AlternateContactPersonName,
temp6.PhoneNumber,temp6.Quantity FROM temp6 LEFT JOIN Application.People AP ON temp6.AlternateContactPersonID = AP.PersonID;

--13.	List of stock item groups and total quantity purchased, total quantity sold, and the remaining stock quantity (quantity purchased ¨C quantity sold)
WITH cte0 AS (SELECT s.StockGroupID, SUM(p.OrderedOuters) AS PurchaseQuantity FROM Purchasing.PurchaseOrderLines p
JOIN Warehouse.StockItemStockGroups s ON p.StockItemID = s.StockItemID
GROUP BY s.StockGroupID
),cte1 AS (SELECT s.StockGroupID, SUM(o.Quantity) AS SaleQuantity
FROM Sales.OrderLines o
JOIN Warehouse.StockItemStockGroups s ON o.StockItemID = s.StockItemID
GROUP BY s.StockGroupID)
SELECT s.StockGroupName, ISNULL(c0.PurchaseQuantity, 0) AS PurchaseQuantity, ISNULL(c1.SaleQuantity, 0) AS SaleQuantity,
ISNULL(c0.PurchaseQuantity, 0) - ISNULL(c1.SaleQuantity, 0) AS RemainingQuantity
FROM Warehouse.StockGroups s
LEFT JOIN cte0 c0 ON s.StockGroupID = c0.StockGroupID
LEFT JOIN cte1 c1 ON s.StockGroupID = c1.StockGroupID

--14.	List of Cities in the US and the stock item that the city got the most deliveries in 2016. 
WITH cte0 AS (SELECT ol.StockItemID, c.DeliveryCityID, COUNT(*) AS Delivery FROM Sales.OrderLines ol
JOIN Sales.Orders o ON o.OrderID = ol.OrderID
JOIN sales.Customers c ON o.CustomerID = c.CustomerID
WHERE YEAR(o.OrderDate) = 2016
GROUP BY ol.StockItemID, c.DeliveryCityID),
cte1 AS(SELECT StockItemID, DeliveryCityID FROM ( 
SELECT StockItemID, DeliveryCityID, 
DENSE_RANK() OVER(PARTITION BY DeliveryCityId ORDER BY Delivery DESC) AS rnk
FROM cte0) a WHERE rnk = 1
)SELECT c.CityName, ISNULL(s.StockItemName, 'No Sale') AS MostDelivery
FROM cte1 c1 JOIN Warehouse.StockItems s ON c1.StockItemID = s.StockItemID
RIGHT JOIN Application.Cities c ON c1.DeliveryCityID = c.CityID

--If the city did not purchase any stock items in 2016, print ¡°No Sales¡±.
--15.	List any orders that had more than one delivery attempt (located in invoice table).
SELECT JSON_QUERY(SI.ReturnedDeliveryData,'$.Events[2]') AS MoreThanOneAttempt FROM Sales.Invoices SI
WHERE JSON_QUERY(SI.ReturnedDeliveryData,'$.Events[2]') IS NOT NULL;

--16.	List all stock items that are manufactured in China. (Country of Manufacture)
SELECT StockItemID, JSON_VALUE(WSI.CustomFields,'$.CountryOfManufacture') AS CountryOfManufacure 
FROM Warehouse.StockItems WSI WHERE JSON_VALUE(WSI.CustomFields,'$.CountryOfManufacture')='China';

--17.	Total quantity of stock items sold in 2015, group by country of manufacturing.
WITH temp AS(SELECT SOL.StockItemID, SUM(SOL.Quantity) AS TotalQuanPerStockItem FROM Sales.Orders SO 
JOIN Sales.OrderLines SOL ON SO.OrderID = SOL.OrderID WHERE YEAR(SO.OrderDate)=2015 GROUP BY StockItemID)
SELECT JSON_VALUE(WSI.CustomFields,'$.CountryOfManufacture') AS CountryOfManufacture, 
SUM(temp.TotalQuanPerStockItem) AS TotalQuantity FROM Warehouse.StockItems WSI JOIN temp ON 
WSI.StockItemID = temp.StockItemID GROUP BY JSON_VALUE(WSI.CustomFields,'$.CountryOfManufacture');

--18.	Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Stock Group Name, 2013, 2014, 2015, 2016, 2017]
CREATE VIEW Sales.StockItemByYear AS WITH cte0 AS (
SELECT StockGroupName, 2013 AS [Year]
FROM Warehouse.StockGroups
UNION ALL
SELECT StockGroupName, [Year] + 1
FROM cte0
WHERE [Year] < 2017
),
cte1 AS (SELECT YEAR(o.OrderDate) AS [Year], sg.StockGroupName, SUM(ol.Quantity) AS Quantity
FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
JOIN Warehouse.StockItems s ON ol.StockItemID =s.StockItemID
JOIN Warehouse.StockItemStockGroups g ON g.StockItemID = s.StockItemID
JOIN Warehouse.StockGroups sg ON g.StockGroupID = sg.StockGroupID WHERE YEAR(o.OrderDate) BETWEEN 2013 AND 2017
GROUP BY YEAR(o.OrderDate), sg.StockGroupName),
cte2 AS (SELECT c0.StockGroupName, c0.[Year], ISNULL(c1.Quantity, 0) AS Quantity FROM cte0 c0
LEFT JOIN cte1 c1 ON c0.[Year] = c1.[Year] AND c0.StockGroupName = c1.StockGroupName
	)SELECT StockGroupName, [2013], [2014], [2015], [2016], [2017]
FROM cte2 PIVOT
(MIN(Quantity) FOR Year IN ([2013], [2014], [2015], [2016], [2017])) TBL


--19.	Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, ¡­ , Stock Group Name10] 
CREATE OR ALTER VIEW TotalQuantities2 AS
WITH temp AS(SELECT SOL.StockItemID, SUM(SOL.Quantity) AS TotalQuanPerStockItem,YEAR(SO.OrderDate) 
AS OrderYear FROM Sales.Orders SO 
JOIN Sales.OrderLines SOL ON SO.OrderID=SOL.OrderID WHERE YEAR(SO.OrderDate) BETWEEN '2013' AND '2017'
GROUP BY StockItemID,YEAR(SO.OrderDate)),
temp2 AS(SELECT SISG.StockGroupID, temp.OrderYear, SUM(temp.TotalQuanPerStockItem) AS TotalQuanPerGroupYear 
FROM Warehouse.StockItemStockGroups SISG JOIN temp ON SISG.StockItemID = temp.StockItemID 
GROUP BY SISG.StockGroupID, temp.OrderYear)
SELECT OrderYear, [1] AS Group1, [2] AS Group2, [3] AS Group3, [4] AS Group4,
[5] AS Group5, [6] AS Group6, [7] AS Group7, [8] AS Group8, [9] AS Group9, [10] AS Group10 FROM
(SELECT * FROM temp2) AS SourceTable 
PIVOT(
MIN(TotalQuanPerGroupYear) FOR StockGroupID IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
) AS PivotTable;
SELECT * FROM TotalQuantities2 ORDER BY OrderYear;

--20.	Create a function, input: order id; return: total of that order. List invoices and use that function to attach the order total to the other fields of invoices. 
CREATE OR ALTER FUNCTION dbo.udf20(@OrderId INT
) RETURNS DEC(18,2) AS
BEGIN
DECLARE @OrderTotal DEC(18,2);
SELECT @OrderTotal = SUM((Quantity*UnitPrice)) FROM Sales.OrderLines SOL 
WHERE SOL.OrderID = @OrderId;
RETURN @OrderTotal;
END;
SELECT * FROM Sales.Invoices SI CROSS APPLY (SELECT dbo.udf20(SI.OrderID)) AS TAB(OrderTotal);

--21.	Create a new table called ods.Orders. Create a stored procedure, 
--with proper error handling and transactions, that input is a date; when executed, 
--it would find orders of that day, calculate order total, and save the information (order id, order date, order total, 
--customer id) into the new table. If a given date is already existing in the new table, throw an error and roll back. 
--Execute the stored procedure 5 times using different dates. 
CREATE SCHEMA ods
GO
CREATE TABLE ods.Orders
(OrderID INT PRIMARY KEY,
OrderDate DATE,
OrderTotal DECIMAL(18, 2),
CustomerID INT)
GO
CREATE PROCEDURE ods.OrderTotalOfDate @OrderDate DATE
AS 
IF EXISTS (SELECT 1 FROM ods.Orders WHERE OrderDate = @OrderDate)
	BEGIN
		RAISERROR('Date Exists ', 16, 1)
	END
ELSE
BEGIN
BEGIN TRANSACTION
INSERT INTO ods.Orders
SELECT o.OrderID, o.OrderDate, f.Total, o.CustomerID
FROM Sales.Orders o
CROSS APPLY Sales.OrderTotal(OrderID) f
WHERE o.OrderDate = @OrderDate
COMMIT
END
GO
EXEC ods.OrderTotalOfDate '2013-01-01'
EXEC ods.OrderTotalOfDate '2013-01-02'
EXEC ods.OrderTotalOfDate '2013-01-03'
EXEC ods.OrderTotalOfDate '2013-01-04'
EXEC ods.OrderTotalOfDate '2013-01-05'

--22.	Create a new table called ods.StockItem. It has following columns: [StockItemID], [StockItemName] ,[SupplierID] ,
--[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[
--Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], 
--[CountryOfManufacture], [Range], [Shelflife]. Migrate all the data in the original stock item table.
CREATE TABLE ods.StockItems(
	StockItemID INT PRIMARY KEY,StockItemName NVARCHAR(100) NOT NULL,
	SupplierID INT NOT NULL,ColorID INT NULL,UnitPackageID INT NOT NULL,OuterPackageID INT NOT NULL,Brand NVARCHAR(50) NULL,
	Size NVARCHAR(20) NULL,
	LeadTimeDays INT NOT NULL,QuantityPerOuter INT NOT NULL,IsChillerStock BIT NOT NULL,
	Barcode NVARCHAR(50) NULL,TaxRate DECIMAL(18, 3) NOT NULL,UnitPrice DECIMAL(18, 2) NOT NULL,
	RecommendedRetailPrice DECIMAL(18, 2) NULL,TypicalWeightPerUnit DECIMAL(18, 3) NOT NULL,MarketingComments NVARCHAR(MAX) NULL,
	InternalComments NVARCHAR(MAX) NULL,CountryOfManufacture NVARCHAR(20) NULL,[Range] NVARCHAR(20) NULL,
	Shelflife NVARCHAR(20) NULL
)
MERGE INTO ods.StockItems AS T
USING Warehouse.StockItems AS R
ON T.StockItemID = R.StockItemID
WHEN NOT MATCHED 
THEN INSERT VALUES (R.StockItemID, R.StockItemName, R.SupplierID, R.ColorID, 
R.UnitPackageID, R.OuterPackageID, R.Brand, R.Size, R.LeadTimeDays, 
R.QuantityPerOuter, R.IsChillerStock, R.Barcode, R.TaxRate, R.UnitPrice,
R.RecommendedRetailPrice, R.TypicalWeightPerUnit, R.MarketingComments,
R.InternalComments, JSON_VALUE(R.CustomFields, '$.CountryOfManufacture'),
JSON_VALUE(R.CustomFields, '$.Range'), JSON_VALUE(R.CustomFields, '$.ShelfLife'));

--23.	Rewrite your stored procedure in (21). Now with a given date, it should wipe out all the order data prior to the input
--date and load the order data that was placed in the next 7 days following the input date.
DROP PROCEDURE ods.OrderTotalOfDate;
CREATE PROCEDURE ods.NewOrderTotalOfDate
	@OrderDate DATE
AS 
BEGIN TRANSACTION
	DELETE FROM ods.Orders
	WHERE OrderDate < @OrderDate
COMMIT
BEGIN TRANSACTION
MERGE ods.Orders T
USING (	
SELECT o.OrderID, o.OrderDate, f.Total, o.CustomerID
FROM Sales.Orders o
CROSS APPLY Sales.OrderTotal(OrderID) f
WHERE DATEDIFF(d, @OrderDate, OrderDate) BETWEEN 1 AND 7
) R
ON T.OrderID = R.OrderID
WHEN NOT MATCHED
THEN INSERT VALUES (R.OrderID, R.OrderDate, R.Total, R.CustomerID);
COMMIT

--24.	Consider the JSON file:

{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}


--Looks like that it is our missed purchase orders. Migrate these data into Stock Item, Purchase Order and Purchase Orde
--r Lines tables. Of course, save the script.
25.	Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.
SELECT Year AS Year,
	[Novelty Items] AS 'StockGroup.Novelty Items',
	[Clothing] AS 'StockGroup.Clothing', 
	[Mugs] AS 'StockGroup.Mugs',
	[T-Shirts] AS 'StockGroup.T-Shirts',
	[Airline Novelties] AS 'StockGroup.Airline Novelties', 
	[Computing Novelties] AS 'StockGroup.Computing Novelties', 
	[USB Novelties] AS 'StockGroup.USB Novelties', 
	[Furry Footwear] AS 'StockGroup.Furry Footwear', 
	[Toys] AS 'StockGroup.Toys', 
	[Packaging Materials] AS 'StockGroup.Packaging Materials'
FROM Sales.StockItemByName 
FOR JSON PATH

26.	Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.
SELECT Year AS '@Year',
	[Novelty Items] AS NoveltyItems,
	[Clothing], 
	[Mugs],
	[T-Shirts],
	[Airline Novelties] AS AirlineNovelties, 
	[Computing Novelties] AS ComputingNovelties, 
	[USB Novelties] AS USBNovelties, 
	[Furry Footwear] AS FurryFootwear, 
	[Toys], 
	[Packaging Materials] AS PackagingMaterials
FROM Sales.StockItemByName 
FOR XML PATH('StockItems')

--27.	Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value) . 
--Create a stored procedure, input is a date. The logic would load invoice information (all columns) as well as invoice 
--line information (all columns) and forge them into a JSON string and then insert into the new table just created. 
--Then write a query to run the stored procedure for each DATE that customer id 1 got something delivered to him.


28.	Write a short essay talking about your understanding of transactions, locks and isolation levels.








--29.	Write a short essay, plus screenshots talking about performance tuning in 
--SQL Server. Must include Tuning Advisor, Extended Events, DMV, Logs and Execution Plan.










Assignments 30 - 32 are group assignments.

30.	Write a short essay talking about a scenario: Good news everyone! We (Wide World Importers) just brought out a small company called ¡°Adventure works¡±! Now that bike shop is our sub-company. The first thing of all works pending would be to merge the user logon information, person information (including emails, phone numbers) and products (of course, add category, colors) to WWI database. Include screenshot, mapping and query.
31.	Database Design: OLTP db design request for EMS business: when people call 911 for medical emergency, 911 will dispatch UNITs to the given address. A UNIT means a crew on an apparatus (Fire Engine, Ambulance, Medic Ambulance, Helicopter, EMS supervisor). A crew member would have a medical level (EMR, EMT, A-EMT, Medic). All the treatments provided on scene are free. If the patient needs to be transported, that¡¯s where the bill comes in. A bill consists of Units dispatched (Fire Engine and EMS Supervisor are free), crew members provided care (EMRs and EMTs are free), Transported miles from the scene to the hospital (Helicopters have a much higher rate, as you can image) and tax (Tax rate is 6%). Bill should be sent to the patient insurance company first. If there is a deductible, we send the unpaid bill to the patient only. Don¡¯t forget about patient information, medical nature and bill paying status.

32.	Remember the discussion about those two databases from the class, also remember, those data models are not perfect. You can always add new columns (but not alter or drop columns) to any tables. Suggesting adding Ingested DateTime and Surrogate Key columns. Study the Wide World Importers DW. Think the integration schema is the ODS. Come up with a TSQL Stored Procedure driven solution to move the data from WWI database to ODS, and then from the ODS to the fact tables and dimension tables. By the way, WWI DW is a galaxy schema db. Requirements:
a.	Luckly, we only start with 1 fact: Purchase. Other facts can be ignored for now.
b.	Add a new dimension: Country of Manufacture. It should be given on top of Stock Items.
c.	Write script(s) and stored procedure(s) for the entire ETL from WWI db to DW.

SELECT FullName, p.FaxNumber,p.PhoneNumber, CustomerName AS CompanyName
FROM Application.People p JOIN Sales.Customers c
ON p.PersonID = c.PrimaryContactPersonID 