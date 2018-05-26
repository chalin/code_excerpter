import 'dart:async';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

import 'src/util.dart';

Builder builder(BuilderOptions options) => new CodeExcerptBuilder(options);

class CodeExcerptBuilder implements Builder {
  final outputExtension = '.yaml';

  BuilderOptions options;

  CodeExcerptBuilder(this.options);

  @override
  Future<void> build(BuildStep buildStep) async {
    AssetId assetId = buildStep.inputId;
    if (assetId.path.endsWith(r'$')) return;

    final content = await buildStep.readAsString(assetId);
    final outputAssetId = assetId.addExtension(outputExtension);

    // TODO: remove temp code
    if (assetId.path.contains('src')) return;

    log.info('>> writing to $outputAssetId');
    final yaml = _yamlEntry('', content);
    final reparsedYaml = loadYaml(yaml);
    // log.info('>> c == z[""]? ${reparsedYaml[''] == '$content'}');
    buildStep.writeAsString(outputAssetId, yaml);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '': [outputExtension]
      };

  String _yamlEntry(String regionName, String excerpt) {
    final lines = excerpt.split(eol);
    dropTrailingBlankLines(lines);
    final codeAsYamlStringValue =
        maxUnindent(lines) // normalize/left-shift indentation
            .map((line) => '  $line') // indent by 2 spaces for YAML
            .join(eol);
    return "'$regionName': |+\n$codeAsYamlStringValue";
  }
}
