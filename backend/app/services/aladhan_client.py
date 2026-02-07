import httpx
from fastapi import HTTPException

# Wichtig: HTTPS benutzen (302 kommt sehr oft von http -> https)
ALADHAN_URL = "https://api.aladhan.com/v1/timings"

async def get_prayer_times(lat: float, lon: float, method: int = 2, school: int = 0):
    params = {
        "latitude": lat,
        "longitude": lon,
        "method": method,
        "school": school,
    }

    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(15.0),
            follow_redirects=True,   # <-- DAS ist der Fix für 302
        ) as client:
            r = await client.get(ALADHAN_URL, params=params)
    except httpx.RequestError as e:
        raise HTTPException(
            status_code=502,
            detail=f"Upstream request failed: {type(e).__name__}: {e}",
        )

    if r.status_code != 200:
        # ein bisschen Body anzeigen, damit man es debuggen kann
        body_preview = (r.text or "")[:200]
        raise HTTPException(
            status_code=502,
            detail=f"Upstream error {r.status_code}: {body_preview}",
        )

    try:
        data = r.json()
        payload = data["data"]
        timings = payload["timings"]
        date_readable = payload["date"]["readable"]
        timezone = payload["meta"]["timezone"]
    except Exception as e:
        raise HTTPException(
            status_code=502,
            detail=f"Unexpected upstream JSON structure: {e}",
        )

    return {
        "date": date_readable,
        "timezone": timezone,
        "location": {"lat": lat, "lon": lon},
        "method": method,
        "school": school,
        "times": timings,
    }
