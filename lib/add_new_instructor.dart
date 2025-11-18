
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'exchange.dart';



class AddNewInstructor extends StatefulWidget {
  const AddNewInstructor({super.key});

  @override
  State<AddNewInstructor> createState() => _AddNewInstructorState();
}

class _AddNewInstructorState extends State<AddNewInstructor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final instructorFirstNameController = TextEditingController();
  final instructorLastNameController = TextEditingController();
  final instructorEMailController = TextEditingController();
  final instructorMobileController = TextEditingController();
  final instructorIdController = TextEditingController();
  final instructorMaxDaysController = TextEditingController();
  final controller = Get.put(ExchangeController());
  static const String _title = 'הוספת מדריך למערכת';
  final _globalKey = GlobalKey<ScaffoldMessengerState>();


  onInit() async {

  }

  submit() async {
    var data = {
      'first_name': instructorLastNameController.text,
      'last_name': instructorLastNameController.text,
      'email': instructorEMailController.text,
      'mobile': instructorMobileController.text,
      'max_days': int.parse(instructorMaxDaysController.text)
    };
    await controller.addInstructorToSystem(instructorIdController.text,data);
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
                  child: Column(
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SizedBox(
                                child: Text('שם פרטי')
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: instructorFirstNameController,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text('שם משפחה'),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: instructorLastNameController,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SizedBox(
                                child: Text('ת.ז.')
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: instructorIdController,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text('אמייל'),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: instructorEMailController,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text('טלפון'),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: instructorMobileController,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text('הזן מקסימום ימים'),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: instructorMaxDaysController,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 100,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            style: const ButtonStyle(
                              visualDensity: VisualDensity(
                                  horizontal: VisualDensity
                                      .minimumDensity,
                                  vertical: VisualDensity
                                      .minimumDensity),
                            ),
                            onPressed: () async
                            {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('הבקשה נשלחה')),
                              );
                              await submit();
                              Navigator.pop(context);
                            },
                            child: const Text('אישור'),
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
                            {
                              Navigator.pop(context)
                            },
                            child: const Text('ביטול'),
                          ),
                        ],
                      )
                    ],
                  )
                ),
              ))),
    );
  }
}
