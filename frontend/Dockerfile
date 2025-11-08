# Usar una imagen base de Python
FROM python:3.9-slim

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar el archivo de requerimientos e instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar todo el código de la aplicación al contenedor
COPY . .

# Exponer el puerto en el que corre la app de Flask (usualmente 5000)
EXPOSE 5000

# Comando para ejecutar la aplicación usando tu archivo run.py
CMD ["python", "run.py"]
