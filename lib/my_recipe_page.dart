import 'package:assignment/recipe_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:assignment/models/recipe.dart';

import 'db/isar_service.dart';
import 'dart:async';

class MyRecipePage extends StatefulWidget {
  const MyRecipePage({super.key});
  @override
  State<MyRecipePage> createState() => _MyRecipePageState();
}

class _MyRecipePageState extends State<MyRecipePage> {
  StreamSubscription<void>? _recipeSub;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30.0),
    borderSide: const BorderSide(color: Color(0xFF187C5C), width: 1.5),
  );

  bool _showTagPanel = false;
  final Set<String> _selectedTags = {};
  final List<String> _allTags = const [
    'SOUP','NOODLE','RICE','DESSERT','LUNCH BOX','KIDS',
    'SPICY','VEGETARIAN','SIDE','PASTRY','SEAFOOD','MEAT','OTHER',
  ];

  List<Recipe> _recipes = [];
  bool _loading = true;
  bool _hasAny = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
    _initIsarWatch();
  }

  @override
  void dispose() {
    _recipeSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initIsarWatch() async {
    final isar = await IsarService.db;
    _recipeSub = isar.recipes.watchLazy().listen((_) {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = await IsarService.db;
    final totalCount = await isar.recipes.count();
    final service = IsarService();
    final list = _query.isEmpty
        ? await service.getByTags(_selectedTags)
        : await service.searchByNamePrefix(_query, _selectedTags);
    if (!mounted) return;
    setState(() {
      _hasAny = totalCount > 0;
      _recipes = list;
      _loading = false;
    });
  }

  Future<void> _applySearch(String raw) async {
    _query = raw.trim();
    await _load();
  }

  Future<void> _clearSearch() async {
    _searchCtrl.clear();
    _query = '';
    await _load();
  }

  Future<void> _toggleTag(String label) async {
    final limitReached = _selectedTags.length >= 2;
    final isSelected = _selectedTags.contains(label);
    if (isSelected) {
      _selectedTags.remove(label);
    } else {
      if (limitReached) return;
      _selectedTags.add(label);
    }
    await _load();
  }

  void _openDetail(Recipe r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailPage(recipeId: r.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
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
              if (_hasAny) ...[
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: _applySearch,
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
                        if (_searchCtrl.text.isNotEmpty)
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
                          onPressed: () => _applySearch(_searchCtrl.text),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '# Tag',
                          style: GoogleFonts.jomhuria(
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF187C5C),
                            height: 1.0,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showTagPanel = !_showTagPanel),
                        child: AnimatedRotation(
                          turns: _showTagPanel ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: SvgPicture.asset(
                            'assets/icons/expand_circle_g.svg',
                            width: 23,
                            height: 23,
                            colorFilter: const ColorFilter.mode(Color(0xFF187C5C), BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) {
                    return SizeTransition(
                      axis: Axis.vertical,
                      sizeFactor: anim,
                      child: FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                    );
                  },
                  child: _showTagPanel
                      ? Padding(
                    key: const ValueKey('panel'),
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 16),
                    child: _buildTagPanel(),
                  )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
                      SizedBox(height: _showTagPanel ? 8 : 10),
                      CustomPaint(painter: DashedLinePainter(), child: const SizedBox(height: 1, width: double.infinity)),
                      const SizedBox(height: 10),
              ],
              Expanded(
                child: _recipes.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, i) {
                    final recipe = _recipes[i];
                    if ((recipe.imagePath ?? '').isEmpty) {
                      return GestureDetector(
                        onTap: () => _openDetail(recipe),
                        child: _buildRecipeItem(recipe.recipeName, recipe.tags),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () => _openDetail(recipe),
                        child: _buildRecipeItemWithImage(
                          recipe.imagePath!, recipe.recipeName, recipe.tags,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagPanel() {
    final limitReached = _selectedTags.length >= 2;

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: _allTags.map((label) {
        final isSelected = _selectedTags.contains(label);
        final canSelectMore = isSelected || !limitReached;

        return GestureDetector(
          onTap: () => _toggleTag(label),
          child: _buildTag(
            label,
            selected: isSelected,
            disabled: !canSelectMore,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTag(String label, {bool selected = false, bool disabled = false}) {
    final borderColor = selected
        ? const Color(0xFF187C5C)
        : (disabled ? const Color(0xFF187C5C).withOpacity(0.4) : const Color(0xFF187C5C));
    final bgColor = selected
        ? const Color(0xFF187C5C)
        : (disabled ? Colors.white.withOpacity(0.7) : Colors.white);
    final textColor = selected
        ? Colors.white
        : (disabled ? const Color(0xFF187C5C).withOpacity(0.5) : const Color(0xFF187C5C));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        label,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0, leading: 0),
        style: GoogleFonts.jomhuria(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.0,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildRecipeItem(String name, List<String> tags) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF187C5C), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600,)
          ),
          Row(
            children: tags
                .map((tag) => _buildTag(tag, selected: true))
                .expand((w) => [w, const SizedBox(width: 4)])
                .toList()
              ..removeLast(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeItemWithImage(String imagePath, String name, List<String> tags) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF187C5C), width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(imagePath),
              width: 130, height: 70, fit: BoxFit.cover,),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(name, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600,)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 8,
                  children: tags.map((tag) => _buildTag(tag, selected: true)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Try to add\nyour own recipe!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.black),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF187C5C)..strokeWidth = 2;
    double x = 0;
    const dash = 9.0, gap = 6.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
