import 'dart:io';

void main(List<String> args) {
  const inputFile = 'tool/README.in.md';
  const outputFile = 'README.md';
  var source = File(inputFile).readAsStringSync();
  final files = [
    '_generate_example.dart',
    '_run_example.dart',
    'example.dot',
    'example.dart',
    'example.mermaid',
  ];

  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    final path = 'example/$file';
    final data = File(path).readAsStringSync();
    source = source.replaceAll('{{$path}}', data);
  }

  File(outputFile).writeAsStringSync(source);
}
