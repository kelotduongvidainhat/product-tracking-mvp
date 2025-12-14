import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';

class ProducerScreen extends StatefulWidget {
  const ProducerScreen({super.key});

  @override
  State<ProducerScreen> createState() => _ProducerScreenState();
}

class _ProducerScreenState extends State<ProducerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _producerController = TextEditingController(text: "Vinamilk-VN");
  final _hashController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
      super.initState();
      // Auto-generate ID and Hash for demo
      _idController.text = "PROD-${DateTime.now().millisecondsSinceEpoch}";
      _hashController.text = "sha256:hash-${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final product = Product(
        id: _idController.text,
        name: _nameController.text,
        producerID: _producerController.text,
        manufactureDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        certHash: _hashController.text,
        status: 'PENDING',
      );

      final success = await _productService.createProduct(product);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product Batch created! Backend processing...')),
        );
        // Reset form
        _idController.text = "PROD-${DateTime.now().millisecondsSinceEpoch}";
        _nameController.clear();
        _hashController.text = "sha256:hash-${DateTime.now().millisecondsSinceEpoch}";
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create product.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Producer Mode', style: GoogleFonts.outfit()),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
               Text(
                "Create New Product Batch",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'Product ID', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter ID' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                 validator: (value) => value!.isEmpty ? 'Please enter Name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _producerController,
                decoration: const InputDecoration(labelText: 'Producer ID', border: OutlineInputBorder()),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _hashController,
                decoration: const InputDecoration(labelText: 'Certificate Hash (Mock)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Create Batch', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
