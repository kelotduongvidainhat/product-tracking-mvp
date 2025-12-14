package main

import (
	"context"
	"crypto/x509"
	"database/sql"
	"encoding/json"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
	"github.com/hyperledger/fabric-gateway/pkg/identity"
	_ "github.com/lib/pq"
	"github.com/segmentio/kafka-go"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

// Product matches the one in API service and Chaincode
type Product struct {
	ID              string `json:"id"`
	Name            string `json:"name"`
	ProducerID      string `json:"producer_id"`
	ManufactureDate string `json:"manufacture_date"`
	CertHash        string `json:"cert_hash"`
	Status          string `json:"status"`
}

var db *sql.DB
var contract *client.Contract

const (
	mspID        = "Org1MSP"
	cryptoPath   = "/crypto-config/peerOrganizations/org1.example.com"
	certPath     = cryptoPath + "/users/User1@org1.example.com/msp/signcerts/User1@org1.example.com-cert.pem"
	keyPath      = cryptoPath + "/users/User1@org1.example.com/msp/keystore/" // Directory contains key
	tlscaPath    = cryptoPath + "/peers/peer0.org1.example.com/tls/ca.crt"
	peerEndpoint = "peer0.org1.example.com:7051"
	gatewayPeer  = "peer0.org1.example.com"
	channelName  = "mychannel"
	chaincodeName= "product_cc"
)

func main() {
    log.Println("Worker Service Starting...")
	// 1. Setup DB
	initDB()
	defer db.Close()

	// 2. Setup Fabric Gateway
	clientConnection := newGrpcConnection()
	defer clientConnection.Close()

	id := newIdentity()
	sign := newSign()

	gateway, err := client.Connect(
		id,
		client.WithSign(sign),
		client.WithClientConnection(clientConnection),
		client.WithEvaluateTimeout(5*time.Second),
		client.WithEndorseTimeout(15*time.Second),
		client.WithSubmitTimeout(5*time.Second),
		client.WithCommitStatusTimeout(1*time.Minute),
	)
	if err != nil {
		log.Fatalf("Failed to connect to gateway: %v", err)
	}
	defer gateway.Close()

	network := gateway.GetNetwork(channelName)
	contract = network.GetContract(chaincodeName)
    log.Println("Connected to Fabric Network.")

	// 3. Start Kafka Consumer
	consumeKafka()
}

func initDB() {
	connStr := os.Getenv("DB_CONN_STR")
	if connStr == "" {
		connStr = "postgres://user:password@postgres:5432/product_tracking?sslmode=disable"
	}
	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
    // Retry connection
	for i := 0; i < 30; i++ {
		err = db.Ping()
		if err == nil {
            break
        }
		log.Printf("Waiting for DB... (%d/30)", i+1)
		time.Sleep(2 * time.Second)
	}
    if err != nil {
        log.Fatalf("DB Connection failed: %v", err)
    }
}

func newGrpcConnection() *grpc.ClientConn {
	certificate, err := loadCertificate(tlscaPath)
	if err != nil {
		log.Fatal(err)
	}

	certPool := x509.NewCertPool()
	certPool.AddCert(certificate)
	transportCredentials := credentials.NewClientTLSFromCert(certPool, gatewayPeer)

	connection, err := grpc.Dial(peerEndpoint, grpc.WithTransportCredentials(transportCredentials))
	if err != nil {
		log.Fatal(err)
	}
	return connection
}

func newIdentity() *identity.X509Identity {
	certificate, err := loadCertificate(certPath)
	if err != nil {
		log.Fatal(err)
	}
	id, err := identity.NewX509Identity(mspID, certificate)
	if err != nil {
		log.Fatal(err)
	}
	return id
}

func newSign() identity.Sign {
	files, err := os.ReadDir(keyPath)
	if err != nil {
		log.Fatal(err)
	}
	privateKeyPath := filepath.Join(keyPath, files[0].Name())

	privateKeyPEM, err := os.ReadFile(privateKeyPath)
	if err != nil {
		log.Fatal(err)
	}

	privateKey, err := identity.PrivateKeyFromPEM(privateKeyPEM)
	if err != nil {
		log.Fatal(err)
	}

	sign, err := identity.NewPrivateKeySign(privateKey)
	if err != nil {
		log.Fatal(err)
	}
	return sign
}

func loadCertificate(filename string) (*x509.Certificate, error) {
	certificatePEM, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	return identity.CertificateFromPEM(certificatePEM)
}

func consumeKafka() {
	broker := os.Getenv("KAFKA_BROKER")
	if broker == "" {
		broker = "kafka:29092"
	}
	topic := "product.create"
    groupID := "worker-group"

	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers:  []string{broker},
		Topic:    topic,
		GroupID:  groupID,
		MinBytes: 10e3, // 10KB
		MaxBytes: 10e6, // 10MB
	})
    defer r.Close()

    log.Println("Kafka Consumer started...")

	for {
		m, err := r.ReadMessage(context.Background())
		if err != nil {
            log.Printf("Kafka read error: %v", err)
			break
		}
		
        log.Printf("Received message: %s", string(m.Value))
        processMessage(m.Value)
	}
}

func processMessage(value []byte) {
    var p Product
    if err := json.Unmarshal(value, &p); err != nil {
        log.Printf("Error unmarshalling: %v", err)
        return
    }

    // 1. Submit Transaction to Fabric
    log.Println("Submitting transaction to Blockchain...")
    _, err := contract.SubmitTransaction("CreateProduct", p.ID, p.Name, p.ProducerID, p.ManufactureDate, p.CertHash)
    
    status := "VERIFIED"
    if err != nil {
        log.Printf("Failed to submit transaction: %v", err)
        status = "FAILED"
        // In PROD, might want to retry or send to DLQ
    } else {
        log.Println("Transaction committed successfully!")
    }

    // 2. Update DB
    _, err = db.Exec("UPDATE products SET status=$1, blockchain_tx_id=$2 WHERE id=$3", status, "tx-hash-placeholder", p.ID)
    if err != nil {
        log.Printf("Failed to update DB: %v", err)
    }
}
