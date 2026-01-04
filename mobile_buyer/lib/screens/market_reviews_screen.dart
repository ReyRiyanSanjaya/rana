import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/config/theme_config.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/reviews_provider.dart';


class MarketReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const MarketReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<MarketReviewsScreen> createState() => _MarketReviewsScreenState();
}

class _MarketReviewsScreenState extends State<MarketReviewsScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  String _formatRelTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m yang lalu';
    if (diff.inHours < 24) return '${diff.inHours}j yang lalu';
    if (diff.inDays < 7) return '${diff.inDays}h yang lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewsProvider>(context, listen: false)
          .loadInitial(widget.productId, sort: 'newest');
    });
  }

  void _onScroll() {
    final rev = Provider.of<ReviewsProvider>(context, listen: false);
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (rev.hasMore(widget.productId) && !rev.isLoading(widget.productId)) {
        rev.loadMore(widget.productId);
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ulasan ${widget.productName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<ReviewsProvider>(
        builder: (context, rev, _) {
          final list = rev.getReviews(widget.productId);
          final loading = rev.isLoading(widget.productId);

          if (list.isEmpty && !loading) {
            return const Center(child: Text('Belum ada ulasan'));
          }

          return Column(
            children: [
              // Filter Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    const Text('Urutkan:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: rev.sortFor(widget.productId),
                      isDense: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Terbaru')),
                        DropdownMenuItem(
                            value: 'rating_desc',
                            child: Text('Terbanyak Bintang')),
                        DropdownMenuItem(
                            value: 'rating_asc',
                            child: Text('Terendah Bintang')),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        rev.loadInitial(widget.productId, sort: val);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length + (loading ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    if (index >= list.length) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final r = list[index];
                    return _buildReviewItem(r);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> r) {
    final date = DateTime.tryParse(r['createdAt'] ?? '') ?? DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: r['user']?['imageUrl'] != null
                  ? NetworkImage(MarketApiService()
                      .resolveFileUrl(r['user']['imageUrl']))
                  : null,
              child: r['user']?['imageUrl'] == null
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['userName'] ?? r['user']?['name'] ?? 'Pengguna',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatRelTime(date),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 14,
                  color: i < (r['rating'] ?? 0)
                      ? ThemeConfig.colorRating
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
        if (r['comment'] != null && r['comment'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 44),
            child: Text(
              r['comment'],
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
      ],
    );
  }
}
