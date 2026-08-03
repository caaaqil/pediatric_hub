import '../../core/network/api_client.dart';
import '../models/facility.dart';
import '../models/telemetry.dart';

/// `backend/src/routes/facility.routes.js` and
/// `backend/src/routes/healthService.routes.js`
class FacilityRepository {
  const FacilityRepository(this._api);

  final ApiClient _api;

  /// `GET /facilities?page&limit&search`
  Future<Paginated<Facility>> list({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.isNotEmpty) query['search'] = search;

    final dynamic data = await _api.getData('/facilities', query: query);
    return Paginated<Facility>.fromJson(asMap(data), Facility.fromJson);
  }

  /// `GET /facilities/:id`
  Future<Facility> byId(String id) async {
    final dynamic data = await _api.getData('/facilities/$id');
    return Facility.fromJson(asMap(data));
  }

  /// `GET /facilities/my-facility` (FACILITY)
  Future<Facility> myFacility() async {
    final dynamic data = await _api.getData('/facilities/my-facility');
    return Facility.fromJson(asMap(data));
  }

  /// `GET /facilities/my-scope` (FACILITY) — dashboard in a single call.
  Future<FacilityScope> myScope() async {
    final dynamic data = await _api.getData('/facilities/my-scope');
    return FacilityScope.fromJson(asMap(data));
  }

  /// `PUT /facilities/:id` (FACILITY | ADMIN)
  Future<Facility> update({
    required String id,
    String? name,
    String? address,
    String? phoneNumber,
    String? facilityType,
    bool? isActive,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (facilityType != null) body['facilityType'] = facilityType;
    if (isActive != null) body['isActive'] = isActive;

    final dynamic data = await _api.putData('/facilities/$id', body: body);
    return Facility.fromJson(asMap(data));
  }

  // ── Health services ───────────────────────────────────────────────────────

  /// `GET /health-services` — scoped to the caller's facility by middleware.
  Future<List<HealthService>> myServices() async {
    final dynamic data = await _api.getData('/health-services');
    return asMapList(data).map(HealthService.fromJson).toList();
  }

  /// `GET /health-services/by-facility/:facilityId` — active services only,
  /// readable by any signed-in user (used by parents while booking).
  Future<List<HealthService>> servicesOfFacility(String facilityId) async {
    final dynamic data = await _api.getData(
      '/health-services/by-facility/$facilityId',
    );
    return asMapList(data).map(HealthService.fromJson).toList();
  }

  /// `POST /health-services`
  Future<HealthService> createService({
    required String name,
    String? description,
    double? price,
    bool isActive = true,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'name': name,
      'isActive': isActive,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (price != null) body['price'] = price;

    final dynamic data = await _api.postData('/health-services', body: body);
    return HealthService.fromJson(asMap(data));
  }

  /// `PUT /health-services/:id`
  Future<HealthService> updateService({
    required String id,
    String? name,
    String? description,
    double? price,
    bool? isActive,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (isActive != null) body['isActive'] = isActive;

    final dynamic data = await _api.putData('/health-services/$id', body: body);
    return HealthService.fromJson(asMap(data));
  }

  /// `DELETE /health-services/:id` — soft delete.
  Future<void> archiveService(String id) =>
      _api.deleteData('/health-services/$id');
}
