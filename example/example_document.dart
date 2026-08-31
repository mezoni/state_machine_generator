// ignore_for_file: unused_element, unused_local_variable

/// [DocumentCommand] a set of commands that can be used with [DocumentMachine]
enum DocumentCommand {
  accept('Accept'),
  approve('Approve'),
  beginReview('BeginReview'),
  changeNeeded('ChangeNeeded'),
  decline('Decline'),
  reject('Reject'),
  restartReview('RestartReview'),
  submit('Submit'),
  updateDocument('UpdateDocument');

  const DocumentCommand(this.fullName);

  final String fullName;
}

sealed class DocumentEvent {
  const DocumentEvent();

  int get $index;
}

final class AcceptEvent extends DocumentEvent {
  const AcceptEvent();

  @override
  int get $index => 0;

  @override
  String toString() => 'Accept';
}

final class ApproveEvent extends DocumentEvent {
  const ApproveEvent();

  @override
  int get $index => 1;

  @override
  String toString() => 'Approve';
}

final class BeginReviewEvent extends DocumentEvent {
  const BeginReviewEvent();

  @override
  int get $index => 2;

  @override
  String toString() => 'BeginReview';
}

final class ChangeNeededEvent extends DocumentEvent {
  const ChangeNeededEvent();

  @override
  int get $index => 3;

  @override
  String toString() => 'ChangeNeeded';
}

final class DeclineEvent extends DocumentEvent {
  const DeclineEvent();

  @override
  int get $index => 4;

  @override
  String toString() => 'Decline';
}

final class RejectEvent extends DocumentEvent {
  const RejectEvent();

  @override
  int get $index => 5;

  @override
  String toString() => 'Reject';
}

final class RestartReviewEvent extends DocumentEvent {
  const RestartReviewEvent();

  @override
  int get $index => 6;

  @override
  String toString() => 'RestartReview';
}

final class SubmitEvent extends DocumentEvent {
  const SubmitEvent();

  @override
  int get $index => 7;

  @override
  String toString() => 'Submit';
}

final class UpdateDocumentEvent extends DocumentEvent {
  const UpdateDocumentEvent();

  @override
  int get $index => 8;

  @override
  String toString() => 'UpdateDocument';
}

sealed class DocumentState {
  const DocumentState();

  int get $index;
}

final class ApprovedState extends DocumentState {
  const ApprovedState();

  @override
  int get $index => 0;

  @override
  String toString() => 'Approved';
}

final class ChangeRequestedState extends DocumentState {
  const ChangeRequestedState();

  @override
  int get $index => 1;

  @override
  String toString() => 'ChangeRequested';
}

final class DeclinedState extends DocumentState {
  const DeclinedState();

  @override
  int get $index => 2;

  @override
  String toString() => 'Declined';
}

final class DraftState extends DocumentState {
  const DraftState();

  @override
  int get $index => 3;

  @override
  String toString() => 'Draft';
}

final class ReviewState extends DocumentState {
  const ReviewState();

  @override
  int get $index => 4;

  @override
  String toString() => 'Review';
}

final class SubmittedToClientState extends DocumentState {
  const SubmittedToClientState();

  @override
  int get $index => 5;

  @override
  String toString() => 'SubmittedToClient';
}

abstract class DocumentMachine {
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

  DocumentState _state = const DraftState();

  final List<void Function(DocumentState)> _stateListeners = [];

  /// Returns the current state of the state machine.
  DocumentState get state => _state;

  List<DocumentCommand> getCommands(DocumentState state) {
    final s = state.$index;
    if (s < 4) {
      if (s < 2) {
        if (s == 1) {
          // State: ChangeRequested
          return const [DocumentCommand.accept, DocumentCommand.reject];
        }
      } else if (s > 2) {
        // State: Draft
        return const [DocumentCommand.beginReview, DocumentCommand.updateDocument];
      } else {
        // State: Declined
        return const [DocumentCommand.restartReview];
      }
    } else if (s > 4) {
      if (s == 5) {
        // State: SubmittedToClient
        return const [DocumentCommand.approve, DocumentCommand.decline];
      }
    } else {
      // State: Review
      return const [DocumentCommand.changeNeeded, DocumentCommand.submit];
    }
    return const [];
  }

  /// Evaluates current state against received event, determines what action
  /// to take and which state to transition to next.
  void processEvent(DocumentEvent event) {
    final $event = event;
    final e = event.$index;
    final s = _state.$index;
    if (s < 3) {
      if (s < 1) {
        if (s == 0) {
          // State: Approved
        }
      } else if (s > 1) {
        // State: Declined
        if (e == 6) {
          final event = $event as RestartReviewEvent;
          _state = const ReviewState();
          _notify(_state, _stateListeners);
        }
      } else {
        // State: ChangeRequested
        if (e == 0) {
          final event = $event as AcceptEvent;
          _state = const DraftState();
          _notify(_state, _stateListeners);
        } else if (e == 5) {
          final event = $event as RejectEvent;
          _state = const ReviewState();
          _notify(_state, _stateListeners);
        }
      }
    } else if (s > 3) {
      if (s < 5) {
        // State: Review
        if (e == 3) {
          final event = $event as ChangeNeededEvent;
          _state = const ChangeRequestedState();
          _notify(_state, _stateListeners);
        } else if (e == 7) {
          final event = $event as SubmitEvent;
          _state = const SubmittedToClientState();
          _notify(_state, _stateListeners);
        }
      } else if (s == 5) {
        // State: SubmittedToClient
        if (e == 1) {
          final event = $event as ApproveEvent;
          _state = const ApprovedState();
          _notify(_state, _stateListeners);
        } else if (e == 4) {
          final event = $event as DeclineEvent;
          _state = const DeclinedState();
          _notify(_state, _stateListeners);
        }
      }
    } else {
      // State: Draft
      if (e == 2) {
        final event = $event as BeginReviewEvent;
        _state = const ReviewState();
        _notify(_state, _stateListeners);
      } else if (e == 8) {
        final event = $event as UpdateDocumentEvent;
        _state = const DraftState();
        _notify(_state, _stateListeners);
      }
    }
  }

  /// Adds a listener that will be notified of changes in the [state] of the state
  /// machine.
  void Function() onStateChange(void Function(DocumentState state) listener) {
    return _addListener<DocumentState>(_stateListeners, listener);
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