import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:assignment/my_recipe_page.dart';
import 'package:assignment/recipe_detail_page.dart';

class Meal {
  final String id;
  final String name;
  final String thumb;
  final String category;
  final String area;
  final List<String> tags;
  Meal({
    required this.id,
    required this.name,
    required this.thumb,
    required this.category,
    required this.area,
    required this.tags,
  });
  factory Meal.fromJson(Map<String, dynamic> j) {
    final rawTags = (j['strTags'] as String?)?.trim();
    return Meal(
      id: j['idMeal'] ?? '',
      name: j['strMeal'] ?? '',
      thumb: j['strMealThumb'] ?? '',
      category: j['strCategory'] ?? '',
      area: j['strArea'] ?? '',
      tags: rawTags == null || rawTags.isEmpty
          ? const []
          : rawTags.split(',').map((s) => '#${s.trim()}').toList(),
    );
  }
}

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});
  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30.0),
    borderSide: const BorderSide(color: Color(0xFF187C5C), width: 1.5),
  );

  List<Meal> _meals = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  bool _randomMode = true;

  @override
  void initState() {
    super.initState();
    _fetchRandomMeals(10);
    _scroll.addListener(_onScroll);
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _clearSearch() async {
    _search.clear();
    await _fetchRandomMeals(10, append: false);
  }

  Future<void> _fetchRandomMeals(int n, {bool append = true}) async {
    if (_loading || _loadingMore) return;
    setState(() {
      if (append) {
        _loadingMore = true;
      } else {
        _loading = true;
      }
      _error = null;
      _randomMode = true;
    });
    try {
      final futures = List.generate(
          n, (_) => http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php')));
      final responses = await Future.wait(futures);
      final items = <Meal>[];
      for (final r in responses) {
        if (r.statusCode == 200) {
          final m = jsonDecode(r.body) as Map<String, dynamic>;
          final list = (m['meals'] as List?) ?? [];
          if (list.isNotEmpty) items.add(Meal.fromJson(list.first));
        }
      }
      final seen = <String>{};
      final next = <Meal>[
        ...(append ? _meals : const <Meal>[]),
        ...items,
      ].where((m) => seen.add(m.id)).toList();

      setState(() => _meals = next);
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        if (!append) _meals = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _searchMeals(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return _fetchRandomMeals(10, append: false);
    }
    setState(() {
      _loading = true;
      _error = null;
      _randomMode = false;
    });
    try {
      final uri = Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeQueryComponent(q)}');
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (json['meals'] as List?) ?? [];
      final meals = list.map((e) => Meal.fromJson(e)).toList().cast<Meal>();
      setState(() => _meals = meals);
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _meals = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch() => _searchMeals(_search.text);

  void _onScroll() {
    if (!_randomMode) return;
    if (_loadingMore || _loading) return;
    if (!_scroll.hasClients) return;

    final pos = _scroll.position;
    final threshold = 480.0;
    if (pos.pixels + threshold >= pos.maxScrollExtent) {
      _fetchRandomMeals(6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/title.png', height: 80, width: 200),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF187C5C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _search,
                onSubmitted: (_) => _onSearch(),
                decoration: InputDecoration(
                  hintText: 'Type Recipe Name',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF525252)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  border: outline,
                  enabledBorder: outline,
                  focusedBorder: outline,
                  suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_search.text.isNotEmpty)
                        IconButton(
                          onPressed: _clearSearch,
                          padding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          constraints: const BoxConstraints(),
                          icon: SvgPicture.asset(
                            'assets/icons/x_circle_g.svg',
                            width: 18, height: 18,
                            colorFilter: const ColorFilter.mode(Color(0xFF187C5C), BlendMode.srcIn),
                          ),
                        ),
                      IconButton(
                        tooltip: 'Search',
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.search, color: Color(0xFF187C5C)),
                        onPressed: _onSearch,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              CustomPaint(
                painter: DashedLinePainter(),
                child: const SizedBox(width: double.infinity, height: 1),
              ),
              const SizedBox(height: 15),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              Expanded(
                child: Stack(
                  children: [
                    GridView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 7,
                        mainAxisSpacing: 7,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: _meals.length,
                      itemBuilder: (_, i) {
                        final m = _meals[i];
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailPage(apiMealId: m.id),
                              ),
                            );
                          },
                          child: _buildRecipeCard(
                            m.thumb,
                            m.name,
                            m.category,
                            m.tags.isEmpty ? ['#${m.area}'] : m.tags,
                          ),
                        );
                      },
                    ),
                    if (_loading && _meals.isEmpty)
                      const Center(child: CircularProgressIndicator()),
                    if (_loadingMore)
                      const Positioned(
                        left: 0, right: 0, bottom: 8,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
      String imageUrl,
      String foodName,
      String category,
      List<String> tags,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF187C5C), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.expand(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                    loadingBuilder: (c, w, p) =>
                    p == null ? w : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    foodName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF187C5C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                      style: GoogleFonts.jomhuria(
                        fontSize: 17,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
