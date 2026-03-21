import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InlineBirthdayPicker extends StatefulWidget {
  const InlineBirthdayPicker({
    super.key,
    required this.initialDate,
    required this.onChanged,
    this.minYear = 1960,
  });

  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;
  final int minYear;

  @override
  State<InlineBirthdayPicker> createState() => _InlineBirthdayPickerState();
}

class _InlineBirthdayPickerState extends State<InlineBirthdayPicker> {
  late int _year;
  late int _month;
  late int _day;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  int get _maxYear => DateTime.now().year - 18;
  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  @override
  void initState() {
    super.initState();
    final safeDate = _sanitize(widget.initialDate);
    _year = safeDate.year;
    _month = safeDate.month;
    _day = safeDate.day;
    _yearController =
        FixedExtentScrollController(initialItem: _year - widget.minYear);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void didUpdateWidget(covariant InlineBirthdayPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDate != widget.initialDate) {
      final safeDate = _sanitize(widget.initialDate);
      if (safeDate.year != _year ||
          safeDate.month != _month ||
          safeDate.day != _day) {
        _year = safeDate.year;
        _month = safeDate.month;
        _day = safeDate.day;
        _yearController.jumpToItem(_year - widget.minYear);
        _monthController.jumpToItem(_month - 1);
        _dayController.jumpToItem(_day - 1);
      }
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppTheme.surfaceHighest,
      ),
      child: Row(
        children: [
          Expanded(
            child: _PickerColumn(
              label: '年份',
              controller: _yearController,
              itemCount: _maxYear - widget.minYear + 1,
              itemBuilder: (index) => '${widget.minYear + index}',
              onSelectedItemChanged: (index) {
                setState(() {
                  _year = widget.minYear + index;
                  _day = math.min(_day, _daysInMonth);
                  _dayController.jumpToItem(_day - 1);
                });
                _notify();
              },
            ),
          ),
          Expanded(
            child: _PickerColumn(
              label: '月份',
              controller: _monthController,
              itemCount: 12,
              itemBuilder: (index) => '${index + 1}月',
              onSelectedItemChanged: (index) {
                setState(() {
                  _month = index + 1;
                  _day = math.min(_day, _daysInMonth);
                  _dayController.jumpToItem(_day - 1);
                });
                _notify();
              },
            ),
          ),
          Expanded(
            child: _PickerColumn(
              label: '日期',
              controller: _dayController,
              itemCount: _daysInMonth,
              itemBuilder: (index) => '${index + 1}日',
              onSelectedItemChanged: (index) {
                setState(() => _day = index + 1);
                _notify();
              },
            ),
          ),
        ],
      ),
    );
  }

  DateTime _sanitize(DateTime input) {
    final cappedYear = input.year.clamp(widget.minYear, _maxYear);
    final cappedMonth = input.month.clamp(1, 12);
    final maxDay = DateUtils.getDaysInMonth(cappedYear, cappedMonth);
    final cappedDay = input.day.clamp(1, maxDay);
    return DateTime(cappedYear, cappedMonth, cappedDay);
  }

  void _notify() {
    widget.onChanged(DateTime(_year, _month, _day));
  }
}

class _PickerColumn extends StatelessWidget {
  const _PickerColumn({
    required this.label,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onSelectedItemChanged,
  });

  final String label;
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) itemBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              CupertinoPicker.builder(
                scrollController: controller,
                itemExtent: 42,
                selectionOverlay: const SizedBox.shrink(),
                onSelectedItemChanged: onSelectedItemChanged,
                childCount: itemCount,
                itemBuilder: (context, index) {
                  return Center(
                    child: Text(
                      itemBuilder(index),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}
