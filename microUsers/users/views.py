from flask import Flask
from users.controllers.user_controller import user_controller
from db.db import db
from flask_cors import CORS
import time
import requests

app = Flask(__name__)
app.secret_key = 'secret123'  # Clave secreta para la sesión
CORS(app, supports_credentials=True) # Habilitar credenciales en CORS
app.config.from_object('config.Config')
db.init_app(app)

def register_service():
    payload = {
        "Name": "users-api",
        "ID": "users-api-1",
        "Address": "users-api",
        "Port": 5002,
        "Check": {
            "HTTP": "http://users-api:5002/health",
            "Interval": "10s"
        }
    }
    for i in range(5):
        try:
            response = requests.put("http://consul-client:8500/v1/agent/service/register", json=payload)
            if response.status_code == 200:
                print("✅ microUsers registrado en Consul exitosamente.")
                return
        except requests.exceptions.ConnectionError:
            print(f"❌ Intento {i+1}/5: Consul no está listo. Reintentando en 5 segundos...")
            time.sleep(5)
    print("🚨 No se pudo registrar el servicio microUsers en Consul después de varios intentos.")

@app.route('/health')
def health_check():
    return "OK", 200

register_service()
app.register_blueprint(user_controller)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)