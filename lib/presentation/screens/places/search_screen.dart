import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/data/models/place.dart';
import '../../../core/data/repositories/place_repository.dart';
import '../../state/ride_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repo = MockPlaceRepository();

  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<Place> _all = [];
  List<Place> _filtered = [];
  final List<String> _recent = [];

  bool _loading = true;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_onType);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.getAll();
      if (!mounted) return;
      setState(() {
        _all = data;
        _filtered = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _all = [];
        _filtered = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load places')),
      );
    }
  }

  void _onType() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      final q = _controller.text.trim();
      setState(() {
        _query = q;
        if (q.isEmpty) {
          _filtered = _all;
        } else {
          final lq = q.toLowerCase();
          _filtered = _all.where((p) =>
              p.name.toLowerCase().contains(lq) ||
              p.address.toLowerCase().contains(lq)).toList();
        }
      });
    });
  }

  void _pick(Place p) {
    if (p.name.isNotEmpty) {
      _recent.removeWhere((e) => e.toLowerCase() == p.name.toLowerCase());
      _recent.insert(0, p.name);
      if (_recent.length > 6) _recent.removeLast();
    }
    context.read<RideState>().setDestination(p);
    Navigator.pushReplacementNamed(context, Routes.home);
  }

  @override
  Widget build(BuildContext context) {
   // final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        centerTitle: false,
        elevation: 0,
      ),

      body: Column(
        children: [
          // Body search bar (prominent)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: _BodySearchField(
              controller: _controller,
              focusNode: _focus,
              hint: 'Where to?',
              onClear: () {
                _controller.clear();
                _onType();
                _focus.requestFocus();
              },
              onSubmit: (_) {
                if (_filtered.isNotEmpty) _pick(_filtered.first);
              },
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const _LoadingList()
                : (_query.isEmpty
                    ? _RecentAndSuggestions(
                        recent: _recent,
                        all: _all,
                        onTapRecent: (text) {
                          _controller.text = text;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: _controller.text.length),
                          );
                          _onType();
                        },
                        onTapPlace: _pick,
                      )
                    : _ResultsList(
                        items: _filtered,
                        query: _query,
                        onTap: _pick,
                      )),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_added_outlined),
              label: const Text('Saved places'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushNamed(context, Routes.savedPlaces),
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================= PARTS ========================= */

class _BodySearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmit;

  const _BodySearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onClear,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.outlineVariant.withValues(alpha: .6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              ),
              onSubmitted: onSubmit,
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => (value.text.isEmpty)
                ? const SizedBox(width: 4)
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onClear,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentAndSuggestions extends StatelessWidget {
  final List<String> recent;
  final List<Place> all;
  final void Function(String) onTapRecent;
  final void Function(Place) onTapPlace;

  const _RecentAndSuggestions({
    required this.recent,
    required this.all,
    required this.onTapRecent,
    required this.onTapPlace,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final top = all.take(6).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Recent', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          ...recent.take(6).map(
            (e) => ListTile(
              dense: true,
              leading: const Icon(Icons.history_rounded),
              title: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => onTapRecent(e),
            ),
          ),
          const SizedBox(height: 10),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('Popular nearby', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
        ...top.map((p) => _PlaceTile(place: p, query: '', onTap: () => onTapPlace(p))),
      ],
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<Place> items;
  final String query;
  final void Function(Place) onTap;

  const _ResultsList({
    required this.items,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        children: [
          const Icon(Icons.search_off_rounded, size: 64),
          const SizedBox(height: 12),
          Text('No results', textAlign: TextAlign.center, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Try a full address or different name.', textAlign: TextAlign.center),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final p = items[i];
        return _PlaceTile(place: p, query: query, onTap: () => onTap(p));
      },
    );
    }
}

class _PlaceTile extends StatelessWidget {
  final Place place;
  final String query;
  final VoidCallback onTap;

  const _PlaceTile({
    required this.place,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // leading
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.place_outlined, color: c.primary),
              ),
              const SizedBox(width: 12),

              // texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlight(place.name, query, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    _highlight(
                      place.address,
                      query,
                      style: t.bodySmall?.copyWith(color: t.bodySmall?.color?.withValues(alpha:.8)),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    // simple skeleton placeholders
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 8,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(bottom: i == 7 ? 0 : 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Color(0x11000000), shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Container(height: 14, decoration: BoxDecoration(color: const Color(0x11000000), borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(height: 12, decoration: BoxDecoration(color: const Color(0x11000000), borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ========================= UTILS ========================= */

Widget _highlight(String text, String query, {TextStyle? style, int maxLines = 1}) {
  if (query.isEmpty) {
    return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
  final lt = text.toLowerCase();
  final lq = query.toLowerCase();
  final i = lt.indexOf(lq);
  if (i < 0) {
    return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
  final before = text.substring(0, i);
  final match = text.substring(i, i + query.length);
  final after = text.substring(i + query.length);
  final bold = (style ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900);
  return Text.rich(
    TextSpan(children: [
      TextSpan(text: before, style: style),
      TextSpan(text: match, style: bold),
      TextSpan(text: after, style: style),
    ]),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}
