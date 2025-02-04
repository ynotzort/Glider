import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:glider/utils/text_style_extension.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Error extends HookConsumerWidget {
  const Error({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double? fontSize =
        Theme.of(context).textTheme.bodyMedium?.scaledFontSize(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          children: <Widget>[
            Icon(
              FluentIcons.error_circle_24_regular,
              size: fontSize != null ? fontSize * 2 : null,
            ),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).wittyError),
          ],
        ),
      ),
    );
  }
}
