val spark = SparkSession.builder().appName(“Our app”).config(“some.config”, “value”).getOrCreate()  
val df = spark.sparkContext.textFile({hdfs_file})  
df.createOrReplaceTempView({table_name})  
spark.sql({spark_sql_query_with_table_name}).saveAsTextFile({hdfs_directory})

