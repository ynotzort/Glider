import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/widgets.dart';
import 'package:glider/utils/animation_util.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext, T, int);
typedef EqualityChecker<T> = bool Function(T, T);

class SliverSmoothAnimatedList<T> extends StatefulHookConsumerWidget {
  SliverSmoothAnimatedList({
    super.key,
    required Iterable<T> items,
    required ItemBuilder<T> builder,
    this.equalityChecker,
  })  : items = items.toList(growable: false),
        builder = ((BuildContext context, T item, int index,
                Animation<double> animation) =>
            AnimationUtil.verticalFadeTransitionBuilder(
              builder(context, item, index),
              CurvedAnimation(
                parent: animation,
                curve: AnimationUtil.defaultCurve,
              ),
            ));

  final List<T> items;
  final Widget Function(BuildContext, T, int, Animation<double>) builder;
  final EqualityChecker<T>? equalityChecker;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SliverSmoothAnimatedListState<T>();
}

class _SliverSmoothAnimatedListState<T>
    extends ConsumerState<SliverSmoothAnimatedList<T>> {
  final GlobalKey<SliverAnimatedListState> listKey =
      GlobalKey<SliverAnimatedListState>();

  late List<T> oldList;

  @override
  void initState() {
    oldList = List<T>.from(widget.items);
    super.initState();
  }

  @override
  void didUpdateWidget(SliverSmoothAnimatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<T> newList = widget.items;
    final Iterable<DiffUpdate> diff = calculateListDiff<T>(
      oldList,
      newList,
      detectMoves: false,
      equalityChecker: widget.equalityChecker,
    ).getUpdates();

    final List<T?> tempList = List<T?>.from(oldList);

    for (final DiffUpdate update in diff) {
      _onDiffUpdate(update, tempList);
    }

    oldList = List<T>.from(newList);
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: listKey,
      itemBuilder:
          (BuildContext context, int index, Animation<double> animation) =>
              widget.builder(context, widget.items[index], index, animation),
      initialItemCount: widget.items.length,
    );
  }

  void _onDiffUpdate(DiffUpdate update, List<T?> tempList) {
    update.when<void>(
      insert: (int pos, int count) => _onInserted(pos, count, tempList),
      remove: (int pos, int count) => _onRemoved(pos, count, tempList),
      change: (int pos, Object? payload) => _onChanged(pos, payload, tempList),
      move: _onMoved,
    );
  }

  void _onInserted(int position, int count, List<T?> tempList) {
    for (int index = position; index < position + count; index++) {
      listKey.currentState!.insertItem(
        index,
        // ignore: avoid_redundant_argument_values
        duration: AnimationUtil.defaultDuration,
      );
    }
    tempList.insertAll(position, List<T?>.filled(count, null));
  }

  void _onRemoved(int position, int count, List<T?> tempList) {
    for (int index = position; index < position + count; index++) {
      final T oldItem = tempList[index] as T;
      listKey.currentState!.removeItem(
        position,
        (BuildContext context, Animation<double> animation) =>
            widget.builder(context, oldItem, index, animation),
        // ignore: avoid_redundant_argument_values
        duration: AnimationUtil.defaultDuration,
      );
    }
    tempList.removeRange(position, position + count);
  }

  void _onChanged(int position, Object? payload, List<T?> tempList) {
    listKey.currentState!.removeItem(
      position,
      (BuildContext context, Animation<double> animation) =>
          const SizedBox.shrink(),
      duration: Duration.zero,
    );
    _onInserted(position, 1, tempList);
  }

  void _onMoved(int from, int to) =>
      throw UnimplementedError('Moves are currently not supported');
}
