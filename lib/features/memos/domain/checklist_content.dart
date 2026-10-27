import 'dart:convert';

import 'package:uuid/uuid.dart';

/// チェックリストの1項目
class ChecklistItem {
  final String id;
  final String text;
  final bool checked;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.checked = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? checked,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      checked: checked ?? this.checked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'checked': checked,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      text: json['text'] as String? ?? '',
      checked: json['checked'] as bool? ?? false,
    );
  }

  static ChecklistItem create({String text = '', bool checked = false}) {
    return ChecklistItem(
      id: const Uuid().v4(),
      text: text,
      checked: checked,
    );
  }
}

/// チェックリスト本文の JSON エンコード / デコード
class ChecklistContentCodec {
  ChecklistContentCodec._();

  /// 空のチェックリスト（項目1件）の初期 content
  static String emptyContent() {
    return encode([ChecklistItem.create()]);
  }

  static String encode(List<ChecklistItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static List<ChecklistItem> decode(String content) {
    if (content.trim().isEmpty) {
      return [ChecklistItem.create()];
    }
    try {
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return [ChecklistItem.create(text: content)];
      }
      return decoded
          .whereType<Map>()
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      // 旧通常メモが誤って checklist 扱いになった場合のフォールバック
      return [ChecklistItem.create(text: content)];
    }
  }
}
