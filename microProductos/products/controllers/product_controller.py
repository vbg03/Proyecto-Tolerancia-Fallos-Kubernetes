from flask import Blueprint, request, jsonify
from products.models.product_model import Product
from db.db import db

product_controller = Blueprint('product_controller', __name__)

@product_controller.route('/api/products', methods=['GET'])
def get_products():
    print("listado de productos")
    products = Product.query.all()
    result = [{
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'price': float(p.price),
        'stock': p.stock,
        'category': p.category,
        'created_at': p.created_at,
        'updated_at': p.updated_at
    } for p in products]
    return jsonify(result)

@product_controller.route('/api/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    print("obteniendo producto")
    p = Product.query.get_or_404(product_id)
    return jsonify({
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'price': float(p.price),
        'stock': p.stock,
        'category': p.category,
        'created_at': p.created_at,
        'updated_at': p.updated_at
    })

@product_controller.route('/api/products', methods=['POST'])
def create_product():
    print("creando producto")
    data = request.json
    new_product = Product(
        name=data['name'],
        description=data.get('description'),
        price=data['price'],
        stock=data.get('stock', 0),
        category=data.get('category')
    )
    db.session.add(new_product)
    db.session.commit()
    return jsonify({'message': 'Product created successfully'}), 201

@product_controller.route('/api/products/<int:product_id>', methods=['PUT'])
def update_product(product_id):
    print("actualizando producto")
    product = Product.query.get_or_404(product_id)
    data = request.json
    product.name = data['name']
    product.description = data.get('description')
    product.price = data['price']
    product.stock = data.get('stock')
    product.category = data.get('category')
    db.session.commit()
    return jsonify({'message': 'Product updated successfully'})

@product_controller.route('/api/products/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    print("eliminando producto")
    product = Product.query.get_or_404(product_id)
    db.session.delete(product)
    db.session.commit()
    return jsonify({'message': 'Product deleted successfully'})

@product_controller.route('/health', methods=['GET'])
def health_check():
    return 'OK', 200

