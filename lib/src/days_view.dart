part of '../clean_nepali_calendar.dart';

typedef HeaderDayBuilder = Widget Function(String headerName, int dayNumber);

const double _kDayPickerRowHeight = 50.0;

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const columnCount = 7;
    final tileWidth = constraints.crossAxisExtent / columnCount;
    final tileHeight = math.min(_kDayPickerRowHeight,
        constraints.viewportMainAxisExtent / (_kMaxDayPickerRowCount + 1));
    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _kDayPickerGridDelegate = _DayPickerGridDelegate();

class _DaysView extends StatelessWidget {
  _DaysView({
    super.key,
    required this.selectedDate,
    required this.currentDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    required this.displayedMonth,
    required this.language,
    required this.calendarStyle,
    required this.headerStyle,
    this.selectableDayPredicate,
    this.dragStartBehavior = DragStartBehavior.start,
    this.headerDayType = HeaderDayType.initial,
    this.headerDayBuilder,
    this.dateCellBuilder,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(selectedDate.isAfter(firstDate));

  final NepaliDateTime selectedDate;

  final NepaliDateTime currentDate;

  final ValueChanged<NepaliDateTime> onChanged;

  final NepaliDateTime firstDate;

  final NepaliDateTime lastDate;

  final NepaliDateTime displayedMonth;

  final SelectableDayPredicate? selectableDayPredicate;

  final DragStartBehavior dragStartBehavior;

  final Language language;
  final CalendarStyle calendarStyle;
  final HeaderStyle headerStyle;
  final HeaderDayType headerDayType;
  final HeaderDayBuilder? headerDayBuilder;
  final DateCellBuilder? dateCellBuilder;

  List<Widget> _getDayHeaders(Language language, TextStyle? headerStyle,
      HeaderDayType headerDayType, HeaderDayBuilder? builder) {
    List<String> headers;
    switch (headerDayType) {
      case HeaderDayType.fullName:
        {
          headers = (language == Language.english)
              ? dayHeaderFullNameEnglish
              : dayHeaderFullNameNepali;
          break;
        }
      case HeaderDayType.halfName:
        {
          headers = (language == Language.english)
              ? dayHeaderHalfNameEnglish
              : dayHeaderHalfNameNepali;

          break;
        }
      case HeaderDayType.initial:
        {
          headers = (language == Language.english)
              ? dayHeaderLetterEnglish
              : dayHeaderLetterNepali;

          break;
        }
    }
    return headers
        .asMap()
        .entries
        .map(
          (label) => ExcludeSemantics(
            child: builder != null
                ? builder(label.value, label.key)
                : Center(
                    child: Text(
                      label.value,
                      style: headerStyle?.copyWith(
                        color: label.key == 6
                            ? calendarStyle.weekEndTextColor
                            : headerStyle.color,
                      ),
                    ),
                  ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final daysInMonth = displayedMonth.totalDays;
    final firstDayOffset = displayedMonth.weekday - 1;
    final labels = <Widget>[];
    if (calendarStyle.renderDaysOfWeek) {
      labels.addAll(
        _getDayHeaders(language, themeData.textTheme.labelMedium, headerDayType,
            headerDayBuilder),
      );
    }

    //this weekNumber is to determine the weekend, saturday.
    int weekNumber = 0;
    for (var i = 0; true; i += 1) {
      if (weekNumber > 6) weekNumber = 0;
      // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
      // a leap year.
      final day = i - firstDayOffset + 1;
      if (day > daysInMonth) break;
      if (day < 1) {
        labels.add(Container());
      } else {
        final dayToBuild = NepaliDateTime(year, month, day);
        final disabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null &&
                !selectableDayPredicate!(dayToBuild));

        final isSelectedDay = selectedDate.year == year &&
            selectedDate.month == month &&
            selectedDate.day == day;
        final bool isCurrentDay = currentDate.year == year &&
            currentDate.month == month &&
            currentDate.day == day;
        final semanticLabel =
            '${formattedMonth(month, Language.english)} $day, $year';
        final text =
            '${language == Language.english ? day : NepaliUnicode.convert('$day')}';

        Widget dayWidget = _DayWidget(
          isDisabled: disabled,
          text: text,
          label: semanticLabel,
          isToday: isCurrentDay,
          isSelected: isSelectedDay,
          calendarStyle: calendarStyle,
          day: dayToBuild,
          isWeekend: weekNumber == 6,
          onTap: () {
            onChanged(dayToBuild);
          },
          builder: dateCellBuilder,
        );

        if (!disabled) {
          dayWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              onChanged(dayToBuild);
            },
            dragStartBehavior: dragStartBehavior,
            child: dayWidget,
          );
        }
        labels.add(dayWidget);
      }

      weekNumber += 1;
    }

    return Column(
      children: <Widget>[
        Flexible(
          child: GridView.custom(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _kDayPickerGridDelegate,
            childrenDelegate:
                SliverChildListDelegate(labels, addRepaintBoundaries: false),
          ),
        ),
      ],
    );
  }
}

final List<String> dayHeaderFullNameEnglish = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday"
];
final List<String> dayHeaderFullNameNepali = [
  "आइतबार",
  "सोमबार",
  "मङ्गलबार",
  "बुधबार",
  "बिहीबार",
  "शुक्रबार",
  "शनिबार"
];
final List<String> dayHeaderHalfNameEnglish = [
  "Sun",
  "Mon",
  "Tues",
  "Wed",
  "Thu",
  "Fri",
  "Sat"
];
final List<String> dayHeaderHalfNameNepali = [
  "आइत",
  "सोम",
  "मङ्गल",
  "बुध",
  "बिही",
  "शुक्र",
  "शनि"
];

final List<String> dayHeaderLetterEnglish = [
  'Su',
  'Mo',
  'Tu',
  'We',
  'TH',
  'Fi',
  'Sa',
];

final List<String> dayHeaderLetterNepali = [
  'आ',
  'सो',
  'मं',
  'बु',
  'वि',
  'शु',
  'श',
];
