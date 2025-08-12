
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import './utils.dart';
import 'package:shifts/pref_date_picker.dart';
import 'package:get/get.dart';
import 'exchange.dart';
import 'shifts_table_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contacts_list.dart';
import 'add_new_instructor.dart';
import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:screenshot/screenshot.dart';
import 'create_new_event.dart';
import 'system_settings_page.dart';
import 'reports.dart';
import 'remove_instructor.dart';

// itdf sfsh hwzf uuty - google pass key
// REMOVED_SECRET.YHsZPwbhshPdynL6TXUmkmr-XXuWyYWXQVYBN9w7cwk -  send grid smtp password

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initializeDateFormatting().then((_) => runApp(
        MaterialApp(
          debugShowCheckedModeBanner: true,
          home: Directionality(
            // add this
            textDirection: TextDirection.rtl, // set this property
            child: DefaultTabController(length: 3, child: Home()),
          ),
        ),
      ));
}

class Controller extends GetxController {
  var eventName = '';
  var db = FirebaseFirestore.instance;
  RxList<Instructor> eventInstructors = RxList<Instructor>();
  RxList<Instructor> selectedDayInstructors = RxList<Instructor>();
  List<String> eventDays = <String>[].obs;
  List miluimEmails = [].obs;
  List instructorsPerDay = [].obs;
  RxList<Instructor> tomorrowInstructorsList= RxList<Instructor>();
  DateTime _selectedDay = DateTime.now();
  // Rx<DateTime> _focusedDay = DateTime.utc(2023, 1, 4).obs;
  Rx<DateTime> _focusedDay = DateTime.now().obs;
  Rx<DateTime> startDate = DateTime.now().obs;
  Rx<DateTime> endDate = DateTime.now().obs;
  RxBool loading = true.obs;
  RxString statusMsg = 'loading...'.obs;
  RxBool platformOpen = true.obs;
  RxBool daysOffDone = true.obs;
  RxList daysForInstructor = [].obs;
  RxInt maxInstructorsPerDay = 0.obs;
  Rx<bool> adminUX = false.obs;
  RxList<String> admins = <String>[].obs;
  RxList<Instructor> newEventInstructors = RxList<Instructor>();
  RxList<DateTime> newEventDates = RxList<DateTime>();
  List<bool> selectedNewEventInstructors = [];
  NewEvent newEvent = NewEvent();
  List<String> eventsNameList = [];
  List<String> eventStatusModes = ['פעיל', 'סגור', 'אילוצים'];
  var currentEvent = ''.obs;
  var currentEventStatus = ''.obs;
  RxList<String> checkedIn = <String>[].obs;
  //late SharedPreferences prefs;

  @override
  onInit() async {
    await loadEventMetadata();
    await loadEventInstructors();
    await loadEventDays();
    if (platformOpen.value) {
      await loadSelectedDayInstructors(DateTime.now());
    }
    await getAssignedDays();
    await loadTomorrowDayInstructors();
    //initPref();
    //adminUX.value = prefs.getBool('admin')??false;
    loading.value = false;
    update();
    print('done init.');
    super.onInit();
  }

  initPref() async {
    //prefs = await SharedPreferences.getInstance();
  }

  bool isEventActive(String selectedEvent) {
    if (eventName==selectedEvent && platformOpen.value) {
      return true;
    } else {
      return false;
    }
  }


  loadTomorrowDayInstructors() async {
    DateTime today  = DateTime.now();
    if (today.day >= endDate.value.day || today.day< startDate.value.day-1) today = startDate.value;
    today = startDate.value;
    DateTime tomorrow = today.add(const Duration(days: 1));
    String dateKey =
        "${tomorrow.day.toString().padLeft(2, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.year.toString()}";
    DocumentReference eventDaysRef =
    db.collection('Events/$eventName/days').doc(dateKey);
    DocumentSnapshot daySnap = await eventDaysRef.get();
    tomorrowInstructorsList.clear();
    if (daySnap.exists) {
      var dayData = daySnap.data() as Map<String, dynamic>;
      List selectedDayInstructorsId = dayData['instructors'];
      int index = 0;
      while (index < eventInstructors.length) {
        if (selectedDayInstructorsId.contains(eventInstructors[index].armyId)) {
          tomorrowInstructorsList.add(eventInstructors[index]);
        }
        index++;
      }
      tomorrowInstructorsList.sort(
              (a, b) => a.firstName.toString().compareTo(b.firstName.toString()));
      update();
    }
  }

  void addInstructor(String instructorId, var instructorData) {
    eventInstructors.add(Instructor(
      instructorId,
      instructorData['first_name'] ?? 'NA',
      instructorData['last_name'] ?? 'NA',
      instructorData['mobile'] ?? 'NA',
      instructorData['email'] ?? 'NA',
      daysOff: instructorData['days_off'],
      //maxDays : instructorData['max_days']
    ));
  }

  removeInstructorFromDay(String instructorId, DateTime selectedDay) async {
    String dateKey =
        "${selectedDay.day.toString().padLeft(2, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.year.toString()}";
    DocumentReference daysRef =
        db.collection('Events/' + eventName + '/days').doc(dateKey);
    await daysRef.update({
      'instructors': FieldValue.arrayRemove([instructorId])
    });
    await daysRef.update({
      'instructors': FieldValue.arrayUnion(["--"])
    });
  }

  Future<void> addInstructorToDay(
      String instructorId, DateTime selectedDay) async {
    String dateKey =
        "${selectedDay.day.toString().padLeft(2, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.year.toString()}";
    DocumentReference daysRef =
        db.collection('Events/' + eventName + '/days').doc(dateKey);
    var Objectlist = (await daysRef.get()).data() as Map<String, dynamic>;
    List list = Objectlist['instructors'];
    int delta = list.length - maxInstructorsPerDay.value;
    //int delta = list.length - selectedDayInstructors.length;
    if (delta<0) delta = 0;
    List updatedDayList = [instructorId];
    for (var i = 0; i < delta; i++) {
      updatedDayList.add('--');
    }
    await daysRef.update({
      'instructors': FieldValue.arrayRemove(["--"])
    });
    await daysRef
        .update({'instructors': FieldValue.arrayUnion(updatedDayList)});
  }

  loadDaysForInstructor(String instructorId) async {
    daysForInstructor.value = [];
    CollectionReference eventDaysRef =
        db.collection('Events/' + eventName + '/days');
    QuerySnapshot eventDaysQuery = await eventDaysRef.get();
    eventDaysQuery.docs.forEach((day) {
      var dayData = day.data() as Map<String, dynamic>;
      List instructorList = dayData['instructors'];
      if (instructorList.contains(instructorId.trim()))
        daysForInstructor.add(day.id);
    });
    update();
    return daysForInstructor;
  }

  loadEventDays() async {
    CollectionReference eventDaysRef =
        db.collection('Events/' + eventName + '/days');
    QuerySnapshot eventDaysQuery = await eventDaysRef.get();
    eventDays = [];
    eventDaysQuery.docs.forEach((element) {
      eventDays.add(element.id);
      var dayData = element.data() as Map<String, dynamic>;
      var dayWithInstructors = [];
      dayData['instructors'].forEach((instructor) {
        dayWithInstructors.add(getInstructorData(instructor, eventInstructors));
      });
      instructorsPerDay.add(dayWithInstructors);
    });

  }

  loadEventMetadata() async {
    DocumentReference eventConfigRef = db.doc('System/config');
    DocumentSnapshot eventConfigQuery = await eventConfigRef.get();
    var eventConfig = eventConfigQuery.data() as Map<String, dynamic>;
    eventName = eventConfig['current_event'];
    currentEventStatus.value = eventConfig['event_status'];
    miluimEmails = eventConfig['miluim_emails'];
    DocumentReference eventMetadataRef = db.doc('Events/' + eventName + '');
    DocumentSnapshot eventMetadataQuery = await eventMetadataRef.get();
    var eventMetadata = eventMetadataQuery.data() as Map<String, dynamic>;
    Timestamp timestampStart = eventMetadata['start_date'];
    platformOpen.value = currentEventStatus == 'פעיל' ? true : false;
    Timestamp timestampDaysOffEndDate =
        eventMetadata['days_off_end_date'] ?? DateTime(2000);
    DateTime daysOffEndDate = timestampDaysOffEndDate.toDate();
    if (currentEventStatus.value == 'אילוצים') {
      daysOffDone.value = false;
    } else {
      daysOffDone.value =
          (daysOffEndDate.compareTo(DateTime.now()) < 0) ? false : true;
    }
    startDate.value = timestampStart.toDate();
    Timestamp timestampEnd = eventMetadata['end_date'];
    endDate.value = timestampEnd.toDate();
    _focusedDay.value = startDate.value;
    _selectedDay = _focusedDay.value;
    maxInstructorsPerDay.value = eventMetadata['instructors_per_day'];
    await loadEventsNameList();
    List _admins = eventConfig['admins'];
    _admins.forEach((admin) {
      admins.add(admin);
    });
    update();
  }

  loadEventsNameList() async {
    CollectionReference eventsListRef = db.collection('Events');
    QuerySnapshot eventsListQuery = await eventsListRef.get();
    var eventsList = eventsListQuery.docs;
    eventsList.forEach((element) {
      if (element.id != 'config') eventsNameList.add(element.id);
    });
  }

  loadEventInstructors() async {
    CollectionReference eventInstructorsRef =
        db.collection('Events/' + eventName + '/instructors');
    QuerySnapshot eventInstructorsQuery = await eventInstructorsRef.get();
    var eventInstructorsList = eventInstructorsQuery.docs;
    eventInstructorsList.forEach((element) {
      var instructorData = element.data() as Map<String, dynamic>;

      addInstructor(element.id, instructorData);
    });
    //List<Instructor> eventInstructorsSorted = eventInstructors;
    eventInstructors.sort((a, b) => a.firstName.compareTo(b.firstName));
  }

  loadSelectedDayInstructors(DateTime selectedDay) async {
    if (selectedDay.weekday == DateTime.saturday ||
        selectedDay.weekday == DateTime.friday) return;
    String dateKey =
        "${selectedDay.day.toString().padLeft(2, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.year.toString()}";
    DocumentReference eventDaysRef =
        db.collection('Events/$eventName/days').doc(dateKey);
    DocumentSnapshot daySnap = await eventDaysRef.get();
    selectedDayInstructors.clear();
    var dayData = daySnap.data() as Map<String, dynamic>;
    List selectedDayInstructorsId = dayData['instructors'];
    int index = 0;
    while (index < eventInstructors.length) {
      if (selectedDayInstructorsId.contains(eventInstructors[index].armyId)) {
        selectedDayInstructors.add(eventInstructors[index]);
      }
      index++;
    }
    selectedDayInstructors.sort(
        (a, b) => a.firstName.toString().compareTo(b.firstName.toString()));
    _selectedDay = selectedDay;
    _focusedDay.value = selectedDay;
    update();
  }

  Future<List<Instructor>> getTomorrowInstructors() async {
    List<Instructor> instructors =[];
    DateTime today  = DateTime.now();
    DateTime tomorrow = today.add(const Duration(days: 1));
    String dateKey =
        "${tomorrow.day.toString().padLeft(2, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.year.toString()}";
    CollectionReference instructorsDayRef =
    db.collection('Events/$eventName/days/$dateKey/instructors');
    QuerySnapshot instructorsDaySnap = await instructorsDayRef.get();
    var instructorsList = instructorsDaySnap.docs;
    for (var element in instructorsList) {
      var instructorData = element.data() as Map<String, dynamic>;
      instructors.add(Instructor(
        element.id,
        instructorData['first_name'],
        instructorData['last_name'],
        instructorData['mobile'],
        instructorData['email'],
      ));
    }
    return instructors;
  }

  getDayInstructorsList(DateTime selectedDay) async {
    if (selectedDay.weekday == DateTime.saturday ||
        selectedDay.weekday == DateTime.friday) return;
    String dateKey =
        "${selectedDay.day.toString().padLeft(2, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.year.toString()}";
    DocumentReference eventDaysRef =
    db.collection('Events/$eventName/days').doc(dateKey);
    DocumentSnapshot daySnap = await eventDaysRef.get();
    selectedDayInstructors.clear();
    var dayData = daySnap.data() as Map<String, dynamic>;
    List selectedDayInstructorsId = dayData['instructors'];
    int index = 0;
    while (index < eventInstructors.length) {
      if (selectedDayInstructorsId.contains(eventInstructors[index].armyId)) {
        selectedDayInstructors.add(eventInstructors[index]);
      }
      index++;
    }
    selectedDayInstructors.sort(
            (a, b) => a.firstName.toString().compareTo(b.firstName.toString()));
    _selectedDay = selectedDay;
    _focusedDay.value = selectedDay;
    update();
  }

  updateSettings() async {
    DocumentReference eventConfigRef = db.doc('System/config');
    await eventConfigRef.update({
      'current_event': currentEvent.value,
      'event_status': currentEventStatus.value,
      'admins': admins
    });
    // refresh data of the system
    await loadEventMetadata();
    await loadEventInstructors();
    await loadEventDays();
    if (platformOpen.value) {
      await loadSelectedDayInstructors(_focusedDay.value);
    }
    await getAssignedDays();
    return;
  }

  updateCheckedIn(selectedDay) async {
    String dateKey =
        "${selectedDay.day.toString().padLeft(2, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.year.toString()}";
    db.collection('Events/$eventName/days').doc(dateKey).update({
      'checked_in' : checkedIn
    });
  }

  sendMyDaysMail(instructorId, days) async {
    var instructorData = getInstructorData(instructorId, eventInstructors);
    var subject = "-" + "המשמרות שלי בימי סיירות " + "-";
    var text = " רשימת הימים להיתיצבות " + "\n";
    text = text + "\n" + days.toString();
    var lines = '<p style="text-align:center">&nbsp;</p>';
    lines +=
        '<table align="center" border="3" cellpadding="20" cellspacing="1" dir="rtl" style="width:500px">';
    lines += '	<thead>';
    lines += '		<tr>';
    lines +=
        '			<center><img src="https://upload.wikimedia.org/wikipedia/he/7/72/%D7%9C%D7%95%D7%92%D7%95_%D7%A2%D7%9E%D7%95%D7%AA%D7%AA_%D7%94%D7%A2%D7%98%D7%9C%D7%A3.png" alt="Atalef" width="150"></center>';
    lines += '		</tr>';
    lines += '	</thead>';
    lines += '	<tbody>';
    lines += '		<tr>';
    lines +=
        '			<th scope="col" style="width:374px"><span style="font-size:20px"><span style="color:#e74c3c"> רשימת הימים שלך להתייצבות  </span></span</th>';
    lines += '		</tr>';
    for (var day in days) {
      lines += '		<tr>';
      lines += '			<td style="text-align:center" style="width:374px">' +
          day.toString() +
          '</td>';
      lines += '		</tr>';
    }
    lines += '		<tr>';
    lines +=
        '			<td style="text-align:center"><a href="https://yemey-siarot.web.app/">לחץ לאפליקציה</a></td>';
    lines += '		</tr>';
    lines += '	</tbody>';
    lines += '</table>';
    lines += '<p style="text-align:right">&nbsp;</p>';
    await db.collection('mail').add({
      'to': instructorData['email'],
      'message': {'subject': subject, 'text': text, 'html': lines}
    });
  }

  getAssignedDays() async {
    for (List day in instructorsPerDay) {
      for (var instructor in day) {
        var instructorIndex = eventInstructors
            .indexWhere((element) => element.armyId == instructor['armyId']);
        if (instructorIndex > -1) {
          eventInstructors[instructorIndex].addAssignedDay();
        }
      }
    }
  }

  sendMiluimDayReportMail(
      List<Instructor> instructorsList, String dateKey) async {
    var subject = "-" + " דוח יומי מילואים " + "-";
    var text = " רשימת המדריכים היומית " + "\n";
    text = text + "\n" + instructorsList.toString();
    var lines = '<p style="text-align:center">&nbsp;</p>';
    lines +=
        '<table align="center" border="3" cellpadding="20" cellspacing="1" dir="rtl" style="width:500px">';
    lines += '	<thead>';
    lines += '		<tr>';
    lines +=
        '			<center><img src="https://upload.wikimedia.org/wikipedia/he/7/72/%D7%9C%D7%95%D7%92%D7%95_%D7%A2%D7%9E%D7%95%D7%AA%D7%AA_%D7%94%D7%A2%D7%98%D7%9C%D7%A3.png" alt="Atalef" width="150"></center>';
    lines += '		</tr>';
    lines += '	</thead>';
    lines += '	<tbody>';
    lines += '		<tr>';
    lines +=
        '</th><th scope="col" style="width:374px"><span style="font-size:20px"><span style="color:#e74c3c">' +
            dateKey +
            ' רשימת המדריכים היומית  </span></span</th>';
    lines += '		</tr>';
    for (var instructor in instructorsList) {
      lines += '		<tr>';
      lines += '			<td style="text-align:center" style="width:374px">' +
          instructor.firstName +
          '  ' +
          instructor.lastName +
          '</td>';
      lines += '		</tr>';
    }
    lines += '		<tr>';
    lines +=
        '			<td style="text-align:center"><a href="https://yemey-siarot.web.app/">לחץ לאפליקציה</a></td>';
    lines += '		</tr>';
    lines += '	</tbody>';
    lines += '</table>';
    lines += '<p style="text-align:right">&nbsp;</p>';
    await db.collection('mail').add({
      'to': miluimEmails,
      'message': {'subject': subject, 'text': text, 'html': lines}
    });
  }

  saveEventInstructorsReportCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(['שם משפחה', 'שם פרטי', 'מספר אישי']);
    for (var instructor in eventInstructors) {
      rows.add([
        instructor.lastName,
        instructor.firstName,
        instructor.armyId.toString()
      ]);
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
      name: 'Event Instructors Report ${DateTime.now().toIso8601String()}', // you can give the CSV file name here.
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  saveTomorrowInstructorsCSV(String title, List<TextEditingController> groups) async {
    List<List<dynamic>> rows = [];
    rows.add([ 'קבוצה','שם משפחה', 'שם פרטי']);
    var index = 0;
    for (var instructor in tomorrowInstructorsList) {
      rows.add([
        groups[index].text,
        instructor.lastName,
        instructor.firstName,
      ]);
      index++;
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
      name: '$title  ${DateTime.now().toIso8601String()}', // you can give the CSV file name here.
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  saveInstructorsDayCountReportCSV(String dateKey) async {
    List<List<dynamic>> rows = [];
    rows.add(['ימים מוקצים','שם משפחה', 'שם פרטי', 'מספר אישי']);
    for (var instructor in eventInstructors) {
      rows.add([
        instructor.assignDays.toString(),
        instructor.lastName,
        instructor.firstName,
        instructor.armyId.toString()
      ]);
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
      name: dateKey, // you can give the CSV file name here.
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  saveMiluimDayReportCSV(
      List<Instructor> instructorsList, String dateKey) async {
    List<List<dynamic>> rows = [];
    rows.add(['שם משפחה', 'שם פרטי', 'מספר אישי']);
    for (var instructor in instructorsList) {
      rows.add([
        instructor.lastName,
        instructor.firstName,
        instructor.armyId.toString()
      ]);
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
      name: dateKey, // you can give the CSV file name here.
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  saveMiluimDayReportImage(bytes, String title) async {
    await FileSaver.instance.saveFile(
      name: title,
      bytes: bytes,
      ext: 'jpeg',
      mimeType: MimeType.jpeg,
    );
  }
}

class Home extends StatelessWidget {
  final controller = Get.put(Controller());
  CalendarFormat _calendarFormat = CalendarFormat.week;
  List<Instructor> _getInstructorsForDay(DateTime selectedDay) {
    return controller.selectedDayInstructors;
  }

  Future<List> _getDaysForInstructor(String instructorId) async {
    return await controller.loadDaysForInstructor(instructorId);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    await controller.loadSelectedDayInstructors(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    final Controller controller = Get.put(Controller());
    final _formKey = GlobalKey<FormState>();
    final instructorIdController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: GestureDetector(
                onDoubleTap: () async {
                  bool? res = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) =>
                          AdminPinDialog(controller.admins));
                  controller.adminUX.value = res ?? false;
                  //await controller.prefs.setBool('admin', res??false);
                },
                child: Column(children: [
                  SizedBox(
                      width: 80,
                      child: Image.network('assets/images/logo.png')),
                  const Text(
                    'ימי סיירות',
                    style: TextStyle(fontSize: 20),
                  )
                ]))),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.calendar_month_rounded)),
            Tab(icon: Icon(Icons.list_outlined)),
            Tab(icon: Icon(Icons.person)),
          ],
        ),
      ),
      drawer: Drawer(
        child: Obx(() => ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text('תפריט ראשי'),
                ),
                controller.platformOpen.value
                    ? ListTile(
                        leading: const Icon(
                          Icons.date_range,
                        ),
                        title: const Text('לו״ז'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      )
                    : const Text(''),
                !controller.daysOffDone.value
                    ? ListTile(
                        leading: const Icon(
                          Icons.date_range_rounded,
                        ),
                        title: const Text('הזן  אילוצים'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Obx(() => PrefDatePicker(
                                  startDate: controller.startDate.value,
                                  endDate: controller.endDate.value,
                                  eventDays: controller.eventDays)),
                            ),
                          );
                        },
                      )
                    : const Text(''),
                controller.platformOpen.value
                    ? ListTile(
                        // to do fix hardcode of no exchange
                        leading: const Icon(
                          Icons.edit,
                        ),
                        title: const Text('החלפות  ומסירות'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => Directionality(
                                      // add this
                                      textDirection: TextDirection
                                          .rtl, // set this property
                                      child: ExchangeHome(),
                                    )),
                          );
                        },
                      )
                    : const Text(''),
                !controller.loading.value && controller.platformOpen.value
                    ? ListTile(
                        leading: const Icon(
                          Icons.contacts_outlined,
                        ),
                        title: const Text('דף קשר'),
                        onTap: () {
                          List allInstructors = controller.eventInstructors;
                          allInstructors.sort((a, b) {
                            return a.firstName
                                .toString()
                                .compareTo(b.firstName.toString());
                          });
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => Directionality(
                                      // add this
                                      textDirection: TextDirection
                                          .rtl, // set this property
                                      child: ContactsListPage(
                                          eventInstructors:
                                              controller.eventInstructors),
                                    )),
                          );
                        },
                      )
                    : const Text(''),
                (!controller.loading.value && controller.adminUX.value)
                    ? Divider(
                        thickness: 10,
                      )
                    : const Text(''),
                (!controller.loading.value && controller.adminUX.value)
                    ? ListTile(
                        leading: const Icon(
                          Icons.add_outlined,
                        ),
                        title: const Text('הוסף מדריך למערכת'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const Directionality(
                                      // add this
                                      textDirection: TextDirection
                                          .rtl, // set this property
                                      child: AddNewInstructor(),
                                    )),
                          );
                        },
                      )
                    : const Text(''),
                (!controller.loading.value && controller.adminUX.value)
                    ? ListTile(
                  leading: const Icon(
                    Icons.add_outlined,
                  ),
                  title: const Text('הסר מדריך מהמערכת'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const Directionality(
                          textDirection: TextDirection.rtl,
                          child: RemoveInstructor(),
                        ),
                      ),
                    );
                  },
                )
                    : const Text(''),
                (!controller.loading.value && controller.adminUX.value)
                    ? ListTile(
                        leading: const Icon(
                          Icons.add_outlined,
                        ),
                        title: const Text('פתיחת ארוע חדש'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => Directionality(
                                    // add this
                                    textDirection:
                                        TextDirection.rtl, // set this property
                                    child: CreateNewEvent())),
                          );
                        },
                      )
                    : const Text(''),
                (!controller.loading.value && controller.adminUX.value)
                    ? ListTile(
                        leading: const Icon(
                          Icons.add_outlined,
                        ),
                        title: const Text('הגדרות מערכת'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => Directionality(
                                    // add this
                                    textDirection:
                                        TextDirection.rtl, // set this property
                                    child: SystemSettingsPage())),
                          );
                        },
                      )
                    : const Text(''),
                (!controller.loading.value && controller.adminUX.value)
                    ? ListTile(
                        leading: const Icon(
                          Icons.add_outlined,
                        ),
                        title: const Text('הפקת דוחות'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const Directionality(
                                    // add this
                                    textDirection:
                                        TextDirection.rtl, // set this property
                                    child: Reports())),
                          );
                        },
                      )
                    : const Text(''),
              ],
            )),
      ),
      body: Obx(() => !controller.loading.value
          ? controller.platformOpen.value || controller.adminUX.value
              ? TabBarView(children: [
                  Center(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 20),
                        Obx(() => SizedBox(
                              height: 150,
                              width: 400,
                              child: TableCalendar(
                                locale: 'he_HE',
                                headerStyle: const HeaderStyle(
                                    titleCentered: true,
                                    formatButtonVisible: false),
                                weekendDays: [
                                  DateTime.friday,
                                  DateTime.saturday
                                ],
                                firstDay: controller.startDate.value,
                                lastDay: controller.endDate.value,
                                focusedDay: controller._focusedDay.value,
                                calendarFormat: _calendarFormat,
                                selectedDayPredicate: (day) =>
                                    isSameDay(controller._selectedDay, day),
                                enabledDayPredicate: (day) {
                                  String dateKey =
                                      "${day.day.toString().padLeft(2, '0')}-${day.month.toString().padLeft(2, '0')}-${day.year.toString()}";
                                  return controller.eventDays.contains(dateKey);
                                  // return controller.eventDays
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
                                eventLoader: _getInstructorsForDay,
                                onDaySelected: _onDaySelected,
                                onDayLongPressed: (selected, focused) async {
                                  if (!controller.adminUX.value) return;
                                  await controller
                                      .loadSelectedDayInstructors(selected);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => DayReportPage(
                                          eventInstructors:
                                              controller.selectedDayInstructors,
                                          selectedDay: selected),
                                    ),
                                  );
                                },
                              ),
                            )),
                        Expanded(
                          child: Obx(() => ListView.builder(
                              itemCount:
                                  controller.selectedDayInstructors.length,
                              itemBuilder: (context, index) {
                                final instructor =
                                    controller.selectedDayInstructors[index];
                                final Uri telLaunchUri = Uri(
                                  scheme: 'tel',
                                  path: instructor.mobile,
                                );
                                final Uri smsLaunchUri = Uri(
                                  scheme: 'sms',
                                  path: instructor.mobile,
                                  queryParameters: <String, String>{},
                                );
                                return Card(
                                    child: ExpansionTile(
                                  expandedAlignment: Alignment.topRight,
                                  title: Text(
                                      '${index + 1}. ${instructor.firstName} ${instructor.lastName}'),
                                  children: [
                                    Row(
                                      children: [
                                        Text(' נייד ${instructor.mobile} '),
                                        ElevatedButton(
                                          style: const ButtonStyle(
                                            visualDensity: VisualDensity(
                                                horizontal: VisualDensity
                                                    .minimumDensity,
                                                vertical: VisualDensity
                                                    .minimumDensity),
                                          ),
                                          onPressed: () async =>
                                              {await launchUrl(telLaunchUri)},
                                          child: const Text('חייג'),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        ElevatedButton(
                                          style: const ButtonStyle(
                                            visualDensity: VisualDensity(
                                                horizontal: VisualDensity
                                                    .minimumDensity,
                                                vertical: VisualDensity
                                                    .minimumDensity),
                                          ),
                                          onPressed: () async =>
                                              {await launchUrl(smsLaunchUri)},
                                          child: const Text('הודעה'),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        Obx(() => controller.adminUX.value
                                            ? ElevatedButton(
                                                style: const ButtonStyle(
                                                  visualDensity: VisualDensity(
                                                      horizontal: VisualDensity
                                                          .minimumDensity,
                                                      vertical: VisualDensity
                                                          .minimumDensity),
                                                ),
                                                onPressed: () async {
                                                  bool? res =
                                                      await showDialog<bool>(
                                                          context: context,
                                                          builder: (BuildContext
                                                                  context) =>
                                                              YesNoDialog());
                                                  if (res ?? false) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                        'מסיר מדריך מהרשימה',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      )),
                                                    );
                                                    await controller
                                                        .removeInstructorFromDay(
                                                            instructor.armyId,
                                                            controller
                                                                ._selectedDay);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                        'המדריך הוסר',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      )),
                                                    );
                                                  }
                                                },
                                                child: const Text('הסר'),
                                              )
                                            : SizedBox(
                                                width: 1,
                                              )),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    )
                                  ],
                                ));
                              })),
                        ),
                        Obx(() => controller.adminUX.value
                            ? Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: ElevatedButton(
                                  style: const ButtonStyle(
                                    visualDensity: VisualDensity(
                                        horizontal:
                                            VisualDensity.minimumDensity,
                                        vertical: VisualDensity.minimumDensity),
                                  ),
                                  onPressed: () async {
                                    String? res = await showDialog<String>(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            AddInstructorDialog());
                                    Instructor? foundInstructor = controller
                                        .eventInstructors
                                        .firstWhereOrNull(
                                            (element) => element.armyId == res);
                                    if (foundInstructor?.armyId != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                          'הוסף מדריך לרשימה',
                                          style: TextStyle(color: Colors.white),
                                        )),
                                      );
                                      await controller.addInstructorToDay(
                                          res!, controller._selectedDay);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                          'המדריך הוסף',
                                          style: TextStyle(color: Colors.white),
                                        )),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                          'מבוטל או ת.ז. לא תקינה',
                                          style: TextStyle(color: Colors.white),
                                        )),
                                      );
                                    }
                                  },
                                  child: const Text('הוסף מדריך'),
                                ),
                              )
                            : SizedBox(
                                width: 1,
                              ))
                      ],
                    ),
                  ),
                  Obx(() => Center(
                        child: ShiftsTableView(
                          instructorsPerDayList: controller.instructorsPerDay,
                          daysList: controller.eventDays,
                          maxInstructorsPerDay:
                              controller.maxInstructorsPerDay.value,
                        ),
                      )),
                  Center(
                    child: Column(
                      children: [
                        //Container(child: Image.asset('images/logo.png'), width: 75),
                        SizedBox(height: 30),
                        SizedBox(
                          width: 200,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('מיין לפי תעודת  זהות'),
                                TextFormField(
                                  controller: instructorIdController,
                                  // The validator receives the text that the user has entered.
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      'לא הוזן כלום!';
                                    }
                                    return null;
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      //instructorIdController.text='4687061'; // for debug
                                      // Validate returns true if the form is valid, or false otherwise.
                                      if (_formKey.currentState!.validate()) {
                                        // If the form is valid, display a snackbar. In the real world,
                                        // you'd often call a server or save the information in a database.

                                        var gotData =
                                            await _getDaysForInstructor(
                                                instructorIdController.text);
                                        if (gotData.length == 0) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('לא נמצאו ימים!!!')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('חפש'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        controller.daysForInstructor.length > 0
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    controller.sendMyDaysMail(
                                        instructorIdController.text,
                                        controller.daysForInstructor);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                        'המידע נשלח אליך למייל האישי',
                                        style: TextStyle(color: Colors.white),
                                      )),
                                    );
                                  },
                                  child: Container(
                                    width: 180,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: const [
                                        Icon(Icons.mail_outline_sharp),
                                        Text('שלח את המידע למייל שלי'),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(
                                height: 10,
                              ),
                        Expanded(
                            child: Obx(() => SizedBox(
                                  width: 150,
                                  child: ListView.builder(
                                      itemCount:
                                          controller.daysForInstructor.length,
                                      itemBuilder: (context, index) {
                                        return Card(
                                          color: Colors.lightGreenAccent,
                                          child: Text(
                                            controller.daysForInstructor[index],
                                            style: TextStyle(fontSize: 20),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }),
                                ))),
                      ],
                    ),
                  ),
                ])
              : EventNotOpen(controller.daysOffDone.value)
          : const LoadingLogo()),
    );
  }
}

class LoadingLogo extends StatelessWidget {
  const LoadingLogo({super.key});

  // This widget is the home page of your application.

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 200,
        ),
        Center(
            child: Container(
                width: 350, child: Image.network('assets/images/logo_round.png'))),
        Center(
            child: Container(
                child: const Text(
          'טוען נתונים',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ))),
      ],
    );
  }
}

class EventNotOpen extends StatelessWidget {
  bool daysOffDone;
  EventNotOpen(this.daysOffDone, {super.key});

  // This widget is the home page of your application.

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 200,
        ),
        Center(
            child: Container(
                width: 350, child: Image.network('assets/images/logo.png'))),
        Center(
            child: Container(
                child: Text(
          daysOffDone ? 'המערכת סגורה' : 'המערכת פתוחה רק להזנת אילוצים' ,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ))),
      ],
    );
  }
}

class DayReportPage extends StatefulWidget {
  final List<Instructor> eventInstructors;
  final DateTime selectedDay;

  const DayReportPage(
      {super.key, required this.eventInstructors, required this.selectedDay});
  @override
  State<DayReportPage> createState() => _DayReportPageState();
}

class _DayReportPageState extends State<DayReportPage> {
  ScreenshotController screenshotController = ScreenshotController();
  final controller = Get.put(Controller());


  @override
  Widget build(BuildContext context) {
    String dateKey =
        "${widget.selectedDay.day.toString().padLeft(2, '0')}-${widget.selectedDay.month.toString().padLeft(2, '0')}";
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                controller.updateCheckedIn(widget.selectedDay);
                Navigator.of(context).pop();
              },
            ),
            title: const Text('הכנת דוח ימי מילואים'),
          ),
          body: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      screenshotController
                          .captureFromLongWidget(
                        InheritedTheme.captureAll(
                          context,
                          Material(
                              child: DayReportImage(
                                  widget.eventInstructors, dateKey),
                          ),
                        ),
                        delay: Duration(milliseconds: 100),
                        context: context,
                      )
                          .then((capturedImage) async {
                        await controller.saveMiluimDayReportImage(
                            capturedImage, dateKey);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                          'הקובץ נשמר',
                          style: TextStyle(color: Colors.white),
                        )),
                      );
                    },
                    child: Container(
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Icon(Icons.save_alt),
                          Text('הורד דוח'),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.saveMiluimDayReportCSV(
                          controller.eventInstructors, dateKey);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                          'הקובץ נשמר',
                          style: TextStyle(color: Colors.white),
                        )),
                      );
                    },
                    child: Container(
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Icon(Icons.table_rows_outlined),
                          Text('שמור לקובץ CSV'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    child: Center(
                      child: ListView.builder(
                          itemCount: widget.eventInstructors.length,
                          itemBuilder: (context, index) {
                            final instructor = widget.eventInstructors[index];
                            return Row(
                              children: [
                                Checkbox(
                                  checkColor: Colors.white,
                                  fillColor: MaterialStateProperty.resolveWith(
                                      (states) {
                                    if (states
                                        .contains(MaterialState.disabled)) {
                                      return Colors.amber;
                                    } else if (states
                                        .contains(MaterialState.dragged)) {
                                      return Colors.blue;
                                    } else if (states
                                        .contains(MaterialState.error)) {
                                      return Colors.brown;
                                    } else if (states
                                        .contains(MaterialState.focused)) {
                                      return Colors.deepOrange;
                                    } else if (states
                                        .contains(MaterialState.hovered)) {
                                      return Colors.cyan;
                                    } else if (states
                                        .contains(MaterialState.pressed)) {
                                      return Colors.green;
                                    } else if (states.contains(
                                        MaterialState.scrolledUnder)) {
                                      return Colors.pink;
                                    } else if (states
                                        .contains(MaterialState.selected)) {
                                      return Colors.teal;
                                    }
                                    return null;
                                  }),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      !controller.checkedIn
                                              .contains(instructor.armyId)
                                          ? controller.checkedIn
                                              .add(instructor.armyId)
                                          : controller.checkedIn
                                              .remove(instructor.armyId);
                                    });
                                  },
                                  value: controller.checkedIn
                                      .contains(instructor.armyId),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Card(
                                      child: Text(
                                    '${index + 1}. ${instructor.firstName} ${instructor.lastName}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24),
                                  )),
                                ),
                              ],
                            );
                          }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

class YesNoDialog extends StatelessWidget {
  const YesNoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('האם אתה בטוח'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('כן'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('לא'),
        ),
      ],
    );
  }
}

class AdminPinDialog extends StatelessWidget {
  final List admins;
  AdminPinDialog(this.admins, {super.key});
  String id = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.only(left: 80.0, top: 20),
      title: const Text('הרשאת מנהל'),
      content: TextField(onChanged: (_id) {
        id = _id;
      }),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            if (admins.contains(id)) {
              return Navigator.pop(context, true);
            } else {
              return Navigator.pop(context, false);
            }
          },
          child: const Text('אישור'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ביטול'),
        ),
      ],
    );
  }
}

class AddInstructorDialog extends StatelessWidget {
  const AddInstructorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    String id = '';
    return AlertDialog(
      title: const Text('הזן ת.ז. של המדריך'),
      content: TextField(onChanged: (_id) {
        id = _id;
      }),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, id),
          child: const Text('הוסף'),
        ),
        TextButton(
          onPressed: () => {
            Navigator.pop(context, ''),
          },
          child: const Text('ביטול'),
        ),
      ],
    );
  }
}

class DayReportImage extends StatelessWidget {
  final List<Instructor> eventInstructors;
  final String dateKey;

  DayReportImage(this.eventInstructors, this.dateKey, {super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Image.network(
              'assets/images/logo.png',
              height: 50,
            ),
            const Text(
              'דוח מילואים יומי',
              style: TextStyle(fontSize: 20),
            ),
            Text(dateKey, style: TextStyle(fontSize: 18)),
            const SizedBox(
                width: 200,
                child: Divider(
                  thickness: 2,
                  color: Colors.black,
                )),
            Container(
              height: 800,
              width: 300,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                      eventInstructors.length,
                      (index) => Row(
                              textDirection: TextDirection.rtl,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 50),
                                  child: Text('.${index + 1}'),
                                ),
                                Text(
                                  eventInstructors[index].armyId,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 8.0),
                                  child:
                                      Text(eventInstructors[index].firstName),
                                ),
                                Text(eventInstructors[index].lastName),
                              ]))),
            ),
          ],
        ));
  }
}

/*
 Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('.${index + 1}'),
                      ),
                      Text(
                        eventInstructors[index].armyId,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: Text(eventInstructors[index].firstName),
                      ),
                      Text(eventInstructors[index].lastName),
                    ]);

 */
