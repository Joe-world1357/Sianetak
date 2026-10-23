import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/util/uuid.dart';
import '../../catalog/domain/catalog_models.dart';
import '../../media/data/media_repository.dart';
import '../../media/domain/media_models.dart';
import '../data/requests_repository.dart';
import '../domain/request_models.dart';

enum RequestStep { describe, location, schedule, review }

enum PhotoStatus { uploading, uploaded, failed }

class PhotoAttachment {
  PhotoAttachment(this.localId, this.file);

  final int localId;
  final PickedImage file;
  PhotoStatus status = PhotoStatus.uploading;
  String? mediaId;
  Object? error;
}

/// Why a step cannot be completed yet; the UI maps each to localized copy.
enum DraftIssue {
  descriptionTooShort,
  descriptionTooLong,
  photosUploading,
  photosFailed,
  addressMissing,
  areaMissing,
  detailsTooShort,
  scheduleMissing,
}

enum AddPhotoResult { added, limitReached, tooLarge, unavailable }

/// Holds the in-progress request and its rules. The server re-validates everything; these
/// checks give fast feedback and keep the four steps consistent.
class RequestDraftController extends ChangeNotifier {
  RequestDraftController({
    required this.service,
    required RequestsRepository requests,
    required MediaRepository media,
    required RequestOptions options,
    required this.savedAddresses,
  }) // Named parameters cannot be private field formals, so assign them here.
    // ignore: prefer_initializing_formals
    : _requests = requests,
       // ignore: prefer_initializing_formals
       _media = media,
       _options = options {
    useNewAddress = savedAddresses.isEmpty;
    if (!useNewAddress) selectedAddressId = savedAddresses.first.id;
    // Default to the only area when there is exactly one.
    if (options.areas.length == 1) areaId = options.areas.first.id;
  }

  static const minDetailsLength = 5;

  final ServiceDetail service;
  final RequestsRepository _requests;
  final MediaRepository _media;
  RequestOptions _options;
  final List<SavedAddress> savedAddresses;

  RequestOptions get options => _options;

  RequestStep step = RequestStep.describe;

  // Step 1 — problem
  String description = '';
  final List<PhotoAttachment> photos = [];
  int _nextPhotoId = 0;

  // Step 2 — location
  late bool useNewAddress;
  String? selectedAddressId;
  String? areaId;
  String details = '';
  String landmark = '';
  String label = '';
  GeoPoint? point;
  bool saveAddress = true;

  // Step 3 — schedule
  RequestSchedule? schedule;

  // Submission
  bool submitting = false;
  Object? submitError;
  RequestDetail? submitted;
  String? _idempotencyKey;
  String? _keyPayload;

  bool _disposed = false;

  String get _trimmedDescription => description.trim();

  DraftIssue? descriptionIssue() {
    final length = _trimmedDescription.length;
    if (length < _options.descriptionMinLength) {
      return DraftIssue.descriptionTooShort;
    }
    if (length > _options.descriptionMaxLength) {
      return DraftIssue.descriptionTooLong;
    }
    return null;
  }

  DraftIssue? photosIssue() {
    if (photos.any((p) => p.status == PhotoStatus.uploading)) {
      return DraftIssue.photosUploading;
    }
    if (photos.any((p) => p.status == PhotoStatus.failed)) {
      return DraftIssue.photosFailed;
    }
    return null;
  }

  DraftIssue? locationIssue() {
    if (!useNewAddress) {
      return selectedAddressId == null ? DraftIssue.addressMissing : null;
    }
    if (areaId == null) return DraftIssue.areaMissing;
    if (details.trim().length < minDetailsLength) {
      return DraftIssue.detailsTooShort;
    }
    return null;
  }

  DraftIssue? scheduleIssue() =>
      schedule == null ? DraftIssue.scheduleMissing : null;

  DraftIssue? issueFor(RequestStep s) => switch (s) {
    RequestStep.describe => descriptionIssue() ?? photosIssue(),
    RequestStep.location => locationIssue(),
    RequestStep.schedule => scheduleIssue(),
    RequestStep.review =>
      descriptionIssue() ?? photosIssue() ?? locationIssue() ?? scheduleIssue(),
  };

  bool get canAddPhoto =>
      _options.uploadsAvailable && photos.length < _options.maxPhotos;

  void update(VoidCallback change) {
    change();
    _notify();
  }

  void goTo(RequestStep next) {
    step = next;
    submitError = null;
    _notify();
  }

  /// Validates the current step and moves on. Returns the blocking issue, if any.
  DraftIssue? next() {
    final issue = issueFor(step);
    if (issue == null && step != RequestStep.review) {
      goTo(RequestStep.values[step.index + 1]);
    }
    return issue;
  }

  void back() {
    if (step.index > 0) goTo(RequestStep.values[step.index - 1]);
  }

  AddPhotoResult addPhoto(PickedImage file) {
    if (!_options.uploadsAvailable) return AddPhotoResult.unavailable;
    if (photos.length >= _options.maxPhotos) return AddPhotoResult.limitReached;
    if (_options.maxPhotoBytes > 0 &&
        file.bytes.length > _options.maxPhotoBytes) {
      return AddPhotoResult.tooLarge;
    }
    final attachment = PhotoAttachment(_nextPhotoId++, file);
    photos.add(attachment);
    _notify();
    _upload(attachment);
    return AddPhotoResult.added;
  }

  void retryPhoto(int localId) {
    final attachment = photos.where((p) => p.localId == localId).firstOrNull;
    if (attachment == null || attachment.status != PhotoStatus.failed) return;
    attachment
      ..status = PhotoStatus.uploading
      ..error = null;
    _notify();
    _upload(attachment);
  }

  void removePhoto(int localId) {
    final attachment = photos.where((p) => p.localId == localId).firstOrNull;
    if (attachment == null) return;
    photos.remove(attachment);
    _notify();
    final id = attachment.mediaId;
    if (id != null) _media.remove(id).catchError((_) {});
  }

  Future<void> _upload(PhotoAttachment attachment) async {
    try {
      final uploaded = await _media.upload(
        MediaPurpose.requestPhoto,
        attachment.file,
      );
      if (!photos.contains(attachment) || _disposed) {
        // Removed (or the draft was abandoned) while uploading: clean up the orphan.
        _media.remove(uploaded.id).catchError((_) {});
        return;
      }
      attachment
        ..mediaId = uploaded.id
        ..status = PhotoStatus.uploaded;
    } catch (e) {
      attachment
        ..status = PhotoStatus.failed
        ..error = e;
    }
    _notify();
  }

  void selectSavedAddress(String id) => update(() {
    useNewAddress = false;
    selectedAddressId = id;
  });

  void useTypedAddress() => update(() => useNewAddress = true);

  SavedAddress? get selectedAddress => useNewAddress
      ? null
      : savedAddresses.where((a) => a.id == selectedAddressId).firstOrNull;

  ServiceArea? get selectedArea => useNewAddress
      ? _options.areas.where((a) => a.id == areaId).firstOrNull
      : selectedAddress?.area;

  RequestSubmission buildSubmission() => RequestSubmission(
    serviceId: service.summary.id,
    description: _trimmedDescription,
    photoIds: [for (final p in photos) ?p.mediaId],
    addressId: useNewAddress ? null : selectedAddressId,
    address: useNewAddress
        ? AddressInput(
            areaId: areaId!,
            details: details.trim(),
            landmark: landmark.trim(),
            label: label.trim(),
            location: point,
          )
        : null,
    saveAddress: useNewAddress && saveAddress,
    schedule: schedule!,
  );

  /// Submits once the server confirms (NFR-REL-03). A retry of the same content reuses the
  /// idempotency key, so a lost response can never create a second request.
  Future<RequestDetail?> submit() async {
    if (submitting || issueFor(RequestStep.review) != null) return null;
    final submission = buildSubmission();
    final payload = jsonEncode(submission.toJson());
    if (payload != _keyPayload) {
      _idempotencyKey = uuidV4();
      _keyPayload = payload;
    }
    submitting = true;
    submitError = null;
    _notify();
    try {
      submitted = await _requests.submit(
        submission,
        idempotencyKey: _idempotencyKey!,
      );
      return submitted;
    } on ApiException catch (e) {
      submitError = e;
      if (e.code == 'INVALID_SCHEDULE') await _refreshSlots();
      return null;
    } catch (e) {
      submitError = e;
      return null;
    } finally {
      submitting = false;
      _notify();
    }
  }

  Future<void> _refreshSlots() async {
    try {
      _options = await _requests.options();
      final chosen = schedule?.slot;
      if (chosen != null && !_options.slots.contains(chosen)) schedule = null;
    } catch (_) {
      // Keep the old list; the error message already asks to pick another time.
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    // Abandoned draft: remove photos that were uploaded but never attached.
    if (submitted == null) {
      for (final p in photos) {
        final id = p.mediaId;
        if (id != null) _media.remove(id).catchError((_) {});
      }
    }
    super.dispose();
  }
}
