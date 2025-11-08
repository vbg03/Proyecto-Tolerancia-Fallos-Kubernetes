from flask import Blueprint, request, jsonify, session
from orders.models.order_model import Orders
# from products.models.product_model import Product # <- LÍNEA ELIMINADA
from db.db import db
import requests

order_controller = Blueprint('order_controller', __name__)

@order_controller.route('/api/orders', methods=['GET'])
def get_all_orders():
    orders = Orders.query.all()
    result = [{
        'id': o.id,
        'userName': o.userName,
        'userEmail': o.userEmail,
        'saleTotal': float(o.saleTotal),
        'date': o.date
    } for o in orders]
    return jsonify(result)

@order_controller.route('/api/orders/<int:order_id>', methods=['GET'])
def get_order(order_id):
    order = Orders.query.get_or_404(order_id)
    return jsonify({
        'id': order.id,
        'userName': order.userName,
        'userEmail': order.userEmail,
        'saleTotal': float(order.saleTotal),
        'date': order.date
    })

@order_controller.route('/api/orders', methods=['POST'])
def create_order():
    data = request.get_json()
    
    user_name = data.get('user', {}).get('name')
    user_email = data.get('user', {}).get('email')

    if not user_name or not user_email:
        return jsonify({'message': 'Información de usuario inválida'}), 400

    products = data.get('products')
    if not products or not isinstance(products, list):
        return jsonify({'message': 'Falta o es inválida la información de los productos'}), 400

    total_sale = 0
    
    for item in products:
        product_id = item.get('id')
        quantity = item.get('quantity')

        try:
            response = requests.get(f"http://products-api:5003/api/products/{product_id}")
            if response.status_code == 200:
                product_data = response.json()
                if product_data['stock'] >= quantity:
                    total_sale += product_data['price'] * quantity
                    
                    new_stock = product_data['stock'] - quantity
                    update_payload = {
                        "name": product_data['name'],
                        "description": product_data['description'],
                        "price": product_data['price'],
                        "stock": new_stock,
                        "category": product_data['category']
                    }
                    requests.put(f"http://products-api:5003/api/products/{product_id}", json=update_payload)
                else:
                    return jsonify({'message': f"No hay suficiente stock para el producto {product_data['name']}"}), 400
            else:
                return jsonify({'message': f'Producto con id {product_id} no encontrado'}), 404
        except requests.exceptions.RequestException as e:
            return jsonify({'message': f'Error al comunicar con el microservicio de productos: {e}'}), 500


    new_order = Orders(userName=user_name, userEmail=user_email, saleTotal=total_sale)
    db.session.add(new_order)
    db.session.commit()
    
    return jsonify({'message': 'Orden creada exitosamente'}), 201

@order_controller.route('/health', methods=['GET'])
def health_check():
    return 'OK', 200