from flask import Blueprint, jsonify, request, g
from sqlalchemy.exc import IntegrityError
from .extensions import db
from .errors import APIError
from .models import Tenant, Dimension

api_bp = Blueprint("api", __name__, url_prefix="/api")


@api_bp.get("/health")
def health():
    return jsonify({"service": "mmcs", "status": "ok"})


# ------- DEV helper to seed a tenant -------
@api_bp.post("/dev/tenants")
def create_tenant():
    p = request.get_json(force=True, silent=True) or {}
    code = p.get("code")
    name = p.get("name")
    if not code or not name:
        raise APIError(400, "code and name are required")
    if Tenant.query.filter_by(code=code).first():
        raise APIError(409, "tenant code exists")
    t = Tenant(code=code, name=name)
    db.session.add(t)
    db.session.commit()
    return jsonify({"id": str(t.id), "code": t.code, "name": t.name}), 201


# ------- Dimensions (scoped by current tenant via RLS) -------
@api_bp.post("/dimensions")
def create_dimension():
    p = request.get_json(force=True, silent=True) or {}
    code = p.get("code")
    name = p.get("name")
    desc = p.get("description")
    if not code or not name:
        raise APIError(400, "code and name are required")

    # Pre-check within current tenant (RLS limits rows to this tenant)
    existing = Dimension.query.filter_by(code=code).first()
    if existing:
        raise APIError(409, f"dimension code '{code}' already exists")

    d = Dimension(tenant_id=g.tenant_uuid, code=code, name=name, description=desc)
    db.session.add(d)
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        # in case of a race, respond cleanly
        raise APIError(409, f"dimension code '{code}' already exists")
    return (
        jsonify(
            {
                "id": str(d.id),
                "code": d.code,
                "name": d.name,
                "description": d.description,
            }
        ),
        201,
    )


@api_bp.get("/dimensions")
def list_dimensions():
    # Optional filter by code: /api/dimensions?code=ACC
    code = request.args.get("code")
    q = Dimension.query
    if code:
        q = q.filter_by(code=code)
    rows = q.order_by(Dimension.code.asc()).all()
    return jsonify(
        [
            {
                "id": str(r.id),
                "code": r.code,
                "name": r.name,
                "description": r.description,
            }
            for r in rows
        ]
    )
