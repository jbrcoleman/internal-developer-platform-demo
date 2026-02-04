FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /sample-service

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /sample-service .

ARG APP_VERSION=unknown
ENV APP_VERSION=$APP_VERSION

EXPOSE 8080
CMD ["./sample-service"]
