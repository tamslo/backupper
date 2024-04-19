String paddedValue(int value) => value > 9 ? value.toString() : '0$value';


String newLogLinePadding({ int logLevel = 0 }) =>
  '           ${' '*logLevel*2}';

// ignore: avoid_print
void beginNewLogPart() => print('');

void writeLog(String text, { int logLevel = 0 }) {
  final now = DateTime.now();
  // ignore: avoid_print
  print(
    '${'-'*logLevel*2}'
    '[${paddedValue(now.hour)}:'
    '${paddedValue(now.minute)}:'
    '${paddedValue(now.second)}] '
    '$text',
  );
}
