import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows an Apple-style wheel date **range** picker in a bottom sheet.
/// User picks "Başlangıç" or "Bitiş", then selects the date with the wheel.
/// No navigation away — everything happens in one sheet on top of the current page.
///
/// Returns the selected [DateTimeRange] when the user confirms, or `null` if cancelled.
Future<DateTimeRange?> showWheelDateRangePicker(
  BuildContext context, {
  required DateTime initialStart,
  required DateTime initialEnd,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  DateTime start = initialStart.isBefore(firstDate) ? firstDate : initialStart;
  DateTime end = initialEnd.isAfter(lastDate) ? lastDate : initialEnd;
  if (end.isBefore(start)) end = start;
  if (start.isAfter(end)) start = end;

  return showModalBottomSheet<DateTimeRange>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _WheelDateRangeSheet(
      initialStart: start,
      initialEnd: end,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _WheelDateRangeSheet extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;

  const _WheelDateRangeSheet({
    required this.initialStart,
    required this.initialEnd,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_WheelDateRangeSheet> createState() => _WheelDateRangeSheetState();
}

class _WheelDateRangeSheetState extends State<_WheelDateRangeSheet> {
  late DateTime _start;
  late DateTime _end;
  late bool _isEditingStart;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    if (_end.isBefore(_start)) _end = _start;
    _isEditingStart = true;
  }

  DateTime get _currentEditing => _isEditingStart ? _start : _end;
  DateTime get _minForPicker => _isEditingStart ? widget.firstDate : _start;
  DateTime get _maxForPicker => _isEditingStart ? _end : widget.lastDate;

  void _onDateChanged(DateTime value) {
    setState(() {
      if (_isEditingStart) {
        _start = value;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = value;
        if (_start.isAfter(_end)) _start = _end;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                Text(
                  'Tarih aralığı seçin',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, DateTimeRange(start: _start, end: _end)),
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Başlangıç / Bitiş toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _RangeTab(
                    label: 'Başlangıç',
                    date: _start,
                    selected: _isEditingStart,
                    onTap: () => setState(() => _isEditingStart = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RangeTab(
                    label: 'Bitiş',
                    date: _end,
                    selected: !_isEditingStart,
                    onTap: () => setState(() => _isEditingStart = false),
                  ),
                ),
              ],
            ),
          ),
          // Wheel picker for current selection
          SizedBox(
            height: 220,
            child: CupertinoTheme(
              data: CupertinoTheme.of(context).copyWith(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _currentEditing,
                minimumDate: _minForPicker,
                maximumDate: _maxForPicker,
                onDateTimeChanged: _onDateChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeTab extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  const _RangeTab({
    required this.label,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? (theme.colorScheme.primaryContainer)
          : (theme.cardTheme.color ?? theme.cardColor),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}.${date.month}.${date.year}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
