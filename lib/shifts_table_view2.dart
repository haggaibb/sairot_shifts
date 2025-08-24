import 'package:flutter/material.dart';
import 'shifts_cells.dart';

class ShiftsTableView2 extends StatefulWidget {
  final List instructorsPerDayList;
  final List daysList;
  final int maxInstructorsPerDay;

  const ShiftsTableView2(
      {Key? key, required this.instructorsPerDayList, required this.daysList, required this.maxInstructorsPerDay})
      : super(key: key);

  @override
  _ShiftsTableView2State createState() => _ShiftsTableView2State();
}

class _ShiftsTableView2State extends State<ShiftsTableView2> {


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
    int numberOfInstructorsPerDay = widget.maxInstructorsPerDay;
     return
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: widget.instructorsPerDayList.length * cellWidth,
            child: DataTable(
              columns:  List.generate(widget.instructorsPerDayList.length, (dayIndex) {
                print('build day col '+widget.daysList[dayIndex]);
                return  DataColumn(
                  label: Expanded(
                    child: Text(
                      widget.daysList[dayIndex],
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                );
              }),
              rows : List.generate(numberOfInstructorsPerDay, (rowIndex) {
                widget.instructorsPerDayList[rowIndex].sort((a, b) => a['firstName'].toString().compareTo(b['firstName'].toString()));
                print(widget.instructorsPerDayList);
                return DataRow(
                    cells: List.generate(widget.instructorsPerDayList[rowIndex].length, (instructorIndex) {
                      return DataCell(Text('${widget.instructorsPerDayList[rowIndex][instructorIndex]['firstName']+' '+widget.instructorsPerDayList[rowIndex][instructorIndex]['lastName']} '));
                    }),
                );
              }
              )
            ),
          ),
        );
  }
}
