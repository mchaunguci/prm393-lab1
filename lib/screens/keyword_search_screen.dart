import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/providers/keyword_search_provider.dart';
import 'package:shopee_app/widgets/keyword_results_table.dart';
import 'package:shopee_app/widgets/stat_card.dart';

class KeywordSearchScreen extends StatefulWidget {
  const KeywordSearchScreen({super.key});

  @override
  State<KeywordSearchScreen> createState() => _KeywordSearchScreenState();
}

class _KeywordSearchScreenState extends State<KeywordSearchScreen> {
  final _controller = TextEditingController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(KeywordSearchProvider provider) async {
    setState(() => _currentPage = 0);
    await provider.search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KeywordSearchProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              const SizedBox(height: 16),
              _buildSourceToggle(provider),
              const SizedBox(height: 16),
              _buildSearchBar(provider),
              const SizedBox(height: 20),
              if (provider.isSearching)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.accent),
                        SizedBox(height: 16),
                        Text(
                          'Đang crawl Shopee qua Python API...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!provider.hasSearched)
                const Expanded(child: _EmptyPrompt())
              else if (provider.error != null)
                Expanded(child: _SearchError(message: provider.error!))
              else if (provider.resultCount == 0)
                Expanded(child: _NoResults(keyword: provider.keyword))
              else ...[
                _buildStats(provider),
                const SizedBox(height: 20),
                Expanded(
                  child: KeywordResultsTable(
                    products: provider.results,
                    shopNameFor: provider.shopNameFor,
                    currentPage: _currentPage,
                    rowsPerPage: 15,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(KeywordSearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phân tích theo Keyword',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          provider.source == KeywordSearchSource.liveApi
              ? 'Crawl Shopee live qua Python API (port 8765) + cookies.txt'
              : 'Lọc sản phẩm đã có trong Firestore',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSourceToggle(KeywordSearchProvider provider) {
    return Row(
      children: [
        SegmentedButton<KeywordSearchSource>(
          segments: const [
            ButtonSegment(
              value: KeywordSearchSource.liveApi,
              label: Text('Crawl Python'),
              icon: Icon(Icons.cloud_download_outlined, size: 16),
            ),
            ButtonSegment(
              value: KeywordSearchSource.firestore,
              label: Text('Firestore'),
              icon: Icon(Icons.storage_outlined, size: 16),
            ),
          ],
          selected: {provider.source},
          onSelectionChanged: (values) {
            provider.setSource(values.first);
            setState(() => _currentPage = 0);
          },
        ),
        const SizedBox(width: 16),
        _ApiStatusBadge(online: provider.apiOnline),
        IconButton(
          tooltip: 'Kiểm tra lại API',
          onPressed: provider.refreshApiStatus,
          icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSearchBar(KeywordSearchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !provider.isSearching,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Nhập keyword, vd: rtx5090, rtx 4090, gpu...',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _runSearch(provider),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: provider.isSearching
                ? null
                : () {
                    _controller.clear();
                    provider.clear();
                    setState(() => _currentPage = 0);
                  },
            child: const Text('Xóa', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: provider.isSearching ? null : () => _runSearch(provider),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text('Phân tích'),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(KeywordSearchProvider provider) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'SẢN PHẨM',
            value: Formatters.number(provider.resultCount),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'SỐ SHOP',
            value: Formatters.number(provider.shopCount),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'GIÁ TB',
            value: Formatters.priceFull(provider.avgPrice),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'ĐÁNH GIÁ TB',
            value: provider.avgRating.toStringAsFixed(1),
            subtitle: '/ 5.0',
            icon: Icons.star,
          ),
        ),
      ],
    );
  }
}

class _ApiStatusBadge extends StatelessWidget {
  final bool online;

  const _ApiStatusBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (online ? AppColors.green : AppColors.textSecondary)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: online ? AppColors.green : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'API online' : 'API offline',
            style: TextStyle(
              color: online ? AppColors.green : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.manage_search,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nhập keyword và bấm Phân tích',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chế độ Crawl Python: chạy ./start_api.sh trong shopee-db/scripts',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  final String message;

  const _SearchError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chạy API:\n'
              'cd shopee-db/scripts\n'
              './start_api.sh',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String keyword;

  const _NoResults({required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy sản phẩm cho "$keyword"',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
