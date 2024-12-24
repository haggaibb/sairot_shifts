import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'main.dart';

/// Example of a Dart/Flutter function that replicates your Node.js logic
/// using the `cloud_firestore` package.
Future<void> dbCreateNewEvent(Map<String, dynamic> eventMetaData) async {
  // 1) Extract fields from eventMetaData
  final controller = Get.put(Controller());
  final eventName = eventMetaData['event_name'] as String;
  final startDate = eventMetaData['start_date'] as DateTime;
  final endDate = eventMetaData['end_date'] as DateTime;
  final instructorsPerDay = eventMetaData['instructors_per_day'] as int;
  // debug fields
  final editDaysOffEndDate = DateTime.now(); // or from eventMetaData if needed
  final adminIds = <String>['028619237']; // For debug: Hard-coded admin IDs

  // 2) start and end dates
  final dateFormat = DateFormat('d-MM-yyyy');
  final eventInstructors = eventMetaData['event_instructors'];
  print('add to db, this may take a while.....');
  controller.statusMsg.value = 'creating new event, this may take a while.....';
  // 3) Create or update the "Events/$eventName" doc in Firestore
  final firestore = FirebaseFirestore.instance;
  await firestore.collection('Events').doc(eventName).set({
    'start_date': startDate,
    'end_date': endDate,
    'instructors_per_day': instructorsPerDay,
    'days_off_end_date': editDaysOffEndDate,
    'admin_ids': adminIds,
  });
  print('metadata created.....');
  for (final dt in eventMetaData['event_days']) {
    // Use DateFormat to get "DD-MM-YYYY"
    final dayKey = DateFormat('dd-MM-yyyy').format(dt);
    controller.statusMsg.value = 'adding $dayKey';
    // Check if day is Friday or Saturday
    final weekdayName = DateFormat('EEEE').format(dt); // e.g. Monday, Tuesday, ...
    if (weekdayName != 'Friday' && weekdayName != 'Saturday') {
      // 1) Create (or overwrite) the doc in "days"
      await firestore
          .collection('Events')
          .doc(eventName)
          .collection('days')
          .doc(dayKey)
          .set({
        'date': dt,
        'instructors': [],
      });
    }
  }
  for (final instructor in eventInstructors) {
    controller.statusMsg.value = 'add ${instructor['armyId']} to assigned instructors';
    await firestore
        .collection('Events')
        .doc(eventName)
        .collection('instructors')
        .doc(instructor['armyId'])
        .set(instructor);
  }
  print('done');
}

