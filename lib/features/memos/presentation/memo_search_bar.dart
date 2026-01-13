import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/memo_providers.dart';

/// メモ検索バー
class MemoSearchBar extends ConsumerStatefulWidget {
  const MemoSearchBar({super.key});

  @override
  ConsumerState<MemoSearchBar> createState() => _MemoSearchBarState();
}

class _MemoSearchBarState extends ConsumerState<MemoSearchBar> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSearching) {
      return IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          setState(() {
            _isSearching = true;
          });
        },
        tooltip: '検索',
      );
    }

    return SizedBox(
      width: 200,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '検索...',
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              });
            },
          ),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }
}
