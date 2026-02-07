import httpx
from datetime import date

async def get_prayer_times(lat: float, lon: float):
    url = "https://api.aladhan.com/v1/timings"
    params = {"latitude": lat, "longitude": lon, "method": 2}

    async with httpx.AsyncClient() as client:
        r = await client.get(url, params=params)
        data = r.json()["data"]["timings"]

    return {
        "date": str(date.today()),
        "times": {
            "fajr": data["Fajr"][:5],
            "dhuhr": data["Dhuhr"][:5],
            "asr": data["Asr"][:5],
            "maghrib": data["Maghrib"][:5],
            "isha": data["Isha"][:5],
        }
    }
