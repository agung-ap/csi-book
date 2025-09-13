SELECT *  
FROM sales_na S JOIN country_codes C ON S.country_code = C.id  
WHERE C.region != ‘NA’;  

result.length == 0

