# --- Stage 1: Builder ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Gestión de dependencias
COPY go.mod ./
# Descargamos dependencias y generamos go.sum
RUN go mod tidy && go mod download

COPY . .

# Compilación estática: 
# -ldflags="-w -s" elimina información de depuración para reducir tamaño
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o life-calendar main.go

# --- Stage 2: Runtime ---
FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/life-calendar .

# Inyección de puerto por defecto (sobreescribible por el Cloud Provider)
ENV PORT=8080
EXPOSE 8080

CMD ["./life-calendar"]
