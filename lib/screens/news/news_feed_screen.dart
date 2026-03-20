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
import '../../l10n/app_localizations.dart';

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
  int likes, views;
  bool liked;

  NewsPost({required this.id, required this.title, required this.category,
    required this.content, required this.mediaFiles, required this.author,
    required this.likes, required this.views, required this.publishedAt, required this.liked});

  factory NewsPost.fromJson(Map<String, dynamic> j) {
    final rawMedia = j['media_files'] as List? ?? [];
    return NewsPost(
      id: j['id'], title: j['title'] ?? '', category: j['category'] ?? 'General News',
      content: j['content'] ?? '', mediaFiles: rawMedia.map((e) => NewsMedia.fromJson(e)).toList(),
      author: j['author'] ?? 'HCR Admin', likes: j['likes'] ?? 0, views: j['views'] ?? 0,
      publishedAt: j['published_at'] ?? '', liked: j['liked'] ?? false,
    );
  }
}

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});
  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  List<NewsPost> _posts     = [];
  bool           _isLoading = true;
  bool           _isOffline = false;
  String?        _selectedValue;
  Timer?         _timer;

  final List<String?> _filterValues = [null, 'General News', 'Safety Tips'];

  String _filterLabel(String? value, AppLocalizations tr) {
    switch (value) {
      case null: return tr.get('all'); case 'General News': return tr.get('news');
      case 'Safety Tips': return tr.get('safety_tips'); default: return value!;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadPosts());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    // 1. Load from cache immediately
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

    // 2. Fetch fresh in background
    try {
      final response = await ApiService.getWithAuth('/news').timeout(const Duration(seconds: 15));
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
      debugPrint('NEWS ERROR: $e');
      if (mounted) setState(() => _isOffline = _posts.isNotEmpty);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<NewsPost> get _filtered {
    if (_selectedValue == null) return _posts;
    return _posts.where((p) => p.category == _selectedValue).toList();
  }

  Future<void> _likePost(NewsPost post) async {
    setState(() { post.liked = !post.liked; post.likes += post.liked ? 1 : -1; });
    try {
      final token = await ApiService.getToken();
      final resp  = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/news/${post.id}/like'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() { post.liked = data['liked'] as bool; post.likes = data['likes'] as int; });
      } else {
        setState(() { post.liked = !post.liked; post.likes += post.liked ? 1 : -1; });
      }
    } catch (e) {
      setState(() { post.liked = !post.liked; post.likes += post.liked ? 1 : -1; });
    }
  }

  Future<void> _openDetail(NewsPost post, AppLocalizations tr) async {
    final langCode = Provider.of<LanguageProvider>(context, listen: false).tr.languageCode;
    final t        = Provider.of<ThemeProvider>(context, listen: false).theme;
    await Navigator.push(context, MaterialPageRoute(
        builder: (_) => NewsDetailScreen(post: post, onLike: () => _likePost(post),
            languageCode: langCode, theme: t)));
    try {
      final token = await ApiService.getToken();
      final resp  = await http.get(Uri.parse('${ApiConstants.baseUrl}/news/${post.id}'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body);
        setState(() { post.views = data['views'] as int; post.liked = data['liked'] as bool; post.likes = data['likes'] as int; });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;
    final t  = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: Column(children: [
        // Filter tabs
        Container(
          color: t.appBarColor,
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _filterValues.map((value) {
              final sel = _selectedValue == value;
              final unselectedBg = t.isNight ? Colors.white.withOpacity(0.12) : t.scaffoldBg;
              final unselectedText = t.isNight ? Colors.white : t.primaryText;
              return GestureDetector(
                onTap: () => setState(() => _selectedValue = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? t.navSelectedColor : unselectedBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(_filterLabel(value, tr),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: sel ? t.appBarColor : unselectedText)),
                ),
              );
            }).toList(),
          ),
        ),

        // Offline banner
        if (_isOffline) _offlineBanner(tr),

        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: t.buttonColor))
              : _filtered.isEmpty
                  ? _emptyState(tr, t)
                  : RefreshIndicator(
                      onRefresh: _loadPosts, color: t.buttonColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i], tr, t),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _offlineBanner(AppLocalizations tr) => Container(
    color: const Color(0xFFD97706),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
      const SizedBox(width: 8),
      Text(tr.get('offline_cached_data'),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      const Spacer(),
      GestureDetector(
        onTap: _loadPosts,
        child: Text(tr.get('retry'),
            style: const TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
      ),
    ]),
  );

  Widget _buildCard(NewsPost post, AppLocalizations tr, AppTheme t) {
    final isSafety  = post.category == 'Safety Tips';
    final accent    = t.isNight
        ? const Color(0xFFD5C38B)
        : (isSafety ? Colors.green.shade700 : t.buttonColor);
    final badgeAccent = isSafety
        ? (t.isNight ? const Color(0xFFD5C38B) : Colors.green.shade700)
        : (t.isNight ? const Color(0xFFD5C38B) : t.buttonColor);
    final images    = post.mediaFiles.where((m) => m.type == 'image').toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.cardColor, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: badgeAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isSafety ? Icons.shield_outlined : Icons.newspaper, size: 12, color: badgeAccent),
                const SizedBox(width: 4),
                Text(isSafety ? tr.get('safety_tip').toUpperCase() : tr.get('news').toUpperCase(),
                    style: TextStyle(fontSize: 11, color: badgeAccent, fontWeight: FontWeight.w800)),
              ]),
            ),
            const Spacer(),
            Text(post.publishedAt, style: TextStyle(fontSize: 12, color: t.secondaryText)),
          ]),
        ),

        if (images.isNotEmpty) _buildCollage(images, t),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
            const SizedBox(height: 6),
            Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: t.secondaryText, height: 1.5)),
          ]),
        ),

        _buildFooter(post, accent, badgeAccent, tr, t),
      ]),
    );
  }

  Widget _buildCollage(List<NewsMedia> images, AppTheme t) {
    final count = images.length;
    if (count == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(images, 0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 160, maxHeight: 280),
          child: Image.network(images[0].url, width: double.infinity, fit: BoxFit.cover,
            loadingBuilder: (_, child, p) => p == null ? child :
                Container(height: 220, color: t.scaffoldBg,
                    child: Center(child: CircularProgressIndicator(color: t.buttonColor))),
            errorBuilder: (_, __, ___) => Container(height: 180, color: t.scaffoldBg)),
        ),
      );
    }
    if (count == 2) return SizedBox(height: 200, child: Row(children: [
      Expanded(child: _imgCell(images[0], 0, images)), const SizedBox(width: 2),
      Expanded(child: _imgCell(images[1], 1, images)),
    ]));
    if (count == 3) return Column(children: [
      SizedBox(height: 180, width: double.infinity, child: _imgCell(images[0], 0, images)),
      const SizedBox(height: 2),
      SizedBox(height: 120, child: Row(children: [
        Expanded(child: _imgCell(images[1], 1, images)), const SizedBox(width: 2),
        Expanded(child: _imgCell(images[2], 2, images)),
      ])),
    ]);
    if (count == 4) return Column(children: [
      SizedBox(height: 150, child: Row(children: [
        Expanded(child: _imgCell(images[0], 0, images)), const SizedBox(width: 2),
        Expanded(child: _imgCell(images[1], 1, images)),
      ])),
      const SizedBox(height: 2),
      SizedBox(height: 150, child: Row(children: [
        Expanded(child: _imgCell(images[2], 2, images)), const SizedBox(width: 2),
        Expanded(child: _imgCell(images[3], 3, images)),
      ])),
    ]);
    return Column(children: [
      SizedBox(height: 180, child: Row(children: [
        Expanded(flex: 2, child: _imgCell(images[0], 0, images)), const SizedBox(width: 2),
        Expanded(child: Column(children: [
          Expanded(child: _imgCell(images[1], 1, images)), const SizedBox(height: 2),
          Expanded(child: _imgCell(images[2], 2, images)),
        ])),
      ])),
      const SizedBox(height: 2),
      SizedBox(height: 120, child: Row(children: [
        Expanded(child: _imgCell(images[3], 3, images)), const SizedBox(width: 2),
        Expanded(child: GestureDetector(
          onTap: () => _openImageViewer(images, 4),
          child: Stack(fit: StackFit.expand, children: [
            _netImg(images[4].url),
            if (count > 5) Container(color: Colors.black54,
                child: Center(child: Text('+${count - 5}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))),
          ]),
        )),
      ])),
    ]);
  }

  Widget _imgCell(NewsMedia m, int i, List<NewsMedia> all) =>
      GestureDetector(onTap: () => _openImageViewer(all, i), child: SizedBox.expand(child: _netImg(m.url)));

  Widget _netImg(String url) => Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD6E4F0),
          child: const Icon(Icons.image, color: Color(0xFF4A6A8A), size: 32)));

  Widget _buildFooter(NewsPost post, Color accent, Color badgeAccent, AppLocalizations tr, AppTheme t) {
    final likedColor = t.isNight ? const Color(0xFFD5C38B) : accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(children: [
        GestureDetector(
          onTap: () => _likePost(post),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: post.liked ? likedColor.withOpacity(0.15) : t.scaffoldBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: post.liked ? likedColor : t.dividerColor),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                child: Icon(post.liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    key: ValueKey(post.liked), size: 15,
                    color: post.liked ? likedColor : t.secondaryText)),
              const SizedBox(width: 5),
              Text(post.likes > 0 ? '${post.likes}' : tr.get('like'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: post.liked ? likedColor : t.secondaryText)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.remove_red_eye_outlined, size: 15, color: t.secondaryText),
        const SizedBox(width: 4),
        Text('${post.views}', style: TextStyle(fontSize: 13, color: t.secondaryText)),
        const Spacer(),
        GestureDetector(
          onTap: () => _openDetail(post, tr),
          child: Text(tr.get('read_details'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: t.isNight ? const Color(0xFFD5C38B) : accent)),
        ),
      ]),
    );
  }

  void _openImageViewer(List<NewsMedia> images, int start) =>
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => _ImageViewerScreen(images: images, initialIndex: start)));

  Widget _emptyState(AppLocalizations tr, AppTheme t) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.newspaper, size: 64, color: t.secondaryText),
      const SizedBox(height: 14),
      Text(tr.get('no_news'), style: TextStyle(color: t.secondaryText, fontSize: 15)),
      TextButton(onPressed: _loadPosts,
          child: Text(tr.get('refresh'), style: TextStyle(color: t.buttonColor))),
    ]),
  );
}

class _ImageViewerScreen extends StatefulWidget {
  final List<NewsMedia> images;
  final int initialIndex;
  const _ImageViewerScreen({required this.images, required this.initialIndex});
  @override
  State<_ImageViewerScreen> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewerScreen> {
  late PageController _ctrl;
  late int _cur;
  @override
  void initState() { super.initState(); _cur = widget.initialIndex; _ctrl = PageController(initialPage: widget.initialIndex); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0,
        title: widget.images.length > 1 ? Text('${_cur + 1} / ${widget.images.length}',
            style: const TextStyle(fontSize: 15)) : null),
    body: PageView.builder(controller: _ctrl, itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _cur = i),
        itemBuilder: (_, i) => InteractiveViewer(minScale: 0.5, maxScale: 4.0,
            child: Center(child: Image.network(widget.images[i].url, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 60))))),
  );
}

class NewsDetailScreen extends StatefulWidget {
  final NewsPost post;
  final VoidCallback onLike;
  final String languageCode;
  final AppTheme theme;
  const NewsDetailScreen({super.key, required this.post, required this.onLike,
      required this.languageCode, required this.theme});
  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late bool _liked;
  late int  _likes, _views;

  AppLocalizations get tr => AppLocalizations(widget.languageCode);
  AppTheme         get t  => widget.theme;

  @override
  void initState() { super.initState(); _liked = widget.post.liked; _likes = widget.post.likes; _views = widget.post.views; }

  void _handleLike() {
    setState(() { _liked = !_liked; _likes += _liked ? 1 : -1; widget.post.liked = _liked; widget.post.likes = _likes; });
    widget.onLike();
  }

  @override
  void didUpdateWidget(NewsDetailScreen old) {
    super.didUpdateWidget(old);
    setState(() { _liked = widget.post.liked; _likes = widget.post.likes; });
  }

  Color get _accent => t.isNight
      ? const Color(0xFFD5C38B)
      : (widget.post.category == 'Safety Tips' ? Colors.green.shade700 : t.buttonColor);

  String _translateCategory(String cat) {
    switch (cat) {
      case 'General News': return tr.get('news'); case 'Safety Tips': return tr.get('safety_tips'); default: return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post   = widget.post;
    final images = post.mediaFiles.where((m) => m.type == 'image').toList();

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor, foregroundColor: t.appBarFg,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, size: 18, color: t.appBarFg), onPressed: () => Navigator.pop(context)),
        title: Text(tr.get('post_details'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.appBarFg)),
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (images.length == 1)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => _ImageViewerScreen(images: images, initialIndex: 0))),
              child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 200, maxHeight: 340),
                  child: Image.network(images[0].url, width: double.infinity, fit: BoxFit.cover)),
            )
          else if (images.length > 1)
            SizedBox(height: 280, child: _DetailImageGallery(images: images)),

          Container(
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(_translateCategory(post.category),
                        style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Text(post.publishedAt, style: TextStyle(fontSize: 12, color: t.secondaryText)),
                ]),
                const SizedBox(height: 14),
                Text(post.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText, height: 1.3)),
                const SizedBox(height: 8),
                Row(children: [
                  CircleAvatar(radius: 12, backgroundColor: t.scaffoldBg,
                      child: Icon(Icons.person, size: 14, color: t.iconColor)),
                  const SizedBox(width: 6),
                  Text(post.author, style: TextStyle(fontSize: 13, color: t.secondaryText, fontWeight: FontWeight.w600)),
                ]),
                Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: t.dividerColor)),
                Text(post.content, style: TextStyle(fontSize: 15, color: t.primaryText, height: 1.8)),
                Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: t.dividerColor)),
                Row(children: [
                  GestureDetector(
                    onTap: _handleLike,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: _liked ? _accent.withOpacity(0.15) : t.scaffoldBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _liked ? _accent : t.dividerColor),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                          child: Icon(_liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                              key: ValueKey(_liked), size: 17,
                              color: _liked ? _accent : t.secondaryText)),
                        const SizedBox(width: 6),
                        Text(_likes > 0 ? '$_likes ${tr.get(_likes == 1 ? 'like' : 'likes')}' : tr.get('like'),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                color: _liked ? _accent : t.secondaryText)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.remove_red_eye_outlined, size: 17, color: t.secondaryText),
                  const SizedBox(width: 4),
                  Text('$_views ${tr.get('views')}', style: TextStyle(fontSize: 13, color: t.secondaryText)),
                ]),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DetailImageGallery extends StatefulWidget {
  final List<NewsMedia> images;
  const _DetailImageGallery({required this.images});
  @override
  State<_DetailImageGallery> createState() => _DetailImageGalleryState();
}

class _DetailImageGalleryState extends State<_DetailImageGallery> {
  int _cur = 0;
  @override
  Widget build(BuildContext context) => Stack(children: [
    PageView.builder(itemCount: widget.images.length, onPageChanged: (i) => setState(() => _cur = i),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => _ImageViewerScreen(images: widget.images, initialIndex: i))),
          child: Image.network(widget.images[i].url, fit: BoxFit.cover, width: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD6E4F0))),
        )),
    if (widget.images.length > 1)
      Positioned(bottom: 10, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _cur == i ? 20 : 7, height: 7,
            decoration: BoxDecoration(
              color: _cur == i ? Colors.white : Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(4),
            ),
          ))),
      ),
  ]);
}