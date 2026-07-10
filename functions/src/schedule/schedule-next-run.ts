import {Timestamp} from "firebase-admin/firestore";

export type ScheduleConfig = {
  kind: "once" | "daily" | "weekly";
  timezone: string;
  runAt?: Timestamp;
  timeOfDay?: string;
  weekdays?: number[];
};

export function nextRunAfter(config: ScheduleConfig, now: Date): Date | null {
  if (config.kind === "once") return nextOnce(config, now);
  if (config.kind === "daily") return nextDaily(config, now);
  return nextWeekly(config, now);
}

function nextOnce(config: ScheduleConfig, now: Date): Date | null {
  const runAt = config.runAt?.toDate();
  if (!runAt || runAt <= now) return null;
  return runAt;
}

function nextDaily(config: ScheduleConfig, now: Date): Date | null {
  const time = timeParts(config.timeOfDay);
  if (!time) return null;
  const parts = zonedParts(now, config.timezone);
  const today = dateInZone(parts.year, parts.month, parts.day, time, config.timezone);
  if (today > now) return today;
  return addZoneDays(parts, 1, time, config.timezone);
}

function nextWeekly(config: ScheduleConfig, now: Date): Date | null {
  const time = timeParts(config.timeOfDay);
  if (!time || !config.weekdays?.length) return null;
  const parts = zonedParts(now, config.timezone);
  for (let offset = 0; offset < 8; offset++) {
    const candidate = addZoneDays(parts, offset, time, config.timezone);
    if (candidate > now && config.weekdays.includes(isoWeekday(candidate, config.timezone))) {
      return candidate;
    }
  }
  return null;
}

function addZoneDays(
  parts: ZonedParts,
  days: number,
  time: TimeParts,
  timezone: string,
): Date {
  const date = new Date(Date.UTC(parts.year, parts.month - 1, parts.day + days));
  const next = zonedParts(date, timezone);
  return dateInZone(next.year, next.month, next.day, time, timezone);
}

function dateInZone(
  year: number,
  month: number,
  day: number,
  time: TimeParts,
  timezone: string,
): Date {
  const guess = new Date(Date.UTC(year, month - 1, day, time.hour, time.minute));
  const actual = zonedParts(guess, timezone);
  const wantedUtc = Date.UTC(year, month - 1, day, time.hour, time.minute);
  const actualUtc = Date.UTC(
    actual.year,
    actual.month - 1,
    actual.day,
    actual.hour,
    actual.minute,
  );
  return new Date(guess.getTime() + wantedUtc - actualUtc);
}

function isoWeekday(date: Date, timezone: string): number {
  const parts = zonedParts(date, timezone);
  const day = new Date(Date.UTC(parts.year, parts.month - 1, parts.day)).getUTCDay();
  return day === 0 ? 7 : day;
}

function zonedParts(date: Date, timezone: string): ZonedParts {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const value = (type: string) => Number(parts.find((part) => part.type === type)?.value);
  return {
    year: value("year"),
    month: value("month"),
    day: value("day"),
    hour: value("hour"),
    minute: value("minute"),
  };
}

function timeParts(value?: string): TimeParts | null {
  const match = value?.match(/^(\d{2}):(\d{2})$/);
  if (!match) return null;
  return {hour: Number(match[1]), minute: Number(match[2])};
}

type TimeParts = {hour: number; minute: number};
type ZonedParts = TimeParts & {year: number; month: number; day: number};
