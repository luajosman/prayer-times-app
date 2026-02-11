from fastapi import APIRouter
from app.api.v1.routes.geocode import router as geocode_router
from app.api.v1.routes.prayer_times import router as prayer_times_router

router = APIRouter()
router.include_router(prayer_times_router)
router.include_router(geocode_router)
