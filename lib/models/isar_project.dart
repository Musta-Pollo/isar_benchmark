import 'package:isar/isar.dart';
import 'package:isar_benchmark/models/isar_model.dart';
import 'package:isar_benchmark/models/project.dart';

part 'isar_project.g.dart';

@Collection()
class IsarIndexProject {
  Id id;

  @Index()
  final String name;

  final models = IsarLinks<IsarIndexModel>();

  IsarIndexProject({
    required this.id,
    required this.name,
    // required this.models,
  });

  factory IsarIndexProject.fromModel(Project project) {
    return IsarIndexProject(
      id: project.id,
      name: project.name,
    );
  }
}

@Collection()
class IsarProject {
  Id id;

  final String name;

  final models = IsarLinks<IsarModel>();

  IsarProject({
    required this.id,
    required this.name,
    // required this.models,
  });

  factory IsarProject.fromModel(Project project) {
    return IsarProject(
      id: project.id,
      name: project.name,
    );
  }
}
