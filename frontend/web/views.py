from flask import Flask, render_template
from flask_cors import CORS
import requests
import time

app = Flask(__name__)
CORS(app)
app.config.from_object('config.Config')

# Función para registrar en Consul
def register_service():
    payload = {
        "Name": "frontend",
        "ID": "frontend-1",
        "Address": "frontend",
        "Port": 5001,
        "Check": {
            "HTTP": "http://frontend:5001/health",
            "Interval": "10s"
        }
    }

    # Bucle de reintentos
    for i in range(5):
        try:
            response = requests.put("http://consul-client:8500/v1/agent/service/register", json=payload)
            if response.status_code == 200:
                print("✅ frontend registrado en Consul exitosamente.")
                return
        except requests.exceptions.ConnectionError:
            print(f"❌ Intento {i+1}/5: Consul no está listo para el frontend. Reintentando en 5 segundos...")
            time.sleep(5)

    print("🚨 No se pudo registrar el servicio frontend en Consul después de varios intentos.")

@app.route('/health')
def health_check():
    return "OK", 200

# Registrar el servicio al iniciar la aplicación
register_service()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/products')
def products():
    return render_template('products.html')

@app.route('/users')
def users():
    return render_template('users.html')

@app.route('/editUser/<string:id>')
def edit_user(id):
    print("id recibido",id)
    return render_template('editUser.html', id=id)

@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html')


if __name__ == '__main__':
    app.run()