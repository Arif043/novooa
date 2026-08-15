import 'firebase_functions_assistant_datasource.dart';

class FirebaseFunctionsTaskBuilderAssistantDatasource
    extends FirebaseFunctionsAssistantDatasource {
  FirebaseFunctionsTaskBuilderAssistantDatasource({
    super.functions,
    super.timeout = const Duration(seconds: 90),
  }) : super(functionName: 'askTaskBuilderAssistant');
}
