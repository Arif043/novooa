import 'package:web/web.dart' as web;

import 'browser_name_from_user_agent.dart';

String? currentBrowserName() =>
    browserNameFromUserAgent(web.window.navigator.userAgent);
