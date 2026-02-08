from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    from_json,
    window,
    sum as spark_sum,
    to_timestamp,
    from_unixtime,
)
from pyspark.sql.types import StructType, StructField, DoubleType, LongType

POSTGRES_URL = "jdbc:postgresql://YOUR_RDS_ENDPOINT:5432/weather"
POSTGRES_TABLE = "hourly_precipitation"
POSTGRES_PROPS = {
    "user": "weather_user",
    "password": "weather_pass",
    "driver": "org.postgresql.Driver",
}

def write_to_postgres(batch_df, batch_id):
    (
        batch_df
        .write
        .mode("append")
        .jdbc(
            url=POSTGRES_URL,
            table=POSTGRES_TABLE,
            properties=POSTGRES_PROPS,
        )
    )

def main():
    spark = (
        SparkSession.builder
        .appName("WeatherStreamingConsumer")
        .getOrCreate()
    )

    spark.sparkContext.setLogLevel("WARN")

    schema = StructType([
        StructField("lat", DoubleType(), False),
        StructField("lon", DoubleType(), False),
        StructField("timestamp", LongType(), False),
        StructField("precipitation_mm", DoubleType(), False),
    ])

    raw_df = (
        spark.readStream
        .format("kinesis")
        .option("streamName", "weather-stream")
        .option("region", "us-east-1")
        .option("startingposition", "TRIM_HORIZON")
        .load()
    )

    parsed_df = (
        raw_df
        .select(from_json(col("data").cast("string"), schema).alias("d"))
        .select("d.*")
        .withColumn(
            "event_time",
            to_timestamp(from_unixtime(col("timestamp")))
        )
    )

    aggregated_df = (
        parsed_df
        .withWatermark("event_time", "1 hour")
        .groupBy(
            window(col("event_time"), "1 hour"),
            col("lat"),
            col("lon"),
        )
        .agg(
            spark_sum("precipitation_mm").alias("total_precipitation_mm")
        )
    )

    (
        aggregated_df
        .writeStream
        .outputMode("update")
        .foreachBatch(write_to_postgres)
        .option("checkpointLocation", "s3://weather-checkpoints/streaming/")
        .start()
        .awaitTermination()
    )

if __name__ == "__main__":
    main()
