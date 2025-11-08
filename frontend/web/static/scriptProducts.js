// Detectar si estamos en Kubernetes o desarrollo local
const PRODUCTS_API_URL = window.location.hostname === 'localhost' || window.location.hostname.includes('192.168') 
  ? 'http://192.168.100.10:5003/api/products'
  : 'http://products-api:5003/api/products';

const ORDERS_API_URL = window.location.hostname === 'localhost' || window.location.hostname.includes('192.168')
  ? 'http://192.168.100.10:5004/api/orders'
  : 'http://orders-api:5004/api/orders';

const API_URL = PRODUCTS_API_URL;

let currentCart = [];

// Mensajes
function showMessage(type, text) {
  const msg = document.getElementById('message');
  if (msg) {
    msg.className = `alert alert-${type}`;
    msg.textContent = text;
    msg.style.display = 'block';
    setTimeout(() => (msg.style.display = 'none'), 3000);
  }
}

// Cargar productos
function getProducts() {
  fetch(API_URL)
    .then((res) => res.json())
    .then((data) => {
      const tbody = document.querySelector('#product-list tbody');
      tbody.innerHTML = '';

      const isDashboard = window.location.pathname.includes('/dashboard');

      data.forEach((p) => {
        const row = document.createElement('tr');
        row.dataset.productId = p.id;

        let actionsCell = '';
        if (isDashboard) {
          actionsCell = `
            <td>
              <input type="number" class="form-control" min="0" value="0" style="width: 80px;" />
            </td>`;
        } else {
          // modo admin
          actionsCell = `
            <td>
              <button class="btn btn-warning btn-sm" onclick="openEditModal(${p.id})">Edit</button>
              <button class="btn btn-danger btn-sm" onclick="deleteProduct(${p.id})">Delete</button>
            </td>`;
        }

        row.innerHTML = `
          <td>${p.name}</td>
          <td>${p.description || ''}</td>
          <td>${p.price}</td>
          <td>${p.stock}</td>
          <td>${p.category || ''}</td>
          ${actionsCell}
        `;
        tbody.appendChild(row);
      });
    })
    .catch((err) => console.error('Error loading products:', err));
}

// Crear producto (vista admin)
function createProduct() {
  const data = {
    name: document.getElementById('name').value,
    description: document.getElementById('description').value,
    price: parseFloat(document.getElementById('price').value),
    stock: parseInt(document.getElementById('stock').value) || 0,
    category: document.getElementById('category').value
  };

  fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
    .then((res) => res.json())
    .then(() => {
      showMessage('success', 'Product created!');
      getProducts();
      document.getElementById('add-product-form')?.reset();
    })
    .catch(() => showMessage('danger', 'Error creating product'));
}

// Eliminar producto (vista admin)
function deleteProduct(id) {
  if (!confirm('Are you sure you want to delete this product?')) return;

  fetch(`${API_URL}/${id}`, { method: 'DELETE' })
    .then((res) => res.json())
    .then(() => {
      showMessage('success', 'Product deleted!');
      getProducts();
    })
    .catch(() => showMessage('danger', 'Error deleting product'));
}

// Abrir modal editar (vista admin)
function openEditModal(id) {
  fetch(`${API_URL}/${id}`)
    .then((res) => res.json())
    .then((p) => {
      document.getElementById('edit-id').value = p.id;
      document.getElementById('edit-name').value = p.name;
      document.getElementById('edit-description').value = p.description || '';
      document.getElementById('edit-price').value = p.price;
      document.getElementById('edit-stock').value = p.stock;
      document.getElementById('edit-category').value = p.category || '';
      $('#editModal').modal('show');
    });
}

// Guardar edición (vista admin)
function updateProduct() {
  const id = document.getElementById('edit-id').value;
  const data = {
    name: document.getElementById('edit-name').value,
    description: document.getElementById('edit-description').value,
    price: parseFloat(document.getElementById('edit-price').value),
    stock: parseInt(document.getElementById('edit-stock').value),
    category: document.getElementById('edit-category').value
  };

  fetch(`${API_URL}/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
    .then((res) => res.json())
    .then(() => {
      $('#editModal').modal('hide');
      showMessage('success', 'Product updated!');
      getProducts();
    })
    .catch(() => showMessage('danger', 'Error updating product'));
}

// --- Carrito (solo dashboard) ---

function orderProducts() {
  const isDashboard = window.location.pathname.includes('/dashboard');
  if (!isDashboard) return;

  currentCart = [];
  const productRows = document.querySelectorAll('#product-list tbody tr');

  productRows.forEach((row) => {
    const quantityInput = row.querySelector('input[type="number"]');
    const quantity = parseInt(quantityInput?.value || 0, 10);

    if (quantity > 0) {
      const id = parseInt(row.dataset.productId, 10);
      const name = row.children[0].textContent;
      const price = parseFloat(row.children[2].textContent);
      currentCart.push({ id, name, price, quantity });
    }
  });

  updateCartView();
}

// Dibuja el carrito
function updateCartView() {
  const cartContainer = document.getElementById('cart-container');

  const legacyItems = document.getElementById('cart-items');
  const legacyTotal = document.getElementById('cart-total');

  if (cartContainer) {
    cartContainer.innerHTML = '';
    if (currentCart.length === 0) {
      cartContainer.innerHTML = '<p class="text-muted m-0">No items in cart.</p>';
      return;
    }

    let total = 0;
    const table = document.createElement('table');
    table.className = 'table table-bordered';
    table.innerHTML = `
      <thead>
        <tr><th>Product</th><th>Quantity</th><th>Price</th><th>Total</th><th>Actions</th></tr>
      </thead>
    `;
    const tbody = document.createElement('tbody');

    currentCart.forEach((item, index) => {
      const itemTotal = item.price * item.quantity;
      total += itemTotal;
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${item.name}</td>
        <td>${item.quantity}</td>
        <td>$${item.price.toFixed(2)}</td>
        <td>$${itemTotal.toFixed(2)}</td>
        <td><button class="btn btn-danger btn-sm" onclick="removeFromCart(${index})">Delete</button></td>
      `;
      tbody.appendChild(tr);
    });

    table.appendChild(tbody);
    cartContainer.appendChild(table);

    const totalEl = document.createElement('h5');
    totalEl.className = 'text-right';
    totalEl.textContent = `Total: $${total.toFixed(2)}`;
    cartContainer.appendChild(totalEl);

    const checkoutBtn = document.createElement('button');
    checkoutBtn.className = 'btn btn-primary float-right';
    checkoutBtn.textContent = 'Checkout';
    checkoutBtn.onclick = checkoutOrder;
    cartContainer.appendChild(checkoutBtn);

    return;
  }

  if (legacyItems && legacyTotal) {
    legacyItems.innerHTML = '';
    if (currentCart.length === 0) {
      legacyItems.innerHTML = `<tr><td colspan="4" class="text-center text-muted">Your cart is empty.</td></tr>`;
      legacyTotal.textContent = '0.00';
      return;
    }

    let total = 0;
    currentCart.forEach((item) => {
      const itemTotal = item.price * item.quantity;
      total += itemTotal;
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${item.name}</td>
        <td>${item.quantity}</td>
        <td>$${item.price.toFixed(2)}</td>
        <td>$${itemTotal.toFixed(2)}</td>
      `;
      legacyItems.appendChild(tr);
    });
    legacyTotal.textContent = total.toFixed(2);
  }
}

// Enviar pedido al backend
function checkoutOrder() {
  if (currentCart.length === 0) {
    alert('Your cart is empty.');
    return;
  }

  const currentUser = JSON.parse(sessionStorage.getItem('currentUser'));

  if (!currentUser) {
    alert('You are not logged in. Please log out and log in again.');
    return;
  }

  const orderData = {
    // Usamos los datos del usuario que inició sesión
    user: { name: currentUser.name, email: currentUser.email },
    products: currentCart.map((p) => ({ id: p.id, quantity: p.quantity }))
  };

  fetch(ORDERS_API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(orderData)
  })
    .then((response) => {
      if (!response.ok) {
        return response.json().then((err) => {
          throw new Error(err.message);
        });
      }
      return response.json();
    })
    .then(() => {
      alert('Order created successfully!');
      getProducts();
      currentCart = [];
      updateCartView();
    })
    .catch((error) => {
      console.error('Error placing order:', error);
      alert('Error creating the order: ' + error.message);
    });
}

function removeFromCart(index) {
  currentCart.splice(index, 1);
  updateCartView();
}