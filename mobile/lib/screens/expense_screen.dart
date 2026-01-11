import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? expenseToEdit;
  const ExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'EXPENSE_PETTY';
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _categories = {
    'EXPENSE_PETTY': {'label': 'Petty Cash (Harian)', 'icon': Icons.wallet},
    'EXPENSE_OPERATIONAL': {
      'label': 'Operasional (Listrik/Air)',
      'icon': Icons.bolt
    },
    'EXPENSE_PURCHASE': {'label': 'Pembelian Stok', 'icon': Icons.inventory_2},
    'EXPENSE_SALARY': {'label': 'Gaji Karyawan', 'icon': Icons.badge},
    'EXPENSE_MARKETING': {'label': 'Pemasaran/Iklan', 'icon': Icons.campaign},
    'EXPENSE_RENT': {'label': 'Sewa Tempat', 'icon': Icons.store},
    'EXPENSE_MAINTENANCE': {
      'label': 'Perbaikan & Perawatan',
      'icon': Icons.build
    },
    'EXPENSE_OTHER': {'label': 'Lain-lain', 'icon': Icons.more_horiz},
  };

  @override
  void initState() {
    super.initState();
    // Load existing expense data if editing
    if (widget.expenseToEdit != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final expense = widget.expenseToEdit!;

    // Load amount
    final amount = expense['amount'];
    if (amount != null) {
      _amountCtrl.text =
          amount is num ? amount.toStringAsFixed(0) : amount.toString();
    }

    // Load description
    final desc = expense['description'];
    if (desc != null) {
      _descCtrl.text = desc.toString();
    }

    // Load category
    final category = expense['category'];
    if (category != null && _categories.containsKey(category)) {
      _category = category.toString();
    }

    // Load date
    final dateStr = expense['date'];
    if (dateStr != null) {
      try {
        _selectedDate = DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Load image if exists
    final imagePath = expense['imagePath'];
    if (imagePath != null && imagePath is String) {
      final file = File(imagePath);
      if (file.existsSync()) {
        _selectedImage = file;
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _submitExpense() async {
    final rawAmount = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah yang valid')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? savedImagePath;
      if (_selectedImage != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'EXP_${DateTime.now().millisecondsSinceEpoch}${p.extension(_selectedImage!.path)}';
        final savedFile = File(p.join(appDir.path, 'expenses', fileName));
        await savedFile.parent.create(recursive: true);
        await _selectedImage!.copy(savedFile.path);
        savedImagePath = savedFile.path;
      }

      // Map invalid categories to valid schema enums
      String finalCategory = _category;
      String finalDesc = _descCtrl.text;

      // Mapping rules
      final Map<String, String> categoryMapping = {
        'EXPENSE_SALARY': 'EXPENSE_OPERATIONAL',
        'EXPENSE_MARKETING': 'EXPENSE_OPERATIONAL',
        'EXPENSE_RENT': 'EXPENSE_OPERATIONAL',
        'EXPENSE_MAINTENANCE': 'EXPENSE_OPERATIONAL',
        'EXPENSE_OTHER': 'OTHER',
      };

      if (categoryMapping.containsKey(_category)) {
        finalCategory = categoryMapping[_category]!;
        final originalLabel = _categories[_category]?['label'] ?? _category;
        finalDesc = '[$originalLabel] $finalDesc';
      }

      final expenseData = {
        'amount': amount,
        'category': finalCategory,
        'description': finalDesc,
        'date': _selectedDate.toIso8601String(),
        'synced': 0,
        'imagePath': savedImagePath,
      };

      if (widget.expenseToEdit != null) {
        await DatabaseHelper.instance.updateExpense(
          widget.expenseToEdit!['id'],
          expenseData,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran Berhasil Diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await DatabaseHelper.instance.insertExpense({
          ...expenseData,
          'storeId': 'store-1',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran Berhasil Disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Pilih Kategori',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: _categories.entries.map((e) {
                  final isSelected = _category == e.key;
                  return ListTile(
                    onTap: () {
                      setState(() => _category = e.key);
                      Navigator.pop(context);
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE07A5F)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        e.value['icon'] as IconData,
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      e.value['label'] as String,
                      style: GoogleFonts.outfit(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFFE07A5F)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFFE07A5F))
                        : null,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ambil Gambar',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFFE07A5F)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF334155),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCategorySelector() {
    final cat = _categories[_category]!;
    return ListTile(
      onTap: _showCategoryPicker,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(cat['icon'] as IconData, color: const Color(0xFFE07A5F)),
      ),
      title: Text(
        'Kategori',
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: const Color(0xFF64748B),
        ),
      ),
      subtitle: Text(
        cat['label'] as String,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      onTap: _pickDate,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE07A5F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.calendar_today, color: Color(0xFFE07A5F)),
      ),
      title: Text(
        'Tanggal',
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: const Color(0xFF64748B),
        ),
      ),
      subtitle: Text(
        DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate),
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
    );
  }

  Widget _buildAmountField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jumlah Pengeluaran',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE07A5F),
            ),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE07A5F),
              ),
              border: InputBorder.none,
              hintText: '0',
              hintStyle:
                  TextStyle(color: const Color(0xFFE07A5F).withOpacity(0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _descCtrl,
        maxLines: 3,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Catatan tambahan (opsional)...',
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 20, color: Color(0xFFE07A5F)),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 32, color: Color(0xFFE07A5F)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Bukti / Struk',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE07A5F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap untuk mengambil gambar',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(
          widget.expenseToEdit == null
              ? 'Catat Pengeluaran'
              : 'Edit Pengeluaran',
          style: GoogleFonts.outfit(
            color: const Color(0xFFE07A5F),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Detail Pengeluaran'),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildCategorySelector(),
                        const Divider(height: 1),
                        _buildDateSelector(),
                        const Divider(height: 1),
                        _buildAmountField(),
                        const Divider(height: 1),
                        _buildDescField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Bukti Pengeluaran'),
                  const SizedBox(height: 16),
                  _buildImagePicker(),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _submitExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE07A5F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            widget.expenseToEdit == null
                ? 'Simpan Pengeluaran'
                : 'Update Pengeluaran',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
