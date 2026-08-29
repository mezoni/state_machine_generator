import 'package:finite_automaton/binary_search_generator.dart';
import 'package:finite_automaton/codegen_mixin.dart';

import 'state_machine.dart';

class StateMachineGenerator {
  final StateMachine stateMachine;

  StateMachineGenerator({
    required this.stateMachine,
  });

  String generate() {
    return _StateMachineGenerator(
      stateMachine: stateMachine,
    ).generate();
  }
}

class _StateMachineGenerator with CodegenMixin {
  static const _templateFields = r'''
/// State action that implemented at the machine-level should subscribe to the
/// internal `cancel action event` using this variable.
///
/// A `cancel action event` always occurs if the current state performs an
/// action at the machine-level and the state machine needs to exit the
/// current state to make the transition.
///
/// The subscription must be made in the action method, each time it is
/// called.
///
/// The subscriber will be called by the state machine to notify that the
/// action needs to be cancelled.\
/// When a notification is received, the subscriber must return control to
/// the state machine as quickly as possible.
///
/// From the moment of receipt of the notification, the action must consider
/// itself cancelled.\
/// The canceled action must not trigger any events.
/// If an action performs any operations, it must asynchronously cancel these
/// operations.
///
/// Example:
///
/// ```dart
/// @override
/// void doLogging(LoginEvent e) {
///   var isCanceled = false;
///   onCancel = () => isCanceled = true;
///   Timer.run(() async {
///     try {
///       final user = await AuthService().login(e.login, e.password);
///       if (!isCanceled) {
///         processEvent(SuccessEvent(user: user, isNew: false));
///       }
///     } catch (e) {
///       if (!isCanceled) {
///         processEvent(FailureEvent(error: e));
///       }
///     }
///   });
/// }
/// ```
void Function()? onCancel;

{{State}} _state = {{InitialState}};

final List<void Function({{State}})> _stateListeners = [];
''';

  static const _templateGetters = r'''
/// Returns the current state of the state machine.
{{State}} get state => _state;
''';

  static const _templateMethods = r'''
/// Adds a listener that will be notified of changes in the [state] of the state
/// machine.
void Function() onStateChange(void Function({{State}} state) listener) {
  return _addListener<{{State}}>(_stateListeners, listener);
}

void Function() _addListener<T>(
  List<void Function(T)> listeners,
  void Function(T) listener,
) {
  listeners.add(listener);
  return () => listeners.remove(listener);
}

void _exitState() {
  final callback = onCancel;
  onCancel = null;
  if (callback != null) {
    callback();
  }
}

void _notify<T>(T event, List<void Function(T)> listeners) {
  if (listeners.isEmpty) {
    return;
  }
  final list = [...listeners];
  for (var i = 0; i < list.length; i++) {
    list[i](event);
  }
}
''';

  static const _varE = r'e';

  static const _varEvent = r'$event';

  static const _varS = r's';

  static const _varState = r'_state';

  final StateMachine stateMachine;

  final Set<Event> _commands = {};

  final Map<Event, int> _eventIndexes = {};

  final Map<State, int> _stateIndexes = {};

  _StateMachineGenerator({
    required this.stateMachine,
  });

  String generate() {
    _generate();
    final source = getSource();
    return source;
  }

  void _collectAll() {
    final states = <State>{};
    final events = <Event>{};
    final transitions = stateMachine.transitions;
    final referenced = {stateMachine.initialState};
    for (final entry in transitions.entries) {
      final transition = entry.value;
      final event = transition.event;
      final source = transition.source;
      final target = transition.target;
      states.add(source);
      events.add(event);
      states.add(target);
      referenced.add(target);
    }

    _eventIndexes.clear();
    _stateIndexes.clear();
    _eventIndexes.addAll(_createIndexes(events, (e) => e.name));
    _stateIndexes.addAll(_createIndexes(states, (e) => e.name));
  }

  Map<T, int> _createIndexes<T>(Set<T> elements, String Function(T) getName) {
    final result = <T, int>{};
    final sorted = [...elements.map((e) => (e, getName(e)))];
    sorted.sort((a, b) => a.$2.compareTo(b.$2));
    for (var i = 0; i < sorted.length; i++) {
      final value = sorted[i];
      final element = value.$1;
      result[element] = result.length;
    }

    return result;
  }

  void _determineCommands() {
    final transitions = stateMachine.transitions;
    final commands = [..._eventIndexes.keys.where((e) => e.isCommand != false)];
    for (final event in {
      ...transitions.values
          .where((e) => e.source.hasAction)
          .map((e) => e.event),
    }) {
      if (event.isCommand != true) {
        commands.remove(event);
      }
    }

    _commands.addAll(commands);
  }

  void _generate() {
    _collectAll();
    _determineCommands();
    _writeGlobals();
    _generateEnumCommand();
    _generateClassesEvent();
    _generateClassesState();
    _generateClassStateMachine();
  }

  void _generateBranchesForEvents(State state) {
    final transitions = stateMachine.transitions;
    final map = <(int, int), (Event, List<Transition>)>{};
    for (final entry in transitions.values
        .where((e) => e.source == state)
        .groupBy((e) => e.event)
        .entries) {
      final event = entry.key;
      final list = entry.value;
      final index = _eventIndexes[event]!;
      map[(index, index)] = (event, list);
    }

    void writeEvent(MapEntry<(int, int), (Event, List<Transition>)> entry) {
      final (event, list) = entry.value;
      final eventType = _getTypeOfEvent(event);
      declare('event', '$_varEvent as $eventType');
      list.sort((a, b) {
        if (a.guard == null && b.guard == null) {
          return 0;
        }

        if (a.guard == null) {
          return 1;
        }

        if (b.guard == null) {
          return -1;
        }

        return 0;
      });

      var isOpen = false;
      for (var i = 0; i < list.length; i++) {
        final transition = list[i];
        final action = transition.action;
        final arguments = transition.arguments;
        final guard = transition.guard;
        final target = transition.target;
        final targetType = _getTypeOfState(target);
        if (guard == null) {
          if (isOpen) {
            else$();
          }
        } else {
          if (!isOpen) {
            isOpen = true;
            openIf(guard);
          } else {
            elseIf(guard);
          }
        }

        if (state.hasAction) {
          stmt(r'_exitState()');
        }

        if (action != null) {
          writeln(action);
        }

        final argumentList = <String>[];
        for (final entry in target.parameters.entries) {
          final name = entry.key;
          final value = arguments[name] ?? 'event.$name';
          argumentList.add('$name: $value');
        }

        final args = argumentList.join(', ');
        final constModifier = args.isEmpty ? 'const ' : '';
        assign(_varState, '$constModifier$targetType($args)');
        if (target.hasAction) {
          final name = target.name;
          stmt('do$name(event)');
        }

        stmt('_notify($_varState, _stateListeners)');
      }
    }

    var branches = '';
    if (map.isNotEmpty) {
      branches = IfElseBinarySearchGenerator(
        callback: (entry) => capture(0, () => writeEvent(entry)),
        map: map,
        name: _varE,
      ).generate();
    }

    writeln(branches);
  }

  void _generateBranchesForStates() {
    final map = <(int, int), State>{};
    for (final entry in _stateIndexes.entries) {
      final state = entry.key;
      final index = entry.value;
      map[(index, index)] = state;
    }

    void writeState(MapEntry<(int, int), State> entry) {
      final state = entry.value;
      final name = state.name;
      writeln('// State: $name');
      _generateBranchesForEvents(state);
    }

    var branches = '';
    if (map.isNotEmpty) {
      branches = IfElseBinarySearchGenerator(
        callback: (entry) => capture(0, () => writeState(entry)),
        map: map,
        name: _varS,
      ).generate();
    }

    writeln(branches);
  }

  void _generateClassesEvent() {
    _generateSealedClasses<Event>(
      _getEventType(),
      getName: (e) => e.name,
      getParameters: (e) => e.parameters,
      getTypeOf: (e) => _getTypeOfEvent(e),
      indexes: _eventIndexes,
    );
  }

  void _generateClassesState() {
    _generateSealedClasses<State>(
      _getStateType(),
      getName: (e) => e.name,
      getParameters: (e) => e.parameters,
      getTypeOf: (e) => _getTypeOfState(e),
      indexes: _stateIndexes,
    );
  }

  void _generateClassStateMachine() {
    final name = stateMachine.name;
    openBlock('abstract class $name {');
    _generateFields();
    _generateGetters();
    _generateMethodsForStateActions();
    _generateMethodGetCommands();
    _generateMethodProcessEvent();
    _generateMethods();
    closeBlock();
    _newline();
  }

  void _generateEnumCommand() {
    final events = [..._commands];
    if (events.isEmpty) {
      return;
    }

    final name = stateMachine.name;
    final commandType = stateMachine.commandType;
    writeln(
        '/// [$commandType] a set of commands that can be used with [$name]');
    openBlock('enum $commandType {');
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final name = _getNameOfCommand(event);
      var fullName = event.fullName ?? event.name;
      fullName = fullName.replaceAll('\n', r'\n');
      fullName = fullName.replaceAll("'", r"\'");
      fullName = fullName.replaceAll('\$', r'\$');
      final element = "$name('$fullName')";
      if (i != events.length - 1) {
        writeln('$element,');
      } else {
        writeln('$element;');
      }
    }

    _newline();
    stmt('const $commandType(this.fullName)');
    _newline();
    declare('fullName', null, type: 'String');

    closeBlock();
    _newline();
  }

  void _generateFields() {
    final initialState = stateMachine.initialState;
    final eventType = _getEventType();
    final stateType = _getStateType();
    final fields = stateMachine.fields;
    if (initialState.hasAction) {
      throw StateError('Initial state must not have action');
    }

    if (initialState.parameters.isNotEmpty) {
      throw StateError(
        'In the initial state there should be no parameters specified',
      );
    }

    final initialStateType = _getTypeOfState(initialState);
    var template = _templateFields.replaceAll('{{State}}', stateType);
    template = template.replaceAll('{{Event}}', eventType);
    template =
        template.replaceAll('{{InitialState}}', 'const $initialStateType()');
    writeln(template.trimRight());
    _newline();
    if (fields != null) {
      writeln(fields.trimRight());
      _newline();
    }
  }

  void _generateGetters() {
    final stateType = _getStateType();
    final template = _templateGetters.replaceAll('{{State}}', stateType);
    writeln(template.trimRight());
    _newline();
  }

  void _generateMethodGetCommands() {
    final actionType = stateMachine.commandType;
    final stateType = stateMachine.stateType;
    final transitions = stateMachine.transitions;
    openFunction(
      name: 'getCommands',
      returnType: 'List<$actionType>',
      positional: [(stateType, 'state')],
    );

    final map = <(int, int), (State, List<Transition>)>{};
    for (final entry in transitions.values
        .where((e) => _commands.contains(e.event))
        .groupBy((e) => e.source)
        .entries) {
      final state = entry.key;
      final list = entry.value;
      final index = _stateIndexes[state]!;
      map[(index, index)] = (state, list);
    }

    void writeState(MapEntry<(int, int), (State, List<Transition>)> entry) {
      final value = entry.value;
      final state = value.$1;
      final transitions = value.$2;
      final events = transitions.map((e) => e.event);
      final list =
          events.map((e) => '$actionType.${_getNameOfCommand(e)}').join(', ');
      writeln('// State: ${state.name}');
      return$('const [$list]');
    }

    var branches = '';
    if (map.isNotEmpty) {
      branches = IfElseBinarySearchGenerator(
        callback: (entry) => capture(0, () => writeState(entry)),
        map: map,
        name: 's',
      ).generate();
    }

    declare('s', 'state.\$index');
    writeln(branches);
    return$('const []');

    closeBlock();
    _newline();
  }

  void _generateMethodProcessEvent() {
    final eventType = _getEventType();

    writeln('''
/// Evaluates current state against received event, determines what action
/// to take and which state to transition to next.''');
    openFunction(
      name: 'processEvent',
      returnType: 'void',
      positional: [(eventType, 'event')],
    );
    declare(_varEvent, 'event');
    declare(_varE, 'event.\$index');
    declare(_varS, '$_varState.\$index');
    _generateBranchesForStates();

    closeBlock();
    _newline();
  }

  void _generateMethods() {
    final eventType = _getEventType();
    final stateType = _getStateType();
    final methods = stateMachine.methods;
    var template = _templateMethods.replaceAll('{{State}}', stateType);
    template = template.replaceAll('{{Event}}', eventType);
    writeln(template.trimRight());
    _newline();
    if (methods != null) {
      writeln(methods);
      _newline();
    }
  }

  void _generateMethodsForStateActions() {
    final transitions = stateMachine.transitions;
    final map = transitions.values
        .where((e) => e.target.hasAction)
        .groupBy((e) => e.target);
    for (final entry in map.entries) {
      final target = entry.key;
      final transitions = entry.value;
      final events = [...transitions.map((e) => e.event)];
      if (events.length > 1) {
        throw StateError('''
Failed to determine state action method signature. Found state transitions via different events.
Target state: ${target.name}
Events: ${events.map((e) => e.name).join(',')}''');
      }

      final event = events.first;
      final eventType = _getTypeOfEvent(event);
      final name = target.name;
      final methodName = 'do$name';
      stmt('void $methodName($eventType event)');
      _newline();
    }
  }

  void _generateSealedClasses<T>(
    String baseType, {
    required String Function(T) getName,
    required Map<String, String> Function(T) getParameters,
    required String Function(T) getTypeOf,
    required Map<T, int> indexes,
  }) {
    openBlock('sealed class $baseType {');
    stmt('const $baseType()');
    _newline();
    stmt('int get \$index');

    closeBlock();
    _newline();

    for (final element in indexes.keys) {
      final className = getTypeOf(element);
      final index = indexes[element];
      final parameters = getParameters(element).entries;
      openBlock('final class $className extends $baseType {');
      for (final parameter in parameters) {
        final name = parameter.key;
        final type = parameter.value;
        declare(name, null, type: type);
        _newline();
      }

      if (parameters.isEmpty) {
        stmt('const $className()');
      } else if (parameters.length == 1) {
        final parameter = parameters.first;
        final name = parameter.key;
        stmt('const $className({required this.$name})');
      } else {
        openBlock('const $className({');
        for (final parameter in parameters) {
          final name = parameter.key;
          writeln('required this.$name,');
        }

        closeBlock('});');
      }

      _newline();
      writeln('@override');
      stmt('int get \$index => $index');
      _newline();
      writeln('@override');
      stmt("String toString() => '${getName(element)}'");

      closeBlock();
      _newline();
    }
  }

  String _getEventType() {
    final eventType = stateMachine.eventType;
    return eventType;
  }

  String _getNameOfCommand(Event event) {
    final eventName = event.name;
    return eventName[0].toLowerCase() + eventName.substring(1);
  }

  String _getStateType() {
    final stateType = stateMachine.stateType;
    return stateType;
  }

  String _getTypeOfEvent(Event event) {
    final prefix = stateMachine.eventPrefix;
    final suffix = stateMachine.eventSuffix;
    final name = event.name;
    return '$prefix$name$suffix';
  }

  String _getTypeOfState(State state) {
    final prefix = stateMachine.statePrefix;
    final suffix = stateMachine.stateSuffix;
    final name = state.name;
    return '$prefix$name$suffix';
  }

  void _newline() {
    writeRawString('\n');
  }

  void _writeGlobals() {
    final globals = stateMachine.globals;
    if (globals == null) {
      return;
    }

    writeln(globals.trimRight());
    _newline();
  }
}

extension<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E element) keySelector) {
    final map = <K, List<E>>{};
    for (var element in this) {
      (map[keySelector(element)] ??= []).add(element);
    }

    return map;
  }
}
