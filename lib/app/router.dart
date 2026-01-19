import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/genres/presentation/genre_list_screen.dart';
import '../features/memos/presentation/genre_detail_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../shared/breakpoints.dart';

/// ルーターのProvider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GenreListScreen(),
      ),
      GoRoute(
        path: '/genre/:genreId',
        builder: (context, state) {
          final genreId = int.parse(state.pathParameters['genreId']!);
          return GenreDetailScreen(genreId: genreId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

/// 2ペイン表示かどうかを判定するヘルパー
bool shouldShowTwoPane(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final orientation = MediaQuery.of(context).orientation;
  return Breakpoints.shouldShowTwoPane(
    width: width,
    isLandscape: orientation == Orientation.landscape,
  );
}
