import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SpeechLanguage { english, hindi, both }

class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.fontScale = 1,
    this.speechLanguage = SpeechLanguage.both,
    this.apiBaseUrl = 'http://10.0.2.2:8000',
  });
  final bool darkMode;
  final double fontScale;
  final SpeechLanguage speechLanguage;
  final String apiBaseUrl;
  AppSettings copyWith({
    bool? darkMode,
    double? fontScale,
    SpeechLanguage? speechLanguage,
    String? apiBaseUrl,
  }) => AppSettings(
    darkMode: darkMode ?? this.darkMode,
    fontScale: fontScale ?? this.fontScale,
    speechLanguage: speechLanguage ?? this.speechLanguage,
    apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();
  void update(AppSettings value) => state = value;
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
