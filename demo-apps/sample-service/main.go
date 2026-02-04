package main

import (
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	version = os.Getenv("APP_VERSION")

	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"status", "endpoint"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request latency in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"endpoint"},
	)
)

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)

	if version == "" {
		version = "unknown"
	}
}

func main() {
	// Simulate different behavior based on version
	errorRate := getErrorRate(version)
	baseLatency := getBaseLatency(version)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		defer func() {
			httpRequestDuration.WithLabelValues("/").Observe(time.Since(start).Seconds())
		}()

		// Simulate latency
		time.Sleep(time.Duration(baseLatency+rand.Intn(100)) * time.Millisecond)

		// Simulate errors
		if rand.Float64() < errorRate {
			httpRequestsTotal.WithLabelValues("500", "/").Inc()
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "Error from version %s\n", version)
			return
		}

		httpRequestsTotal.WithLabelValues("200", "/").Inc()
		fmt.Fprintf(w, "Hello from version %s!\n", version)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "OK")
	})

	http.HandleFunc("/ready", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "Ready")
	})

	http.Handle("/metrics", promhttp.Handler())

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting server version %s on port %s", version, port)
	log.Printf("Metrics endpoint: http://localhost:%s/metrics", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

// getErrorRate returns error rate based on version (for demo purposes)
func getErrorRate(version string) float64 {
	switch version {
	case "v2-bad":
		return 0.15 // 15% error rate - will trigger rollback
	case "v3-slow":
		return 0.02 // 2% error rate
	default:
		return 0.001 // 0.1% error rate - healthy
	}
}

// getBaseLatency returns base latency in ms based on version
func getBaseLatency(version string) int {
	switch version {
	case "v3-slow":
		return 400 // 400ms base latency - will trigger rollback
	default:
		return 50 // 50ms base latency
	}
}
