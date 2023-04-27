import 'package:isar/isar.dart';
import 'package:isar_benchmark/models/isar_project.dart';
import 'package:isar_benchmark/models/model.dart';

part 'isar_model.g.dart';

@Collection()
class IsarIndexModel {
  Id id;

  @Index()
  final String title;

  @Index(type: IndexType.hashElements)
  final List<String> words;

  @Index(composite: [CompositeIndex('title')])
  final bool archived;

  IsarIndexModel({
    required this.id,
    required this.title,
    required this.words,
    required this.archived,
  });

  factory IsarIndexModel.fromModel(Model model) {
    return IsarIndexModel(
      id: model.id,
      title: model.title,
      words: model.words,
      archived: model.archived,
    );
  }
}

@Collection()
class IsarModel {
  Id id;

  final String title;

  final List<String> words;

  final bool archived;

  @Backlink(to: 'models')
  final projects = IsarLinks<IsarProject>();

  IsarModel({
    required this.id,
    required this.title,
    required this.words,
    required this.archived,
  });

  factory IsarModel.fromModel(Model model) {
    return IsarModel(
      id: model.id,
      title: model.title,
      words: model.words,
      archived: model.archived,
    );
  }
}
