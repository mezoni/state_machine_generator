import 'state_machine.dart';

void _sortTable(List<List<String>> table) {
  table.sort((a, b) {
    final minLength = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLength; i++) {
      final comparison = a[i].compareTo(b[i]);
      if (comparison != 0) {
        return comparison;
      }
    }

    return a.length.compareTo(b.length);
  });
}

class StateMachineToEventTableConverter {
  final StateMachine stateMachine;

  StateMachineToEventTableConverter({required this.stateMachine});

  List<List<String>> convert() {
    final transitions = stateMachine.transitions;
    final eventSet = <Event>{};
    for (final transition in transitions.values) {
      final event = transition.event;
      eventSet.add(event);
    }

    final events = eventSet.toList();
    events.sort((a, b) => a.name.compareTo(b.name));
    final table = [
      ['name', 'isCommand', 'parameters', 'fullName', 'description'],
    ];
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final description = event.description ?? '';
      final fullName = event.fullName ?? '';
      final isCommand =
          event.isCommand == null ? '' : event.isCommand.toString();
      final name = event.name;
      final parameters = event.parameters.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      final row = <String>[
        name,
        isCommand,
        parameters,
        fullName,
        description,
      ];
      table.add(row);
    }

    return table;
  }
}

class StateMachineToStateMatrixTableConverter {
  final StateMachine stateMachine;

  StateMachineToStateMatrixTableConverter({required this.stateMachine});

  List<List<String>> convert() {
    final transitions = stateMachine.transitions;
    final matrix = <String, Map<String, String>>{};
    final stateSet = <String>{};
    for (final transition in transitions.values) {
      final source = transition.source;
      final target = transition.target;
      stateSet.add(source.name);
      stateSet.add(target.name);
    }

    final states = stateSet.toList();
    states.sort();
    for (var i = 0; i < states.length; i++) {
      final state = states[i];
      matrix[state] ??= {};
    }

    for (final transition in transitions.values) {
      final event = transition.event;
      final guard = transition.guard;
      final source = transition.source;
      final target = transition.target;
      final row = matrix[source.name] ??= {};
      final buffer = StringBuffer();
      buffer.write(event.name);
      if (guard != null) {
        buffer.write(' [$guard]');
      }

      row[target.name] = buffer.toString();
    }

    final result = <List<String>>[];
    final header = ['Current/Next', ...states];
    result.add(header);
    for (var i = 0; i < states.length; i++) {
      final current = states[i];
      final row = List.filled(states.length + 1, '');
      final matrixRow = matrix[current] ?? {};
      result.add(row);
      row[0] = current;
      for (var j = 0; j < states.length; j++) {
        final next = states[j];
        final value = matrixRow[next] ?? '';
        row[j + 1] = value;
      }
    }

    return result;
  }
}

class StateMachineToStateTableConverter {
  final StateMachine stateMachine;

  StateMachineToStateTableConverter({required this.stateMachine});

  List<List<String>> convert() {
    final transitions = stateMachine.transitions;
    final stateSet = <State>{};
    for (final transition in transitions.values) {
      final source = transition.source;
      final target = transition.target;
      stateSet.add(source);
      stateSet.add(target);
    }

    final states = stateSet.toList();
    states.sort((a, b) => a.name.compareTo(b.name));
    final table = [
      ['name', 'hasAction', 'parameters'],
    ];
    for (var i = 0; i < states.length; i++) {
      final state = states[i];
      final name = state.name;
      final hasAction = state.hasAction ? 'true' : '';
      final parameters = state.parameters.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      final row = <String>[
        name,
        hasAction,
        parameters,
      ];
      table.add(row);
    }

    return table;
  }
}

class StateMachineToTransitionTableConverter {
  final StateMachine stateMachine;

  StateMachineToTransitionTableConverter({required this.stateMachine});

  List<List<String>> convert() {
    final transitions = stateMachine.transitions;
    final rows = <List<String>>[];
    for (final transition in transitions.values) {
      final action = transition.action;
      final guard = transition.guard;
      final event = transition.event;
      final source = transition.source;
      final target = transition.target;
      final row = <String>[
        source.name,
        event.name,
        target.name,
        guard ?? '',
        action ?? '',
      ];
      rows.add(row);
    }

    _sortTable(rows);
    final table = [
      ['source', 'event', 'target', 'guard', 'action'],
      ...rows,
    ];

    return table;
  }
}
