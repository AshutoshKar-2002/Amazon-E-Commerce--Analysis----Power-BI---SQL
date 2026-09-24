create database ecommerce
use ecommerce
select count(*) from customers
select count(*) from orders
-- drop table orders
select * from customers
select * from orders


CREATE TABLE orders (
  OrderDate DATE,
  OrderID INT,
  DeliveryDate DATE,
  CustomerID VARCHAR(50),
  Location VARCHAR(100),
  Zone VARCHAR(50),
  DeliveryType VARCHAR(50),
  ProductCategory VARCHAR(100),
  SubCategory VARCHAR(100),
  Product VARCHAR(150),
  UnitPrice DECIMAL(10,2),
  ShippingFee DECIMAL(10,2),
  OrderQuantity INT,
  SalePrice DECIMAL(10,2),
  Status VARCHAR(50),
  Reason VARCHAR(255),
  Rating INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(OrderDate, OrderID, DeliveryDate, CustomerID, Location, Zone, DeliveryType, 
 ProductCategory, SubCategory, Product, UnitPrice, ShippingFee, 
 OrderQuantity, SalePrice, Status, Reason, Rating);
 
 SHOW WARNINGS;
 
select count(distinct CustomerID ) from orders;

-- ///Q14. 
select distinct CustomerID,sum(SalePrice) as TotalSales,
count(OrderID) as Frequency,avg(SalePrice) as AvgValue,
(0.5 * sum(SalePrice) + 0.3 * count(OrderID)+ 0.2 * avg(SalePrice)) as CompositeScore
from orders
group by CustomerID
order by CompositeScore desc
limit 5;

-- ///Q15
with MonthlyRevenue as
(
	select year(OrderDate) as 'YEAR',month(OrderDate) as 'MONTH',sum(SalePrice) as TotalSales
    from orders
    group by year(OrderDate),month(OrderDate)
)
select *,
    (TotalSales - lag(TotalSales) over (order by YEAR ,MONTH))/
		(lag(TotalSales) over (order by YEAR,MONTH) )*100 as MoMGrowthRate
from MonthlyRevenue;

-- // Q16
with RollingAvg as
(
	select distinct coalesce(nullif(ProductCategory, ''), 'NA') AS ProductCategory ,year(OrderDate) as 'YEAR',
    month(OrderDate) as 'MONTH',sum(SalePrice) as TotalRevenue 
    from orders
    group by ProductCategory,YEAR , MONTH
    order by YEAR , MONTH
)
select *,
avg(TotalRevenue) over(partition by ProductCategory order by YEAR,MONTH
	rows between 2 preceding and current row) as 3DayRollingAverage
from RollingAvg;
 
-- // Q17
update orders
set SalePrice = SalePrice * 0.85
where CustomerID in (
	select CustomerID from orders group by CustomerID
	having count(OrderID)>=10 
); 

-- //Q18
with NxtOrders as
(
	select CustomerID,OrderID,OrderDate,
	lead(OrderDate) over(partition by CustomerID order by OrderDate) as NxtOrderDt
    from orders
)
select CustomerID,
avg(datediff(NxtOrderDt,OrderDate)) as AvgDaysBtwOrders
from NxtOrders
where NxtOrderDt is not null
group by CustomerID
having count(OrderID) >=5;

-- //Q19
select CustomerID,sum(SalePrice)as TotalRevenue
from orders
group by CustomerID
having TotalRevenue > 
	(
		select avg(SalePrice)*1.30  from orders
	);
    
-- //Q20
with CurrentYear as
(
	select ProductCategory,sum(SalePrice) as CurrentYrTotalSales
    from orders
    where year(OrderDate)=(select max(year(OrderDate)) from orders)
    group by ProductCategory
)
,PreviousYear as
(
		select ProductCategory,sum(SalePrice) as PreviousYrTotalSales
		from orders
		where year(OrderDate)=(select max(year(OrderDate))-1 from orders)
		group by ProductCategory
)
select c.*,p.PreviousYrTotalSales,
c.CurrentYrTotalSales - p.PreviousYrTotalSales as SalesIncrease
from CurrentYear c join PreviousYear p 
on c.ProductCategory = p.ProductCategory;
 
 
 
 
 