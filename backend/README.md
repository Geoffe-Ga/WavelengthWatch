# WavelengthWatch Backend

FastAPI backend service for the WavelengthWatch journaling application.

## Features

- **CRUD APIs**: Full REST endpoints for layers, phases, curriculum, strategies, and journal entries
- **SQLModel/SQLAlchemy**: Type-safe database operations with PostgreSQL/SQLite support
- **Auto-seeding**: Database automatically seeds with reference data on first run
- **Relationship loading**: Optimized queries with eager loading support
- **Input validation**: Pydantic schemas for request/response validation
- **Pagination**: Built-in pagination support for list endpoints
- **Filtering**: Query parameters for filtering resources

## Project Structure

```
backend/
├── main.py              # FastAPI application entrypoint
├── database.py          # Database engine and session management
├── models.py            # SQLModel table definitions
├── schemas.py           # Pydantic request/response schemas
├── routers/             # API route modules
│   ├── layer.py         # Layer CRUD endpoints
│   ├── phase.py         # Phase CRUD endpoints
│   ├── curriculum.py    # Curriculum CRUD endpoints
│   ├── strategy.py      # Strategy CRUD endpoints
│   └── journal.py       # Journal CRUD endpoints
├── tools/
│   └── seed_data.py     # Database seeding utility
└── requirements.txt     # Python dependencies
```

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Run the Server

```bash
# Development server with auto-reload
python -m uvicorn backend.main:app --reload

# Production server
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

### 3. View API Documentation

- **Interactive docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Database Configuration

The application uses SQLite by default but supports any SQLAlchemy-compatible database via the `DATABASE_URL` environment variable:

```bash
# SQLite (default)
DATABASE_URL=sqlite:///./app.db

# PostgreSQL
DATABASE_URL=postgresql://user:password@localhost/wavelengthwatch

# MySQL
DATABASE_URL=mysql://user:password@localhost/wavelengthwatch
```

## API Endpoints

### Layer Management
- `GET /layer` - List all layers with pagination
- `GET /layer/{id}` - Get specific layer
- `POST /layer` - Create new layer
- `PUT /layer/{id}` - Update layer
- `DELETE /layer/{id}` - Delete layer

### Phase Management
- `GET /phase` - List all phases with pagination
- `GET /phase/{id}` - Get specific phase
- `POST /phase` - Create new phase
- `PUT /phase/{id}` - Update phase
- `DELETE /phase/{id}` - Delete phase

### Curriculum Management
- `GET /curriculum` - List curriculum with optional filters (`layer_id`, `phase_id`, `dosage`)
- `GET /curriculum/{id}` - Get specific curriculum with related data
- `POST /curriculum` - Create new curriculum entry
- `PUT /curriculum/{id}` - Update curriculum
- `DELETE /curriculum/{id}` - Delete curriculum

### Strategy Management
- `GET /strategy` - List strategies with optional filters (`layer_id`, `phase_id`)
- `GET /strategy/{id}` - Get specific strategy with related data
- `POST /strategy` - Create new strategy
- `PUT /strategy/{id}` - Update strategy
- `DELETE /strategy/{id}` - Delete strategy

### Journal Management
- `GET /journal` - List journal entries with optional filters (`user_id`, `strategy_id`, `from`, `to`)
- `GET /journal/{id}` - Get specific journal entry with related data
- `POST /journal` - Create new journal entry
- `PUT /journal/{id}` - Update journal entry
- `DELETE /journal/{id}` - Delete journal entry

## Example API Usage

### Get all curriculum for a specific layer and phase
```bash
curl "http://localhost:8000/curriculum?layer_id=1&phase_id=2&limit=10"
```

### Create a new journal entry
```bash
curl -X POST "http://localhost:8000/journal" \
  -H "Content-Type: application/json" \
  -d '{
    "created_at": "2025-09-16T10:30:00Z",
    "user_id": 1,
    "curriculum_id": 25,
    "secondary_curriculum_id": 26,
    "strategy_id": 15
  }'
```

### Get journal entries for a user within date range
```bash
curl "http://localhost:8000/journal?user_id=1&from=2025-09-01T00:00:00Z&to=2025-09-30T23:59:59Z"
```

### Filter strategies by layer
```bash
curl "http://localhost:8000/strategy?layer_id=3"
```

### Get curriculum with medicinal dosage only
```bash
curl "http://localhost:8000/curriculum?dosage=Medicinal"
```

## Data Model

### Core Tables
- **Layer**: Color-coded stages (Beige, Purple, Red, etc.)
- **Phase**: Temporal phases (Rising, Peaking, Withdrawal, etc.)
- **Curriculum**: Layer+Phase combinations with medicinal/toxic expressions
- **Strategy**: Self-care strategies linked to specific layer+phase
- **Journal**: User interaction logs with curriculum and strategy references

### Key Relationships
- Curriculum → Layer (many-to-one)
- Curriculum → Phase (many-to-one)
- Strategy → Layer (many-to-one)
- Strategy → Phase (many-to-one)
- Journal → Curriculum (many-to-one, primary)
- Journal → Curriculum (many-to-one, secondary, optional)
- Journal → Strategy (many-to-one, optional)

## Development

### Run Tests
```bash
pytest
```

### Manual Database Seeding
```bash
python -m backend.tools.seed_data
```

### Database Reset
```bash
rm app.db  # Delete SQLite database
python -m uvicorn backend.main:app --reload  # Restart to recreate and seed
```

## Production Deployment

For production deployments:

1. **Set environment variables**:
   ```bash
   export DATABASE_URL="postgresql://user:password@host/db"
   ```

2. **Run with production ASGI server**:
   ```bash
   pip install gunicorn
   gunicorn backend.main:app -w 4 -k uvicorn.workers.UvicornWorker
   ```

3. **Configure CORS** appropriately in `main.py` for your frontend domain
