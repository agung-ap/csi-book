INSERT INTO sample_table (%(id), ‘UP’);  
INSERT INTO sample_table (%(id), ‘DOWN’);  
SELECT (  
  SELECT Count(*) FROM sample_table WHERE counter = ‘UP’  
) - (  
  SELECT Count(*) FROM sample_table WHERE counter = ‘DOWN’  
);

