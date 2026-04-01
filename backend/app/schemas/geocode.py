from pydantic import BaseModel

from app.schemas.prayer_times import Location


class GeocodeResponse(BaseModel):
    query: str
    label: str
    location: Location
