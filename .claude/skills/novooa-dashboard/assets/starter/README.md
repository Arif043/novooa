# __DASHBOARD_TITLE__ – novooa-Dashboard

Kundenspezifisches Dashboard für eine novooa-Runtime. Erzeugt mit dem Skill
`novooa-dashboard` (Version siehe `.novooa-dashboard`).

```bash
flutter pub get
# Desktop/Mobil: Adresse der Runtime wird beim ersten Start abgefragt.
flutter run -d macos
# Web: Adresse der Runtime fest einbauen; die Runtime braucht dafür
# LOCAL_RUNTIME_ALLOWED_ORIGINS=<Herkunft dieses Dashboards>.
flutter run -d chrome --web-port=5060 \
  --dart-define=WORKSPACE_API_URL=http://127.0.0.1:8090
```

Welche Aufgaben erscheinen, steht in `lib/app/dashboard_config.dart`.
