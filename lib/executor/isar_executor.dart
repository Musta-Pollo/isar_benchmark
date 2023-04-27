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

    return isar;
  }

  @override
  FutureOr<void> finalizeDatabase(Isar db) async {
    await db.close(deleteFromDisk: true);
  }

  @override
  Stream<int> insertSync(List<Model> models) {
    return runBenchmark((isar) {
      final isarModels = models.map(IsarModel.fromModel).toList();
      isar.writeTxnSync(() {
        isar.isarModels.putAllSync(isarModels);
      });
    });
  }

  @override
  Stream<int> insertAsync(List<Model> models) {
    return runBenchmark((isar) {
      final isarModels = models.map(IsarModel.fromModel).toList();
      return isar.writeTxn(() {
        return isar.isarModels.putAll(isarModels);
      });
    });
  }

  @override
  Stream<int> getSync(List<Model> models) {
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (isar) {
        final isarModels = models.map(IsarModel.fromModel).toList();
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
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (isar) {
        final isarModels = models.map(IsarModel.fromModel).toList();
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
    final idsToDelete =
        models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (isar) {
        final isarModels = models.map(IsarModel.fromModel).toList();
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
    final idsToDelete =
        models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (isar) {
        final isarModels = models.map(IsarModel.fromModel).toList();
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
  Stream<int> filterQuerySync(List<Model> models) {
    return runBenchmark(
      prepare: (isar) {
        final isarModels = models.map(IsarModel.fromModel).toList();
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
  Stream<int> filterSortQuerySync(List<Model> models) {
    return runBenchmark(
      prepare: (isar) {
        final isarModels = models.map(IsarModel.fromModel).toList();
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
  Stream<int> filterQueryAsync(List<Model> models) {
    return runBenchmark(
      prepare: (isar) {
        final isarModels = models.map(IsarModel.fromModel).toList();
        return isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
      },
      (isar) async {
        await isar.isarModels
            .filter()
            .wordsElementEqualTo('time')
            .or()
            .titleContains('a')
            .findAll();
      },
    );
  }

  @override
  Stream<int> filterSortQueryAsync(List<Model> models) {
    return runBenchmark(
      prepare: (isar) {
        final isarModels = models.map(IsarModel.fromModel).toList();
        return isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
      },
      (isar) async {
        await isar.isarModels
            .filter()
            .archivedEqualTo(true)
            .sortByTitle()
            .findAll();
      },
    );
  }

  @override
  Stream<int> dbSize(List<Model> models, List<Project> projects) async* {
    final isar = await prepareDatabase();
    try {
      final isarModels = models.map(IsarModel.fromModel).toList();
      final isarProjects = projects.map(IsarProject.fromModel).toList();
      isar.writeTxnSync(() {
        return isar.isarModels.putAllSync(isarModels);
      });
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
      final stat = await File('$directory/default.isar').stat();
      yield (stat.size / 1000).round();
    } finally {
      await finalizeDatabase(isar);
    }
  }

  @override
  Stream<int> relationshipsNToNInsertSync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      (isar) async {
        final isarModels = models.map(IsarModel.fromModel).toList();
        final isarProjects = projects.map(IsarProject.fromModel).toList();
        isar.writeTxnSync(() {
          return isar.isarModels.putAllSync(isarModels);
        });
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
  Stream<int> relationshipsNToNFindSync(
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
  Stream<int> relationshipsNToNDeleteSync(
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

  @override
  Stream<int> relationshipsNToNInsertAsync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      (isar) async {
        final isarModels = models.map(IsarModel.fromModel).toList();
        await isar.writeTxn(() {
          return isar.isarModels.putAll(isarModels);
        });
        final isarProjects = projects.map(IsarProject.fromModel).toList();
        for (var i = 0; i < projects.length; i++) {
          isar.writeTxn(() async {
            final isarProject = isarProjects[i];
            final project = projects[i];
            final foundModels = (await isar.isarModels.getAll(project.models))
                .map((e) => e as IsarModel);
            isarProject.id = await isar.isarProjects.put(isarProject);
            isarProject.models.addAll(foundModels);
            isarProject.models.save();
          });
        }
      },
    );
  }

  @override
  Stream<int> relationshipsNToNFindAsync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(prepare: (isar) async {
      final isarModels = models.map(IsarModel.fromModel).toList();
      final isarProjects = projects.map(IsarProject.fromModel).toList();
      await isar.writeTxn(() {
        return isar.isarModels.putAll(isarModels);
      });
      return isar.writeTxn(() async {
        for (var i = 0; i < projects.length; i++) {
          final isarProject = isarProjects[i];
          final project = projects[i];
          final foundModels = (await isar.isarModels.getAll(project.models))
              .map((e) => e as IsarModel);
          isarProject.models.addAll(foundModels);
          await isar.isarProjects.put(isarProject);
          await isarProject.models.save();
        }
      });
    }, (isar) async {
      for (final project in projects) {
        //It loads linked object automaticly
        final pro = await isar.isarProjects.get(project.id);

        final models = pro!.models.map((e) => e.title);
      }
    });
  }

  @override
  Stream<int> relationshipsNToNDeleteAsync(
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
        final pro = await isar.isarProjects.get(project.id);
        final modelIds = pro!.models.map((e) => e.id).toList();
        await isar.writeTxn(() async {
          await isar.isarModels.deleteAll(modelIds);
          await isar.isarProjects.delete(project.id);
        });
      }
    });
  }
}
