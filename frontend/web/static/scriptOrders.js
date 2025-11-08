const ORDERS_API_URL = window.location.hostname === 'localhost' || window.location.hostname.includes('192.168')
  ? 'http://192.168.100.3:5004/api/orders'
  : 'http://orders-api:5004/api/orders';

document.addEventListener('DOMContentLoaded', function () {
    getOrders();
});

function getOrders() {
    fetch(ORDERS_API_URL)
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            const orderListBody = document.querySelector('#order-list tbody');
            orderListBody.innerHTML = '';

            if (data.length === 0) {
                orderListBody.innerHTML = '<tr><td colspan="6" class="text-center">No orders found.</td></tr>';
                return;
            }

            data.forEach(order => {
                const row = document.createElement('tr');
                const orderDate = new Date(order.date).toLocaleString();

                row.innerHTML = `
                    <td>${order.id}</td>
                    <td>${order.userName}</td>
                    <td>${order.userEmail}</td>
                    <td>$${parseFloat(order.saleTotal).toFixed(2)}</td>
                    <td>${orderDate}</td>
                    <td>
                        <button class="btn btn-danger btn-sm" onclick="deleteOrder(${order.id})">Delete</button>
                    </td>
                `;
                orderListBody.appendChild(row);
            });
        })
        .catch(error => {
            console.error('Error fetching orders:', error);
            const orderListBody = document.querySelector('#order-list tbody');
            orderListBody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">Error loading orders. Please try again.</td></tr>`;
        });
}


function getOrderById() {
    const orderId = document.getElementById('orderIdInput').value;
    const orderDetailsDiv = document.getElementById('orderDetails');

    if (!orderId) {
        alert('Please enter a valid order ID');
        return;
    }

    fetch(`${ORDERS_API_URL}/${orderId}`)
        .then(response => {
            if (!response.ok) {
                throw new Error('Order not found');
            }
            return response.json();
        })
        .then(order => {
            const orderDate = new Date(order.date).toLocaleString();

            orderDetailsDiv.innerHTML = `
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Order #${order.id}</h5>
                        <p><strong>User:</strong> ${order.userName}</p>
                        <p><strong>Email:</strong> ${order.userEmail}</p>
                        <p><strong>Total:</strong> $${parseFloat(order.saleTotal).toFixed(2)}</p>
                        <p><strong>Date:</strong> ${orderDate}</p>
                    </div>
                </div>
            `;
        })
        .catch(error => {
            console.error('Error fetching order:', error);
            orderDetailsDiv.innerHTML = `<p class="text-danger">Order not found or error fetching order.</p>`;
        });
}



function deleteOrder(orderId) {

    if (!confirm('Are you sure you want to delete this order?')) {
        return;
    }

    fetch(`${ORDERS_API_URL}/${orderId}`, {
        method: 'DELETE',
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Failed to delete order');
        }
        return response.json();
    })
    .then(data => {
        console.log(data.message);
        getOrders(); 
    })
    .catch(error => {
        console.error('Error deleting order:', error);
        alert('Could not delete the order. Please try again.');
    });

}
