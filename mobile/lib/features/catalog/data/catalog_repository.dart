import '../../../local/local_backend.dart';
import '../domain/catalog_models.dart';

abstract class CatalogRepository {
  Future<List<ServiceCategory>> listCategories();
  Future<CategoryDetail> getCategory(String slug);
  Future<ServiceDetail> getService(String slug);
}

/// The service catalog, read from the on-device database.
class LocalCatalogRepository implements CatalogRepository {
  LocalCatalogRepository(this._backend);

  final LocalBackend _backend;

  @override
  Future<List<ServiceCategory>> listCategories() async =>
      (await _backend.categories())
          .map(ServiceCategory.fromJson)
          .toList(growable: false);

  @override
  Future<CategoryDetail> getCategory(String slug) async =>
      CategoryDetail.fromJson(await _backend.category(slug));

  @override
  Future<ServiceDetail> getService(String slug) async =>
      ServiceDetail.fromJson(await _backend.service(slug));
}
