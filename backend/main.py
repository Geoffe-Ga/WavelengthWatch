"""FastAPI application entrypoint for WavelengthWatch backend."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.database import init_db
from backend.routers import curriculum, journal, layer, phase, strategy
from backend.tools.seed_data import seed_database


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management."""
    # Startup: Create tables and seed data
    init_db()
    seed_database()
    yield
    # Shutdown: Add cleanup if needed


app = FastAPI(
    title="WavelengthWatch Backend",
    version="0.1.0",
    description="Backend API for WavelengthWatch journaling app",
    lifespan=lifespan,
)

# CORS middleware for frontend development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(layer.router)
app.include_router(phase.router)
app.include_router(curriculum.router)
app.include_router(strategy.router)
app.include_router(journal.router)


@app.get("/")
def read_root():
    """Root endpoint."""
    return {"message": "WavelengthWatch Backend API"}


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "ok"}
