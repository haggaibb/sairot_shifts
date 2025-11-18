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
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final instructorIdController = TextEditingController();
  final controller = Get.put(ExchangeController());
  static const String _title = 'מחיקת מדריך מהמערכת';
  final _globalKey = GlobalKey<ScaffoldMessengerState>();
  final firestore = FirebaseFirestore.instance;
  bool foundInstructor = false;
  Map<String, dynamic> instructorData = {};
  bool loading = false;
  onInit() async {
  }

  Future <Map<String, dynamic>> loadInstructorData(String id) async {
    if (id=='') return {};
    setState(() {
      loading = true;
    });
    DocumentSnapshot instructorDoc = await firestore.collection('Instructors').doc(id).get();
    if (instructorDoc.exists) {
      // found
      setState(() {
        loading = false;
        foundInstructor = true;
      });
      instructorData = instructorDoc.data() as Map<String, dynamic>;
      return instructorData;
    } else {
      // not found
      setState(() {
        foundInstructor = false;
        loading = false;
      });
      return {};
    }
  }

  removeInstructor(String id) async {
    setState(() {
      loading = true;
    });
    await firestore.collection('Instructors').doc(id).delete();
    setState(() {
      instructorData = {};
      foundInstructor = false;
      instructorIdController.text = '';
      loading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: _title,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ScaffoldMessenger(
            key: _scaffoldMessengerKey,
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
                  child: SizedBox(
                    width: 400,
                    height: 500,
                    child: Column(
                        //mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: SizedBox(child: Text('ת.ז.')),
                              ),
                              SizedBox(
                                width: 150,
                                child: TextFormField(
                                  controller: instructorIdController,
                                ),
                              ),
                              ElevatedButton(
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity(
                                      horizontal: VisualDensity.minimumDensity,
                                      vertical: VisualDensity.minimumDensity),
                                ),
                                onPressed: () async {
                                  Map<String, dynamic> data = await loadInstructorData(
                                      instructorIdController.text);
                                  setState(() {
                                    if (!foundInstructor) {
                                      _scaffoldMessengerKey.currentState!.showSnackBar(
                                        const SnackBar(
                                            content: Text('לא נמצא מספר אישי כזה במערכת!!!')),
                                      );
                                      instructorData = data;
                                      instructorIdController.text='';
                                    }
                                  });
                                  //Navigator.pop(context);
                                },
                                child: const Text('חפש'),
                              ),
                            ],
                          ),
                          loading?SizedBox(width: 200, child: LinearProgressIndicator()):SizedBox.shrink(),
                          foundInstructor
                              ? SizedBox(
                                  height: 200,
                                  width: 300,
                                  child: Card(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(Icons.contacts_sharp),
                                          title: Text('${instructorData['last_name'] ?? ''} ${instructorData['first_name'] ?? ''}',
                                              style:
                                                  const TextStyle(color: Colors.green)),
                                          subtitle: Text(instructorIdController.text,
                                              style: const TextStyle(
                                                  color: Colors.orangeAccent)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(right : 12.0),
                                          child: Text('דואר אלקטרוני:   ${instructorData['email']?? '--'}'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(right: 12.0),
                                          child: Text('נייד:   ${instructorData['mobile']?? '--'}'),
                                        ),
                                        SizedBox(height: 30,),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              child:
                                                  const Text('הסר מדריך מהמערכת', style: TextStyle(color: Colors.red),),
                                              onPressed: () async {
                                                setState(() {
                                                  loading = true;
                                                });
                                                await removeInstructor(
                                                    instructorIdController.text);
                                                _scaffoldMessengerKey.currentState!.showSnackBar(
                                                  const SnackBar(
                                                      content: Text('המדריך הוסר מהמערכת!')),
                                                );
                                                setState(() {
                                                  loading = false;
                                                  instructorData = {};
                                                  instructorIdController.text='';
                                                });
                                                //Navigator.pop(context);
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton(
                                              child: const Text('ביטול'),
                                              onPressed: () {
                                                setState(() {
                                                  instructorIdController.text='';
                                                  foundInstructor = false;
                                                  instructorData = {};
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(),
                        ]),
                  ),
                ))),
          ),
        ));
  }
}
