import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../search/categories.dart';
import '../search/location_link.dart';
import '../search/place.dart';
import '../search/recent_searches.dart';
import '../search/search_format.dart';
import '../search/search_service.dart';

/// شاشة البحث: تصنيفات حولك + آخر عمليات البحث + نتائج فورية أثناء الكتابة.
/// ترجع المكان المختار للشاشة الرئيسية.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.service,
    required this.recent,
    required this.nearLat,
    required this.nearLon,
    this.hint,
  });

  /// نص إرشادي بديل (مثل: «ابحث عن مكان البيت»).
  final String? hint;

  final SearchService service;
  final RecentSearches recent;
  final double nearLat;
  final double nearLon;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;

  List<Place> _recent = const [];
  List<Place>? _results; // null = لم نبحث بعد
  bool _loading = false;
  bool _error = false;
  String? _notice; // رسالة خاصة (مثل: رابط مختصر في المتصفح)

  @override
  void initState() {
    super.initState();
    widget.recent.load().then((r) {
      if (mounted) setState(() => _recent = r);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _results = null;
        _loading = false;
        _error = false;
        _notice = null;
      });
      return;
    }
    // الروابط والإحداثيات تُفهم فوراً بدون انتظار.
    final direct = LocationLink.parse(text);
    if (direct != null) {
      _debounce?.cancel();
      _requestId++;
      setState(() {
        _results = [direct];
        _loading = false;
        _error = false;
        _notice = null;
      });
      return;
    }
    if (LocationLink.isShortLink(text)) {
      _debounce?.cancel();
      _resolveShort(text);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(text));
  }

  Future<void> _resolveShort(String text) async {
    final id = ++_requestId;
    final t = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = false;
      _notice = null;
      _results = null;
    });
    Place? place;
    try {
      place = await LocationLink.resolveShortLink(text);
    } catch (_) {
      place = null;
    }
    if (!mounted || id != _requestId) return;
    setState(() {
      _loading = false;
      if (place != null) {
        _results = [place];
      } else {
        _notice = kIsWeb ? t.shortLinkWeb : t.linkNotFound;
      }
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _onChanged(text);
  }

  Future<void> _run(String text, {PlaceCategory? category}) async {
    final id = ++_requestId;
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = category != null
          ? await widget.service.nearby(category,
              nearLat: widget.nearLat, nearLon: widget.nearLon)
          : await widget.service.search(text,
              languageCode: lang,
              nearLat: widget.nearLat,
              nearLon: widget.nearLon);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
        _notice = null;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _openCategory(PlaceCategory c) {
    final t = AppLocalizations.of(context);
    _controller.text = categoryLabel(t, c);
    _debounce?.cancel();
    _run(_controller.text, category: c);
  }

  Future<void> _choose(Place place) async {
    await widget.recent.add(place);
    if (mounted) Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: t.back,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const BackButtonIcon(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                      onSubmitted: (v) {
                        _debounce?.cancel();
                        if (v.trim().isNotEmpty) _run(v);
                      },
                      decoration: InputDecoration(
                        hintText: widget.hint ?? t.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, _) => _controller.text.isEmpty
                              ? IconButton(
                                  tooltip: t.paste,
                                  icon: const Icon(Icons.content_paste),
                                  onPressed: _paste,
                                )
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _controller.clear();
                                    _onChanged('');
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _body(t)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations t) {
    final notice = _notice;
    if (notice != null) {
      return _Message(icon: Icons.link_off, text: notice);
    }
    if (_error) {
      return _Message(icon: Icons.cloud_off, text: t.searchError);
    }
    final results = _results;
    if (results != null) {
      if (results.isEmpty && !_loading) {
        return _Message(icon: Icons.search_off, text: t.noResults);
      }
      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, i) => _PlaceTile(
          place: results[i],
          nearLat: widget.nearLat,
          nearLon: widget.nearLon,
          onTap: () => _choose(results[i]),
        ),
      );
    }
    // قبل الكتابة: التصنيفات وآخر عمليات البحث.
    return ListView(
      children: [
        _SectionTitle(t.nearbyTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in PlaceCategory.values)
                ActionChip(
                  avatar: Icon(c.icon, size: 18),
                  label: Text(categoryLabel(t, c)),
                  onPressed: () => _openCategory(c),
                ),
            ],
          ),
        ),
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SectionTitle(t.recentTitle)),
              TextButton(
                onPressed: () async {
                  await widget.recent.clear();
                  if (mounted) setState(() => _recent = const []);
                },
                child: Text(t.clearRecent),
              ),
              const SizedBox(width: 8),
            ],
          ),
          for (final p in _recent)
            _PlaceTile(
              place: p,
              nearLat: widget.nearLat,
              nearLon: widget.nearLon,
              leadingIcon: Icons.history,
              onTap: () => _choose(p),
            ),
        ],
      ],
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.nearLat,
    required this.nearLon,
    required this.onTap,
    this.leadingIcon,
  });

  final Place place;
  final double nearLat;
  final double nearLon;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListTile(
      onTap: onTap,
      leading: PlaceIcon(
        icon: leadingIcon ?? PlaceCategory.iconFor(place.osmKey, place.osmValue),
      ),
      title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: place.subtitle.isEmpty
          ? null
          : Text(place.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatDistance(t, nearLat, nearLon, place.lat, place.lon),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
