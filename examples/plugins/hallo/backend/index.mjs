// Beispiel-Plugin: ein Baustein und ein Trigger. Siehe docs/features/plugins.md.
//
// Baustein: `settings` sind die Werte der Felder aus plugin.json (Template-Ausdrücke sind schon aufgelöst),
// `panel` die Werte der Einstellungs-Panels. Rückgabe: Objekt aus den deklarierten Ausgaben.
// Trigger: `state` ist das, was der Trigger beim letzten Aufruf zurückgegeben hat.
export default {
  primitives: {
    greet: ({settings, panel}) => {
      const text = `${panel.greeting ?? "Hallo"}, ${settings.name}!`;
      return {value: text, length: text.length};
    },
  },
  triggers: {
    tick: ({state}) => {
      const count = (typeof state === "number" ? state : 0) + 1;
      return {events: [{context: `Tick ${count}`, data: {count}}], state: count};
    },
  },
};
