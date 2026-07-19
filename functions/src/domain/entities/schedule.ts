export type ScheduleConfig = {
  kind: "once" | "daily" | "weekly";
  timezone: string;
  runAt?: Date;
  timeOfDay?: string;
  weekdays?: number[];
  slots?: ScheduleSlot[];
};

export type ScheduleSlot = {
  weekday: number;
  timeOfDay: string;
};
