SELECT {yesterday_date}, word, COUNT(*)  
FROM word_day_bucket  
GROUP BY {yesterday_date}, word

