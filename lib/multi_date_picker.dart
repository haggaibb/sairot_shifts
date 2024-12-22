import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import './utils.dart';
import 'dart:collection';
import 'package:screenshot/screenshot.dart';
import 'package:file_saver/file_saver.dart';
import 'package:csv/csv.dart';
import 'dart:typed_data';
import 'dart:convert';


class MultiDatePicker extends StatefulWidget {
  final List instructorsPerDay;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> eventDays;


  const MultiDatePicker({super.key, required this.instructorsPerDay, required this.startDate, required this.endDate, required this.eventDays});
  @override
  State<MultiDatePicker> createState() => _MultiDatePickerState();
}

class _MultiDatePickerState extends State<MultiDatePicker> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _focusedDay;
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  var eventInstructors = [];
  var editDaysOffEndDate = DateTime.now();
  var isLoading = true;
  var db = FirebaseFirestore.instance;
  ScreenshotController screenshotController = ScreenshotController();


  saveMiluimMultiReportImage(bytes, String dateKey) async {
    await FileSaver.instance.saveFile(
      name: dateKey, // you can give the CSV file name here.
      bytes: bytes,
      ext: 'jpeg',
      mimeType: MimeType.jpeg,
    );
  }

  saveToCSV() async {
    List<List<dynamic>> rows = [];
    for (var date in _selectedDays) {
      rows.add([toDateKey(date)]);
      var dayIndex = widget.eventDays.indexWhere((element) { return element==toDateKey(date);});
      var indexStr = 1;
      for (var instructor in widget.instructorsPerDay[dayIndex]) {
        rows.add([
          indexStr,
          instructor['lastName'],
          instructor['firstName'],
          instructor['armyId'].toString()
        ]);
        indexStr++;
      }
      rows.add([]);
      rows.add([]);
    }
    // Convert your CSV string to a Uint8List for downloading.
    String csv = const ListToCsvConverter().convert(rows);
    //Uint8List bytes = Uint8List.fromList(utf8.encode(csv));
    List<int> intBytes = List.from(utf8.encode(csv));
    intBytes.insert(0, 0xBF );
    intBytes.insert(0, 0xBB );
    intBytes.insert(0, 0xEF );
    // This will download the file on the device.
    Uint8List bytes = Uint8List.fromList(intBytes);
    await FileSaver.instance.saveFile(
      name: 'multi_day_report', // you can give the CSV file name here.
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<void> generateReport() async {
    List selectedDays = [];
    _selectedDays.forEach((element) {
      selectedDays.add(
         {
           'index': element.day-widget.startDate.day,
           'date' : element
         }
      );
    });
    screenshotController
        .captureFromLongWidget(
      InheritedTheme.captureAll(
        context,
        Material(
          child: MultiDayReportImage(widget.instructorsPerDay,selectedDays,widget.eventDays),
        ),
      ),
      delay: Duration(milliseconds: 100),
      context: context,
      ///
      /// Additionally you can define constraint for your image.
      ///
      /// constraints: BoxConstraints(
      ///   maxHeight: 1000,
      ///   maxWidth: 1000,
      /// )
    )
        .then((capturedImage) async {
      await saveMiluimMultiReportImage(capturedImage, 'multi_day_report');

    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      // Update values in a Set
      if (_selectedDays.contains(selectedDay)) {
        _selectedDays.remove(selectedDay);
      } else {
        _selectedDays.add(selectedDay);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference dates = FirebaseFirestore.instance.collection('Dates');
    final formKey = GlobalKey<FormState>();
    final instructorIdController = TextEditingController();
    final DateTime now = DateTime.now();
    return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('הכנת דוח ימי מילואים'),
            ),
            body: Center(
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    height: 100,
                    child: Center(
                        child: Text(
                      'נא סמן את הימים לכלול בדוח',
                      style: TextStyle(fontSize: 24),
                    )),
                  ), //Title
                  TableCalendar(
                    locale: 'he_HE',
                    weekendDays: const [DateTime.friday, DateTime.saturday],
                    headerStyle: const HeaderStyle(
                        titleCentered: true, formatButtonVisible: false),
                    firstDay: widget.startDate,
                    lastDay: widget.endDate,
                    focusedDay: _focusedDay ?? widget.startDate,
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    selectedDayPredicate: (day) {
                      // Use values from Set to mark multiple days as selected
                      return _selectedDays.contains(day);
                    },
                    enabledDayPredicate: (day) {
                      String dateKey =
                          "${day.day.toString().padLeft(2, '0')}-${day.month.toString().padLeft(2, '0')}-${day.year.toString()}";
                      return widget.eventDays.contains(dateKey);
                      // return controller.eventDays
                    },
                    calendarStyle: const CalendarStyle(
                      defaultTextStyle: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold),
                      weekendTextStyle: TextStyle(color: Colors.red),
                      isTodayHighlighted: false,
                      outsideDaysVisible: false,
                      markersMaxCount: 0,
                    ),
                    //eventLoader: _updateDaysPicked,
                    onDaySelected: _onDaySelected,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 150,
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                await generateReport();
                              },
                              child: const Text('תכלול הדוח'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                await saveToCSV();
                              },
                              child: const Text('CSV'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));

  }

}


class MultiDayReportImage extends StatelessWidget {
  final List listByDay;
  final List selectedDays;
  final List eventDays;

  MultiDayReportImage(this.listByDay, this.selectedDays, this.eventDays, {super.key});

  toDateKey(DateTime selectedDay) {
    String dateKey =
        "${selectedDay.day.toString().padLeft(2, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.year.toString()}";
  return dateKey;
  }
  getDayIndex(rowIndex) {
    return eventDays.indexWhere((element) => element==toDateKey(selectedDays[rowIndex]['date']));
  }

  @override
  Widget build(BuildContext context) {
    //print(listByDay);


    return Center(
        child: Column(
          children: [
            Image.network('assets/images/logo.png' ,height: 50,),
            const Text('דוח מילואים רב יומי', style: TextStyle(fontSize: 20),),
            const SizedBox(width: 200, child: Divider(thickness: 2, color: Colors.black,)),
            Column(
              children: List.generate(selectedDays.length, (rowIndex) =>
                  Column(
                    children: [
                      Text(toDateKey(selectedDays[rowIndex]['date']) , style: TextStyle(fontWeight: FontWeight.bold),),
                      SizedBox(
                        height: 800,
                        width: 300,
                        child: Column(
                            children : List.generate(
                                listByDay[getDayIndex(rowIndex)].length, (index) =>
                                Row(
                                    textDirection: TextDirection.rtl,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0, right: 50),
                                        child: Text('.${index+1}'),
                                      ),
                                      Text(listByDay[getDayIndex(rowIndex)][index]['armyId']),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                        child: Text(listByDay[getDayIndex(rowIndex)][index]['firstName']),
                                      ),
                                      Text(listByDay[getDayIndex(rowIndex)][index]['lastName']),
                                    ]
                                )
                                ))
                      ),
                    ],
                  ),),
            ),
          ],
        ),
      );
  }
}

/*

ListView.builder(
                              padding: const EdgeInsets.all(18),
                              itemCount: listByDay[selectedDays[rowIndex]['index']].length,
                              itemBuilder: (BuildContext context, int index) {
                                return Row(
                                    textDirection: TextDirection.rtl,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left:8.0),
                                      child: Text('.${index+1}'),
                                    ),
                                    Text(listByDay[selectedDays[rowIndex]['index']][index]['armyId']),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                      child: Text(listByDay[selectedDays[rowIndex]['index']][index]['firstName']),
                                    ),
                                    Text(listByDay[selectedDays[rowIndex]['index']][index]['lastName']),
                                  ]
                                );
                              }),

 Container(
              height: 800,
              width: 1200,
              child: Column(
                children: List.generate(listOfIndexes.length, (rowIndex) =>
                    ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: listByDay[listOfIndexes[rowIndex]].length,
                    itemBuilder: (BuildContext context, int index) {
                      return Row(
                        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left:8.0),
                              child: Text('.${index+1}'),
                            ),
                            Text(listByDay[listOfIndexes[rowIndex]][index].armyId,),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text(listByDay[listOfIndexes[rowIndex]][index].firstName),
                            ),
                            Text(listByDay[listOfIndexes[rowIndex]][index].lastName),
                          ]
                      );
                    }),),
              )


          ),

 */