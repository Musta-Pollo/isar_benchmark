import 'package:drift/drift.dart';
import 'package:isar_benchmark/models/drift_models.dart';
import 'package:isar_benchmark/models/model.dart';
import 'package:isar_benchmark/models/project.dart';

extension DriftModelExtensions on Model {
  DriftModelData get driftModelData {
    return DriftModelData(id: id, title: title, archived: archived);
  }

  DriftModelCompanion get driftModelCompanion {
    return DriftModelCompanion.insert(
      title: title,
      id: id,
      archived: Value(archived),
      words: Value(words),
    );
  }
}

extension DriftProjectExtensions on Project {
  DriftProjectCompanion get driftProjectCompanion {
    return DriftProjectCompanion.insert(
      name: name,
      id: id,
    );
  }
}

extension MapExtension on ProjectModel {
  DriftProjectDriftModelCompanion get driftProjectDriftModelCompanion {
    return DriftProjectDriftModelCompanion.insert(
      projectId: projectId,
      modelId: modelId,
    );
  }
}
