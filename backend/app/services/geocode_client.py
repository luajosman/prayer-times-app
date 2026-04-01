import httpx
from fastapi import HTTPException

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
USER_AGENT = "prayer-compass-app/1.0 (local-dev)"


async def geocode_place(query: str):
    cleaned = query.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail="Query darf nicht leer sein.")

    params = {
        "q": cleaned,
        "format": "jsonv2",
        "limit": 1,
        "addressdetails": 0,
    }

    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(12.0),
            follow_redirects=True,
            headers={"User-Agent": USER_AGENT},
        ) as client:
            response = await client.get(NOMINATIM_URL, params=params)
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
        payload = response.json()
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
