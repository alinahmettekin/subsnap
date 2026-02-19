import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showCustomDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required ValueChanged<DateTime> onDateChanged,
  DateTime? minDate,
  DateTime? maxDate,
}) {
  // Default minimum date: Jan 1, 2024
  final effectiveMinDate = minDate ?? DateTime(2024);

  // Default maximum date: 10 years from now
  final effectiveMaxDate = maxDate ?? DateTime.now().add(const Duration(days: 365 * 10));

  return showCupertinoModalPopup(
    context: context,
    builder: (context) => Container(
      height: 280,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bitti', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              initialDateTime: initialDate,
              mode: CupertinoDatePickerMode.date,
              dateOrder: DatePickerDateOrder.dmy,
              use24hFormat: true,
              minimumDate: effectiveMinDate,
              maximumDate: effectiveMaxDate,
              onDateTimeChanged: onDateChanged,
            ),
          ),
        ],
      ),
    ),
  );
}
