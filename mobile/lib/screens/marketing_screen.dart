import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/local/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // [NEW] Clipboard
import 'package:screenshot/screenshot.dart'; // [NEW]
import 'package:share_plus/share_plus.dart'; // [NEW]
import 'package:path_provider/path_provider.dart'; // [NEW]
import 'dart:io'; // [NEW]

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
  bool _showWatermark = true; // [NEW] Smart Branding State
  final TextEditingController _captionController = TextEditingController(); // [NEW]
  final ScreenshotController _screenshotController = ScreenshotController(); // [NEW]

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Preview Poster', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text("Watermark", style: GoogleFonts.poppins(fontSize: 12)),
                    Switch(value: _showWatermark, onChanged: (val) => setState(() => _showWatermark = val), activeColor: Colors.pinkAccent),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: _buildPosterPreview(),
            ),
            
            const SizedBox(height: 24),
            
            // [NEW] 3. AI Copywriting Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade100)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       const Icon(Icons.auto_awesome, color: Colors.purple),
                       const SizedBox(width: 8),
                       Text('AI Caption Generator', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.purple)),
                     ],
                   ),
                   const SizedBox(height: 12),
                   TextField(
                     controller: _captionController,
                     maxLines: 4,
                     decoration: const InputDecoration(
                       filled: true, fillColor: Colors.white,
                       hintText: 'Klik "Buat Caption" untuk hasil otomatis...',
                       border: OutlineInputBorder(borderSide: BorderSide.none),
                     ),
                   ),
                   const SizedBox(height: 12),
                   Row(
                     children: [
                       Expanded(
                         child: ElevatedButton.icon(
                           onPressed: _generateCaption, 
                           icon: const Icon(Icons.refresh), 
                           label: const Text('Buat Caption'),
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white)
                         )
                       ),
                       const SizedBox(width: 8),
                       IconButton(
                         onPressed: () {
                           Clipboard.setData(ClipboardData(text: _captionController.text));
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caption disalin!')));
                         }, 
                         icon: const Icon(Icons.copy, color: Colors.purple),
                         tooltip: 'Salin Caption',
                       )
                     ],
                   )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 3. Action Buttons
            // 3. Action Buttons
            FilledButton.icon(
              onPressed: () async {
                 // [NEW] Real Capture and Share Logic
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sedang membuat poster...')));
                 
                 try {
                   final directory = (await getApplicationDocumentsDirectory()).path;
                   String fileName = "Rana_Poster_${DateTime.now().millisecondsSinceEpoch}.png";
                   String path = '$directory/$fileName';
                   
                   await _screenshotController.captureAndSave(
                      directory, 
                      fileName: fileName,
                      pixelRatio: 2.0 // High Quality
                   );

                   // Verify file exists then share
                   File imgFile = File(path);
                   if (await imgFile.exists()) {
                      // [UPDATED] Share with Caption
                      await Share.shareXFiles(
                        [XFile(path)], 
                        text: _captionController.text.isNotEmpty ? _captionController.text : "Poster Promo ${_selectedProduct?['name'] ?? ''}"
                      );
                   } else {
                      throw Exception("Gagal menyimpan gambar");
                   }

                 } catch (e) {
                   if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membagikan: $e'), backgroundColor: Colors.red));
                   }
                 }
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

    return Screenshot( // [NEW] Wrap in Screenshot Widget
      controller: _screenshotController,
      child: Container(
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
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
            ),
            
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: _showWatermark 
               ? Container(
                   margin: const EdgeInsets.symmetric(horizontal: 24),
                   padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                   decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(4)),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.store, color: Colors.white, size: 10),
                       const SizedBox(width: 4),
                       Text("Rana Store", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 8),
                       Container(width: 1, height: 10, color: Colors.white),
                       const SizedBox(width: 8),
                       const Icon(Icons.phone, color: Colors.white, size: 10),
                       const SizedBox(width: 4),
                       Text("0812-3456-7890", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10)),
                     ],
                   ),
                 )
               : Text(
                  "Order via WhatsApp Sekarang!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
                ),
            )
          ],
        ),
      ),
    );
  }
  // [NEW] AI Logic
  void _generateCaption() {
    if (_selectedProduct == null) return;
    
    final name = _selectedProduct!['name'];
    final price = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_selectedProduct!['sellingPrice']);
    
    List<String> templates = [];
    
    switch (_selectedTemplate) {
      case 'Discount':
        templates = [
          "🔥 DISKON SPESIAL HARI INI! 🔥\n\nDapatkan $name cuma seharga $price lho! Mumpung lagi promo, yuk borong sekarang sebelum kehabisan.\n\n📍 Rana Store\n📞 Order via WA: 0812-3456-7890",
          "Turun Harga! 📉\n\n$name favorit kamu lagi diskon nih. Cuma $price aja! Kapan lagi dapet harga segini?\n\nYuk order sekarang!",
        ];
        break;
      case 'New Arrival':
        templates = [
          "✨ BARANG BARU NIH! ✨\n\nHalo kak, kita baru aja restock $name nih. Harganya $price aja. Kualitas dijamin mantap!\n\nStok terbatas ya, siapa cepat dia dapat! 🏃‍♂️💨",
          "Fresh from the oven! 🥐\n\n$name sudah tersedia di Rana Store. Yuk cobain sekarang, cuma $price!",
        ];
        break;
      case 'Flash Sale':
        templates = [
          "⚡ FLASH SALE ALERT! ⚡\n\nCuma HARI INI! Dapatkan $name dengan harga spesial $price.\n\nJangan sampai nyesel karena kehabisan ya! 😱",
        ];
        break;
      case 'Quote':
         templates = [
          "Mood Booster Hari Ini 💡\n\n\"Belanja Senang, Hati Tenang\"\n\nYuk lengkapi harimu dengan $name, cuma $price.\n\n#RanaStore #HappyShopping",
        ];
        break;
      default:
        templates = [
          "Halo Kak! 👋\n\n$name ready stok nih, harga bersahabat cuma $price.\n\nMinat? Langsung balas chat ini ya!",
          "Rekomendasi Hari Ini: $name 🌟\n\nHarga: $price\nKualitas: ⭐⭐⭐⭐⭐\n\nOrder sekarang sebelum kehabisan!",
        ];
    }
    
    // Pick Random
    setState(() {
      _captionController.text = (templates..shuffle()).first;
    });
  }
}
