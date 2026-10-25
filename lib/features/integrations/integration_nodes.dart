import 'google_drive/google_drive_plugin.dart';
import 'shopware/shopware_plugin.dart';

/// Meldet die Bausteine aller Plugins an. Ein neues Plugin wird hier eingetragen.
void registerIntegrationNodes() {
  registerShopwarePlugin();
  registerGoogleDrivePlugin();
}
