import json
import time
import requests
import boto3

STREAM_NAME = "weather-stream"
REGION = "us-east-1"

kinesis = boto3.client("kinesis", region_name=REGION)

URL = (
    "https://api.openweathermap.org/data/3.0/onecall"
    "?lat=52.084516"
    "&lon=5.115539"
    "&exclude=hourly,daily,current"
    "&units=metric"
    "&appid=YOUR_API_KEY"
)

def main():
    response = requests.get(URL)
    response.raise_for_status()
    payload = response.json()

    lat = payload["lat"]
    lon = payload["lon"]

    for event in payload["minutely"]:
        record = {
            "lat": lat,
            "lon": lon,
            "timestamp": event["dt"],              # UNIX seconds
            "precipitation_mm": event["precipitation"]
        }

        kinesis.put_record(
            StreamName=STREAM_NAME,
            Data=json.dumps(record),
            PartitionKey=f"{lat}_{lon}"
        )

        print("Sent:", record)
        time.sleep(0.05)  # optional pacing for realism


if __name__ == "__main__":
    main()
