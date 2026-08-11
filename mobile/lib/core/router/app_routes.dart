/// Every route path in one place so links never drift.
class Routes {
  const Routes._();

  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  // Parent
  static const String parentHome = '/parent';
  static const String children = '/parent/children';
  static const String childNew = '/parent/children/new';
  static String childDetail(String id) => '/parent/children/$id';
  static String childEdit(String id) => '/parent/children/$id/edit';
  static String childVaccines(String id) => '/parent/children/$id/vaccines';
  static String childRecords(String id) => '/parent/children/$id/records';
  static String childGrowth(String id) => '/parent/children/$id/growth';
  static const String vaccines = '/parent/vaccines';
  static const String doctors = '/parent/doctors';
  static String doctorDetail(String id) => '/parent/doctors/$id';
  static const String bookAppointment = '/parent/book';
  static const String chatbot = '/parent/chatbot';
  static const String payments = '/parent/payments';

  // Doctor
  static const String doctorHome = '/doctor';
  static const String patients = '/doctor/patients';
  static String patientDetail(String id) => '/doctor/patients/$id';

  // Facility
  static const String facilityHome = '/facility';
  static const String facilityStaff = '/facility/staff';
  static const String facilityServices = '/facility/services';

  /// Mirrors the web `/facility/admin` page.
  static const String facilityAdmin = '/facility/admin';

  // Admin
  static const String adminHome = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminTemplates = '/admin/templates';
  static const String adminAudits = '/admin/audits';
  static const String adminDoctors = '/admin/doctors';
  static const String adminFacilities = '/admin/facilities';
  static const String adminPayments = '/admin/payments';

  // Shared across roles — reachable from any portal
  static String appointmentDetail(String id) => '/appointments/$id';
  static const String teleconsult = '/teleconsult';

  /// The live video call. The appointment id doubles as the Socket.IO room.
  static String videoCall(String appointmentId) => '/call/$appointmentId';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String education = '/education';
  static const String emergency = '/emergency';

  /// Role home for the signed-in user, used by the auth redirect.
  static String homeForRole(String role) {
    switch (role) {
      case 'DOCTOR':
        return doctorHome;
      case 'FACILITY':
        return facilityHome;
      case 'ADMIN':
        return adminHome;
      case 'PARENT':
      default:
        return parentHome;
    }
  }
}
