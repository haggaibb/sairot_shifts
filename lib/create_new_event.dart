import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import './utils.dart';
import 'package:get/get.dart';
import 'main.dart';
import 'db_create_new_event.dart';

class CreateNewEvent extends StatefulWidget {
  const CreateNewEvent({super.key});

  @override
  State<CreateNewEvent> createState() => _CreateNewEventState();
}

class _CreateNewEventState extends State<CreateNewEvent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final eventNameController = TextEditingController();
  final startDateController = TextEditingController();
  final instructorsPerDayController = TextEditingController();
  List<DateTime> newEventDates = <DateTime>[];
  DateTime? startDate;
  DateTime? endDate;
  final endDateController = TextEditingController();
  String addDateDropdownValue = 'לא נטען';
  static const String _title = 'פתיחת סודר חדש';
  final _globalKey = GlobalKey<ScaffoldMessengerState>();
  DateTime? _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  final controller = Get.put(Controller());
  List<Instructor> allInstructorsList = [];

  endDateTapFunction({required BuildContext context}) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      lastDate: DateTime.now().add(Duration(days: 364)),
      firstDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (pickedDate == null) return;
    setState(() {
      endDateController.text = pickedDate.toIso8601String();
      endDate = pickedDate;
    });
  }

  startDateTapFunction({required BuildContext context}) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      lastDate: DateTime.now().add(Duration(days: 364)),
      firstDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (pickedDate == null) return;
    setState(() {
      startDateController.text = pickedDate.toIso8601String();
      if (!(pickedDate.compareTo(endDate ?? DateTime.now()) < 0)) {
        print("DT1 is not before DT2");
        endDate = pickedDate;
      }
      startDate = pickedDate;
    });
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
      newEventDates = _selectedDays.toList();
    });
  }

  createNewEvent() async {
    controller.loading.value = true;
    print('create new event...');
    //controller.newEvent.eventName = eventNameController.text;
    //controller.newEvent.startDate = DateTime.parse(startDateController.text);
    //controller.newEvent.endDate = DateTime.parse(endDateController.text);
    print('prepare data...');
    List newEventInstructors = [];
    for (Instructor element in controller.newEventInstructors) {
      var instructorData =
          getInstructorData(element.armyId, controller.eventInstructors);
      newEventInstructors.add({
        'armyId': instructorData['armyId'],
        'first_name': instructorData['firstName'],
        'last_name': instructorData['lastName'],
        'mobile': instructorData['mobile'],
        'email': instructorData['email'],
        'maxDays': instructorData['maxDays']
      });
    }
    var newEventData = {
      'event_name': eventNameController.text,
      'start_date': DateTime.parse(startDateController.text),
      'end_date': DateTime.parse(endDateController.text),
      'days_off_and_date' : DateTime.parse(startDateController.text),
      'instructors_per_day': int.parse(instructorsPerDayController.text),
      'event_instructors': newEventInstructors,
      'event_days': newEventDates
    };
    await dbCreateNewEvent(newEventData);
    //await triggerExtFunction(newEventData,'createNewEvent');
    print('new event created');
    controller.loading.value = false;
    Navigator.pop(context);
  }

  onInit() async {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
              key: _globalKey,
              appBar: AppBar(
                  leading: IconButton(
                    onPressed: () => {Navigator.pop(context)},
                    icon: Icon(Icons.arrow_back),
                  ),
                  title: const Text(_title)),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Obx(() => !controller.loading.value
                      ? Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 18.0),
                                      child: Text('שם הארוע'),
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        controller: eventNameController,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 18.0),
                                      child: Text('תאריך התחלה'),
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        controller: startDateController,
                                        readOnly: true,
                                        onTap: () => startDateTapFunction(
                                            context: context),
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 18.0),
                                      child: Text('תאריך סיום'),
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        controller: endDateController,
                                        onTap: () => endDateTapFunction(
                                            context: context),
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 18.0),
                                      child: Text('מספר מדריכים ביום'),
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        controller: instructorsPerDayController,
                                        keyboardType: TextInputType.number,
                                        onTap: () => {},
                                      ),
                                    )
                                  ],
                                ),
                                TableCalendar(
                                  locale: 'he_HE',
                                  weekendDays: const [
                                    DateTime.friday,
                                    DateTime.saturday
                                  ],
                                  headerStyle: const HeaderStyle(
                                      titleCentered: true,
                                      formatButtonVisible: false),
                                  firstDay: startDate ?? DateTime.now(),
                                  lastDay: endDate ?? DateTime.now(),
                                  focusedDay: _focusedDay ??
                                      startDate ??
                                      DateTime.now(),
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
                                  calendarStyle: const CalendarStyle(
                                    defaultTextStyle: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold),
                                    weekendTextStyle:
                                        TextStyle(color: Colors.red),
                                    isTodayHighlighted: false,
                                    outsideDaysVisible: false,
                                    markersMaxCount: 0,
                                  ),
                                  //eventLoader: _updateDaysPicked,
                                  onDaySelected: _onDaySelected,
                                ),
                                InstructorsConfigPage(
                                    controller.eventInstructors),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 30.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await createNewEvent();
                                    },
                                    child: const Text('שמור'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                          children: [
                            Text(
                              controller.statusMsg.value,
                              style: TextStyle(fontSize: 20),
                            ),
                            CircularProgressIndicator(),
                          ],
                        ))),
                ),
              ))),
    );
  }
}

class InstructorsConfigPage extends StatefulWidget {
  final List<Instructor> allInstructorsList;
  const InstructorsConfigPage(this.allInstructorsList, {super.key});

  @override
  State<InstructorsConfigPage> createState() => _InstructorsConfigPageState();
}

class _InstructorsConfigPageState extends State<InstructorsConfigPage> {
  late List<bool> selected;
  late List<TextEditingController> _textEditingControllers;
  late bool sort;
  final controller = Get.put(Controller());

  onSortColum(int columnIndex, bool ascending) {
    if (columnIndex == 1) {
      if (ascending) {
        widget.allInstructorsList
            .sort((a, b) => a.firstName.compareTo(b.firstName));
      } else {
        widget.allInstructorsList
            .sort((a, b) => b.firstName.compareTo(a.firstName));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selected = List<bool>.generate(
        widget.allInstructorsList.length, (int index) => false);
    controller.newEventInstructors.value = widget.allInstructorsList;
    _textEditingControllers =
        List.generate(widget.allInstructorsList.length, (index) {
      TextEditingController tmp = TextEditingController();
      tmp.text = widget.allInstructorsList[index].maxDays != null
          ? widget.allInstructorsList[index].maxDays.toString()
          : '17';
      controller.newEventInstructors[index].setMaxDays = int.parse(
          widget.allInstructorsList[index].maxDays != null
              ? widget.allInstructorsList[index].maxDays.toString()
              : '17');
      return tmp;
    });
    sort = true;
    onSortColum(1, true);
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      sortAscending: sort,
      sortColumnIndex: 1,
      columns: <DataColumn>[
        DataColumn(
          label: Text(''),
        ),
        DataColumn(
          numeric: false,
          label: Text(' שם המדריך'),
          onSort: (columnIndex, ascending) {
            print(columnIndex);
            print(ascending);
            setState(() {
              sort = !sort;
            });
            onSortColum(columnIndex, ascending);
          },
        ),
        DataColumn(
          label: Text('ת.ז.'),
        ),
        DataColumn(
          numeric: true,
          label: Text('מקסימום ימי מילואים'),
        ),
      ],
      rows: List<DataRow>.generate(
        widget.allInstructorsList.length,
        (int index) => DataRow(
          cells: <DataCell>[
            DataCell(Text((index + 1).toString())),
            DataCell(Text(widget.allInstructorsList[index].firstName +
                ' ' +
                widget.allInstructorsList[index].lastName)),
            DataCell(Text(widget.allInstructorsList[index].armyId)),
            DataCell(TextFormField(
              keyboardType: TextInputType.number,
              controller: _textEditingControllers[index],
              onEditingComplete: () => {
                controller.newEventInstructors[index].setMaxDays =
                    int.parse(_textEditingControllers[index].text)
              },
            ))
          ],
          selected: selected[index],
          onSelectChanged: (bool? value) {
            setState(() {
              selected[index] = value!;
              controller.selectedNewEventInstructors = selected;
            });
          },
        ),
      ),
    );
  }
}
