import 'enums.dart';
import 'json_utils.dart';

/// The role-specific profile row attached to a `User`.
///
/// The backend attaches whichever of `ParentProfile` / `DoctorProfile` /
/// `FacilityProfile` matches the role (`auth.service.js` → `loginUser`, and
/// `auth.controller.js` → `getProfile`), so a single shape with optional fields
/// covers all three without guessing.
class UserProfile {
  const UserProfile({
    required this.id,
    this.userId,
    this.firstName,
    this.lastName,
    this.name,
    this.phoneNumber,
    this.address,
    this.licenseNumber,
    this.specialization,
    this.verificationStatus,
    this.facilityId,
    this.facilityType,
    this.isActive,
  });

  final String id;
  final String? userId;

  /// ParentProfile / DoctorProfile
  final String? firstName;
  final String? lastName;

  /// FacilityProfile
  final String? name;

  final String? phoneNumber;
  final String? address;

  /// DoctorProfile
  final String? licenseNumber;
  final String? specialization;
  final String? verificationStatus;
  final String? facilityId;

  /// FacilityProfile
  final FacilityType? facilityType;
  final bool? isActive;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: Json.str(json['id']),
      userId: Json.strOrNull(json['userId']),
      firstName: Json.strOrNull(json['firstName']),
      lastName: Json.strOrNull(json['lastName']),
      name: Json.strOrNull(json['name']),
      phoneNumber: Json.strOrNull(json['phoneNumber']),
      address: Json.strOrNull(json['address']),
      licenseNumber: Json.strOrNull(json['licenseNumber']),
      specialization: Json.strOrNull(json['specialization']),
      verificationStatus: Json.strOrNull(json['verificationStatus']),
      facilityId: Json.strOrNull(json['facilityId']),
      facilityType: json['facilityType'] == null
          ? null
          : FacilityType.fromJson(json['facilityType']),
      isActive: json['isActive'] == null
          ? null
          : Json.boolean(json['isActive']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'firstName': firstName,
    'lastName': lastName,
    'name': name,
    'phoneNumber': phoneNumber,
    'address': address,
    'licenseNumber': licenseNumber,
    'specialization': specialization,
    'verificationStatus': verificationStatus,
    'facilityId': facilityId,
    'facilityType': facilityType?.wire,
    'isActive': isActive,
  };

  String get fullName {
    final String first = firstName ?? '';
    final String last = lastName ?? '';
    final String joined = '$first $last'.trim();
    if (joined.isNotEmpty) return joined;
    return name ?? '';
  }
}

/// A signed-in user. `role` drives every routing and permission decision.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.isActive = true,
    this.isEmailVerified = false,
    this.createdAt,
    this.profile,
  });

  final String id;
  final String email;
  final UserRole role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final UserProfile? profile;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? profileJson = Json.mapOrNull(json['profile']);
    return AppUser(
      id: Json.str(json['id']),
      email: Json.str(json['email']),
      role: UserRole.tryParse(json['role']) ?? UserRole.parent,
      isActive: Json.boolean(json['isActive'], fallback: true),
      isEmailVerified: Json.boolean(json['isEmailVerified']),
      createdAt: Json.dateOrNull(json['createdAt']),
      profile: profileJson == null ? null : UserProfile.fromJson(profileJson),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'role': role.wire,
    'isActive': isActive,
    'isEmailVerified': isEmailVerified,
    'createdAt': createdAt?.toIso8601String(),
    'profile': profile?.toJson(),
  };

  AppUser copyWith({UserProfile? profile}) {
    return AppUser(
      id: id,
      email: email,
      role: role,
      isActive: isActive,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      profile: profile ?? this.profile,
    );
  }

  /// Name for headers and avatars, falling back to the email local-part.
  String get displayName {
    final String name = profile?.fullName ?? '';
    if (name.isNotEmpty) {
      return role == UserRole.doctor ? 'Dr. $name' : name;
    }
    final int at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  String get initials {
    final String name = profile?.fullName.trim() ?? '';
    final String source = name.isNotEmpty ? name : email;
    final List<String> parts = source
        .split(RegExp(r'[\s@._-]+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

/// `POST /auth/login` → `{ user, token, refreshToken }`.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    this.refreshToken,
  });

  final AppUser user;
  final String token;
  final String? refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AppUser.fromJson(
        Json.mapOrNull(json['user']) ?? <String, dynamic>{},
      ),
      token: Json.str(json['token']),
      refreshToken: Json.strOrNull(json['refreshToken']),
    );
  }
}

/// `POST /auth/register` → `{ user, token, verificationToken }`.
///
/// `verificationToken` is the raw token the backend would normally email; it is
/// what `POST /auth/verify-email` expects as its `token` field.
class RegistrationResult {
  const RegistrationResult({
    required this.user,
    required this.token,
    this.verificationToken,
  });

  final AppUser user;
  final String token;
  final String? verificationToken;

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    return RegistrationResult(
      user: AppUser.fromJson(
        Json.mapOrNull(json['user']) ?? <String, dynamic>{},
      ),
      token: Json.str(json['token']),
      verificationToken: Json.strOrNull(json['verificationToken']),
    );
  }
}
