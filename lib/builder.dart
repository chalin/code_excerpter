import 'dart:async';

import 'package:build/build.dart';

import 'package:code_excerpter/src/util/line.dart';
import 'package:code_excerpter/src/excerpter.dart';

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

    final excerpter = new Excerpter(assetId.path, content);
    final yaml = _toYaml(excerpter.weave().excerpts);
    if (yaml.isNotEmpty) {
      log.info('writing to $outputAssetId');
      buildStep.writeAsString(outputAssetId, yaml);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '': [outputExtension]
      };

  String _toYaml(Map<String, List<String>> excerpts) {
    final StringBuffer s = new StringBuffer();

    excerpts.forEach((name, lines) {
      s.writeln(_yamlEntry(name, lines));
    });
    return s.toString();
  }

  String _yamlEntry(String regionName, List<String> lines) {
    final codeAsYamlStringValue = lines
        .map((line) => '  $line') // indent by 2 spaces for YAML
        .join(eol);
    return "'$regionName': |+\n$codeAsYamlStringValue";
  }
}
