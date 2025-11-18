import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import './utils.dart';
import 'package:get/get.dart';
import 'main.dart';
import 'db_create_new_event.dart';
import 'package:intl/intl.dart' as intl;

class CreateNewEvent extends StatefulWidget {
  final Map<String, dynamic>? existingEvent;
  const CreateNewEvent({super.key, this.existingEvent});
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
  final controller = Get.put(Controller());
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

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      final event = widget.existingEvent!;
      eventNameController.text = event['event_name'] ?? '';
      startDateController.text = event['start_date'].toIso8601String();
      endDateController.text = event['end_date'].toIso8601String();
      instructorsPerDayController.text = event['instructors_per_day'].toString();
      final dateFormat = intl.DateFormat('dd-MM-yyyy');
      newEventDates = (event['event_days'] as List)
          .map<DateTime>((e) => dateFormat.parse(e))
          .toList();
      _selectedDays.addAll(newEventDates);
      final existingInstructorIds = (event['event_instructors'] as List)
          .map((e) => (e is Instructor)
              ? e.armyId
              : (e as Map<String, dynamic>)['armyId'])
          .toSet();
      selectedInstructors = (event['event_instructors'] as List)
          .map<Instructor>((e) {
        if (e is Instructor) return e;
        if (e is Map<String, dynamic>) {
          return Instructor.fromMap(e,e['armyId']);
        }
        throw Exception('Invalid instructor format: $e');
      })
          .where((instructor) => existingInstructorIds.contains(instructor.armyId))
          .toList();
      startDate = event['start_date'];
      endDate = event['end_date'];
      _focusedDay = startDate;
    }
  }

  @override
  void dispose() {
    eventNameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    instructorsPerDayController.dispose();
    super.dispose();
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

  Future<void> saveOrUpdateEvent() async {
    /// validations
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
    if (startDateController.text.isEmpty || endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('אנא הזן תאריכים תקינים')),
      );
      return;
    }
    final instructorsPerDay = int.tryParse(instructorsPerDayController.text);
    if (instructorsPerDay == null || instructorsPerDay <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('אנא הזן מספר מדריכים חוקי')),
      );
      return;
    }

    /// start saving
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
          'max_days': element.maxDays,
        });
      }
    }

    var newEventData = {
      'event_name': eventNameController.text,
      'start_date': DateTime.parse(startDateController.text),
      'end_date': DateTime.parse(endDateController.text),
      'days_off_and_date': DateTime.parse(startDateController.text),
      'instructors_per_day': instructorsPerDay,
      'event_instructors': selectedInstructors,
      'event_days': newEventDates,
    };

    final isEditing = widget.existingEvent != null;

    if (isEditing) {
      await dbUpdateEvent(newEventData, selectedInstructors);
    } else {
      await dbCreateNewEvent(newEventData);
    }

    controller.loading.value = false;
    Navigator.pop(context);
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
          title: Text(
              widget.existingEvent == null ? 'פתיחת סודר חדש' : 'עריכת סודר'),
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
                            LabeledInputField(
                                label: 'שם הארוע',
                                controller: eventNameController),
                            LabeledInputField(
                              label: 'תאריך התחלה',
                              controller: startDateController,
                              readOnly: true,
                              onTap: () =>
                                  startDateTapFunction(context: context),
                            ),
                            LabeledInputField(
                              label: 'תאריך סיום',
                              controller: endDateController,
                              onTap: () => endDateTapFunction(context: context),
                            ),
                            LabeledInputField(
                              label: 'מספר מדריכים ביום',
                              controller: instructorsPerDayController,
                              keyboardType: TextInputType.number,
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
                              focusedDay:
                                  _focusedDay ?? startDate ?? DateTime.now(),
                              calendarFormat: _calendarFormat,
                              onFormatChanged: (format) {
                                if (_calendarFormat != format) {
                                  setState(() {
                                    _calendarFormat = format;
                                  });
                                }
                              },
                              selectedDayPredicate: (day) =>
                                  _selectedDays.contains(day),
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
                              controller.allInstructorsList,
                              selectedInstructors: selectedInstructors,
                              onSelectionChanged: (updatedList) {
                                setState(() {
                                  selectedInstructors = updatedList;
                                });
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 30.0),
                              child: ElevatedButton(
                                onPressed: () async =>
                                    await saveOrUpdateEvent(),
                                child: Text(widget.existingEvent == null
                                    ? 'שמור'
                                    : 'עדכן'),
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

class LabeledInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType keyboardType;

  const LabeledInputField({
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.onTap,
    this.keyboardType = TextInputType.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: Text(label),
        ),
        SizedBox(
          width: 150,
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
          ),
        )
      ],
    );
  }
}

class InstructorsConfigPage extends StatefulWidget {
  final List<Instructor> allInstructorsList;
  final List<Instructor> selectedInstructors;
  final Function(List<Instructor>) onSelectionChanged;
  const InstructorsConfigPage(
    this.allInstructorsList, {
    required this.selectedInstructors,
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
    // 🔁 Merge maxDays from selectedInstructors into allInstructorsList
    final selectedById = {
      for (var i in widget.selectedInstructors) i.armyId: i.maxDays
    };
    for (var instructor in widget.allInstructorsList) {
      if (selectedById.containsKey(instructor.armyId)) {
        instructor.maxDays = selectedById[instructor.armyId]!;
      }
    }
    selected = List<bool>.generate(
      widget.allInstructorsList.length,
          (int index) =>
          widget.selectedInstructors.any((i) =>
          i.armyId == widget.allInstructorsList[index].armyId),
    );
    _textEditingControllers = List.generate(
      widget.allInstructorsList.length,
          (index) {
        final tmp = TextEditingController(
          text: widget.allInstructorsList[index].maxDays.toString(),
        );
        tmp.addListener(() {
          final newVal = int.tryParse(tmp.text) ?? 0;
          widget.allInstructorsList[index].maxDays = newVal;
        });
        return tmp;
      },
    );
    sort = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        onSortColum(1, true);
      });
    });
  }

  @override
  void dispose() {
    for (final c in _textEditingControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      sortAscending: sort,
      sortColumnIndex: 1,
      columns: <DataColumn>[
        const DataColumn(
          label: Text(''),
        ),
        DataColumn(
          numeric: false,
          label: const Text(' שם המדריך'),
          onSort: (columnIndex, ascending) {
            setState(() {
              sort = !sort;
            });
            onSortColum(columnIndex, ascending);
          },
        ),
        const DataColumn(
          label: Text('ת.ז.'),
        ),
        const DataColumn(
          numeric: true,
          label: Text('מקסימום ימי מילואים'),
        ),
      ],
      rows: List<DataRow>.generate(
        widget.allInstructorsList.length,
        (int index) => DataRow(
          cells: <DataCell>[
            DataCell(Text((index + 1).toString())),
            DataCell(Text('${widget.allInstructorsList[index].firstName} ${widget.allInstructorsList[index].lastName}')),
            DataCell(Text(widget.allInstructorsList[index].armyId)),
            DataCell(TextFormField(
              keyboardType: TextInputType.number,
              controller: _textEditingControllers[index],
              onChanged: (val) {
                final newVal = int.tryParse(val) ?? 0;
                setState(() {
                  widget.allInstructorsList[index].maxDays = newVal;
                  if (selected[index]) {
                    final armyId = widget.allInstructorsList[index].armyId;
                    // Find matching instructor in selectedInstructors
                    final selectedInstructor = widget.selectedInstructors
                        .firstWhereOrNull((i) => i.armyId == armyId);
                    if (selectedInstructor != null) {
                      selectedInstructor.maxDays = newVal;
                    }
                  }
                });
              },
            ))
          ],
          selected: selected[index],
          onSelectChanged: (bool? value) {
            setState(() {
              selected[index] = value!;
            });
            final selectedInstructors = <Instructor>[];
            for (int i = 0; i < widget.allInstructorsList.length; i++) {
              if (selected[i]) {
                selectedInstructors.add(widget.allInstructorsList[i]);
              }
            }
            widget.onSelectionChanged(selectedInstructors);
          },
        ),
      ),
    );
  }
}

// /// Example Firestore update
// Future<void> dbUpdateEvent(String id, Map<String, dynamic> data) async {
//   await FirebaseFirestore.instance.collection('events').doc(id).update(data);
// }
