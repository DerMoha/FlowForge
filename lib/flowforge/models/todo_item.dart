import 'task_energy_requirement.dart';

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.energyRequirement,
    required this.estimateMinutes,
  });

  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final TaskEnergyRequirement energyRequirement;
  final int estimateMinutes;

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? createdAt,
    TaskEnergyRequirement? energyRequirement,
    int? estimateMinutes,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      energyRequirement: energyRequirement ?? this.energyRequirement,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'is_done': isDone,
      'created_at': createdAt.toIso8601String(),
      'energy_requirement': energyRequirement.storageValue,
      'estimate_minutes': estimateMinutes,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawTitle = json['title'];
    final rawDone = json['is_done'];
    final rawCreatedAt = json['created_at'];
    final rawEnergyRequirement = json['energy_requirement'];
    final rawEstimateMinutes = json['estimate_minutes'];

    if (rawId is! String ||
        rawTitle is! String ||
        rawDone is! bool ||
        rawCreatedAt is! String) {
      throw const FormatException('Invalid todo payload');
    }

    final parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    if (parsedCreatedAt == null) {
      throw const FormatException('Invalid todo timestamp');
    }

    return TodoItem(
      id: rawId,
      title: rawTitle,
      isDone: rawDone,
      createdAt: parsedCreatedAt,
      energyRequirement: TaskEnergyRequirementX.fromStorageValue(
        rawEnergyRequirement is String ? rawEnergyRequirement : null,
      ),
      estimateMinutes: rawEstimateMinutes is int
          ? rawEstimateMinutes.clamp(10, 240)
          : 25,
    );
  }
}
