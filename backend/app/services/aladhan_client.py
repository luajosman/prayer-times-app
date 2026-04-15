import httpx
from fastapi import HTTPException

ALADHAN_BASE = "https://api.aladhan.com/v1"


async def get_prayer_times(lat: float, lon: float, method: int = 2, school: int = 0):
    """
    Fetch prayer times from AlAdhan.
    We add:
    - follow_redirects=True (avoids 302 issues)
    - timeouts (avoid hanging)
    - proper error mapping to FastAPI HTTPException
    """
    params = {
        "latitude": lat,
        "longitude": lon,
        "method": method,
        "school": school,
    }

    timeout = httpx.Timeout(connect=10.0, read=20.0, write=10.0, pool=10.0)

    try:
        async with httpx.AsyncClient(
            base_url=ALADHAN_BASE,
            follow_redirects=True,
            timeout=timeout,
        ) as client:
            resp = await client.get("/timings", params=params)

        # Non-200 -> treat as upstream error
        if resp.status_code != 200:
            raise HTTPException(
                status_code=502,
                detail=f"Upstream error {resp.status_code}: {resp.text[:200]}",
            )

        data = resp.json()

        # AlAdhan returns "code" and "status"
        if not isinstance(data, dict) or data.get("code") != 200:
            raise HTTPException(
                status_code=502,
                detail=f"Upstream bad payload: {str(data)[:200]}",
            )

        return data

    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Upstream timeout (AlAdhan)")
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=f"Upstream request error: {str(e)}")
