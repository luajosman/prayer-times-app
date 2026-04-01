from fastapi import APIRouter, Query

from app.schemas.geocode import GeocodeResponse
from app.services.geocode_client import geocode_place

router = APIRouter()


@router.get("/geocode", response_model=GeocodeResponse)
async def geocode(
    q: str = Query(..., min_length=2, description="City, district, or address text"),
):
    return await geocode_place(q)
