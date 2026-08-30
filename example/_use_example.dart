import 'dart:async';

import '_auth_service.dart';
import 'example.dart';

void main(List<String> args) {
  _fsm.onStateChange(_listen);

  final events = [
    LoginEvent(login: 'user', password: '123'),
    const RetryEvent(),
    RegisterEvent(login: 'user', password: '123'),
    RegisterEvent(login: 'user', password: '123'),
    LogoutEvent(user: _user),
    LogoutEvent(user: _user),
    RegisterEvent(login: 'user', password: '123'),
    const RetryEvent(),
    LoginEvent(login: 'user', password: '123'),
    LogoutEvent(user: _user),
    const ExitEvent(),
  ];

  var isStateChanged = false;

  _fsm.onStateChange((state) {
    isStateChanged = true;
  });

  Timer.periodic(Duration(seconds: 4), (timer) {
    if (!isStateChanged) {
      print("State '${_fsm.state}' not changed");
    }

    print('User: $_user');

    final index = timer.tick - 1;
    if (index >= events.length) {
      timer.cancel();
      return;
    }

    isStateChanged = false;
    final event = events[index];
    _sendEvent(event);
  });
}

final _fsm = _Fsm();

User? _user;

void _listen(AuthState state) {
  print('-' * 40);
  print('State: $state');
  _notifyStateChanged(state);
  switch (state) {
    case final FailureState state:
      print('Error: ${state.error}');
      break;
    case final LoggedState state:
      final isNew = state.isNew;
      final user = state.user;
      final text = isNew
          ? 'Hello, $user! You have successfully registered'
          : 'Hello, $user!';
      _user = user;
      print(text);
      break;
    case LoginState():
      print('Logging...');
      break;
    case LogoutState():
      print('Logging out...');
      break;
    case NotLoggedState():
      _user = null;
      break;
    case RegisterState():
      print('Registering...');
    case TerminatedState():
      print('Good bye');
  }
}

void _notifyStateChanged(AuthState state) {
  // Add your logic
}

void _sendEvent(AuthEvent event) {
  Timer.run(() {
    print('SEND_EVENT: $event');
    _fsm.processEvent(event);
  });
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
