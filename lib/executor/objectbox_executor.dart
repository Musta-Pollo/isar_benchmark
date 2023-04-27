import 'dart:async';
import 'dart:io';

import 'package:isar_benchmark/executor/executor.dart';
import 'package:isar_benchmark/models/model.dart';
import 'package:isar_benchmark/models/objectbox_model.dart';
import 'package:isar_benchmark/models/project.dart';
import 'package:isar_benchmark/objectbox.g.dart';

import '../models/objectbox_project.dart';

List<ObjectBoxModel?> _getAsync(Store store, List<int> idsToGet) {
  return store.box<ObjectBoxModel>().getMany(idsToGet);
}

void _deleteAsync(Store store, List<int> idsToDelete) {
  store.box<ObjectBoxModel>().removeMany(idsToDelete);
}

class ObjectBoxExecutor extends Executor<Store> {
  ObjectBoxExecutor(super.directory, super.repetitions);

  String get storeDirectory => '$directory/objectbox';

  @override
  FutureOr<Store> prepareDatabase() {
    var store = Store(
      getObjectBoxModel(),
      directory: storeDirectory,
    );
    return store;
  }

  @override
  FutureOr finalizeDatabase(Store db) {
    db.close();
    return Directory(storeDirectory).delete(recursive: true);
  }

  @override
  Stream<int> insertSync(List<Model> models) {
    return runBenchmark((store) {
      final obModels = models.map(ObjectBoxModel.fromModel).toList();
      store.box<ObjectBoxModel>().putMany(obModels);
    });
  }

  @override
  Stream<int> insertAsync(List<Model> models) {
    return runBenchmark((store) {
      final obModels = models.map(ObjectBoxModel.fromModel).toList();
      return store.runAsync<List<ObjectBoxModel>, void>(
        (store, obModels) {
          store.box<ObjectBoxModel>().putMany(obModels);
        },
        obModels,
      );
    });
  }

  @override
  Stream<int> getSync(List<Model> models) {
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (store) {
        final obModels = models.map(ObjectBoxModel.fromModel).toList();
        store.box<ObjectBoxModel>().putMany(obModels);
      },
      (store) {
        store.box<ObjectBoxModel>().getMany(idsToGet);
      },
    );
  }

  @override
  Stream<int> getAsync(List<Model> models) {
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (store) {
        final obModels = models.map(ObjectBoxModel.fromModel).toList();
        store.box<ObjectBoxModel>().putMany(obModels);
      },
      (store) async {
        await store.runAsync<List<int>, List<ObjectBoxModel?>>(
          _getAsync,
          idsToGet,
        );
      },
    );
  }

  @override
  Stream<int> deleteSync(List<Model> models) {
    final idsToDelete =
        models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (store) {
        final obModels = models.map(ObjectBoxModel.fromModel).toList();
        store.box<ObjectBoxModel>().putMany(obModels);
      },
      (store) {
        store.box<ObjectBoxModel>().removeMany(idsToDelete);
      },
    );
  }

  @override
  Stream<int> deleteAsync(List<Model> models) {
    final idsToDelete =
        models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (store) {
        final obModels = models.map(ObjectBoxModel.fromModel).toList();
        store.box<ObjectBoxModel>().putMany(obModels);
      },
      (store) {
        return store.runAsync<List<int>, void>(_deleteAsync, idsToDelete);
      },
    );
  }

  @override
  Stream<int> filterQuerySync(List<Model> models) {
    return runBenchmark(
      prepare: (store) {
        final obModels = models.map(ObjectBoxModel.fromModel).toList();
        store.box<ObjectBoxModel>().putMany(obModels);
      },
      (store) {
        store
            .box<ObjectBoxModel>()
            .query(
              ObjectBoxModel_.words.contains('time').or(
                    ObjectBoxModel_.title.contains('a'),
                  ),
            )
            .build()
            .find();
      },
    );
  }

  @override
  Stream<int> filterSortQuerySync(List<Model> models) {
    final obModels = models.map(ObjectBoxModel.fromModel).toList();
    return runBenchmark(
      prepare: (store) {
        store.box<ObjectBoxModel>().putMany(obModels);
      },
      (store) {
        (store
                .box<ObjectBoxModel>()
                .query(ObjectBoxModel_.archived.equals(true))
              ..order(ObjectBoxModel_.title))
            .build()
            .find();
      },
    );
  }

  @override
  Stream<int> dbSize(List<Model> models, List<Project> projects) async* {
    final obModels = models.map(ObjectBoxModel.fromModel).toList();
    final store = await prepareDatabase();
    try {
      final obModels = models.map(ObjectBoxModel.fromModel).toList();
      final obProjects = projects.map(ObjectBoxProject.fromModel).toList();
      store.box<ObjectBoxModel>().putMany(obModels);
      for (var i = 0; i < projects.length; i++) {
        final obProject = obProjects[i];
        final project = projects[i];
        final foundModels = store
            .box<ObjectBoxModel>()
            .getMany(project.models)
            .map((e) => e as ObjectBoxModel);
        obProject.models.addAll(foundModels);
        store.box<ObjectBoxProject>().put(obProject);
      }
      final stat = await File('$storeDirectory/data.mdb').stat();
      yield (stat.size / 1000).round();
    } finally {
      await finalizeDatabase(store);
    }
  }

  @override
  Stream<int> relationshipsNToNInsertSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      (store) {
        final obModels = models.map(ObjectBoxModel.fromModel).toList();
        final obProjects = projects.map(ObjectBoxProject.fromModel).toList();
        store.box<ObjectBoxModel>().putMany(obModels);
        for (var i = 0; i < projects.length; i++) {
          final obProject = obProjects[i];
          final project = projects[i];
          final foundModels = store
              .box<ObjectBoxModel>()
              .getMany(project.models)
              .map((e) => e as ObjectBoxModel);
          obProject.models.addAll(foundModels);
          store.box<ObjectBoxProject>().put(obProject);
        }
      },
    );
  }

  @override
  Stream<int> relationshipsNToNDeleteSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      prepare: (store) {
        final obModels = models.map(ObjectBoxModel.fromModel).toList();
        final obProjects = projects.map(ObjectBoxProject.fromModel).toList();
        store.box<ObjectBoxModel>().putMany(obModels);
        for (var i = 0; i < projects.length; i++) {
          final obProject = obProjects[i];
          final project = projects[i];
          final foundModels = store
              .box<ObjectBoxModel>()
              .getMany(project.models)
              .map((e) => e as ObjectBoxModel);
          obProject.models.addAll(foundModels);
          store.box<ObjectBoxProject>().put(obProject);
        }
      },
      (store) {
        for (final project in projects) {
          final pro = store.box<ObjectBoxProject>().get(project.id);
          store
              .box<ObjectBoxModel>()
              .removeMany(pro!.models.map((element) => element.id).toList());
          store.box<ObjectBoxProject>().get(project.id);
        }
      },
    );
  }

  @override
  Stream<int> relationshipsNToNFindSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      prepare: (store) {
        final obModels = models.map(ObjectBoxModel.fromModel).toList();
        final obProjects = projects.map(ObjectBoxProject.fromModel).toList();
        store.box<ObjectBoxModel>().putMany(obModels);
        for (var i = 0; i < projects.length; i++) {
          final obProject = obProjects[i];
          final project = projects[i];
          final foundModels = store
              .box<ObjectBoxModel>()
              .getMany(project.models)
              .map((e) => e as ObjectBoxModel);
          obProject.models.addAll(foundModels);
          store.box<ObjectBoxProject>().put(obProject);
        }
      },
      (store) {
        for (final project in projects) {
          final pro = store.box<ObjectBoxProject>().get(project.id);

          final models = pro!.models.map((element) => element.title);
        }
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
