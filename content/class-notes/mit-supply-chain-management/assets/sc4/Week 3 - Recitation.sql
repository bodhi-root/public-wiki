Drop database if exists General_Store;
Create Database General_Store;
Use General_Store;

Create Table Location (
Location_ID INT not Null Primary Key Auto_Increment,
Location_Territory Varchar(20) not null,
Location_Country Varchar(20) not null );

Create Table Stores (
Store_ID Int Not Null Primary Key,
Store_Name Varchar(40),
Store_Phone Varchar(20),
Store_Manager Varchar(20),
Location_ID Int not null,
Foreign key (Location_ID) references Location(Location_ID) );

Create Table Warehouses (
Warehouse_ID Int not Null Primary Key Auto_Increment,
Warehouse_Name Varchar(40),
Warehouse_Manager Varchar(20),
Warehouse_Phone Varchar(20),
Location_ID Int not null,
Foreign key (Location_ID) references Location(Location_ID) );

Create Table Shipments (
Shipment_ID Int not Null Primary Key Auto_Increment,
Warehouse_ID Int not Null,
Store_ID Int not Null,
Transportation_Cost Decimal(6,2),
Total_Product_Value Decimal(16,2),
Foreign key (Warehouse_ID) references Warehouses(Warehouse_ID),
Foreign key (Store_ID) references Stores(Store_ID) );

Insert into Location
values 
(1,'Maine','USA'),
(2,'New_York','USA'),
(3,'Michigan','USA'),
(4,'Wisconsin','USA'),
(5,'Nova_Scotia','Canada'),
(6,'New_Brunswick','Canada'),
(7,'Quebec','Canada'),
(8,'Ontario','Canada');

Insert into Stores
values
(1,'Vanessas_General_Store','5554984378','Vanessa',3),
(2,'Bens_General_Store','5554984365','Bobby',4),
(3,'Roberts_General_Store','5554984376','Rob',2),
(4,'Yummies_General_Store','5554984377','Carl',7),
(5,'Frosties_General_Store','5554984386','Susie',6),
(6,'Valerias_General_Store','5554984348','Victoria',4),
(7,'Santas_General_Store','5554984397','Nick',4),
(8,'Gills_General_Store','5554984310','Gilbert',5);



Insert into Warehouses
values 
(1,'The_Big_Red_Barn','Marty','5552345678',4),
(2,'The_Hut','April','5552345645',1),
(3,'The_Store_House','Hanook','5552345647',2),
(4,'Fields_of_Grain','Steve','55523456789',3),
(5,'Winterland','Rachel','5552345628',8);

Insert into Shipments
values
(1,5,4,847.36,125137.45),
(2,5,3,2030.52,232758.17),
(3,2,3,3069.03,348012.68),
(4,2,4,4426.47,122413.35),
(5,5,7,2572.4,219754.03),
(6,4,1,600.38,312345.95),
(7,2,5,3311.54,225368.73),
(8,1,6,1938.72,268452.25),
(9,1,8,3738.19,246162.57),
(10,1,6,3574.39,238107.25),
(11,1,6,1378.97,323813.3),
(12,4,6,1802.97,159676.86),
(13,4,8,2165.07,122114.96),
(14,5,7,1260.51,177091.52),
(15,2,7,3473.44,226721.91),
(16,2,1,4505.14,260972.16),
(17,5,3,2587.8,186133.9),
(18,3,5,2169.86,231861.15),
(19,4,6,579.47,374818.94),
(20,1,7,2997.39,305260.75),
(21,3,7,1197.08,187675.8),
(22,1,4,2933.09,140154.71),
(23,1,5,4372.91,149502.33),
(24,1,3,2052.9,301782.54),
(25,3,4,2687.56,226738.37),
(26,4,5,3870.83,153937.23),
(27,1,8,2342.62,115174.86),
(28,4,6,3348.78,146703.66),
(29,3,4,3806.43,205493.68),
(30,2,6,2716.2,330455.59);




select Warehouse_Name
from Warehouses
where Warehouse_ID=3;

Select Location.Location_Territory
from Location, Stores
where Stores.Store_Manager='Vanessa'
and
Location.Location_ID=Stores.Location_ID;

select Location.Location_Territory
from Stores
join Location on location.Location_ID=Stores.Location_ID
where
Stores.Store_Manager='Vanessa';

Select Shipments.Transportation_Cost
from Shipments, Warehouses, Stores
where
Warehouses.Warehouse_Name='The_Big_Red_Barn'
and
Stores.Store_Manager='Victoria'
and
Stores.Store_ID=Shipments.Store_ID
and
Warehouses.Warehouse_ID=Shipments.Warehouse_ID;

Select Sum(Shipments.Transportation_Cost)
from Shipments, Warehouses, Stores
where
Warehouses.Warehouse_Name='The_Big_Red_Barn'
and
Stores.Store_Manager='Victoria'
and
Stores.Store_ID=Shipments.Store_ID
and
Warehouses.Warehouse_ID=Shipments.Warehouse_ID;

Select Count(Shipments.Transportation_Cost)
from Shipments, Warehouses, Stores
where
Warehouses.Warehouse_Name='The_Big_Red_Barn'
and
Stores.Store_Manager='Victoria'
and
Stores.Store_ID=Shipments.Store_ID
and
Warehouses.Warehouse_ID=Shipments.Warehouse_ID;
