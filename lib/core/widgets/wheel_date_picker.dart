import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows an Apple-style wheel date picker in a bottom sheet.
/// Day, month, and year are selected by scrolling wheels.
///
/// Returns the selected [DateTime] when the user confirms, or `null` if cancelled.
Future<DateTime?> showWheelDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  DateTime picked = initialDate;

  // Clamp initial to range
  if (picked.isBefore(firstDate)) picked = firstDate;
  if (picked.isAfter(lastDate)) picked = lastDate;

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        children: [
          // Header with Cancel / Done
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, picked),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Cupertino wheel picker
          SizedBox(
            height: 250,
            child: CupertinoTheme(
              data: CupertinoTheme.of(context).copyWith(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 21,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (DateTime value) {
                  picked = value;
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
