import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/screens/blog_detail_screen.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final posts = await _api.getBlogPosts();
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Blog & Berita',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: const Color(0xFFE07A5F))),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE07A5F)))
          : _posts.isEmpty
              ? Center(
                  child: Text('Belum ada berita',
                      style: GoogleFonts.poppins(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _buildBlogCard(post, index);
                  },
                ),
    );
  }

  Widget _buildBlogCard(Map<String, dynamic> post, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => BlogDetailScreen(post: post))),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8))
            ]),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (post['imageUrl'] != null && post['imageUrl'] != '')
                    Image.network(post['imageUrl'], fit: BoxFit.cover)
                  else
                    Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.article,
                            size: 64, color: Color(0xFFCBD5E1))),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        post['tags']?.isNotEmpty == true
                            ? post['tags'][0].toUpperCase()
                            : 'NEWS',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE07A5F)),
                      ),
                    ),
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['title'] ?? 'No Title',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                        height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      post['summary'] ??
                          (post['content'] ?? '')
                                  .replaceAll(RegExp(r'<[^>]*>'), '')
                                  .substring(0, 80) +
                              '...',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(post['readTime'] ?? '3 min read',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('Baca Selengkapnya',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE07A5F))),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: Color(0xFFE07A5F))
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
  }
}
