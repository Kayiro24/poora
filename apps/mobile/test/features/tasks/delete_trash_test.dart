import 'package:flutter_test/flutter_test.dart';
import 'package:poora/core/db/daos/tasks_dao.dart';
import 'package:poora/core/db/database.dart';
import 'package:poora/core/time/clock.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/features/tasks/data/tasks_repository.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/occurrence_generator.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';
import 'package:poora/features/tasks/domain/series_edits.dart';

void main() {
  late AppDatabase db;
  late TasksDao dao;
  late TasksRepository repo;
  late FakeClock clock;
  final gen = OccurrenceGenerator(mondayFirst: true);
  final start = Days.ymd(2026, 10, 19);
  final today = Days.ymd(2026, 10, 21);

  Task task(String id, RepeatRule rule) => rule.applyTo(
    Task(
      id: id,
      title: id,
      color: 0xFFEF7867,
      startDate: start,
      seriesId: id,
      createdAt: DateTime(2026, 10, 19),
      updatedAt: DateTime(2026, 10, 19),
      startMinute: 540,
      durationMin: 30,
    ),
  );

  Future<List<Occurrence>> occ() async =>
      gen.generate(snapshot: await dao.loadSnapshot(), range: DateRange(start, Days.add(start, 6)), today: today);
  Future<Occurrence> at(String id, DateTime d) async =>
      (await occ()).firstWhere((o) => o.task.id == id && o.originalDate == d);

  setUp(() {
    db = AppDatabase.memory();
    dao = TasksDao(db);
    clock = FakeClock(DateTime(2026, 10, 21, 10));
    repo = TasksRepository(dao: dao, clock: clock, generator: () => gen);
  });
  tearDown(() => db.close());

  test('one-off: delete moves to Trash; undo restores', () async {
    await repo.create(task('a', RepeatRule.none));
    final undo = await repo.delete(await at('a', start));
    expect(await occ(), isEmpty);
    expect((await dao.watchDeleted().first).single.id, 'a');
    await undo();
    expect((await occ()).single.task.id, 'a');
    expect(await dao.watchDeleted().first, isEmpty);
  });

  test('recurring "This task" removes one occurrence; undo brings it back', () async {
    await repo.create(task('d', RepeatRule.daily()));
    final undo = await repo.delete(await at('d', Days.add(start, 2)), scope: EditScope.thisOne);
    expect((await occ()).map((o) => o.date), isNot(contains(Days.add(start, 2))));
    expect((await occ()).length, 6);
    await undo();
    expect((await occ()).length, 7);
  });

  test('"This task" undo keeps a completion that existed before', () async {
    await repo.create(task('d', RepeatRule.daily()));
    await repo.setDone(await at('d', start), done: true);
    final undo = await repo.delete(await at('d', start), scope: EditScope.thisOne);
    await undo();
    expect((await at('d', start)).status, OccurrenceStatus.done);
  });

  test('"This and following" ends the series; undo restores it', () async {
    await repo.create(task('d', RepeatRule.daily()));
    final undo = await repo.delete(await at('d', Days.add(start, 3)), scope: EditScope.thisAndFollowing);
    expect((await occ()).length, 3);
    await undo();
    expect((await occ()).length, 7);
  });

  test('"All tasks" trashes the whole series', () async {
    await repo.create(task('d', RepeatRule.daily()));
    await repo.delete(await at('d', Days.add(start, 3)));
    expect(await occ(), isEmpty);
  });

  test('Trash: restore, delete forever and 30-day purge', () async {
    await repo.create(task('a', RepeatRule.none));
    await repo.create(task('b', RepeatRule.none));
    await repo.delete(await at('a', start));
    await repo.delete(await at('b', start));
    await repo.restore('a');
    expect((await occ()).single.task.id, 'a');
    await repo.deleteForever('b');
    expect(await dao.watchDeleted().first, isEmpty);
    expect((await dao.loadSnapshot(includeDeleted: true)).tasks.map((t) => t.id), ['a']);

    await repo.delete(await at('a', start));
    clock.advance(const Duration(days: 29));
    await repo.purgeOldTrash();
    expect((await dao.watchDeleted().first).length, 1);
    clock.advance(const Duration(days: 2));
    await repo.purgeOldTrash();
    expect(await dao.watchDeleted().first, isEmpty);
  });
}
