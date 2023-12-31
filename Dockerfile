FROM golang:1.21-alpine as builder
RUN apk --update add ca-certificates tzdata
WORKDIR /app
COPY . ./
RUN go mod download
RUN GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" main.go

FROM scratch
ENV TZ=Europe/Berlin
COPY --from=builder /app/main /bin/main
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
CMD ["/bin/main"]
