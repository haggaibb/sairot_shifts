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
  final endDateController = TextEditingController();
  final instructorsPerDayController = TextEditingController();
  final _globalKey = GlobalKey<ScaffoldMessengerState>();
  final controller = Get.find<Controller>();
  DateTime? startDate;
  DateTime? endDate;
  DateTime? _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  List<DateTime> newEventDates = <DateTime>[];
  List<Instructor> selectedInstructors = [];

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
        endDate = pickedDate;
      }
      startDate = pickedDate;
    });
  }

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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      if (_selectedDays.contains(selectedDay)) {
        _selectedDays.remove(selectedDay);
      } else {
        _selectedDays.add(selectedDay);
      }
      newEventDates = _selectedDays.toList();
    });
  }

  createNewEvent() async {
    /// form validation
    if (selectedInstructors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('אנא בחר לפחות מדריך אחד')),
      );
      return;
    }
    if (newEventDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('אנא בחר לפחות יום אחד בלוח השנה')),
      );
      return;
    }
    /// start creation
    controller.loading.value = true;
    List<Map<String, dynamic>> newEventInstructors = [];
    for (Instructor element in selectedInstructors) {
      if (element.maxDays > 0) {
        newEventInstructors.add({
          'armyId': element.armyId,
          'first_name': element.firstName,
          'last_name': element.lastName,
          'mobile': element.mobile,
          'email': element.email,
          'maxDays': element.maxDays,
        });
      }
    }
    var newEventData = {
      'event_name': eventNameController.text,
      'start_date': DateTime.parse(startDateController.text),
      'end_date': DateTime.parse(endDateController.text),
      'days_off_and_date': DateTime.parse(startDateController.text),
      'instructors_per_day': int.parse(instructorsPerDayController.text),
      'event_instructors': newEventInstructors,
      'event_days': newEventDates,
    };
    await dbCreateNewEvent(newEventData);
    controller.loading.value = false;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    eventNameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    instructorsPerDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _globalKey,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
          ),
          title: const Text('פתיחת סודר חדש'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(50.0),
            child: Obx(
                  () => !controller.loading.value
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
                              onTap: () => startDateTapFunction(context: context),
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
                              onTap: () => endDateTapFunction(context: context),
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
                            ),
                          )
                        ],
                      ),
                      TableCalendar(
                        locale: 'he_HE',
                        weekendDays: const [DateTime.friday, DateTime.saturday],
                        headerStyle: const HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false),
                        firstDay: startDate ?? DateTime.now(),
                        lastDay: endDate ?? DateTime.now(),
                        focusedDay: _focusedDay ?? startDate ?? DateTime.now(),
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        selectedDayPredicate: (day) => _selectedDays.contains(day),
                        calendarStyle: const CalendarStyle(
                          defaultTextStyle: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold),
                          weekendTextStyle: TextStyle(color: Colors.red),
                          isTodayHighlighted: false,
                          outsideDaysVisible: false,
                          markersMaxCount: 0,
                        ),
                        onDaySelected: _onDaySelected,
                      ),
                      InstructorsConfigPage(
                        controller.eventInstructors,
                        onSelectionChanged: (updatedList) {
                          setState(() {
                            selectedInstructors = updatedList;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: ElevatedButton(
                          onPressed: () async => await createNewEvent(),
                          child: const Text('שמור'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : Column(
                children: [
                  Text(
                    controller.statusMsg.value,
                    style: TextStyle(fontSize: 20),
                  ),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class InstructorsConfigPage extends StatefulWidget {
  final List<Instructor> allInstructorsList;
  final Function(List<Instructor>) onSelectionChanged;
  const InstructorsConfigPage(
    this.allInstructorsList, {
    required this.onSelectionChanged,
    super.key,
  });
  @override
  State<InstructorsConfigPage> createState() => _InstructorsConfigPageState();
}

class _InstructorsConfigPageState extends State<InstructorsConfigPage> {
  late List<bool> selected;
  late List<TextEditingController> _textEditingControllers;
  late bool sort;
  final controller = Get.find<Controller>();
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
    selected = List<bool>.generate(widget.allInstructorsList.length, (int index) => false);

    // Initialize controllers
    _textEditingControllers = List.generate(widget.allInstructorsList.length, (index) {
      final tmp = TextEditingController(
        text: widget.allInstructorsList[index].maxDays.toString(),
      );
      tmp.addListener(() {
        final newVal = int.tryParse(tmp.text) ?? 0;
        widget.allInstructorsList[index].maxDays = newVal;
      });
      return tmp;
    });
    sort = true;
    onSortColum(1, true);
  }
  @override
  void dispose() {
    for (final controller in _textEditingControllers) {
      controller.dispose();
    }
    super.dispose();
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
              onChanged: (val) {
                final newVal = int.tryParse(val) ?? 0;
                // Update both lists (so UI and logic stay consistent)
                setState(() {
                  widget.allInstructorsList[index].maxDays = newVal;
                });
              },
            ))
          ],
          selected: selected[index],
          onSelectChanged: (bool? value) {
            setState(() {
              selected[index] = value!;
            });
            // Create a list of selected instructors
            final selectedInstructors = <Instructor>[];
            for (int i = 0; i < widget.allInstructorsList.length; i++) {
              if (selected[i]) {
                selectedInstructors.add(widget.allInstructorsList[i]);
              }
            }
            // 🔥 Notify parent with the updated list
            widget.onSelectionChanged(selectedInstructors);
          },
        ),
      ),
    );
  }
}
