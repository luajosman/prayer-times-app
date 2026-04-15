import httpx
from fastapi import HTTPException

NOMINATIM_SEARCH_URL = "https://nominatim.openstreetmap.org/search"
NOMINATIM_REVERSE_URL = "https://nominatim.openstreetmap.org/reverse"
USER_AGENT = "prayer-compass-app/1.0 (local-dev)"


async def geocode_place(query: str):
    cleaned = query.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail="Query darf nicht leer sein.")

    payload = await _request_nominatim(
        NOMINATIM_SEARCH_URL,
        params={
            "q": cleaned,
            "format": "jsonv2",
            "limit": 1,
            "addressdetails": 0,
        },
    )

    try:
        if not isinstance(payload, list) or not payload:
            raise HTTPException(
                status_code=404,
                detail="Ort nicht gefunden. Bitte Stadt oder Adresse präzisieren.",
            )

        first = payload[0]
        lat = float(first["lat"])
        lon = float(first["lon"])
        label = str(first.get("display_name", cleaned))
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=502,
            detail=f"Unexpected geocoding response structure: {error}",
        )

    return {
        "query": cleaned,
        "label": label,
        "location": {"lat": lat, "lon": lon},
    }


async def reverse_geocode_coordinates(lat: float, lon: float) -> dict[str, str | None]:
    payload = await _request_nominatim(
        NOMINATIM_REVERSE_URL,
        params={
            "lat": lat,
            "lon": lon,
            "format": "jsonv2",
            "zoom": 18,
            "addressdetails": 1,
        },
    )

    if not isinstance(payload, dict):
        raise HTTPException(
            status_code=502,
            detail="Unexpected reverse geocoding response structure.",
        )

    display_name = str(payload.get("display_name", "")).strip()
    address = payload.get("address")
    if not isinstance(address, dict):
        address = {}

    city = _pick_address_part(
        address,
        [
            "city",
            "town",
            "village",
            "municipality",
            "county",
            "state_district",
            "state",
        ],
    )
    country = _pick_address_part(address, ["country"])
    label = _format_reverse_label(address, display_name)
    if label or city or country:
        return {
            "label": label or None,
            "city": city,
            "country": country,
        }

    raise HTTPException(
        status_code=404,
        detail="Ort konnte für diese Koordinaten nicht bestimmt werden.",
    )


async def _request_nominatim(url: str, params: dict):
    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(12.0),
            follow_redirects=True,
            headers={"User-Agent": USER_AGENT},
        ) as client:
            response = await client.get(url, params=params)
    except httpx.RequestError as error:
        raise HTTPException(
            status_code=502,
            detail=f"Geocoding request failed: {type(error).__name__}: {error}",
        )

    if response.status_code != 200:
        preview = (response.text or "")[:200]
        raise HTTPException(
            status_code=502,
            detail=f"Geocoding upstream error {response.status_code}: {preview}",
        )

    try:
        return response.json()
    except ValueError as error:
        raise HTTPException(
            status_code=502,
            detail=f"Geocoding upstream returned invalid JSON: {error}",
        )


def _format_reverse_label(address: dict, display_name: str) -> str:
    primary = _format_primary_address(address)
    secondary = _pick_address_part(
        address,
        [
            "neighbourhood",
            "suburb",
            "city_district",
            "district",
            "quarter",
            "borough",
        ],
    )
    city = _pick_address_part(
        address,
        [
            "city",
            "town",
            "village",
            "municipality",
            "county",
            "state_district",
            "state",
        ],
    )
    country = _pick_address_part(address, ["country"])

    parts = []
    for value in [primary, secondary, city, country]:
        if value and value not in parts:
            parts.append(value)

    if parts:
        return ", ".join(parts)

    if not display_name:
        return ""

    fallback_parts = []
    for raw_part in display_name.split(","):
        part = raw_part.strip()
        if part and part not in fallback_parts:
            fallback_parts.append(part)
        if len(fallback_parts) == 4:
            break
    return ", ".join(fallback_parts)


def _format_primary_address(address: dict) -> str | None:
    road = _pick_address_part(
        address,
        ["road", "pedestrian", "footway", "path", "cycleway"],
    )
    house_number = _pick_address_part(address, ["house_number"])
    amenity = _pick_address_part(address, ["amenity", "building"])

    if road and house_number:
        return f"{road} {house_number}"
    if road:
        return road
    if amenity:
        return amenity
    return _pick_address_part(
        address,
        ["hamlet", "isolated_dwelling", "allotments", "farm"],
    )


def _pick_address_part(address: dict, keys: list[str]) -> str | None:
    for key in keys:
        value = address.get(key)
        if not value:
            continue

        text = str(value).strip()
        if text:
            return text

    return None
