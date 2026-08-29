import 'state_machine.dart';

class StateMachineToMapConverter {
  final StateMachine stateMachine;

  List<Event> _events = const [];

  List<State> _states = const [];

  StateMachineToMapConverter({
    required this.stateMachine,
  });

  Map<String, Object> convert() {
    _events = [];
    _states = [];
    final transitions = _convertTransitions();
    final states = _convertStates();
    final events = _convertEvents();
    final map = <String, Object>{};
    _addValue(map, 'name', stateMachine.name);
    _addValue(map, 'initialState', stateMachine.initialState.name);
    _addValue(map, 'eventPrefix', stateMachine.eventPrefix);
    _addValue(map, 'eventSuffix', stateMachine.eventSuffix);
    _addValue(map, 'eventType', stateMachine.eventType);
    _addValue(map, 'statePrefix', stateMachine.statePrefix);
    _addValue(map, 'stateSuffix', stateMachine.stateSuffix);
    _addValue(map, 'stateType', stateMachine.stateType);
    _addValue(map, 'fields', stateMachine.fields);
    _addValue(map, 'globals', stateMachine.globals);
    _addValue(map, 'methods', stateMachine.methods);
    _addValue(map, 'states', states);
    _addValue(map, 'events', events);
    _addValue(map, 'transitions', transitions);
    return map;
  }

  void _addValue(Map<String, Object> map, String key, Object? value) {
    if (value == null) {
      return;
    }

    if (value is List && value.isEmpty) {
      return;
    }

    if (value is Map && value.isEmpty) {
      return;
    }

    map[key] = value;
  }

  List<Map<String, Object>> _convertEvents() {
    final result = <Map<String, Object>>[];
    for (var i = 0; i < _events.length; i++) {
      final event = _events[i];
      final map = <String, Object>{};
      _addValue(map, 'name', event.name);
      _addValue(map, 'fullName', event.fullName);
      _addValue(map, 'parameters', event.parameters);
      result.add(map);
    }

    return result;
  }

  List<Map<String, Object>> _convertStates() {
    final result = <Map<String, Object>>[];
    for (var i = 0; i < _states.length; i++) {
      final state = _states[i];
      final map = <String, Object>{};
      _addValue(map, 'name', state.name);
      _addValue(map, 'parameters', state.parameters);
      _addValue(map, 'action', state.hasAction);
      result.add(map);
    }

    return result;
  }

  List<Map<String, Object>> _convertTransitions() {
    final result = <Map<String, Object>>[];
    final transitions = stateMachine.transitions;
    for (final entry in transitions.entries) {
      final map = <String, Object>{};
      final transition = entry.value;
      final arguments = transition.arguments;
      final action = transition.action;
      final event = transition.event;
      final guard = transition.guard;
      final source = transition.source;
      final target = transition.target;
      _addValue(map, 'source', source.name);
      _addValue(map, 'event', event.name);
      _addValue(map, 'guard', guard);
      _addValue(map, 'target', target.name);
      _addValue(map, 'arguments', arguments);
      _addValue(map, 'action', action);
      _events.add(event);
      _states.add(source);
      _states.add(target);
      result.add(map);
    }

    return result;
  }
}
