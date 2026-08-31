import 'package:state_machine_generator/state_machine.dart';
import 'package:state_machine_generator/state_machine_builder.dart';
import 'package:state_machine_generator/state_path_checker.dart';

import '_build_utils.dart';

void main(List<String> args) {
  const initialStateName = 'Draft';
  final b = StateMachineBuilder(
    initialState: initialStateName,
  );

  b.addState('Approved');
  b.addState('ChangeRequested');
  b.addState('Declined');
  b.addState('Draft');
  b.addState('Review');
  b.addState('SubmittedToClient');

  b.addEvent('Accept');
  b.addEvent('Approve');
  b.addEvent('BeginReview');
  b.addEvent('ChangeNeeded');
  b.addEvent('Decline');
  b.addEvent('Reject');
  b.addEvent('RestartReview');
  b.addEvent('Submit');
  b.addEvent('UpdateDocument');

  const transitionSource = '''
ChangeRequested .Accept Draft
ChangeRequested .Reject Review
Declined  .RestartReview Review
Draft .BeginReview Review
Draft .UpdateDocument Draft
Review .ChangeNeeded ChangeRequested
Review .Submit SubmittedToClient
SubmittedToClient .Approve Approved
SubmittedToClient .Decline Declined
''';

  const pathSource = '''
''';

  addTransitions(b, transitionSource);

  final (:initialState, :transitions) = b.build();

  final pathChecker = StatePathChecker(transitions: transitions);
  addStatePaths(pathChecker, pathSource);
  pathChecker.check();

  const name = 'Document';
  final stateMachine = StateMachine(
    commandType: '${name}Command',
    eventType: '${name}Event',
    initialState: initialState,
    globals: _globals,
    name: '${name}Machine',
    stateType: '${name}State',
    transitions: transitions,
  );

  writeFiles(stateMachine, 'example/example_document');
}

const _globals = '''
// ignore_for_file: unused_element, unused_local_variable
''';
