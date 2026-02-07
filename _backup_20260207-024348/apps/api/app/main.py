from fastapi import FastAPI
from app.api.v1.prayer_times import router as prayer_router

app = FastAPI(title="Prayer Times API")

app.include_router(prayer_router, prefix="/api/v1")
