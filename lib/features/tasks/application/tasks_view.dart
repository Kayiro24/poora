import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/providers.dart';
import 'package:poora/core/time/date_utils.dart';

enum TaskView {
  day('Day', 1),
  threeDay('3 Day', 3),
  week('Week', 7),
  month('Month', 0),
  schedule('Schedule', 0);

  TaskView(this.label, this.columns);
  final String label;
  final int columns;
}

class TasksViewState {
  const TasksViewState({
    required this.view,
    required this.selected,
    this.showCompletion = false,
    this.query = '',
  });

  final TaskView view;
  final DateTime selected;

  /// Month view overlay of completion-calendar day states (§4.11).
  final bool showCompletion;
  final String query;

  TasksViewState copyWith({
    TaskView? view,
    DateTime? selected,
    bool? showCompletion,
    String? query,
  }) => TasksViewState(
    view: view ?? this.view,
    selected: selected ?? this.selected,
    showCompletion: showCompletion ?? this.showCompletion,
    query: query ?? this.query,
  );
}

final tasksViewProvider = NotifierProvider<TasksViewController, TasksViewState>(
  TasksViewController.new,
);

class TasksViewController extends Notifier<TasksViewState> {
  @override
  TasksViewState build() =>
      TasksViewState(view: TaskView.day, selected: ref.read(todayProvider));

  void setView(TaskView v) => state = state.copyWith(view: v);
  void select(DateTime d) => state = state.copyWith(selected: Days.of(d));
  void today() => state = state.copyWith(selected: ref.read(todayProvider));
  void toggleCompletion() =>
      state = state.copyWith(showCompletion: !state.showCompletion);
  void search(String q) => state = state.copyWith(query: q);

  /// Moves by one page of the current view (day / 3 days / week / month).
  void page(int dir) {
    final s = state.selected;
    state = state.copyWith(
      selected: switch (state.view) {
        TaskView.month => DateTime.utc(s.year, s.month + dir),
        TaskView.schedule || TaskView.week => Days.add(s, 7 * dir),
        _ => Days.add(s, state.view.columns * dir),
      },
    );
  }
}
