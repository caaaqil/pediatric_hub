import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// `enum Role` — backend/prisma/schema.prisma
enum UserRole {
  parent('PARENT', 'Parent'),
  doctor('DOCTOR', 'Doctor'),
  facility('FACILITY', 'Facility'),
  admin('ADMIN', 'Administrator');

  const UserRole(this.wire, this.label);

  final String wire;
  final String label;

  static UserRole? tryParse(dynamic value) {
    if (value == null) return null;
    final String raw = value.toString().toUpperCase();
    for (final UserRole role in UserRole.values) {
      if (role.wire == raw) return role;
    }
    return null;
  }
}

/// `enum AppointmentStatus` — PENDING | CONFIRMED | RESCHEDULED | CANCELLED |
/// COMPLETED | NO_SHOW
enum AppointmentStatus {
  pending('PENDING', 'Pending'),
  confirmed('CONFIRMED', 'Confirmed'),
  rescheduled('RESCHEDULED', 'Rescheduled'),
  cancelled('CANCELLED', 'Cancelled'),
  completed('COMPLETED', 'Completed'),
  noShow('NO_SHOW', 'No show');

  const AppointmentStatus(this.wire, this.label);

  final String wire;
  final String label;

  static AppointmentStatus fromJson(dynamic value) {
    final String raw = value?.toString().toUpperCase() ?? '';
    for (final AppointmentStatus status in AppointmentStatus.values) {
      if (status.wire == raw) return status;
    }
    return AppointmentStatus.pending;
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.primary600;
      case AppointmentStatus.rescheduled:
        return AppColors.violet;
      case AppointmentStatus.cancelled:
        return AppColors.danger;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.noShow:
        return AppColors.lightTextMuted;
    }
  }

  bool get isOpen =>
      this == AppointmentStatus.pending ||
      this == AppointmentStatus.confirmed ||
      this == AppointmentStatus.rescheduled;
}

/// `enum VaccineStatus` — UPCOMING | DUE | COMPLETED | MISSED.
///
/// Transitions are driven by `backend/src/cron/vaccineCron.js`: UPCOMING flips
/// to DUE inside a 7-day window, and UPCOMING/DUE flips to MISSED once the
/// scheduled date is more than 7 days in the past.
enum VaccineStatus {
  upcoming('UPCOMING', 'Upcoming'),
  due('DUE', 'Due'),
  completed('COMPLETED', 'Completed'),
  missed('MISSED', 'Missed');

  const VaccineStatus(this.wire, this.label);

  final String wire;
  final String label;

  static VaccineStatus fromJson(dynamic value) {
    final String raw = value?.toString().toUpperCase() ?? '';
    for (final VaccineStatus status in VaccineStatus.values) {
      if (status.wire == raw) return status;
    }
    return VaccineStatus.upcoming;
  }

  Color get color {
    switch (this) {
      case VaccineStatus.upcoming:
        return AppColors.primary600;
      case VaccineStatus.due:
        return AppColors.warning;
      case VaccineStatus.completed:
        return AppColors.success;
      case VaccineStatus.missed:
        return AppColors.danger;
    }
  }

  IconData get icon {
    switch (this) {
      case VaccineStatus.upcoming:
        return Icons.schedule_rounded;
      case VaccineStatus.due:
        return Icons.notifications_active_rounded;
      case VaccineStatus.completed:
        return Icons.check_circle_rounded;
      case VaccineStatus.missed:
        return Icons.error_rounded;
    }
  }
}

/// `enum PaymentStatus` — PENDING | PAID | FAILED
enum PaymentStatus {
  pending('PENDING', 'Pending'),
  paid('PAID', 'Paid'),
  failed('FAILED', 'Failed');

  const PaymentStatus(this.wire, this.label);

  final String wire;
  final String label;

  static PaymentStatus fromJson(dynamic value) {
    final String raw = value?.toString().toUpperCase() ?? '';
    for (final PaymentStatus status in PaymentStatus.values) {
      if (status.wire == raw) return status;
    }
    return PaymentStatus.pending;
  }

  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.failed:
        return AppColors.danger;
    }
  }
}

/// `enum Relationship` — used by the ParentInfo (guardian) records.
enum Relationship {
  father('FATHER', 'Father'),
  mother('MOTHER', 'Mother'),
  uncle('UNCLE', 'Uncle'),
  aunt('AUNT', 'Aunt'),
  maternalUncle('MATERNAL_UNCLE', 'Maternal uncle'),
  maternalAunt('MATERNAL_AUNT', 'Maternal aunt'),
  guardian('GUARDIAN', 'Guardian'),
  other('OTHER', 'Other');

  const Relationship(this.wire, this.label);

  final String wire;
  final String label;

  static Relationship fromJson(dynamic value) {
    final String raw = value?.toString().toUpperCase() ?? '';
    for (final Relationship rel in Relationship.values) {
      if (rel.wire == raw) return rel;
    }
    return Relationship.other;
  }
}

/// `enum FacilityType` — HOSPITAL | CLINIC
enum FacilityType {
  hospital('HOSPITAL', 'Hospital'),
  clinic('CLINIC', 'Clinic');

  const FacilityType(this.wire, this.label);

  final String wire;
  final String label;

  static FacilityType fromJson(dynamic value) {
    final String raw = value?.toString().toUpperCase() ?? '';
    for (final FacilityType type in FacilityType.values) {
      if (type.wire == raw) return type;
    }
    return FacilityType.clinic;
  }
}
