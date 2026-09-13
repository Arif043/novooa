export type ModelOutputValue =
  | string
  | number
  | boolean
  | ModelOutputValueList
  | ModelOutputValueRecord;

export interface ModelOutputValueList extends ReadonlyArray<ModelOutputValue> {}

export interface ModelOutputValueRecord {
  readonly [key: string]: ModelOutputValue;
}
