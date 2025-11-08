from flask import Blueprint, request, jsonify, session
from werkzeug.security import check_password_hash
from users.models.user_model import Users
from db.db import db

user_controller = Blueprint('user_controller', __name__)

@user_controller.route('/api/users', methods=['GET'])
def get_users():
    print("listado de usuarios")
    users = Users.query.all()
    result = [{'id':user.id, 'name': user.name, 'email': user.email, 'username': user.username} for user in users]
    return jsonify(result)

# Get single user by id
@user_controller.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    print("obteniendo usuario")
    user = Users.query.get_or_404(user_id)
    return jsonify({'id': user.id, 'name': user.name, 'email': user.email, 'username': user.username})

@user_controller.route('/api/users', methods=['POST'])
def create_user():
    print("creando usuario")
    data = request.json
    new_user = Users(name=data['name'], email=data['email'], username=data['username'], password=data['password'])
    db.session.add(new_user)
    db.session.commit()
    return jsonify({'message': 'User created successfully'}), 201

# Update an existing user
@user_controller.route('/api/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    print("actualizando usuario")
    user = Users.query.get_or_404(user_id)
    data = request.json
    user.name = data['name']
    user.email = data['email']
    user.username = data['username']
    user.password = data['password']
    db.session.commit()
    return jsonify({'message': 'User updated successfully'})

# Delete an existing user
@user_controller.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    user = Users.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    return jsonify({'message': 'User deleted successfully'})

@user_controller.route('/health', methods=['GET'])
def health_check():
    return 'OK', 200

@user_controller.route('/api/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'message': 'Missing username or password'}), 400

    user = Users.query.filter_by(username=username).first()

    if not user or not user.password == password: # Compara la contraseña directamente
        return jsonify({'message': 'Invalid username or password'}), 401

    session['user_id'] = user.id
    session['username'] = user.username
    session['email'] = user.email

    return jsonify({'message': 'Login successful'}), 200

@user_controller.route('/api/logout', methods=['POST'])
def logout():
    session.clear() # Limpia toda la sesión
    return jsonify({'message': 'Logout successful'}), 200