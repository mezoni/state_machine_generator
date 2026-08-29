import 'dart:convert';
import 'dart:io';

import 'package:state_machine_generator/state_machine.dart';
import 'package:state_machine_generator/state_machine_builder.dart';
import 'package:state_machine_generator/state_machine_generator.dart';
import 'package:state_machine_generator/state_machine_to_map_converter.dart';
import 'package:state_machine_generator/state_machine_visualization.dart';
import 'package:state_machine_generator/state_path_checker.dart';
import 'package:yaml_writer/yaml_writer.dart';

void addStatePaths(StatePathChecker p, String source) {
  var comment = '';
  for (final line in const LineSplitter().convert(source)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    if (trimmed.startsWith('#')) {
      comment = trimmed.substring(1).trimLeft();
      continue;
    }

    final list = [...trimmed.split(' ').where((e) => e.isNotEmpty)];
    p.addPath(comment, list);
    comment = '';
  }
}

void addTransitions(StateMachineBuilder b, String source) {
  for (final line in const LineSplitter().convert(source)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    if (trimmed.startsWith('#')) {
      continue;
    }

    final list = [...trimmed.split(' ').where((e) => e.isNotEmpty)];
    final length = list.length;
    if (list.length < 3) {
      throw StateError('''
The number of elements in the processing list must not less than 3.
Processing elements: $line''');
    }

    if (length.isEven) {
      throw StateError('''
The number of elements in the processing list must be odd.
Processing elements: $line''');
    }

    for (var i = 1; i < length; i += 2) {
      if (i > length - 2) {
        break;
      }

      final source = list[i - 1];
      var event = list[i];
      final target = list[i + 1];
      if (!event.startsWith('.')) {
        throw StateError(
          "Expected '$source .$event $target' but found '$source $event $target'",
        );
      }

      event = event.substring(1);
      b.addTransition(from: source, on: event, to: target);
    }
  }
}

void writeFiles(StateMachine stateMachine, String path) {
  final source = StateMachineGenerator(
    stateMachine: stateMachine,
  ).generate();

  final dot = StateMachineToGraphvizConverter(
    stateMachine: stateMachine,
  ).convert();

  final mermaid = StateMachineToMermaidConverter(
    stateMachine: stateMachine,
  ).convert();

  final map = StateMachineToMapConverter(
    stateMachine: stateMachine,
  ).convert();

  final writer = YamlWriter();
  final yaml = writer.write(map);
  File('$path.dart').writeAsStringSync(source);
  File('$path.dot').writeAsStringSync(dot);
  File('$path.mermaid').writeAsStringSync(mermaid);
  File('$path.yaml').writeAsStringSync(yaml);
}
