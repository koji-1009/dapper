import 'dart:io';

import 'package:dapper/dapper.dart';
import 'package:yaml/yaml.dart';

/// Loads format options from configuration files.
class ConfigLoader {
  const ConfigLoader();

  /// Loads options from `dapper.yaml` or `analysis_options.yaml`.
  ///
  /// Returns `null` if no configuration is found.
  FormatOptions? loadFromDirectory(String directoryPath) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      return null;
    }

    // Try dapper.yaml first
    final dapperConfig = File('${dir.path}/dapper.yaml');
    if (dapperConfig.existsSync()) {
      return _parseConfigFile(dapperConfig.readAsStringSync());
    }

    // Fall back to analysis_options.yaml
    final analysisOptions = File('${dir.path}/analysis_options.yaml');
    if (analysisOptions.existsSync()) {
      return _parseAnalysisOptions(analysisOptions.readAsStringSync());
    }

    return null;
  }

  FormatOptions? _parseConfigFile(String content) {
    try {
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) {
        return null;
      }
      return _parseOptionsMap(yaml);
    } catch (_) {
      return null;
    }
  }

  FormatOptions? _parseAnalysisOptions(String content) {
    try {
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) {
        return null;
      }
      final dapperBlock = yaml['dapper'];
      if (dapperBlock is! YamlMap) {
        return null;
      }
      return _parseOptionsMap(dapperBlock);
    } catch (_) {
      return null;
    }
  }

  FormatOptions? _parseOptionsMap(YamlMap map) {
    final printWidth =
        _parseInt(map['print_width']) ?? _parseInt(map['printWidth']);
    final tabWidth = _parseInt(map['tab_width']) ?? _parseInt(map['tabWidth']);
    final proseWrap =
        _parseProseWrap(map['prose_wrap']) ?? _parseProseWrap(map['proseWrap']);
    final ulStyle =
        _parseUlStyle(map['ul_style']) ?? _parseUlStyle(map['ulStyle']);

    if (printWidth == null &&
        tabWidth == null &&
        proseWrap == null &&
        ulStyle == null) {
      return null;
    }

    return FormatOptions(
      printWidth: printWidth ?? 80,
      tabWidth: tabWidth ?? 2,
      proseWrap: proseWrap ?? ProseWrap.preserve,
      ulStyle: ulStyle ?? UnorderedListStyle.asterisk,
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  ProseWrap? _parseProseWrap(dynamic value) {
    if (value is! String) return null;
    return switch (value.toLowerCase()) {
      'always' => ProseWrap.always,
      'never' => ProseWrap.never,
      'preserve' => ProseWrap.preserve,
      _ => null,
    };
  }

  UnorderedListStyle? _parseUlStyle(dynamic value) {
    if (value is! String) return null;
    return switch (value.toLowerCase()) {
      'dash' || '-' => UnorderedListStyle.dash,
      'asterisk' || '*' => UnorderedListStyle.asterisk,
      'plus' || '+' => UnorderedListStyle.plus,
      _ => null,
    };
  }
}
