import {networkInterfaces} from "node:os";

/**
 * Die Adressen, unter denen die Runtime im Netz erreichbar ist — zum
 * Anzeigen in der Einrichtung.
 *
 * Bewusst *ermittelt* statt konfiguriert: Ein eingetippter Wert wird bei
 * jedem DHCP-Wechsel still falsch, und niemand merkt es, bis sich jemand
 * nicht mehr verbinden kann. Eine ermittelte Liste ist immer aktuell und
 * spart das fehleranfällige Abtippen.
 *
 * Läuft im Container, sieht also dessen Interfaces. Die Docker-Bridge-
 * Adresse ist für Clients nutzlos, lässt sich hier aber nicht zuverlässig
 * von einer echten LAN-Adresse unterscheiden — die Einrichtung zeigt
 * deshalb alle Kandidaten an, statt zu raten und die richtige zu verbergen.
 */
export function reachableAddresses(port: number): string[] {
  const addresses: string[] = [];
  for (const entries of Object.values(networkInterfaces())) {
    for (const entry of entries ?? []) {
      if (entry.internal || entry.family !== "IPv4") continue;
      addresses.push(`http://${entry.address}:${port}`);
    }
  }
  return addresses;
}
