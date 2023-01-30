# 1 list of markets in apac region
SELECT distinct market
FROM gdb023.dim_customer
where customer = "AtliQ Exclusive" and region = "APAc";

# 2 percentage of unique product increase in 2021 vs. 2020
with cte1 as (select 
count(distinct 
case	
	when fiscal_year = 2020 then product_code    
end) as unique_product_2020,

count(distinct
case	
	when fiscal_year = 2021 then product_code    
end) as unique_product_2021    

from fact_sales_monthly)   

select unique_product_2020, unique_product_2021,
concat(round((unique_product_2021 - unique_product_2020)/ unique_product_2020 * 100,2), "%") as percentage_chg

from cte1;



# 3 all the unique product counts for each segment in desc
select segment, count(distinct (product_code)) as product_count
from dim_product
group by segment
order by count(product_code) desc;

# 4. which segment had most increase in unique products in 2021 vs 2020
with cte3 as(
	select p.product, p.product_code, p.segment, s.fiscal_year
	from dim_product p
	join fact_sales_monthly s
	on p.product_code = s.product_code),
cte4 as( select segment,
    count(distinct 
    case
    when cte3.fiscal_year = 2020 then cte3.product
    end) as product_count_2020,
    count(distinct 
    case
    when cte3.fiscal_year = 2021 then cte3.product
    end) as product_count_2021
    from cte3
    group by segment)
select segment, product_count_2020, product_count_2021,
		product_count_2021-product_count_2020 as difference
        from cte4;


# 5. products that have the highest and lowest manufacturing costs
select	p.product_code, p.product, mc.manufacturing_cost
from fact_manufacturing_cost mc
join dim_product p
on mc.product_code = p.product_code
where manufacturing_cost = 
	(select max(manufacturing_cost) from fact_manufacturing_cost)
or manufacturing_cost = 
	(select min(manufacturing_cost) from fact_manufacturing_cost); 
    

# 6. Top 5 customers who received avg high pre invoice discount % for fiscal yr 2021 in indian market
with cte5 as (
	select c.customer_code, c.customer, c.market, d.fiscal_year, d.pre_invoice_discount_pct
	from dim_customer c
	join fact_pre_invoice_deductions d
	on c.customer_code = d.customer_code)
select customer, customer_code, round(avg(pre_invoice_discount_pct),2) as Average_discount_percentage
from cte5
where market = "India" and fiscal_year = "2021"
group by customer, customer_code
order by avg(pre_invoice_discount_pct) desc
limit 5;

# 7. gross sales amount by month
select month(s.date) as Month, year(s.date) as Year, sum(g.gross_price * s.sold_quantity) as Gross_Sales_amount
from dim_customer c
join fact_sales_monthly s
on c.customer_code = s.customer_code
join fact_gross_price g
on g.product_code = s.product_code
where customer = "AtliQ Exclusive"
group by Month, Year
order by Month;


# 8. quarter wise quanities sold. . Note that fiscal_year
#For Atliq Hardware starts from September(09)

select 
	case
    when month(date) in (9,10,11) then "1st Quarter"
	 when month(date) in (12,1,2) then "2nd Quarter"
      when month(date) in (3,4,5) then "3rd Quarter"
       when month(date) in (6,7,8) then "4th Quarter"
	end as Quarter,
    sum(sold_quantity) as Total_quantity
from fact_sales_monthly
where fiscal_year = "2020"
group by Quarter
order by sum(sold_quantity) desc;

#9. which channel helped to bring more gross sales in 2021 and % of contribution
with cte6 as(
	select channel,
	round(sum(g.gross_price * s.sold_quantity)/1000000,2) as Gross_sales_mln
	from dim_customer c
	join fact_sales_monthly s
	on c.customer_code = s.customer_code
	join fact_gross_price g
	on g.product_code = s.product_code
	where s.fiscal_year = "2021"
	group by channel
	order by Gross_sales_mln)
    
select * , (Gross_sales_mln * 100)/ sum(Gross_sales_mln)
over() as Percentage
from cte6;


#10. Top 3 products in each division that have a high total_sold_quantity in the 2021
with cte7 as(
	select p.division, p.product, p.product_code, sum(s.sold_quantity) as Total_sold_quantity
	from dim_product p
	join fact_sales_monthly s
	on p.product_code = s.product_code
	where s.fiscal_year = "2021"
	group by p.division,p.product, p.product_code),
cte8 as (select *,
	dense_rank() over( partition by division
    order by Total_sold_quantity desc) as Rank_order
    from cte7)

select * from cte8 where Rank_order <=3;








