"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { ArrowLeft, Search, ShieldCheck, Box, User, Calendar, Loader2, FileText } from "lucide-react";
import Link from "next/link";
import { getProduct, type Product } from "@/lib/api";

export default function ConsumerPage() {
    const [searchId, setSearchId] = useState("");
    const [loading, setLoading] = useState(false);
    const [product, setProduct] = useState<Product | null>(null);
    const [error, setError] = useState("");

    const handleVerify = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!searchId.trim()) return;

        setLoading(true);
        setError("");
        setProduct(null);

        try {
            const data = await getProduct(searchId);
            setProduct(data);
        } catch (err: any) {
            setError("Product not found or verification failed.");
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

                <div className="text-center mb-10">
                    <h1 className="text-3xl font-bold text-white mb-2">Verify Product</h1>
                    <p className="text-slate-400">Enter a Product ID to check its authenticity.</p>
                </div>

                {/* Search Box */}
                <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="glass-panel p-2 rounded-2xl flex items-center mb-12"
                >
                    <Search className="w-6 h-6 text-slate-400 ml-4 mr-2" />
                    <form onSubmit={handleVerify} className="flex-1 flex">
                        <input
                            type="text"
                            value={searchId}
                            onChange={(e) => setSearchId(e.target.value)}
                            placeholder="Enter Product ID (e.g. P-1001)"
                            className="flex-1 bg-transparent border-none text-white placeholder-slate-500 focus:ring-0 p-3 outline-none"
                        />
                        <button
                            type="submit"
                            disabled={loading}
                            className="bg-blue-600 hover:bg-blue-500 text-white px-8 rounded-xl font-medium transition-colors disabled:opacity-50 ml-2"
                        >
                            {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : "Verify"}
                        </button>
                    </form>
                </motion.div>

                {/* Result Card */}
                {error && (
                    <div className="text-center text-red-400 bg-red-500/10 p-4 rounded-xl border border-red-500/20">
                        {error}
                    </div>
                )}

                {product && (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="glass-panel p-8 rounded-3xl border border-blue-500/30 shadow-[0_0_50px_-10px_rgba(59,130,246,0.2)]"
                    >
                        <div className="flex items-center justify-between mb-8 border-b border-white/10 pb-6">
                            <div>
                                <h2 className="text-2xl font-bold text-white">{product.name}</h2>
                                <div className="flex items-center text-green-400 text-sm mt-1">
                                    <ShieldCheck className="w-4 h-4 mr-1" />
                                    Authentic & Verified
                                </div>
                            </div>
                            <div className="bg-white/5 p-3 rounded-lg">
                                <Box className="w-8 h-8 text-blue-400" />
                            </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-4">
                            <InfoItem icon={<Box className="w-4 h-4" />} label="Product ID" value={product.id} />
                            <InfoItem icon={<User className="w-4 h-4" />} label="Producer" value={product.producerId} />
                            <InfoItem icon={<Calendar className="w-4 h-4" />} label="Manufacture Date" value={product.manufactureDate} />
                            <InfoItem icon={<ShieldCheck className="w-4 h-4" />} label="Status" value={product.status} highlight />
                        </div>

                        {product.integrityHash && (
                            <div className="mt-6 p-4 bg-white/5 rounded-xl border border-white/10">
                                <div className="flex items-center gap-2 mb-2">
                                    <FileText className="w-4 h-4 text-purple-400" />
                                    <p className="text-xs text-slate-500 uppercase tracking-wider">Integrity Hash</p>
                                </div>
                                <div className="flex items-center gap-2">
                                    <code className="text-[10px] md:text-xs text-green-300 font-mono break-all">{product.integrityHash}</code>
                                    <span className="shrink-0 text-[10px] bg-green-500/20 text-green-400 px-2 py-0.5 rounded-full">Valid</span>
                                </div>
                            </div>
                        )}

                        <div className="mt-8 pt-6 border-t border-white/10">
                            <p className="text-xs text-slate-500 uppercase tracking-wider mb-2">Blockchain Transaction ID</p>
                            <div className="font-mono text-xs text-slate-400 break-all bg-black/30 p-3 rounded-lg border border-white/5">
                                {product.blockchainTxId || "N/A"}
                            </div>
                        </div>
                    </motion.div>
                )}
            </div>
        </div>
    );
}

function InfoItem({ icon, label, value, highlight }: { icon: any, label: string, value: string, highlight?: boolean }) {
    return (
        <div className="flex items-start">
            <div className={`mt-1 mr-3 ${highlight ? "text-green-400" : "text-slate-400"}`}>
                {icon}
            </div>
            <div>
                <p className="text-xs text-slate-500 uppercase tracking-wider mb-0.5">{label}</p>
                <p className={`font-medium ${highlight ? "text-green-400" : "text-slate-200"}`}>{value}</p>
            </div>
        </div>
    );
}
