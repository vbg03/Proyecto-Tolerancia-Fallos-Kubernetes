from flask import Flask, render_template
from flask_cors import CORS
import requests
import time

app = Flask(__name__)
CORS(app)
app.config.from_object('config.Config')

@app.route('/health')
def health_check():
    return "OK", 200

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/products')
def products():
    return render_template('products.html')

@app.route('/users')
def users():
    return render_template('users.html')

@app.route('/orders')
def orders():
    return render_template('orders.html')

@app.route('/editUser/<string:id>')
def edit_user(id):
    print("id recibido",id)
    return render_template('editUser.html', id=id)

@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html')


if __name__ == '__main__':
    app.run()