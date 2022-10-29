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
      case Benchmark.filterQuery:
        return executor.filterQuery(models);
      case Benchmark.filterSortQuery:
        return executor.filterSortQuery(models);
      case Benchmark.dbSize:
        return executor.dbSize(models);
      case Benchmark.relationshipsNTo1Insert:
        return executor.relationshipsNTo1InsertSync(models, projects);
      case Benchmark.relationshipsNTo1Delete:
        return executor.relationshipsNTo1DeleteSync(models, projects);
      case Benchmark.relationshipsNTo1Find:
        return executor.relationshipsNTo1FindSync(models, projects);
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
  filterQuery('Filter Query', 'ms'),
  filterSortQuery('Filter & Sort Query', 'ms'),
  dbSize('Database Size', 'KB'),
  relationshipsNTo1Insert("Relationship N:1 Insert", "ms"),
  relationshipsNTo1Delete("Relationship N:1 Delete", "ms"),
  relationshipsNTo1Find("Relationship N:1 Find", "ms");

  final String name;

  final String unit;

  const Benchmark(this.name, this.unit);
}
