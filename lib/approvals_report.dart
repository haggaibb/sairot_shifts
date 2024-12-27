import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

class RequestApprovalsTableScreen extends StatefulWidget {
  @override
  _RequestApprovalsTableScreenState createState() =>
      _RequestApprovalsTableScreenState();
}

class _RequestApprovalsTableScreenState
    extends State<RequestApprovalsTableScreen> {
  String _sortField = 'approved_request.give_day'; // Default sort field
  bool _isAscending = false; // Default sort order (descending)

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Enable RTL layout
      child: Scaffold(
        appBar: AppBar(
          title: Text('טבלת אישורי בקשות'),
          actions: [
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: () => _showSortDialog(),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _getSortedQuery(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('לא נמצאו נתונים.'));
            }

            final docs = snapshot.data!.docs;

            return Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortAscending: _isAscending,
                    sortColumnIndex: _getSortColumnIndex(),
                    columns: [
                      DataColumn(
                        label: Text('מספר אישי'),
                      ),
                      DataColumn(
                        label: Text('שם מלא'),
                      ),
                      DataColumn(
                        label: Text('סוג בקשה'),
                      ),
                      DataColumn(
                        label: Text('זמן אישור'),
                      ),
                      DataColumn(
                        label: Text('יום נתינה'),
                      ),
                      DataColumn(
                        label: Text('יום לקיחה'),
                      ),
                      DataColumn(
                        label: Text('מאושר על ידי'),
                      ),
                    ],
                    rows: docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;

                      return DataRow(cells: [
                        DataCell(Text(data['approved_request']['army_id'] ?? '')),
                        DataCell(Text(data['approved_request']['full_name'] ?? '')),
                        DataCell(Text(data['approved_request']['type'] ?? '')),
                        DataCell(Text(_formatTimestamp(data['approval_timestamp']))),
                        DataCell(Text(_formatTimestamp(data['approved_request']['give_day']))),
                        DataCell(Text(_formatTimestamp(data['take_day']))),
                        DataCell(Text(data['approved_by'] ?? '')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Format timestamp for display
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return 'לא זמין';
    return intl.DateFormat('HH:mm:ss dd-MM-yyyy').format(timestamp.toDate());
  }

  // Get sorted query
  Stream<QuerySnapshot> _getSortedQuery() {
    Query query = FirebaseFirestore.instance.collection('request_approvals');
    query = query.orderBy(_sortField, descending: !_isAscending);

    return query.snapshots();
  }

  // Show sort dialog with dropdown for field name
  void _showSortDialog() {
    String selectedSortField = _sortField;
    bool selectedAscending = _isAscending;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text('מיון בקשות'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedSortField,
                      items: [
                        DropdownMenuItem(
                          value: 'approval_timestamp',
                          child: Text('זמן אישור'),
                        ),
                        DropdownMenuItem(
                          value: 'approved_request.army_id',
                          child: Text('מספר אישי'),
                        ),
                        DropdownMenuItem(
                          value: 'approved_request.full_name',
                          child: Text('שם מלא'),
                        ),
                        DropdownMenuItem(
                          value: 'approved_request.give_day',
                          child: Text('יום נתינה'),
                        ),
                        DropdownMenuItem(
                          value: 'take_day',
                          child: Text('יום לקיחה'),
                        ),
                        DropdownMenuItem(
                          value: 'approved_by',
                          child: Text('מאושר על ידי'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSortField = value!;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: Text('סדר עולה'),
                      value: selectedAscending,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAscending = value;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sortField = selectedSortField;
                        _isAscending = selectedAscending;
                      });
                      Navigator.pop(context); // Close dialog
                    },
                    child: Text('בצע'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Determine which column index corresponds to the sort field
  int? _getSortColumnIndex() {
    switch (_sortField) {
      case 'approval_timestamp':
        return 3;
      case 'approved_request.army_id':
        return 0;
      case 'approved_request.full_name':
        return 1;
      case 'approved_request.give_day':
        return 4;
      case 'take_day':
        return 5;
      case 'approved_by':
        return 6;
      default:
        return null;
    }
  }
}