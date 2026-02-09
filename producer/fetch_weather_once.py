"""
Fetch a single OpenWeatherMap One Call API response and store it locally.

This script is intended to be run once during development to avoid exceeding
the OpenWeatherMap daily API rate limit. The stored JSON file can later be
replayed by the ingestion service to simulate a real-time data stream.
"""

import json
import requests
from pathlib import Path

API_KEY = "87600d4493f574b1d19f7cf6c247a6eb"

LAT = 52.084516
LON = 5.115539

URL = (
    "https://api.openweathermap.org/data/3.0/onecall"
    f"?lat={LAT}&lon={LON}"
    "&exclude=hourly,daily,current"
    "&units=metric"
    f"&appid={API_KEY}"
)

OUTPUT_DIR = Path(__file__).parent / "data"
OUTPUT_FILE = OUTPUT_DIR / "weather.json"


def fetch_weather_data() -> dict:
    """
    Fetch weather data from the OpenWeatherMap One Call API.
    """
    response = requests.get(URL, timeout=10)
    response.raise_for_status()
    return response.json()


def save_weather_data(data: dict, path: Path) -> None:
    """
    Save weather data to a local JSON file.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


def main() -> None:
    data = fetch_weather_data()
    save_weather_data(data, OUTPUT_FILE)
    print(f"Weather data saved to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()