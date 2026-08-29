import 'state_machine.dart';

class StatePathChecker {
  final Transitions transitions;

  final Map<String, List<String>> _paths = {};

  Set<String> _states = const {};

  StatePathChecker({
    required this.transitions,
  });

  void addPath(String name, List<String> states) {
    if (states.length < 2) {
      throw StateError('The list of states must contain at least 2 elements');
    }

    if (_paths.containsKey(name)) {
      throw StateError('Duplicate path name: $name');
    }

    _paths[name] = [...states];
  }

  void check() {
    final map = <(String, String), List<Transition>>{};
    _states = {};
    for (final entry in transitions.entries) {
      final transition = entry.value;
      final source = transition.source;
      final target = transition.target;
      _states.add(source.name);
      _states.add(target.name);
      (map[(source.name, target.name)] ??= []).add(transition);
    }

    for (final entry in _paths.entries) {
      final name = entry.key;
      final states = entry.value;
      var count = 0;
      for (var i = 1; i < states.length; i++) {
        final source = states[i - 1];
        final target = states[i];
        _checkState(source, states);
        _checkState(target, states);
        final transition = map[(source, target)];
        if (transition == null) {
          break;
        }

        count++;
      }

      if (count != states.length - 1) {
        throw StateError('''
The graph path '$name' is not complete..
Expected path: ${states.join(' -> ')}
Resolved path: ${states.take(count + 1).join(' -> ')}''');
      }
    }
  }

  void _checkState(String state, List<String> states) {
    if (!_states.contains(state)) {
      throw StateError("State '$state' not found: ${states.join(' ')}");
    }
  }
}
