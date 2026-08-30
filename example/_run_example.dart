import 'dart:async';
import 'dart:io';

import '_auth_service.dart';
import '_cli_utils.dart';
import 'example.dart';

Future<void> main(List<String> args) async {
  _fsm.onStateChange(_listen);
  _fsm.onStateChange(_handleCancel);
  // init _cancelSub
  _cancelSub;
  _onStateChange(_fsm.state);
}

final _cancelSub = stdin.listen((event) {
  // Handle 'enter' as cancel event
  if (!_isCancelAllowed ||
      event.isEmpty ||
      event.length != 1 ||
      event[0] != 10) {
    return;
  }

  print('Cancelling...');
  _processEvent(const CancelEvent());
});

final _fsm = _Fsm();

bool _isCancelAllowed = false;

User? _user;

void _handleCancel(AuthState state) {
  _isCancelAllowed = false;
  final commands = _fsm.getCommands(state);
  for (var i = 0; i < commands.length; i++) {
    final command = commands[i];
    if (command == AuthCommand.cancel) {
      _isCancelAllowed = true;
      break;
    }
  }
}

void _listen(AuthState state) {
  Timer.run(() => _onStateChange(state));
}

void _notifyAboutCancel(AuthState state) {
  if (_fsm.getCommands(state).contains(AuthCommand.cancel)) {
    print("Press 'enter' to cancel");
  }
}

void _onStateChange(AuthState state) {
  print('=== $state ===');
  switch (state) {
    case final FailureState state:
      final error = state.error;
      print('Error: $error');
      break;
    case final LoggedState state:
      _user = state.user;
      final isNew = state.isNew;
      if (isNew) {
        print('Hello, $_user. You have successfully registered');
      } else {
        print("Logged as '$_user'");
      }

      break;
    case LoginState():
      print('Logging...');
      print("This will take 3 seconds");
      break;
    case LogoutState():
      print('Logging out...');
      print("This will take 3 seconds");
      break;
    case NotLoggedState():
      break;
    case RegisterState():
      print('Registering...');
      print("This will take 5 seconds");
      break;
    case TerminatedState():
      print('Terminated');
      _cancelSub.cancel().ignore();
      break;
  }

  _notifyAboutCancel(state);
  _processState(state);
}

void _processEvent(AuthEvent event) {
  Timer.run(() => _fsm.processEvent(event));
}

void _processState(AuthState state) {
  final commands = _fsm.getCommands(state);
  if (commands.isEmpty) {
    return;
  }

  final current = <(String, AuthCommand)>[];
  for (var i = 0; i < commands.length; i++) {
    final command = commands[i];
    if (command == AuthCommand.cancel) {
      // With blocking, synchronous 'stdin' processing 'cancel' does not come here
      continue;
    }

    current.add((command.fullName, command));
  }

  if (current.isEmpty) {
    return;
  }

  while (true) {
    final command = readCommand(current);
    switch (command) {
      case AuthCommand.cancel:
        _processEvent(const CancelEvent());
        return;
      case AuthCommand.exit:
        _processEvent(const ExitEvent());
        return;
      case AuthCommand.login:
        final text = prompt('Enter login and password');
        final parts = toWords(text);
        if (parts.length != 2) {
          continue;
        }

        final login = parts[0];
        final password = parts[1];
        _processEvent(LoginEvent(login: login, password: password));
        return;
      case AuthCommand.logout:
        final user = _user;
        _processEvent(LogoutEvent(user: user));
        return;
      case AuthCommand.register:
        final text = prompt('Enter login and password');
        final parts = toWords(text);
        if (parts.length != 2) {
          continue;
        }

        final login = parts[0];
        final password = parts[1];
        _processEvent(RegisterEvent(login: login, password: password));
        return;
      case AuthCommand.retry:
        _processEvent(const RetryEvent());
        return;
    }
  }
}

class _Fsm extends AuthMachine {
  @override
  void doLogin(LoginEvent e) {
    var isCanceled = false;
    onCancel = () => isCanceled = true;
    Timer.run(() async {
      try {
        final user = await AuthService().login(e.login, e.password);
        if (!isCanceled) {
          processEvent(SuccessEvent(user: user, isNew: false));
        }
      } catch (e) {
        if (!isCanceled) {
          processEvent(FailureEvent(error: e));
        }
      }
    });
  }

  @override
  void doLogout(LogoutEvent event) {
    var isCanceled = false;
    onCancel = () => isCanceled = true;
    Timer.run(() async {
      try {
        final user = event.user;
        await AuthService().logout(user);
      } catch (_) {}
      if (!isCanceled) {
        processEvent(LoggedOutEvent());
      }
    });
  }

  @override
  void doRegister(RegisterEvent event) {
    var isCanceled = false;
    onCancel = () => isCanceled = true;
    Timer.run(() async {
      try {
        final user = await AuthService().register(event.login, event.password);
        if (!isCanceled) {
          processEvent(SuccessEvent(user: user, isNew: true));
        }
      } catch (e) {
        if (!isCanceled) {
          processEvent(FailureEvent(error: e));
        }
      }
    });
  }
}
