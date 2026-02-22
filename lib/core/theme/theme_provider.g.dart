// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemeSettings)
final themeSettingsProvider = ThemeSettingsProvider._();

final class ThemeSettingsProvider
    extends $NotifierProvider<ThemeSettings, ThemeMode> {
  ThemeSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeSettingsHash();

  @$internal
  @override
  ThemeSettings create() => ThemeSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeSettingsHash() => r'0068911c21a7ab7db6be32db790d2c8426d70c4d';

abstract class _$ThemeSettings extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
