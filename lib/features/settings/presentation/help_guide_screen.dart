import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/help_guide.dart';

/// 設定から開く使い方画面
/// タイトル一覧から、調べたい操作を選んで読める構成
class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        title: const Text(
          HelpGuide.title,
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            '調べたい操作を選んでください',
            style: TextStyle(
              fontSize: 14.0,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...HelpGuide.sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.surface,
                borderRadius: AppColors.borderRadius,
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    iconColor: AppColors.inkSecondary,
                    collapsedIconColor: AppColors.inkTertiary,
                    title: Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          section.body,
                          style: const TextStyle(
                            fontSize: 15.0,
                            height: 1.55,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
