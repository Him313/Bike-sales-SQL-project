# Bike-sales-SQL-project
Domain: Sales Transactions

Created by :- Himanshu Gusain

Posted on : 22-12-2022

Tool used:- PostgreSQL

Concepts used : Views, Aggregate Funcions, CTE table, Windows functions, Joins.

Dataset Info: 
1) Transaction Table : Contains 20000 records detailing all of the transactions customers made for the bike.
2) Customer Demographics : Consists of 4000 personal records of all customers.
3) Customer Address : consists of 4000 records of customer locations.

Business problem: So, in a hypothetical case, a company named XYZ that is new to the market would like to generate more profit, and in order to do so, they would like to target the top 1000 customers from three major states in Australia.
They have also requested a market demographic analysis to better understand who their customers are.

Approach: In this project, I conducted basic exploratory and RFM analyses,  
I investigated data on total profit made from selling and total transactions made, analysis of how much other brands have sold and profited, purchase trends in each state and among different age groups, percentage of online and offline transactions, the status of cars owned, past 3-year bike purchases of every brand by each gender, customer distribution based on wealth segment, and job title information regarding which state has the highest cancellation rate.
In the second half of the project, I performed RFM modeling. 
RFM analysis is a marketing technique that is used to quantitatively rank and group customers based on the recency, frequency, and monetary total of their most recent transactions in order to identify the best customers and conduct targeted marketing campaigns.
Through case statements, I have performed quartile segmentation of recency, monetary, and frequency. Adding all scores Customers were assigned a category based on their RFM scores, which ranged from loyal to evasive.
Following the categorization of customers, various pieces of information were extracted, such as the number of customers in each category and state, as well as their age group, which provides a rough estimate of the number of devoted customers, the average monthly profit by category, which reveals information about each category's performance, and finally, the top 1000 Customers to target based on their recent, monetary, and frequency of purchase.
