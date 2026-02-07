select * from transactions;
select * from receivers;
-- 1) Total number of transactions → COUNT(*)
select count(*) as total_transaction from transactions;   

-- 2)Total transaction amount → SUM(amount)
select sum(amount) as total_transaction_amount from transactions;
   
-- 3)Average, max, min transaction amount 
select round(avg(amount),2) as average_transaction_amount,
round(max(amount),2) as maximum_transaction_amount,
round(min(amount),2) as minimum_transaction_amount
 from transactions;                           
 
 -- 4)Find the total number of transactions for each transaction_type                     .
 select transaction_type,count(transaction_id) as total_TransactionCount
 from transactions
 group by transaction_type
 order by total_TransactionCount desc;
 
 -- 5)Find the total transaction amount for each transaction_type          
 select transaction_type, SUM(amount) as total_TransactionAmount
  from transactions
 group by transaction_type;
 
 -- 6)Find the total number of transactions that occurred in each time_step (hour).

select time_step,count(transaction_id) as transaction_count_per_hour
from transactions
group by time_step
order by time_step;

-- 7)Find the number of fraud cases (fraud = 1) that occurred in each time_step (hour)
select t.time_step as transaction_count_per_hour , 
count(case when r.fraud=1 then 1 end) as fraud_count
from transactions t 
join receivers r
on t.transaction_id =r.transaction_id
group by t.time_step 
order by t.time_step;

-- 8)to find the overall fraud rate-- 
select sum(case when fraud =1 then 1 else 0 end)*1.0/count(*)
 as overall_fraud_rate
from receivers;

-- 9)Fraud rate by type 
select t.transaction_type ,
(sum(case when r.fraud=1 then 1 else 0 end )* 1.0 /count(*)) * 100 
as fraud_rate_by_type 
from transactions t
 join receivers r 
  on t.transaction_id = r.transaction_id
 group by t.transaction_type;

-- 10) Identify the top 10 largest transactions based on the transaction amount. 
select transaction_id, amount
from transactions 
order by amount desc
limit 10;

-- 11) top 10 senders by total sent amount                                                                 
select s.sender_id,sum(t.amount) as total_sent_amount
from transactions t 
join senders s 
on t.transaction_id = s.transaction_id 
group by s.sender_id
order by  total_sent_amount desc
limit 10;

-- 12)Senders with balance = 0 after transactions → WHERE sender_new_balance = 0
select sender_old_balance,sender_new_balance
from senders
where sender_new_balance =0;  -- //no any o balance

-- 13) Receivers count by type (C vs M)
select 
CASE 
WHEN receiver_id Like "M%" then"Merchant"
WHEN receiver_id Like "C%" then"Customer"
end as receiver_type,count(*) as receiver_count
from receivers
group by receiver_type;

-- 14)Fraud rate for M receivers 
select 
sum(fraud)*1.0 /count(*) as ReceiverFraudRateForMerchant
from receivers
where receiver_id Like "M%";


-- 15)Fraud rate for C receivers 
select 
sum(fraud)*1.0 /count(*) as  ReceiverFraudRateForCustomer
from receivers
where receiver_id Like "C%";  -- //no any value

 -- 16)Top 10 receivers by total incoming money 
select r.receiver_id , sum(t.amount) as total_incoming_amount
from transactions t 
join receivers r 
on t.transaction_id =r.transaction_id
group by r.receiver_id
order by total_incoming_amount desc 
limit 10;

-- 17)balance change vs no change
SELECT 
    SUM(CASE WHEN receiver_old_balance = receiver_new_balance THEN 1 ELSE 0 END)
    AS no_balance_change,
    SUM(CASE WHEN receiver_old_balance != receiver_new_balance THEN 1 ELSE 0 END)
    AS with_balance_change
FROM receivers;

-- 18)Bucket transactions (small/medium/large) → 
SELECT 
    CASE 
        WHEN amount < 500000 THEN 'Small'
        WHEN amount BETWEEN 500000 AND 1500000 THEN 'Medium'
        ELSE 'Large'
    END AS transaction_range,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY transaction_range
ORDER BY transaction_count DESC;

-- 19) Most risky hours (highest fraud %)
select t.time_step ,
sum(r.fraud)*1.0/count(*)*100 as fraud_percent
from transactions t 
join receivers r
on t.transaction_id = r.transaction_id 
group by t.time_step 
order by fraud_percent desc;

-- 20)Largest transaction per type 
select transaction_id,transaction_type,amount
from(
select  t.transaction_id,t.transaction_type,t.amount,
row_number() over (partition by t.transaction_type order by t.amount desc)as rn from
transactions t ) ranked where rn =1;

-- 21)Rank receivers by fraud amount 
select receiver_id, sum(t.amount) as total_fraud_amount,
rank() over (order by sum(t.amount) desc ) as fraud_rank
from transactions t
join receivers r
on t.transaction_id = r.transaction_id
group by receiver_id
order by  total_fraud_amount desc;

-- 22) Senders with repeated fraud cases 
SELECT s.sender_id,
       SUM(CASE WHEN r.fraud = 1 THEN 1 ELSE 0 END) AS fraud_count
FROM transactions t
JOIN receivers r ON t.transaction_id = r.transaction_id
JOIN senders   s ON t.transaction_id = s.transaction_id
GROUP BY s.sender_id
HAVING SUM(CASE WHEN r.fraud = 1 THEN 1 ELSE 0 END) >= 1
ORDER BY fraud_count DESC;

-- 23)How effective is the bank’s rule (isFlaggedFraud)?
SELECT
  SUM(CASE WHEN flagged_fraud = 1 AND fraud = 1 THEN 1 END) AS true_positives,
  SUM(CASE WHEN flagged_fraud = 1 AND fraud = 0 THEN 1 END) AS false_positives,
  SUM(CASE WHEN flagged_fraud = 0 AND fraud = 1 THEN 1 END) AS false_negatives
FROM receivers;

-- 24)Top flagged but not fraud (false positives) transactions
SELECT t.transaction_id, t.amount, t.transaction_type
FROM transactions t
JOIN receivers r ON t.transaction_id = r.transaction_id
WHERE r.flagged_fraud = 1 AND r.fraud = 0
ORDER BY t.amount DESC
LIMIT 10;