from fastapi import APIRouter, Query
from app.services.aladhan_client import get_prayer_times

router = APIRouter()

@router.get("/prayer-times")
async def prayer_times(lat: float = Query(...), lon: float = Query(...)):
    return await get_prayer_times(lat, lon)
