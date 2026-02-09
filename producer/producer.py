"""
Replay weather events from a local JSON file into Kinesis.

This simulates real-time streaming without repeatedly calling the
OpenWeatherMap API (rate-limited).
"""

import json
import time
from pathlib import Path

import boto3

# -------- Configuration --------

STREAM_NAME = "weather-streaming-weather-stream"
REGION = "us-east-1"

DATA_FILE = Path(__file__).parent / "data" / "weather.json"

# -------------------------------

kinesis = boto3.client("kinesis", region_name=REGION)


def main() -> None:
    # Load previously fetched weather data
    with open(DATA_FILE, "r") as f:
        payload = json.load(f)

    lat = payload["lat"]
    lon = payload["lon"]

    print(f"Replaying {len(payload['minutely'])} events to Kinesis...")

    for event in payload["minutely"]:
        record = {
            "lat": lat,
            "lon": lon,
            "timestamp": event["dt"],          # UNIX seconds (event time)
            "precipitation_mm": event["precipitation"]
        }

        kinesis.put_record(
            StreamName=STREAM_NAME,
            Data=json.dumps(record),
            PartitionKey=f"{lat}_{lon}"
        )

        print("Sent:", record)

        # Small delay to simulate streaming
        time.sleep(0.1)


if __name__ == "__main__":
    main()
