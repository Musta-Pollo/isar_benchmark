import 'dart:async';
import 'dart:io';

import 'package:isar_benchmark/executor/executor.dart';
import 'package:isar_benchmark/models/model.dart';
import 'package:isar_benchmark/models/project.dart';
import 'package:isar_benchmark/models/realm_model.dart';
import 'package:realm/realm.dart' hide RealmModel;

class RealmExecutor extends Executor<Realm> {
  RealmExecutor(super.directory, super.repetitions);

  String get realmFile => '$directory/db.realm';

  @override
  FutureOr<Realm> prepareDatabase() {
    final config = Configuration.local(
      [
        RealmModel.schema,
        RealmIndexModel.schema,
        RealmIndexProject.schema,
        RealmProject.schema
      ],
      path: realmFile,
    );
    return Realm(config);
  }

  @override
  FutureOr<void> finalizeDatabase(Realm db) async {
    db.close();
    File(realmFile).deleteSync();
  }

  @override
  Stream<int> insertSync(List<Model> models) {
    return runBenchmark((realm) {
      List<RealmModel> realmModels = models.map(modelToRealm).toList();
      realm.write(() {
        realm.addAll(realmModels);
      });
    });
  }

  @override
  Stream<int> insertAsync(List<Model> models) => throw UnimplementedError();

  @override
  Stream<int> getSync(List<Model> models) {
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (realm) {
        final realmModels = models.map(modelToRealm).toList();
        realm.write(() {
          realm.addAll(realmModels);
        });
      },
      (realm) {
        for (var id in idsToGet) {
          realmToModel(realm.find<RealmModel>(id)!);
        }
      },
    );
  }

  @override
  Stream<int> getAsync(List<Model> models) => throw UnimplementedError();

  @override
  Stream<int> deleteSync(List<Model> models) {
    late List<RealmModel> modelsToDelete;
    return runBenchmark(
      prepare: (realm) {
        final realmModels = models.map(modelToRealm).toList();
        modelsToDelete = realmModels.where((e) => e.id % 2 == 0).toList();
        realm.write(() {
          realm.addAll(realmModels);
        });
      },
      (realm) {
        realm.write(() {
          // TODO use delete by id when available
          realm.deleteMany(modelsToDelete);
        });
      },
    );
  }

  @override
  Stream<int> deleteAsync(List<Model> models) => throw UnimplementedError();

  @override
  Stream<int> filterQuerySync(List<Model> models) {
    return runBenchmark(
      prepare: (realm) {
        final realmModels = models.map(modelToRealm).toList();
        realm.write(() {
          realm.addAll(realmModels);
        });
      },
      (realm) {
        final results = realm.query<RealmModel>(
            "ANY words contains 'time' OR title CONTAINS 'a'");
        for (var result in results) {
          realmToModel(result);
        }
      },
    );
  }

  @override
  Stream<int> filterSortQuerySync(List<Model> models) {
    return runBenchmark(
      prepare: (realm) {
        final realmModels = models.map(modelToRealm).toList();
        realm.write(() {
          realm.addAll(realmModels);
        });
      },
      (realm) {
        final results =
            realm.query<RealmModel>('archived == true SORT(title ASCENDING)');
        for (var result in results) {
          realmToModel(result);
        }
      },
    );
  }

  @override
  Stream<int> dbSize(List<Model> models, List<Project> projects) async* {
    final realmModels = models.map(modelToRealm).toList();
    final realm = await prepareDatabase();
    try {
      final realmModels = models.map(modelToRealm).toList();
      final realmProjects = projects.map(projectToRealm).toList();
      realm.write(() {
        realm.addAll(realmModels);
        for (var i = 0; i < projects.length; i++) {
          final realmProject = realmProjects[i];
          final project = projects[i];

          for (final model in project.models) {
            final foundModel = realm.find<RealmModel>(model) as RealmModel;
            realmProject.models.add(foundModel);
          }
          realm.add(realmProject);
        }
      });
      final stat = await File(realmFile).stat();
      yield (stat.size / 1000).round();
    } finally {
      await finalizeDatabase(realm);
    }
  }

  @override
  Stream<int> relationshipsNToNDeleteSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      prepare: (realm) {
        final realmModels = models.map(modelToRealm).toList();
        final realmProjects = projects.map(projectToRealm).toList();
        realm.write(() {
          realm.addAll(realmModels);
          for (var i = 0; i < projects.length; i++) {
            final realmProject = realmProjects[i];
            final project = projects[i];

            for (final model in project.models) {
              final foundModel = realm.find<RealmModel>(model) as RealmModel;
              realmProject.models.add(foundModel);
            }
            realm.add(realmProject);
          }
        });
      },
      (realm) {
        for (final project in projects) {
          //It loads linked object automaticly

          final pro = realm.find<RealmProject>(project.id) as RealmProject;
          realm.write(() {
            realm.deleteMany(pro.models);
            realm.delete(pro);
          });
        }
      },
    );
  }

  @override
  Stream<int> relationshipsNToNFindSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      prepare: (realm) {
        final realmModels = models.map(modelToRealm).toList();
        final realmProjects = projects.map(projectToRealm).toList();
        realm.write(() async {
          realm.addAll(realmModels);
          for (var i = 0; i < projects.length; i++) {
            final realmProject = realmProjects[i];
            final project = projects[i];

            for (final model in project.models) {
              final foundModel = realm.find<RealmModel>(model) as RealmModel;
              realmProject.models.add(foundModel);
            }
            realm.add(realmProject);
          }
        });
      },
      (realm) {
        for (final project in projects) {
          //It loads linked object automaticly
          final pro = realm.find<RealmProject>(project.id);

          final models = pro!.models.map((e) => e.title);
        }
      },
    );
  }

  @override
  Stream<int> relationshipsNToNInsertSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      (realm) {
        final realmModels = models.map(modelToRealm).toList();
        final realmProjects = projects.map(projectToRealm).toList();
        realm.write(() async {
          realm.addAll(realmModels);
          for (var i = 0; i < projects.length; i++) {
            final realmProject = realmProjects[i];
            final project = projects[i];

            for (final model in project.models) {
              final foundModel = realm.find<RealmModel>(model) as RealmModel;
              realmProject.models.add(foundModel);
              foundModel.projects.add(realmProject);
            }
            realm.add(realmProject);
          }
        });
      },
    );
  }

  @override
  Stream<int> relationshipsNToNDeleteAsync(
      List<Model> models, List<Project> projects) {
    // TODO: implement relationshipsNTo1DeleteAsync
    throw UnimplementedError();
  }

  @override
  Stream<int> relationshipsNToNFindAsync(
      List<Model> models, List<Project> projects) {
    // TODO: implement relationshipsNTo1FindAsync
    throw UnimplementedError();
  }

  @override
  Stream<int> relationshipsNToNInsertAsync(
      List<Model> models, List<Project> projects) {
    // TODO: implement relationshipsNTo1InsertAsync
    throw UnimplementedError();
  }

  @override
  Stream<int> filterQueryAsync(List<Model> models) {
    // TODO: implement filterQueryAsync
    throw UnimplementedError();
  }

  @override
  Stream<int> filterSortQueryAsync(List<Model> models) {
    // TODO: implement filterSortQueryAsync
    throw UnimplementedError();
  }
}
