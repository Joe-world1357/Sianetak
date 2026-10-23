import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/catalog_models.dart';

abstract class CatalogRepository {
  Future<List<ServiceCategory>> listCategories();
  Future<CategoryDetail> getCategory(String slug);
  Future<ServiceDetail> getService(String slug);
}

/// Guest-accessible catalog over the backend REST API.
class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ServiceCategory>> listCategories() async {
    final json = await _api.get('/catalog/categories');
    final items = json['items'];
    if (items is! List) {
      throw const ApiException(code: ApiException.badResponse);
    }
    return items
        .cast<Map<String, dynamic>>()
        .map(ServiceCategory.fromJson)
        .toList(growable: false);
  }

  @override
  Future<CategoryDetail> getCategory(String slug) async =>
      CategoryDetail.fromJson(
        await _api.get('/catalog/categories/${Uri.encodeComponent(slug)}'),
      );

  @override
  Future<ServiceDetail> getService(String slug) async => ServiceDetail.fromJson(
    await _api.get('/catalog/services/${Uri.encodeComponent(slug)}'),
  );
}
