from app import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health_ok():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_curriculum_endpoint():
    r = client.get("/curriculum")
    assert r.status_code == 200
    assert isinstance(r.json(), list)


def test_strategies_endpoint():
    r = client.get("/strategies")
    assert r.status_code == 200
    assert isinstance(r.json(), list)
