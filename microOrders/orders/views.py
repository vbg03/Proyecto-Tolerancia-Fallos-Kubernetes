from flask import Flask
from orders.controllers.order_controller import order_controller 
from db.db import db
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
app.config.from_object('config.Config')
db.init_app(app)

@app.route('/health')
def health_check():
    return "OK", 200

# Registrar el blueprint correcto
app.register_blueprint(order_controller)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004)