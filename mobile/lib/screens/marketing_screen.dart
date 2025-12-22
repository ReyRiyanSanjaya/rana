import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/local/database_helper.dart';
import 'package:intl/intl.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  List<Map<String, dynamic>> _products = [];
  String? _selectedProductId; // [FIX] Store ID instead of Map object
  Map<String, dynamic>? get _selectedProduct {
    if (_selectedProductId == null) return null;
    try {
      return _products.firstWhere((p) => p['id'] == _selectedProductId);
    } catch (e) {
      return null;
    }
  }

  String _selectedTemplate = 'Simple'; // Discount, New Arrival, Flash Sale, Quote, Simple
  bool _isLoading = true;

  final List<String> _templates = ['Discount', 'New Arrival', 'Flash Sale', 'Quote', 'Simple'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = data;
      // [FIX] Ensure selected ID is still valid, else reset
      if (_products.isNotEmpty) {
        if (_selectedProductId == null || !_products.any((p) => p['id'] == _selectedProductId)) {
           _selectedProductId = _products.first['id'];
        }
      } else {
        _selectedProductId = null;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text('Marketing Auto-Pilot', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Selector Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedProductId,
                          items: _products.map((p) {
                             final price = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(p['sellingPrice']);
                             return DropdownMenuItem<String>(
                               value: p['id'],
                               child: Text("${p['name']} - $price", overflow: TextOverflow.ellipsis),
                             );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedProductId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Pilih Template', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _templates.map((t) {
                        final isSelected = _selectedTemplate == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedTemplate = t),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. Preview Section
            Text('Preview Poster', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Center(
              child: _buildPosterPreview(),
            ),

            const SizedBox(height: 24),
            
            // 3. Action Buttons
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Poster berhasil dibagikan ke WhatsApp Story! (Simulasi)')),
                );
              },
              icon: const Icon(Icons.share),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Bagikan Sekarang'),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterPreview() {
    if (_selectedProduct == null) return const SizedBox();

    final productName = _selectedProduct!['name'];
    final price = _selectedProduct!['sellingPrice'] ?? 0;
    final fmtPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
    
    Color bg1, bg2;
    String title, subtitle;
    IconData icon;

    switch (_selectedTemplate) {
      case 'Discount':
        bg1 = Colors.red.shade400;
        bg2 = Colors.red.shade900;
        title = "DISKON SPESIAL!";
        subtitle = "Cuma Hari Ini Aja Lho!";
        icon = Icons.percent;
        break;
      case 'New Arrival':
        bg1 = Colors.blue.shade400;
        bg2 = Colors.blue.shade900;
        title = "BARU DATANG BOS!";
        subtitle = "Segera Serbu Sebelum Kehabisan";
        icon = Icons.new_releases;
        break;
      case 'Flash Sale':
        bg1 = Colors.orange.shade400;
        bg2 = Colors.deepOrange.shade900;
        title = "FLASH SALE ⚡";
        subtitle = "Harga Hancur Lebur!";
        icon = Icons.flash_on;
        break;
      default:
        bg1 = Colors.purple.shade400;
        bg2 = Colors.purple.shade900;
        title = "QUOTE HARI INI";
        subtitle = "Belanja Senang, Hati Tenang";
        icon = Icons.format_quote;
    }

    return Container(
      width: 300,
      height: 300, // Instagram Square
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg1, bg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Stack(
        children: [
          // Background Pattern (Circles)
          Positioned(right: -20, top: -20, child: CircleAvatar(radius: 60, backgroundColor: Colors.white10)),
          Positioned(left: -30, bottom: -30, child: CircleAvatar(radius: 80, backgroundColor: Colors.white10)),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(fontSize: 32, color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    productName,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fmtPrice,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Text(
              "Order via WhatsApp Sekarang!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
            ),
          )
        ],
      ),
    );
  }
}
