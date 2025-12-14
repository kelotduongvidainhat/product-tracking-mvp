import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';

class ConsumerScreen extends StatefulWidget {
  const ConsumerScreen({super.key});

  @override
  State<ConsumerScreen> createState() => _ConsumerScreenState();
}

class _ConsumerScreenState extends State<ConsumerScreen> {
  final MobileScannerController controller = MobileScannerController();
  final _productService = ProductService();
  final _idController = TextEditingController(); // Manual input fallback
  
  Product? _scannedProduct;
  bool _isLoading = false;
  bool _isError = false;

  Future<void> _fetchProduct(String id) async {
      setState(() {
          _isLoading = true;
          _isError = false;
          _scannedProduct = null;
          _idController.text = id;
      });

      final product = await _productService.getProduct(id);

      setState(() {
          _isLoading = false;
          _scannedProduct = product;
          if (product == null) {
              _isError = true;
          }
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _buildProductInfo() {
      if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
      }
      if (_isError) {
           return Center(
               child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                       const Icon(Icons.error_outline, size: 60, color: Colors.red),
                       const SizedBox(height: 10),
                       Text("Product Not Found or Network Error", style: GoogleFonts.outfit(fontSize: 18))
                   ],
               )
           );
      }
      if (_scannedProduct != null) {
          final isVerified = _scannedProduct!.status == "VERIFIED";
          return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                              children: [
                                  Icon(
                                      isVerified ? Icons.verified : Icons.hourglass_top,
                                      color: isVerified ? Colors.green : Colors.orange,
                                      size: 30
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isVerified ? "Verified Origin" : "Processing...",
                                    style: GoogleFonts.outfit(
                                        fontSize: 22, 
                                        fontWeight: FontWeight.bold,
                                        color: isVerified ? Colors.green : Colors.orange
                                    ),
                                  ),
                              ],
                          ),
                          const Divider(height: 30),
                          _infoRow("Product Name", _scannedProduct!.name),
                          _infoRow("Producer", _scannedProduct!.producerID),
                          _infoRow("Date", _scannedProduct!.manufactureDate),
                          _infoRow("Blockchain ID", _scannedProduct!.id),
                      ],
                  ),
              ),
          );
      }
      return Center(
          child: Text("Scan a QR code or enter ID to check origin", style: GoogleFonts.outfit(color: Colors.grey)),
      );
  }

  Widget _infoRow(String label, String value) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text(value)),
              ],
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consumer Mode', style: GoogleFonts.outfit()),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                        // Pause logic would go here if needed, but for simplicity we just fetch
                        // MobileScanner is continuous
                        if (!_isLoading) {
                            _fetchProduct(barcode.rawValue!);
                        }
                    }
                }
              },
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                  children: [
                      Expanded(
                          child: TextField(
                              controller: _idController,
                              decoration: const InputDecoration(
                                  hintText: "Or enter Product ID manually",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.search)
                              ),
                          ) // Manual Input
                      ),
                      IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                               if(_idController.text.isNotEmpty) {
                                   _fetchProduct(_idController.text);
                               }
                          },
                      )
                  ],
              ),
          ),
          Expanded(
            flex: 3,
            child: Container(
                width: double.infinity,
                color: Colors.grey[100],
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildProductInfo(),
                ),
            ),
          )
        ],
      ),
    );
  }
}
