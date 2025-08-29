from flask import jsonify


class APIError(Exception):
    def __init__(self, status: int, message: str):
        super().__init__(message)
        self.status = status
        self.message = message


def register_error_handlers(app):
    @app.errorhandler(APIError)
    def handle_api_error(err: APIError):
        resp = jsonify({"error": err.message})
        resp.status_code = err.status
        return resp

    @app.errorhandler(404)
    def not_found(_):
        return jsonify({"error": "not found"}), 404

    @app.errorhandler(400)
    def bad_request(_):
        return jsonify({"error": "bad request"}), 400

    @app.errorhandler(500)
    def server_error(err):
        app.logger.exception("server error: %s", err)
        return jsonify({"error": "internal server error"}), 500
