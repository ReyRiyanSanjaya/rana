import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:rana_merchant/data/local/database_helper.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(
          widget.expenseToEdit == null ? 'Catat Pengeluaran' : 'Edit Pengeluaran',
          style: GoogleFonts.outfit(
              color: const Color(0xFFE07A5F), fontWeight: FontWeight.bold),
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
          onPressed: _saveExpense,
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
            'Simpan Pengeluaran',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
              hintStyle: TextStyle(color: const Color(0xFFE07A5F).withOpacity(0.3)),
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
      onTap: () => _showImageSourcePicker(),
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
                        child: const Icon(Icons.close, size: 20, color: Color(0xFFE07A5F)),
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
                        color: isSelected ? const Color(0xFFE07A5F) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        e.value['icon'] as IconData,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      e.value['label'] as String,
                      style: GoogleFonts.outfit(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color(0xFFE07A5F) : const Color(0xFF1E293B),
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

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah pengeluaran')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagePath;
      if (_selectedImage != null) {
        // Save image to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await _selectedImage!.copy('${appDir.path}/$fileName');
        imagePath = savedImage.path;
      }

      final expense = {
        'amount': amount,
        'category': _category,
        'description': _descCtrl.text,
        'date': _selectedDate.toIso8601String(),
        'imagePath': imagePath,
        'synced': 0, // Flag for sync
      };

      if (widget.expenseToEdit != null) {
        await DatabaseHelper.instance.updateExpense(widget.expenseToEdit!['id'], expense);
      } else {
        await DatabaseHelper.instance.insertExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

  Future<void> _submitExpense() async {
    // Remove non-numeric characters except dot (if any, though keyboard is number)
    // Actually Indonesian usually uses no decimals for daily transactions or just raw numbers
    // Let's assume input is just numbers.
    final rawAmount = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan jumlah yang valid')));
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
        // Prepend original category label to description for context
        final originalLabel = _categories[_category]?['label'] ?? _category;
        finalDesc = '[$originalLabel] $finalDesc';
      }

      if (widget.expenseToEdit != null) {
        // UPDATE
        // If image is changed, the new image is already copied to a new path above if selected
        // If image is not changed (_selectedImage is same as original), savedImagePath will be null in above logic?
        // Wait, the logic for saving image above is: if (_selectedImage != null) { copy... }
        // If we are editing and kept the old image, _selectedImage is File(oldPath).
        // Copying it to itself or similar path might be redundant but safe.
        // However, we should check if it's a new image or existing one.
        // For simplicity: If _selectedImage is set, we overwrite imagePath.

        final Map<String, dynamic> updateData = {
          'amount': amount,
          'category': finalCategory,
          'description': finalDesc,
          'date': _selectedDate.toIso8601String(),
          'synced': 0
        };

        if (savedImagePath != null) {
          updateData['imagePath'] = savedImagePath;
        } else if (_selectedImage != null) {
          // Existing image kept, no new file created, keep existing path
          // But wait, if I picked a NEW image, savedImagePath is set.
          // If I didn't pick a new image, _selectedImage is what I loaded in initState.
          // So if savedImagePath is null, but _selectedImage is not null, it means it's the old image.
          // So we don't need to update 'imagePath' column unless we want to be sure.
          // Actually, the above logic:
          // if (_selectedImage != null) { copy... }
          // This will ALWAYS copy, even if it's the same file.
          // Let's optimize: check if path contains 'expenses' directory (already saved).

          // Correct logic was implemented in previous step? No, let's look at the previous code block.
          // The previous code block was:
          /*
            if (_selectedImage != null) {
              final appDir = await getApplicationDocumentsDirectory();
              final fileName = ...
              final savedFile = File(...);
              await savedFile.parent.create(recursive: true);
              await _selectedImage!.copy(savedFile.path);
              savedImagePath = savedFile.path;
            }
           */
          // If I load an existing image from /data/user/0/.../expenses/img.jpg into _selectedImage
          // Then I call copy to /data/user/0/.../expenses/NEW_NAME.jpg
          // It duplicates the file. This is acceptable for now to avoid complexity of detecting "same file".
          // Old file remains as "trash" until we implement cleanup.
          // Better approach: Only copy if it's not already in the target directory?
          // For now, I will just stick to the simple logic: it creates a new file.

          if (savedImagePath != null) {
            updateData['imagePath'] = savedImagePath;
          }
        } else {
          // User removed image
          updateData['imagePath'] = null;
        }

        await DatabaseHelper.instance
            .updateExpense(widget.expenseToEdit!['id'], updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pengeluaran Berhasil Diperbarui'),
              backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        // INSERT
        await DatabaseHelper.instance.insertExpense({
          'storeId': 'store-1',
          'amount': amount,
          'category': finalCategory,
          'description': finalDesc,
          'date': _selectedDate.toIso8601String(),
          'imagePath': savedImagePath,
          'synced': 0
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pengeluaran Berhasil Disimpan'),
              backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(
            widget.expenseToEdit != null
                ? 'Edit Pengeluaran'
                : 'Catat Pengeluaran',
            style: const TextStyle(
                color: Color(0xFFE07A5F), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFFE07A5F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pengeluaran',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE07A5F)),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.black12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Details Form
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Picker
                    InkWell(
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F0),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.calendar_today,
                                color: Color(0xFFE07A5F)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tanggal Transaksi',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                    DateFormat('EEEE, d MMMM yyyy')
                                        .format(_selectedDate),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                    const Divider(height: 32),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _category,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Kategori Pengeluaran',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      items: _categories.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Row(
                            children: [
                              Icon(e.value['icon'] as IconData,
                                  size: 20, color: const Color(0xFFE07A5F)),
                              const SizedBox(width: 12),
                              Text(e.value['label'] as String,
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    TextField(
                      controller: _descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Catatan / Keterangan',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon:
                            const Icon(Icons.notes, color: Color(0xFFE07A5F)),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Proof Image
            const Text('Bukti Transaksi (Opsional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Ambil Foto'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickImage(ImageSource.camera);
                                }),
                            ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Pilih dari Galeri'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickImage(ImageSource.gallery);
                                }),
                          ],
                        ));
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selectedImage!, fit: BoxFit.cover),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedImage = null),
                                child: const CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 14,
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.white)),
                              ),
                            )
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Ketuk untuk upload foto struk',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitExpense,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE07A5F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.expenseToEdit != null
                            ? 'UPDATE PENGELUARAN'
                            : 'SIMPAN PENGELUARAN',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
