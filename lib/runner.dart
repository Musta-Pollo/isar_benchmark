import 'package:isar_benchmark/executor/executor.dart';

import 'models/model.dart';
import 'models/project.dart';

class BenchmarkRunner {
  final String directory;
  final int repetitions;

  late final Map<Database, Executor> executors = {
    for (var database in Database.values)
      database: Executor.getExecutor(database, directory, repetitions)
  };

  BenchmarkRunner(this.directory, this.repetitions);

  Stream<RunnerResult> runBenchmark(
      Benchmark benchmark, int objectCount, bool big) async* {
    final models = Model.generateModels(objectCount * 100, big);
    final projects = Project.generateProjects(objectCount, big);
    for (var i = 0; i < Database.values.length; i++) {
      final database = Database.values[i];
      final executor = executors[database]!;
      try {
        final resultStream = _exec(
          benchmark,
          executor,
          models.map((e) => e.copy).toList(),
          projects.map((e) => e.copy).toList(),
        );
        yield* resultStream
            .map((e) => RunnerResult(database, benchmark, e))
            .handleError((e) {
          print(e);
        });
      } on UnimplementedError {
        // ignore
      }

      if (i != Database.values.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Stream<int> _exec(Benchmark benchmark, Executor executor, List<Model> models,
      List<Project> projects) {
    switch (benchmark) {
      case Benchmark.insertSync:
        return executor.insertSync(models);
      case Benchmark.insertAsync:
        return executor.insertAsync(models);
      case Benchmark.getSync:
        return executor.getSync(models);
      case Benchmark.getAsync:
        return executor.getAsync(models);
      case Benchmark.deleteSync:
        return executor.deleteSync(models);
      case Benchmark.deleteAsync:
        return executor.deleteAsync(models);
      case Benchmark.filterQuerySync:
        return executor.filterQuerySync(models);
      case Benchmark.filterSortQuerySync:
        return executor.filterSortQuerySync(models);
      case Benchmark.filterQueryAsync:
        return executor.filterQueryAsync(models);
      case Benchmark.filterSortQueryAsync:
        return executor.filterSortQueryAsync(models);
      case Benchmark.dbSize:
        return executor.dbSize(models, projects);
      case Benchmark.relationshipsNToNInsertSync:
        return executor.relationshipsNToNInsertSync(models, projects);
      case Benchmark.relationshipsNToNDeleteSync:
        return executor.relationshipsNToNDeleteSync(models, projects);
      case Benchmark.relationshipsNToNFindSync:
        return executor.relationshipsNToNFindSync(models, projects);
      case Benchmark.relationshipsNToNInsertAsync:
        return executor.relationshipsNToNInsertAsync(models, projects);
      case Benchmark.relationshipsNToNDeleteAsync:
        return executor.relationshipsNToNDeleteAsync(models, projects);
      case Benchmark.relationshipsNToNFindAsync:
        return executor.relationshipsNToNFindAsync(models, projects);
    }
  }
}

class RunnerResult {
  final Database database;

  final Benchmark benchmark;

  final int value;

  const RunnerResult(this.database, this.benchmark, this.value);
}

enum Benchmark {
  insertSync('Insert Sync', 'ms'),
  insertAsync('Insert Async', 'ms'),
  getSync('Get Sync', 'ms'),
  getAsync('Get Async', 'ms'),
  deleteSync('Delete Sync', 'ms'),
  deleteAsync('Delete Async', 'ms'),
  filterQuerySync('Filter Sync', 'ms'),
  filterSortQuerySync('Filter&Sort Sync', 'ms'),
  filterQueryAsync('Filter Async', 'ms'),
  filterSortQueryAsync('Filter&Sort Async', 'ms'),

  dbSize('Database Size', 'KB'),
  relationshipsNToNInsertSync("Rel. N:N InsertSync", "ms"),
  relationshipsNToNDeleteSync("Rel. N:N DeleteSync", "ms"),
  relationshipsNToNFindSync("Rel. N:N FindSync", "ms"),
  relationshipsNToNInsertAsync("Rel. N:N InsertAsync", "ms"),
  relationshipsNToNDeleteAsync("Rel. N:N DeleteAsync", "ms"),
  relationshipsNToNFindAsync("Rel. N:N FindAsync", "ms");

  final String name;

  final String unit;

  const Benchmark(this.name, this.unit);
}
