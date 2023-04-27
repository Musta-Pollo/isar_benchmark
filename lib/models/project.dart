import 'dart:math';

import '../helpers.dart';

class Project {
  final int id;

  final String name;

  final List<int> models;

  const Project({
    required this.id,
    required this.name,
    required this.models,
  });

  static List<Project> generateProjects(int count, bool big) {
    final rand = Random();
    final List<Project> models = [];

    for (var i = 1; i < count + 1; i++) {
      models.add(
        Project(
          id: i,
          name: generateWords(big ? 50 : 5, rand).join(' '),
          models: generatedModelIds(big ? 50 : 5, rand, count * 100),
        ),
      );
    }

    return models;
  }

  Project get copy {
    return Project(
      id: id,
      name: name,
      models: models,
    );
  }
}
