SELECT *  
FROM (  
  SELECT user_id, count(*) AS cnt 
FROM Transactions 
  WHERE Date(timestamp) = Curdate() - INTERVAL 1 DAY  
  GROUP BY user_id  
) AS yesterday_user_counts  
WHERE cnt > 5;  
 
result.length == 0

