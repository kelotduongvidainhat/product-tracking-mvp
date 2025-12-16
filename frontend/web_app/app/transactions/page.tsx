"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { ArrowLeft, Loader2, RefreshCw, CheckCircle, Clock, Copy, FileText } from "lucide-react";
import Link from "next/link";
import { getAllProducts, type Product } from "@/lib/api";
import { ProductQRCode } from "@/app/components/ProductQRCode";

export default function TransactionsPage() {
    const [products, setProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchProducts = async () => {
        setLoading(true);
        try {
            const data = await getAllProducts();
            setProducts(data);
        } catch (error) {
            console.error("Failed to fetch products:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchProducts();
    }, []);

    return (
        <div className="min-h-screen p-6 md:p-12 flex flex-col items-center">
            <div className="w-full max-w-5xl">
                <div className="flex items-center justify-between mb-8">
                    <Link href="/" className="inline-flex items-center text-slate-400 hover:text-white transition-colors">
                        <ArrowLeft className="w-4 h-4 mr-2" /> Back to Home
                    </Link>
                    <button
                        onClick={fetchProducts}
                        className="p-2 bg-white/5 hover:bg-white/10 rounded-lg transition-colors text-slate-300 hover:text-white"
                        title="Refresh List"
                    >
                        <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
                    </button>
                </div>

                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="glass-panel p-8 rounded-2xl overflow-hidden"
                >
                    <div className="mb-6">
                        <h1 className="text-3xl font-bold text-white mb-2">Transaction History</h1>
                        <p className="text-slate-400">List of all products recorded on the ledger system.</p>
                    </div>

                    {/* Latest Activity Carousel */}
                    {products.length > 0 && !loading && (
                        <div className="mb-10">
                            <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4 flex items-center gap-2">
                                <Clock className="w-4 h-4" /> Recent Activity
                            </h2>
                            <div className="flex gap-4 overflow-x-auto pb-6 snap-x snap-mandatory scrollbar-hide -mx-4 px-4 md:mx-0 md:px-0">
                                {products.map((product) => (
                                    <Link href={`/verify/${product.id}`} key={product.id} className="snap-center shrink-0">
                                        <motion.div
                                            whileHover={{ y: -5 }}
                                            className="w-72 bg-white/5 border border-white/10 p-5 rounded-2xl hover:bg-white/10 transition-colors group cursor-pointer h-full"
                                        >
                                            <div className="flex items-start justify-between mb-4">
                                                <div className="w-12 h-12 bg-white p-1 rounded-lg">
                                                    <div className="w-full h-full overflow-hidden">
                                                        <ProductQRCode productId={product.id} size={40} />
                                                    </div>
                                                </div>
                                                <span className={`px-2 py-1 rounded-full text-xs font-bold 
                                                    ${product.status === 'VERIFIED' ? 'bg-green-500/20 text-green-400' : 'bg-yellow-500/20 text-yellow-400'}`}>
                                                    {product.status}
                                                </span>
                                            </div>
                                            <h3 className="text-white font-bold text-lg truncate mb-1">{product.name}</h3>
                                            <p className="text-slate-500 text-xs mb-3 font-mono">{product.id}</p>
                                            {product.integrityHash && (
                                                <div className="flex items-center gap-1.5 text-green-400/80 bg-green-500/5 p-2 rounded-lg border border-green-500/10">
                                                    <FileText className="w-3 h-3 flex-shrink-0" />
                                                    <code className="text-[10px] font-mono truncate">{product.integrityHash}</code>
                                                </div>
                                            )}
                                        </motion.div>
                                    </Link>
                                ))}
                            </div>
                        </div>
                    )}

                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="text-slate-400 border-b border-white/10">
                                    <th className="py-4 px-4 font-medium text-sm uppercase tracking-wider">Product ID</th>
                                    <th className="py-4 px-4 font-medium text-sm uppercase tracking-wider">Name</th>
                                    <th className="py-4 px-4 font-medium text-sm uppercase tracking-wider">Producer</th>
                                    <th className="py-4 px-4 font-medium text-sm uppercase tracking-wider">Status</th>
                                    <th className="py-4 px-4 font-medium text-sm uppercase tracking-wider">QR Code</th>
                                    <th className="py-4 px-4 font-medium text-sm uppercase tracking-wider text-right">Integrity</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-white/5">
                                {loading && products.length === 0 ? (
                                    <tr>
                                        <td colSpan={6} className="py-12 text-center text-slate-500">
                                            <div className="flex items-center justify-center">
                                                <Loader2 className="w-6 h-6 animate-spin mr-2" /> Loading records...
                                            </div>
                                        </td>
                                    </tr>
                                ) : products.length === 0 ? (
                                    <tr>
                                        <td colSpan={6} className="py-12 text-center text-slate-500">
                                            No transactions found. Start by creating a product!
                                        </td>
                                    </tr>
                                ) : (
                                    products.map((product) => (
                                        <tr key={product.id} className="hover:bg-white/5 transition-colors group">
                                            <td className="py-4 px-4">
                                                <Link href={`/verify/${product.id}`} className="font-mono text-purple-400 hover:text-purple-300 font-medium">
                                                    {product.id}
                                                </Link>
                                            </td>
                                            <td className="py-4 px-4 text-white font-medium">{product.name}</td>
                                            <td className="py-4 px-4 text-slate-300">{product.producerId}</td>
                                            <td className="py-4 px-4">
                                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium 
                                                    ${product.status === 'VERIFIED' ? 'bg-green-500/20 text-green-400' :
                                                        product.status === 'FAILED' ? 'bg-red-500/20 text-red-400' :
                                                            'bg-yellow-500/20 text-yellow-400'}`}>
                                                    {product.status === 'VERIFIED' ? <CheckCircle className="w-3 h-3 mr-1" /> :
                                                        product.status === 'PENDING' ? <Clock className="w-3 h-3 mr-1" /> : null}
                                                    {product.status}
                                                </span>
                                            </td>
                                            <td className="py-4 px-4">
                                                <div className="w-12 h-12 bg-white p-1 rounded-lg">
                                                    {/* Using a simplified QR for list view or reusing the component with strict sizing */}
                                                    <div className="w-full h-full overflow-hidden">
                                                        <ProductQRCode productId={product.id} size={40} />
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="py-4 px-4 text-right">
                                                {product.integrityHash ? (
                                                    <div className="flex items-center justify-end gap-2 group/hash">
                                                        <code className="bg-slate-900/50 px-2 py-1 rounded text-xs font-mono text-green-400/80 border border-white/5">
                                                            {product.integrityHash.substring(0, 12)}...
                                                        </code>
                                                        <button
                                                            onClick={() => navigator.clipboard.writeText(product.integrityHash || "")}
                                                            className="p-1.5 hover:bg-white/10 rounded-md transition-colors text-slate-500 hover:text-white opacity-0 group-hover/hash:opacity-100"
                                                            title="Copy Hash"
                                                        >
                                                            <Copy className="w-3.5 h-3.5" />
                                                        </button>
                                                    </div>
                                                ) : (
                                                    <span className="text-slate-600">-</span>
                                                )}
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </motion.div>
            </div>
        </div>
    );
}
