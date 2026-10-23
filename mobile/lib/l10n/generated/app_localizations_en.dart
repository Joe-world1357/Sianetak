// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sianetak';

  @override
  String get homeHeadline => 'What needs fixing?';

  @override
  String get homeSubtitle =>
      'Pick a service type and see the details before you request.';

  @override
  String get categoriesTitle => 'Services';

  @override
  String get switchLanguage => 'العربية';

  @override
  String get switchLanguageTooltip => 'Switch language to Arabic';

  @override
  String get accountTooltip => 'My account';

  @override
  String get signInTooltip => 'Sign in';

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
      zero: 'No services',
    );
    return '$_temp0';
  }

  @override
  String get sampleDataBadge => 'Sample data';

  @override
  String get sampleDataNotice =>
      'This is sample data for demonstration only and has not been approved.';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Try again';

  @override
  String get emptyCategories =>
      'No services are available right now. Please check back later.';

  @override
  String get emptyServices =>
      'No services are available in this category right now.';

  @override
  String get errorLoadTitle => 'Couldn\'t load data';

  @override
  String get errorNotFound =>
      'This item doesn\'t exist or is no longer available.';

  @override
  String get errorNetwork =>
      'Couldn\'t connect. Check your internet connection and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get priceInspectionRequired => 'Price set after inspection';

  @override
  String get priceInspectionExplanation =>
      'There\'s no reliable estimate for this service. The technician will inspect the problem and send you an itemized quote to approve before any work starts.';

  @override
  String priceIndicativeRange(String min, String max) {
    return 'Estimated price: $min – $max';
  }

  @override
  String get priceIndicativeExplanation =>
      'The final price is set after inspection and needs your approval before work starts.';

  @override
  String get pricingTitle => 'Pricing';

  @override
  String get aboutServiceTitle => 'About this service';

  @override
  String get requestServiceButton => 'Request this service';

  @override
  String get signInToRequest => 'Sign in to request this service';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Enter your mobile number and we\'ll text you a verification code.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneHint => '01XXXXXXXXX';

  @override
  String get phoneInvalid =>
      'Enter a valid Egyptian mobile number (e.g. 01012345678).';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get otpTitle => 'Enter verification code';

  @override
  String otpSubtitle(int length, String phone) {
    return 'We sent a $length-digit code to $phone.';
  }

  @override
  String get otpLabel => 'Verification code';

  @override
  String otpInvalidFormat(int length) {
    return 'Enter the full $length-digit code.';
  }

  @override
  String get verifyButton => 'Verify';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resendButton => 'Resend code';

  @override
  String get changeNumber => 'Change number';

  @override
  String get codeResent => 'A new code has been sent.';

  @override
  String devCodeBanner(String code) {
    return 'Development only — no SMS was sent. Code: $code';
  }

  @override
  String errorOtpInvalid(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: '$attempts attempts left.',
      one: '1 attempt left.',
      zero: 'No attempts left.',
    );
    return 'Incorrect code. $_temp0';
  }

  @override
  String get errorOtpInvalidNoCount => 'Incorrect code.';

  @override
  String get errorOtpExpired => 'This code has expired. Request a new one.';

  @override
  String get errorOtpTooManyAttempts =>
      'Too many incorrect attempts. Request a new code.';

  @override
  String errorResendTooSoon(int seconds) {
    return 'Wait $seconds seconds before requesting a new code.';
  }

  @override
  String get errorOtpRateLimited =>
      'Too many codes were requested for this number. Try again later.';

  @override
  String get errorRateLimited =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errorOtpUnavailable => 'SMS sign-in isn\'t available right now.';

  @override
  String get errorOtpDeliveryFailed =>
      'Couldn\'t send the code. Please try again.';

  @override
  String get errorAccountSuspended =>
      'This account has been suspended. Please contact support.';

  @override
  String get errorSessionExpired =>
      'Your session has ended. Please sign in again.';

  @override
  String get signedInWelcome => 'Welcome! You\'re signed in.';

  @override
  String get profileTitle => 'My account';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileNameHint => 'Enter your name';

  @override
  String get profileNameInvalid => 'Enter a name with at least 2 letters.';

  @override
  String get profilePhoneLabel => 'Mobile number';

  @override
  String get profileRoleLabel => 'Account type';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleTechnician => 'Technician';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get saveButton => 'Save';

  @override
  String get profileSaved => 'Saved.';

  @override
  String get signOutButton => 'Sign out';

  @override
  String get nextButton => 'Next';

  @override
  String get backButton => 'Back';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get editButton => 'Edit';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get requestFlowTitle => 'Request a service';

  @override
  String get stepDescribeTitle => 'Describe the problem';

  @override
  String get stepLocationTitle => 'Service address';

  @override
  String get stepScheduleTitle => 'When';

  @override
  String get stepReviewTitle => 'Review your request';

  @override
  String get descriptionLabel => 'What is the problem?';

  @override
  String get descriptionHint =>
      'e.g. Water has been leaking under the kitchen sink for two days';

  @override
  String descriptionTooShort(int min) {
    return 'Write at least $min characters.';
  }

  @override
  String descriptionTooLong(int max) {
    return 'The description is longer than $max characters.';
  }

  @override
  String get photosTitle => 'Photos (optional)';

  @override
  String photosHelp(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Add up to $max photos that show the problem.',
      one: 'Add a photo that shows the problem.',
    );
    return '$_temp0 Location data is removed from photos automatically.';
  }

  @override
  String get addPhotoCamera => 'Take photo';

  @override
  String get addPhotoGallery => 'From gallery';

  @override
  String get photoUploading => 'Uploading photo';

  @override
  String get photoFailed => 'Upload failed';

  @override
  String get photoRetry => 'Retry upload';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String photoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get photosUploadingWait => 'Wait for the photos to finish uploading.';

  @override
  String get photosFailedFix =>
      'Retry or remove the photos that failed to upload.';

  @override
  String photoLimitReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'You can add up to $max photos.',
      one: 'You can add only 1 photo.',
    );
    return '$_temp0';
  }

  @override
  String get photoTooLarge => 'That photo is too large. Choose a smaller one.';

  @override
  String get photoUploadsUnavailable =>
      'Photo uploads aren\'t available right now. You can still send the request without photos.';

  @override
  String get photoPermissionDenied =>
      'Camera or photo access wasn\'t allowed. You can allow it in your device settings, or continue without photos.';

  @override
  String get photoPickFailed => 'Couldn\'t open that image. Try again.';

  @override
  String get savedAddressesTitle => 'Saved addresses';

  @override
  String get newAddressOption => 'New address';

  @override
  String get areaLabel => 'Area';

  @override
  String get areaRequired => 'Choose the area.';

  @override
  String get addressDetailsLabel => 'Address details';

  @override
  String get addressDetailsHint => 'Street, building, floor, apartment';

  @override
  String get addressDetailsTooShort => 'Add more detail to the address.';

  @override
  String get landmarkLabel => 'Landmark (optional)';

  @override
  String get addressLabelLabel => 'Label (optional)';

  @override
  String get addressLabelHint => 'e.g. Home, Work';

  @override
  String get saveAddressLabel => 'Save this address for next time';

  @override
  String get useCurrentLocation => 'Use my current location';

  @override
  String get locating => 'Finding your location…';

  @override
  String get locationCaptured =>
      'Your current location was added to the address.';

  @override
  String get locationRemove => 'Remove location';

  @override
  String get locationOptionalNote =>
      'Location is optional and helps us find you. It is only used for your requests.';

  @override
  String get locationDenied =>
      'Location access wasn\'t allowed. Type the address instead.';

  @override
  String get locationDeniedForever =>
      'Location access is turned off for this app. Allow it in your device settings, or type the address instead.';

  @override
  String get locationServiceOff =>
      'Location services are off on your device. Turn them on or type the address instead.';

  @override
  String get locationUnavailable =>
      'Couldn\'t find your location. Type the address instead.';

  @override
  String get addressMissing => 'Choose an address.';

  @override
  String get noAreasConfigured => 'No service areas are available right now.';

  @override
  String get scheduleAsap => 'As soon as possible';

  @override
  String get scheduleAsapHint => 'No fixed appointment.';

  @override
  String get scheduleChooseSlot => 'Or choose a time';

  @override
  String get scheduleNoSlots => 'No appointment times are available right now.';

  @override
  String get scheduleMissing => 'Choose a time or \"As soon as possible\".';

  @override
  String slotRange(String day, String from, String to) {
    return '$day, $from – $to';
  }

  @override
  String get reviewServiceLabel => 'Service';

  @override
  String get reviewDescriptionLabel => 'Problem';

  @override
  String get reviewPhotosLabel => 'Photos';

  @override
  String get reviewNoPhotos => 'No photos';

  @override
  String get reviewLocationLabel => 'Address';

  @override
  String get reviewScheduleLabel => 'When';

  @override
  String get reviewPricingLabel => 'Price and fees';

  @override
  String feeInspection(String amount) {
    return 'Inspection fee: $amount';
  }

  @override
  String get feeNoneAtSubmission =>
      'Nothing is charged when you send this request. Any price or fee will be shown to you for approval before work starts.';

  @override
  String get reviewNextSteps =>
      'After you send it, we\'ll review your request. No technician has been assigned yet.';

  @override
  String get submitRequestButton => 'Send request';

  @override
  String get submittingLabel => 'Sending…';

  @override
  String get submitFailedRetry =>
      'The request wasn\'t sent. Check your connection and tap Send request again. It won\'t be sent twice.';

  @override
  String get requestSubmittedTitle => 'Request sent';

  @override
  String get requestReferenceLabel => 'Reference';

  @override
  String get requestSubmittedBody =>
      'Status: Received. You can follow it in My requests.';

  @override
  String get viewRequestButton => 'View request';

  @override
  String get backToHomeButton => 'Back to home';

  @override
  String get statusSubmitted => 'Received';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get myRequestsTitle => 'My requests';

  @override
  String get myRequestsEmpty =>
      'You haven\'t sent any requests yet. Choose a service to start.';

  @override
  String get loadMoreButton => 'Show more';

  @override
  String submittedOn(String date) {
    return 'Sent on $date';
  }

  @override
  String get requestDetailTitle => 'Request details';

  @override
  String get timelineTitle => 'Request history';

  @override
  String get photoLoadFailed => 'Couldn\'t load the photo';

  @override
  String get requestsCustomerOnly =>
      'Service requests are available for customer accounts only.';

  @override
  String get errorServiceNotAvailable =>
      'This service isn\'t available right now.';

  @override
  String get errorAreaNotAvailable => 'This area isn\'t served right now.';

  @override
  String get errorLocationOutOfArea =>
      'That location is outside the service area.';

  @override
  String get errorInvalidSchedule =>
      'That time is no longer available. Choose another.';

  @override
  String get errorTooManyOpenRequests =>
      'You have too many open requests. Wait for them to be handled before sending another.';

  @override
  String get errorMediaInvalid =>
      'One of the files can no longer be used. Remove it and add it again.';

  @override
  String get errorFileTooLarge => 'The file is too large.';

  @override
  String get errorUnsupportedFile =>
      'Unsupported file. Use a JPG or PNG image.';

  @override
  String get errorMediaUnavailable =>
      'File uploads aren\'t available right now.';

  @override
  String get errorMediaPendingLimit =>
      'You have too many unused uploads. Remove some first.';

  @override
  String get errorAddressNotFound =>
      'That address no longer exists. Choose another.';

  @override
  String get errorAddressLimit =>
      'You\'ve reached the maximum number of saved addresses.';

  @override
  String get errorValidation =>
      'Some details are not valid. Check them and try again.';

  @override
  String get errorForbidden => 'You don\'t have permission to do that.';

  @override
  String get errorApplicationAlreadySubmitted =>
      'Your application is already under review.';

  @override
  String get errorApplicationStateConflict =>
      'The application status has changed. Refresh and try again.';

  @override
  String get errorCategoryNotAvailable =>
      'One of the specialties is no longer offered.';

  @override
  String errorDocumentsRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Attach at least $min documents.',
      one: 'Attach at least 1 document.',
    );
    return '$_temp0';
  }

  @override
  String get errorCannotReviewOwn => 'You can\'t review your own application.';

  @override
  String get myRequestsEntry => 'My requests';

  @override
  String get technicianEntryApply => 'Join as a technician';

  @override
  String get technicianEntryStatus => 'My technician application';

  @override
  String get adminReviewEntry => 'Review technician applications';

  @override
  String get technicianApplyTitle => 'Join as a technician';

  @override
  String get technicianApplyIntro =>
      'Send your details for review. You won\'t receive any work until your account is approved.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameInvalid => 'Enter your full name using letters.';

  @override
  String get yearsLabel => 'Years of experience (optional)';

  @override
  String get yearsInvalid => 'Enter a number from 0 to 60.';

  @override
  String get bioLabel => 'About your experience (optional)';

  @override
  String get specialtiesTitle => 'Specialties';

  @override
  String get specialtiesRequired => 'Choose at least one specialty.';

  @override
  String get serviceAreasTitle => 'Areas you serve';

  @override
  String get serviceAreasRequired => 'Choose at least one area.';

  @override
  String get documentsTitle => 'Verification documents';

  @override
  String get documentsOptionalHelp =>
      'The required documents haven\'t been decided yet. Attach anything that shows your identity or experience.';

  @override
  String documentsMinHelp(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Attach at least $min documents.',
      one: 'Attach at least 1 document.',
    );
    return '$_temp0';
  }

  @override
  String get documentsPrivacy =>
      'Documents are private and only seen by the review team.';

  @override
  String get documentKindLabel => 'Document type';

  @override
  String get documentKindIdentity => 'Proof of identity';

  @override
  String get documentKindQualification => 'Certificate or experience';

  @override
  String get documentKindOther => 'Other';

  @override
  String documentNumber(int number) {
    return 'Document $number';
  }

  @override
  String get documentRemove => 'Remove document';

  @override
  String get documentLimitReached =>
      'You\'ve reached the maximum number of documents.';

  @override
  String get submitApplicationButton => 'Send application';

  @override
  String get resubmitApplicationButton => 'Edit and resubmit';

  @override
  String get applicationSubmittedMessage =>
      'Your application was sent for review.';

  @override
  String get applicationStatusTitle => 'Technician application';

  @override
  String get verificationPending => 'Under review';

  @override
  String get verificationPendingBody =>
      'The team is reviewing your details. The result will appear here.';

  @override
  String get verificationApproved => 'Approved';

  @override
  String get verificationApprovedBody =>
      'Your technician account is approved. Receiving work will be available in an upcoming update.';

  @override
  String get verificationRejected => 'Not accepted';

  @override
  String get verificationRejectedBody =>
      'You can update your details and resubmit.';

  @override
  String get verificationRejectedFinal =>
      'Resubmitting isn\'t possible right now. Contact support.';

  @override
  String get verificationSuspended => 'Suspended';

  @override
  String get verificationSuspendedBody =>
      'Your technician account is suspended. Contact support.';

  @override
  String get decisionReasonLabel => 'Reason';

  @override
  String get adminApplicationsTitle => 'Technician applications';

  @override
  String get adminApplicationsEmpty => 'No applications with this status.';

  @override
  String adminApplicationMeta(int specialties, int areas, int documents) {
    return 'Specialties: $specialties · Areas: $areas · Documents: $documents';
  }

  @override
  String get adminApplicantPhone => 'Mobile number';

  @override
  String yearsValue(int years) {
    return 'Years of experience: $years';
  }

  @override
  String get documentsNone => 'No documents';

  @override
  String get pdfDocumentLabel => 'PDF file (preview not available in the app)';

  @override
  String get adminHistoryTitle => 'Review history';

  @override
  String get historySubmitted => 'Submitted';

  @override
  String get historyResubmitted => 'Resubmitted';

  @override
  String get historyApproved => 'Approved';

  @override
  String get historyRejected => 'Rejected';

  @override
  String get historySuspended => 'Suspended';

  @override
  String get adminApproveButton => 'Approve';

  @override
  String get adminRejectButton => 'Reject';

  @override
  String get adminSuspendButton => 'Suspend';

  @override
  String get adminReinstateButton => 'Reinstate';

  @override
  String get adminApproveTitle => 'Approve this technician?';

  @override
  String get adminApproveBody =>
      'The account becomes an approved technician account.';

  @override
  String get adminRejectTitle => 'Reject application';

  @override
  String get adminSuspendTitle => 'Suspend technician';

  @override
  String get adminNoteLabel => 'Internal note (optional)';

  @override
  String get adminReasonLabel => 'Reason (shown to the applicant)';

  @override
  String get adminReasonRequired => 'Write a reason of at least 3 characters.';

  @override
  String get adminDecisionSaved => 'Decision saved.';
}
