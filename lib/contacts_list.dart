import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsListPage extends StatelessWidget {
  final List eventInstructors;
  ContactsListPage({super.key, List? eventInstructors }):this.eventInstructors = eventInstructors ?? [];
  @override

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('דך קשר'),
          ),
          body: Center(
            child: ListView.builder(
                itemCount: eventInstructors.length,
                itemBuilder: (context, index) {
                  final instructor = eventInstructors[index];
                  final Uri telLaunchUri = Uri(
                    scheme: 'tel',
                    path: instructor.mobile,
                  );
                  final Uri smsLaunchUri = Uri(
                    scheme: 'sms',
                    path: instructor.mobile,
                    queryParameters: <String, String>{},
                  );
                  return Card(
                      child: ExpansionTile(
                        expandedAlignment: Alignment.topRight,
                        title: Text(
                            '${index + 1}. ${instructor.firstName} ${instructor.lastName}'),
                        children: [
                          Row(
                            children: [
                              Text(' נייד ${instructor.mobile} '),
                              ElevatedButton(
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity(
                                      horizontal:
                                      VisualDensity.minimumDensity,
                                      vertical:
                                      VisualDensity.minimumDensity),
                                ),
                                onPressed: () async =>
                                {await launchUrl(telLaunchUri)},
                                child: const Text('חייג'),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity(
                                      horizontal:
                                      VisualDensity.minimumDensity,
                                      vertical:
                                      VisualDensity.minimumDensity),
                                ),
                                onPressed: () async =>
                                {await launchUrl(smsLaunchUri)},
                                child: const Text('הודעה'),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          )
                          //Row(children: [Text(' מ.א. ${instructor.armyId}'),],)
                        ],
                      ));
                }),
          ),
        ));
  }
}
