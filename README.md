# Life Calendar Service

A high-performance, server-side rendered (SSR) microservice written in Go that visualizes the human lifespan as a discrete finite matrix.

This project implements a **Memento Mori** visualization based on the "Life Calendar" concept by Tim Urban, engineered for containerized environments and serverless architectures.

## 1. Mathematical Model

The application models time as a quantized resource. The lifespan domain $\Omega$ is defined as a grid of discrete units (weeks).

### Definitions
* **Constants:**
    * $L_{max} = 90$ (Maximum theoretical age in years)
    * $W = 52$ (Temporal resolution in weeks/year)
* **Total Domain Space:**
    $$|\Omega| = L_{max} \times W = 4,680 \text{ units}$$

### State Function
Given an input parameter $t$ (current age in years), the consumed resource set $C$ is calculated as:
$$C(t) = \min(t \times W, |\Omega|)$$

The rendering engine generates a boolean state matrix $M$ of size $4680$, where the state of any cell $i$ (where $0 \le i < 4680$) is determined by:

$$M_{i} = \begin{cases} 1 (\text{Filled}) & \text{if } i < C(t) \\ 0 (\text{Empty}) & \text{if } i \ge C(t) \end{cases}$$

## 2. Technical Architecture

The service is designed as a cloud-native, stateless microservice.

### Stack
* **Language:** Go 1.21+
* **HTTP Server:** `net/http` (Standard Library, no frameworks)
* **Template Engine:** `html/template`
* **Observability:** Prometheus (`client_golang`)
* **Containerization:** Docker (Multi-stage Alpine build)

### Key Engineering Features
* **Single Binary Distro:** Utilizes the `embed` directive to compile HTML templates directly into the binary, simplifying deployment artifacts.
* **Algorithmic Efficiency:** Matrix generation occurs in $O(N)$ time complexity and $O(N)$ space complexity.
* **Zero-Dependency Runtime:** The final container image is based on Alpine Linux and contains *only* the compiled binary (approx. 15MB total size).
* **Instrumentation:** Native Prometheus metrics exposure for latency histograms and request counting.

## 3. Project Structure

```text
.
├── Dockerfile          # Multi-stage build definition (Builder -> Alpine)
├── go.mod              # Go module definition
├── main.go             # Application entry point & HTTP handlers
└── templates
    └── index.html      # HTML/CSS template (CSS Grid implementation)
