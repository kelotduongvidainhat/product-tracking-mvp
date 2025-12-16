import axios from "axios";

// Determine API URL based on environment
// For local dev, we use localhost:8081
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8081";

export interface Product {
    id: string;
    name: string;
    producerId: string;
    manufactureDate: string;
    status: string;
    blockchainTxId?: string;
    integrityHash?: string;
}

export const api = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        "Content-Type": "application/json",
    },
});

export const createProduct = async (product: Omit<Product, "blockchainTxId">) => {
    const response = await api.post("/products", product);
    return response.data;
};

export const getProduct = async (id: string) => {
    const response = await api.get(`/products/${id}`);
    return response.data as Product;
};

export const getAllProducts = async () => {
    const response = await api.get("/products");
    return response.data as Product[];
};
