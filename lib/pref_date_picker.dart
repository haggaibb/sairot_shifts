import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import './utils.dart';
import 'dart:collection';

class PrefDatePicker extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<String> eventDays;

  PrefDatePicker({Key? key, DateTime? startDate, DateTime? endDate, List<String>? eventDays})
      : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now(),
        eventDays = eventDays ?? [];
  @override
  State<PrefDatePicker> createState() => _PrefDatePickerState();
}

class _PrefDatePickerState extends State<PrefDatePicker> {
  var db = FirebaseFirestore.instance;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _focusedDay;
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  var eventMetadata;
  var eventName = '';
  var eventInstructors = [];
  var editDaysOffEndDate = DateTime.now();
  var isLoading = true;
  loadEventMetadata() async {
    DocumentReference eventConfigRef = db.doc('System/config');
    DocumentSnapshot eventConfigQuery = await eventConfigRef.get();
    var eventConfig = eventConfigQuery.data() as Map<String, dynamic>;
    eventName = eventConfig['current_event'];
    DocumentReference eventMetadataRef = db.doc('Events/$eventName');
    DocumentSnapshot eventMetadataQuery = await eventMetadataRef.get();
    eventMetadata = eventMetadataQuery.data() as Map<String, dynamic>;
    CollectionReference eventInstructorsRef =
        db.collection('Events/$eventName/instructors');
    QuerySnapshot eventInstructorsQuery = await eventInstructorsRef.get();
    var eventInstructorsList = eventInstructorsQuery.docs;
    for (var element in eventInstructorsList) {
      eventInstructors.add(element.id);
    }
    Timestamp timestampDaysOffEndDate = eventMetadata['days_off_end_date'];
    setState(() {
      editDaysOffEndDate = timestampDaysOffEndDate.toDate();
      isLoading = false;
    });
  }


  Future<void> addDaysOffRequest(instructorId) async {
    DocumentReference initialDaysOffRequest = FirebaseFirestore.instance
        .collection('/Events/$eventName/instructors/')
        .doc(instructorId);
    initialDaysOffRequest.update({
      'days_off': _selectedDays,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הנתונים הוזנו בהצלחה...')));
      Navigator.pop(context);
      Navigator.pop(context);
    }).catchError((error) => ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('הזנת הנתונים נכשלה !!!'))));
  }
  isValidId(id) {
    if (eventInstructors.contains(id)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    _getThingsOnStartup().then((value) {
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _getThingsOnStartup() async {
    await loadEventMetadata();
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
    final formKey = GlobalKey<FormState>();
    final instructorIdController = TextEditingController();
    return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('בחירת ימי חופש'),
            ),
            body: Center(
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    height: 30,
                    child: Center(
                        child: Text(
                      'נא סמן את הימים שאינך יכול',
                      style: TextStyle(fontSize: 20),
                    )),
                  ),
                  const SizedBox(
                    height: 30,
                    child: Center(
                        child: Text(
                          'שים לב! כל הזנה חדשה תמחק הזנה קודמת!',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        )),
                  ),//Title
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
                          const Text('הזן ת.ז.'),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            controller: instructorIdController,
                            // The validator receives the text that the user has entered.
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'לא הוזן כלום!';
                              } else if (!isValidId(value)) {
                                return 'מספר אישי לא קיים במערכת!';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                // Validate returns true if the form is valid, or false otherwise.
                                if (formKey.currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('מזין נתונים...')),
                                  );
                                  await addDaysOffRequest(
                                      instructorIdController.text);
                                }
                              },
                              child: const Text('עדכן'),
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
