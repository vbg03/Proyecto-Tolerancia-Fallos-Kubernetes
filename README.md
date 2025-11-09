<div align="center">

# Proyecto de Tolerancia a Fallos en Kubernetes

**Sistema de microservicios resiliente con Flask, Kubernetes e Istio**  
Implementando patrones como *Circuit Breaker*, *Retry*, *Failover*, *Auto-Scaling* y *Chaos Engineering*

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?logo=flask&logoColor=white)
![Istio](https://img.shields.io/badge/Istio-466BB0?logo=istio&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?logo=grafana&logoColor=white)

</div>

---

## Descripción del Proyecto

Este proyecto implementa una aplicación distribuida de **e-commerce** con tres microservicios principales:  
**Usuarios**, **Productos** y **Órdenes**, además de un **frontend web** y una **base de datos MySQL**.  
Todo está orquestado con **Kubernetes** y configurado con patrones de **alta disponibilidad y resiliencia**.

---

## Arquitectura

```text
┌─────────────┐
│   Frontend  │
│   (Flask)   │
└──────┬──────┘
       │
┌──────┴───────────────────────────┐
│                                  │
│  ┌────────────┐   ┌────────────┐ │
│  │ Users API  │   │ Products   │ │
│  │  (Flask)   │   │ API (Flask)│ │
│  └─────┬──────┘   └──────┬─────┘ │
│        │                  │       │
│        └──────┬───────────┘       │
│               │                   │
│           ┌───▼────────────┐      │
│           │  Orders API    │      │
│           │    (Flask)     │      │
│           └──────┬─────────┘      │
└──────────────────┴────────────────┘
       │
┌──────▼──────┐
│   MySQL     │
└─────────────┘
```

---

## Componentes Principales

| Componente | Descripción |
|-------------|-------------|
| **Frontend (Flask)** | Interfaz web del sistema de e-commerce. |
| **Users API** | Servicio para la gestión de usuarios. |
| **Products API** | Servicio encargado del catálogo de productos. |
| **Orders API** | Servicio responsable de la creación y seguimiento de órdenes. |
| **MySQL DB** | Base de datos relacional que almacena la información persistente. |
| **Istio** | Implementa balanceo de carga, políticas de tráfico y resiliencia. |
| **Prometheus / Grafana** | Monitorización y visualización del sistema. |

---

## Despliegue

El despliegue se realiza mediante **Kubernetes**, utilizando archivos YAML para describir los recursos del clúster.

### 1. Construcción de Imágenes Docker

```bash
docker build -t users-api:latest ./users
docker build -t products-api:latest ./products
docker build -t orders-api:latest ./orders
docker build -t frontend:latest ./frontend
```

### 2. Aplicación de Manifiestos en Kubernetes

```bash
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
kubectl apply -f k8s/istio/
```

### 3. Verificación de Recursos

```bash
kubectl get pods -A
kubectl get services -A
kubectl get gateways -A
```

---

## Pruebas de Resiliencia

El sistema incorpora mecanismos de tolerancia a fallos mediante:

- **Circuit Breaker:** evita llamadas repetidas a servicios no disponibles.  
- **Retry Policy:** reintenta peticiones fallidas de manera controlada.  
- **Failover:** redirige tráfico ante la caída de pods.  
- **Auto-Scaling:** ajusta dinámicamente el número de réplicas.  
- **Chaos Engineering:** pruebas controladas de fallos para medir la resiliencia.

---

## Monitoreo

**Prometheus** recopila métricas de los microservicios e **Istio**, mientras que **Grafana** ofrece paneles para la visualización y análisis del rendimiento.

Ejemplo de comandos útiles:

```bash
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

---

## Conclusiones

El proyecto demuestra cómo un sistema basado en microservicios puede alcanzar **alta disponibilidad** y **resiliencia** mediante la integración de herramientas modernas del ecosistema **Kubernetes**.

---

## Autores

- Equipo de desarrollo de Ingeniería de Software Distribuido  
- Universidad / Laboratorio de Sistemas Distribuidos
