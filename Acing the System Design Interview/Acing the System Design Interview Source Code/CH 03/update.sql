UPDATE sample_table SET counter = counter + 1 WHERE sample_id = %(id);  
UPDATE sample_table SET counter = counter - 1 WHERE sample_id = %(id);  
SELECT counter FROM sample_table WHERE sample_id = %(id);

