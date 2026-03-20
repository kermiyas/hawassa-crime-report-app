// lib/l10n/tr_extension.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'app_localizations.dart';

// Usage in any widget:
//   final tr = context.tr;
//   Text(tr.get('home'))
extension TranslationExtension on BuildContext {
  AppLocalizations get tr => read<LanguageProvider>().tr;
  AppLocalizations get trWatch => watch<LanguageProvider>().tr;
}