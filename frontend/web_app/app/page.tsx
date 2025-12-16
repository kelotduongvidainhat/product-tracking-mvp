"use client";

import { motion } from "framer-motion";
import { PackageSearch, Factory, List } from "lucide-react";
import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-6 relative z-10">
      <div className="absolute inset-0 bg-transparent z-0" />

      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
        className="text-center mb-16 z-10"
      >
        <h1 className="text-5xl md:text-7xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-blue-400 via-purple-500 to-pink-500 drop-shadow-lg">
          Product Tracking
        </h1>
        <p className="mt-4 text-slate-300 text-lg md:text-xl font-light tracking-wide">
          Blockchain-Enabled Origin Verification System
        </p>
      </motion.div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 w-full max-w-4xl z-10">
        {/* Producer Card */}
        <Link href="/producer" className="group">
          <motion.div
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="glass-card p-8 h-full flex flex-col items-center justify-center text-center cursor-pointer border-t-4 border-t-purple-500"
          >
            <div className="w-20 h-20 bg-purple-500/10 rounded-full flex items-center justify-center mb-6 group-hover:bg-purple-500/20 transition-colors">
              <Factory className="w-10 h-10 text-purple-400" />
            </div>
            <h2 className="text-2xl font-bold text-white mb-2">Producer</h2>
            <p className="text-slate-400">Create and register new products on the blockchain.</p>
          </motion.div>
        </Link>

        {/* Consumer Card */}
        <Link href="/consumer" className="group">
          <motion.div
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="glass-card p-8 h-full flex flex-col items-center justify-center text-center cursor-pointer border-t-4 border-t-blue-500"
          >
            <div className="w-20 h-20 bg-blue-500/10 rounded-full flex items-center justify-center mb-6 group-hover:bg-blue-500/20 transition-colors">
              <PackageSearch className="w-10 h-10 text-blue-400" />
            </div>
            <h2 className="text-2xl font-bold text-white mb-2">Consumer</h2>
            <p className="text-slate-400">Verify product authenticity and origin history.</p>
          </motion.div>
        </Link>
      </div>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.5 }}
        className="mt-12 z-10"
      >
        <Link href="/transactions" className="flex items-center text-slate-400 hover:text-white transition-colors gap-2 px-6 py-3 rounded-full hover:bg-white/5 border border-transparent hover:border-white/10">
          <List className="w-5 h-5" />
          <span>View All Transactions</span>
        </Link>
      </motion.div>

      <footer className="absolute bottom-6 text-slate-500 text-sm">
        Powered by Hyperledger Fabric
      </footer>
    </main >
  );
}
