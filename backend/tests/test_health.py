from app import create_app


def test_health_ok():
    app = create_app()
    client = app.test_client()
    r = client.get("/api/health")
    assert r.status_code == 200
    data = r.get_json()
    assert data["service"] == "mmcs"
    assert data["status"] == "ok"
