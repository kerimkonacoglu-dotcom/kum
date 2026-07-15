import 'package:flutter/material.dart';
import '../services/enigma_service.dart';
import '../services/favorites_store.dart';

/// Buketleri ve kanalları listeler; dokununca o kanala geçer. Favori desteği var.
class ChannelsView extends StatefulWidget {
  final EnigmaService service;
  final VoidCallback? onZap;
  const ChannelsView({super.key, required this.service, this.onZap});

  @override
  State<ChannelsView> createState() => _ChannelsViewState();
}

class _ChannelsViewState extends State<ChannelsView> {
  final _favStore = FavoritesStore();
  Map<String, String> _favorites = {};
  List<ServiceRef> _bouquets = [];
  ServiceRef? _selected;
  bool _showFavorites = false;
  List<ServiceRef> _channels = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _favorites = await _favStore.load();
    await _loadBouquets();
  }

  Future<void> _loadBouquets() async {
    setState(() => _loading = true);
    try {
      final b = await widget.service.bouquets();
      setState(() => _bouquets = b);
      if (b.isNotEmpty) {
        await _selectBouquet(b.first);
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectBouquet(ServiceRef b) async {
    setState(() {
      _selected = b;
      _showFavorites = false;
      _loading = true;
    });
    try {
      final ch = await widget.service.channels(b.reference);
      setState(() => _channels = ch);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _zap(ServiceRef c) async {
    try {
      await widget.service.zap(c.reference);
      widget.onZap?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${c.name} kanalına geçildi'),
            duration: const Duration(seconds: 1)));
      }
    } catch (_) {}
  }

  Future<void> _toggleFav(ServiceRef c) async {
    final m = await _favStore.toggle(c.reference, c.name);
    setState(() => _favorites = m);
  }

  @override
  Widget build(BuildContext context) {
    final List<ServiceRef> source = _showFavorites
        ? _favorites.entries
            .map((e) => ServiceRef(reference: e.key, name: e.value))
            .toList()
        : _channels;
    final filtered = _search.isEmpty
        ? source
        : source
            .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              ChoiceChip(
                label: const Text('★ Favoriler'),
                selected: _showFavorites,
                onSelected: (_) => setState(() => _showFavorites = true),
                selectedColor: const Color(0xFFE57A29),
              ),
              const SizedBox(width: 8),
              for (final b in _bouquets) ...[
                ChoiceChip(
                  label: Text(b.name),
                  selected: !_showFavorites &&
                      b.reference == _selected?.reference,
                  onSelected: (_) => _selectBouquet(b),
                  selectedColor: const Color(0xFF2E7BE5),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Kanal ara...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                          _showFavorites
                              ? 'Henüz favori yok'
                              : 'Kanal bulunamadı',
                          style: const TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final fav = _favorites.containsKey(c.reference);
                        return ListTile(
                          dense: true,
                          leading: Text('${i + 1}',
                              style: const TextStyle(color: Colors.white38)),
                          title: Text(c.name),
                          trailing: IconButton(
                            icon: Icon(
                              fav ? Icons.star : Icons.star_border,
                              color: fav ? const Color(0xFFE57A29) : null,
                              size: 20,
                            ),
                            onPressed: () => _toggleFav(c),
                          ),
                          onTap: () => _zap(c),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
