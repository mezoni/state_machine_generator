// ignore_for_file: unused_local_variable
import '_auth_service.dart';

/// [AuthCommand] a set of commands that can be used with [AuthMachine]
enum AuthCommand {
  cancel('Cancel'),
  exit('Exit'),
  login('Login'),
  logout('Logout'),
  register('Register'),
  retry('Retry');

  const AuthCommand(this.fullName);

  final String fullName;
}

sealed class AuthEvent {
  const AuthEvent();

  int get $index;
}

final class CancelEvent extends AuthEvent {
  const CancelEvent();

  @override
  int get $index => 0;

  @override
  String toString() => 'Cancel';
}

final class ExitEvent extends AuthEvent {
  const ExitEvent();

  @override
  int get $index => 1;

  @override
  String toString() => 'Exit';
}

final class FailureEvent extends AuthEvent {
  final Object error;

  const FailureEvent({required this.error});

  @override
  int get $index => 2;

  @override
  String toString() => 'Failure';
}

final class LoggedOutEvent extends AuthEvent {
  const LoggedOutEvent();

  @override
  int get $index => 3;

  @override
  String toString() => 'LoggedOut';
}

final class LoginEvent extends AuthEvent {
  final String login;

  final String password;

  const LoginEvent({
    required this.login,
    required this.password,
  });

  @override
  int get $index => 4;

  @override
  String toString() => 'Login';
}

final class LogoutEvent extends AuthEvent {
  final User? user;

  const LogoutEvent({required this.user});

  @override
  int get $index => 5;

  @override
  String toString() => 'Logout';
}

final class RegisterEvent extends AuthEvent {
  final String login;

  final String password;

  const RegisterEvent({
    required this.login,
    required this.password,
  });

  @override
  int get $index => 6;

  @override
  String toString() => 'Register';
}

final class RetryEvent extends AuthEvent {
  const RetryEvent();

  @override
  int get $index => 7;

  @override
  String toString() => 'Retry';
}

final class SuccessEvent extends AuthEvent {
  final User user;

  final bool isNew;

  const SuccessEvent({
    required this.user,
    required this.isNew,
  });

  @override
  int get $index => 8;

  @override
  String toString() => 'Success';
}

sealed class AuthState {
  const AuthState();

  int get $index;
}

final class FailureState extends AuthState {
  final Object error;

  const FailureState({required this.error});

  @override
  int get $index => 0;

  @override
  String toString() => 'Failure';
}

final class LoggedState extends AuthState {
  final User user;

  final bool isNew;

  const LoggedState({
    required this.user,
    required this.isNew,
  });

  @override
  int get $index => 1;

  @override
  String toString() => 'Logged';
}

final class LoginState extends AuthState {
  const LoginState();

  @override
  int get $index => 2;

  @override
  String toString() => 'Login';
}

final class LogoutState extends AuthState {
  const LogoutState();

  @override
  int get $index => 3;

  @override
  String toString() => 'Logout';
}

final class NotLoggedState extends AuthState {
  const NotLoggedState();

  @override
  int get $index => 4;

  @override
  String toString() => 'NotLogged';
}

final class RegisterState extends AuthState {
  const RegisterState();

  @override
  int get $index => 5;

  @override
  String toString() => 'Register';
}

final class TerminatedState extends AuthState {
  const TerminatedState();

  @override
  int get $index => 6;

  @override
  String toString() => 'Terminated';
}

abstract class AuthMachine {
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

  AuthState _state = const NotLoggedState();

  final List<void Function(AuthState)> _stateListeners = [];

  /// Returns the current state of the state machine.
  AuthState get state => _state;

  void doLogin(LoginEvent event);

  void doRegister(RegisterEvent event);

  void doLogout(LogoutEvent event);

  List<AuthCommand> getCommands(AuthState state) {
    final s = state.$index;
    if (s < 3) {
      if (s < 1) {
        if (s == 0) {
          // State: Failure
          return const [AuthCommand.retry, AuthCommand.exit];
        }
      } else if (s > 1) {
        // State: Login
        return const [AuthCommand.cancel];
      } else {
        // State: Logged
        return const [AuthCommand.logout, AuthCommand.exit];
      }
    } else if (s > 3) {
      if (s < 5) {
        // State: NotLogged
        return const [AuthCommand.login, AuthCommand.register, AuthCommand.exit];
      } else if (s == 5) {
        // State: Register
        return const [AuthCommand.cancel];
      }
    } else {
      // State: Logout
      return const [AuthCommand.cancel];
    }
    return const [];
  }

  /// Evaluates current state against received event, determines what action
  /// to take and which state to transition to next.
  void processEvent(AuthEvent event) {
    final $event = event;
    final e = event.$index;
    final s = _state.$index;
    if (s < 3) {
      if (s < 1) {
        if (s == 0) {
          // State: Failure
          if (e == 1) {
            final event = $event as ExitEvent;
            _state = const TerminatedState();
            _notify(_state, _stateListeners);
          } else if (e == 7) {
            final event = $event as RetryEvent;
            _state = const NotLoggedState();
            _notify(_state, _stateListeners);
          }
        }
      } else if (s > 1) {
        // State: Login
        if (e < 2) {
          if (e == 0) {
            final event = $event as CancelEvent;
            _exitState();
            _state = const NotLoggedState();
            _notify(_state, _stateListeners);
          }
        } else if (e > 2) {
          if (e == 8) {
            final event = $event as SuccessEvent;
            _exitState();
            _state = LoggedState(user: event.user, isNew: event.isNew);
            _notify(_state, _stateListeners);
          }
        } else {
          final event = $event as FailureEvent;
          _exitState();
          _state = FailureState(error: event.error);
          _notify(_state, _stateListeners);
        }
      } else {
        // State: Logged
        if (e == 1) {
          final event = $event as ExitEvent;
          _state = const TerminatedState();
          _notify(_state, _stateListeners);
        } else if (e == 5) {
          final event = $event as LogoutEvent;
          _state = const LogoutState();
          doLogout(event);
          _notify(_state, _stateListeners);
        }
      }
    } else if (s > 3) {
      if (s < 5) {
        // State: NotLogged
        if (e < 4) {
          if (e == 1) {
            final event = $event as ExitEvent;
            _state = const TerminatedState();
            _notify(_state, _stateListeners);
          }
        } else if (e > 4) {
          if (e == 6) {
            final event = $event as RegisterEvent;
            _state = const RegisterState();
            doRegister(event);
            _notify(_state, _stateListeners);
          }
        } else {
          final event = $event as LoginEvent;
          _state = const LoginState();
          doLogin(event);
          _notify(_state, _stateListeners);
        }
      } else if (s > 5) {
        if (s == 6) {
          // State: Terminated
        }
      } else {
        // State: Register
        if (e < 2) {
          if (e == 0) {
            final event = $event as CancelEvent;
            _exitState();
            _state = const NotLoggedState();
            _notify(_state, _stateListeners);
          }
        } else if (e > 2) {
          if (e == 8) {
            final event = $event as SuccessEvent;
            _exitState();
            _state = LoggedState(user: event.user, isNew: event.isNew);
            _notify(_state, _stateListeners);
          }
        } else {
          final event = $event as FailureEvent;
          _exitState();
          _state = FailureState(error: event.error);
          _notify(_state, _stateListeners);
        }
      }
    } else {
      // State: Logout
      if (e == 0) {
        final event = $event as CancelEvent;
        _exitState();
        _state = const NotLoggedState();
        _notify(_state, _stateListeners);
      } else if (e == 3) {
        final event = $event as LoggedOutEvent;
        _exitState();
        _state = const NotLoggedState();
        _notify(_state, _stateListeners);
      }
    }
  }

  /// Adds a listener that will be notified of changes in the [state] of the state
  /// machine.
  void Function() onStateChange(void Function(AuthState state) listener) {
    return _addListener<AuthState>(_stateListeners, listener);
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

}