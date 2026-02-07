from fastapi import APIRouter, Query
from app.services.aladhan_client import get_prayer_times
from app.schemas.prayer_times import PrayerTimesResponse

router = APIRouter()

@router.get("/prayer-times", response_model=PrayerTimesResponse)
async def prayer_times(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude"),
    method: int = Query(2, description="AlAdhan calculation method"),
    school: int = Query(0, description="0=Shafi, 1=Hanafi (affects Asr)"),
):
    return await get_prayer_times(lat, lon, method=method, school=school)
