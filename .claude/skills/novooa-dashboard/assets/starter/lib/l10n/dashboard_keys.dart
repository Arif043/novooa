/// Übersetzungsschlüssel des Dashboards (`assets/translations/*.json`).
/// Von Hand gepflegt statt generiert, damit die Vorlage ohne Codegen läuft.
class DashboardKeys {
  const DashboardKeys._();

  static const retry = 'common.retry';
  static const cancel = 'common.cancel';
  static const loadFailed = 'common.load_failed';

  static const connectionTitle = 'connection.title';
  static const connectionAddress = 'connection.address';
  static const connectionAddressHint = 'connection.address_hint';
  static const connectionConnect = 'connection.connect';
  static const connectionConnecting = 'connection.connecting';
  static const connectionUnreachable = 'connection.unreachable';
  static const connectionSetupRequired = 'connection.setup_required';
  static const signInTitle = 'sign_in.title';
  static const signInLoginName = 'sign_in.login_name';
  static const signInPassword = 'sign_in.password';
  static const signInAction = 'sign_in.action';
  static const signInHaveInvitation = 'sign_in.have_invitation';
  static const signInInvitationCode = 'sign_in.invitation_code';
  static const signInInvitationAction = 'sign_in.invitation_action';
  static const signInBack = 'sign_in.back';
  static const signOut = 'sign_in.sign_out';

  static const tasksTitle = 'tasks.title';
  static const tasksEmpty = 'tasks.empty';
  static const tasksStart = 'tasks.start';
  static const tasksContext = 'tasks.context';
  static const tasksContextHint = 'tasks.context_hint';
  static const tasksStarted = 'tasks.started';
  static const tasksStartFailed = 'tasks.start_failed';

  static const runsTitle = 'runs.title';
  static const runsEmpty = 'runs.empty';
  static const runsShowTasks = 'runs.show_tasks';
  static const runsResult = 'runs.result';
  static const runsNoResult = 'runs.no_result';
  static const runsApprove = 'runs.approve';
  static const runsReject = 'runs.reject';
  static const runsReviewFailed = 'runs.review_failed';
  static const runsOpenInOfficialApp = 'runs.open_in_official_app';
  static String runStatus(String status) => 'runs.status.$status';

  static String failure(String kind) => 'failures.$kind';
}
