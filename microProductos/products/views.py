from flask import Flask
from products.controllers.product_controller import product_controller
from db.db import db
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
app.config.from_object('config.Config')
db.init_app(app)

# Añade esta ruta de health check para que Consul pueda verificar el estado
@app.route('/health')
def health_check():
    return "OK", 200

# Registrar el blueprint
app.register_blueprint(product_controller)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003)

