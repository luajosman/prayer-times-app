import asyncio

from fastapi import APIRouter, Query

from app.services.aladhan_client import get_prayer_times
from app.services.geocode_client import reverse_geocode_coordinates
from app.schemas.prayer_times import PrayerTimesResponse

router = APIRouter()


async def _safe_reverse_geocode(lat: float, lon: float) -> dict[str, str | None] | None:
    try:
        return await asyncio.wait_for(
            reverse_geocode_coordinates(lat, lon),
            timeout=3.0,
        )
    except Exception:
        return None


@router.get("/prayer-times", response_model=PrayerTimesResponse)
async def prayer_times(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude"),
    method: int = Query(2, description="AlAdhan calculation method"),
    school: int = Query(0, description="0=Shafi, 1=Hanafi (affects Asr)"),
):
    prayer_data, location_data = await asyncio.gather(
        get_prayer_times(lat, lon, method=method, school=school),
        _safe_reverse_geocode(lat, lon),
    )

    if location_data and isinstance(prayer_data.get("location"), dict):
        prayer_data["location"].update(location_data)

    return prayer_data
