SELECT count(*) AS cnt 
FROM Transactions  
WHERE Date(timestamp) = Curdate() - INTERVAL 1 DAY AND coupon_code = @coupon_code  

result.length <= 100  

SELECT * 
FROM (  
  SELECT count(*) AS cnt 
FROM Transactions  
WHERE Date(timestamp) = Curdate() - INTERVAL 1 DAY AND coupon_code = @coupon_code  
) AS yesterday_user_counts  
WHERE cnt > 100;  

result.length == 0

