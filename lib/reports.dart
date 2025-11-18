import 'package:flutter/material.dart';
import 'multi_date_picker.dart';
import 'package:get/get.dart';
import 'main.dart';
import 'package:screenshot/screenshot.dart';
import './utils.dart';
import 'approvals_report.dart';
import 'package:intl/intl.dart' as intl;

class Reports extends StatefulWidget {


  const Reports(
      {Key? key,})
      : super(key: key);

  @override
  _ReportsState createState() => _ReportsState();
}
class _ReportsState extends State<Reports> {
  final controller = Get.put(Controller());

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('הפקת דוחות'),
          ),
          body: Center(
            child: GridView.builder(
              padding: const EdgeInsets.all(30.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two buttons per row
                crossAxisSpacing: 20.0, // Spacing between columns
                mainAxisSpacing: 20.0, // Spacing between rows
                childAspectRatio: 4, // Adjust the aspect ratio for button size
              ),
              itemCount: 6, // Total number of buttons
              itemBuilder: (context, index) {
                // Determine button properties based on index
                String buttonText;
                Widget targetPage;
                switch (index) {
                  case 0:
                    buttonText = 'הפקת דוח מילואים רב יומי';
                    targetPage = MultiDatePicker(
                      instructorsPerDay: controller.instructorsPerDay,
                      startDate: controller.startDate.value,
                      endDate: controller.endDate.value,
                      eventDays: controller.eventDays,
                    );
                    break;
                  case 1:
                    buttonText = 'הפקת דוח אילוצי מדריכים';
                    targetPage = DaysOffReportPage();
                    break;
                  case 2:
                    buttonText = 'הפקת דוח ימים מוקצים';
                    targetPage = DaysCountReportPage();
                    break;
                  case 3:
                    buttonText = 'דוח אישורי החלפה ומסירה';
                    targetPage = RequestApprovalsTableScreen();
                    break;
                  case 4:
                    buttonText = 'דוח אישורי כניסה';
                    targetPage = EventInstructorsReportPage();
                    break;
                  case 5:
                    buttonText = 'דוח קבוצות למחר';
                    targetPage = TomorrowGroupsReportPage();
                    break;
                  default:
                    buttonText = '';
                    targetPage = const SizedBox(); // Fallback widget
                }

                return SizedBox(
                  height: 60,
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                            textDirection: TextDirection.rtl, // Set RTL
                            child: targetPage, // Navigate to respective page
                          ),
                        ),
                      );
                    },
                    child: Text(buttonText),
                  ),
                );
              },
            ),
          ),
        ));
  }
}
/////////////////
////////////////
class DaysOffReportPage extends StatelessWidget {
  final controller = Get.put(Controller());

  DaysOffReportPage(
      {super.key});

  final ScreenshotController screenshotController = ScreenshotController();
  @override
  Widget build(BuildContext context) {
    List<Instructor> instructors = controller.eventInstructors;
    final dateFormatter = intl.DateFormat('dd-MM-yyyy');
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('דוח אילוצי מדריכים'),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.network('assets/images/logo.png' ,height: 50,),
                  Text('דוח אילוצי מדריכים', style: TextStyle(fontSize: 20),),
                  const SizedBox(width: 200, child: Divider(thickness: 2, color: Colors.black,)),
                  Directionality(textDirection: TextDirection.rtl,
                      child: DataTable(
                          columns: const <DataColumn>[
                            DataColumn(
                              label: Text(
                                textDirection: TextDirection.rtl,
                                'שם מלא',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                textDirection: TextDirection.rtl,
                                'ת.ז.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                textDirection: TextDirection.rtl,
                                'אילוצים',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                          rows: List.generate(instructors.length, (index) =>
                              DataRow(
                                cells: <DataCell>[
                                  DataCell(Text(textDirection: TextDirection.rtl,'${instructors[index].firstName} ${instructors[index].lastName}')),
                                  DataCell(Text(textDirection: TextDirection.rtl,instructors[index].armyId)),

                      DataCell(
                      Text(
                      instructors[index].daysOff != null
                      ? instructors[index]
                          .daysOff!
                      .map((e) => dateFormatter.format(DateTime.parse(e.toString())))
        .join(', ')
        : 'אין חופשות',
    style: TextStyle(fontSize: 8),
    softWrap: true,
    textDirection: TextDirection.rtl,
    ),
    ),                                ],
                              ))
                      ))
                ]
              ),
            ),
          ),
        ));
  }
}
class DaysOffReportReportImage extends StatelessWidget {
  final String title;
  final List<Instructor> instructors;


  DaysOffReportReportImage(this.title, this.instructors, {super.key});

  @override
  Widget build(BuildContext context) {
    //print(listByDay);
    //print(selectedDays);
    return Center(
      child: Column(
        children: [
          Image.network('assets/images/logo.png' ,height: 50,),
          Text(title, style: const TextStyle(fontSize: 20),),
          const SizedBox(width: 200, child: Divider(thickness: 2, color: Colors.black,)),
          Column(
            children: List.generate(instructors.length, (index) =>
                Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 50),
                        child: Text('.${index+1}'),
                      ),
                      Text(instructors[index].armyId),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: Text(instructors[index].firstName),
                      ),
                      Text(instructors[index].lastName),
                      Text(' ${instructors[index].daysOff.toString()} '),
                    ]
                )

            ),),
        ],
      ),
    );
  }
}

///////////////
///////////////
class DaysCountReportPage extends StatelessWidget {
  final controller = Get.put(Controller());

  DaysCountReportPage(
      {super.key});

  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('דוח הקצאת ימי מילואים'),
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
                            child: DaysCountReportImage('דוח הקצאת ימי מילואים',controller.eventInstructors),
                          ),
                        ),
                        delay: Duration(milliseconds: 100),
                        context: context,
                      )
                          .then((capturedImage) async {
                        await controller.saveMiluimDayReportImage(
                            capturedImage, 'דוח הקצאת ימי מילואים');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                              'הקובץ נשמר',
                              style: TextStyle(color: Colors.white),
                            )),
                      );
                    },
                    child: const SizedBox(
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
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
                      await controller.saveInstructorsDayCountReportCSV('דוח הקצאת ימי מילואים');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                              'הקובץ נשמר',
                              style: TextStyle(color: Colors.white),
                            )),
                      );
                    },
                    child: const SizedBox(
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Icons.table_rows_outlined),
                          Text('שמור לקובץ CSV'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ListView.builder(
                        itemCount: controller.eventInstructors.length,
                        itemBuilder: (context, index) {
                          final instructor = controller.eventInstructors[index];
                          return Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Text(
                                  '${index + 1}. ${instructor.firstName} ${instructor.lastName}',
                                  style: TextStyle(
                                    //fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Text(
                                  controller.eventInstructors[index].assignDays.toString(),
                                  style: TextStyle(
                                    //fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                            ],
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
class DaysCountReportImage extends StatelessWidget {
  final String title;
  final List<Instructor> instructors;


  DaysCountReportImage(this.title, this.instructors, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Image.network('assets/images/logo.png' ,height: 50,),
          Text(title, style: TextStyle(fontSize: 20),),
          const SizedBox(width: 200, child: Divider(thickness: 2, color: Colors.black,)),
          Column(
            children: List.generate(instructors.length, (index) =>
                      Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 50),
                              child: Text('.${index+1}'),
                             ),
                             Text(instructors[index].armyId),
                             Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text(instructors[index].firstName),
                             ),
                             Text(instructors[index].lastName),
                            Text(' ${instructors[index].assignDays} '),
                          ]
                      )

                ),),
        ],
      ),
    );
  }
}
///////////////
///////////////
class DaysInstructorsDetailedReportPage extends StatelessWidget {
  final controller = Get.put(Controller());

  DaysInstructorsDetailedReportPage(
      {super.key});

  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('דוח ימי מילואים מפורט'),
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
                            child: DaysInstructorsDetailedReportImage('דוח ימי מילואים מפורט',controller.eventInstructors),
                          ),
                        ),
                        delay: Duration(milliseconds: 100),
                        context: context,
                      )
                          .then((capturedImage) async {
                        await controller.saveMiluimDayReportImage(
                            capturedImage, 'דוח ימי מילואים מפורט');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                              'הקובץ נשמר',
                              style: TextStyle(color: Colors.white),
                            )),
                      );
                    },
                    child: const SizedBox(
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Icons.save_alt),
                          Text('הורד דוח'),
                        ],
                      ),
                    ),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(12.0),
                //   child: ElevatedButton(
                //     onPressed: () async {
                //       await controller.saveMiluimDayReportCSV(
                //           controller.eventInstructors, 'TODO');
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //             content: Text(
                //               'הקובץ נשמר',
                //               style: TextStyle(color: Colors.white),
                //             )),
                //       );
                //     },
                //     child: Container(
                //       width: 180,
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //         children: const [
                //           Icon(Icons.table_rows_outlined),
                //           Text('שמור לקובץ CSV'),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                Expanded(
                  child: Center(
                    child: ListView.builder(
                        itemCount: controller.eventInstructors.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            shadowColor: Colors.greenAccent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  //leading: Icon(Icons.album),
                                  title: Text('${controller.eventInstructors[index].firstName} ${controller.eventInstructors[index].lastName}',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  subtitle: Text(controller.eventInstructors[index].armyId),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(left:8,right:20,top :0, bottom: 0),
                                      child: Text('ימים מוקצים' ,style: TextStyle(fontWeight: FontWeight.bold),),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(left:8.0,right:20,top :0, bottom: 5),
                                      child: Text(controller.eventInstructors[index].assignDays.toString()),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(left:8.0,right:20,top :5, bottom: 0),
                                      child: Text('אילוצים',style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    controller.eventInstructors[index].daysOff!.isNotEmpty?
                                    Padding(
                                      padding: const EdgeInsets.only(left:0.0,right:20,top :0, bottom: 0),
                                      child: SizedBox(
                                        height: ((controller.eventInstructors[index].daysOff!.length/4).floorToDouble()+1)*50,
                                        width: 200,
                                        child: controller.eventInstructors[index].daysOff!.isNotEmpty?
                                            GridView.count(
                                              shrinkWrap: true,
                                          crossAxisCount: 4,
                                          children: List.generate(controller.eventInstructors[index].daysOff!.length, (daysOffIndex) {
                                            return Text(
                                              '${(controller.eventInstructors[index].daysOff?[daysOffIndex])?.day}/'
                                                  '${(controller.eventInstructors[index].daysOff?[daysOffIndex])?.month}',
                                            );
                                          }),
                                        )
                                            :Text('אין אילוצים'),
                                      ),
                                    )
                                    :Padding(
                                      padding: EdgeInsets.only(left:0.0,right:20,top :0, bottom: 5),
                                      child: Text('אין אילוצים'),
                                    ),

                                  ],
                                )
                              ],
                            ),
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
class DaysInstructorsDetailedReportImage extends StatelessWidget {
  final String title;
  final List<Instructor> instructors;


  DaysInstructorsDetailedReportImage(this.title, this.instructors, {super.key});
  @override
  Widget build(BuildContext context) {
    print('hetre');

    return Center(
      child: Column(
        children: [
          Image.network('assets/images/logo.png' ,height: 50,),
          Text(title, style: TextStyle(fontSize: 20),),
          const SizedBox(width: 200, child: Divider(thickness: 2, color: Colors.black,)),
          Directionality(textDirection: TextDirection.rtl,
              child: DataTable(
            columns: const <DataColumn>[
              DataColumn(
                label: Text(
                  textDirection: TextDirection.rtl,
                  'שם מלא',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              DataColumn(
                label: Text(
                  textDirection: TextDirection.rtl,
                  'ת.ז.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              DataColumn(
                label: Text(
                  textDirection: TextDirection.rtl,
                  'הקצאה',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              DataColumn(
                label: Text(
                  textDirection: TextDirection.rtl,
                  'אילוצים',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            rows:
            List.generate(instructors.length, (index) =>
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text(textDirection: TextDirection.rtl,'${instructors[index].firstName} ${instructors[index].lastName}')),
                    DataCell(Text(textDirection: TextDirection.rtl,instructors[index].armyId)),
                    DataCell(Text(textDirection: TextDirection.rtl,instructors[index].assignDays.toString())),
                    DataCell(Text(textDirection: TextDirection.rtl,instructors[index].daysOff.toString(), style: const TextStyle(fontSize: 8),)),
                  ],
                )
            )
          ))
        ],
      ),
    );
  }
}
///////////////
///////////////
class EventInstructorsReportPage extends StatelessWidget {
  final controller = Get.put(Controller());

  EventInstructorsReportPage(
      {super.key});


  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('רשימת המדריכים לארוע הפעיל'),
          ),
          body: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.saveEventInstructorsReportCSV();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                              'הקובץ נשמר',
                              style: TextStyle(color: Colors.white),
                            )),
                      );
                    },
                    child: const SizedBox(
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
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
                          itemCount: controller.eventInstructors.length,
                          itemBuilder: (context, index) {
                            final instructor = controller.eventInstructors[index];
                            return Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Text(
                                    '${index + 1}. ${instructor.firstName} ${instructor.lastName}',
                                    style: TextStyle(
                                      //fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Text(
                                    instructor.armyId,
                                    style: TextStyle(
                                      //fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
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
class EventInstructorsReportImage extends StatelessWidget {
  final String title;
  final List<Instructor> instructors;


  EventInstructorsReportImage(this.title, this.instructors, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Image.network('assets/images/logo.png' ,height: 50,),
          Text(title, style: const TextStyle(fontSize: 20),),
          const SizedBox(width: 200, child: Divider(thickness: 2, color: Colors.black,)),
      DataTable(
        columns: const [
          DataColumn(label: Text('מספר')),
          DataColumn(label: Text('מספר אישי')),
          DataColumn(label: Text('שם פרטי')),
          DataColumn(label: Text('שם משפחה')),
        ],
        rows: List.generate(
          instructors.length,
              (index) => DataRow(
            cells: [
              DataCell(Text('.${index + 1}')), // Serial number
              DataCell(Text(instructors[index].armyId)), // Army ID
              DataCell(Text(instructors[index].firstName)), // First name
              DataCell(Text(instructors[index].lastName)), // Last name
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
///////////////
///////////////
class TomorrowGroupsReportPage extends StatefulWidget {

  const TomorrowGroupsReportPage({super.key});

  @override
  State<TomorrowGroupsReportPage> createState() => _TomorrowGroupsReportPageState();
}
class _TomorrowGroupsReportPageState extends State<TomorrowGroupsReportPage> {
  final controller = Get.put(Controller());
  final DateTime today  = DateTime.now();
  late DateTime tomorrow;
  late String tomorrowDateKey;
  List<TextEditingController> groupsCtrl =[];


  @override
  void initState() {
    tomorrow = today.add(const Duration(days: 1));
    tomorrowDateKey =
        "${tomorrow.day.toString().padLeft(2, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.year.toString()}";
    for (var element in controller.tomorrowInstructorsList) {
      groupsCtrl.add(TextEditingController());
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('דוח קבוצות למחר'),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                  children: [
                    //Image.network('assets/images/logo.png' ,height: 50,),
                    //const Text('דוח קבוצות למחר', style: TextStyle(fontSize: 20),),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller.saveTomorrowInstructorsCSV(tomorrowDateKey,groupsCtrl);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                  'הקובץ נשמר',
                                  style: TextStyle(color: Colors.white),
                                )),
                          );
                        },
                        child: const SizedBox(
                          width: 180,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(Icons.table_rows_outlined),
                              Text('שמור לקובץ CSV'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Text(tomorrowDateKey, style: TextStyle(fontSize: 20),),
                    const SizedBox(width: 200, child: Divider(thickness: 2, color: Colors.black,)),
                    Directionality(textDirection: TextDirection.rtl,
                        child: DataTable(
                            columns: const <DataColumn>[
                              DataColumn(
                                label: Text(
                                  textDirection: TextDirection.rtl,
                                  '',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  textDirection: TextDirection.rtl,
                                  'שם מלא',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  textDirection: TextDirection.rtl,
                                  'קבוצה',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                            rows: List.generate(controller.tomorrowInstructorsList.length, (index) =>
                                DataRow(
                                  cells: <DataCell>[
                                    DataCell(Text((index+1).toString(), style: TextStyle(fontSize: 8), softWrap: true, textDirection: TextDirection.rtl)),
                                    DataCell(Text(textDirection: TextDirection.rtl,'${controller.tomorrowInstructorsList[index].firstName} ${controller.tomorrowInstructorsList[index].lastName}')),
                                    DataCell(
                                        TextField(
                                          controller: groupsCtrl[index],
                                          enabled: true,
                                        )
                                    ),
                                  ],
                                ))
                        ))
                  ]
              ),
            ),
          ),
        ));
  }
}
