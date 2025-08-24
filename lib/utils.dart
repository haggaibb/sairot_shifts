
import 'package:http/http.dart' as http;


/// Example Instructor class.
class Instructor {
  final String armyId;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  int? maxDays;
  final List<dynamic>? daysOff;
  int  assignDays;


  Instructor(this.armyId,this.firstName,this.lastName,this.mobile,this.email,{this.maxDays, this.daysOff, this.assignDays=0});

  set setMaxDays(int maxDays) {
    maxDays = maxDays;
  }

  void addAssignedDay() {
    assignDays = assignDays + 1;
  }

  @override
  String toString() => armyId;

  String get daysOffStr {
    List<String> dates =[];
    daysOff?.forEach((dayOff) {
      DateTime date = dayOff.toDate();
      String dateKey = "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}";
      dates.add(dateKey);
      });
    if (dates.length<1) dates.add('איו אילוצים');
    return dates.toString();
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

  NewEvent({this.eventName,this.startDate,this.endDate,this.instructorsPerDay});


  @override
  String toString() => eventName??'';
}



List<Instructor> InstructorData=[];


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
