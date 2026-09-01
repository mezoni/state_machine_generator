import 'state_machine.dart';

class StateMachineToMermaidConverter extends _StateMachineVisualizer {
  StateMachineToMermaidConverter({required super.stateMachine});

  @override
  void addFooter(StringBuffer buffer) {
    //
  }

  @override
  void addHeader(StringBuffer buffer) {
    buffer.writeln('stateDiagram-v2');
  }

  @override
  void addState(StringBuffer buffer, State state, {bool isInitial = false}) {
    final name = state.name;
    final label = buildStateLabel(state);
    buffer.write('  ');
    buffer.write(name);
    buffer.write(' : ');
    buffer.writeln(label.escapeMermaid);
  }

  @override
  void addTransition(StringBuffer buffer, Transition transition) {
    final source = transition.source;
    final target = transition.target;
    final label = buildTransitionLabel(transition);
    buffer.write('  ');
    buffer.write(source.name);
    buffer.write(' --> ');
    buffer.write(target.name);
    buffer.write(' : ');
    buffer.writeln(label.escapeMermaid);
  }
}

class StateMachineToGraphvizConverter extends _StateMachineVisualizer {
  StateMachineToGraphvizConverter({required super.stateMachine});

  @override
  void addFooter(StringBuffer buffer) {
    buffer.writeln('}');
  }

  @override
  void addHeader(StringBuffer buffer) {
    final name = stateMachine.name;
    buffer.writeln('digraph $name {');
  }

  @override
  void addState(StringBuffer buffer, State state, {bool isInitial = false}) {
    final name = state.name;
    final label = buildStateLabel(state);
    buffer.write('  ');
    buffer.write(name);
    buffer.write(' [ label="');
    buffer.write(label.escapeGraphviz);
    buffer.writeln('"]');
  }

  @override
  void addTransition(StringBuffer buffer, Transition transition) {
    final source = transition.source;
    final target = transition.target;
    final label = buildTransitionLabel(transition);
    buffer.write('  ');
    buffer.write(source.name);
    buffer.write(' -> ');
    buffer.write(target.name);
    buffer.write(' [label="');
    buffer.write(label.escapeGraphviz);
    buffer.writeln('"]');
  }
}

abstract class _StateMachineVisualizer {
  final StateMachine stateMachine;

  _StateMachineVisualizer({required this.stateMachine});

  void addFooter(StringBuffer buffer);

  void addHeader(StringBuffer buffer);

  void addState(StringBuffer buffer, State state, {bool isInitial = false});

  void addTransition(StringBuffer buffer, Transition transition);

  String buildStateLabel(State state) {
    final parameters = state.parameters;
    final params =
        parameters.entries.map((e) => '${e.value} ${e.key}').join(', ');
    final buffer = StringBuffer();
    buffer.write('${state.name}($params)');
    if (state.hasAction) {
      final name = state.name;
      writeAction(buffer, 'do$name()');
    }

    return buffer.toString();
  }

  String buildTransitionLabel(Transition transition) {
    final action = transition.action;
    final guard = transition.guard;
    final event = transition.event;
    final parameters = event.parameters;
    final buffer = StringBuffer();
    buffer.write(event.name);
    if (parameters.isNotEmpty) {
      final list =
          parameters.entries.map((e) => '${e.value} ${e.key}').join(', ');
      buffer.write('($list)');
    } else {
      buffer.write('()');
    }

    if (guard != null) {
      buffer.writeln();
      buffer.write('guard: [$guard]');
    }

    if (action != null) {
      writeAction(buffer, action);
    }

    return buffer.toString();
  }

  String convert() {
    final initialState = stateMachine.initialState;
    final transitions = stateMachine.transitions;
    final buffer = StringBuffer();
    final states = {initialState};
    addHeader(buffer);
    addState(buffer, initialState, isInitial: true);
    for (final entry in transitions.entries) {
      final transition = entry.value;
      final source = transition.source;
      final target = transition.target;
      if (states.add(source)) {
        addState(buffer, source);
      }

      if (states.add(target)) {
        addState(buffer, target);
      }

      addTransition(buffer, transition);
    }

    addFooter(buffer);
    return buffer.toString();
  }

  void writeAction(StringBuffer buffer, String action) {
    buffer.writeln();
    buffer.write('action: $action');
  }
}

extension on String {
  String get escapeMermaid {
    var result = this;
    result = result.replaceAll('\n', '<br/>');
    result = result.replaceAll('"', r'\"');
    result = result.replaceAll(',', r'\,');
    result = result.replaceAll(';', '#59;');
    return result;
  }

  String get escapeGraphviz {
    var result = replaceAll('"', r'\"');
    result = result.replaceAll('\n', r'\n');
    return result;
  }
}
