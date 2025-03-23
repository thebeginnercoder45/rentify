import 'package:flutter/material.dart';

class DateRangePicker extends StatefulWidget {
  final Function(DateTime, DateTime) onDateRangeSelected;

  const DateRangePicker({
    Key? key,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date Range',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                value: startDate,
                onTap: () => _selectDate(context, true),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                value: endDate,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text(
              value != null
                  ? '${value.day}/${value.month}/${value.year}'
                  : 'Select Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? DateTime.now()
          : (startDate ?? DateTime.now()).add(Duration(days: 1)),
      firstDate: isStartDate ? DateTime.now() : (startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = startDate!.add(Duration(hours: 1));
          }
        } else {
          endDate = picked;
        }
      });

      if (startDate != null && endDate != null) {
        widget.onDateRangeSelected(startDate!, endDate!);
      }
    }
  }
}
