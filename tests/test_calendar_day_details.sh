#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DOCK="$ROOT_DIR/quickshell/a16een/ui/Dock.qml"
DETAILS="$ROOT_DIR/quickshell/a16een/ui/CalendarDayDetails.qml"
DATA="$ROOT_DIR/quickshell/a16een/ui/CalendarCommemorations.qml"

grep -Fq 'property bool calendarDetailsOpen: false' "$DOCK"
grep -Fq 'property int selectedCalendarDay: 0' "$DOCK"
grep -Fq 'navbarClockPanel.selectedCalendarDay = dateCellModel.modelData.day' "$DOCK"
grep -Fq 'navbarClockPanel.calendarDetailsOpen = true' "$DOCK"
grep -Fq 'CalendarDayDetails {' "$DOCK"
grep -Fq 'CalendarCommemorations {' "$DETAILS"
grep -Fq 'Behavior on opacity' "$DETAILS"
grep -Fq 'Behavior on scale' "$DETAILS"
grep -Fq 'signal hoveringChanged(bool hovering)' "$DETAILS"
grep -Fq '"12": ({' "$DATA"
grep -Fq '"16": ({' "$DATA"
grep -Fq '"21": ({' "$DATA"
grep -Fq 'ቅዱስ ሚካኤል' "$DATA"
grep -Fq 'ኪዳነ ምሕረት' "$DATA"
grep -Fq 'ቅድስት ማርያም' "$DATA"
grep -Fq 'ራእይ 12፥7' "$DATA"
grep -Fq 'ሉቃስ 1፥50' "$DATA"
grep -Fq 'ሉቃስ 1፥48' "$DATA"
grep -Fq 'navbarClockPanel.calendarDetailsHovering' "$DOCK"

printf 'Calendar day-detail foundation checks passed.\n'
