import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import './utils.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class ExchangeController extends GetxController {
  var db = FirebaseFirestore.instance;
  var eventName = '';
  RxBool requestsLoading = true.obs;
  List<Request> allRequests = <Request>[].obs;
  RxList<Request> selectedDayRequests = RxList<Request>();
  RxList<Instructor> eventInstructors = RxList<Instructor>();
  RxList<Instructor> selectedDayInstructors = RxList<Instructor>();
  RxList<String> daysForInstructor = <String>[].obs;
  RxList<String> daysForInstructorNoLimit = <String>[].obs;
  RxList<String> daysWithoutInstructor = <String>[].obs;
  RxList<String> listOfAdminIds = <String>[].obs;
  DateTime? _selectedDay;
  Rx<DateTime> _focusedDay = DateTime.now().obs;
  Rx<DateTime> startDate = DateTime.now().obs;
  Rx<DateTime> endDate = DateTime.now().obs;
  late Rx<String> selectedTakeDayMills;
  @override
  onInit() async {
    await loadEventMetadata();
    await loadEventInstructors();
    await loadAllRequests();
    requestsLoading.value = false;
    super.onInit();
    //await loadSelectedDayRequests(_focusedDay.value);
  }

  void addInstructor(String instructorId, var instructorData) {
    var maxDaysInt = int.parse(instructorData['max_days']);
    eventInstructors.add(Instructor(
        instructorId,
        instructorData['first_name'],
        instructorData['last_name'],
        instructorData['mobile'],
        instructorData['email'],
        instructorData['max_days']
    ));
  }

  void addDayRequest(String requestId, var requestData) {
    Timestamp timestampRequestInit = requestData['request_init'];
    Timestamp timestampRequestGiveDay = requestData['give_day'];
    // Convert take_day from List<dynamic> to List<DateTime>
    List<dynamic>? takeDayList = requestData['take_day'];
    List<DateTime>? convertedTakeDayList = takeDayList?.map((element) {
          Timestamp ts = element as Timestamp;
          return ts.toDate();
        }).toList() ??
        [DateTime(1971)];
    selectedDayRequests.add(Request(
        requestData['instructor_id'],
        requestData['full_name'],
        timestampRequestInit.toDate(),
        requestData['type'] ?? 'NA',
        timestampRequestGiveDay.toDate(),
        convertedTakeDayList,
        requestId));
  }

  void addToAllRequests(String requestId, var requestData) {
    Timestamp timestampRequestInit = requestData['request_init'];
    Timestamp timestampRequestGiveDay = requestData['give_day'];
    List timestampRequestTakeDays = requestData['take_day'];
    List<DateTime> takeDays = timestampRequestTakeDays
        .map((e) =>
            DateTime.fromMillisecondsSinceEpoch(e.millisecondsSinceEpoch))
        .toList();
    allRequests.add(Request(
        requestData['instructor_id'],
        requestData['full_name'],
        timestampRequestInit.toDate(),
        requestData['type'] ?? 'NA',
        timestampRequestGiveDay.toDate(),
        takeDays,
        requestId));
  }

  loadEventMetadata() async {
    DocumentReference eventConfigRef = db.doc('Events/config');
    DocumentSnapshot eventConfigQuery = await eventConfigRef.get();
    var eventConfig = eventConfigQuery.data() as Map<String, dynamic>;
    eventName = eventConfig['current_event'];
    DocumentReference eventMetadataRef = db.doc('Events/' + eventName + '');
    DocumentSnapshot eventMetadataQuery = await eventMetadataRef.get();
    var eventMetadata = eventMetadataQuery.data() as Map<String, dynamic>;
    Timestamp timestampStart = eventMetadata['start_date'];
    startDate.value = timestampStart.toDate();
    Timestamp timestampEnd = eventMetadata['end_date'];
    endDate.value = timestampEnd.toDate();
    _focusedDay.value = startDate.value;
    update();
    //List adminList = ['4687061']; //// todo change to daynamic
    List adminList = eventConfig['admin_id_list'];
    List<String> adminIdList = adminList.map((e) => e.toString()).toList();
    listOfAdminIds.value = adminIdList;
  }

  loadEventInstructors() async {
    CollectionReference eventInstructorsRef =
        db.collection('Events/$eventName/instructors');
    QuerySnapshot eventInstructorsQuery = await eventInstructorsRef.get();
    var eventInstructorsList = eventInstructorsQuery.docs;
    eventInstructorsList.forEach((element) {
      var instructorData = element.data() as Map<String, dynamic>;
      addInstructor(element.id, instructorData);
    });
  }

  loadSelectedDayRequests(DateTime selectedDay) async {
    String dateKey =
        "${selectedDay.day.toString().padLeft(2, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.year.toString()}";
    CollectionReference requestsDaysRef =
        db.collection('Events/$eventName/days/$dateKey/requests');
    QuerySnapshot requestsDaySnap = await requestsDaysRef.get();
    var requestsDayList = requestsDaySnap.docs;
    selectedDayRequests.clear();
    for (var element in requestsDayList) {
      var requestData = element.data() as Map<String, dynamic>;
      if (requestData['take_day'].length < 1)
        requestData['take_day'] = [Timestamp.fromDate(DateTime(1971))];
      addDayRequest(element.id, requestData);
    }
    _selectedDay = selectedDay;

    _focusedDay.value = selectedDay;
    update();
  }




  Future<void> loadAllRequests() async {
    DateTime today = DateTime.now();
    //today = DateTime(2025,1,17);
    allRequests.clear();
    CollectionReference eventDaysRef = db.collection('Events/$eventName/days');
    QuerySnapshot eventDaysQuery = await eventDaysRef.get();
    // Use a regular for loop or for-in loop instead of forEach
    for (var day in eventDaysQuery.docs) {
      var dayData = day.data() as Map<String, dynamic>;
      var dayDate = dayData['date'].toDate();
      String dateKey =
          "${dayDate.day.toString().padLeft(2, '0')}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.year.toString()}";
      // CollectionReference expiredRequestsDaysRef = db.collection('Events/$eventName/days/$dateKey/requests');
      // QuerySnapshot expiredRequestsDaySnap = await expiredRequestsDaysRef
      //     .where('give_day', isLessThanOrEqualTo: today)
      //     .get();
      // for (var expiredDay in expiredRequestsDaySnap.docs) {
      //   await expiredDay.reference.delete();
      // }
      CollectionReference requestsDaysRef =
          db.collection('Events/$eventName/days/$dateKey/requests');
      QuerySnapshot requestsDaySnap =
          await requestsDaysRef.where('give_day', isGreaterThan: today).get();
      if (requestsDaySnap.size > 0) {
        var requestsDayList = requestsDaySnap.docs;
        for (var element in requestsDayList) {
          var requestData = element.data() as Map<String, dynamic>;
          addToAllRequests(element.id, requestData);
        }
      }
    }
    update();
  }

  loadDaysForInstructor(String instructorId) async {
    daysForInstructor.value = [];
    CollectionReference eventDaysRef =
        db.collection('Events/' + eventName + '/days');
    QuerySnapshot eventDaysQuery = await eventDaysRef.get();
    eventDaysQuery.docs.forEach((day) {
      var dayData = day.data() as Map<String, dynamic>;
      List instructorList = dayData['instructors'];
      if (instructorList.contains(instructorId)) daysForInstructor.add(day.id);
    });
    update();
    return daysForInstructor;
  }

  loadDaysWithoutInstructor(String instructorId) async {
    daysWithoutInstructor.value = [];
    CollectionReference eventDaysRef =
        db.collection('Events/' + eventName + '/days');
    QuerySnapshot eventDaysQuery = await eventDaysRef.get();
    eventDaysQuery.docs.forEach((day) {
      var dayData = day.data() as Map<String, dynamic>;
      List instructorList = dayData['instructors'];
      if (!instructorList.contains(instructorId))
        daysWithoutInstructor.add(day.id);
    });
    update();
  }

  submitExchangeRequest(Request request) async {
    var requestObject = {
      'instructor_id': request.armyId,
      'full_name': request.fullName,
      'give_day': request.giveDay,
      'take_day': request.takeDays,
      'type': request.type,
      'request_init': DateTime.now()
    };
    var selectedDay = request.giveDay;
    String dateKey =
        "${selectedDay.day.toString().padLeft(2, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.year.toString()}";
    CollectionReference requestsDaysRef =
        db.collection('Events/$eventName/days/$dateKey/requests');
    QuerySnapshot requestsDaySnap = await requestsDaysRef.get();
    if (requestsDaySnap.size <= 0) {
      db
          .collection('Events/$eventName/days/$dateKey/requests')
          .doc()
          .set(requestObject);
    } else {
      await requestsDaysRef.add(requestObject);
    }
    CollectionReference requestsRef = db.collection('requests');
    await requestsRef.add(requestObject);
    print('submitted');
  }

  approveRequest(String instructorId, Request request, String? takeDay) async {
    // var requestObject = {
    //   'instructor_id': request.armyId,
    //   'full_name': request.fullName,
    //   'give_day': request.giveDay,
    //   'take_day': takeDay,
    //   'type': request.type,
    //   'request_init': request.requestInit
    // };
    if (instructorId == '') return;

    /// first give day to instructor
    var giveDay = request.giveDay;
    String giveDateKey =
        "${giveDay.day.toString().padLeft(2, '0')}-${giveDay.month.toString().padLeft(2, '0')}-${giveDay.year.toString()}";
    DocumentReference giveDaysRef =
        db.doc('Events/$eventName/days/$giveDateKey');
    await giveDaysRef.update({
      'instructors': FieldValue.arrayUnion([instructorId])
    });

    /// now take off day from request instructor
    await giveDaysRef.update({
      'instructors': FieldValue.arrayRemove([request.armyId])
    });
    if (request.type == 'החלפה' && takeDay != null) {
      /// now give takeDay to request Instructor
      String takeDateKey = takeDay;
      DocumentReference takeDaysRef =
          db.doc('Events/$eventName/days/$takeDateKey');
      await takeDaysRef.update({
        'instructors': FieldValue.arrayUnion([request.armyId])
      });

      /// now remove new approved InstructorID from takeDay
      await takeDaysRef.update({
        'instructors': FieldValue.arrayRemove([instructorId])
      });
    }

    ///delete request
    DocumentReference dayRequestsRef = db
        .collection('Events/$eventName/days/$giveDateKey/requests')
        .doc(request.requestId);
    await dayRequestsRef.delete();

    /// update request_approvals
    CollectionReference RequestApprovalsRef =
        db.collection('request_approvals');
    await RequestApprovalsRef.add({
      'approval_timestamp': DateTime.now(),
      'approved_by': instructorId,
      'approved_request': request.toJson(),
      'take_day': takeDay,
      'system_status': 'init'
    });
    print('request approval executed');
  }

  removeRequest(String approvalId, Request request) async {
    /// check valid removal Id
    if ((request.armyId == approvalId) ||
        (listOfAdminIds.contains(approvalId))) {
      // Id ok
      /// remove request
      var giveDay = request.giveDay;
      String giveDateKey =
          "${giveDay.day.toString().padLeft(2, '0')}-${giveDay.month.toString().padLeft(2, '0')}-${giveDay.year.toString()}";
      DocumentReference dayRequestsRef = db
          .collection('Events/$eventName/days/$giveDateKey/requests')
          .doc(request.requestId);
      await dayRequestsRef.delete();
      return true;

      ///
    } else {
      return false;
    }
  }

  addInstructorToDay(String instructorId, String selectedDay) async {
    if (instructorId == '') return;
    DocumentReference giveDaysRef =
        db.doc('Events/$eventName/days/$selectedDay');
    await giveDaysRef.update({
      'instructors': FieldValue.arrayUnion([instructorId])
    });
    print('Instructor added to day');
  }

  addInstructorToSystem(id, Map<String, dynamic> data) async {
    CollectionReference eventInstructorsRef =
        db.collection('Events/$eventName/instructors');
    await eventInstructorsRef.doc(id).set(data);
    CollectionReference instructorsRef =
    db.collection('Instructors');
    await instructorsRef.doc(id).set(data);
  }

//   bool isValidId(String id) {
//
//   }
}

class ExchangeHome extends StatelessWidget {
  final controller = Get.put(ExchangeController());
  final CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    await controller.loadSelectedDayRequests(selectedDay);
  }

  Future<void> removeRequestApprovalDialog(
      BuildContext context, Request request) async {
    return showDialog(
        context: context,
        builder: (context) {
          return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('אישור הסרת בקשה'),
                content: Container(
                  height: 150,
                  child: Column(
                    children: [
                      const Text('יש להזין ת.ז. של בעל הבקשה או פיקוד בכיר'),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (value) {},
                          controller: removalIdController,
                          decoration: const InputDecoration(hintText: "ת.ז."),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    child: Text('ביטול'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    child: const Text('אישור'),
                    onPressed: () async {
                      /// todo
                      if (await controller.removeRequest(
                          removalIdController.text, request)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('הבקשה הוסרה')),
                        );
                        controller.loadAllRequests();
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                            'ת.ז. לא מורשה!!!',
                            style: TextStyle(color: Colors.red),
                          )),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ));
        }
        );
  }
  List<Request> _getRequestsForDay(DateTime selectedDay) {
    return controller.selectedDayRequests;
  }
  //final _dialogFormKey = GlobalKey<FormState>();
  final instructorIdController = TextEditingController();
  final removalIdController = TextEditingController();
  String typeDropdownValue = listType.first;
  late String takeDateDropdownValue;

  @override
  Widget build(BuildContext context) {
    final ExchangeController controller = Get.put(ExchangeController());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => {Navigator.pop(context)},
          icon: Icon(Icons.arrow_back),
        ),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('החלפות ומסירות'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SwapRequestWizard(),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            const Center(
              child: SizedBox(
                child: Text('רשימת בקשות לפי  יום  מסומן'),
              ),
            ),
            Obx(() => SizedBox(
                  child: TableCalendar(
                    locale: 'he_HE',
                    headerStyle: const HeaderStyle(
                        titleCentered: true, formatButtonVisible: false),
                    weekendDays: const [DateTime.friday, DateTime.saturday],
                    firstDay: controller.startDate.value,
                    lastDay: controller.endDate.value,
                    focusedDay: controller._focusedDay.value,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) =>
                        isSameDay(controller._selectedDay, day),
                    calendarStyle: const CalendarStyle(
                      defaultTextStyle: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold),
                      weekendTextStyle: TextStyle(color: Colors.red),
                      isTodayHighlighted: false,
                      outsideDaysVisible: true,
                      markersMaxCount: 0,
                    ),
                    eventLoader: _getRequestsForDay,
                    onDaySelected: _onDaySelected,
                  ),
                )),
            Expanded(
              child: Obx(() => ListView.builder(
                  itemCount: controller.selectedDayRequests.length,
                  itemBuilder: (context, index) {
                    final request = controller.selectedDayRequests[index];
                    //var takeDate = request.takeDays ?? DateTime(1971);
                    //String takeDateStr =
                    //    "${takeDate.day.toString().padLeft(2, '0')}-${takeDate.month.toString().padLeft(2, '0')}-${takeDate.year.toString()}";
                    return Card(
                        child: ExpansionTile(
                      expandedAlignment: Alignment.topRight,
                      title: Text(
                          '${request.fullName} רוצה ${request.type == 'החלפה' ? 'החלפה ' : 'מסירה '} '),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 80, bottom: 10, top: 5),
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  return removeRequestApprovalDialog(
                                      context, request);
                                },
                                style: ButtonStyle(),
                                child: Text('הסר'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          content: Container(
                                            height: 450,
                                            child: SwapApproveWizard(
                                                request: request),

                                            /// to do change to dropdown of date and add take date
                                          ),
                                        );
                                      });
                                },
                                style: ButtonStyle(),
                                child: Text('החלף'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ));
                  })),
            ),
            const Divider(
              height: 20,
              thickness: 3,
              indent: 20,
              endIndent: 20,
              color: Colors.blue,
            ),
            const Center(
              child: SizedBox(
                child: Text('רשימת בקשות כללית'),
              ),
            ),
            Obx(
              () => !controller.requestsLoading.value
                  ? controller.allRequests.isNotEmpty
                      ? Expanded(
                          child: ListView.builder(
                              itemCount: controller.allRequests.length,
                              itemBuilder: (context, index) {
                                final request = controller.allRequests[index];
                                var giveDate = request.giveDay;
                                // String takeDateStr =
                                //   "${takeDate.day.toString().padLeft(2, '0')}-${takeDate.month.toString().padLeft(2, '0')}-${takeDate.year.toString()}";
                                String giveDateStr =
                                    "${giveDate.day.toString().padLeft(2, '0')}-${giveDate.month.toString().padLeft(2, '0')}-${giveDate.year.toString()}";
                                return ExchangeCard(
                                  request: request,
                                  giveDay: giveDateStr,
                                );
                              }),
                        )
                      : const SizedBox.shrink()
                  : const Padding(
                      padding: EdgeInsets.all(100.0),
                      child: Column(
                        children: [
                          LinearProgressIndicator(),
                          Text('טוען את כל הבקשות')
                        ],
                      ),
                    ),
            ),
            //Obx(() => controller.requestsLoading.value?const LinearProgressIndicator():const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

/// Add Request
List<String> listType = <String>['החלפה', 'מסירה'];

class SwapRequestWizard extends StatefulWidget {
  const SwapRequestWizard({super.key});

  @override
  State<SwapRequestWizard> createState() => _SwapRequestWizardState();
}

class _SwapRequestWizardState extends State<SwapRequestWizard> {
  int _index = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final instructorIdController = TextEditingController();
  String typeDropdownValue = listType.first;
  List<DateTime> selectedDaysToTake = [];
  String giveDateDropdownValue = 'לא נטען';
  String takeDateDropdownValue = 'לא נטען';
  final controller = Get.put(ExchangeController());
  static const String _title = 'מסך החלפות ומסירות';
  final _globalKey = GlobalKey<ScaffoldMessengerState>();

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
                child: Form(
                  key: _formKey,
                  child: ListView(children: [
                    Stepper(
                      currentStep: _index,
                      onStepCancel: () {
                        if (_index > 0) {
                          setState(() {
                            _index -= 1;
                          });
                        }
                      },
                      onStepContinue: () async {
                        if (_index == 0) {
                          /// first step
                          /// check ID and load days if ID ok
                          if (_formKey.currentState!.validate()) {
                            await controller.loadDaysForInstructor(
                                instructorIdController.text);
                            if (controller.daysForInstructor.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('לא נמצאו ימים!!!')),
                              );
                            } else {
                              await controller.loadDaysWithoutInstructor(
                                  instructorIdController.text);
                              setState(() {
                                giveDateDropdownValue =
                                    controller.daysForInstructor[0];
                                takeDateDropdownValue =
                                    controller.daysWithoutInstructor[0];
                                _index++;
                              });
                            }
                          }
                        } else if (_index == 1) {
                          setState(() => _index++);
                        } else if (_index == 2) {
                          if (typeDropdownValue == 'החלפה') {
                            setState(() => _index++);
                          } else {
                            setState(() => _index = _index + 2);
                          }
                        } else if (_index == 3) {
                          setState(() {
                            _index++;
                          });
                        }
                      },
                      onStepTapped: (int index) {
                        if (controller.daysForInstructor.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('לא נמצאו ימים לספר אישי זה')),
                          );
                        } else if (typeDropdownValue != 'החלפה' && index == 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('סוג הבקשה הוגדר כמסירה לא החלפה')),
                          );
                          _index = index + 1;
                        } else {
                          setState(() {
                            _index = index;
                          });
                        }
                      },
                      steps: <Step>[
                        Step(
                            title: const Text('הזדהות'),
                            subtitle: const Text('נא הזן ת.ז. של מגיש הבקשה'),
                            content: Container(
                              width: 150,
                              alignment: Alignment.centerRight,
                              child: TextFormField(
                                controller: instructorIdController,
                                // The validator receives the text that the user has entered.
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    'לא הוזן כלום!';
                                  }
                                  return null;
                                },
                              ),
                            )),
                        Step(
                            title: Text('סוג  הבקשה'),
                            content: Container(
                              alignment: Alignment.centerRight,
                              child: DropdownButton(
                                onChanged: (String? value) {
                                  setState(() {
                                    typeDropdownValue = value!;
                                  });
                                },
                                value: typeDropdownValue,
                                items: listType.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            )),
                        Step(
                            title: const Text('בחירת  היום להחלפה או מסירה'),
                            content: Obx(() => Container(
                                  alignment: Alignment.centerRight,
                                  child: DropdownButton(
                                    onChanged: (String? value) {
                                      setState(() {
                                        giveDateDropdownValue = value!;
                                      });
                                    },
                                    value: giveDateDropdownValue,
                                    items: controller.daysForInstructor
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ))),
                        Step(
                            title: const Text(
                                'בחירת  היום המבוקש רלוונטי רק להחלפה'),
                            content: Obx(() => MultiSelectDialogField(
                                  confirmText: Text('אישור'),
                                  cancelText: Text('בטל'),
                                  buttonText: Text('בחירת ימים'),
                                  searchHint: 'בחירת ימים',
                                  items: controller.daysWithoutInstructor
                                      .map((e) => MultiSelectItem(e, e))
                                      .toList(),
                                  onConfirm: (val) {
                                    selectedDaysToTake = [];
                                    for (var element in val) {
                                      selectedDaysToTake.add(DateTime.parse(
                                          toValidDateKey(element.toString())));
                                    }
                                  },
                                ))),
                        Step(
                            title: const Text('שליחת הבקשה'),
                            content: Container(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (typeDropdownValue == 'החלפה' && selectedDaysToTake.isEmpty ) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('בקשת החלפה מחיייבת הזנת ימים לקחת!' , style: TextStyle(fontSize: 20, color: Colors.red)),
                                      ));
                                    Navigator.pop(context);
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('הבקשה נשלחת למערכת')),
                                  );
                                  giveDateDropdownValue =
                                      giveDateDropdownValue == ''
                                          ? controller.daysForInstructor[0]
                                          : giveDateDropdownValue;
                                  takeDateDropdownValue =
                                      takeDateDropdownValue == ''
                                          ? controller.daysWithoutInstructor[0]
                                          : takeDateDropdownValue;
                                  var giveSplitResult =
                                      giveDateDropdownValue.split('-');
                                  var giveDateForParse =
                                      '${giveSplitResult[2]}-${giveSplitResult[1]}-${giveSplitResult[0]}';
                                  controller.eventInstructors
                                      .forEach((element) async {
                                    if (element.armyId ==
                                        instructorIdController.text) {
                                      await controller
                                          .submitExchangeRequest(Request(
                                        instructorIdController.text,
                                        '${element.firstName} ${element.lastName}',
                                        DateTime.now(),
                                        typeDropdownValue,
                                        DateTime.parse(giveDateForParse),
                                        selectedDaysToTake,
                                        null,
                                      ));
                                    }
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('הבקשה התקבלה')),
                                  );
                                  Navigator.pop(context);
                                  controller.loadAllRequests();
                                },
                                child: Text('אשר ושלח את הבקשה'),
                              ),
                            )),
                      ],
                      controlsBuilder:
                          (BuildContext context, ControlsDetails dtl) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20, right: 100),
                          child: Row(
                              children: _index != 4
                                  ? [
                                      SizedBox(width: 30),
                                      ElevatedButton(
                                        onPressed: dtl.onStepContinue,
                                        child: const Text('הבא'),
                                      )
                                    ]
                                  : [Text('')]),
                        );
                      },
                    ),
                  ]),
                ),
              ))),
    );
  }
}

/// Swap - Approve
class SwapApproveWizard extends StatefulWidget {
  final Request request;
  const SwapApproveWizard({super.key, required this.request});

  @override
  State<SwapApproveWizard> createState() => _SwapApproveWizardState();
}

class _SwapApproveWizardState extends State<SwapApproveWizard> {
  static const String _title = 'מסך אישור';
  int _index = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final instructorIdController = TextEditingController();
  String typeDropdownValue = listType.first;
  late String takedaysDropdownValue;
  List<String> takeDays = [];
  List<String> commonTakeDays = [];
  bool loading = true;
  final controller = Get.put(ExchangeController());
  bool isIdValid = false;

  @override
  void initState() {
    if (widget.request.type == 'החלפה') {
      DateTime firstTakeDay = widget.request.takeDays![0];
      takedaysDropdownValue =
          "${firstTakeDay.day.toString().padLeft(2, '0')}-${firstTakeDay.month.toString().padLeft(2, '0')}-${firstTakeDay.year.toString()}";
    } else {
      takedaysDropdownValue = '--';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
              leading: IconButton(
                onPressed: () => {Navigator.pop(context)},
                icon: const Icon(Icons.arrow_back),
              ),
              title: const Text(_title)),
          body: Center(
            child: Form(
              key: _formKey,
              child: ListView(children: [
                Stepper(
                  currentStep: _index,
                  onStepCancel: () {
                    if (_index > 0) {
                      setState(() {
                        _index -= 1;
                      });
                    }
                  },
                  onStepContinue: () async {
                    if (_index == 0) {
                      if (_formKey.currentState!.validate()) {
                        if (instructorIdController.text == '' || (controller.eventInstructors.indexWhere((element) => element.armyId == instructorIdController.text)==-1)) {
                          setState(() {
                            isIdValid = false;
                            instructorIdController.text == '';
                            _index=0;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('מספר אישי לא תקין')),
                          );
                          return;
                        }
                        isIdValid = true;
                        await controller.loadDaysWithoutInstructor(
                            instructorIdController.text);
                        var giveDayDate = widget.request.giveDay;
                        String giveDateKey =
                            "${giveDayDate.day.toString().padLeft(2, '0')}-${giveDayDate.month.toString().padLeft(2, '0')}-${giveDayDate.year.toString()}";
                        var giveDaySwapIsValid = controller
                            .daysWithoutInstructor
                            .contains(giveDateKey);
                        if (giveDaySwapIsValid) {
                          if (widget.request.type == 'החלפה') {
                            await controller.loadDaysForInstructor(
                                instructorIdController.text);
                            for (var takeDayDate in widget.request.takeDays!) {
                              takeDays.add(
                                  "${takeDayDate.day.toString().padLeft(2, '0')}-${takeDayDate.month.toString().padLeft(2, '0')}-${takeDayDate.year.toString()}");
                            }
                            commonTakeDays = takeDays
                                .where((element) => controller.daysForInstructor
                                    .contains(element))
                                .toList();
                            var takeDaySwapIsValid = commonTakeDays.isNotEmpty;
                            if (takeDaySwapIsValid) {
                              /// all valid so move on
                              setState(() {
                                loading = false;
                                takedaysDropdownValue = commonTakeDays[0];
                                _index++;
                              });
                            } else {
                              /// not valid take day
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'תקלה - אין אפשרות לתת את היום המבוקש')),
                              );
                              Navigator.pop(context);
                            }
                          } else {
                            /// not a swap so no need to check takeDay go on
                            setState(() => _index = _index + 2);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'תקלה - אין אפשרות לקחת את היום המבוקש')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    }
                    else if (_index == 1) {
                      setState(() => _index++);
                      //Navigator.pop(context);
                    }
                  },
                  onStepTapped: (int index) {
                    if (index==0) {
                      setState(() {
                        isIdValid = false;
                        instructorIdController.text='';
                      });
                    }
                    if ((index == 2 || index==1) && !isIdValid)  {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('לא הוזנה ת.ז. או לא נמצאו ימים לספר אישי זה')),
                      );
                      setState(() {
                        _index = 0;
                      });
                    }
                     else if (widget.request.type == 'החלפה' && index == 2) {
                      setState(() {
                        _index = index;
                      });
                    } else {
                      setState(() {
                        _index = index;
                      });
                    }
                  },
                  steps: <Step>[
                    Step(
                        title: const Text('הזדהות'),
                        subtitle: const Text('נא הזן ת.ז.'),
                        content: Container(
                          width: 150,
                          alignment: Alignment.topRight,
                          child: TextFormField(
                            controller: instructorIdController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                'לא הוזן כלום!';
                              }
                              return null;
                            },
                          ),
                        )),
                    Step(
                        title: const Text('בחירת יום להחלפה'),
                        content: Container(
                          alignment: Alignment.centerRight,
                          child: Column(
                            children: [
                                widget.request.type == 'החלפה'
                                    ? DropdownButton(
                                onChanged: (String? value) {
                                  setState(() {
                                    takedaysDropdownValue = value!;
                                  });
                                },
                                value: takedaysDropdownValue,
                                items: commonTakeDays
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              )
                                    : Text('לא רלוונטי זו בקשת מסירה!'),
                            ],
                          ),
                        )),
                    Step(
                        title: const Text('אישור הבקשה'),
                        content: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'אישור ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                widget.request.type == 'החלפה'
                                    ? Text('החלפה של ',
                                        style: TextStyle(fontSize: 14))
                                    : Text('מסירה מ ',
                                        style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            Row(
                              children: [
                                Text(widget.request.fullName,
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            Row(
                              children: [
                                Text('עם ', style: TextStyle(fontSize: 14)),
                                Text(instructorIdController.text,
                                    style: TextStyle(fontSize: 14))
                              ],
                            ),
                            Row(
                              children: [
                                widget.request.type == 'החלפה'
                                    ? Text('החלפה של ',
                                        style: TextStyle(fontSize: 14))
                                    : Text('מסירה של ',
                                        style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            Row(
                              children: [
                                Text(toDateKey(widget.request.giveDay),
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            Row(
                              children: [
                                widget.request.type == 'החלפה'
                                    ? Text(' ב ' + takedaysDropdownValue,
                                        style: TextStyle(fontSize: 14))
                                    : Text('', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (instructorIdController.text == '') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('הזדהות לא חוקית')),
                                  );
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('הבקשה נשלחת למערכת')),
                                );
                                await controller.approveRequest(
                                    instructorIdController.text,
                                    widget.request,
                                    takedaysDropdownValue);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('הבקשה התקבלה')),
                                );
                                controller.loadAllRequests();
                                controller.loadSelectedDayRequests(
                                    controller._focusedDay.value);
                                setState(() => _index++);
                              },
                              child: const Text('אשר ושלח את הבקשה'),
                            ),
                          ],
                        )),
                    Step(
                        title: const Text('סיום'),
                        content: Container(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            child: const Text('סגור'),
                          ),
                        )),
                  ],
                  controlsBuilder: (BuildContext context, ControlsDetails dtl) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10, right: 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _index == 0
                              ? [
                                  ElevatedButton(
                                    onPressed: dtl.onStepContinue,
                                    child: const Text('הבא'),
                                  )
                                ]
                              : [Text('')]),
                    );
                  },
                ),
              ]),
            ),
          ),
        ));
  }
}

/// exchange request card -0
class ExchangeCard extends StatefulWidget {
  final Request request;
  final String giveDay;

  const ExchangeCard({super.key, required this.request, required this.giveDay});

  @override
  State<ExchangeCard> createState() => _ExchangeCardState();
}

class _ExchangeCardState extends State<ExchangeCard> {
  late String takeDayDropdownValue;
  final controller = Get.put(ExchangeController());
  final removalIdController = TextEditingController();
  List<DateTime> takeDays = [];
  Future<void> removeRequestApprovalDialog(
      BuildContext context, Request request) async {
    return showDialog(
        context: context,
        builder: (context) {
          return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('אישור הסרת בקשה'),
                content: Container(
                  height: 150,
                  child: Column(
                    children: [
                      const Text('יש להזין ת.ז. של בעל הבקשה או פיקוד בכיר'),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (value) {},
                          controller: removalIdController,
                          decoration: const InputDecoration(hintText: "ת.ז."),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    child: Text('ביטול'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    child: const Text('אישור'),
                    onPressed: () async {
                      /// todo
                      if (await controller.removeRequest(
                          removalIdController.text, request)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('הבקשה הוסרה')),
                        );
                        controller.loadAllRequests();
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                            'ת.ז. לא מורשה!!!',
                            style: TextStyle(color: Colors.red),
                          )),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ));
        });
  }

  TextSpan takeDaysToTextSpan(List<DateTime> takeDays) {
    // Convert each DateTime to a string using your formatting
    final List<String> dateStrings = takeDays.map(toDateKey).toList();

    // Helper to create a bold TextSpan
    TextSpan boldSpan(String text) {
      return TextSpan(
        text: text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    // If no dates, return a simple TextSpan
    if (dateStrings.isEmpty) {
      return const TextSpan(text: "לא מולאו תאריכים");
    }

    // If exactly one date, just show it in bold
    if (dateStrings.length == 1) {
      return boldSpan(dateStrings.first);
    }
    final List<TextSpan> children = [];

    // Add the first n-1 dates with commas
    for (int i = 0; i < dateStrings.length - 1; i++) {
      children.add(boldSpan(dateStrings[i]));
      if (i < dateStrings.length - 2) {
        children.add(const TextSpan(text: ', ')); // normal text
      }
    }
    // Add " and " in normal style
    children.add(const TextSpan(text: ' או '));

    // Add the last date in bold
    children.add(boldSpan(dateStrings.last));

    return TextSpan(children: children);
  }

  @override
  void initState() {
    //DateTime today = DateTime.now();
    //DateTime today = DateTime.parse('2023-01-01'); /// for debug todo del this and uncomment line above
    /*
    widget.request.takeDays?.forEach((takeDay) {
      if(takeDay.compareTo(today) > 0){
        takeDays.add(takeDay);
      }
    });
     */
    //var millis = widget.request.takeDays![0].millisecondsSinceEpoch;
    //takeDayDropdownValue = millis.toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Request request = widget.request;
    String giveDateStr = widget.giveDay;
    return Card(
        child: ExpansionTile(
      initiallyExpanded: false,
      expandedAlignment: Alignment.topRight,
      title: Text(
          '${request.fullName}  רוצה ${request.type == 'החלפה' ? ' החלפה של ' : 'מסירה של '} $giveDateStr'),
      children: [
        Column(
          children: [
            request.type == 'החלפה'
                ? const Text('מעוניין להחליף עם ')
                : const SizedBox.shrink(),
            request.takeDays != null && request.type == 'החלפה'
                ? RichText(text: takeDaysToTextSpan(request.takeDays!))
                : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: SwapApproveWizard(
                                request: request,
                              ),
                            );
                          });
                    },
                    style: ButtonStyle(),
                    child: Text('החלף'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      return removeRequestApprovalDialog(context, request);
                    },
                    style: ButtonStyle(),
                    child: const Text('הסר בקשה'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ));
  }
}
