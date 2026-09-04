# state_machine_generator

Finite state machine source code generator. Graphviz, Mermaid visualizations. Automatic generation of commands available for different states. FSM generation for any purpose.

[![Pub Package](https://img.shields.io/pub/v/state_machine_generator.svg)](https://pub.dev/packages/state_machine_generator)
[![Pub Monthly Downloads](https://img.shields.io/pub/dm/state_machine_generator.svg)](https://pub.dev/packages/state_machine_generator/score)
[![GitHub Issues](https://img.shields.io/github/issues/mezoni/state_machine_generator.svg)](https://github.com/mezoni/state_machine_generator/issues)
[![GitHub Forks](https://img.shields.io/github/forks/mezoni/state_machine_generator.svg)](https://github.com/mezoni/state_machine_generator/forks)
[![GitHub Stars](https://img.shields.io/github/stars/mezoni/state_machine_generator.svg)](https://github.com/mezoni/state_machine_generator/stargazers)
[![GitHub License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://raw.githubusercontent.com/mezoni/state_machine_generator/main/LICENSE)

## About this software

Finite state machine source code generator. Graphviz, Mermaid visualizations. Automatic generation of commands available for different states. FSM generation for any purpose.

Advantages:

- Easy to model, verify and debug the state machines being developed
- Strict validation during the building process of the state machine
- Conversion to `Graphviz` or `Mermaid` visualization tools
- High transition speed, independent of the number of states
- Can be used in high-load systems
- Synchronous automaton for asynchronous operations
- The `guard` conditions are supported

Disadvantages:

- Source code generation of the state machine required
- Hierarchically nested states are not supported
- Orthogonal regions are not supported

The source code generation comes from special configuration classes.  
Creating configuration classes is possible directly or by converting from other formats.  

## Modeling and source code generation

The state machine source code is generated from special configuration classes.  
List of configuration classes:

- `Event`
- `State`
- `StateMachine`
- `Transition`

These classes are very primitive and the understanding of their meaning can be found in the description of these classes.  
State machine modeling can be done directly using these classes or using various convenient tools at the discretion of the developer. For example, `StateMachineBuilder`, `StatePathChecker` or other self-written ones.

The `StateMachineGenerator` class is intended for generating source code of the state machine.

Theoretically, modeling can be performed in visual development environments with subsequent transformation.  
At the moment, this software does not provide any converters for such purposes.

## Example

An example of a simple state machine model can be found in the `example` directory.  

State machine diagram

![State machine diagram](./example/example.png)

[Graphviz example](https://github.com/mezoni/state_machine_generator/blob/main/example/example.dot)

```txt
{{example/example.dot}}
```

[Mermaid example](https://github.com/mezoni/state_machine_generator/blob/main/example/example.mermaid)

```txt
{{example/example.mermaid}}
```

[Event table example](https://github.com/mezoni/state_machine_generator/blob/main/example/example.events.csv)

```txt
{{example/example.events.csv}}
```

[State table example](https://github.com/mezoni/state_machine_generator/blob/main/example/example.states.csv)

```txt
{{example/example.states.csv}}
```

[Transitions table example](https://github.com/mezoni/state_machine_generator/blob/main/example/example.transitions.csv)

```txt
{{example/example.transitions.csv}}
```

[State matrix table example](https://github.com/mezoni/state_machine_generator/blob/main/example/example.state_matrix.csv)

```txt
{{example/example.state_matrix.csv}}
```

[Simulation example of using a state machine](https://github.com/mezoni/state_machine_generator/blob/main/example/_use_example.dart)

```dart
{{example/_use_example.dart}}
```

Result of simulation:

```txt
State 'NotLogged' not changed
User: null
SEND_EVENT: Login
----------------------------------------
State: Login
Logging...
----------------------------------------
State: Failure
Error: Bad state: Invalid login or password
User: null
SEND_EVENT: Retry
----------------------------------------
State: NotLogged
User: null
SEND_EVENT: Register
----------------------------------------
State: Register
Registering...
----------------------------------------
State: Logged
Hello, user! You have successfully registered
User: user
SEND_EVENT: Register
Valid commands (events): [logout, exit]
State 'Logged' not changed
User: user
SEND_EVENT: Logout
----------------------------------------
State: Logout
Logging out...
----------------------------------------
State: NotLogged
User: null
SEND_EVENT: Logout
Valid commands (events): [login, register, exit]
State 'NotLogged' not changed
User: null
SEND_EVENT: Register
----------------------------------------
State: Register
Registering...
----------------------------------------
State: Failure
Error: Bad state: User 'user' already exists
User: null
SEND_EVENT: Retry
----------------------------------------
State: NotLogged
User: null
SEND_EVENT: Login
----------------------------------------
State: Login
Logging...
----------------------------------------
State: Logged
Hello, user!
User: user
SEND_EVENT: Logout
----------------------------------------
State: Logout
Logging out...
----------------------------------------
State: NotLogged
User: null
SEND_EVENT: Exit
----------------------------------------
State: Terminated
Good bye
User: null

```

[CLI example of using a state machine](https://github.com/mezoni/state_machine_generator/blob/main/example/_run_example.dart)

```dart
{{example/_run_example.dart}}
```

[An example of generating a state machine](https://github.com/mezoni/state_machine_generator/blob/main/example/_generate_example.dart)

```dart
{{example/_generate_example.dart}}
```

[An example of generated a state machine](https://github.com/mezoni/state_machine_generator/blob/main/example/example.dart)

```dart
{{example/example.dart}}
```
