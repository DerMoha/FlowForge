/// Status of a task in the kanban workflow.
enum TaskStatus { backlog, today, done }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.backlog:
        return 'Backlog';
      case TaskStatus.today:
        return 'Today';
      case TaskStatus.done:
        return 'Done';
    }
  }

  String get storageValue => name;

  static TaskStatus fromStorageValue(String? value) {
    for (final status in TaskStatus.values) {
      if (status.storageValue == value) {
        return status;
      }
    }
    return TaskStatus.backlog;
  }
}
