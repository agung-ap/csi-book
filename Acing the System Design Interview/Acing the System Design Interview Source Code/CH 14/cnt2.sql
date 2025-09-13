SELECT user_id, count(*) AS cnt 
FROM Transactions  
WHERE Date(timestamp) = Curdate() - INTERVAL 1 DAY  
GROUP BY user_id  

result.length <= 5

