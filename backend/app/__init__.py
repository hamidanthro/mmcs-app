import os
import re
import uuid

from flask import Flask, g, request
from flask_cors import CORS
from sqlalchemy import text

from .api import api_bp
from .config import get_config
from .errors import APIError, register_error_handlers
from .extensions import db, migrate
from .models import Tenant  # removed unused import 'Dimension'

UUID_RE = re.compile(r"^[0-9a-fA-F-]{36}$")


def bootstrap_db_and_rls(app: Flask) -> None:
    """Create tables and ensure RLS artifacts exist (idempotent)."""
    with app.app_context():
        db.create_all()
        # helper schema/function for RLS
        db.session.execute(text("CREATE SCHEMA IF NOT EXISTS app"))
        db.session.execute(
            text(
                """
                CREATE OR REPLACE FUNCTION app.tenant_id() RETURNS uuid AS
                $$ SELECT current_setting('app.tenant_id', true)::uuid $$ LANGUAGE SQL STABLE;
                """
            )
        )
        # enable RLS + policy on dimension
        db.session.execute(text("ALTER TABLE IF EXISTS dimension ENABLE ROW LEVEL SECURITY"))
        db.session.execute(
            text(
                """
                DO $$
                BEGIN
                  IF NOT EXISTS (
                    SELECT 1
                    FROM pg_policies
                    WHERE schemaname = 'public'
                      AND tablename = 'dimension'
                      AND policyname = 'dimension_isolation'
                  ) THEN
                    EXECUTE 'CREATE POLICY dimension_isolation ON public.dimension
                             USING (tenant_id = app.tenant_id())
                             WITH CHECK (tenant_id = app.tenant_id())';
                  END IF;
                END$$;
                """
            )
        )
        db.session.commit()


def create_app():
    app = Flask(__name__)
    app.config.from_object(get_config())

    # CORS for local dev
    CORS(app, resources={r"/api/*": {"origins": os.getenv("CORS_ORIGINS", "*")}})

    # init DB / migrate / errors
    db.init_app(app)
    migrate.init_app(app, db)
    register_error_handlers(app)

    # Request ID
    @app.before_request
    def _req_id():
        rid = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        g.request_id = rid

    # Tenant + RLS binding
    @app.before_request
    def _tenant_and_rls():
        # allow tenantless routes
        if request.path.startswith("/api/health") or request.path.startswith("/api/dev/tenants"):
            return
        code = request.headers.get("X-Tenant")
        if not code:
            raise APIError(400, "X-Tenant header required")
        tenant = Tenant.query.filter_by(code=code).first()
        if not tenant:
            raise APIError(404, f"unknown tenant '{code}'")
        g.tenant_uuid = tenant.id
        db.session.execute(text("SET LOCAL app.tenant_id = :tid"), {"tid": str(tenant.id)})

    @app.after_request
    def _add_req_id(resp):
        if g.get("request_id"):
            resp.headers["X-Request-ID"] = g.request_id
        return resp

    # Bootstrap now unless explicitly disabled (e.g., tests)
    if os.getenv("SKIP_BOOTSTRAP") != "1":
        bootstrap_db_and_rls(app)

    app.register_blueprint(api_bp)
    return app


app = create_app()
