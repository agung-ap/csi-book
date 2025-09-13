SELECT s.timestamp, user_id, d.word  
FROM search_log s JOIN dictionary d ON s.search_term = d.word  
WHERE CAST(s.timestamp AS DATE) > “{yesterday_date}”  
  AND CAST(s.timestamp AS DATE) <= “{today_date}”

