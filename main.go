package main

import (
	"embed"
	"html/template"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

//go:embed templates/*
var resources embed.FS

var tpl = template.Must(template.ParseFS(resources, "templates/index.html"))

// Definición de métricas (Histograma de latencia)
var (
	httpDuration = prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "http_request_duration_seconds",
		Help:    "Duration of HTTP requests in seconds",
		Buckets: prometheus.DefBuckets,
	}, []string{"path"})
)

func init() {
	prometheus.MustRegister(httpDuration)
}

type PageData struct {
	Age         int
	TotalWeeks  int
	FilledWeeks int
	Weeks       []struct{Filled bool}
}

// Middleware para observabilidad
func prometheusMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		defer func() {
			duration := time.Since(start).Seconds()
			path := r.URL.Path
			if path == "/" {
				path = "root"
			}
			httpDuration.WithLabelValues(path).Observe(duration)
		}()
		next(w, r)
	}
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	ageStr := r.URL.Query().Get("age")
	age := 0
	if ageStr != "" {
		if a, err := strconv.Atoi(ageStr); err == nil {
			age = a
		}
	}

	// Constantes del dominio
	const totalYears = 90
	const weeksPerYear = 52
	totalWeeks := totalYears * weeksPerYear
	filledWeeks := age * weeksPerYear

	if filledWeeks > totalWeeks {
		filledWeeks = totalWeeks
	}

	// Inicialización de la matriz (Slice de structs)
	weeks := make([]struct{Filled bool}, totalWeeks)
	for i := 0; i < totalWeeks; i++ {
		weeks[i].Filled = i < filledWeeks
	}

	data := PageData{
		Age:         age,
		TotalWeeks:  totalWeeks,
		FilledWeeks: filledWeeks,
		Weeks:       weeks,
	}

	w.Header().Set("Content-Type", "text/html")
	if err := tpl.Execute(w, data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", prometheusMiddleware(indexHandler))
	http.Handle("/metrics", promhttp.Handler())

	log.Printf("Servidor escuchando en puerto %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
