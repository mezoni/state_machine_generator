typedef Transitions = Map<(State, Event, String?), Transition>;

/// [Event] is a type of data the [StateMachine] reacts to.
///
/// Also acts as a `Command` enum value if the event is not private.
class Event {
  /// The description of the `command`.
  String? description;

  /// The name of the `command`.
  String? fullName;

  /// Indicates whether the event is a command, otherwise it will be determined
  /// automatically when generating the state machine.
  ///
  /// It is recommended to explicitly specify the value only for special events
  /// (e.g. `CancelEvent`).\
  /// This will allow such events to change the logic of the states performing
  /// the actions, in particular, they will stop early at the state machine
  /// level, due to a forced transition to another state.\
  /// This approach is completely safe, since the state machine does this
  /// natively.
  ///
  /// For states that perform actions outside the state machine, the safety of
  /// such transitions must be ensured at the level of the frameworks used or in
  /// some other way.
  final bool? isCommand;

  /// The name of the [Event].
  final String name;

  /// Parameters of the [Event].
  final Map<String, String> parameters;

  Event(
    this.name, {
    this.description,
    this.fullName,
    this.isCommand,
    this.parameters = const {},
  }) {
    if (name.isEmpty) {
      throw ArgumentError('The name must not be empty');
    }
  }

  @override
  String toString() {
    return 'Event($name)';
  }
}

/// [State] represents a distinct state of the [StateMachine].
///
/// A [StateMachine] can only be in one [State] at any given time. It changes
/// from one [State] to another via transitions triggered by the [Event].
class State {
  /// Indicates that the state has an action ath ete state machine level.
  final bool hasAction;

  /// The name of the [State].
  final String name;

  /// Parameters of the [State].
  ///
  /// State parameters are intended solely for storing public data reflecting
  /// the current state. They are completely unnecessary for the proper
  /// operation of the state machine.
  ///
  /// The values ​​for the [parameters] (arguments) are automatically filled in
  /// from the arguments passed in the [Event] instance.\
  /// The mapping of parameters is performed by name.\
  /// For parameters that do not have parameters of the same name in the
  /// [Event], it is necessary to specify arguments in the [Transition].\
  /// To explicitly specify arbitrary values, the argument values ​​in the
  /// [Transition] must also be specified.
  final Map<String, String> parameters;

  State(
    this.name, {
    this.hasAction = false,
    this.parameters = const {},
  });

  @override
  int get hashCode {
    return name.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is State && name == other.name;
  }

  @override
  String toString() {
    return 'State($name)';
  }
}

/// [StateMachine] is used to describe the automaton on the basis of which the
/// source code of the state machine is generated.
class StateMachine {
  /// The name of the enum type for `Command`
  final String commandType;

  /// Type name prefix for a specific [Event] type
  final String eventPrefix;

  /// Type name suffix for a specific [Event] type
  final String eventSuffix;

  /// The name of the base type for [Event]
  final String eventType;

  /// Source code of the state machine class fields.
  String? fields;

  /// Top-level source code of the state machine library.
  String? globals;

  /// Initial state of the state machine.
  final State initialState;

  /// Source code of the state machine class methods.
  String? methods;

  /// Name of the state machine class.
  final String name;

  /// Type name prefix for a specific [State] type
  final String statePrefix;

  /// Type name suffix for a specific [State] type
  final String stateSuffix;

  /// The name of the base type for [State]
  final String stateType;

  /// Transition of the state machine.
  final Transitions transitions;

  StateMachine({
    required this.commandType,
    this.eventPrefix = '',
    this.eventSuffix = 'Event',
    required this.eventType,
    this.fields,
    this.globals,
    required this.initialState,
    this.methods,
    required this.name,
    this.statePrefix = '',
    this.stateSuffix = 'State',
    required this.stateType,
    required this.transitions,
  }) {
    if (commandType.isEmpty) {
      throw ArgumentError('The action type name must not be empty');
    }

    if (eventType.isEmpty) {
      throw ArgumentError('The event type name must not be empty');
    }

    if (stateType.isEmpty) {
      throw ArgumentError('The state type name must not be empty');
    }

    if (name.isEmpty) {
      throw ArgumentError('The name must not be empty');
    }

    if (name.isEmpty) {
      throw ArgumentError('The name must not be empty');
    }
  }

  @override
  String toString() {
    return 'StateMachine($name}';
  }
}

class Transition {
  /// Transition arguments.\
  /// The arguments specified in the transition are used to fill in the values
  /// ​of the state parameters.
  final Map<String, String> arguments;

  /// Source code of the action.
  ///
  /// The main purpose is to prepare the arguments used to create the [State]
  /// instance before transitioning to the next state.
  String? action;

  /// The event that accepts this transition.
  final Event event;

  /// Source code of the `guard` expression.
  final String? guard;

  /// The state from which the transition is performed.
  final State source;

  /// The state to which the transition is performed.
  final State target;

  Transition({
    this.action,
    this.arguments = const {},
    required this.event,
    this.guard,
    required this.source,
    required this.target,
  }) {
    _checkArguments();
  }

  @override
  int get hashCode {
    return arguments.length ^
        action.hashCode ^
        event.hashCode ^
        guard.hashCode ^
        source.hashCode ^
        target.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Transition) {
      return false;
    }

    return difference(other) != null;
  }

  (String, (Object?, Object?))? difference(Transition other) {
    if (action != other.action) {
      return ('doAction', (action, other.action));
    }

    if (event != other.event) {
      return ('event', (event, other.event));
    }

    if (guard != other.guard) {
      return ('guard', (guard, other.guard));
    }

    if (source != other.source) {
      return ('source', (source, other.source));
    }

    if (target != other.target) {
      return ('target', (target, other.target));
    }

    final map1 = arguments;
    final map2 = other.arguments;
    var isEquals = false;
    if (map1.length == map2.length) {
      isEquals = true;
      for (final entry in map1.entries) {
        final key = entry.key;
        final value = entry.value;
        final value2 = map2[key];
        if (value2 == null || value2 != value) {
          isEquals = false;
          break;
        }
      }
    }

    if (!isEquals) {
      return ('arguments', (map1, map2));
    }

    return null;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('Transition($source, $event, $target');
    if (guard != null) {
      buffer.write(', [$guard]');
    }

    buffer.write(')');
    return buffer.toString();
  }

  void _checkArguments() {
    String args2str(Map<String, String> arguments) {
      return arguments.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }

    String params2str(Map<String, String> parameters) {
      return parameters.entries.map((e) => '${e.value} ${e.key}').join(', ');
    }

    final args = {...arguments.keys};
    final inp = {...event.parameters.keys};
    final out = {...target.parameters.keys};
    final invalid = args.difference(out);
    final missing = out.difference(inp);
    if (missing.isNotEmpty) {
      final missing2 = missing.difference(args);
      if (missing2.isNotEmpty) {
        final list = target.parameters.entries
            .where((e) => missing2.contains(e.key))
            .map((e) => '${e.value} ${e.key}');
        throw StateError('''
Some arguments are missing to fill the parameters of the target state '${target.name}'.
Transition: $this
Missing arguments: ${list.join(', ')}
Target: ${target.name}(${params2str(target.parameters)})
Event: ${event.name}(${params2str(event.parameters)})
Arguments: ${args2str(arguments)}''');
      }
    }

    if (invalid.isNotEmpty) {
      throw StateError('''
Some arguments are invalid to fill the parameters of the target state '${target.name}'.
Transition: $this
Invalid arguments: ${args2str(Map.fromEntries(arguments.entries.where((e) => invalid.contains(e.key))))}
Target: ${target.name}(${params2str(target.parameters)})
Arguments: ${args2str(arguments)}''');
    }
  }
}
