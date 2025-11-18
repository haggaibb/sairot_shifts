import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'shifts_cells.dart';

class ShiftsTableView extends StatefulWidget {
  final List instructorsPerDayList;
  final List daysList;
  final int maxInstructorsPerDay;

  const ShiftsTableView(
      {Key? key, required this.instructorsPerDayList, required this.daysList, required this.maxInstructorsPerDay})
      : super(key: key);

  @override
  _ShiftsTableViewState createState() => _ShiftsTableViewState();
}

class _ShiftsTableViewState extends State<ShiftsTableView> {
  late LinkedScrollControllerGroup _controllers;
  late ScrollController _headController;
  late ScrollController _bodyController;

  @override
  void initState() {
    super.initState();
    //print(widget.instructorsPerDayList[0]);
    _controllers = LinkedScrollControllerGroup();
    _headController = _controllers.addAndGet();
    _bodyController = _controllers.addAndGet();
  }

  @override
  void dispose() {
    _headController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int numberOfInstructorsPerDay = widget.maxInstructorsPerDay;
     return
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: widget.instructorsPerDayList.length * cellWidth,
            child: GridView.count(
              //childAspectRatio: 0.6,
              //padding: EdgeInsets.only(left: 10, right: 10),
              //crossAxisSpacing: 50,
              //shrinkWrap: true,
                crossAxisCount: widget.instructorsPerDayList.length,
                children: List.generate((widget.instructorsPerDayList.length*numberOfInstructorsPerDay)+widget.instructorsPerDayList.length , (i) {
                  //if (i>widget.instructorsPerDayList.length-1) {
                  if (i>widget.instructorsPerDayList.length-1) {
                    i = i - widget.instructorsPerDayList.length;
                    var x = i~/widget.instructorsPerDayList.length;
                    var offset = x*(widget.instructorsPerDayList.length-numberOfInstructorsPerDay);
                    var y = i - (x*numberOfInstructorsPerDay) - offset;
                    widget.instructorsPerDayList[y].sort((a, b) => a['firstName'].toString().compareTo(b['firstName'].toString()));
                    return ShiftCell(
                        value: '${widget.instructorsPerDayList[y][x]['firstName']+' '+widget.instructorsPerDayList[y][x]['lastName']} '
                    );
                  }
                  else {
                    return DateCell(
                        value: widget.daysList[i]
                    );
                  }
                })
            ),
          ),
        );
  }
}
