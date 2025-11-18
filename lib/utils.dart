
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Example Instructor class.
class Instructor {
  final String armyId;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  int maxDays; // can still be mutable if you want to edit in UI
  final List<DateTime>? daysOff;
  int assignDays;

  Instructor({
    required this.armyId,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.maxDays,
    this.daysOff,
    this.assignDays = 0,
  });

  /// Construct from Firestore/JSON map
  factory Instructor.fromMap(Map<String, dynamic> map , String armyId) {
    return Instructor(
      armyId: armyId ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      mobile: map['mobile'] ?? '',
      email: map['email'] ?? '',
      maxDays: map['max_days'] is String
          ? int.tryParse(map['max_days']) ?? 0
          : (map['max_days'] is int ? map['max_days'] : 0),
      daysOff:  map['days_off'] != null
          ? ((map['days_off']) as List)
          .map((e) {
        if (e is Timestamp) return e.toDate();
        if (e is DateTime) return e;
        if (e is String) return DateTime.tryParse(e) ?? DateTime(1970);
        return DateTime(1970);
      })
          .toList()
          : null,
      assignDays: map['assignDays'] ?? 0,
    );
  }

  /// Convert back to Firestore/JSON map
  Map<String, dynamic> toMap() {
    return {
      'armyId': armyId,
      'first_name': firstName,
      'last_name': lastName,
      'mobile': mobile,
      'email': email,
      'max_days': maxDays,
      'days_off': daysOff?.map((e) => Timestamp.fromDate(e)).toList(),
      'assignDays': assignDays,
    };
  }
}

class Request {
  final String armyId;
  final String fullName;
  final DateTime requestInit;
  final String type;
  final DateTime giveDay;
  final List<DateTime>? takeDays;
  final String? requestId;

  const Request(this.armyId,this.fullName,this.requestInit,this.type,this.giveDay,this.takeDays,this.requestId);

  Map toJson() => {
    'army_id': armyId,
    'full_name': fullName,
    'requestInit' : requestInit,
    'type' : type,
    'give_day' : giveDay,
    'take_days' : takeDays,
    'requestId' : requestId
  };

  @override
  String toString() => takeDays.toString();
}

class NewEvent{
  String? eventName;
  DateTime? startDate;
  DateTime? endDate;
  int? instructorsPerDay;
  List<Instructor>? eventInstructors;
  List<String>? eventDays;

  NewEvent({this.eventName,this.startDate,this.endDate,this.instructorsPerDay, this.eventInstructors, this.eventDays});

  @override
  String toString() => eventName??'';
}

// List<Instructor> instructorData=[];

getInstructorData(String instructorId, List<Instructor> instructorsList) {
  bool found = false;
  int index = 0;
  var instructorData;
  while (!found && index <instructorsList.length) {
    if (instructorsList[index].armyId==instructorId) {
      found=true;
      instructorData = {
        'armyId' :  instructorsList[index].armyId,
        'firstName' : instructorsList[index].firstName,
        'lastName' : instructorsList[index].lastName,
        'mobile' : instructorsList[index].mobile,
        'email' : instructorsList[index].email,
        'maxDays' :  instructorsList[index].maxDays,
      };
    } else {
      index++;
    }
  }
  if (!found) {
    print(instructorId);
    instructorData = {
    'armyId' :  '--',
    'firstName' :  '--',
    'lastName' :  '--',
    'mobile' :  '--'
  };
  }
  return instructorData;
}

String toDateKey(DateTime selectedDay) {
  String dateKey = "${selectedDay.day.toString().padLeft(2,'0')}-${selectedDay.month.toString().padLeft(2,'0')}-${selectedDay.year.toString()}";
  return dateKey;
}

toValidDateKey(String selectedDay) {
  String dateKey = selectedDay.substring(6)+'-'+selectedDay.substring(3,5)+'-'+selectedDay.substring(0,2);
  //String dateKey = "${selectedDay.year.toString()}-${selectedDay.month.toString().padLeft(2,'0')}-${selectedDay.day.toString().padLeft(2,'0')}";
  return dateKey;
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

triggerExtFunction(var data, String functionName) async {
print('activate function ' +functionName);
  try {
    var url = Uri.http(
        //'us-central1-dripit.cloudfunctions.net', functionName);
        '127.0.0.1:5001', '/yemey-siarot/us-central1/$functionName');
    print(url);
    var response = await http
        .post(url, body: data);
    print(response.statusCode);
    print(response.body);
  } catch (e) {
    print(e);
  }
}
