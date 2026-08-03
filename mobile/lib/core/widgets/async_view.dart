import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/api_exception.dart';
import 'state_views.dart';

/// Renders an [AsyncValue] with consistent loading / error / empty / data
/// states and wires pull-to-refresh to a provider refresh.
///
/// Every list screen in the app goes through this so the three states are never
/// forgotten and refresh behaves identically everywhere.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.builder,
    this.isEmpty,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage = 'There is no data to show right now.',
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.loadingMessage,
  });

  final AsyncValue<T> value;
  final Future<void> Function() onRefresh;
  final Widget Function(T data) builder;

  /// Return true when [T] holds no rows — drives the empty state.
  final bool Function(T data)? isEmpty;

  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => LoadingView(message: loadingMessage),
      error: (Object error, StackTrace _) => _Scrollable(
        onRefresh: onRefresh,
        child: ErrorView(
          message: error is ApiException
              ? error.detailedMessage
              : 'Unexpected error: $error',
          onRetry: onRefresh,
        ),
      ),
      data: (T data) {
        final bool empty = isEmpty?.call(data) ?? false;
        if (empty) {
          return _Scrollable(
            onRefresh: onRefresh,
            child: EmptyView(
              title: emptyTitle,
              message: emptyMessage,
              icon: emptyIcon,
              actionLabel: emptyActionLabel,
              onAction: onEmptyAction,
            ),
          );
        }
        return RefreshIndicator(onRefresh: onRefresh, child: builder(data));
      },
    );
  }
}

/// Keeps empty/error states pullable by giving them a scrollable viewport.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
