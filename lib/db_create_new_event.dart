import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:shifts/utils.dart';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final adminIds = controller
      .admins; // <String>['028619237']; // For debug: Hard-coded admin IDs

  // 2) start and end dates
  //final dateFormat = DateFormat('d-MM-yyyy');
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
    final weekdayName =
        DateFormat('EEEE').format(dt); // e.g. Monday, Tuesday, ...
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
// 🔧 Step 1: Convert to Map<String, Map<String, dynamic>>
  final batch = firestore.batch();
  final instructorsRef =
      firestore.collection('Events').doc(eventName).collection('instructors');

  for (final Instructor instructor in eventInstructors) {
    final docRef = instructorsRef.doc(instructor.armyId); // armyId as doc ID
    batch.set(docRef, instructor.toMap()); // 🔥 convert object to map
  }

  await batch.commit(); // ⚡️ send all at once
  print('done');
}

///
///
Future<void> dbUpdateEvent(Map<String, dynamic> eventMetaData, List<Instructor> selectedInstructors) async {

  Future<void> syncEventDays({
    required DocumentReference eventDocRef,
    required List<DateTime> newEventDays,
   }) async
  {
    final controller = Get.put(Controller());
    final firestore = FirebaseFirestore.instance;
    final daysCollection = eventDocRef.collection('days');
    final dateFormatter = DateFormat('dd-MM-yyyy');

    // 🧹 Step 1: Filter newEventDays to only valid weekdays (Mon–Thu, Sun)
    final filteredNewDays = newEventDays.where((dt) {
      final weekday = dt.weekday; // 1 = Mon, ..., 7 = Sun
      return weekday != DateTime.friday && weekday != DateTime.saturday;
    }).toList();

    final newDayMap = {
      for (final dt in filteredNewDays) dateFormatter.format(dt): dt
    };
    final newDayKeys = newDayMap.keys.toSet();

    // 📥 Step 2: Get existing days from Firestore
    final existingDaysSnapshot = await daysCollection.get();
    final existingDayKeys =
        existingDaysSnapshot.docs.map((doc) => doc.id).toSet();
    // ➕➖ Step 3: Compute diffs
    final daysToAdd = newDayKeys.difference(existingDayKeys);
    final daysToDelete = existingDayKeys.difference(newDayKeys);
    // 🧾 Step 4: Apply changes in a batch
    final batch = firestore.batch();
    for (final dayKey in daysToAdd) {
      final dt = newDayMap[dayKey]!;
      final docRef = daysCollection.doc(dayKey);
      batch.set(docRef, {
        'date': dt,
        'instructors': [],
      });
    }
    for (final dayKey in daysToDelete) {
      final docRef = daysCollection.doc(dayKey);
      batch.delete(docRef);
    }

    await batch.commit();
    controller.statusMsg.value =
        'עדכון ימי הארוע הסתיים (${daysToAdd.length} נוספו, ${daysToDelete.length} הוסרו)';
  }
  print('update db, this may take a while.....');
  final controller = Get.put(Controller());
  controller.statusMsg.value = 'update event, this may take a while.....';
  final firestore = FirebaseFirestore.instance;
  final eventDocRef = firestore.collection('Events').doc(eventMetaData['event_name']);

  // instructors


  final batch = firestore.batch();
  final instructorsRef = firestore
      .collection('Events')
      .doc(eventMetaData['event_name'])
      .collection('instructors');

  for (final Instructor instructor in eventMetaData['event_instructors']) {
    final docRef = instructorsRef.doc(instructor.armyId); // armyId as doc ID
    batch.update(docRef, instructor.toMap()); // 🔥 convert object to map
  }
  await batch.commit(); // ⚡️ send all at once
  print('updated instructors.....');

  /// Days
  await syncEventDays(
    eventDocRef: eventDocRef,
    newEventDays: eventMetaData['event_days']
  );
  // 3. Build the payload for Firestore
  final updateMetadata = {
    'event_name': eventMetaData['event_name'],
    'start_date': Timestamp.fromDate(eventMetaData['start_date']),
    'end_date': Timestamp.fromDate(eventMetaData['end_date']),
    'days_off_and_date': Timestamp.fromDate(eventMetaData['days_off_and_date']),
    'instructors_per_day': eventMetaData['instructors_per_day'],
  };
  await firestore
      .collection('Events')
      .doc(eventMetaData['event_name'])
      .update(updateMetadata);
  print('done');
}
