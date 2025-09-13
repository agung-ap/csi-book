SELECT COUNT(*) AS cnt 
FROM Transactions  
WHERE code_id = @code_id AND Date(timestamp) > @date AND Date(timestamp) = Curdate() - INTERVAL 1 DAY

