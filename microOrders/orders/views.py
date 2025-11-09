from flask import Flask
from orders.controllers.order_controller import order_controller 
from db.db import db
from flask_cors import CORS
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
CORS(app)
app.config.from_object('config.Config')
db.init_app(app)

# Agregar métricas de Prometheus
metrics = PrometheusMetrics(app)
metrics.info('orders_api_info', 'Orders API Information', version='1.0.0')

@app.route('/health')
def health_check():
    return "OK", 200

app.register_blueprint(order_controller)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004)