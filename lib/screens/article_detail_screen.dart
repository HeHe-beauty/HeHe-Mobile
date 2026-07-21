import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/article/article_repository.dart';
import '../dtos/common/article/article_detail_dto.dart';
import '../theme/app_palette.dart';
import '../widgets/article/article_content_renderer.dart';

typedef ArticleDetailLoader = Future<ArticleDetailDto> Function(int articleId);

class ArticleDetailScreen extends StatefulWidget {
  final int? articleId;
  final ArticleDetailDto? initialArticle;
  final ArticleDetailLoader loader;

  const ArticleDetailScreen({
    super.key,
    required int this.articleId,
    this.loader = ArticleRepository.getArticleDetail,
  }) : initialArticle = null;

  const ArticleDetailScreen.data({super.key, required ArticleDetailDto article})
    : articleId = null,
      initialArticle = article,
      loader = ArticleRepository.getArticleDetail;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Future<ArticleDetailDto> _articleFuture;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  void _loadArticle() {
    _articleFuture = widget.initialArticle != null
        ? Future.value(widget.initialArticle!)
        : widget.loader(widget.articleId!);
  }

  void _retry() {
    setState(_loadArticle);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ArticleAppBar(
              onBack: () => Navigator.maybePop(context),
              onShare: _copyArticleTitle,
            ),
            Expanded(
              child: widget.initialArticle != null
                  ? _ArticleBody(article: widget.initialArticle!)
                  : FutureBuilder<ArticleDetailDto>(
                      future: _articleFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return _LoadingState(color: palette.primary);
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return _ErrorState(onRetry: _retry);
                        }
                        return _ArticleBody(article: snapshot.data!);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyArticleTitle() async {
    try {
      final article = await _articleFuture;
      await Clipboard.setData(ClipboardData(text: article.title));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('콘텐츠 제목을 복사했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // The error state already provides retry feedback.
    }
  }
}

class _ArticleAppBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onShare;

  const _ArticleAppBar({required this.onBack, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          _SoftIconButton(
            tooltip: '뒤로',
            icon: Icons.chevron_left_rounded,
            onTap: onBack,
          ),
          const Spacer(),
          _SoftIconButton(
            tooltip: '공유',
            icon: Icons.ios_share_rounded,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _SoftIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.surface,
        shape: CircleBorder(side: BorderSide(color: palette.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: palette.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  final ArticleDetailDto article;

  const _ArticleBody({required this.article});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tags = article.tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.28,
              letterSpacing: 0,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ArticleTagBadges(tags: tags),
          ],
          const SizedBox(height: 20),
          _HeroImage(url: article.thumbnailUrl),
          const SizedBox(height: 20),
          ArticleContentRenderer(content: article.content),
        ],
      ),
    );
  }
}

class _ArticleTagBadges extends StatelessWidget {
  final List<String> tags;

  const _ArticleTagBadges({required this.tags});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags)
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.primaryStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? url;

  const _HeroImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final validUrl = url?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.82,
        child: validUrl == null || validUrl.isEmpty
            ? const _ImagePlaceholder()
            : Image.network(
                validUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const _ImagePlaceholder(showProgress: true),
                errorBuilder: (_, _, _) => const _ImagePlaceholder(),
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool showProgress;

  const _ImagePlaceholder({this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ColoredBox(
      color: palette.surfaceSoft,
      child: Center(
        child: showProgress
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.primary,
                ),
              )
            : Icon(Icons.image_outlined, color: palette.textTertiary, size: 34),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final Color color;

  const _LoadingState({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 25,
        height: 25,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 34,
              color: palette.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              '콘텐츠를 불러오지 못했어요.',
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
