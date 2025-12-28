import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/local/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart'; // [NEW]
import 'package:dio/dio.dart'; // [NEW]
import '../constants.dart'; // [NEW]
import 'package:provider/provider.dart'; // [NEW]
import '../providers/auth_provider.dart'; // [NEW]

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _products = [];
  String? _selectedProductId;
  Map<String, dynamic>? get _selectedProduct {
    if (_selectedProductId == null) return null;
    try {
      return _products.firstWhere((p) => p['id'] == _selectedProductId);
    } catch (e) {
      return null;
    }
  }

  String _selectedTemplate = 'Discount'; // Default
  bool _isLoading = true;
  bool _showWatermark = true;
  final TextEditingController _captionController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // [NEW] Modes
  bool _isVideoMode = false;
  late TabController _tabController;
  
  // [NEW] Controllers for custom price and duration
  final TextEditingController _newPriceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '7'); // Default 7 days
  
  final List<String> _templates = ['Discount', 'New Arrival', 'Flash Sale', 'Quote', 'Simple'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProducts();
    
    // Auto-generate initial caption listener
    _tabController.addListener(() {
        setState(() {
            _isVideoMode = _tabController.index == 1;
        });
    });
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = data;
      if (_products.isNotEmpty) {
        if (_selectedProductId == null || !_products.any((p) => p['id'] == _selectedProductId)) {
           _selectedProductId = _products.first['id'];
        }
      } else {
        _selectedProductId = null;
      }
      _isLoading = false;
    });
    // Trigger initial caption
    if (_selectedProduct != null) _generateCaption();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text('Marketing Studio 🚀', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: const [
                Tab(icon: Icon(Icons.image), text: "Poster"),
                Tab(icon: Icon(Icons.movie_filter), text: "Video Animation"),
            ],
        ),
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
                          onChanged: (val) {
                              setState(() => _selectedProductId = val);
                              _generateCaption();
                          },
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
                          onSelected: (val) {
                              setState(() => _selectedTemplate = t);
                              _generateCaption();
                          },
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
                Text(_isVideoMode ? 'Live Preview 🔴' : 'Preview Poster', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text("Branding", style: GoogleFonts.poppins(fontSize: 12)),
                    Switch(value: _showWatermark, onChanged: (val) => setState(() => _showWatermark = val), activeColor: Colors.pinkAccent),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: _buildPreview(),
            ),

            if (_selectedTemplate == 'Discount' || _selectedTemplate == 'Flash Sale') ...[
                 const SizedBox(height: 16),
                 Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                         color: Colors.orange.shade50,
                         border: Border.all(color: Colors.orange),
                         borderRadius: BorderRadius.circular(8)
                     ),
                     child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                             Row(
                                 children: [
                                     const Icon(Icons.percent, color: Colors.orange),
                                     const SizedBox(width: 12),
                                     Expanded(
                                         child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                                 Text(_selectedTemplate == 'Flash Sale' ? "Flash Sale Price" : "Discount Price", 
                                                     style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                                 Text("Set harga baru untuk diterapkan di sistem", style: GoogleFonts.poppins(fontSize: 12)),
                                             ],
                                         )
                                     ),
                                 ],
                             ),
                             const SizedBox(height: 12),
                             Row(
                                 children: [
                                     Expanded(
                                         child: TextField(
                                             controller: _newPriceController,
                                             keyboardType: TextInputType.number,
                                             decoration: InputDecoration(
                                                 hintText: 'Harga Baru',
                                                 prefixText: 'Rp ',
                                                 filled: true,
                                                 fillColor: Colors.white,
                                                 border: OutlineInputBorder(
                                                     borderRadius: BorderRadius.circular(8),
                                                     borderSide: BorderSide(color: Colors.orange.shade200),
                                                 ),
                                                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                             ),
                                         ),
                                     ),
                                     const SizedBox(width: 8),
                                     SizedBox(
                                         width: 70,
                                         child: TextField(
                                             controller: _durationController,
                                             keyboardType: TextInputType.number,
                                             textAlign: TextAlign.center,
                                             decoration: InputDecoration(
                                                 hintText: 'Hari',
                                                 suffixText: 'hari',
                                                 filled: true,
                                                 fillColor: Colors.white,
                                                 border: OutlineInputBorder(
                                                     borderRadius: BorderRadius.circular(8),
                                                     borderSide: BorderSide(color: Colors.orange.shade200),
                                                 ),
                                                 contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                             ),
                                         ),
                                     ),
                                     const SizedBox(width: 8),
                                     FilledButton.icon(
                                         onPressed: _applyDiscountToStore,
                                         icon: const Icon(Icons.check, size: 18),
                                         label: const Text("TERAPKAN"),
                                         style: FilledButton.styleFrom(
                                             backgroundColor: Colors.deepOrange,
                                         ),
                                     ),
                                 ],
                             ),
                             if (_selectedProduct != null) ...[
                                 const SizedBox(height: 8),
                                 Text(
                                     "Harga asli: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_selectedProduct!['originalPrice'] ?? _selectedProduct!['sellingPrice'])} | Durasi: berlaku selama ${_durationController.text} hari",
                                     style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                                 ),
                             ],
                         ],
                     ),
                 ),
            ],
            
            const SizedBox(height: 24),
            
            // 3. Caption Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Caption Otomatis', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   TextField(
                     controller: _captionController,
                     maxLines: 4,
                     decoration: const InputDecoration(
                       filled: true, fillColor: Colors.white,
                       hintText: 'Caption akan muncul disini...',
                       border: OutlineInputBorder(borderSide: BorderSide.none),
                     ),
                   ),
                   const SizedBox(height: 8),
                   Align(
                       alignment: Alignment.centerRight,
                       child: IconButton(
                         onPressed: () {
                           Clipboard.setData(ClipboardData(text: _captionController.text));
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caption disalin!')));
                         }, 
                         icon: const Icon(Icons.copy, size: 20),
                         tooltip: 'Salin',
                       ),
                   )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 4. Action Buttons
            FilledButton.icon(
              onPressed: _shareContent,
              icon: Icon(_isVideoMode ? Icons.movie_filter : Icons.share),
              label: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_isVideoMode ? 'Bagikan Video' : 'Bagikan Poster'),
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

  Widget _buildPreview() {
     // If Video Mode, we wrap content in Animation Logic
     Widget content = _buildPosterContent();
     
     if (_selectedProduct == null) return const SizedBox();

     // Both modes now use Screenshot for sharing capability
     return Screenshot(
         controller: _screenshotController,
         child: _isVideoMode 
             ? Container(
                 key: ValueKey(_selectedTemplate), // Force rebuild on template change
                 child: content
              )
             : content
     );
  }

  Widget _buildPosterContent() {
    if (_selectedProduct == null) return const SizedBox();

    final productName = _selectedProduct!['name'];
    final currentPrice = _selectedProduct!['sellingPrice'] ?? 0;
    final originalPrice = _selectedProduct!['originalPrice'] ?? currentPrice;
    
    final fmtCurrentPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(currentPrice);
    final fmtOriginalPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(originalPrice);
    
    // Calculate validity date
    final durationDays = int.tryParse(_durationController.text) ?? 7;
    final validUntil = DateTime.now().add(Duration(days: durationDays));
    final fmtValidUntil = DateFormat('dd/MM/yyyy').format(validUntil);
    
    // Check if this is a discount type template
    final isDiscountType = _selectedTemplate == 'Discount' || _selectedTemplate == 'Flash Sale';
    final hasDiscount = isDiscountType && originalPrice > currentPrice;
    
    // Calculate discount percentage  
    int discountPercent = 0;
    if (hasDiscount && originalPrice > 0) {
      discountPercent = (((originalPrice - currentPrice) / originalPrice) * 100).round();
    }
    
    // Template-specific styling
    List<Color> gradientColors;
    String title, subtitle;
    IconData icon;
    Color accentColor;

    switch (_selectedTemplate) {
      case 'Discount':
        gradientColors = [const Color(0xFFFF416C), const Color(0xFFFF4B2B)];
        title = "🔥 DISKON GILA!";
        subtitle = "Promo Terbatas!";
        icon = Icons.local_offer;
        accentColor = Colors.yellowAccent;
        break;
      case 'New Arrival':
        gradientColors = [const Color(0xFF667eea), const Color(0xFF764ba2)];
        title = "✨ BARU DATANG!";
        subtitle = "Fresh & Trending";
        icon = Icons.auto_awesome;
        accentColor = Colors.cyanAccent;
        break;
      case 'Flash Sale':
        gradientColors = [const Color(0xFFf12711), const Color(0xFFf5af19)];
        title = "⚡ FLASH SALE";
        subtitle = "Buruan Sebelum Habis!";
        icon = Icons.bolt;
        accentColor = Colors.white;
        break;
      case 'Quote':
        gradientColors = [const Color(0xFF11998e), const Color(0xFF38ef7d)];
        title = "💬 QUOTE";
        subtitle = "Inspirasi Hari Ini";
        icon = Icons.format_quote;
        accentColor = Colors.white;
        break;
      default:
        gradientColors = [const Color(0xFF2193b0), const Color(0xFF6dd5ed)];
        title = "📢 PROMO";
        subtitle = "Penawaran Spesial";
        icon = Icons.campaign;
        accentColor = Colors.white;
    }

    // Main Icon with glow effect
    Widget mainIcon = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Icon(icon, size: 36, color: Colors.white),
    );
    
    if (_isVideoMode) {
      mainIcon = mainIcon.animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(duration: 800.ms, begin: const Offset(1, 1), end: const Offset(1.15, 1.15))
          .then().shimmer(duration: 600.ms, color: Colors.white54);
    }

    // Title with shadow
    Widget titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 22, 
        fontWeight: FontWeight.w900, 
        color: Colors.white,
        shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 2))],
      ),
    );
    
    if (_isVideoMode) {
      titleWidget = titleWidget.animate()
          .slideY(begin: -0.3, end: 0, duration: 500.ms, curve: Curves.easeOutBack)
          .fadeIn();
    }

    // Product name card
    Widget productWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Text(
        productName,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
    
    if (_isVideoMode) {
      productWidget = productWidget.animate()
          .slideX(begin: -0.5, end: 0, duration: 600.ms, delay: 150.ms, curve: Curves.easeOut)
          .fadeIn();
    }

    // Price section
    Widget priceSection;
    if (hasDiscount) {
      priceSection = Column(
        children: [
          Text(
            fmtOriginalPrice,
            style: GoogleFonts.poppins(
              fontSize: 13, 
              fontWeight: FontWeight.w500, 
              color: Colors.white70,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white70,
              decorationThickness: 2,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: accentColor.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)],
            ),
            child: Text(
              fmtCurrentPrice,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red.shade700),
            ),
          ),
        ],
      );
    } else {
      priceSection = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 12)],
        ),
        child: Text(
          fmtCurrentPrice,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.grey.shade900),
        ),
      );
    }
    
    if (_isVideoMode) {
      priceSection = priceSection.animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1500.ms, color: Colors.white38)
          .scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
    }

    // Subtitle badge
    Widget subtitleWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        subtitle,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
    
    if (_isVideoMode) {
      subtitleWidget = subtitleWidget.animate()
          .fadeIn(delay: 800.ms, duration: 400.ms)
          .slideY(begin: 0.3, end: 0);
    }

    return Container(
        width: 300,
        height: 380,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: gradientColors[0].withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
            BoxShadow(color: gradientColors[1].withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: Stack(
          children: [
            // Background decorations
            if (_isVideoMode) ...[
              Positioned(
                top: -40, right: -40,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                ).animate(onPlay: (c) => c.repeat())
                  .scale(duration: 2000.ms, begin: const Offset(1, 1), end: const Offset(1.3, 1.3))
                  .then().scale(duration: 2000.ms, begin: const Offset(1.3, 1.3), end: const Offset(1, 1)),
              ),
            ] else ...[
              Positioned(top: -30, right: -30, child: Container(
                width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
              )),
              Positioned(bottom: -40, left: -20, child: Container(
                width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
              )),
            ],

            // Discount badge
            if (hasDiscount) Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Text("-$discountPercent%", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.red.shade700)),
              ).animate(target: _isVideoMode ? 1 : 0).scale(duration: 500.ms, curve: Curves.elasticOut),
            ),
            
            // Validity badge
            if (isDiscountType) Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 10),
                    const SizedBox(width: 4),
                    Text("s.d $fmtValidUntil", style: GoogleFonts.poppins(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ).animate(target: _isVideoMode ? 1 : 0).fadeIn(duration: 400.ms, delay: 200.ms),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  mainIcon,
                  const SizedBox(height: 10),
                  titleWidget,
                  const SizedBox(height: 10),
                  productWidget,
                  const SizedBox(height: 10),
                  priceSection,
                  const SizedBox(height: 8),
                  subtitleWidget,
                ],
              ),
            ),
            
            // Branding watermark
            Positioned(
              bottom: 8, left: 0, right: 0,
              child: _showWatermark 
               ? Center(child: Container(
                   padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                   decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.storefront, color: Colors.white, size: 10),
                       const SizedBox(width: 4),
                       Text("Rana Store", style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                       const SizedBox(width: 6),
                       Container(width: 1, height: 10, color: Colors.white38),
                       const SizedBox(width: 6),
                       const Icon(Icons.phone_android, color: Colors.white, size: 10),
                       const SizedBox(width: 3),
                       Text("0812-3456-7890", style: GoogleFonts.poppins(color: Colors.white, fontSize: 9)),
                     ],
                   ),
                 ))
               : const SizedBox(),
            ),
          ],
        ),
    );
  }

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
          "Mood Booster Hari Ini 💡\n\n\"Belanja Senang, Hati Tenang\"\n\nYuk lengkapi harimu dengan $name, cuma $price.\n\n#RanaStore #HappyShopping #Quotes",
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

  Future<void> _shareContent() async {
      // For both poster and video mode, we capture as image and share directly
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isVideoMode ? 'Membuat gambar animasi...' : 'Sedang membuat poster...')));
      
      try {
        final directory = (await getApplicationDocumentsDirectory()).path;
        String fileName = "Rana_Poster_${DateTime.now().millisecondsSinceEpoch}.png";
        String path = '$directory/$fileName';
        
        await _screenshotController.captureAndSave(
           directory, 
           fileName: fileName,
           pixelRatio: 2.0 // High Quality
        );

        File imgFile = File(path);
        if (await imgFile.exists()) {
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
  }

  // [NEW] API CALL - Updated to support custom price
  Future<void> _applyDiscountToStore() async {
      if (_selectedProduct == null) return;
      
      final productId = _selectedProduct!['id'];
      final newPriceText = _newPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (newPriceText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Masukkan harga baru terlebih dahulu'), backgroundColor: Colors.orange)
          );
          return;
      }
      
      final newPrice = double.tryParse(newPriceText);
      if (newPrice == null || newPrice <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Harga tidak valid'), backgroundColor: Colors.red)
          );
          return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menerapkan harga ${_selectedTemplate}...'))
      );

      try {
          // Get Token
          final token = Provider.of<AuthProvider>(context, listen: false).token;
          if (token == null) throw Exception("Not Authenticated");
          
          // Calculate promo end date
          final durationDays = int.tryParse(_durationController.text) ?? 7;
          final promoEndsAt = DateTime.now().add(Duration(days: durationDays));

          // Direct Dio Call
          final dio = Dio();
          final url = '${AppConstants.baseUrl}/api/products/$productId/apply-discount'; 
          
          await dio.post(
              url, 
              data: {
                  "newPrice": newPrice,
                  "promoType": _selectedTemplate == 'Flash Sale' ? 'flashsale' : 'discount',
                  "label": _captionController.text.split('\\n').first,
                  "durationDays": durationDays
              },
              options: Options(
                  headers: {
                      "Authorization": "Bearer $token"
                  }
              )
          );
          
          // [FIX] Also update local SQLite database
          final currentProduct = _selectedProduct!;
          final originalPrice = currentProduct['originalPrice'] ?? currentProduct['sellingPrice'];
          
          await DatabaseHelper.instance.updateProductDetails(productId, {
              'sellingPrice': newPrice,
              'originalPrice': originalPrice,
              'promoEndsAt': promoEndsAt.toIso8601String(),
          });
          
          // Reload products to show updated price
          await _loadProducts();
          _newPriceController.clear();
          
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('✅ Sukses! Harga ${_selectedTemplate} telah diterapkan.'),
                      backgroundColor: Colors.green,
                  )
              );
          }
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
          }
      }
  }
}
