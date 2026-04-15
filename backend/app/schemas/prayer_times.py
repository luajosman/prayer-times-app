from pydantic import BaseModel
from typing import Dict, Optional

class Location(BaseModel):
    lat: float
    lon: float
    label: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None

class PrayerTimesResponse(BaseModel):
    date: str
    timezone: Optional[str] = None
    location: Location
    method: int
    school: int
    times: Dict[str, str]
