import 'package:isar_benchmark/models/model.dart';
import 'package:isar_benchmark/models/project.dart';
import 'package:realm/realm.dart' hide RealmModel;
import 'package:realm/realm.dart' as realm;

part 'realm_model.g.dart';

@realm.RealmModel()
class _RealmIndexModel {
  @PrimaryKey()
  late int id;

  @Indexed()
  late String title;

  late List<_RealmProject> indexProjects;

  late List<String> words;

  late bool archived;
}

RealmIndexModel modelToRealmIndex(Model model) {
  return RealmIndexModel(
    model.id,
    model.title,
    model.archived,
    words: model.words,
  );
}

@realm.RealmModel()
class _RealmModel {
  @PrimaryKey()
  late int id;

  late String title;

  late List<_RealmProject> projects;

  late List<String> words;

  late bool archived;
}

RealmModel modelToRealm(Model model) {
  return RealmModel(
    model.id,
    model.title,
    model.archived,
    words: model.words,
  );
}

Model realmToModel(RealmModel model) {
  return Model(
    id: model.id,
    title: model.title,
    archived: model.archived,
    words: model.words,
  );
}

@realm.RealmModel()
class _RealmIndexProject {
  @PrimaryKey()
  late int id;

  @Indexed()
  late String name;

  late List<_RealmModel> indexModels;
}

RealmIndexProject projectToRealmIndex(Project project) {
  return RealmIndexProject(
    project.id,
    project.name,
  );
}

@realm.RealmModel()
class _RealmProject {
  @PrimaryKey()
  late int id;

  late String name;

  late List<_RealmModel> models;
}

RealmProject projectToRealm(Project project) {
  return RealmProject(
    project.id,
    project.name,
  );
}

Project realmToProject(RealmProject project) {
  return Project(
    id: project.id,
    name: project.name,
    models: [],
  );
}
