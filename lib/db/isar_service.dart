import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> get db async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([RecipeSchema], directory: dir.path);
    return _isar!;
  }

  Future<List<Recipe>> getAll() async {
    final isar = await db;
    return isar.recipes.where().sortByCreatedAtDesc().findAll();
  }

  Future<List<Recipe>> getByTags(Set<String> tags) async {
    final isar = await db;
    if (tags.isEmpty) return getAll();

    final t = tags.toList();
    if (t.length == 1) {
      return isar.recipes
          .filter()
          .tagsElementEqualTo(t[0], caseSensitive: false)
          .sortByCreatedAtDesc()
          .findAll();
    }
    return isar.recipes
        .filter()
        .group((q) => q
        .tagsElementEqualTo(t[0], caseSensitive: false)
        .or()
        .tagsElementEqualTo(t[1], caseSensitive: false))
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<List<Recipe>> searchByNamePrefix(String q, Set<String> tags) async {
    final isar = await db;
    final query = isar.recipes.filter().recipeNameStartsWith(q, caseSensitive: false);

    if (tags.isEmpty) {
      return query.sortByCreatedAtDesc().findAll();
    }

    final t = tags.toList();
    if (t.length == 1) {
      return query
          .and()
          .tagsElementEqualTo(t[0], caseSensitive: false)
          .sortByCreatedAtDesc()
          .findAll();
    }

    return query
        .and()
        .group((g) => g
        .tagsElementEqualTo(t[0], caseSensitive: false)
        .or()
        .tagsElementEqualTo(t[1], caseSensitive: false))
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<Recipe?> getById(int id) async {
    final isar = await IsarService.db;
    return isar.recipes.get(id);
  }
}

