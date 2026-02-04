#!/bin/bash
set -e

# Definición de constantes
MODULE_NAME="monitoring"
ARCHIVE_NAME="monitoring_infrastructure.tar.gz"

echo "[INFO] Inicializando módulo de infraestructura: $MODULE_NAME"

# 1. Crear directorio aislado
rm -rf $MODULE_NAME
mkdir -p $MODULE_NAME

# 2. Generar prometheus.yml
# Nota: Se define un 'scrape_config' apuntando a la variable de entorno o placeholder
echo "[INFO] Generando configuración de Prometheus..."
cat << 'EOF' > $MODULE_NAME/prometheus.yml
global:
  scrape_interval: 15s     # Frecuencia de muestreo (Nyquist-Shannon compliant para eventos >30s)
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'life-calendar-service'
    metrics_path: '/metrics'
    scheme: 'https'        # Render fuerza TLS, es mandatorio
    static_configs:
      # IMPORTANTE: Reemplaza este target con tu URL de producción real
      - targets: ['life-calendar-tu-app.onrender.com'] 
        labels:
          environment: 'production'
          service: 'life-calendar'
EOF

# 3. Generar Dockerfile
# Usamos una imagen base oficial y copiamos la configuración
echo "[INFO] Generando Dockerfile para Prometheus..."
cat << 'EOF' > $MODULE_NAME/Dockerfile
FROM prom/prometheus:v2.45.0

# Inyectar configuración personalizada en la ruta estándar
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Exponer puerto del TSDB (Time Series Database)
EXPOSE 9090

# Volumen efímero para el almacenamiento de métricas (Free Tier compatible)
# Advertencia: Los datos se perderán al reiniciar el pod.
VOLUME [ "/prometheus" ]

# El entrypoint por defecto de la imagen ya ejecuta el binario de prometheus
EOF

# 4. Empaquetado (Opcional, ya que lo vas a subir al repo)
echo "[INFO] Generando snapshot en $ARCHIVE_NAME..."
tar -czvf $ARCHIVE_NAME $MODULE_NAME/

echo "----------------------------------------------------------------"
echo "[SUCCESS] Estructura generada en carpeta './$MODULE_NAME'"
echo "[ACTION REQUIRED] Edita '$MODULE_NAME/prometheus.yml' y pon la URL real de tu app."
echo "----------------------------------------------------------------"
