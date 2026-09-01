import 'package:state_machine_generator/state_machine.dart';
import 'package:state_machine_generator/state_machine_builder.dart';
import 'package:state_machine_generator/state_path_checker.dart';

import '_build_utils.dart';

void main(List<String> args) {
  const initialStateName = 'NotLogged';
  final b = StateMachineBuilder(
    initialState: initialStateName,
  );

  b.addState('Failure', parameters: {'error': 'Object'});
  b.addState('Logged', parameters: {'user': 'User', 'isNew': 'bool'});
  b.addState('Login', hasAction: true);
  b.addState('Logout', hasAction: true);
  b.addState('NotLogged');
  b.addState('Register', hasAction: true);
  b.addState('Terminated');

  b.addEvent('Cancel', isCommand: true);
  b.addEvent('Exit');
  b.addEvent('Failure', parameters: {'error': 'Object'});
  b.addEvent('Login', parameters: {'login': 'String', 'password': 'String'});
  b.addEvent('Logout', parameters: {'user': 'User?'});
  b.addEvent('LoggedOut');
  b.addEvent('Register', parameters: {'login': 'String', 'password': 'String'});
  b.addEvent('Retry');
  b.addEvent('Success', parameters: {'user': 'User', 'isNew': 'bool'});

  const transitionSource = '''
# Login successful
NotLogged .Login Login .Success Logged

# Login failed
NotLogged .Login Login .Failure Failure

# Registering successful
NotLogged .Register Register .Success Logged

# Registering failed
NotLogged .Register Register .Failure Failure

# Logout
Logged .Logout Logout .LoggedOut NotLogged

# Retry
Failure .Retry NotLogged
''';

  const pathSource = '''
# Login succeeded
NotLogged Login Logged

# Login failed
NotLogged Login Failure NotLogged

# Registration succeeded
NotLogged Register Logged

# Registration failed
NotLogged Register Failure NotLogged

#  Logout
Logged Logout NotLogged

# Reset
Failure NotLogged
''';

  addTransitions(b, transitionSource);

  // Example of adding 'terminated' state
  const terminated = 'Terminated';
  // Exclude states that execute actions at the state machine level.
  final excludedStates = b.transitions.values
      .where((e) => e.source.hasAction)
      .map((e) => e.source.name)
      .toSet();
  for (final state in b.states) {
    final name = state.name;
    if (name == terminated || excludedStates.contains(name)) {
      continue;
    }

    b.addTransition(from: name, on: 'Exit', to: terminated);
  }

  // Example of adding 'cancel' event
  const cancel = 'Cancel';
  // Add for states that execute actions at the state machine level.
  for (final state in excludedStates) {
    b.addTransition(from: state, on: cancel, to: initialStateName);
  }

  final (:initialState, :transitions) = b.build();

  final pathChecker = StatePathChecker(transitions: transitions);
  addStatePaths(pathChecker, pathSource);
  pathChecker.check();

  const name = 'Auth';
  final stateMachine = StateMachine(
    commandType: '${name}Command',
    eventType: '${name}Event',
    globals: _globals,
    initialState: initialState,
    name: '${name}Machine',
    stateType: '${name}State',
    transitions: transitions,
  );

  writeFiles(stateMachine, 'example/example');
}

const _globals = '''
// ignore_for_file: unused_local_variable
import '_auth_service.dart';
''';
