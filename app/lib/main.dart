import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Pair App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Employee Pair App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<List<dynamic>>? _csvTable;

  Future<void> _loadCSVFromAsset() async {
    String data = await rootBundle.loadString('assets/data.csv');
    _csvTable = const CsvToListConverter().convert(data);
    employees(_csvTable!);
  }

  List<List> employees(List<List<dynamic>> csvTable) {
    List<List> employees = [];
    List<List> pairs = [];

    for (var employee in csvTable) {
      employees.add(employee);
    }

    for (var emp1 in employees) {
      for (var emp2 in employees) {
        if (emp1[1] == emp2[1] && emp1 != emp2) {
          if (!pairs.any((pair) =>
              (pair[0] == emp1 && pair[1] == emp2) ||
              (pair[0] == emp2 && pair[1] == emp1))) {
            pairs.add([emp1, emp2]);
          }
        }
      }
    }
    pairsInfo(pairs);
    return pairs;
  }

  List<List<String>> pairsInfo(List<List> pairs) {
    List<List<String>> pairsInfo = [];
    for (var pair in pairs) {
      pairsInfo.add([
        intParser(pair[0][0]),
        intParser(pair[1][0]),
        intParser(pair[1][1]),
        intParser(workDays(pair))
      ]);
    }

    return pairsInfo;
  }

  String intParser(int num) {
    return '$num';
  }

  int workDays(List<dynamic> pair) {
    DateTime from1 = _parseDate(pair[0][2].toString());
    DateTime to1 = pair[0][3].toString() == 'NULL'
        ? DateTime.now()
        : _parseDate(pair[0][3].toString());
    DateTime from2 = _parseDate(pair[1][2].toString());
    DateTime to2 = pair[1][3].toString() == 'NULL'
        ? DateTime.now()
        : _parseDate(pair[1][3].toString());

    final secondStarted = from1.isAfter(from2) ? from1 : from2;
    final firstFinished = to1.isBefore(to2) ? to1 : to2;

    return firstFinished.difference(secondStarted).inDays > 0
        ? firstFinished.difference(secondStarted).inDays
        : 0;
  }

  DateTime _parseDate(String date) {
    List<String> formats = [
      'yyyy-MM-dd',
      'MM-dd-yyyy',
      'dd-MM-yyyy',
      'yyyy/MM/dd',
      'MM/dd/yyyy',
      'dd/MM/yyyy'
    ];

    for (String format in formats) {
      try {
        return DateFormat(format).parse(date);
      } catch (e) {
        // Format doesn't match, try the next one
      }
    }
    return DateTime.now();
  }

  Widget rowWidget(List<String> strings) {
    return Row(children: [for (var string in strings) Text(string)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => setState(() {
                _loadCSVFromAsset();
              }),
              child: const Text('Load CSV Data'),
            ),
            const SizedBox(height: 20),
            pairsInfo(employees(_csvTable ?? [])).isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Employee #1 ID')),
                        DataColumn(label: Text('Employee #2 ID')),
                        DataColumn(label: Text('Project ID')),
                        DataColumn(label: Text('Days Worked')),
                      ],
                      rows: List<DataRow>.generate(
                        pairsInfo(employees(_csvTable!)).length,
                        (index) => DataRow(
                          cells: pairsInfo(employees(_csvTable!))[index]
                              .map(
                                (data) => DataCell(Text(data)),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  )
                : const Text('No Data'),
          ],
        ),
      ),
    );
  }
}
