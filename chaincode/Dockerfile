FROM golang:1.20-alpine

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o chaincode_server smartcontract.go

EXPOSE 9999

CMD ["./chaincode_server"]
