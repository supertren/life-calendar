FROM prom/prometheus:v2.45.0

# Inyectar configuración personalizada en la ruta estándar
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY alerts.yml /etc/prometheus/alerts.yml
# Exponer puerto del TSDB (Time Series Database)
EXPOSE 9090

# Volumen efímero para el almacenamiento de métricas (Free Tier compatible)
# Advertencia: Los datos se perderán al reiniciar el pod.
VOLUME [ "/prometheus" ]

# El entrypoint por defecto de la imagen ya ejecuta el binario de prometheus
