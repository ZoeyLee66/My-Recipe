import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:assignment/my_recipe_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'db/isar_service.dart';
import 'models/recipe.dart';
import 'recipe_detail_page.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key, this.recipeIdToEdit});
  final int? recipeIdToEdit;

  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _nameController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30.0),
    borderSide: const BorderSide(color: Color(0xFF187C5C), width: 1.5),
  );

  final List<TextEditingController> _step = [];
  final Set<String> _selectedTags = {};
  final ImagePicker _picker = ImagePicker();
  XFile? _recipeImage;
  String? _existingImagePath;

  bool _loading = false;
  Recipe? _original;

  bool get _isEdit => widget.recipeIdToEdit != null;

  @override
  void initState() {
    super.initState();
    _step.add(TextEditingController());
    if (_isEdit) _loadForEdit();
  }

  Future<void> _loadForEdit() async {
    setState(() => _loading = true);
    final isar = await IsarService.db;
    final r = await isar.recipes.get(widget.recipeIdToEdit!);
    _original = r;
    if (r != null) {
      _nameController.text = r.recipeName;
      _ingredientsController.text = r.ingredients;
      _selectedTags
        ..clear()
        ..addAll(r.tags);
      _step.clear();
      if (r.steps.isEmpty) {
        _step.add(TextEditingController());
      } else {
        for (final s in r.steps) {
          _step.add(TextEditingController(text: s));
        }
      }
      _existingImagePath = r.imagePath;
      if ((r.imagePath ?? '').isNotEmpty) {
        _recipeImage = XFile(r.imagePath!);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    for (final c in _step) c.dispose();
    super.dispose();
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
              Expanded(
                child: ListView(
                  children: [
                    if (_recipeImage != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_recipeImage!.path),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildSectionTitleWithAdd('RECIPE NAME'),
                    CustomPaint(painter: DashedLinePainter(), child: const SizedBox(height: 1)),
                    const SizedBox(height: 10),
                    _buildTextField('Recipe Name', controller: _nameController),
                    const SizedBox(height: 30),

                    _buildSectionTitle('Ingredients'),
                    CustomPaint(painter: DashedLinePainter(), child: const SizedBox(height: 1)),
                    const SizedBox(height: 10),
                    _buildTextField('Ingredient list', controller: _ingredientsController),
                    const SizedBox(height: 30),

                    _buildSectionTitle('STEPS'),
                    CustomPaint(painter: DashedLinePainter(), child: const SizedBox(height: 1)),
                    const SizedBox(height: 10),
                    ...List.generate(_step.length, (i) {
                      final isDeletable = _step.length > 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF187C5C),
                              radius: 16,
                              child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: TextField(
                                controller: _step[i],
                                decoration: InputDecoration(
                                  hintText: 'Step',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF525252)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: outline,
                                  enabledBorder: outline,
                                  focusedBorder: outline,
                                ),
                              ),
                            ),
                            if (isDeletable) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    final ctrl = _step.removeAt(i);
                                    ctrl.dispose();
                                  });
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/delete_g.svg',
                                  width: 20, height: 20,
                                  colorFilter: const ColorFilter.mode(Color(0xFF187C5C), BlendMode.srcIn),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _step.add(TextEditingController())),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          foregroundColor: const Color(0xFF187C5C),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF187C5C)),
                            const SizedBox(width: 6),
                            Text(
                              'Add more step',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF187C5C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildSectionTitle('Tag (Maximum two tags)'),
                    CustomPaint(painter: DashedLinePainter(), child: const SizedBox(height: 1)),
                    const SizedBox(height: 10),
                    _buildTagSection(),
                    const SizedBox(height: 30),

                    if (_isEdit) ...[
                      Center(
                        child: OutlinedButton(
                          onPressed: _onCancel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF187C5C), width: 1.5),
                            foregroundColor: const Color(0xFF187C5C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            padding: const EdgeInsets.symmetric(horizontal: 94, vertical: 10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'CANCEL',
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false, applyHeightToLastDescent: false,
                              ),
                              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0, leading: 0),
                              style: GoogleFonts.jomhuria(
                                fontSize: 40, fontWeight: FontWeight.w400, color: const Color(0xFF187C5C),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    Center(
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF187C5C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'SAVE',
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false, applyHeightToLastDescent: false,
                            ),
                            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0, leading: 0),
                            style: GoogleFonts.jomhuria(
                              fontSize: 45, fontWeight: FontWeight.w400, color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final ImagePicker _galleryPicker = ImagePicker();
  Future<void> _pickRecipeImage() async {
    final XFile? img = await _galleryPicker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final saved = await _persistPickedImage(img.path);
      setState(() {
        _recipeImage = XFile(saved ?? img.path);
        _existingImagePath = _recipeImage!.path;
      });
    }
  }
  void _clearRecipeImage() {
    setState(() {
      _recipeImage = null;
      _existingImagePath = null;
    });
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: GoogleFonts.jomhuria(
      fontSize: 33, fontWeight: FontWeight.w400, color: const Color(0xFF187C5C),
      height: 1.0, letterSpacing: 0.5,
    ),
  );

  Widget _buildTextField(String hintText, {TextEditingController? controller}) => TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF525252)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: outline, enabledBorder: outline, focusedBorder: outline,
    ),
  );

  Widget _buildTagSection() {
    final tags = [
      'SOUP','NOODLE','RICE','DESSERT','LUNCH BOX','KIDS',
      'SPICY','VEGETARIAN','SIDE','PASTRY','SEAFOOD','MEAT','OTHER',
    ];
    final limitReached = _selectedTags.length >= 2;

    return Wrap(
      spacing: 4, runSpacing: 8,
      children: tags.map((label) {
        final isSelected = _selectedTags.contains(label);
        final canSelectMore = isSelected || !limitReached;
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _selectedTags.remove(label);
            } else if (_selectedTags.length < 2) {
              _selectedTags.add(label);
            }
          }),
          child: _buildTag(label, selected: isSelected, disabled: !canSelectMore),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitleWithAdd(String title) {
    final hasImage = (_recipeImage != null) || (_existingImagePath != null);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.jomhuria(
              fontSize: 33, fontWeight: FontWeight.w400, color: const Color(0xFF187C5C),
              height: 1.0, letterSpacing: 0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextButton(
            onPressed: _pickRecipeImage,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF187C5C),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                  child: SvgPicture.asset('assets/icons/add_photo_w.svg',
                    width: 14, height: 14,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    hasImage ? 'Change Recipe Img' : 'Add Recipe Img',
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false, applyHeightToLastDescent: false,
                    ),
                    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 11, fontWeight: FontWeight.w600, height: 1.0, color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasImage)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: GestureDetector(
              onTap: _clearRecipeImage,
              child: SvgPicture.asset('assets/icons/trash_g.svg',
                width: 22, height: 22,
                colorFilter: const ColorFilter.mode(Color(0xFF187C5C), BlendMode.srcIn),
              ),
            ),
          ),
      ],
    );
  }

  Future<String?> _persistPickedImage(String srcPath) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final ext = srcPath.toLowerCase().endsWith('.png') ? '.png' : '.jpg';
      final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}$ext';
      final saved = File('${docs.path}/$fileName');
      await File(srcPath).copy(saved.path);
      return saved.path;
    } catch (_) {
      return null;
    }
  }

  void _onCancel() {
    if (_isEdit && _original != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: _original!.id)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final ingredients = _ingredientsController.text.trim();
    final steps = _step.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final tags = _selectedTags.toList();
    final imagePath = _existingImagePath;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter recipe name')));
      return;
    }

    final isar = await IsarService.db;
    final now = DateTime.now();

    if (_isEdit && _original != null) {
      final updated = Recipe()
        ..id = _original!.id
        ..recipeName = name
        ..ingredients = ingredients
        ..steps = steps
        ..tags = tags
        ..imagePath = imagePath
        ..createdAt = _original!.createdAt
        ..updatedAt = now;

      await isar.writeTxn(() async {
        await isar.recipes.put(updated);
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: updated.id)),
      );
    } else {
      final recipe = Recipe()
        ..recipeName = name
        ..ingredients = ingredients
        ..steps = steps
        ..tags = tags
        ..imagePath = imagePath
        ..createdAt = now
        ..updatedAt = now;

      await isar.writeTxn(() async {
        await isar.recipes.put(recipe);
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!')));
      _resetForm();
    }
  }

  void _resetForm() {
    _nameController.clear();
    _ingredientsController.clear();
    for (final c in _step) c.dispose();
    _step
      ..clear()
      ..add(TextEditingController());
    _selectedTags.clear();
    _recipeImage = null;
    _existingImagePath = null;
    setState(() {});
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false, applyHeightToLastDescent: false,
        ),
        strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0, leading: 0),
        style: GoogleFonts.jomhuria(
          fontSize: 22, fontWeight: FontWeight.w400, color: textColor, height: 1.0, letterSpacing: 0.3,
        ),
      ),
    );
  }
}
