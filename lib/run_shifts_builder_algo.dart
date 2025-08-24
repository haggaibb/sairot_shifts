import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // for random
import 'package:get/get.dart';
import 'main.dart';
import 'package:intl/intl.dart';


// A rough conversion of your Node.js runShiftsBuilder(targetEvent) function
Future<bool> runShiftsBuilderAlgo(String targetEvent) async {
  final firestore = FirebaseFirestore.instance;
  final controller = Get.put(Controller());

  final eventName = targetEvent;
  //final eventName = 'test';



  final eventDocRef = firestore.collection('Events').doc(eventName);
  final daysCollectionRef = eventDocRef.collection('days');
  final eventInstructorsDocRef = eventDocRef.collection('instructors');
  controller.statusMsg.value = 'Fetching data for event => $eventName';
  print('Fetching data for event => $eventName');

  // 2) Get event doc
  final eventDoc = await eventDocRef.get();
  if (!eventDoc.exists) {
    print('No Event document!');
    return false;
  }
  final eventMetadata = eventDoc.data() ?? {};
  final instructorsPerDay = eventMetadata['instructors_per_day'] as int? ?? 0;
  print('Got event metadata for event => $eventName');
  controller.statusMsg.value = 'Got event metadata for event $eventName';


  // 3) Get event Days
  final eventDaysSnap = await daysCollectionRef.get();
  final eventDaysList = eventDaysSnap.docs;
  /// clean days from old data
  for (final dayDoc in  eventDaysList) {
    await dayDoc.reference.update({'instructors': []});
    print('✅ Cleared instructors for day doc: ${dayDoc.id}');
  }
  print('Got the list of Days in the event $eventName');
  controller.statusMsg.value = 'Got the list of Days in the event $eventName';
  // 4) Get event instructors
  final eventInstructorsSnap = await eventInstructorsDocRef.where('maxDays', isGreaterThan: 0).get();
  final eventInstructorsList = eventInstructorsSnap.docs;
  print('Got the list(${eventInstructorsSnap.docs.length}) of instructors for the event $eventName');
  controller.statusMsg.value = 'Got the list(${eventInstructorsSnap.docs}) of instructors for the event $eventName';

  // array struct to manage the random shift pick
  // In Node code:  "var listOfDaysWithAssignedInsturctors = new Array(eventDaysList.length);"
  // In Dart:
  final List<List<String>> listOfDaysWithAssignedInstructors =
  List.generate(eventDaysList.length, (_) => <String>[]);
  // 6) The random shift assignment loops
  // We do 10 runs, as in your Node code: "for (var i=0; i<10;i++) {...}"
  for (var i = 0; i < 10; i++) {
    controller.statusMsg.value = 'Algo run number $i';
    print('Algo run number $i');
    // eventInstructorsList.forEach( async (instructorDoc)=>{ ... })
    // In Dart, we can't do an async forEach callback. We'll do a for loop:
    for (final instructorDoc in eventInstructorsList) {
      controller.statusMsg.value = 'assign random shift for ID ${instructorDoc.id}';
      //print('assign random shift for ID ${instructorDoc.id}');
      print('eventDaysList = ${eventDaysList.length}');
      print(eventDaysList.first.id);
      print(eventDaysList.first.data());

      await _assignRandomShift(
        firestore: firestore,
        eventName: eventName,
        instructorDoc: instructorDoc,
        eventDaysList: eventDaysList,
        listOfDaysWithAssignedInstructors: listOfDaysWithAssignedInstructors,
        instructorsPerDay: instructorsPerDay,
      );
    }
  }

  print('Done!!!');
  return true;
}

// The Node.js code had a function getRandomShift(instructor){...} that we replicate
Future<void> _assignRandomShift({
  required FirebaseFirestore firestore,
  required String eventName,
  required QueryDocumentSnapshot instructorDoc,
  required List<QueryDocumentSnapshot> eventDaysList,
  required List<List<String>> listOfDaysWithAssignedInstructors,
  required int instructorsPerDay,
}) async {
  final instructorData = instructorDoc.data() as Map<String, dynamic>;
  final instructorId = instructorDoc.id;
  final maxDays = instructorData['max_days'] as int? ?? 5; // arbitrary fallback
  final daysOff = (instructorData['days_off'] as List<dynamic>?) ?? [];
  bool notDone = true;
  int foundShift = -1;
  int tries = 0;
  final controller = Get.put(Controller());
  // Provide a function to get a random day index
  int getRandomShiftSlot() {
    final min = 0;
    final max = eventDaysList.length - 1;
    return Random().nextInt(max - min + 1) + min;
  }
  // check if instructor reached max day limit
  bool checkMaxDaysLimitReached() {
    // count how many days instructor already assigned
    var daysCounter = 0;
    for (final dayList in listOfDaysWithAssignedInstructors) {
      if (dayList.contains(instructorId)) {
        daysCounter++;
      }
    }
    // We also see logic about realMaxLimit in Node code (daysCounter/(listOfDaysWithAssignedInstructors.length - days_off.length) >1).
    final totalDays = listOfDaysWithAssignedInstructors.length;
    final offCount = daysOff.length;
    final realMaxLimit = offCount >= totalDays
        ? 0.0
        : daysCounter / (totalDays - offCount);
    // if daysCounter >= maxDays or realMaxLimit>1 => done
    if (daysCounter >= maxDays || realMaxLimit > 1.0) {
      return true;
    }
    return false;
  }

  // check if day is a day off
  bool isDayOff(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= eventDaysList.length) {
      print('invalid day');
      return true; // invalid day => treat as day off
    }
    final daySnap = eventDaysList[dayIndex];
    final dayData = daySnap.id;
    // 1. Convert String to DateTime
    DateFormat format = DateFormat("dd-MM-yyyy");
    DateTime dateTime = format.parse(dayData);
    Timestamp timestamp = Timestamp.fromDate(dateTime);
    // 2. Convert DateTime to Timestamp
    print(dateTime);
    final dayTimestamp = Timestamp.fromDate(dateTime);
    //final dayData = daySnap.data() as Map<String, dynamic>;
    final dateToCheck = dayTimestamp.toDate();
    print('compare dayToCheck with each item in daysOff...');
    // compare dayToCheck with each item in daysOff
    for (final dOff in daysOff) {
      if (dOff is Timestamp) {
        final offDate = dOff.toDate();
        // If the day+month+year match => day off
        if (offDate.year == dateToCheck.year &&
            offDate.month == dateToCheck.month &&
            offDate.day == dateToCheck.day) {
          print('is day off');
          return true;
        }
      }
      // if daysOff is list of something else => handle accordingly
    }
    return false;
  }

  // check if no weekend bridging => Node code references dayOfWeek==5 or dayOfWeek==1
  // but never fully spelled out. We'll attempt a partial match:
  bool checkNoWeekendBridge(int dayIndex) {
    // E.g. if dayIndex is a Friday or Monday, check neighbor days
    if (dayIndex < 0 || dayIndex >= eventDaysList.length) return false;

    final daySnap = eventDaysList[dayIndex];
    final dayData = daySnap.data() as Map<String, dynamic>;
    final dayTimestamp = dayData['date'] as Timestamp?;
    if (dayTimestamp == null) return false;
    final date = dayTimestamp.toDate();
    final dayOfWeek = date.weekday; // in Dart, Monday=1,... Sunday=7
    // Node code logic said: if dayOfWeek==5 or dayOfWeek==1 => check bridging
    // Let's adapt:
    if (dayOfWeek == DateTime.friday) {
      final nextIndex = dayIndex + 1;
      if (nextIndex < eventDaysList.length &&
          listOfDaysWithAssignedInstructors[nextIndex].contains(instructorId)) {
        return true;
      }
    } else if (dayOfWeek == DateTime.monday) {
      final prevIndex = dayIndex - 1;
      if (prevIndex >= 0 &&
          listOfDaysWithAssignedInstructors[prevIndex].contains(instructorId)) {
        return true;
      }
    }
    return false;
  }

  // Attempt to assign a shift
  while (notDone && tries < 50) {
    final randomSlot = getRandomShiftSlot();
    controller.statusMsg.value = '${controller.statusMsg.value}\nsearch for a free shift slot at ${eventDaysList[randomSlot].id}';
    //print('${controller.statusMsg.value}\nsearch for a free shift slot at ${eventDaysList[randomSlot].id}');
    // if instructor not already in this day
    print('is instructor already in this day?');
    print(listOfDaysWithAssignedInstructors[randomSlot].contains(instructorId));
    if (!listOfDaysWithAssignedInstructors[randomSlot].contains(instructorId)) {
      print('--looking at ${eventDaysList[randomSlot].id}');
      // check if day is not full
      if (listOfDaysWithAssignedInstructors[randomSlot].length < instructorsPerDay) {
        print('----day is not full');
        // check if instructor has not reached max days
        if (!checkMaxDaysLimitReached()) {
          print('------not reached max');
          print('#### day off? ${isDayOff(randomSlot)}');
          if (!isDayOff(randomSlot)) {
            print('--------not a day off');
            if (!checkNoWeekendBridge(randomSlot)) {
              // success, assign
              notDone = false;
              foundShift = randomSlot;
              listOfDaysWithAssignedInstructors[randomSlot].add(instructorId);
              // Update Firestore docs => day + instructor
              print('%%% Found Shift %%');
              final dayDocId = eventDaysList[randomSlot].id;
              final dayDocRef = firestore
                  .collection('Events')
                  .doc(eventName)
                  .collection('days')
                  .doc(dayDocId);
              // arrayUnion
              await dayDocRef.update({
                'instructors': FieldValue.arrayUnion([instructorId]),
              });

            } else {
              // conflict - weekend bridging
              // print('conflict - weekendbridge');
            }
          } else {
            // conflict - day off
            // print('conflict - day off');
          }
        } else {
          // print('conflict - no days left for instructor');
          notDone = false;
        }
      } else {
        // day is full
      }
    } else {
      // already assigned to day
    }
    tries++;
  }
  // if foundShift = -1 => no shift assigned
}