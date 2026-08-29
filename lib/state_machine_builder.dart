import 'dart:collection';

import 'state_machine.dart';

class StateMachineBuilder {
  final Map<String, Event> _events = {};

  final Map<String, State> _states = {};

  final Transitions _transitions = {};

  final String initialState;

  StateMachineBuilder({
    required this.initialState,
  });

  List<Event> get events {
    return UnmodifiableListView(_events.values.toList());
  }

  List<State> get states {
    return UnmodifiableListView(_states.values.toList());
  }

  Transitions get transitions {
    return UnmodifiableMapView(_transitions);
  }

  Event addEvent(
    String name, {
    String? description,
    String? fillName,
    bool? isCommand,
    Map<String, String> parameters = const {},
  }) {
    if (_events.containsKey(name)) {
      throw StateError('Duplicate event name: $name');
    }

    final event = Event(
      name,
      description: description,
      fullName: fillName,
      isCommand: isCommand,
      parameters: parameters,
    );
    _events[name] = event;
    return event;
  }

  State addState(
    String name, {
    bool hasAction = false,
    Map<String, String> parameters = const {},
  }) {
    if (_states.containsKey(name)) {
      throw StateError('Duplicate state name: $name');
    }

    final state = State(name, hasAction: hasAction, parameters: parameters);
    _states[name] = state;
    return state;
  }

  Transition addTransition({
    Map<String, String> arguments = const {},
    String? action,
    required String from,
    String? guard,
    required String on,
    required String to,
  }) {
    final event = getEvent(on);
    final source = getState(from);
    final target = getState(to);
    final transition = Transition(
      arguments: arguments,
      action: action,
      event: event,
      guard: guard,
      source: source,
      target: target,
    );
    final key = (source, event, guard);
    final found = _transitions[key];
    if (found != null) {
      final difference = found.difference(transition);
      if (difference != null) {
        throw StateError('''
A conflict was detected while adding the transition.
Transition key: ($source, $event, $guard)
Conflicting values: ${difference.$1}
Exist value: ${difference.$2.$1}
New value: ${difference.$2.$2} ''');
      }
    }

    _transitions[key] = transition;
    return transition;
  }

  ({State initialState, Transitions transitions}) build() {
    final usedEvents = <String>{};
    final usedStates = <String>{};
    final fromState = <State, Set<Event>>{};
    final toState = <State, Set<Event>>{};
    final initialState = _states[this.initialState];
    if (initialState == null) {
      throw StateError('Initial state not defined: ${this.initialState}');
    }

    usedStates.add(initialState.name);
    for (final entry in _transitions.entries) {
      final transition = entry.value;
      final event = transition.event;
      final source = transition.source;
      final target = transition.target;
      usedEvents.add(event.name);
      usedStates.add(source.name);
      usedStates.add(target.name);
      (fromState[source] ??= {}).add(event);
      (toState[target] ??= {}).add(event);
    }

    final unusedEvents = {..._events.keys}.difference(usedEvents);
    if (unusedEvents.isNotEmpty) {
      throw StateError('Found unreferenced events: ${unusedEvents.join(', ')}');
    }

    final unusedStates = {..._states.keys}.difference(usedStates);
    if (unusedStates.isNotEmpty) {
      throw StateError('Found unreferenced states: ${unusedStates.join(', ')}');
    }

    return (initialState: initialState, transitions: _transitions);
  }

  Event getEvent(String name) {
    final event = _events[name];
    if (event == null) {
      throw StateError('Event not found: $name');
    }

    return event;
  }

  State getState(String name) {
    final state = _states[name];
    if (state == null) {
      throw StateError('State not found: $name');
    }

    return state;
  }
}
