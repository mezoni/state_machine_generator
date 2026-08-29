import 'dart:io';

String prompt(String text) {
  stdout.writeln(text);
  return stdin.readLineSync() ?? '';
}

T readCommand<T>(List<(String, T)> commands) {
  if (commands.isEmpty) {
    throw ArgumentError('The list of commands must not be empty');
  }

  while (true) {
    print('Please select a command:');
    for (var i = 0; i < commands.length; i++) {
      final command = commands[i];
      final name = command.$1;
      final n = i + 1;
      print('$n - $name');
    }

    var input = stdin.readLineSync();
    if (input == null) {
      continue;
    }

    input = input.trim();
    var index = int.tryParse(input);
    if (index == null) {
      continue;
    }

    index--;
    if (index >= 0 && index < commands.length) {
      return commands[index].$2;
    }
  }
}

List<String> toWords(String text) {
  final result = <String>[];
  final parts = text.split(' ');
  for (var part in parts) {
    if (part.isNotEmpty) {
      result.add(part);
    }
  }

  return result;
}
