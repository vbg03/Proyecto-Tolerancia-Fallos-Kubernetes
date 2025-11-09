from flask import Flask
from users.controllers.user_controller import user_controller
from db.db import db
from flask_cors import CORS
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
app.secret_key = 'secret123'
CORS(app, supports_credentials=True)
app.config.from_object('config.Config')
db.init_app(app)

# Agregar métricas de Prometheus
metrics = PrometheusMetrics(app)

# Métricas personalizadas
metrics.info('users_api_info', 'Users API Information', version='1.0.0')

@app.route('/health')
def health_check():
    return "OK", 200

@app.route('/metrics')
def metrics_endpoint():
    return metrics.export()

app.register_blueprint(user_controller)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)