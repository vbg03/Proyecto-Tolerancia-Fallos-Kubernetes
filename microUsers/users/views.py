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

@app.route('/health')
def health_check():
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)