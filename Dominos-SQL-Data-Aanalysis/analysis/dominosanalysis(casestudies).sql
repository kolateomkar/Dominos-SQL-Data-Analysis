-- 1. Order Volume Analysis Queries
select count(distinct(order_id)) from orders;

--  How has this order volume changed month-over-month and year-over-year
-- month-over-month
with monthly_orders as(
select MONTH(order_date) as month,
COUNT(order_id) as order_count
from orders GROUP BY MONTH(order_date)
)

SELECT month, order_count,
LAG(order_count) OVER(order by month) as prev_month,
ROUND(100.0 * (order_count - LAG(order_count) OVER(order by month)) / nullif(LAG(order_count) OVER(order by month),0), 2 )
as mon_growth_perc
from monthly_orders
order by month;

-- year-over-over
with yearly_orders as(
select YEAR(order_date) as year,
COUNT(order_id) as order_count
from orders GROUP BY YEAR(order_date)
)

SELECT year, order_count,
LAG(order_count) OVER(order by year) as prev_year,
ROUND(100.0 * (order_count - LAG(order_count) OVER(order by year)) / nullif(LAG(order_count) OVER(order by year),0), 2 )
as year_growth_perc
from yearly_orders
order by year;

-- peak and off-peak order days??
select dayname(order_date) as weekday,
COUNT(distinct(order_id))as total_orders from orders group by dayname(order_date) order by total_orders desc; 

-- how do volume vary by day of the week
with daily_orders as(
select weekday(order_date) as day,
COUNT(order_id) as order_count
from orders GROUP BY weekday(order_date)
)

SELECT day, order_count,
LAG(order_count) OVER(order by day) as prev_day,
ROUND(100.0 * (order_count - LAG(order_count) OVER(order by day)) / nullif(LAG(order_count) OVER(order by day),0), 2 )
as day_growth_perc
from daily_orders;

-- weekdays vs weekends
with daily_orderss as (
select case
when weekday(order_date) in (5,6) THEN "weekend"
else "weekday"
end as day_type,
count(order_id) as order_count
from orders 
group by case
when weekday(order_date) in (5,6) then "weekend"
else "weekday"
end
)
select day_type, order_count from daily_orderss;


with daily_orderss as (
select DAYNAME(order_date) as day_name, WEEKDAY(order_date) as day_num,
case
when weekday(order_date) in (5,6) THEN "weekend"
else "weekday"
end as day_type,
count(order_id) as order_count
from orders 
group by DAYNAME(order_date), WEEKDAY(order_date),
case
when weekday(order_date) in (5,6) then "weekend"
else "weekday"
end
)
select day_name,day_type, order_count,
LAG(order_count) OVER(order by day_num) as prev_day_count,
ROUND(100.0 * (order_count - LAG(order_count) OVER(order by day_num)) / nullif(LAG(order_count) OVER(order by day_num),0), 2 )
as day_growth_perc
from daily_orderss
order by day_num;


-- avg order per customer
select ROUND(count(distinct order_id) * 1.0 / count(distinct custid), 2) as avg_order_per_cus
from orders;

-- who are our top customers driving the order volume
select c.custid,c.first_name,c.last_name,count(o.order_id) as total_orders 
from customers c join orders o on c.custid = o.custid 
group by o.custid, c.first_name, c.last_name order by count(o.order_id) desc;

-- can you also project the expected order growth trend based on historical details
   -- month-over-month trend

    -- cumulative order trend
    select order_date, count(order_id) as daily_orders,
    SUM(count(order_id)) OVER (order by order_date) as cumulative_count 
    from orders
    group by order_date order by order_date;
    
    -- total revenue
    select ROUND(sum(od.quantity * p.price),2) as total_revenue 
    from order_details od join pizzas p on od.pizza_id = p.pizza_id;
    
    -- 3.highest price pizza
    select pt.name, pt.category,p.size, CONCAT("$ " ,p.price) as price
    from pizza_types pt join pizzas p on pt.pizza_type_id = p.pizza_type_id 
    order by p.price desc;
    
    -- 4. most comman size pizza ordered
    select p.size, count(od.order_id) total_order from order_details od join pizzas p on od.pizza_id = p.pizza_id 
    group by p.size order by total_order desc;
    -- top 5 most ordered pizzas
     select pt.name,od.pizza_id, sum(od.quantity) as total_quantity 
     from order_details od join pizzas p on od.pizza_id = p.pizza_id 
     join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
     group by pt.name, od.pizza_id order by total_quantity desc;
     
     
     select pizza_id, sum(quantity) from order_details
     group by pizza_id order by sum(quantity) desc;
     
-- 6. total quantity by pizza category
     select pt.category, sum(od.quantity) as total_quantity from 
     order_details od join pizzas p on od.pizza_id = p.pizza_id 
     join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
     group by pt.category
     order by total_quantity desc;
     
-- 7. order by hour of the day
select HOUR(order_time ) as order_hour,
count(*) as order_count
from orders group by order_hour order by order_hour;

-- 8. category wise pizza distribution
     with cat_dis as(
     select pt.category as category, SUM(od.quantity) as total_quantity
     from order_details od join pizzas p on od.pizza_id = p.pizza_id
     join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
     group by pt.category
     )
     select category, total_quantity ,
     ROUND(total_quantity * 100.0 / SUM(total_quantity) OVER () ,2 ) as cat_per
     from cat_dis
     order by total_quantity desc;
     
     -- 9. avg pizzas ordered per day
     select ROUND(avg(daily_total),0) as avg_pizza_order_per_day
     from (select o.order_date, sum(od.quantity) as daily_total 
     from orders o join order_details od on o.order_id = od.order_id
     group by o.order_date) t;
     
-- 10.top 3 pizzas by revenue
     select pt.name, sum(p.price * od.quantity) as revenue,
     RANK() over(order by sum(p.price * od.quantity) desc) as rnk
     from pizzas p join order_details od on p.pizza_id = od.pizza_id 
     join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
     group by pt.name order by revenue desc ;
     
-- 11. revenue contribution per pizza
select pt.name, sum(p.price * od.quantity) as revenue,
CONCAT(ROUND(100 * sum(p.price * od.quantity) / sum(sum(p.price * od.quantity)) OVER() ,2)," %") as pct_contribution
from pizzas p join order_details od on p.pizza_id = od.pizza_id 
join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
group by pt.name order by pct_contribution desc ;

-- 12.cumulative revenue over time
 select 
 order_date,
 daily_revenue,
 SUM(daily_revenue) over(order by order_date) as cumulative_revenue 
 from
 (select o.order_date, ROUND(sum(od.quantity * p.price),2) as daily_revenue
 from orders o join order_details od on o.order_id = od.order_id
 join pizzas p on od.pizza_id = p.pizza_id
 group by (o.order_date)) t;
 
 -- 13. top 3 pizzas per category(revenue based)
with pizza_revenue as
(
select pt.name as name,pt.category as category, sum(p.price * od.quantity) as revenue
from pizzas p join order_details od on p.pizza_id = od.pizza_id 
join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
group by pt.name, pt.category order by revenue desc

),
ranked as
(select name, category,revenue , RANK() OVER(partition by category order by revenue desc) as rnk
from pizza_revenue)

select name, category, revenue,rnk from ranked where rnk <=3;

-- 14.top 10 customer by spending
select 
c.custid, c.first_name, c.last_name, sum(od.quantity),
ROUND(sum(od.quantity * p.price),2) total_spending 
from order_details od 
join orders o on od.order_id = o.order_id
join customers c on o.custid = c.custid  
join pizzas p on od.pizza_id = p.pizza_id
group by c.custid, c.first_name, c.last_name order by total_spending desc;

-- 15. orders by weekday
with daily_orders as(
select DAYNAME(order_date) as day_name, WEEKDAY(order_date) as day_num,
case when WEEKDAY(order_date) in (5,6) then "weekend"
else "weekday"
end as day_type,
count(order_id) as order_count
from orders 
group by day_name, day_num,
case 
when WEEKDAY(order_date) in (5,6) then "weekend"
else "weekday"
end)
select day_name,day_type, order_count from daily_orders
order by order_count desc;

-- avg order size 
select ROUND(avg(total_size),0) avg_order_size from(
select  order_id, sum(quantity) as total_size 
from order_details
group by order_id) t;


-- 17.seasonal trends
select MONTH(order_date) as month,
COUNT(order_id) as order_count
from orders GROUP BY MONTH(order_date);

-- 18.revenue by size
select p.size,sum(od.quantity) as revenue,
CONCAT(ROUND(100 * sum(od.quantity) / sum(sum(od.quantity)) over(),2), " %") as rev_contri
from order_details od join pizzas p on od.pizza_id = p.pizza_id
group by (p.size) order by revenue desc;

-- 19. customer segmentation
with cust_spend as (
select 
c.custid custid, c.first_name first_name, c.last_name last_name, sum(od.quantity) total_quantity,
ROUND(sum(od.quantity * p.price),2) as total_spending 
from order_details od 
join orders o on od.order_id = o.order_id
join customers c on o.custid = c.custid  
join pizzas p on od.pizza_id = p.pizza_id
group by c.custid, c.first_name, c.last_name )

select
custid, 
first_name,last_name,total_quantity,total_spending,
case
when total_spending > 81000 then "HIGH VALUE"
else "REGULAR" 
end as segment
from cust_spend
group by custid ,first_name,last_name,total_quantity,total_spending,case
when total_spending > 81000 then "HIGH VALUE"
else "REGULAR" 
end 
order by custid;

-- 20. repeat customer rate
with cust_orders as (
select custid, count(order_id) as order_count
from orders
group by custid)

select ROUND(100.0 *  sum(case when order_count > 2050  then 1 else 0 end) / count(*),2) as repeat_rate
from cust_orders; 