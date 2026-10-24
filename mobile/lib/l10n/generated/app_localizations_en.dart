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
  String get errorNetwork => 'Couldn\'t reach the data. Please try again.';

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
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Welcome back. Use your mobile number and password.';

  @override
  String get errorSessionExpired =>
      'Your session has ended. Please sign in again.';

  @override
  String get profileTitle => 'My account';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileNameHint => 'Enter your name';

  @override
  String get profileNameInvalid => 'Enter a name with at least 2 letters.';

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
  String get statusSubmitted => 'Finding a technician';

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
  String get technicianEntryStatus => 'My technician application';

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
      'Optional: attach proof of identity or experience, such as an ID or a certificate.';

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
      'Documents stay on this device and only an administrator can open them.';

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
      'An administrator is reviewing your details. The result will appear here; sign in any time to check.';

  @override
  String get verificationApproved => 'Approved';

  @override
  String get verificationApprovedBody =>
      'Your technician account is approved. Job offers and assigned jobs are on your home screen.';

  @override
  String get verificationRejected => 'Not accepted';

  @override
  String get verificationRejectedBody =>
      'You can update your details and resubmit.';

  @override
  String get verificationRejectedFinal =>
      'Resubmitting isn\'t possible right now. Contact the administrator.';

  @override
  String get verificationSuspended => 'Suspended';

  @override
  String get verificationSuspendedBody =>
      'Your technician account is suspended. Contact the administrator.';

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

  @override
  String get statusUnmatched => 'Waiting for operations';

  @override
  String get statusAssigned => 'Technician assigned';

  @override
  String get statusEnRoute => 'On the way';

  @override
  String get statusArrived => 'Technician arrived';

  @override
  String get statusQuoted => 'Awaiting quote approval';

  @override
  String get statusQuoteRejected => 'Quote declined';

  @override
  String get statusInProgress => 'Work in progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String homeGreeting(String name) {
    return 'Hi $name 👋';
  }

  @override
  String get tabHome => 'Home';

  @override
  String get tabRequests => 'Requests';

  @override
  String get tabNotifications => 'Alerts';

  @override
  String get tabAccount => 'Account';

  @override
  String get tabOffers => 'Offers';

  @override
  String get tabJobs => 'My jobs';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabTechnicians => 'Technicians';

  @override
  String get languageSetting => 'Language';

  @override
  String get technicianCardTitle => 'Technician';

  @override
  String get customerCardTitle => 'Customer';

  @override
  String get ratingNone => 'No ratings yet';

  @override
  String ratingSummary(String avg, int count) {
    return '$avg ($count)';
  }

  @override
  String ratingStars(int stars) {
    return '$stars out of 5 stars';
  }

  @override
  String get ratingTitle => 'Your rating';

  @override
  String get etaEstimate => 'Estimated arrival in about 20–30 minutes';

  @override
  String get chatOpenButton => 'Message about this request';

  @override
  String get chatViewButton => 'View conversation';

  @override
  String get chatTitle => 'Conversation';

  @override
  String get chatEmpty => 'No messages yet. Say hello.';

  @override
  String get chatHint => 'Write a message…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatReadOnly => 'This conversation is read-only.';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get paymentCashCollected => 'Cash collected';

  @override
  String get paymentCommission => 'Platform commission';

  @override
  String get paymentRecordedAt => 'Recorded at';

  @override
  String get cancelReasonTitle => 'Cancellation reason';

  @override
  String get addressHiddenUntilAccepted =>
      'The full address appears once you accept.';

  @override
  String get byOperations => 'by operations';

  @override
  String get quoteTitle => 'Quote';

  @override
  String get quotePending => 'Awaiting approval';

  @override
  String get quoteApproved => 'Approved';

  @override
  String get quoteRejected => 'Declined';

  @override
  String journeyStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get cancelRequestButton => 'Cancel request';

  @override
  String get cancelSheetTitle => 'Why are you cancelling?';

  @override
  String get cancelReasonChangedMind => 'I no longer need the service';

  @override
  String get cancelReasonFixed => 'The problem got fixed';

  @override
  String get cancelReasonTooLong => 'It\'s taking too long';

  @override
  String get cancelReasonOther => 'Another reason';

  @override
  String get requestCancelledToast => 'Request cancelled.';

  @override
  String get customerSearchingTitle => 'Finding you a technician';

  @override
  String get customerSearchingBody =>
      'We\'ve sent your request to approved technicians in your area. You\'ll be notified as soon as one accepts.';

  @override
  String get customerUnmatchedTitle => 'No technician has accepted yet';

  @override
  String get customerUnmatchedBody =>
      'No technician has accepted yet. An administrator will assign one.';

  @override
  String get customerAssignedTitle => 'Your technician is on it';

  @override
  String get customerAssignedBody =>
      'The technician will inspect the problem and send you a quote before any work starts.';

  @override
  String customerQuoteTitle(String amount) {
    return 'Quote: $amount';
  }

  @override
  String get customerQuoteBody =>
      'Work starts only after you approve. Pay in cash when it\'s done.';

  @override
  String get customerQuoteRejectedTitle => 'You declined the quote';

  @override
  String get customerQuoteRejectedBody =>
      'The technician can send a new quote, or you can cancel.';

  @override
  String get customerInProgressTitle => 'Work is underway';

  @override
  String get customerInProgressBody =>
      'The technician will confirm completion and collect the agreed amount.';

  @override
  String get customerCompletedTitle => 'Service completed';

  @override
  String get customerCompletedBody => 'Tell us how it went to help others.';

  @override
  String get approveQuoteButton => 'Approve quote';

  @override
  String get rejectQuoteButton => 'Decline';

  @override
  String get quoteApprovedToast => 'Approved. The technician can start.';

  @override
  String get rateButton => 'Rate the service';

  @override
  String get rateSheetTitle => 'How was the service?';

  @override
  String get rateCommentLabel => 'Comment (optional)';

  @override
  String get rateSubmitButton => 'Submit rating';

  @override
  String get ratingThanks => 'Thanks for your rating!';

  @override
  String get offerForYouTitle => 'A new job for you';

  @override
  String offerExpiresIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Expires in $minutes minutes',
      one: 'Expires in 1 minute',
      zero: 'Expires now',
    );
    return '$_temp0';
  }

  @override
  String get acceptOfferButton => 'Accept job';

  @override
  String get declineOfferButton => 'Decline';

  @override
  String get offerAcceptedToast => 'Job accepted. The customer has been told.';

  @override
  String get techAssignedTitle => 'This job is yours';

  @override
  String get techAssignedBody => 'Let the customer know when you set off.';

  @override
  String get onMyWayButton => 'I\'m on my way';

  @override
  String get arrivedButton => 'I\'ve arrived';

  @override
  String get customerNotifiedToast => 'The customer has been notified.';

  @override
  String get techQuoteNeededTitle => 'Inspect and send a quote';

  @override
  String get techQuoteRejectedTitle => 'The customer declined your quote';

  @override
  String get techQuoteNeededBody =>
      'Work can\'t start until the customer approves the price.';

  @override
  String get sendQuoteButton => 'Send quote';

  @override
  String get techAwaitingApprovalTitle => 'Waiting for the customer';

  @override
  String get techAwaitingApprovalBody =>
      'We\'ll tell you as soon as they respond.';

  @override
  String get techWorkingTitle => 'Approved: start the work';

  @override
  String techWorkingBody(String amount) {
    return 'When finished, collect $amount in cash and confirm.';
  }

  @override
  String get completeJobButton => 'Finish & record cash';

  @override
  String get completeJobTitle => 'Confirm completion';

  @override
  String completeJobBody(String amount) {
    return 'Is the work done and $amount collected in cash?';
  }

  @override
  String get jobCompletedToast => 'Completion and payment recorded.';

  @override
  String get quoteSheetTitle => 'Your quote';

  @override
  String get quoteSheetHint =>
      'Enter the total price (labour and parts) after inspection.';

  @override
  String get quoteAmountLabel => 'Amount';

  @override
  String get quoteAmountInvalid => 'Enter a valid amount.';

  @override
  String get quoteNoteLabel => 'Work details (optional)';

  @override
  String get currencyEgpShort => 'EGP';

  @override
  String get quoteSentToast => 'Quote sent to the customer.';

  @override
  String get adminSearchingTitle => 'Offers are out';

  @override
  String get adminUnmatchedTitle => 'Needs manual assignment';

  @override
  String get adminAssignBody =>
      'You can assign an approved technician who covers this service and area.';

  @override
  String get assignTechnicianButton => 'Assign technician';

  @override
  String get assignSheetTitle => 'Choose a technician';

  @override
  String get assignNoneEligible =>
      'No approved technician covers this service and area.';

  @override
  String get assignedToast => 'Technician assigned.';

  @override
  String get offersTitle => 'Job offers';

  @override
  String get offersIntro =>
      'Requests matching your skills and areas. The first to accept gets the job.';

  @override
  String get offersEmpty => 'No new offers right now. We\'ll let you know.';

  @override
  String get myJobsTitle => 'My jobs';

  @override
  String get jobsActiveTab => 'Active';

  @override
  String get jobsHistoryTab => 'History';

  @override
  String get jobsEmptyActive => 'No active jobs. Accept an offer to start.';

  @override
  String get jobsEmptyHistory => 'No finished jobs yet.';

  @override
  String get earningsTitle => 'Your net earnings';

  @override
  String get earningsNetHint => 'After the platform commission (10%, proposed)';

  @override
  String get earningsJobs => 'Jobs';

  @override
  String get earningsCollected => 'Collected';

  @override
  String get earningsCommission => 'Commission';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String ntfNewOffer(String ref) {
    return 'New job offer $ref';
  }

  @override
  String ntfAssignedByAdmin(String ref) {
    return 'Operations assigned you to $ref';
  }

  @override
  String ntfAssigned(String ref) {
    return 'A technician was assigned to $ref';
  }

  @override
  String ntfEnRoute(String ref) {
    return 'Your technician is on the way $ref';
  }

  @override
  String ntfArrived(String ref) {
    return 'Your technician has arrived $ref';
  }

  @override
  String ntfQuoted(String ref) {
    return 'You have a quote for $ref';
  }

  @override
  String ntfQuoteApproved(String ref) {
    return 'The customer approved your quote $ref';
  }

  @override
  String ntfQuoteRejected(String ref) {
    return 'The customer declined your quote $ref';
  }

  @override
  String ntfCompleted(String ref) {
    return 'Service completed $ref. Rate your technician';
  }

  @override
  String ntfRated(String ref) {
    return 'You received a new rating $ref';
  }

  @override
  String ntfMessage(String ref) {
    return 'New message about $ref';
  }

  @override
  String ntfCancelled(String ref) {
    return 'Request $ref was cancelled';
  }

  @override
  String ntfUnmatched(String ref) {
    return 'Request $ref needs a technician';
  }

  @override
  String get ntfApplicationSubmitted =>
      'A new technician application is waiting for review';

  @override
  String get ntfApplicationApproved =>
      'Your technician application was approved';

  @override
  String get ntfApplicationRejected =>
      'Your technician application was not approved';

  @override
  String get ntfApplicationSuspended => 'Your technician account was suspended';

  @override
  String get adminDashboardTitle => 'Operations';

  @override
  String get kpiNeedsAttention => 'Need attention';

  @override
  String get kpiInProgress => 'In progress';

  @override
  String get kpiCompleted => 'Completed';

  @override
  String get kpiCommission => 'Commission earned';

  @override
  String kpiPendingApplications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applications waiting for review',
      one: '1 application waiting for review',
      zero: 'No applications waiting',
    );
    return '$_temp0';
  }

  @override
  String kpiApprovedTechnicians(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count approved technicians',
      one: '1 approved technician',
    );
    return '$_temp0';
  }

  @override
  String get adminRequestsTitle => 'Requests';

  @override
  String get adminFilterAttention => 'Needs attention';

  @override
  String get adminFilterActive => 'Active';

  @override
  String get adminFilterDone => 'Closed';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminRequestsEmpty => 'Nothing here.';

  @override
  String get errorOfferExpired => 'This offer has expired.';

  @override
  String get errorOfferTaken => 'Another technician already took this job.';

  @override
  String get errorStateConflict =>
      'The request has changed. Refresh and try again.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboarding1Title => 'Home repairs, all in one place';

  @override
  String get onboarding1Body =>
      'Plumbing, electrical, AC, carpentry, painting and appliances across Aswan.';

  @override
  String get onboarding2Title => 'Reviewed technicians';

  @override
  String get onboarding2Body =>
      'Every technician applies first and takes jobs only after an administrator approves them.';

  @override
  String get onboarding3Title => 'You approve before work starts';

  @override
  String get onboarding3Body =>
      'Review and approve the price, follow each step, then rate the job.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneInvalid =>
      'Enter a valid Egyptian mobile number, e.g. 01012345678.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordConfirmLabel => 'Confirm password';

  @override
  String get passwordRules =>
      'At least 8 characters, including a letter and a number.';

  @override
  String get passwordMismatch => 'Passwords don\'t match.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get noAccountPrompt => 'New to Sianetak?';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get signInLink => 'Sign in';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Choose an account type, then add your details.';

  @override
  String get accountTypeLabel => 'Account type';

  @override
  String get accountTypeCustomerBlurb =>
      'Request services and follow them through.';

  @override
  String get accountTypeTechnicianBlurb =>
      'Apply, then take jobs once approved.';

  @override
  String get registerButton => 'Create account';

  @override
  String get localDataNote =>
      'Works offline. Accounts and data are stored only on this device and shared by every account on it.';

  @override
  String get adminSetupPrompt => 'Device owner?';

  @override
  String get adminSetupLink => 'Set up the administrator';

  @override
  String get adminSetupTitle => 'Set up the administrator';

  @override
  String get adminSetupBody =>
      'The first administrator can be created only once on this device. After that, only an administrator can add another.';

  @override
  String get adminSetupButton => 'Create administrator';

  @override
  String get addAdminEntry => 'Add an administrator';

  @override
  String get addAdminTitle => 'Add an administrator';

  @override
  String get addAdminBody =>
      'They\'ll be able to review technicians and manage requests. Share the password with them securely.';

  @override
  String get addAdminButton => 'Add administrator';

  @override
  String adminAdded(String name) {
    return '$name was added as an administrator.';
  }

  @override
  String get changePasswordEntry => 'Change password';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'You\'ll need your number and password to sign in again.';

  @override
  String get aboutDataEntry => 'About your data';

  @override
  String get aboutDataBody =>
      'Sianetak is a fully local build made for a school project. There is no server: accounts, requests, messages and photos are kept in a database on this device only, and passwords are stored as salted one-way hashes. Notifications and chat reach only accounts on this same device, and payment is cash, recorded in the app.';

  @override
  String get gotIt => 'Got it';

  @override
  String get tabApplication => 'Application';

  @override
  String get errorInvalidCredentials => 'Wrong mobile number or password.';

  @override
  String get errorPhoneTaken =>
      'This number already has an account. Sign in instead.';

  @override
  String errorTooManyAttempts(int minutes) {
    return 'Too many attempts. Try again in $minutes min.';
  }

  @override
  String get errorAdminExists =>
      'An administrator already exists on this device.';

  @override
  String get errorAccountDisabled => 'This account is disabled.';

  @override
  String get errorWrongPassword => 'The current password is wrong.';

  @override
  String get errorTechnicianNotApproved =>
      'An administrator must approve your application first.';
}
