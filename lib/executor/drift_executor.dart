import 'dart:async';
import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:drift/drift.dart';
import 'package:isar_benchmark/executor/executor.dart';
import 'package:isar_benchmark/models/drift_extensions.dart';
import 'package:isar_benchmark/models/drift_models.dart';
import 'package:isar_benchmark/models/model.dart';
import 'package:isar_benchmark/models/project.dart';

class DriftExecutor extends Executor<Drift> {
  DriftExecutor(super.directory, super.repetitions);

  String get storeDirectory => '$directory/db.sqlite';

  @override
  FutureOr<Drift> prepareDatabase() async {
    return Drift(directory);
  }

  @override
  FutureOr finalizeDatabase(Drift db) async {
    await db.close();
    return Directory(storeDirectory).delete(recursive: true);
  }

  @override
  Stream<int> insertSync(List<Model> models) {
    throw UnimplementedError();
  }

  @override
  Stream<int> insertAsync(List<Model> models) {
    return runBenchmark((drift) {
      final driftModels = models.map((e) => e.driftModelCompanion).toList();
      return drift.transaction(() async {
        return drift.batch((batch) {
          return batch.insertAll(drift.driftModel, driftModels);
        });
      });
    });
  }

  @override
  Stream<int> getSync(List<Model> models) => throw UnimplementedError();

  @override
  Stream<int> dbSize(List<Model> models, List<Project> projects) async* {
    final drift = await prepareDatabase();
    try {
      final driftModels = models.map((e) => e.driftModelCompanion).toList();
      final driftProjects =
          projects.map((e) => e.driftProjectCompanion).toList();
      var projModel = projects
          .map((p) => p.models.map((m) => ProjectModel(
                projectId: p.id,
                modelId: m,
              )))
          .flatten()
          .map((e) => e.driftProjectDriftModelCompanion);
      await drift.transaction(
        () async {
          await drift.batch((batch) {
            return batch.insertAll(drift.driftModel, driftModels);
          });
          await drift.batch((batch) {
            return batch.insertAll(drift.driftProject, driftProjects);
          });
          await drift.batch((batch) {
            return batch.insertAll(drift.driftProjectDriftModel, projModel);
          });
        },
      );
      final stat = await File(storeDirectory).stat();
      yield (stat.size / 1000).round();
    } finally {
      await finalizeDatabase(drift);
    }
  }

  @override
  Stream<int> deleteAsync(List<Model> models) {
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (drift) {
        final driftModels = models.map((e) => e.driftModelCompanion).toList();
        return drift.transaction(
          () async {
            return drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
          },
        );
      },
      (drift) async {
        await drift.transaction(() async {
          return drift.batch(
            (batch) => batch.deleteWhere(
              drift.driftModel,
              ($DriftModelTable tbl) => tbl.id.isIn(idsToGet),
            ),
          );
        });
      },
    );
  }

  @override
  Stream<int> deleteSync(List<Model> models) {
    // TODO: implement deleteSync
    throw UnimplementedError();
  }

  @override
  Stream<int> filterQuerySync(List<Model> models) {
    // TODO: implement filterQuery
    throw UnimplementedError();
  }

  @override
  Stream<int> filterSortQuerySync(List<Model> models) {
    // TODO: implement filterSortQuery
    throw UnimplementedError();
  }

  @override
  Stream<int> getAsync(List<Model> models) {
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (drift) {
        final driftModels = models.map((e) => e.driftModelCompanion).toList();
        return drift.transaction(
          () async {
            return drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
          },
        );
      },
      (drift) async {
        await drift.transaction(() async {
          return (drift.select(drift.driftModel)
                ..where((tbl) => tbl.id.isIn(idsToGet)))
              .get();
        });
      },
    );
  }

  @override
  Stream<int> relationshipsNToNDeleteSync(
      List<Model> models, List<Project> projects) {
    // TODO: implement relationshipsNTo1DeleteSync
    throw UnimplementedError();
  }

  @override
  Stream<int> relationshipsNToNFindSync(
      List<Model> models, List<Project> projects) {
    // TODO: implement relationshipsNTo1FindSync
    throw UnimplementedError();
  }

  @override
  Stream<int> relationshipsNToNInsertSync(
      List<Model> models, List<Project> projects) {
    // TODO: implement relationshipsNTo1FindSync
    throw UnimplementedError();
  }

  @override
  Stream<int> relationshipsNToNDeleteAsync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      prepare: (drift) async {
        final driftProjects =
            projects.map((e) => e.driftProjectCompanion).toList();
        final driftModels = models.map((e) => e.driftModelCompanion).toList();

        var projModel = projects
            .map((p) => p.models.map((m) => ProjectModel(
                  projectId: p.id,
                  modelId: m,
                )))
            .flatten()
            .map((e) => e.driftProjectDriftModelCompanion);
        await drift.transaction(
          () async {
            await drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
            await drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
            await drift.batch((batch) {
              return batch.insertAll(drift.driftProjectDriftModel, projModel);
            });
          },
        );
      },
      (drift) async {
        for (final project in projects) {
          //It loads linked object automaticly

          await drift.transaction(
            () async {
              final ids = (await (drift.select(drift.driftProjectDriftModel)
                        ..where((tbl) => tbl.projectId.equals(project.id)))
                      .get())
                  .map((e) => e.modelId);

              drift
                  .delete(drift.driftProject)
                  .where((tbl) => tbl.id.equals(project.id));
              await drift.batch((batch) {
                return batch.deleteWhere(
                    drift.driftProjectDriftModel,
                    ($DriftProjectDriftModelTable tbl) =>
                        tbl.projectId.equals(project.id));
              });
              await drift.batch((batch) {
                return batch.deleteWhere(drift.driftModel,
                    ($DriftModelTable tbl) => tbl.id.isIn(ids));
              });
            },
          );
        }
      },
    );
  }

  @override
  Stream<int> relationshipsNToNFindAsync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      prepare: (drift) async {
        final driftProjects =
            projects.map((e) => e.driftProjectCompanion).toList();
        final driftModels = models.map((e) => e.driftModelCompanion).toList();

        var projModel = projects
            .map((p) => p.models.map((m) => ProjectModel(
                  projectId: p.id,
                  modelId: m,
                )))
            .flatten()
            .map((e) => e.driftProjectDriftModelCompanion);
        await drift.transaction(
          () async {
            await drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
            await drift.batch((batch) {
              return batch.insertAll(drift.driftProject, driftProjects);
            });
            await drift.batch((batch) {
              return batch.insertAll(drift.driftProjectDriftModel, projModel);
            });
          },
        );
      },
      (drift) async {
        for (final project in projects) {
          //It loads linked object automaticly

          await drift.transaction(
            () async {
              final contentQuery =
                  (await (drift.select(drift.driftProjectDriftModel).join(
                [
                  innerJoin(
                    drift.driftModel,
                    drift.driftModel.id
                        .equalsExp(drift.driftProjectDriftModel.modelId),
                  ),
                ],
              )..where(drift.driftProjectDriftModel.projectId
                          .equals(project.id)))
                      .get());

              final titles =
                  contentQuery.map((e) => e.read(drift.driftModel.title));
            },
          );
        }
      },
    );
  }

  @override
  Stream<int> relationshipsNToNInsertAsync(
      List<Model> models, List<Project> projects) {
    return runBenchmark(
      (drift) async {
        final driftModels = models.map((e) => e.driftModelCompanion).toList();
        final driftProjects =
            projects.map((e) => e.driftProjectCompanion).toList();
        var projModel = projects
            .map((p) => p.models.map((m) => ProjectModel(
                  projectId: p.id,
                  modelId: m,
                )))
            .flatten()
            .map((e) => e.driftProjectDriftModelCompanion);
        await drift.transaction(
          () async {
            await drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
            await drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
            await drift.batch((batch) {
              return batch.insertAll(drift.driftProjectDriftModel, projModel);
            });
          },
        );
      },
    );
  }

  @override
  Stream<int> filterQueryAsync(List<Model> models) {
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (drift) {
        final driftModels = models.map((e) => e.driftModelCompanion).toList();
        return drift.transaction(
          () async {
            return drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
          },
        );
      },
      (drift) async {
        // await isar.isarModels
        //     .filter()
        //     .wordsElementEqualTo('time')
        //     .or()
        //     .titleContains('a')
        //     .findAll();
        await (drift.driftModel.select()
              ..where((tbl) =>
                  tbl.words.contains('time') | tbl.title.contains('a')))
            .get();
      },
    );
  }

  @override
  Stream<int> filterSortQueryAsync(List<Model> models) {
    final idsToGet = models.map((e) => e.id).where((e) => e % 2 == 0).toList();
    return runBenchmark(
      prepare: (drift) {
        final driftModels = models.map((e) => e.driftModelCompanion).toList();
        return drift.transaction(
          () async {
            return drift.batch((batch) {
              return batch.insertAll(drift.driftModel, driftModels);
            });
          },
        );
      },
      (drift) async {
        // await isar.isarModels
        //     .filter()
        //     .archivedEqualTo(true)
        //     .sortByTitle()
        //     .findAll();
        await (drift.driftModel.select()
              ..where((tbl) => tbl.archived.equals(true))
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
            .get();
      },
    );
  }
}
