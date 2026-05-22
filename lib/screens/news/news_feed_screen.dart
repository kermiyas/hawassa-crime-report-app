// lib/screens/news/news_feed_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';    // ← new
import '../../widgets/auth_gate.dart';           // ← new
import '../../l10n/app_localizations.dart';
import '../../providers/badge_provider.dart';

class NewsMedia {
  final String url, type;
  NewsMedia({required this.url, required this.type});
  factory NewsMedia.fromJson(Map<String, dynamic> j) =>
      NewsMedia(url: j['url'] ?? '', type: j['type'] ?? 'image');
}

class NewsPost {
  final int id;
  final String title, category, content, author, publishedAt;
  final List<NewsMedia> mediaFiles;
  int  likes, views;
  bool liked;

  NewsPost({
    required this.id, required this.title, required this.category,
    required this.content, required this.mediaFiles, required this.author,
    required this.likes, required this.views,
    required this.publishedAt, required this.liked,
  });

  factory NewsPost.fromJson(Map<String, dynamic> j) {
    final rawMedia = j['media_files'] as List? ?? [];
    return NewsPost(
      id: j['id'], title: j['title'] ?? '',
      category: j['category'] ?? 'General News',
      content: j['content'] ?? '',
      mediaFiles: rawMedia.map((e) => NewsMedia.fromJson(e)).toList(),
      author: j['author'] ?? 'HCR Admin',
      likes: j['likes'] ?? 0, views: j['views'] ?? 0,
      publishedAt: j['published_at'] ?? '',
      liked: j['liked'] ?? false,
    );
  }
}

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});
  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  List<NewsPost> _posts      = [];
  bool           _isLoading  = true;
  bool           _isOffline  = false;
  bool           _isRefreshing = false;
  String?        _selectedValue;
  Timer?         _timer;

  // ── Colors ────────────────────────────────────────────────────────────────
  static const Color _navy     = Color(0xFF1A3A5C);
  static const Color _navyDark = Color(0xFF0D1B2A);
  static const Color _gold     = Color(0xFFC9A84C);
  static const Color _white    = Color(0xFFFFFFFF);

  final List<String?> _filterValues = [null, 'General News', 'Safety Tips'];

  String _filterLabel(String? value) {
    switch (value) {
      case null:           return 'All';
      case 'General News': return 'News';
      case 'Safety Tips':  return 'Safety Tips';
      default:             return value!;
    }
  }

  Color _filterColor(String? value) {
    switch (value) {
      case 'General News': return const Color(0xFF1976D2);
      case 'Safety Tips':  return const Color(0xFF059669);
      default:             return _gold;
    }
  }

  IconData _filterIcon(String? value) {
    switch (value) {
      case 'General News': return Icons.newspaper_rounded;
      case 'Safety Tips':  return Icons.shield_outlined;
      default:             return Icons.dynamic_feed_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => _loadPosts());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (mounted) setState(() => _isLoading = true);
    final cached = await CacheService.load('news_feed');
    if (cached != null) {
      try {
        final data = jsonDecode(cached);
        final list = data['posts'] as List;
        if (mounted) setState(() {
          _posts     = list.map((e) => NewsPost.fromJson(e)).toList();
          _isLoading = false;
        });
      } catch (_) {}
    }

    try {
      final response = await ApiService.getWithAuth('/news')
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        await CacheService.save('news_feed', response.body);
        final data = jsonDecode(response.body);
        final list = data['posts'] as List;
        if (mounted) setState(() {
          _posts     = list.map((e) => NewsPost.fromJson(e)).toList();
          _isOffline = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isOffline = _posts.isNotEmpty);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<NewsPost> get _filtered {
    if (_selectedValue == null) return _posts;
    return _posts.where((p) => p.category == _selectedValue).toList();
  }

  // ── Like — gated for guests ───────────────────────────────────────────────
  Future<void> _likePost(NewsPost post) async {
    // Block guests before doing anything
    if (!AuthGate.require(context, featureName: 'like posts')) return;

    setState(() {
      post.liked  = !post.liked;
      post.likes += post.liked ? 1 : -1;
    });
    try {
      final token = await ApiService.getToken();
      final resp  = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/news/${post.id}/like'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          post.liked = data['liked'] as bool;
          post.likes = data['likes'] as int;
        });
      } else {
        setState(() {
          post.liked  = !post.liked;
          post.likes += post.liked ? 1 : -1;
        });
      }
    } catch (_) {
      setState(() {
        post.liked  = !post.liked;
        post.likes += post.liked ? 1 : -1;
      });
    }
  }

  Future<void> _openDetail(NewsPost post) async {
  context.read<BadgeProvider>().markNewsSeen();
    final langCode = Provider.of<LanguageProvider>(
        context, listen: false).tr.languageCode;
    final t = Provider.of<ThemeProvider>(
        context, listen: false).theme;
    final auth = Provider.of<AuthProvider>(
        context, listen: false);          // ← pass auth down

    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => NewsDetailScreen(
        post: post,
        onLike: () => _likePost(post),
        languageCode: langCode,
        theme: t,
        isGuest: auth.isGuest,            // ← new param
      )));

    try {
      final token = await ApiService.getToken();
      final resp  = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/news/${post.id}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body);
        setState(() {
          post.views = data['views'] as int;
          post.liked = data['liked'] as bool;
          post.likes = data['likes'] as int;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: t.isNight
          ? const Color(0xFF112D4E)
          : const Color(0xFFF0F4F8),
      body: Column(children: [

        // ── Filter tabs ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.isNight
                  ? [const Color(0xFF1A2F4A), const Color(0xFF0D1B2A)]
                  : [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: Row(children: [
            ..._filterValues.map((value) {
              final sel  = _selectedValue == value;
              final fClr = _filterColor(value);
              return GestureDetector(
                onTap: () => setState(() => _selectedValue = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? _gold
                        : _white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? _gold
                          : _white.withOpacity(0.2),
                      width: 1.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_filterIcon(value),
                        size: 13,
                        color: sel
                            ? _navyDark
                            : _white.withOpacity(0.7)),
                    const SizedBox(width: 5),
                    Text(_filterLabel(value),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? _navyDark
                                : _white.withOpacity(0.7))),
                  ]),
                ),
              );
            }),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                setState(() => _isRefreshing = true);
                await _loadPosts();
                if (mounted) setState(() => _isRefreshing = false);
              },
              child: AnimatedRotation(
                turns: _isRefreshing ? 1 : 0,
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _isRefreshing
                        ? _gold.withOpacity(0.3)
                        : _white.withOpacity(0.1),
                    shape: BoxShape.circle),
                  child: Icon(Icons.refresh_rounded,
                    color: _isRefreshing ? _gold : _white,
                    size: 16)),
              ),
            ),
          ]),
        ),

        // ── Offline banner ──────────────────────────────────────────────
        if (_isOffline) _buildOfflineBanner(),

        

        // ── Feed list ────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(
                  color: t.isNight ? _gold : _navy))
              : _filtered.isEmpty
                  ? _buildEmpty(t)
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      color: t.isNight ? _gold : _navy,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) =>
                            _buildCard(_filtered[i], t),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildOfflineBanner() => Container(
    color: const Color(0xFFD97706),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: _white, size: 14),
      const SizedBox(width: 8),
      const Expanded(child: Text('Showing cached content',
          style: TextStyle(
              color: _white,
              fontSize: 12,
              fontWeight: FontWeight.w600))),
      GestureDetector(
        onTap: _loadPosts,
        child: const Text('Retry',
            style: TextStyle(
                color: _white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline))),
    ]),
  );

  Widget _buildCard(NewsPost post, AppTheme t) {
    final isSafety  = post.category == 'Safety Tips';
    final catColor  = isSafety
        ? const Color(0xFF059669)
        : const Color(0xFF1976D2);
    final images    = post.mediaFiles
        .where((m) => m.type == 'image').toList();
    final cardBg    = t.isNight ? const Color(0xFF1A3A5C) : _white;
    final textColor = t.isNight ? _white.withOpacity(0.9) : _navy;
    final subColor  = t.isNight
        ? _white.withOpacity(0.45)
        : _navy.withOpacity(0.5);
    final likeColor = t.isNight ? _gold : _navy;

    // Check guest state for like icon hint
    final isGuest = context.read<AuthProvider>().isGuest;

    return GestureDetector(
      onTap: () => _openDetail(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                  t.isNight ? 0.2 : 0.07),
              blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Media ───────────────────────────────────────────────────
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: _buildCollage(images, t),
              ),

            // ── Category badge + time ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: catColor.withOpacity(0.25),
                        width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSafety
                            ? Icons.shield_outlined
                            : Icons.newspaper_rounded,
                        size: 12, color: catColor),
                      const SizedBox(width: 5),
                      Text(
                        isSafety ? 'SAFETY TIP' : 'NEWS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: catColor,
                          letterSpacing: 0.5)),
                    ]),
                ),
                const Spacer(),
                Icon(Icons.access_time_rounded,
                    size: 12, color: subColor),
                const SizedBox(width: 4),
                Text(post.publishedAt,
                    style: TextStyle(fontSize: 11, color: subColor)),
              ]),
            ),

            // ── Title ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(post.title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.3)),
            ),

            const SizedBox(height: 6),

            // ── Content preview ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, color: subColor, height: 1.5)),
            ),

            const SizedBox(height: 14),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: t.isNight
                        ? _white.withOpacity(0.08)
                        : const Color(0xFFDDE6F0),
                    width: 1))),
              child: Row(children: [
                // Author
               // Like button — LEFT, stops tap propagation
GestureDetector(
  onTap: () => _likePost(post),
  behavior: HitTestBehavior.opaque,
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(
      post.liked
          ? Icons.thumb_up_rounded
          : Icons.thumb_up_outlined,
      size: 18,
      color: post.liked ? likeColor : subColor),
    if (post.likes > 0) ...[
      const SizedBox(width: 4),
      Text('${post.likes}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: post.liked ? likeColor : subColor)),
    ],
  ]),
),

const SizedBox(width: 12),

// Views
Row(children: [
  Icon(Icons.remove_red_eye_outlined, size: 14, color: subColor),
  const SizedBox(width: 4),
  Text('${post.views}',
      style: TextStyle(fontSize: 12, color: subColor)),
]),

const Spacer(),

// Author
Container(
  width: 26, height: 26,
  decoration: BoxDecoration(
    color: (t.isNight ? _gold : _navy).withOpacity(0.1),
    shape: BoxShape.circle),
  child: Icon(Icons.person_rounded,
    size: 14,
    color: t.isNight ? _gold : _navy.withOpacity(0.6)),
),
const SizedBox(width: 6),
Text(post.author,
  style: TextStyle(
    fontSize: 12, color: subColor,
    fontWeight: FontWeight.w500),
  overflow: TextOverflow.ellipsis),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollage(List<NewsMedia> images, AppTheme t) {
    final count = images.length;
    if (count == 1) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
            minHeight: 180, maxHeight: 260),
        child: _netImg(images[0].url),
      );
    }
    if (count == 2) {
      return SizedBox(height: 200,
        child: Row(children: [
          Expanded(child: _imgCell(images[0], 0, images)),
          const SizedBox(width: 2),
          Expanded(child: _imgCell(images[1], 1, images)),
        ]));
    }
    if (count == 3) {
      return Column(children: [
        SizedBox(height: 180, width: double.infinity,
          child: _imgCell(images[0], 0, images)),
        const SizedBox(height: 2),
        SizedBox(height: 120,
          child: Row(children: [
            Expanded(child: _imgCell(images[1], 1, images)),
            const SizedBox(width: 2),
            Expanded(child: _imgCell(images[2], 2, images)),
          ])),
      ]);
    }
    return Column(children: [
      SizedBox(height: 160,
        child: Row(children: [
          Expanded(child: _imgCell(images[0], 0, images)),
          const SizedBox(width: 2),
          Expanded(child: _imgCell(images[1], 1, images)),
        ])),
      const SizedBox(height: 2),
      SizedBox(height: 120,
        child: Row(children: [
          Expanded(child: _imgCell(images[2], 2, images)),
          const SizedBox(width: 2),
          Expanded(child: GestureDetector(
            onTap: () => _openImageViewer(images, 3),
            child: Stack(fit: StackFit.expand, children: [
              _netImg(images[3].url),
              if (count > 4)
                Container(
                  color: Colors.black54,
                  child: Center(child: Text('+${count - 4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)))),
            ]),
          )),
        ])),
    ]);
  }

  Widget _imgCell(NewsMedia m, int i, List<NewsMedia> all) =>
    GestureDetector(
      onTap: () => _openImageViewer(all, i),
      child: SizedBox.expand(child: _netImg(m.url)));

  Widget _netImg(String url) => Image.network(url,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (_, __, ___) => Container(
      color: const Color(0xFFDDE6F0),
      child: const Icon(Icons.image_outlined,
          color: Color(0xFF1A3A5C), size: 32)));

  void _openImageViewer(List<NewsMedia> images, int start) =>
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ImageViewerScreen(
          images: images, initialIndex: start)));

  Widget _buildEmpty(AppTheme t) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: (t.isNight ? _gold : _navy).withOpacity(0.08),
            shape: BoxShape.circle),
          child: Icon(Icons.newspaper_rounded,
            size: 38,
            color: t.isNight
                ? _gold.withOpacity(0.5)
                : _navy.withOpacity(0.3))),
        const SizedBox(height: 16),
        Text('No Posts Yet',
          style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800,
            color: t.isNight ? _white : _navy)),
        const SizedBox(height: 8),
        Text('Check back later for news and safety tips',
          style: TextStyle(
            fontSize: 13,
            color: t.isNight
                ? _white.withOpacity(0.45)
                : _navy.withOpacity(0.5))),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _loadPosts,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: (t.isNight ? _gold : _navy).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Text('Refresh',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: t.isNight ? _gold : _navy))),
        ),
      ],
    ),
  );
}

// ── Image viewer ──────────────────────────────────────────────────────────────
class _ImageViewerScreen extends StatefulWidget {
  final List<NewsMedia> images;
  final int initialIndex;
  const _ImageViewerScreen({
      required this.images, required this.initialIndex});
  @override
  State<_ImageViewerScreen> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewerScreen> {
  late PageController _ctrl;
  late int _cur;
  @override
  void initState() {
    super.initState();
    _cur  = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      title: widget.images.length > 1
          ? Text('${_cur + 1} / ${widget.images.length}',
              style: const TextStyle(fontSize: 14))
          : null),
    body: PageView.builder(
      controller: _ctrl,
      itemCount: widget.images.length,
      onPageChanged: (i) => setState(() => _cur = i),
      itemBuilder: (_, i) => InteractiveViewer(
        minScale: 0.5, maxScale: 4.0,
        child: Center(child: Image.network(
          widget.images[i].url, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image, color: Colors.white54, size: 60))))),
  );
}

// ── News detail screen ────────────────────────────────────────────────────────
class NewsDetailScreen extends StatefulWidget {
  final NewsPost     post;
  final VoidCallback onLike;
  final String       languageCode;
  final AppTheme     theme;
  final bool         isGuest;        // ← new

  const NewsDetailScreen({
    super.key,
    required this.post,
    required this.onLike,
    required this.languageCode,
    required this.theme,
    required this.isGuest,           // ← new
  });
  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late bool _liked;
  late int  _likes, _views;

  AppLocalizations get tr => AppLocalizations(widget.languageCode);
  AppTheme         get t  => widget.theme;

  static const Color _navy     = Color(0xFF1A3A5C);
  static const Color _navyDark = Color(0xFF0D1B2A);
  static const Color _gold     = Color(0xFFC9A84C);
  static const Color _white    = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _liked = widget.post.liked;
    _likes = widget.post.likes;
    _views = widget.post.views;
  }

  void _handleLike() {
    // Gate guests — show sign-in sheet and bail out
    if (widget.isGuest) {
      AuthGate.require(context, featureName: 'like posts');
      return;
    }

    setState(() {
      _liked  = !_liked;
      _likes += _liked ? 1 : -1;
      widget.post.liked = _liked;
      widget.post.likes = _likes;
    });
    widget.onLike();
  }

  Color get _catColor => widget.post.category == 'Safety Tips'
      ? const Color(0xFF059669)
      : const Color(0xFF1976D2);

  Color get _accentColor => t.isNight ? _gold : _navy;

  @override
  Widget build(BuildContext context) {
    final post   = widget.post;
    final images = post.mediaFiles
        .where((m) => m.type == 'image').toList();
    final cardBg  = t.isNight ? const Color(0xFF1A3A5C) : _white;
    final textClr = t.isNight ? _white.withOpacity(0.9) : _navy;
    final subClr  = t.isNight
        ? _white.withOpacity(0.45)
        : _navy.withOpacity(0.5);

    return Scaffold(
      backgroundColor: t.isNight
          ? const Color(0xFF112D4E)
          : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: images.isNotEmpty ? 260 : 0,
            pinned: true,
            backgroundColor:
                t.isNight ? const Color(0xFF0F2440) : _navy,
            foregroundColor: _white,
            leading: IconButton(
              icon: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.15),
                  shape: BoxShape.circle),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _white, size: 16)),
              onPressed: () => Navigator.pop(context)),
            title: const Text('Police Feed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _white)),
            flexibleSpace: images.isNotEmpty
                ? FlexibleSpaceBar(
                    background:
                        _DetailImageGallery(images: images))
                : null,
          ),

          // ── Content ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + time
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _catColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _catColor.withOpacity(0.25))),
                      child: Row(children: [
                        Icon(
                          post.category == 'Safety Tips'
                              ? Icons.shield_outlined
                              : Icons.newspaper_rounded,
                          size: 13, color: _catColor),
                        const SizedBox(width: 5),
                        Text(
                          post.category == 'Safety Tips'
                              ? 'Safety Tip'
                              : 'News',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _catColor)),
                      ]),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded,
                        size: 12, color: subClr),
                    const SizedBox(width: 4),
                    Text(post.publishedAt,
                        style: TextStyle(
                            fontSize: 12, color: subClr)),
                  ]),

                  const SizedBox(height: 14),

                  // Title
                  Text(post.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textClr,
                      height: 1.3)),

                  const SizedBox(height: 10),

                  // Author
                  Row(children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        shape: BoxShape.circle),
                      child: Icon(Icons.person_rounded,
                        size: 16,
                        color: _accentColor.withOpacity(0.6))),
                    const SizedBox(width: 8),
                    Text(post.author,
                      style: TextStyle(
                        fontSize: 13,
                        color: subClr,
                        fontWeight: FontWeight.w500)),
                  ]),

                  const SizedBox(height: 16),

                  Divider(
                    color: t.isNight
                        ? _white.withOpacity(0.08)
                        : const Color(0xFFDDE6F0)),

                  const SizedBox(height: 16),

                  // Content
                  Text(post.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: textClr,
                      height: 1.8)),

                  const SizedBox(height: 24),

                  Divider(
                    color: t.isNight
                        ? _white.withOpacity(0.08)
                        : const Color(0xFFDDE6F0)),

                  const SizedBox(height: 16),

                  // ── Like + views row ────────────────────────────────
                  Row(children: [
                    GestureDetector(
                      onTap: _handleLike,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: (!widget.isGuest && _liked)
                              ? _accentColor.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (!widget.isGuest && _liked)
                                ? _accentColor.withOpacity(0.4)
                                : (t.isNight
                                    ? _white.withOpacity(0.15)
                                    : const Color(0xFFDDE6F0)),
                            width: 1.5)),
                        child: Row(children: [
                          Icon(
                            _liked
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_up_outlined,
                            size: 17,
                            color: _liked ? _accentColor : subClr),
                          const SizedBox(width: 8),
                          Text(
                            _likes > 0
                                ? '$_likes ${_likes == 1 ? 'Like' : 'Likes'}'
                                : 'Like',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _liked ? _accentColor : subClr)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.remove_red_eye_outlined,
                        size: 17, color: subClr),
                    const SizedBox(width: 5),
                    Text('$_views views',
                        style: TextStyle(
                            fontSize: 13, color: subClr)),
                  ]),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImageGallery extends StatefulWidget {
  final List<NewsMedia> images;
  const _DetailImageGallery({required this.images});
  @override
  State<_DetailImageGallery> createState() =>
      _DetailImageGalleryState();
}

class _DetailImageGalleryState extends State<_DetailImageGallery> {
  int _cur = 0;
  @override
  Widget build(BuildContext context) => Stack(children: [
    PageView.builder(
      itemCount: widget.images.length,
      onPageChanged: (i) => setState(() => _cur = i),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => _ImageViewerScreen(
            images: widget.images, initialIndex: i))),
        child: Image.network(widget.images[i].url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFFDDE6F0))))),
    if (widget.images.length > 1)
      Positioned(
        bottom: 12, left: 0, right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (i) =>
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _cur == i ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _cur == i
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4)))))),
  ]);
}