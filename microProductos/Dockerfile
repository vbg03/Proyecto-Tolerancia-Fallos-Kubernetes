# Usar una imagen base de Python
FROM python:3.9-slim

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar el archivo de requerimientos e instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar todo el código de la API al contenedor
COPY . .

# Exponer el puerto en el que corre la API (usualmente 5000 para Flask)
EXPOSE 5000

# Comando para ejecutar la aplicación
# con host='0.0.0.0'
CMD ["python", "run.py"]
