import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// assuming that your file is called filename.dart. This will give an error at
// first, but it's needed for drift to know about the generated code
part 'drift_models.g.dart';

// this will generate a table called "todos" for us. The rows of that table will
// be represented by a class called "Todo".
class DriftModel extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get words => text().map(const WordsConverter()).nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

class WordsConverter extends TypeConverter<List<String>, String> {
  const WordsConverter();

  @override
  List<String> fromSql(String fromDb) {
    return fromDb.split(";");
  }

  @override
  String toSql(List<String> value) {
    return value.join(';');
  }
}

// This will make drift generate a class called "Category" to represent a row in
// this table. By default, "Categorie" would have been used because it only
//strips away the trailing "s" in the table name.
class DriftProject extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
}

class DriftProjectDriftModel extends Table {
  IntColumn get modelId => integer().references(DriftModel, #id)();
  // id of the item in this cart
  IntColumn get projectId => integer().references(DriftProject, #id)();
  // again, we could store additional information like when the item was
  // added, an amount, etc.
}

// this annotation tells drift to prepare a database class that uses both of the
// tables we just defined. We'll see how to use that database class in a moment.
@DriftDatabase(tables: [DriftProject, DriftModel, DriftProjectDriftModel])
class Drift extends _$Drift {
  final String directory;
  Drift(this.directory) : super(_openConnection(directory));

  String get storeDirectory => '$directory/db.sqlite';

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection(String directory) {
  final store = '$directory/db.sqlite';
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final file = File(store);
    return NativeDatabase(file);
  });
}

class ProjectModel {
  final int projectId;
  final int modelId;
  ProjectModel({
    required this.projectId,
    required this.modelId,
  });
}

  // final int id;

  // final String title;

  // final List<String> words;

  // final bool archived;