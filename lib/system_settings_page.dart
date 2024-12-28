
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shifts/db_create_new_event.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import './utils.dart';
import 'package:get/get.dart';
import 'main.dart';
import 'run_shifts_builder_algo.dart';
import 'dart:convert';


class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  static const String _title = 'הגדרות מערכת';
  final _globalKey = GlobalKey<ScaffoldMessengerState>();
  final controller = Get.put(Controller());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController activeEventController = TextEditingController();
  final TextEditingController newAdminIDController = TextEditingController();
  final TextEditingController eventModeController = TextEditingController();
  final TextEditingController shiftsBuilderEventController = TextEditingController();

  late List<String> eventsList;
  late String selectedEvent;
  late List<String> adminsList;
  late List<String> eventStatusModes;
  late String selectedMode;
  late String selectedShiftsBuilderEvent;


  saveSettings() async{
    controller.loading.value = true;
    controller.currentEventStatus.value = selectedMode;
    controller.currentEvent.value = selectedEvent;
    await controller.updateSettings();
    controller.loading.value = false;
    Navigator.pop(context);Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
          content:
          Text('הנתונים נשמרו!!')),
    );

  }

  runShiftsBuilder() async {
    controller.loading.value = true;
    if (controller.isEventActive(selectedShiftsBuilderEvent)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ארוע פעיל! לא ניתן להריץ שיבוץ')),
      );
      controller.loading.value = false;
      return;
    }
    await runShiftsBuilderAlgo(selectedShiftsBuilderEvent);
    controller.loading.value = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('השיבוץ הסתיים.')),
    );
  }


  @override
  void initState() {
    super.initState();
    eventsList = controller.eventsNameList;
    adminsList = controller.admins;
    selectedEvent = controller.eventName;
    eventStatusModes = controller.eventStatusModes;
    selectedMode = controller.currentEventStatus.value;
    selectedShiftsBuilderEvent = eventsList[0];


  }


  @override
  Widget build(BuildContext context) {


      return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.grey[100],
              key: _globalKey,
              appBar: AppBar(
                  leading: IconButton(
                    onPressed: () => {Navigator.pop(context)},
                    icon: Icon(Icons.arrow_back),
                  ),
                  title: const Text(_title)),
              body: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Obx(() => !controller.loading.value
                    ?Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: 300,
                            height: 400,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('הגדרות ארוע פעיל' , style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                                Card(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left :20.0, right :10),
                                            child: Text('ארוע פעיל'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: SizedBox(
                                              width: 150,
                                              child: DropdownMenu<String>(
                                                initialSelection: selectedEvent,
                                                controller: activeEventController,
                                                requestFocusOnTap: true,
                                                label: const Text('ארוע'),
                                                onSelected: (String? event) {
                                                  setState(() {
                                                    selectedEvent = event??'';
                                                  });
                                                },
                                                dropdownMenuEntries: eventsList
                                                    .map<DropdownMenuEntry<String>>(
                                                        (String event) {
                                                      return DropdownMenuEntry<String>(
                                                        value: event,
                                                        label: event,
                                                        enabled: event != 'Grey',
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left :20.0, right :10),
                                            child: Text('סטטוס הארוע'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: SizedBox(
                                              width: 150,
                                              child: DropdownMenu<String>(
                                                initialSelection: selectedMode,
                                                controller: eventModeController,
                                                requestFocusOnTap: true,
                                                label: const Text('סטטוס'),
                                                onSelected: (String? mode) {
                                                  setState(() {
                                                    selectedMode = mode??'סגור';
                                                  });
                                                },
                                                dropdownMenuEntries: eventStatusModes
                                                    .map<DropdownMenuEntry<String>>(
                                                        (String mode) {
                                                      return DropdownMenuEntry<String>(
                                                        value: mode,
                                                        label: mode,
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  )
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            height: 400,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('מנהלי מערכת' , style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                                Card(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: SizedBox(
                                                width: 150,
                                                child: TextFormField(
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    hintText: 'הזן ת.ז.',
                                                  ),
                                                  controller: newAdminIDController,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    adminsList.add(newAdminIDController.text);
                                                  });
                                                },
                                                child: const Text('הוסף'),
                                              ),
                                            ),

                                          ],
                                        ),
                                        DataTable(
                                          columns: <DataColumn>[
                                            DataColumn(
                                              label: Text('מנהלי מערכת'),
                                            ),
                                            DataColumn(
                                              label: Text(''),
                                            ),
                                          ],
                                          rows: List<DataRow>.generate(
                                            adminsList.length,
                                                (int index) => DataRow(
                                              cells: <DataCell>[
                                                DataCell(Text(adminsList[index])),
                                                DataCell(
                                                    IconButton(
                                                      icon: const Icon(Icons.delete),
                                                      tooltip: 'הסר הרשאה',
                                                      onPressed: () {
                                                        setState(() {
                                                          adminsList.remove(adminsList[index]);
                                                        });
                                                      },
                                                    )
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      ],
                                    )
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            height: 400,
                            child: Column(
                              children: [
                                Text('הרצת שיבוץ לארוע' , style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                                Card(
                                  color: Colors.red[100],
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Text(''),
                                        Text('שים לב!!!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        Text('הרצה של שיבוץ תימחק את כל הנתונים', style: TextStyle(fontSize: 12),),
                                        Text('של השיבוצים, ההחלפות והמסירות', style: TextStyle(fontSize: 12)),
                                        Text('של הארוע', style: TextStyle(fontSize: 12)),
                                        DropdownMenu<String>(
                                          initialSelection: selectedShiftsBuilderEvent,
                                          controller: shiftsBuilderEventController,
                                          requestFocusOnTap: true,
                                          label: const Text('ארוע'),
                                          onSelected: (String? event) {
                                            setState(() {
                                              selectedShiftsBuilderEvent = event??'';
                                            });
                                          },
                                          dropdownMenuEntries: eventsList
                                              .map<DropdownMenuEntry<String>>(
                                                  (String event) {
                                                return DropdownMenuEntry<String>(
                                                  value: event,
                                                  label: event,
                                                  enabled: event != 'Grey',
                                                );
                                              }).toList(),
                                        ),
                                        //Text(selectedEvent, style: TextStyle(fontSize: 9)),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12.0),
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              bool? res = await showDialog<bool>(
                                                  context: context,
                                                  builder: (BuildContext context) =>
                                                      AdminPinDialog(controller.admins));
                                              if (res??false) {
                                                runShiftsBuilder();
                                              }
                                              else {
                                                /// TODO snack msg
                                                print('not a valid admin');
                                              }
                                            },
                                            child: const Text('הרץ שיבוץ'),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[100]
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('בטל'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[100]
                              ),
                              onPressed: () async {
                                await saveSettings();
                              },
                              child: const Text('שמור'),
                            ),
                          )
                        ],
                      ),
                    ],
                  )
                )
                    :Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(controller.statusMsg.value, style: TextStyle(fontSize: 20),),
                        CircularProgressIndicator(),
                      ],
                    ))
                ),
              )));

  }



}



