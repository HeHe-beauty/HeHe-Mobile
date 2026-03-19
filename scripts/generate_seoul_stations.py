#!/usr/bin/env python3
"""Generate a Flutter-ready Seoul subway station JSON from T-data.

Source:
- T-data Seoul Traffic Big Data Platform
- API: 지하철역_GEOM (역사마스터)
- Service path: TaimsKsccDvSubwayStationGeom/1.0

Output:
- assets/data/subway/seoul_stations.json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

T_DATA_API_KEY = "89ccb5ee-5d54-4f30-b335-2bfcfb5359e4"
T_DATA_BASE_URL = (
    "http://t-data.seoul.go.kr/apig/apiman-gateway/tapi/"
    "TaimsKsccDvSubwayStationGeom/1.0"
)
PAGE_SIZE = 1000
DEFAULT_OUTPUT = Path("assets/data/subway/seoul_stations.json")


def require_api_key(api_key: str) -> str:
    cleaned = api_key.strip()
    if not cleaned or cleaned == "PUT_YOUR_TDATA_API_KEY_HERE":
        raise RuntimeError("Set T_DATA_API_KEY before running this script.")
    return cleaned


def fetch_page(api_key: str, start_row: int, row_count: int) -> Any:
    query = urllib.parse.urlencode(
        {
            "apikey": api_key,
            "startRow": start_row,
            "rowCnt": row_count,
        }
    )
    url = f"{T_DATA_BASE_URL}?{query}"

    request = urllib.request.Request(
        url,
        headers={"User-Agent": "hehe-seoul-station-generator/1.0"},
        method="GET",
    )

    with urllib.request.urlopen(request, timeout=60) as response:
        raw = response.read().decode("utf-8")
        return json.loads(raw)


def extract_rows(payload: Any) -> list[dict[str, Any]]:
    # T-data sample preview shows a flat JSON object shape in docs,
    # but actual responses can vary by gateway/config.
    if isinstance(payload, list):
        return [row for row in payload if isinstance(row, dict)]

    if isinstance(payload, dict):
        # Case 1: direct single row object
        if "stnKrNm" in payload and "lineNm" in payload:
            return [payload]

        # Case 2: wrapped list-like keys
        for key in ("data", "items", "row", "rows", "result", "results"):
            value = payload.get(key)
            if isinstance(value, list):
                return [row for row in value if isinstance(row, dict)]

        # Case 3: nested dict containing rows
        for value in payload.values():
            if isinstance(value, list):
                return [row for row in value if isinstance(row, dict)]
            if isinstance(value, dict):
                for nested_key in ("data", "items", "row", "rows", "result", "results"):
                    nested_value = value.get(nested_key)
                    if isinstance(nested_value, list):
                        return [row for row in nested_value if isinstance(row, dict)]

    raise RuntimeError(f"Unexpected T-data response shape: {type(payload).__name__}")


def fetch_all_rows(api_key: str) -> list[dict[str, Any]]:
    all_rows: list[dict[str, Any]] = []
    start_row = 1

    while True:
        payload = fetch_page(api_key, start_row, PAGE_SIZE)
        page_rows = extract_rows(payload)

        if not page_rows:
            break

        all_rows.extend(page_rows)

        if len(page_rows) < PAGE_SIZE:
            break

        start_row += PAGE_SIZE

    return all_rows


def normalize_station_name(name: str) -> str:
    compact = re.sub(r"\s+", "", name.strip())
    if compact.endswith("역"):
        return compact[:-1]
    return compact


def to_station_name(name: str) -> str:
    cleaned = re.sub(r"\s+", "", name.strip())
    if not cleaned:
        return cleaned
    return cleaned if cleaned.endswith("역") else f"{cleaned}역"


def aliases_for_name(name: str) -> list[str]:
    alias = normalize_station_name(name)
    return [alias] if alias and alias != name else []


def make_station_id(name: str) -> str:
    station_id = normalize_station_name(name).lower()
    station_id = re.sub(r"[^0-9a-zA-Z가-힣]+", "_", station_id)
    station_id = re.sub(r"_+", "_", station_id).strip("_")
    return station_id or "station"


def normalize_line_name(line_name: str) -> str:
    value = re.sub(r"\s+", "", line_name.strip())

    # 예: "2" -> "2호선"
    if value.isdigit():
        return f"{value}호선"

    # 예: 이미 "2호선"
    if re.fullmatch(r"\d+호선", value):
        return value

    return value


def line_sort_key(line_name: str) -> tuple[int, str]:
    match = re.fullmatch(r"(\d+)호선", line_name)
    if match:
        return (0, f"{int(match.group(1)):03d}")
    return (1, line_name)


def parse_coordinates(row: dict[str, Any]) -> tuple[float, float] | None:
    x = row.get("convX")
    y = row.get("convY")

    if x in (None, "", "0") or y in (None, "", "0"):
        return None

    try:
        longitude = float(str(x).strip())
        latitude = float(str(y).strip())
        return latitude, longitude
    except ValueError:
        return None


def build_station_objects(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    merged: dict[str, dict[str, Any]] = {}

    for row in rows:
        raw_name = str(row.get("stnKrNm", "")).strip()
        raw_line = str(row.get("lineNm", "")).strip()
        coordinates = parse_coordinates(row)

        if not raw_name or not raw_line or coordinates is None:
            continue

        station_name = to_station_name(raw_name)
        line_name = normalize_line_name(raw_line)
        station_key = normalize_station_name(station_name)

        entry = merged.setdefault(
            station_key,
            {
                "id": make_station_id(station_name),
                "name": station_name,
                "aliases": aliases_for_name(station_name),
                "lines": set(),
                "_latitudes": [],
                "_longitudes": [],
            },
        )

        entry["lines"].add(line_name)
        entry["_latitudes"].append(coordinates[0])
        entry["_longitudes"].append(coordinates[1])

    stations: list[dict[str, Any]] = []

    for _, entry in sorted(merged.items(), key=lambda item: item[1]["name"]):
        latitudes = entry.pop("_latitudes")
        longitudes = entry.pop("_longitudes")
        entry["lines"] = sorted(entry["lines"], key=line_sort_key)
        entry["latitude"] = round(sum(latitudes) / len(latitudes), 6)
        entry["longitude"] = round(sum(longitudes) / len(longitudes), 6)
        stations.append(entry)

    return stations


def write_json(path: Path, stations: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(stations, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--api-key",
        default=T_DATA_API_KEY,
        help="T-data API key. Defaults to T_DATA_API_KEY in this file.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Output path (default: {DEFAULT_OUTPUT})",
    )
    args = parser.parse_args()

    api_key = require_api_key(args.api_key)
    rows = fetch_all_rows(api_key)
    if not rows:
        raise RuntimeError("No rows returned from T-data API.")

    stations = build_station_objects(rows)
    if not stations:
        raise RuntimeError("No station records were generated.")

    write_json(args.output, stations)
    print(f"Generated {len(stations)} stations -> {args.output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)