SELECT COUNT(*) AS cnt  
FROM Transactions  
WHERE Date(timestamp) >= Curdate() - INTERVAL 1 DAY

