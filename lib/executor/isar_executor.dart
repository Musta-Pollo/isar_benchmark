import 'dart:async';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:isar_benchmark/executor/executor.dart';
import 'package:isar_benchmark/models/isar_model.dart';
import 'package:isar_benchmark/models/model.dart';
import 'package:isar_benchmark/models/project.dart';

import '../models/isar_project.dart';

class IsarExecutor extends Executor<Isar> {
  IsarExecutor(super.directory, super.repetitions);

  @override
  FutureOr<Isar> prepareDatabase() async {
    final isar = await Isar.open(
      [
        IsarIndexModelSchema,
        IsarModelSchema,
        IsarProjectSchema,
        IsarIndexProjectSchema
      ],
      directory: directory,
    );

    isar.writeTxnSync(() {
      isar.isarModels.clearSync();
      isar.isarIndexModels.clearSync();
      isar.isarIndexProjects.clearSync();
      isar.isarProjects.clearSync();
    });
    return isar;
  }

  @override
  FutureOr<void> finalizeDatabase(Isar db) async {
    await db.close(deleteFromDisk: true);
  }

  @override
  Stream<int> insertSync(List<Model> models) {
    final isarModels = models.map(IsarModel.fromModel).toList();
    return runBenchmark((isar) {
      isar.writeTxnSync(() {
        isar.isarModels.putAllSync(isarModels);
      });
    });
  }

  @override
  Stream<int> insertAsync(List<Model> models) {
    final isarModels = models.map(IsarModel.fromModel).toList();
    return runBenchmark((isar) {
      return isar.writeTxn(() {
        return isar.isarModels.putAll(isarModels);
      });
    });
  }

  @override
  Stream<int> getSync(List<Model> models) {
    final isarModels = models.map(IsarModel.fromModel).toList();
    final idsToGet =
        isarModels.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (isar) {
        return isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
      },
      (isar) {
        isar.writeTxnSync(() {
          isar.isarModels.getAllSync(idsToGet);
        });
      },
    );
  }

  @override
  Stream<int> getAsync(List<Model> models) {
    final isarModels = models.map(IsarModel.fromModel).toList();
    final idsToGet =
        isarModels.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (isar) {
        return isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
      },
      (isar) {
        return isar.writeTxn(() {
          return isar.isarModels.getAll(idsToGet);
        });
      },
    );
  }

  @override
  Stream<int> deleteSync(List<Model> models) {
    final isarModels = models.map(IsarModel.fromModel).toList();
    final idsToDelete =
        isarModels.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (isar) {
        return isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
      },
      (isar) {
        isar.writeTxnSync(() {
          isar.isarModels.deleteAllSync(idsToDelete);
        });
      },
    );
  }

  @override
  Stream<int> deleteAsync(List<Model> models) {
    final isarModels = models.map(IsarModel.fromModel).toList();
    final idsToDelete =
        isarModels.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (isar) {
        return isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
      },
      (isar) {
        return isar.writeTxn(() {
          return isar.isarModels.deleteAll(idsToDelete);
        });
      },
    );
  }

  @override
  Stream<int> filterQuery(List<Model> models) {
    final isarModels = models.map(IsarModel.fromModel).toList();
    return runBenchmark(
      prepare: (isar) {
        return isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
      },
      (isar) {
        isar.isarModels
            .filter()
            .wordsElementEqualTo('time')
            .or()
            .titleContains('a')
            .findAllSync();
      },
    );
  }

  @override
  Stream<int> filterSortQuery(List<Model> models) {
    final isarModels = models.map(IsarModel.fromModel).toList();
    return runBenchmark(
      prepare: (isar) {
        return isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
      },
      (isar) {
        isar.isarModels
            .filter()
            .archivedEqualTo(true)
            .sortByTitle()
            .findAllSync();
      },
    );
  }

  @override
  Stream<int> dbSize(List<Model> models) async* {
    final isarModels = models.map(IsarModel.fromModel).toList();
    final isar = await prepareDatabase();
    try {
      await isar.writeTxn(() {
        return isar.isarModels.putAll(isarModels);
      });
      final stat = await File('$directory/default.isar').stat();
      yield (stat.size / 1000).round();
    } finally {
      await finalizeDatabase(isar);
    }
  }

  @override
  Stream<int> relationshipsNTo1InsertSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      (isar) async {
        final isarModels = models.map(IsarModel.fromModel).toList();
        isar.writeTxnSync(() {
          return isar.isarModels.putAllSync(isarModels);
        });
        final isarProjects = projects.map(IsarProject.fromModel).toList();
        for (var i = 0; i < projects.length; i++) {
          isar.writeTxnSync(() async {
            final isarProject = isarProjects[i];
            final project = projects[i];
            final foundModels = (isar.isarModels.getAllSync(project.models))
                .map((e) => e as IsarModel);
            isarProject.id = isar.isarProjects.putSync(isarProject);
            isarProject.models.addAll(foundModels);
            isarProject.models.saveSync();
          });
        }
      },
    );
  }

  @override
  Stream<int> relationshipsNTo1FindSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(prepare: (isar) async {
      final isarModels = models.map(IsarModel.fromModel).toList();
      final isarProjects = projects.map(IsarProject.fromModel).toList();
      await isar.writeTxn(() {
        return isar.isarModels.putAll(isarModels);
      });
      return isar.writeTxnSync(() async {
        for (var i = 0; i < projects.length; i++) {
          final isarProject = isarProjects[i];
          final project = projects[i];
          final foundModels = (isar.isarModels.getAllSync(project.models))
              .map((e) => e as IsarModel);
          isarProject.models.addAll(foundModels);
          isar.isarProjects.putSync(isarProject);
          isarProject.models.saveSync();
        }
      });
    }, (isar) async {
      for (final project in projects) {
        //It loads linked object automaticly
        final pro = isar.isarProjects.getSync(project.id);

        final models = pro!.models.map((e) => e.title);
      }
    });
  }

  @override
  Stream<int> relationshipsNTo1DeleteSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(prepare: (isar) async {
      final isarModels = models.map(IsarModel.fromModel).toList();
      final isarProjects = projects.map(IsarProject.fromModel).toList();
      await isar.writeTxn(() {
        return isar.isarModels.putAll(isarModels);
      });
      return isar.writeTxnSync(() async {
        isar.isarModels.putAllSync(isarModels);
        for (var i = 0; i < projects.length; i++) {
          final isarProject = isarProjects[i];
          final project = projects[i];
          final foundModels = (isar.isarModels.getAllSync(project.models))
              .map((e) => e as IsarModel);
          isar.isarProjects.putSync(isarProject);
          isarProject.models.addAll(foundModels);
          isarProject.models.saveSync();
        }
      });
    }, (isar) async {
      for (final project in projects) {
        //It loads linked object automaticly
        final pro = isar.isarProjects.getSync(project.id);
        final modelIds = pro!.models.map((e) => e.id).toList();
        isar.writeTxnSync(() {
          isar.isarModels.deleteAllSync(modelIds);
          isar.isarProjects.deleteSync(project.id);
        });
      }
    });
  }
}
