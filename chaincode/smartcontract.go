package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing a Product
type SmartContract struct {
	contractapi.Contract
}

// Product describes basic details of what makes up a product
type Product struct {
	ID              string `json:"id"`
	Name            string `json:"name"`
	ProducerID      string `json:"producer_id"`
	ManufactureDate string `json:"manufacture_date"`
	CertHash        string `json:"cert_hash"`
	Status          string `json:"status"` // e.g., "CREATED", "SHIPPED", "SOLD"
    CreatedTime     string `json:"created_time"`
}

// InitLedger adds a base set of products to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
    // Optional: Pre-populate
	return nil
}

// CreateProduct adds a new product to the world state with given details
func (s *SmartContract) CreateProduct(ctx contractapi.TransactionContextInterface, id string, name string, producerID string, date string, certHash string) error {
	exists, err := s.ProductExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the product %s already exists", id)
	}

	product := Product{
		ID:              id,
		Name:            name,
		ProducerID:      producerID,
		ManufactureDate: date,
		CertHash:        certHash,
		Status:          "CREATED",
        CreatedTime:     time.Now().UTC().Format(time.RFC3339),
	}

	productJSON, err := json.Marshal(product)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, productJSON)
}

// ReadProduct returns the product stored in the world state with given id
func (s *SmartContract) ReadProduct(ctx contractapi.TransactionContextInterface, id string) (*Product, error) {
	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if productJSON == nil {
		return nil, fmt.Errorf("the product %s does not exist", id)
	}

	var product Product
	err = json.Unmarshal(productJSON, &product)
	if err != nil {
		return nil, err
	}

	return &product, nil
}

// ProductExists returns true when product with given ID exists in world state
func (s *SmartContract) ProductExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return productJSON != nil, nil
}

// GetAllProducts returns all products found in world state
func (s *SmartContract) GetAllProducts(ctx contractapi.TransactionContextInterface) ([]*Product, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var products []*Product
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var product Product
		err = json.Unmarshal(queryResponse.Value, &product)
		if err != nil {
			return nil, err
		}
		products = append(products, &product)
	}

	return products, nil
}

func main() {
	assetChaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating product-tracking chaincode: %s", err.Error())
		return
	}

	if err := assetChaincode.Start(); err != nil {
		fmt.Printf("Error starting product-tracking chaincode: %s", err.Error())
	}
}
