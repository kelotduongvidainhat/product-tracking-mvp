package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
	"github.com/segmentio/kafka-go"
)

// Product represents the product data
type Product struct {
	ID              string `json:"id"`
	Name            string `json:"name"`
	ProducerID      string `json:"producer_id"`
	ManufactureDate string `json:"manufacture_date"`
	IntegrityHash   string `json:"integrity_hash"`
	Status          string `json:"status"` // PENDING, VERIFIED, FAILED
}

var db *sql.DB
var kafkaWriter *kafka.Writer

func main() {
	// 1. Setup Database
	initDB()
	defer db.Close()

	// 2. Setup Kafka
	initKafka()
	defer kafkaWriter.Close()

	// 3. Setup Router
	r := gin.Default()
        
    // Enable CORS
    r.Use(func(c *gin.Context) {
        c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
        c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
        c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }
        c.Next()
    })

	r.POST("/products", createProduct)
	r.GET("/products", getProducts)
	r.GET("/products/:id", getProduct)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Server starting on port %s", port)
	r.Run(":" + port)
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
	for i := 0; i < 10; i++ {
		err = db.Ping()
		if err == nil {
			break
		}
		log.Printf("Waiting for DB... (%d/10)", i+1)
		time.Sleep(2 * time.Second)
	}
	if err != nil {
		log.Fatal("Could not connect to database:", err)
	}

	// Migrate Table (Reset for Dev)
    db.Exec("DROP TABLE IF EXISTS products")
	query := `CREATE TABLE IF NOT EXISTS products (
		id TEXT PRIMARY KEY,
		name TEXT,
		producer_id TEXT,
		manufacture_date TEXT,
		integrity_hash TEXT,
		status TEXT,
        blockchain_tx_id TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`
	_, err = db.Exec(query)
	if err != nil {
		log.Fatal("Failed to create table:", err)
	}
	log.Println("Database connected and initialized.")
}

func initKafka() {
	broker := os.Getenv("KAFKA_BROKER")
	if broker == "" {
		broker = "kafka:29092" // Internal docker network address
	}
	topic := "product.create"

	kafkaWriter = &kafka.Writer{
		Addr:     kafka.TCP(broker),
		Topic:    topic,
		Balancer: &kafka.LeastBytes{},
	}
	log.Println("Kafka init done.")
}

func createProduct(c *gin.Context) {
	var input Product
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 1. Save to DB (Status: PENDING)
	input.Status = "PENDING"
	query := `INSERT INTO products (id, name, producer_id, manufacture_date, integrity_hash, status) 
			  VALUES ($1, $2, $3, $4, $5, $6)`
	_, err := db.Exec(query, input.ID, input.Name, input.ProducerID, input.ManufactureDate, input.IntegrityHash, input.Status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save to DB: " + err.Error()})
		return
	}

	// 2. Push to Kafka
	msgBytes, _ := json.Marshal(input)
	err = kafkaWriter.WriteMessages(context.Background(),
		kafka.Message{
			Key:   []byte(input.ID),
			Value: msgBytes,
		},
	)
	if err != nil {
		// Rollback DB or log error? For MVP, just log
		log.Printf("Failed to write to Kafka: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to queue message"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Product creation requested", "product": input})
}

func getProduct(c *gin.Context) {
	id := c.Param("id")
	var p Product
	query := `SELECT id, name, producer_id, manufacture_date, integrity_hash, status FROM products WHERE id=$1`
	err := db.QueryRow(query, id).Scan(&p.ID, &p.Name, &p.ProducerID, &p.ManufactureDate, &p.IntegrityHash, &p.Status)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, p)
}

func getProducts(c *gin.Context) {
	query := `SELECT id, name, producer_id, manufacture_date, integrity_hash, status, blockchain_tx_id FROM products ORDER BY created_at DESC`
	rows, err := db.Query(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	var products []Product
	for rows.Next() {
		var p Product
        var txId sql.NullString // Handle nullable tx_id
		err := rows.Scan(&p.ID, &p.Name, &p.ProducerID, &p.ManufactureDate, &p.IntegrityHash, &p.Status, &txId)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
        if txId.Valid {
            // We can add a field for TxID if we want to show it, currently Product struct doesn't have it explicitly as public field?
            // Wait, Product struct in main.go:18 does NOT have BlockchainTxID field mapped to json.
            // Let's check struct first.
        }
		products = append(products, p)
	}
	c.JSON(http.StatusOK, products)
}
