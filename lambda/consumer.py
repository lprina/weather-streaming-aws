import json
import base64
import boto3
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

s3 = boto3.client("s3")

BUCKET = "weather-streaming-data-dev"
PREFIX = "weather/minutely"

CET = ZoneInfo("Europe/Amsterdam")  # CET/CEST-safe


def lambda_handler(event, context):
    print(f"Received {len(event['Records'])} records")

    output_lines = []

    for record in event["Records"]:
        payload = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
        data = json.loads(payload)

        # UNIX seconds → timezone-aware datetime
        ts_utc = datetime.fromtimestamp(
            data["timestamp"], tz=timezone.utc
        )
        ts_cet = ts_utc.astimezone(CET)

        enriched = {
            "lat": data["lat"],
            "lon": data["lon"],
            "precipitation_mm": data["precipitation_mm"],
            "timestamp_utc": ts_utc.isoformat(),
            "timestamp_cet": ts_cet.isoformat(),
        }

        output_lines.append(json.dumps(enriched))

    if not output_lines:
        print("No records to write")
        return {"status": "empty"}

    now = datetime.now(tz=CET)
    key = (
        f"{PREFIX}/"
        f"year={now.year}/month={now.month:02d}/day={now.day:02d}/"
        f"events_{now.strftime('%H%M%S')}.jsonl"
    )

    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body="\n".join(output_lines).encode("utf-8"),
    )

    print(f"Wrote {len(output_lines)} records to s3://{BUCKET}/{key}")

    return {
        "records_written": len(output_lines),
        "s3_key": key,
    }
