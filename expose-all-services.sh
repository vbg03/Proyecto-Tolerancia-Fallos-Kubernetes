# Exponer users-api como NodePort
apiVersion: v1
kind: Service
metadata:
  name: users-api-external
spec:
  type: NodePort
  selector:
    app: users-api
  ports:
  - port: 5002
    targetPort: 5002
    nodePort: 30002  # Puerto fijo
---
# Exponer products-api como NodePort
apiVersion: v1
kind: Service
metadata:
  name: products-api-external
spec:
  type: NodePort
  selector:
    app: products-api
  ports:
  - port: 5003
    targetPort: 5003
    nodePort: 30003  # Puerto fijo
---
# Exponer orders-api como NodePort
apiVersion: v1
kind: Service
metadata:
  name: orders-api-external
spec:
  type: NodePort
  selector:
    app: orders-api
  ports:
  - port: 5004
    targetPort: 5004
    nodePort: 30004  # Puerto fijo
---
# Frontend ya está como NodePort, pero lo dejamos con puerto fijo
apiVersion: v1
kind: Service
metadata:
  name: frontend-external
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 8080
    targetPort: 5001
    nodePort: 30080  # Puerto fijo
