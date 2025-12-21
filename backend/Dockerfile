# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN go build -o main .

# Final stage
FROM alpine:latest

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/main .

# Create directory for uploads
RUN mkdir -p uploads

# Expose port (HF Spaces uses 7860)
EXPOSE 7860

# Command to run the executive
CMD ["./main"]
