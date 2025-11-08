from flask import Flask
# Corregí la ruta de importación
from orders.controllers.order_controller import order_controller 
from db.db import db
from flask_cors import CORS
import time
import requests

app = Flask(__name__)
CORS(app)
app.config.from_object('config.Config')
db.init_app(app)

# Función para registrar en Consul
def register_service():
    payload = {
        "Name": "orders-api",
        "ID": "orders-api-1",
        "Address": "orders-api",
        "Port": 5004,
        "Check": {
            "HTTP": "http://orders-api:5004/health",
            "Interval": "10s"
        }
    }
    
    # Bucle de reintentos
    for i in range(5):
        try:
            response = requests.put("http://consul-client:8500/v1/agent/service/register", json=payload)
            if response.status_code == 200:
                print("✅ microOrders registrado en Consul exitosamente.")
                return 
        except requests.exceptions.ConnectionError:
            print(f"❌ Intento {i+1}/5: Consul no está listo. Reintentando en 5 segundos...")
            time.sleep(5)
    
    print("🚨 No se pudo registrar el servicio microOrders en Consul después de varios intentos.")


@app.route('/health')
def health_check():
    return "OK", 200

# Registrar el servicio al iniciar
register_service()

# Registrar el blueprint correcto
app.register_blueprint(order_controller)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004)