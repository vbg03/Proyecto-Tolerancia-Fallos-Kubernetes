from flask import Flask
from products.controllers.product_controller import product_controller
from db.db import db
from flask_cors import CORS
import requests  # Para registro en Consul
import time

app = Flask(__name__)
CORS(app)
app.config.from_object('config.Config')
db.init_app(app)

# Función para registrar en Consul
def register_service():
    payload = {
        "Name": "products-api",
        "ID": "products-api-1",
        "Address": "products-api",
        "Port": 5003,
        "Check": {
            "HTTP": "http://products-api:5003/health",
            "Interval": "10s"
        }
    }
    
    # Bucle de reintentos
    for i in range(5):
        try:
            response = requests.put("http://consul-client:8500/v1/agent/service/register", json=payload)
            if response.status_code == 200:
                print("✅ microProducts registrado en Consul exitosamente.")
                return # Si tiene éxito, sal de la función
        except requests.exceptions.ConnectionError:
            print(f"❌ Intento {i+1}/5: Consul no está listo. Reintentando en 5 segundos...")
            time.sleep(5) # Espera 5 segundos
    
    print("🚨 No se pudo registrar el servicio microProducts en Consul después de varios intentos.")


# Añade esta ruta de health check para que Consul pueda verificar el estado
@app.route('/health')
def health_check():
    return "OK", 200

# Registrar el servicio al iniciar
register_service()

# Registrar el blueprint
app.register_blueprint(product_controller)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003)

