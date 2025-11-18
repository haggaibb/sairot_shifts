import 'package:flutter/material.dart';
import 'utils.dart';

/// PlutoGrid Example
//
/// For more examples, go to the demo web link on the github below.
class InstructorsConfigPage extends StatefulWidget {
  final List<Instructor> allInstructorsList;
  const InstructorsConfigPage(this.allInstructorsList, {super.key});

  @override
  State<InstructorsConfigPage> createState() => _InstructorsConfigPageState();
}

class _InstructorsConfigPageState extends State<InstructorsConfigPage> {
  late List<bool> selected;
  late List<TextEditingController> _textEditingControllers;
  late bool sort;

  onSortColum(int columnIndex, bool ascending) {
    if (columnIndex == 1) {
      if (ascending) {
        widget.allInstructorsList.sort((a, b) => a.firstName.compareTo(b.firstName));
      } else {
        widget.allInstructorsList.sort((a, b) => b.firstName.compareTo(a.firstName));
      }
    }
  }

  @override
  void initState()  {
    super.initState();
    selected = List<bool>.generate(widget.allInstructorsList.length, (int index) => false);
    _textEditingControllers = List.generate(widget.allInstructorsList.length, (index)  {
      TextEditingController tmp = TextEditingController();
      tmp.text = widget.allInstructorsList[index].maxDays!=null?widget.allInstructorsList[index].maxDays.toString():'17';
      return tmp;
    });
    sort=true;
    onSortColum(1,true);
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      sortAscending: sort,
      sortColumnIndex: 1,
      columns: <DataColumn>[
        DataColumn(
          label: Text(''),
        ),
        DataColumn(
          numeric: false,
          label: Text(' שם המדריך'),
            onSort: (columnIndex, ascending) {
            print(columnIndex);
            print(ascending);
            setState(() {
                sort = !sort;
              });
              onSortColum(columnIndex, ascending);
            },
        ),
        DataColumn(
          label: Text('ת.ז.'),
        ),
        DataColumn(
          numeric: true,
          label: Text('מקסימום ימי מילואים'),
        ),
      ],
      rows: List<DataRow>.generate(
        widget.allInstructorsList.length,
            (int index) => DataRow(
          cells: <DataCell>[
            DataCell(Text((index+1).toString())),
            DataCell(Text(widget.allInstructorsList[index].firstName+' '+widget.allInstructorsList[index].lastName)),
            DataCell(Text(widget.allInstructorsList[index].armyId)),
            DataCell(TextFormField(
              keyboardType: TextInputType.number,
              controller: _textEditingControllers[index],
              onTap: () => {},
            ))
          ],
          selected: selected[index],
          onSelectChanged: (bool? value) {
            setState(() {
              selected[index] = value!;
            });
          },
        ),
      ),
    );
  }
}




