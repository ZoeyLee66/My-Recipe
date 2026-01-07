import 'package:isar/isar.dart';

part 'recipe.g.dart';

@collection
class Recipe {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String recipeName;
  late String ingredients;
  List<String> steps = [];
  List<String> tags = [];
  String? imagePath;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;
}
