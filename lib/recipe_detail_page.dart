import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:assignment/my_recipe_page.dart';
import 'add_recipe_page.dart';
import 'package:http/http.dart' as http;
import 'db/isar_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/recipe.dart';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({super.key, this.recipeId, this.apiMealId})
      : assert(recipeId != null || apiMealId != null);

  final int? recipeId;
  final String? apiMealId;
  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  bool _loading = true;
  Recipe? _recipe;

  String? _apiName, _apiThumb, _apiArea, _apiYoutube;
  List<String> _apiTags = [];
  String _apiIngredients = '-';
  List<String> _apiSteps = [];

  bool get _isApi => widget.apiMealId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isApi) {
      await _loadApi(widget.apiMealId!);
    } else {
      final isar = await IsarService.db;
      final content = await isar.recipes.get(widget.recipeId!);
      if (!mounted) return;
      setState(() {
        _recipe = content;
        _loading = false;
      });
    }
  }

  Future<void> _loadApi(String id) async {
    try {
      final uri = Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=$id');
      final res = await http.get(uri);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (json['meals'] as List?) ?? [];
      if (list.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final m = list.first as Map<String, dynamic>;

      _apiName     = (m['strMeal'] ?? '') as String;
      _apiThumb    = (m['strMealThumb'] ?? '') as String;
      _apiArea     = (m['strArea'] ?? '') as String;
      _apiYoutube  = (m['strYoutube'] ?? '') as String;

      final rawTags = (m['strTags'] as String?)?.trim();
      final tagsFromApi = (rawTags == null || rawTags.isEmpty)
          ? <String>[]
          : rawTags.split(',').map((s) => '#${s.trim()}').toList();

      final combined = <String>[];
      if ((_apiArea ?? '').isNotEmpty) combined.add('#${_apiArea!.trim()}');
      combined.addAll(tagsFromApi);
      _apiTags = combined.take(6).toList();

      final ing = <String>[];
      for (int i = 1; i <= 20; i++) {
        final ingName = (m['strIngredient$i'] as String?)?.trim();
        final measure = (m['strMeasure$i'] as String?)?.trim();
        if (ingName != null && ingName.isNotEmpty) {
          final txt = (measure != null && measure.isNotEmpty)
              ? '$ingName ($measure)'
              : ingName;
          ing.add(txt);
        }
      }
      _apiIngredients = ing.isEmpty ? '-' : ing.join(', ');

      final instr = (m['strInstructions'] as String?) ?? '';
      _apiSteps = instr
          .split(RegExp(r'(\r?\n)+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFEF0),
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: Color(0xFF187C5C))),
        ),
      );
    }

    if (!_isApi && _recipe == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFEF0),
        body: SafeArea(child: Center(child: Text('Recipe not found'))),
      );
    }

    final title = _isApi ? (_apiName ?? '-') : _recipe!.recipeName;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 25, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(24),
                      child: SvgPicture.asset(
                        'assets/icons/back_g.svg',
                        width: 34, height: 34,
                        colorFilter: const ColorFilter.mode(Color(0xFF187C5C), BlendMode.srcIn),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            textAlign: TextAlign.right,
                            strutStyle: const StrutStyle(forceStrutHeight: true, height: 2.2),
                            style: GoogleFonts.jomhuria(
                              fontSize: 55, fontWeight: FontWeight.w400,
                              color: const Color(0xFF187C5C), height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isApi && (_apiThumb ?? '').isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _apiThumb!, width: double.infinity, height: 180, fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (!_isApi && ((_recipe!.imagePath ?? '').isNotEmpty)) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_recipe!.imagePath!),
                          width: double.infinity, height: 180, fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingredients',
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false, applyHeightToLastDescent: false,
                          ),
                          style: GoogleFonts.jomhuria(
                            fontSize: 35, fontWeight: FontWeight.w400, color: const Color(0xFF187C5C),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            _isApi ? _apiIngredients : _formatIngredients(_recipe!.ingredients),
                            style: const TextStyle(fontSize: 15, color: Colors.black),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4, runSpacing: 8,
                            children: (_isApi ? _apiTags : _recipe!.tags.take(6).map((t)=>'#$t').toList())
                                .map((t) => _isApi ? _buildApiTag(t) : _buildTag(t, selected: true))
                                .toList(),
                          ),
                        ),
                        if (!_isApi)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => AddRecipePage(recipeIdToEdit: _recipe!.id),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: const Color(0xFF187C5C),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.jomhuria(
                                  fontSize: 30, fontWeight: FontWeight.w400, color: const Color(0xFF187C5C),
                                ),
                                children: [
                                  const TextSpan(text: 'EDIT'),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: SvgPicture.asset(
                                        'assets/icons/edit_g.svg', height: 20, width: 20,
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xFF187C5C), BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_isApi && (_apiYoutube ?? '').isNotEmpty) ...[
                      InkWell(
                        onTap: () => _openYoutube(_apiYoutube!),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 10, 15, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF187C5C),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SvgPicture.asset('assets/icons/video_w.svg', width: 20, height: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'YouTube Link',
                                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    CustomPaint(
                      painter: DashedLinePainter(),
                      child: const SizedBox(width: double.infinity, height: 1),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Instructions',
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false, applyHeightToLastDescent: false,
                            ),
                            style: GoogleFonts.jomhuria(
                              fontSize: 45, fontWeight: FontWeight.w400, color: const Color(0xFF187C5C),
                            ),
                          ),
                        ),
                        if (!_isApi)
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: _confirmDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: SvgPicture.asset(
                              'assets/icons/trash_g.svg',
                              width: 22, height: 22,
                              colorFilter: const ColorFilter.mode(Color(0xFF187C5C), BlendMode.srcIn),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _isApi
                          ? _buildStepsAligned(_apiSteps)
                          : _buildStepsAligned(_recipe!.steps),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openYoutube(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildApiTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF187C5C), width: 1.5),
      ),
      child: Text(
        label,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false, applyHeightToLastDescent: false,
        ),
        strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0, leading: 0),
        style: GoogleFonts.jomhuria(
          fontSize: 18, fontWeight: FontWeight.w400,
          color: const Color(0xFF187C5C), height: 1.0, letterSpacing: 0.3,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
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

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this recipe?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteRecipe();
    }
  }

  Future<void> _deleteRecipe() async {
    if (_isApi || _recipe == null) return;
    final isar = await IsarService.db;
    await isar.writeTxn(() async {
      await isar.recipes.delete(_recipe!.id);
    });
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
  }


  String _formatIngredients(String raw) {
    final parts = raw
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '-';
    return parts.join(', ');
  }

  Widget _buildStepsAligned(List<String> steps) {
    if (steps.isEmpty) {
      return const Text('-', style: TextStyle(color: Color(0xFF187C5C), fontSize: 17));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final n = i + 1;
        return Padding(
          padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 4 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$n.',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  steps[i],
                  softWrap: true,
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  strutStyle: const StrutStyle(
                    forceStrutHeight: true, height: 1.5
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
