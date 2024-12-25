import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'exchange.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemoveInstructor extends StatefulWidget {
  const RemoveInstructor({super.key});

  @override
  State<RemoveInstructor> createState() => _RemoveInstructorState();
}

class _RemoveInstructorState extends State<RemoveInstructor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final instructorIdController = TextEditingController();
  final controller = Get.put(ExchangeController());
  static const String _title = 'מחיקת מדריך מהמערכת';
  final _globalKey = GlobalKey<ScaffoldMessengerState>();
  final firestore = FirebaseFirestore.instance;
  late CollectionReference eventInstructorsDocRef;
  Map<String, dynamic> instructorData = {};
  bool loading = false;
  onInit() async {
    eventInstructorsDocRef = firestore.collection('instructors');
  }

  getInstructorData(String id) async {
    //todo - remove - add function in controller
    setState(() {
      loading = true;
    });
    DocumentSnapshot instructorDoc = await eventInstructorsDocRef.doc(id).get();
    if (instructorDoc.exists) {
      // found
      setState(() {
        instructorData = instructorDoc.data() as Map<String, dynamic>;
        loading = false;
      });
    } else {
      // not found
      setState(() {
        instructorData = {};
        loading = false;
      });
    }
  }

  removeInstructor(String id) async {
    //todo - remove - add function in controller
    setState(() {
      loading = true;
    });
    //await eventInstructorsDocRef.doc(id).delete();
    print('removed $id');
    setState(() {
      loading = true;
    });
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
                child: Column(children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(20.0),
                            child: SizedBox(child: Text('ת.ז.')),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: instructorIdController,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        width: 300,
                        child: Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Icons.call),
                                title: Text("Name",
                                    style: TextStyle(color: Colors.green)),
                                subtitle: Text("ID",
                                    style:
                                        TextStyle(color: Colors.orangeAccent)),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    child: const Text('הסר מדריך מהמערכת'),
                                    onPressed: () {/* ... */},
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    child: const Text('ביטול'),
                                    onPressed: () {/* ... */},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            style: const ButtonStyle(
                              visualDensity: VisualDensity(
                                  horizontal: VisualDensity.minimumDensity,
                                  vertical: VisualDensity.minimumDensity),
                            ),
                            onPressed: () async {
                              setState(() {
                                loading = true;
                              });
                              await removeInstructor(instructorIdController.text);
                              setState(() {
                                loading = false;
                                instructorData = {};
                              });
                              //Navigator.pop(context);
                            },
                            child: const Text('חפש'),
                          ),
                          ElevatedButton(
                            style: const ButtonStyle(
                              visualDensity: VisualDensity(
                                  horizontal: VisualDensity.minimumDensity,
                                  vertical: VisualDensity.minimumDensity),
                            ),
                            onPressed: () async => {Navigator.pop(context)},
                            child: const Text('ביטול'),
                          ),
                        ],
                      )
                    ],
                  )
                ]),
              ))),
        ));
  }
}
