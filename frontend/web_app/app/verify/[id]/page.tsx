"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { ArrowLeft, Loader2, CheckCircle, XCircle, Package } from "lucide-react";
import Link from "next/link";
import { getProduct } from "@/lib/api";

export default function VerifyPage() {
    const params = useParams();
    const router = useRouter();
    const id = params?.id as string;

    // Using explicit any to bypass strict type checking for the MVP quick fix
    const [product, setProduct] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (!id) return;

        const fetchProduct = async () => {
            try {
                const data = await getProduct(id);
                setProduct(data);
            } catch (err: any) {
                console.error(err);
                setError(err.response?.data?.error || "Failed to load product details.");
            } finally {
                setLoading(false);
            }
        };

        fetchProduct();
    }, [id]);

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
                    <div className="mb-8 border-b border-white/10 pb-6">
                        <h1 className="text-3xl font-bold text-white mb-2">Product Verification</h1>
                        <p className="text-slate-400">Verifying authenticity for ID: <span className="font-mono text-white">{id}</span></p>
                    </div>

                    {loading ? (
                        <div className="flex flex-col items-center justify-center py-12">
                            <Loader2 className="w-12 h-12 text-purple-500 animate-spin mb-4" />
                            <p className="text-slate-300">Querying Blockchain Ledger...</p>
                        </div>
                    ) : error ? (
                        <div className="flex flex-col items-center justify-center py-8 text-center bg-red-500/10 rounded-xl border border-red-500/20">
                            <XCircle className="w-16 h-16 text-red-500 mb-4" />
                            <h2 className="text-2xl font-bold text-white mb-2">Verification Failed</h2>
                            <p className="text-red-200">{error}</p>
                            <p className="text-slate-400 mt-4 text-sm">The product ID does not exist or has been tampered with.</p>
                        </div>
                    ) : product ? (
                        <div className="space-y-6">
                            <div className="flex items-center justify-center py-6 bg-green-500/10 rounded-xl border border-green-500/20 mb-6">
                                <CheckCircle className="w-10 h-10 text-green-500 mr-4" />
                                <div>
                                    <h2 className="text-xl font-bold text-white">Authentic Product</h2>
                                    <p className="text-green-200 text-sm">Verified on Hyperledger Fabric</p>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div className="p-4 bg-white/5 rounded-lg">
                                    <label className="text-xs text-slate-400 uppercase tracking-wider">Product Name</label>
                                    <p className="text-lg font-medium text-white flex items-center mt-1">
                                        <Package className="w-4 h-4 mr-2 text-purple-400" />
                                        {product.name}
                                    </p>
                                </div>
                                <div className="p-4 bg-white/5 rounded-lg">
                                    <label className="text-xs text-slate-400 uppercase tracking-wider">Status</label>
                                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 mt-2">
                                        {product.status}
                                    </span>
                                </div>
                                <div className="p-4 bg-white/5 rounded-lg">
                                    <label className="text-xs text-slate-400 uppercase tracking-wider">Producer ID</label>
                                    <p className="text-white font-mono mt-1">{product.producerId}</p>
                                </div>
                                <div className="p-4 bg-white/5 rounded-lg">
                                    <label className="text-xs text-slate-400 uppercase tracking-wider">Manufacture Date</label>
                                    <p className="text-white mt-1">{product.manufactureDate}</p>
                                </div>
                            </div>

                            <div className="mt-8 p-4 bg-slate-900/50 rounded-lg overflow-hidden">
                                <label className="text-xs text-slate-500 uppercase tracking-wider mb-2 block">Blockchain Signature (Owner)</label>
                                <p className="font-mono text-xs text-slate-400 break-all">
                                    {product.owner}
                                </p>
                            </div>
                        </div>
                    ) : null}
                </motion.div>
            </div>
        </div>
    );
}
