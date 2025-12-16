"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { ArrowLeft, Loader2, CheckCircle, AlertCircle, FileText } from "lucide-react";
import Link from "next/link";
import { createProduct } from "@/lib/api";
import { ProductQRCode } from "@/app/components/ProductQRCode";

export default function ProducerPage() {
    const [formData, setFormData] = useState({
        id: "",
        name: "",
        producerId: "PROD-001", // Default for MVP
        manufactureDate: new Date().toISOString().split("T")[0],
        status: "Manufactured",
        integrityHash: "",
    });
    const [loading, setLoading] = useState(false);
    const [result, setResult] = useState<{ success?: boolean; message?: string; productId?: string } | null>(null);

    // Auto-calculate Integrity Hash whenever specific fields change
    useEffect(() => {
        const computeHash = async () => {
            if (!formData.id || !formData.name) {
                setFormData(prev => ({ ...prev, integrityHash: "" }));
                return;
            }

            // Format data as string "ID+Name+ProducerID+Date"
            const dataString = `${formData.id}${formData.name}${formData.producerId}${formData.manufactureDate}`;
            const encoder = new TextEncoder();
            const data = encoder.encode(dataString);
            const hashBuffer = await crypto.subtle.digest("SHA-256", data);

            const hashArray = Array.from(new Uint8Array(hashBuffer));
            const hashHex = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

            setFormData(prev => {
                if (prev.integrityHash === hashHex) return prev;
                return { ...prev, integrityHash: hashHex };
            });
        };

        computeHash();
    }, [formData.id, formData.name, formData.producerId, formData.manufactureDate]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setResult(null);

        try {
            await createProduct(formData);
            setResult({ success: true, message: `Product ${formData.id} created successfully on Blockchain!`, productId: formData.id });
            setFormData({ ...formData, id: "", name: "", integrityHash: "" }); // Reset
        } catch (error: any) {
            console.error(error);
            setResult({ success: false, message: error.response?.data?.error || "Failed to create product." });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen p-6 md:p-12 flex flex-col items-center">
            <div className="w-full max-w-2xl">
                <Link href="/" className="inline-flex items-center text-slate-400 hover:text-white mb-8 transition-colors">
                    <ArrowLeft className="w-4 h-4 mr-2" /> Back to Home
                </Link>

                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="glass-panel p-8 rounded-2xl"
                >
                    <div className="mb-8">
                        <h1 className="text-3xl font-bold text-white mb-2">Register Product</h1>
                        <p className="text-slate-400">Enter product details to record on the ledger.</p>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-300">Product ID</label>
                                <input
                                    required
                                    type="text"
                                    value={formData.id}
                                    onChange={(e) => setFormData({ ...formData, id: e.target.value })}
                                    placeholder="e.g., P-1001"
                                    className="w-full px-4 py-3 rounded-xl modern-input"
                                />
                            </div>

                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-300">Producer ID</label>
                                <input
                                    type="text"
                                    value={formData.producerId}
                                    disabled
                                    className="w-full px-4 py-3 rounded-xl modern-input opacity-70 cursor-not-allowed"
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-300">Product Name</label>
                            <input
                                required
                                type="text"
                                value={formData.name}
                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                placeholder="Item Name"
                                className="w-full px-4 py-3 rounded-xl modern-input"
                            />
                        </div>

                        <div className="space-y-4">
                            {formData.integrityHash && (
                                <div className="bg-slate-900/50 p-4 rounded-xl border border-slate-700/50 flex items-start gap-3">
                                    <FileText className="w-5 h-5 text-purple-400 mt-0.5 flex-shrink-0" />
                                    <div className="overflow-hidden">
                                        <p className="text-xs text-slate-500 uppercase font-semibold mb-1">DATA INTEGRITY HASH (AUTO)</p>
                                        <p className="text-xs text-slate-300 font-mono break-all">{formData.integrityHash}</p>
                                        <p className="text-[10px] text-slate-500 mt-1">Generated from ID + Name + Producer + Date</p>
                                    </div>
                                </div>
                            )}
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full py-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white font-bold rounded-xl shadow-lg transition-all transform active:scale-95 disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center"
                        >
                            {loading ? <Loader2 className="w-5 h-5 animate-spin mr-2" /> : null}
                            {loading ? "Processing..." : "Register Product"}
                        </button>
                    </form>

                    {result && (
                        <motion.div
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            className={`mt-6 p-4 rounded-xl flex items-start ${result.success ? "bg-green-500/20 text-green-200" : "bg-red-500/20 text-red-200"}`}
                        >
                            {result.success ? <CheckCircle className="w-5 h-5 mr-3 mt-0.5" /> : <AlertCircle className="w-5 h-5 mr-3 mt-0.5" />}
                            <div className="w-full">
                                <h4 className="font-bold">{result.success ? "Success" : "Error"}</h4>
                                <p className="text-sm opacity-90 mb-4">{result.message}</p>

                                {result.success && result.productId && (
                                    <div className="mt-4 flex flex-col items-center p-4 bg-white/10 rounded-lg">
                                        <p className="text-sm text-slate-300 mb-2">Product QR Code</p>
                                        <ProductQRCode productId={result.productId} />
                                    </div>
                                )}
                            </div>
                        </motion.div>
                    )}
                </motion.div>
            </div>
        </div>
    );
}
