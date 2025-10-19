use dominos_db;
select * from customers;
select * from orders;
/*cleaning data*/
select min(custid) from customers group by email; /* find duplicate record */
delete from customers where custid not in (select min(custid) from customers group by email);

select custid, ROW_NUMBER() OVER(partition by email order by custid) as rn from customers;

delete from customers 
where custid IN (select custid from (
select custid, ROW_NUMBER() OVER(partition by email order by custid) 
as rn from customers)t
where t.rn > 1
);

-- check for null values
select count(*) from customers;
select count(*) from customers where phone is null OR
first_name is null OR
last_name is null OR
email is null OR 
address is null;

-- replace null values
update customers set phone = "0" where phone is null; -- for other columns

-- handling negative values 
select * from order_details where quantity < 1;
update order_details set quantity = '0' where quantity <1;

-- fixing inconsistent date format & invalid dates
select  order_id, order_date from orders where order_date  NOT regexp '^(19|20)[0-9]{2}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$';
-- insert into orders values(1001,'2015-09-33','11:30:34',111,"success");
-- delete from orders where order_id = 1001 ;
SET SQL_SAFE_UPDATES = 0;

-- find and fix invalid email address
select custid, email from customers where email NOT regexp '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-za-z]{2,}$';

-- fixing datatypes 


