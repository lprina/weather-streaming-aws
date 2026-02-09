import json
import base64
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

CET = ZoneInfo("Europe/Amsterdam")  # CET/CEST-safe


def lambda_handler(event, context):
    print(f"Received {len(event['Records'])} records")

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

        print(json.dumps(enriched))
