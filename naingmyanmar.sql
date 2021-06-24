create database naingmyanmar

create schema ComDB

create table ComDB.Customers
(
CuID char(5) not null
constraint pk_Customers_CuID
primary key(CuID),
CName varchar(30) not null,
CAddress varchar(30) not null,
CPh varchar(11) not null
constraint check_Customers_CPh
check (CPh LIKE  '09-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' 
 or 
CPh LIKE  '09-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
CMail varchar(30) not null
constraint check_Customers_CMail
check (CMail LIKE '%_@__%.__%')
)

create table ComDB.Branch
(
BNO varchar(8) not null
constraint pk_Branch_BNO
primary key(BNO),
BAdd varchar(30) not null,
BMail varchar(30) not null
constraint check_Branch_BMail
check (BMail LIKE '%_@__%.__%'),
BPh varchar(11) not null
constraint check_Branch_BPh
check (BPh LIKE  '09-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' 
 or 
BPh LIKE  '09-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
)

create table ComDB.Staff
(
StaffID varchar(7) not null
constraint pk_Staff_StaffID
primary key(StaffID),
StaffName varchar(30) not null
)

create table ComDB.Supplier
(
SupplierID char(5) not null
constraint pk_Supplier_SupplierID
primary key(SupplierID),
SupplierName varchar(30) not null,
SupplierAddress varchar(30) not null
)


create table ComDB.Item
(
ItemCode varchar(5) not null
constraint pk_Item_ItemCode
primary key(ItemCode),
ItemDescription varchar(70) not null,
UnitPrice Money not null
constraint check_Item_UnitPrice
check(UnitPrice>0),
SupplierID char(5) not null
constraint fk_Item_SupplierID
foreign key(SupplierID)
references ComDB.Supplier(SupplierID)
on delete cascade
on update cascade
)

create table ComDB.Orderr
(
ONO char(7) not null
constraint pk_Orderr_ONO
primary key(ONO),
ODate datetime not null
constraint check_Orderr_ODate
check(ODate<=getdate())
constraint default_Orderr_ODate
default getdate(),
CuID char(5) not null
constraint fk_Orderr_CuID
foreign key(CuID)
references ComDb.Customers(CuID)
on delete cascade
on update cascade,
BNO varchar(8) not null
constraint fk_Orderr_BNO
foreign key(BNO)
references ComDB.Branch(BNO)
on delete cascade
on update cascade,
StaffID varchar(7) not null
constraint fk_Orderr_StaffID
foreign key(StaffID)
references ComDB.Staff(StaffID)
on delete cascade
on update cascade,
DeAdd varchar(30)not null,
SubTotal money null,
TaxRate  money null,
DeliveryCharges money null,
Total money null
)

create table ComDB.OrderDetail
(
ONO char(7) not null
constraint fk_OrderDetail_ONO
foreign key(ONO)
references ComDB.Orderr(ONO)
on delete cascade
on update cascade,
ItemCode varchar(5) not null
constraint fk_OrderDetail_ItemCode
foreign key(ItemCode)
references ComDb.Item(ItemCode)
on delete cascade
on update cascade
constraint pk_OrderDetail_ONOItemCode
primary key(ONO,ItemCode),
Qty int not null
constraint check_OrderDetail_Qty
check(Qty>0),
Amount money null,
DiscountRate int null,
DiscountAmount money null,
TotalItemAmount money null
)




--Trigger starts from here
create trigger trg_update_orderdetail
on ComDB.OrderDetail
after insert
as
declare @ono char(7)
declare @itemcode varchar(5)
declare @qty int
declare @price money
declare @amount money
declare @discountrate int
declare @discountamount money
declare @totalitemamount money
set @ono=(select ONO from inserted)
set @itemcode=(select ItemCode from inserted)
set @qty=(select Qty from inserted)
set @price=(select UnitPrice from ComDb.Item where ItemCode=@itemcode)
set @amount=@qty*@price
if(@amount>0 and @amount<=50000)
set @discountrate=0
else if(@amount>=50001 and @amount<=200000)
set @discountrate=5
else if(@amount>=200001 and @amount<=400000)
set @discountrate=10
else
set @discountrate=15
set @discountamount=(@amount*@discountrate)/100
set @totalitemamount=(@amount-@discountamount)

update ComDb.OrderDetail
set Amount=@amount,DiscountRate=@discountrate,DiscountAmount=@discountamount,TotalItemAmount=@totalitemamount
where ONO=@ono and ItemCode=@itemcode


create trigger trg_update_Orderr
on ComDB.OrderDetail
after update
as
declare @ono char(7)
declare @subtotal money
declare @taxrate money
declare @total money
declare @deliverycharges money
declare @deadd varchar(30)
set @ono=(select ONO from inserted)
set @subtotal=(select sum(TotalItemAmount) from ComDB.OrderDetail where ONO=@ono)
set @taxrate=(@subtotal*6)/100
set @deadd=(select DeAdd from ComDB.Orderr where ONO=@ono)
set @deliverycharges=(select DeliveryCharges from ComDB.Orderr where ONO=@ono)
if (@deadd='Yangon') 
set @deliverycharges=0
else 
set @deliverycharges=5000
set @total=@subtotal+@taxrate+@deliverycharges
update ComDB.Orderr
set SubTotal=@subtotal,TaxRate=@taxrate,DeliveryCharges=@deliverycharges,Total=@total
where ONO=@ono


---trigger 3rd
create trigger trg_update_Orderr2
on ComDB.OrderDetail
after delete
as
declare @ono char(7)
declare @subtotal money
declare @taxrate money
declare @total money
declare @deliverycharges money
declare @deadd varchar(30)
set @ono=(select ONO from deleted)
set @subtotal=(select sum(TotalItemAmount) from ComDB.OrderDetail where ONO=@ono)
set @taxrate=(@subtotal*6)/100
set @deadd=(select DeAdd from ComDB.Orderr where ONO=@ono)
set @deliverycharges=(select DeliveryCharges from ComDB.Orderr where ONO=@ono)
--if (@deadd='Yangon') 
--set @deliverycharges=0
--else 
--set @deliverycharges=5000
set @total=@subtotal+@taxrate+@deliverycharges
update ComDB.Orderr
set SubTotal=@subtotal,TaxRate=@taxrate,DeliveryCharges=@deliverycharges,Total=@total
where ONO=@ono



--Customer Table insert start here

insert into ComDB.Customers 
values('C-001','U Maung Maung Soe','20(A), Monywa','09-54012346','maungmaungsoe@gmail.com')
insert into ComDB.Customers 
values('C-002','U Min Min','30(B), Yangon','09-55555546','minmin@gmail.com')
insert into ComDB.Customers 
values('C-003','U Zaw Zaw','999(C), Mandalay','09-45454546','zawzaw@gmail.com')
insert into ComDB.Customers 
values('C-004','Daw Thin Thin','44(KA), Taungyii','09-55457542','myomyou@gmail.com')
insert into ComDB.Customers 
values('C-005','Daw Hla Hla','902(CD), Kachin','09-37459140','hlahla@gmail.com')
insert into ComDB.Customers 
values('C-006','Daw Saw Hla Shwe','456(Z), Bago','09-78490546','sawhlashwe@gmail.com')
insert into ComDB.Customers 
values('C-007','U Min Thiha Oo','777(M), Yangon','09-98203481','minthihaoo@gmail.com')
insert into ComDB.Customers 
values('C-008','Daw Hla Htwe','987(B), Taungoo','09-90872671','hlahtwe@gmail.com')
insert into ComDB.Customers 
values('C-009','U Win Htein Win','289(C), Yangon','09-86009799','winhteinwin@gmail.com')
insert into ComDB.Customers 
values('C-010','Daw Hnin Hnin','871(N), Mandalay','09-90349812','hninhnin@gmail.com')

insert into ComDb.Branch
values('Branch-1','NO12,MingalardonTownship','naingmyanmarbr1@gmail.com','09-54012346')
insert into ComDb.Branch
values('Branch-2','NO199,MayangoneTownship','naingmyanmarbr2@gmail.com','09-98563892')
insert into ComDb.Branch
values('Branch-3','NO444,SanChaungTownship','naingmyanmarbr3@gmail.com','09-91836328')
insert into ComDb.Branch
values('Branch-4','NO876,BahanTownship','naingmyanmarbr4@gmail.com','09-98375843')
insert into ComDb.Branch
values('Branch-5','NO20DC,PabedanTownship','naingmyanmarbr5@gmail.com','09-98472345')
insert into ComDb.Branch
values('Branch-6','NOWE23,HlaingTownship','naingmyanmarbr6@gmail.com','09-78456372')
insert into ComDb.Branch
values('Branch-7','NO92SD,BotahtaungTownship','naingmyanmarbr7@gmail.com','09-10854932')
insert into ComDb.Branch
values('Branch-8','NO424,PasundunTownship','naingmyanmarbr8@gmail.com','09-78943784')
insert into ComDb.Branch
values('Branch-9','NO883C,TarmweTownship','naingmyanmarbr9@gmail.com','09-87934637')


insert into ComDB.Staff
values('IDN-001','Min Min')
insert into ComDB.Staff
values('IDN-002','Aung Aung')
insert into ComDB.Staff
values('IDN-003','Zaw Zaw')
insert into ComDB.Staff
values('IDN-004','Soe Soe')
insert into ComDB.Staff
values('IDN-005','Htwe Htwe')
insert into ComDB.Staff
values('IDN-006','Ei Ei')
insert into ComDB.Staff
values('IDN-007','Shwe Shwe')
insert into ComDB.Staff
values('IDN-008','Chit Chit')
insert into ComDB.Staff
values('IDN-009','Su Su')
insert into ComDB.Staff
values('IDN-010','Mar Mar')

insert into ComDB.Supplier
values('S-001','Win Kyaw','30(B), Sanchaung')

insert into ComDB.Item
values('AC','Café’ Table Cherry Top,blk base 36’ Rd',25000,'S-001')
insert into ComDB.Item
values('7P','chair,occasional,Blk,Tub 31w',20000,'S-001')
insert into ComDB.Item
values('8B','Buffet, 4"x3",brown ',500000,'S-001')
insert into ComDB.Item
values('9D','Wooden Glass chair',250000,'S-001')
insert into ComDb.Item
values ('8Z','Fiber Door Wooden Latch',555000,'S-001')
insert into ComDb.Item
values ('B4','Rockin Chair',350000,'S-001')
insert into ComDb.Item
values ('C3','Children Study Table',30000,'S-001')
insert into ComDb.Item
values ('4K','Gaming Desktop Table',480000,'S-001')
insert into ComDb.Item
values ('2T','Standing Table',340000,'S-001')
insert into ComDb.Item
values ('4L','Rounded Seating Set',750000,'S-001')

insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12345','4/6/2016','C-001','Branch-1','IDN-001','Monywa')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12341','1/24/2016','C-002','Branch-1','IDN-002','Yangon')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12342','1/16/2016','C-005','Branch-9','IDN-009','Kachin')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12343','1/28/2016','C-005','Branch-9','IDN-009','Kachin')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12344','1/28/2016','C-005','Branch-9','IDN-009','Kachin')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12340','5/8/2016','C-003','Branch-3','IDN-008','Mandalay')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12346','5/6/2016','C-004','Branch-2','IDN-004','Taungyii')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12347','4/22/2016','C-006','Branch-4','IDN-007','Bago')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12348','4/25/2016','C-007','Branch-5','IDN-005','Yangon')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12349','3/13/2016','C-008','Branch-6','IDN-003','Taungoo')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12350','6/16/2016','C-009','Branch-7','IDN-008','Yangon')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12351','3/22/2016','C-010','Branch-8','IDN-005','Mandalay')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12352','4/14/2016','C-002','Branch-9','IDN-006','Yangon')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12353','6/18/2016','C-004','Branch-9','IDN-002','Taungyii')
insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12354','6/18/2016','C-004','Branch-9','IDN-002','Taungyii')


insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12340','7P',2)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12345','AC',5)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12345','7P',20)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--1
values('O-12345','8B',6)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12341','9D',5)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12341','8Z',20)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12342','B4',6)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12342','8B',5)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--2
values('O-12342','4K',20)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12343','2T',6)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12343','4L',5)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--3
values('O-12343','8Z',20)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12344','C3',8)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12344','9D',5)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--4
values('O-12344','7P',10)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12346','8Z',4)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--6
values('O-12346','4K',9)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12347','9D',2)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--7
values('O-12347','8B',7)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12348','8B',4)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--8
values('O-12348','B4',2)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12349','8Z',11)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--9
values('O-12349','4K',15)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12350','AC',10)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--10
values('O-12350','C3',12)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--11
values('O-12351','4K',10)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12352','2T',3)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--12
values('O-12352','7P',9)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12353','8Z',8)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--13
values('O-12353','4L',20)--delete test
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)--13
values('O-12354','8Z',20)



select * from ComDb.Customers
select * from ComDb.Branch
select * from ComDb.Staff
select * from ComDb.Supplier

select * from ComDB.Item
select * from ComDb.Orderr
select * from ComDb.OrderDetail

drop table ComDB.OrderDetail
drop table ComDb.Orderr
drop table ComDb.Customers
drop table ComDB.Branch
drop table ComDb.Item
drop table ComDb.Staff
drop table comDb.Supplier

--Query ! starts here


------------------------------
--1st Real Query

select CName,ODate,sum(Total)as TotalOrderCost,count(ONO)as OrderTimes
from ComDB.Customers as c
left outer join ComDB.Orderr as o
on c.CuID=o.CuID
where Month(ODate)='01'
--where ODate='2016/06/18'
group by CName ,ODate
order by count(ONO) desc
------------------------------

--4th Real Query

select s.StaffID,s.StaffName,i.ItemDescription,sum(oo.Qty) as Qty
from ComDB.Staff as s
left outer join ComDB.Orderr as o
on s.StaffID=o.StaffID
left outer join ComDB.OrderDetail as oo
on o.ONO=oo.ONO
left outer join ComDB.Item as i
on oo.ItemCode=i.ItemCode
group by s.StaffID,s.StaffName,i.ItemDescription
having s.StaffID='IDN-002'
order by sum(oo.Qty)


--3rd Real Query
select Top 1 i.ItemCode,it.ItemDescription,it.UnitPrice,sum(Qty) SoldOutQuantities,count(ONO) as NoOfTimesOrdered
from ComDB.OrderDetail as i
right outer join ComDB.Item as it
on i.ItemCode=it.ItemCode
group by i.ItemCode,it.ItemDescription,it.UnitPrice
order by sum(Qty) desc



--6th Real Query
select c.CuID,c.CName,c.CPh,c.CAddress from ComDB.Customers as c 
where c.CAddress like'%Yangon%'


--5th Real Query
select CName,count(ONO)as OrderTimes
from ComDB.Customers as c
left outer join ComDB.Orderr as o
on c.CuID=o.CuID
where Month(ODate)='06'
group by CName 
order by count(ONO) desc

--7th Real Query
select top 1 StaffName,sum(Qty) as TotalQuantity
from ComDb.Staff as s
right outer join ComDB.Orderr as o
on  s.StaffID=o.StaffID
right outer join ComDb.OrderDetail as od
on o.ONO=od.ONO
--where s.StaffID='IDN-002'
group by StaffName
order by sum(Qty) desc

--2nd Real Query--(please delete ODate for assignment query becos ODate used for checking month)
select od.ItemCode,ItemDescription,sum(Qty) as TotalQuantity,sum(Amount) as TotalSaleAmount
from ComDB.Item as it
right outer join
ComDb.OrderDetail as od
on it.ItemCode=od.ItemCode
left outer join 
ComDb.Orderr as o
on od.ONO=o.ONO
where Month(ODate)='01' and Year(ODate)='2016'
group by od.ItemCode,ItemDescription
order by sum(Qty)


---End of Assignment...

delete from ComDB.OrderDetail
where ONO='O-12353' and ItemCode='4L'


delete from ComDB.Item
where ItemCode='8B'

update ComDB.Item
set ItemDescription='Rounded Seating Set'
where ItemCode='4L'










































select * from ComDB.OrderDetail
select * from ComDB.Orderr

select Cname from ComDb.Customers

---------
select Cname,

update ComDb.Orderr 
set DeAdd='Monywa'
where ONO='O-12345'
-----second data test
insert into ComDB.Customers 
values('C-002','U Soe Soe Maung','20(A), Yangon','09-55555546','soesoemaung@gmail.com')

insert into ComDb.Orderr(ONO,ODate,CuID,BNO,StaffID,DeAdd)
values('O-12344','5/7/2016','C-002','Branch-1','IDN-001','Yangon')

insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12344','AC',4)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12344','7P',5)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12344','8B',1)

------third data test
insert into ComDB.Customers 
values('C-003','U Myo Myo','999, Mandalay','09-55456546','myomyou@gmail.com')

insert into ComDb.Orderr(ONO,CuID,BNO,StaffID,DeAdd)
values('O-12343','C-002','Branch-1','IDN-001','Mandalay')

insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12343','AC',4)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12343','9D',5)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12343','8Z',1)

------fourth data test
insert into ComDB.Customers 
values('C-003','U Myo Myo','999, Mandalay','09-55456546','myomyou@gmail.com')

insert into ComDb.Orderr(ONO,CuID,BNO,StaffID,DeAdd)
values('O-12346','C-003','Branch-1','IDN-001','Mandalay')

insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12346','7P',6)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12346','9D',5)
insert into ComDB.OrderDetail(ONO,ItemCode,Qty)
values('O-12346','AC',3)
----End junk testing


'%_@__%._%'


Create table Student
(
StuID char(5) not null
constraint pk_student_StuID
primary key(StuID),
Name varchar(30) not null,
Phone varchar(30) not null
constraint chk_student_Phone
check(Phone like '09-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' or
Phone like '09-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
Email varchar(30) not null
constraint chk_student_Email
check(Email like '%_@__%._%'),
NRC varchar(30) not null
constraint unique_student_NRC
unique (NRC)
)

insert into Student values('S-001','man Heinz Kyaws',
'09-1234567890','pucci29@gmail.com',
'9/mhm(naing)050007')

select * from Student



	



