
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'exchange.dart';



class AddInstructToDay extends StatefulWidget {
  const AddInstructToDay({super.key});

  @override
  State<AddInstructToDay> createState() => _AddInstructToDayState();
}

class _AddInstructToDayState extends State<AddInstructToDay> {
  int _index = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final instructorIdController = TextEditingController();
  String addDateDropdownValue = 'לא נטען';
  final controller = Get.put(ExchangeController());
  static const String _title = 'הוסף מדריך ליום ספציפי';
  final _globalKey = GlobalKey<ScaffoldMessengerState>();


  onInit() async {

  }


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
                          if (_formKey.currentState!.validate() && instructorIdController.text!='') {
                            print('validate');
                            // If the form is valid, display a snackbar. In the real world,
                            // you'd often call a server or save the information in a database.
                            await controller.loadDaysWithoutInstructor(
                                instructorIdController.text);
                            if (controller.daysWithoutInstructor.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('לא נמצאו ימים!!!')),
                              );
                            } else {
                                setState(() {
                                  addDateDropdownValue =
                                  controller.daysWithoutInstructor[0];
                                  _index++;
                                });
                            }
                          }
                        } else if (_index == 1) {
                            setState(() => _index++);
                          } else if (_index == 2) {
                            setState(() => _index++);
                          }
                      },
                      onStepTapped: (int index) {
                        if (controller.daysWithoutInstructor.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('לא נמצאו ימים למספר אישי זה')),
                          );
                        } else {
                          setState(() {
                            _index = index;
                          });
                        }
                      },
                      steps: <Step>[
                        Step(
                            title: const Text('הוסף מדריך ליום ספציפי'),
                            subtitle: const Text('נא הזן ת.ז. של המדריך'),
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
                            title: const Text('בחירת  היום'),
                            content: Obx(() => Container(
                              alignment: Alignment.centerRight,
                              child: DropdownButton(
                                onChanged: (String? value) {
                                  setState(() {
                                    addDateDropdownValue = value!;
                                  });
                                },
                                value: addDateDropdownValue,
                                items: controller.daysWithoutInstructor
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
                            title: const Text('אישור הבקשה'),
                            content: Container(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('הבקשה נשלחת למערכת')),
                                  );
/*                                  addDateDropdownValue =
                                  addDateDropdownValue == ''
                                      ? controller.daysForInstructor[0]
                                      : addDateDropdownValue;*/
                                  var addSplitResult =
                                  addDateDropdownValue.split('-');
                                  var addDateForParse =
                                      '${addSplitResult[0]}-${addSplitResult[1]}-${addSplitResult[2]}';
                                  await controller.addInstructorToDay(instructorIdController.text,  addDateForParse);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('הבקשה התקבלה')),
                                  );
                                  Navigator.pop(context);
                                  controller.loadAllRequests();
                                },
                                child: const Text('אשר את הבקשה'),
                              ),
                            )),
                      ],
                      controlsBuilder:
                          (BuildContext context, ControlsDetails dtl) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20, right: 100),
                          child: Row(
                              children: _index != 2
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
