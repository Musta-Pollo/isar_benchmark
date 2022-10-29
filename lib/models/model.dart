import 'dart:math';

import '../helpers.dart';

class Model {
  final int id;

  final String title;

  final List<String> words;

  final bool archived;

  const Model({
    required this.id,
    required this.title,
    required this.words,
    required this.archived,
  });

  static List<Model> generateModels(int count, bool big) {
    final rand = Random();
    final List<Model> models = [];

    for (var i = 1; i < count + 1; i++) {
      models.add(Model(
        id: i,
        title: generateWords(big ? 50 : 5, rand).join(' '),
        words: generateWords(big ? 50 : 5, rand),
        archived: rand.nextBool(),
      ));
    }

    return models;
  }

  Model get copy {
    return Model(id: id, title: title, words: words, archived: archived);
  }
}
