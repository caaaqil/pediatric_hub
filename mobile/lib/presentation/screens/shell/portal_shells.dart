import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../admin/admin_templates_screen.dart';
import '../admin/admin_users_screen.dart';
import '../dashboard/main_dashboard_screen.dart';
import '../doctor/patients_screen.dart';
import '../facility/facility_staff_screen.dart';
import '../parent/chatbot_screen.dart';
import '../parent/children_screen.dart';
import '../shared/appointments_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/teleconsult_screen.dart';
import 'role_shell.dart';

/// The four portals. Drawer links mirror the web `DashboardLayout` sidebar
/// exactly — same labels, same icons, same order — and the blue toolbar quick
/// links mirror its sub-navigation strip.

class ParentShell extends StatelessWidget {
  const ParentShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      portalName: 'Parent',
      quickLinks: const <SidebarLink>[
        SidebarLink(
          'Appointments',
          Icons.calendar_month_rounded,
          Routes.bookAppointment,
        ),
        SidebarLink('Health Records', Icons.folder_rounded, Routes.children),
        SidebarLink(
          'Teleconsultation',
          Icons.show_chart_rounded,
          Routes.teleconsult,
        ),
        SidebarLink(
          'AI Health Assistant',
          Icons.smart_toy_rounded,
          Routes.chatbot,
        ),
      ],
      sidebarLinks: const <SidebarLink>[
        SidebarLink(
          'Child Health Records',
          Icons.show_chart_rounded,
          Routes.children,
        ),
        SidebarLink(
          'Book Appointment',
          Icons.calendar_month_rounded,
          Routes.bookAppointment,
        ),
        SidebarLink('Vaccinations', Icons.vaccines_rounded, Routes.vaccines),
        SidebarLink(
          'Message Doctor',
          Icons.mail_outline_rounded,
          Routes.messages,
        ),
        SidebarLink(
          'Tele-Consultation',
          Icons.phone_in_talk_rounded,
          Routes.teleconsult,
        ),
        SidebarLink(
          'Health Education',
          Icons.menu_book_rounded,
          Routes.education,
        ),
        SidebarLink(
          'Emergency Guidance',
          Icons.error_outline_rounded,
          Routes.emergency,
        ),
        SidebarLink('AI Chatbot', Icons.smart_toy_outlined, Routes.chatbot),
        SidebarLink(
          'Payment History',
          Icons.credit_card_rounded,
          Routes.payments,
        ),
      ],
      tabs: const <ShellTab>[
        ShellTab(
          label: 'Dashboard',
          breadcrumb: 'Main Dashboard',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          child: MainDashboardScreen(),
        ),
        ShellTab(
          label: 'Children',
          breadcrumb: 'My Children',
          icon: Icons.child_care_outlined,
          activeIcon: Icons.child_care_rounded,
          child: ChildrenScreen(),
        ),
        ShellTab(
          label: 'Appointments',
          breadcrumb: 'Appointments',
          icon: Icons.event_note_outlined,
          activeIcon: Icons.event_note_rounded,
          child: AppointmentsScreen(),
        ),
        ShellTab(
          label: 'PediaBot',
          breadcrumb: 'AI Chatbot',
          icon: Icons.smart_toy_outlined,
          activeIcon: Icons.smart_toy_rounded,
          child: ChatbotScreen(),
        ),
        ShellTab(
          label: 'Profile',
          breadcrumb: 'Account',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          child: ProfileScreen(),
        ),
      ],
    );
  }
}

class DoctorShell extends StatelessWidget {
  const DoctorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      portalName: 'Doctor',
      quickLinks: const <SidebarLink>[
        SidebarLink(
          'Appointments',
          Icons.calendar_month_rounded,
          Routes.patients,
        ),
        SidebarLink('Health Records', Icons.folder_rounded, Routes.patients),
        SidebarLink(
          'Teleconsultation',
          Icons.show_chart_rounded,
          Routes.teleconsult,
        ),
      ],
      sidebarLinks: const <SidebarLink>[
        SidebarLink(
          'Clinical Schedule',
          Icons.calendar_month_rounded,
          Routes.patients,
        ),
        SidebarLink(
          'Patient Records',
          Icons.monitor_heart_rounded,
          Routes.patients,
        ),
        SidebarLink('Messenger', Icons.mail_outline_rounded, Routes.messages),
        SidebarLink(
          'Teleconsultation',
          Icons.medical_services_rounded,
          Routes.teleconsult,
        ),
        SidebarLink(
          'Health Education',
          Icons.menu_book_rounded,
          Routes.education,
        ),
      ],
      tabs: const <ShellTab>[
        ShellTab(
          label: 'Dashboard',
          breadcrumb: 'Main Dashboard',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          child: MainDashboardScreen(),
        ),
        ShellTab(
          label: 'Schedule',
          breadcrumb: 'Clinical Schedule',
          icon: Icons.event_note_outlined,
          activeIcon: Icons.event_note_rounded,
          child: AppointmentsScreen(),
        ),
        ShellTab(
          label: 'Patients',
          breadcrumb: 'Patient Records',
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups_rounded,
          child: PatientsScreen(),
        ),
        ShellTab(
          label: 'Teleconsult',
          breadcrumb: 'Teleconsultation',
          icon: Icons.videocam_outlined,
          activeIcon: Icons.videocam_rounded,
          child: TeleconsultScreen(showAppBar: false),
        ),
        ShellTab(
          label: 'Profile',
          breadcrumb: 'Account',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          child: ProfileScreen(),
        ),
      ],
    );
  }
}

class FacilityShell extends StatelessWidget {
  const FacilityShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      portalName: 'Facility',
      quickLinks: const <SidebarLink>[
        SidebarLink(
          'Appointments',
          Icons.calendar_month_rounded,
          Routes.facilityStaff,
        ),
        SidebarLink(
          'Services',
          Icons.medical_information_rounded,
          Routes.facilityServices,
        ),
      ],
      sidebarLinks: const <SidebarLink>[
        SidebarLink(
          'Facility Admin',
          Icons.layers_rounded,
          Routes.facilityAdmin,
        ),
        SidebarLink(
          'Health Services',
          Icons.medical_information_rounded,
          Routes.facilityServices,
        ),
        SidebarLink(
          'My Clinical Staff',
          Icons.medical_services_rounded,
          Routes.facilityStaff,
        ),
      ],
      tabs: const <ShellTab>[
        ShellTab(
          label: 'Dashboard',
          breadcrumb: 'Main Dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          child: MainDashboardScreen(),
        ),
        ShellTab(
          label: 'Staff',
          breadcrumb: 'My Clinical Staff',
          icon: Icons.medical_services_outlined,
          activeIcon: Icons.medical_services_rounded,
          child: FacilityStaffScreen(),
        ),
        ShellTab(
          label: 'Appointments',
          breadcrumb: 'Appointments',
          icon: Icons.event_note_outlined,
          activeIcon: Icons.event_note_rounded,
          child: AppointmentsScreen(),
        ),
        ShellTab(
          label: 'Profile',
          breadcrumb: 'Account',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          child: ProfileScreen(),
        ),
      ],
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      portalName: 'Admin',
      quickLinks: const <SidebarLink>[
        SidebarLink(
          'Admin Control Center',
          Icons.dashboard_rounded,
          Routes.adminAudits,
        ),
      ],
      sidebarLinks: const <SidebarLink>[
        SidebarLink('Identity Access', Icons.groups_rounded, Routes.adminUsers),
        SidebarLink(
          'Doctor Registry',
          Icons.medical_services_rounded,
          Routes.adminDoctors,
        ),
        SidebarLink(
          'Facility Registry',
          Icons.layers_rounded,
          Routes.adminFacilities,
        ),
        SidebarLink(
          'Payment History',
          Icons.credit_card_rounded,
          Routes.adminPayments,
        ),
        SidebarLink(
          'Chatbot Templates',
          Icons.smart_toy_outlined,
          Routes.adminTemplates,
        ),
        SidebarLink(
          'System Audit',
          Icons.gpp_maybe_rounded,
          Routes.adminAudits,
        ),
      ],
      tabs: const <ShellTab>[
        ShellTab(
          label: 'Dashboard',
          breadcrumb: 'Main Dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          child: MainDashboardScreen(),
        ),
        ShellTab(
          label: 'Users',
          breadcrumb: 'Users Management',
          icon: Icons.manage_accounts_outlined,
          activeIcon: Icons.manage_accounts_rounded,
          child: AdminUsersScreen(),
        ),
        ShellTab(
          label: 'PediaBot',
          breadcrumb: 'Chatbot Templates',
          icon: Icons.smart_toy_outlined,
          activeIcon: Icons.smart_toy_rounded,
          child: AdminTemplatesScreen(),
        ),
        ShellTab(
          label: 'Profile',
          breadcrumb: 'Account',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          child: ProfileScreen(),
        ),
      ],
    );
  }
}
