import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/producer_screen.dart';
import 'screens/consumer_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Origin Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.outfitTextTheme(),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a2a6c), Color(0xFFb21f1f), Color(0xFFfdbb2d)] // Nice gradient
            )
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.verified_user_outlined, size: 80, color: Colors.white),
               const SizedBox(height: 20),
               Text(
                "Origin Verify",
                style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
               Text(
                "Blockchain-based Product Authentication",
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 50),

              _buildRoleButton(
                  context, 
                  "I am a Producer", 
                  Icons.store, 
                  Colors.blue.shade800,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProducerScreen()))
              ),
              const SizedBox(height: 20),
              _buildRoleButton(
                  context, 
                  "I am a Consumer", 
                  Icons.qr_code_scanner, 
                  Colors.green.shade800,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsumerScreen()))
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String text, IconData icon, Color color, VoidCallback onTap) {
      return SizedBox(
          width: 280,
          height: 60,
          child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white),
              label: Text(text, style: GoogleFonts.outfit(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5
              ),
          ),
      );
  }
}
