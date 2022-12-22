-- --Adding a Column named age of a customer
-- Alter table "CustomerDemographics"
-- add column age numeric

-- update "CustomerDemographics"
-- set age = round(extract (year from AGE(current_date,"DOB")) +  extract(month from AGE(current_date,"DOB"))/12,2)

-- --Adding a column named profit
-- Alter table "Transactions"
-- add column profit numeric

-- update "Transactions"
-- set profit = list_price-standard_cost

-- The total Profit made from selling bikes
select extract(month from transaction_date) as month,round(sum(profit)) as Total_Profit from "Transactions"
where order_status='Approved'
group by month
order by month

--Total Transactions made by all customers
select count(customer_id) from "Transactions"

--Total number of deceased customers
select count(deceased_indicator) as Deceased from "CustomerDemographics"
where deceased_indicator='Y'

-- Monthly profit and the number of purchases made by each brand 
with brand_profit as (select customer_id,extract (month from transaction_date) as month,brand, transaction_date ,sum(profit) over(partition by brand, extract (month from transaction_date)) as profit
from "Transactions"
where order_status='Approved' and brand is not null
order by brand,MONTH)

select brand,month,count(*) as number_of_purchases,profit
from brand_profit
group by month,brand,profit
order by brand,month

-- percentage of online vs offline transactions
with online_order as (select online_order,count(online_order) from "Transactions"
			where online_order is not null
group by online_order
)
select online_order,round((100*count::decimal/total),3) as percentage from(
select *,sum(count) over() as total from online_order)a

-- Total purchases made in every state
with cust_info as(select * from "CustomerDemographics" d left join "CustomerAddress" c on d.Customer_id=c.customer_id)

select distinct state,sum(past_3_years_bike_related_purchases) over (partition by state) as total_purchase from cust_info
where state is not null
order by total_purchase desc

--Classifying age groups
with cust_age(customer_id,wealth_segment,past_3_years_bike_related_purchases,age,age_range) as(select d.customer_id,wealth_segment,past_3_years_bike_related_purchases,age,
  case
   when age <18 then 'Under 18'
   when age >=18 and age<=24 then '18-24'
   when age >24 and age<=34 then '25-34'
   when age >34 and age<=44 then '35-44'
   when age >44 and age<=60 then '45-60'
   when age >60  then 'Above 60'
 END as age_range from "CustomerDemographics" d join "Transactions" t on d.customer_id=t.customer_id
 where age is not null)

-- Number of customers belonging to various age groups
select age_range,count(*) as customer_count from cust_age
group by age_range
order by age_range

-- status of cars owned in every state
with cust_state as(
select * from "CustomerDemographics" a 
join "CustomerAddress" t on a.customer_id=t.customer_id)
	
select state,owns_car,count as customer_count,round(100*count::decimal/sum,2) as percentage from(
select state,owns_car,sum(count) over(partition by state),count from(
select count(*),state,owns_car from cust_state
where deceased_indicator='N'
group by state,owns_car
order by state,owns_car)a)b

--Past 3 year bike purchases of every brand by each gender
select c.gender,t.product_line,sum(c.past_3_years_bike_related_purchases) as past_3_years_bike_related_purchases from "CustomerDemographics" c join "Transactions" t on t.customer_id = c.customer_id
where c.deceased_indicator='N' and t.order_status='Approved' and t.product_line is not null
group by c.gender,t.product_line
order by t.product_line,c.gender

--Number of customers belonging to each Wealth segment
select wealth_segment,count(wealth_segment) from "CustomerDemographics"
group by wealth_segment

--Customers with different age group belonging to each wealth segment and their past 3 year purchases
select wealth_segment,age_range,sum(past_3_years_bike_related_purchases) as past_3_years_bike_related_purchases from cust_age where age is not null
group by wealth_segment,age_range
order by wealth_segment,age_range

--Transactions made by customer belonging to various job industries
select job_industry_category , count(*) as transaction_count from "CustomerDemographics" c join "Transactions" t on t.customer_id = c.customer_id
group by job_industry_category
order by transaction_count

--Percentage of orders cancelled in every region
with cte as(select state,order_status,count(order_status) as status from "Transactions" t join "CustomerAddress" a on a.customer_id = t.customer_id
where order_status = 'Cancelled'									 
group by state,order_status)
select state,order_status,round(100*status::decimal/(select sum(status) from cte),2) as percentage from cte
order by state, order_status

--Top ten most customers from each job title
select job_title,count(job_title) as no_customer from "CustomerDemographics"
where job_title is not null
group by job_title
order by no_customer desc
limit 10

--RFM Modelling

--fetching details of frequency,recency and profit
create view rfm as select d.customer_id,count(*) as frequency,sum(profit) as profit,min((select max(transaction_date) from "Transactions")-transaction_date) as recency from "CustomerDemographics" d join "Transactions" t on t.customer_id = d.customer_id
group by d.customer_id
order by d.customer_id

--grouping frequency on the basis of quartiles
create view freq as select customer_id,frequency, row_number() over(order by frequency) as num from rfm

create view fscore as
select customer_id,frequency,
case 
when frequency >= (select min(frequency)from freq) and frequency <(select frequency from freq where num in (((select count(*) from freq)+1)/4)) then 1 
when frequency >= (select frequency from freq where num in ((((select count(*) from freq)+1)/4))) and frequency<(select frequency from freq where num in (2*((select count(*) from freq)+1)/4)) then 2
when frequency >= (select frequency from freq where num in ((2*((select count(*) from freq)+1)/4))) and frequency< (select frequency from freq where num in (3*((select count(*) from freq)+1)/4)) then 3
when frequency >= (select frequency from freq where num in ((3*((select count(*) from freq)+1)/4))) and frequency<=(select max(frequency) from freq) then 4 end as f_score
from freq

--grouping recency on the basis of quartiles
create view rec as select customer_id,recency, row_number() over(order by recency desc) as num from rfm

create view rscore as
select customer_id,recency,
case 
when recency <= (select max(recency)from rec) and recency >(select recency from rec where num in (((select count(*) from rec)+1)/4)) then 1 
when recency <= (select recency from rec where num in ((((select count(*) from rec)+1)/4))) and recency>(select recency from rec where num in (2*((select count(*) from rec)+1)/4)) then 2
when recency <= (select recency from rec where num in ((2*((select count(*) from rec)+1)/4))) and recency> (select recency from rec where num in (3*((select count(*) from rec)+1)/4)) then 3
when recency <= (select recency from rec where num in ((3*((select count(*) from rec)+1)/4))) and recency>=(select min(recency) from rec) then 4 end as r_score
from rec

--grouping monetary on the basis of quartiles
create view prof as select customer_id,profit, row_number() over(order by profit desc) as num from rfm

create view mscore as
select customer_id,profit,
case 
when profit >= (select min(profit)from prof) and profit <(select profit from prof where num in (((select count(*) from prof)+1)/4)) then 1 
when profit >= (select profit from prof where num in ((((select count(*) from prof)+1)/4))) and profit<(select profit from prof where num in (2*((select count(*) from prof)+1)/4)) then 2
when profit >= (select profit from prof where num in ((2*((select count(*) from prof)+1)/4))) and profit< (select profit from prof where num in (3*((select count(*) from prof)+1)/4)) then 3
when profit >= (select profit from prof where num in ((3*((select count(*) from prof)+1)/4))) and profit<=(select max(profit) from prof) then 4 end as m_score
from prof


--Combining all recency,frequency and monetary scores 
create view rfm_val as
	select f.customer_id,f.frequency,f_score,m.profit,m_score,r.recency,r_score, (r_score*100+f_Score*10+m_score) as rfm_score
	from fscore f 
	join mscore m on f.customer_id=m.customer_id
	join rscore r on m.customer_id=r.customer_id
	order by rfm_score desc


--Grouping customers into 5 categories based on their RFM scores
create view rfm_num as select *, row_number() over(order by rfm_score desc) as num from rfm_val

create view cust_category as
select customer_id,recency,frequency,profit,rfm_score,
case 
when rfm_score >= (select min(rfm_score)from rfm_num) and rfm_score <(select rfm_score from rfm_num where num in (4*((select count(*) from rfm_num)+1)/5)) then 'Evasive Buyer'
when rfm_score >= (select rfm_score from rfm_num where num in ((4*((select count(*) from rfm_num)+1)/5))) and rfm_score<(select rfm_score from rfm_num where num in (3*((select count(*) from rfm_num)+1)/5)) then 'Rare Buyer'
when rfm_score >= (select rfm_score from rfm_num where num in ((3*((select count(*) from rfm_num)+1)/5))) and rfm_score<(select rfm_score from rfm_num where num in (2*((select count(*) from rfm_num)+1)/5)) then 'Average Buyer'
when rfm_score >= (select rfm_score from rfm_num where num in ((2*((select count(*) from rfm_num)+1)/5))) and rfm_score<(select rfm_score from rfm_num where num in (((select count(*) from rfm_num)+1)/5)) then 'Frequent Buyer'
when rfm_score >= (select rfm_score from rfm_num where num in ((((select count(*) from rfm_num)+1)/5))) and rfm_score<=(select max(rfm_score) from rfm_num) then 'Loyal Buyer' end as title
from rfm_num

-- Number of customers belonging to each category
select title,count(*) as customer_count from cust_category
group by title
order by customer_count desc

--Average montly profit made by each category
select title,extract(month from transaction_date) as month, 
round(avg(c.profit),2) as average_profit from "Transactions" t join cust_category c on t.customer_id= c.customer_id
group by title,month
order by title,month

--Customer category status in every state
select state,title,count(*) as number_of_customers from cust_category c join "CustomerAddress" a on c.customer_id = a.customer_id
group by state,title
order by state

--Top 1000 Customers to target based on their recency,monetary and frequency of purchase
select c.customer_id,first_name,last_name,gender,extract (year from AGE(current_date,"DOB")) as age, title
from cust_category c join "CustomerDemographics" d on c.customer_id=d.customer_id
order by rfm_score DESC
limit 1000

--Customers in each age range according to their category
select title,age_range,count(*) as customer_count from cust_age a join cust_category b on a.customer_id=b.customer_id
group by title,age_range
order by title,age_range



