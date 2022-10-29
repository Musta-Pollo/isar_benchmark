import 'package:isar_benchmark/models/project.dart';
import 'package:objectbox/objectbox.dart';

import 'objectbox_model.dart';

@Entity()
class ObjectBoxIndexProject {
  @Id(assignable: true)
  int id;

  @Index()
  final String name;

  final models = ToMany<ObjectBoxModel>();

  ObjectBoxIndexProject({
    required this.id,
    required this.name,
  });

  factory ObjectBoxIndexProject.fromModel(Project model) {
    return ObjectBoxIndexProject(
      id: model.id,
      name: model.name,
    );
  }

  
}

@Entity()
class ObjectBoxProject {
  @Id(assignable: true)
  int id;

  final String name;

  final models = ToMany<ObjectBoxModel>();

  ObjectBoxProject({
    required this.id,
    required this.name,
  });

  factory ObjectBoxProject.fromModel(Project model) {
    return ObjectBoxProject(
      id: model.id,
      name: model.name,
    );
  }
}
