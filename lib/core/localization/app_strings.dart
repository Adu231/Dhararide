import 'package:flutter/material.dart';
import '../../data/models/enums.dart';

class AppStrings {
  final AppLanguage language;
  AppStrings(this.language);

  bool get isMr => language == AppLanguage.marathi;

  // App & Branding
  String get appName => 'DharRide';
  String get appTagline => isMr ? 'तुमची राइड, तुमच्या पसंतीची.' : 'Your Ride. Your Way.';
  String get appSubtagline => isMr ? 'धाराशिवचे स्थानिक ऑटो-रिक्षा बुकिंग नेटवर्क' : "Dharashiv's Local Auto-Rickshaw Booking Network";
  String get targetCity => 'Dharashiv';

  // Onboarding
  String get onboardingTitle1 => isMr ? 'जवळपास ऑटो शोधा' : 'Find an Auto Nearby';
  String get onboardingDesc1 => isMr ? 'धाराशिव शहरात कुठेही एका टॅपवर जवळच्या ऑटो-रिक्षांशी थेट कनेक्ट व्हा.' : 'Connect directly with auto-rickshaws anywhere in Dharashiv city with a single tap.';
  String get onboardingTitle2 => isMr ? 'चालकाशी थेट संपर्क' : 'Connect directly with Driver';
  String get onboardingDesc2 => isMr ? 'मध्यस्थ नाही, कमिशन नाही. तुमच्या चालकाला थेट कॉल करा आणि संवाद साधा.' : 'No middleman, no commission fees. Call your driver and coordinate directly.';
  String get onboardingTitle3 => isMr ? 'तुमच्या आवडीने प्रवास करा' : 'Ride Your Way';
  String get onboardingDesc3 => isMr ? 'ग्राहक आणि चालक यांच्यात परस्पर भाडे ठरवा. रोख किंवा UPI द्वारे पेमेंट करा.' : 'Mutual fare agreement between customer and driver. Pay via Cash or UPI.';
  String get skip => isMr ? 'वगळा' : 'Skip';
  String get next => isMr ? 'पुढे' : 'Next';
  String get getStarted => isMr ? 'सुरवात करा' : 'Get Started';

  // Auth & General
  String get login => isMr ? 'लॉग इन करा' : 'Log In';
  String get register => isMr ? 'नोंदणी करा' : 'Register';
  String get logout => isMr ? 'लॉग आउट' : 'Log Out';
  String get save => isMr ? 'जतन करा' : 'Save';
  String get cancel => isMr ? 'रद्द करा' : 'Cancel';
  String get confirm => isMr ? 'निश्चित करा' : 'Confirm';
  String get submit => isMr ? 'सबमिट करा' : 'Submit';
  String get back => isMr ? 'मागे' : 'Back';
  String get accept => isMr ? 'स्वीकारा' : 'Accept';
  String get reject => isMr ? 'नाकारा' : 'Reject';
  String get call => isMr ? 'कॉल करा' : 'Call';
  String get callCustomer => isMr ? 'ग्राहकाला कॉल करा' : 'Call Customer';
  String get callDriver => isMr ? 'चालकाला कॉल करा' : 'Call Driver';
  String get viewLocation => isMr ? 'स्थान पहा' : 'View Location';
  String get openInGoogleMaps => isMr ? 'गूगल मॅप्समध्ये उघडा' : 'Open in Google Maps';
  String get startRide => isMr ? 'प्रवास सुरू करा' : 'Start Ride';
  String get completeRide => isMr ? 'प्रवास पूर्ण करा' : 'Complete Ride';
  String get payViaUpi => isMr ? 'UPI द्वारे पैसे द्या' : 'Pay via UPI';
  String get showQr => isMr ? 'QR कोड दाखवा' : 'Show QR Code';
  String get iHavePaid => isMr ? 'मी पैसे दिले आहेत' : 'I Have Paid';
  String get paymentReceived => isMr ? 'पैसे मिळाले' : 'Payment Received';
  String get rateDriver => isMr ? 'चालकाला रेटिंग द्या' : 'Rate Driver';
  String get close => isMr ? 'बंद करा' : 'Close';

  // Form Fields
  String get roleCustomer => isMr ? 'ग्राहक' : 'Customer';
  String get roleDriver => isMr ? 'चालक' : 'Driver';
  String get roleAdmin => isMr ? 'प्रशासक' : 'Admin';
  String get cancelRide => isMr ? 'प्रवास रद्द करा' : 'Cancel Ride';

  String get selectRole => isMr ? 'खात्याची भूमिका निवडा' : 'Select Account Role';
  String get fullName => isMr ? 'पूर्ण नाव' : 'Full Name';
  String get mobileNumber => isMr ? 'मोबाईल नंबर' : 'Mobile Phone Number';
  String get emailOptional => isMr ? 'ईमेल (ऐच्छिक)' : 'Email Address (Optional)';
  String get password => isMr ? 'पासवर्ड' : 'Password';
  String get autoNumber => isMr ? 'ऑटो गाडी नंबर (उदा. MH-25-AB-1234)' : 'Auto Vehicle Number (e.g. MH-25-AB-1234)';
  String get upiId => isMr ? 'UPI ID (उदा. driver@upi)' : 'UPI ID (e.g. driver@upi)';
  String get loginDemoHint => isMr ? 'लॉग इन (खालील खात्यावर टॅप करा)' : 'Quick Login (tap an account below)';
  String get demoCustomerBtn => isMr ? 'ग्राहक' : 'Customer';
  String get demoDriverBtn => isMr ? 'चालक' : 'Driver';
  String get demoAdminBtn => isMr ? 'ॲडमिन' : 'Admin';

  // Customer Booking & Ride Tracking
  String get greetingHello => isMr ? 'नमस्कार,' : 'Hello,';
  String get whereToGo => isMr ? 'तुम्हाला कुठे जायचे आहे?' : 'Where do you want to go?';
  String get pickupLocation => isMr ? 'पिकअप स्थान' : 'Pickup Location';
  String get destinationLocation => isMr ? 'गंतव्य स्थान (ड्रॉप)' : 'Destination (Drop)';
  String get bookAuto => isMr ? 'ऑटो बुक करा' : 'Book Auto';
  String get popularPlaces => isMr ? 'धाराशिवमधील प्रसिद्ध ठिकाणे' : 'Popular Places in Dharashiv';
  String get recentlyVisitedPlaces => isMr ? 'अलीकडे भेट दिलेली ठिकाणे' : 'Recently Visited Places';
  String get suggestedFare => isMr ? 'अंदाजित भाडे' : 'Suggested Fare';
  String get finalFare => isMr ? 'अंतिम ठरलेले भाडे' : 'Final Agreed Fare';
  String get mutualFareNote => isMr ? 'अंतिम भाडे ग्राहक आणि चालक यांच्यात आपापसात ठरवता येते.' : 'Final fare can be mutually agreed between customer and driver.';
  String get noCommissionNote => isMr ? '0% कमिशन प्लॅटफॉर्म - थेट चालकाला पैसे द्या.' : '0% commission platform - 100% fare goes to the driver.';
  String get searchPlaces => isMr ? 'धाराशिवमधील ठिकाण शोधा...' : 'Search landmarks in Dharashiv...';
  String get useCurrentLocation => isMr ? 'सध्याचे स्थान वापरा' : 'Use Current Location';
  String get swapLocations => isMr ? 'स्थान बदला' : 'Swap Locations';
  String get locationPermissionDisabled => isMr ? 'स्थान परवानगी बंद आहे • चालू करा' : 'Location permission disabled • Tap to enable';
  String get directToDriver => isMr ? '१००% रक्कम चालकाला' : '100% to Driver';

  // Where is my driver & Navigation
  String get whereIsMyDriver => isMr ? 'माझा ड्रायव्हर कुठे आहे?' : 'Where is my driver?';
  String get driverLocationUnavailable => isMr ? 'चालकाचे थेट स्थान अद्याप उपलब्ध नाही' : 'Driver location is not available yet';
  String get driverLocationUnavailableDesc => isMr
      ? 'चालक लवकरच पिकअप स्थानावर पोहोचेल. तुम्ही चालकाला थेट कॉल करू शकता किंवा पिकअप पत्ता पाहू शकता.'
      : 'Driver will arrive at pickup shortly. You can call the driver directly or view pickup location.';
  String get navigateToPickup => isMr ? 'पिकअप स्थानाकडे नेव्हिगेट करा' : 'Navigate to Pickup';
  String get navigateToDestination => isMr ? 'ड्रॉप स्थानाकडे नेव्हिगेट करा' : 'Navigate to Drop';
  String get estimatedFare => isMr ? 'अंदाजित भाडे' : 'Estimated Fare';
  String get reviewBooking => isMr ? 'राइड आढावा आणि खात्री' : 'Review & Confirm Ride';
  String get confirmBooking => isMr ? 'ऑटो बुक करा' : 'Confirm & Request Auto';
  String get openLocationSettings => isMr ? 'लोकेशन सेटिंग उघडा' : 'Open Location Settings';
  String get openAppSettings => isMr ? 'ॲप सेटिंग उघडा' : 'Open App Settings';
  String get gpsDisabledTitle => isMr ? 'GPS बंद आहे' : 'GPS Turned Off';
  String get gpsDisabledDesc => isMr ? 'तुमच्या फोनचे GPS बंद आहे. कृपया चालू करा.' : 'Device location is turned off. Please turn on GPS.';
  String get searchingPlaces => isMr ? 'ठिकाणे शोधत आहोत...' : 'Searching places...';
  String get retryRouting => isMr ? 'मार्ग पुन्हा मोजा' : 'Retry Route';
  String get roadDistance => isMr ? 'रस्त्यावरील अंतर' : 'Road Distance';
  String get measuringRoadDistance => isMr ? 'रस्त्यावरील मार्ग मोजत आहोत...' : 'Calculating road route...';
  String get offlineRouteEstimate => isMr ? 'ऑफलाइन अंदाजित मार्ग' : 'Offline Route Estimate';

  // Ride Statuses
  String get statusSearching => isMr ? 'ऑटो शोधत आहोत...' : 'Searching for Auto...';
  String get statusDriverAssigned => isMr ? 'चालक नियुक्त झाला' : 'Driver Assigned';
  String get statusDriverArriving => isMr ? 'चालक येत आहे' : 'Driver Coming to Pickup';
  String get statusDriverArrived => isMr ? 'चालक पोहोचला' : 'Driver Arrived';
  String get statusRideStarted => isMr ? 'प्रवास सुरू आहे' : 'Ride in Progress';
  String get statusRideCompleted => isMr ? 'प्रवास पूर्ण झाला' : 'Ride Completed';
  String get statusCancelled => isMr ? 'प्रवास रद्द झाला' : 'Ride Cancelled';

  // Booking Review & Calculations
  String get bookingConfirmation => isMr ? 'राइड आढावा आणि खात्री' : 'Review & Confirm Ride';
  String get confirmAndBook => isMr ? 'बुकिंग निश्चित करा' : 'Confirm Booking';
  String get pleaseSelectBoth => isMr ? 'कृपया पिकअप आणि ड्रॉप दोन्ही ठिकाणे निवडा.' : 'Please select both pickup and destination locations.';
  String get selectSamePlaceError => isMr ? 'पिकअप आणि ड्रॉप ठिकाण एकच असू शकत नाही.' : 'Pickup and destination cannot be the same.';
  String get bookingInProgress => isMr ? 'बुकिंग प्रक्रिया सुरू आहे...' : 'Processing booking...';
  String get estimatedDistance => isMr ? 'अंदाजित अंतर' : 'Estimated Distance';
  String get estimatedTime => isMr ? 'अंदाजित वेळ' : 'Estimated Time';
  String get baseFareLabel => isMr ? 'बेस भाडे (पहिले १.५ किमी)' : 'Base Fare (First 1.5 km)';
  String get distanceFareLabel => isMr ? 'अंतर भाडे' : 'Distance Fare';
  String get platformFee => isMr ? 'प्लॅटफॉर्म फी' : 'Platform Fee';
  String get zeroPlatformFee => isMr ? '₹० (०% कमिशन)' : '₹0 (0% Commission)';

  // Status & Searching
  String get searchingNearby => isMr ? 'जवळपासच्या रिक्षांचा शोध घेत आहोत...' : 'Searching for nearby auto-rickshaws...';
  String get connectingDriver => isMr ? 'थेट संपर्क साधत आहोत (शून्य कमिशन)' : 'Direct connection (0% commission)';
  String get cancelRequest => isMr ? 'विनंती रद्द करा' : 'Cancel Request';
  String get rateYourExperience => isMr ? 'तुमच्या प्रवासाचा अनुभव कसा होता?' : 'How was your ride experience?';
  String get writeFeedback => isMr ? 'प्रतिक्रिया लिहा (ऐच्छिक)' : 'Write feedback (optional)';

  // Payment
  String get paymentMethod => isMr ? 'पेमेंट पद्धत' : 'Payment Method';
  String get cash => isMr ? 'रोख (Cash)' : 'Cash';
  String get onlineUpi => isMr ? 'ऑनलाइन UPI' : 'Online UPI';
  String get scanQrToPay => isMr ? 'QR कोड स्कॅन करा किंवा UPI ID द्वारे पैसे द्या' : 'Scan QR code or pay via driver UPI ID';

  // Driver Strings
  String get statusOnline => isMr ? 'ऑनलाइन' : 'ONLINE';
  String get statusOffline => isMr ? 'ऑफलाइन' : 'OFFLINE';
  String get driverOnlineDesc => isMr ? 'तुम्ही ऑनलाइन आहात आणि राइड विनंत्या स्वीकारू शकता.' : 'You are online and ready to accept ride requests.';
  String get driverOfflineDesc => isMr ? 'तुम्ही ऑफलाइन आहात. विनंत्या मिळवण्यासाठी स्विच चालू करा.' : 'You are offline. Turn on toggle to receive rides.';
  String get newRideRequest => isMr ? 'नवीन राइड विनंती उपलब्ध!' : 'New Ride Request Available!';
  String get todaysRides => isMr ? 'आजच्या राइड्स' : "Today's Rides";
  String get completedRides => isMr ? 'पूर्ण झालेल्या राइड्स' : 'Completed Rides';
  String get todaysEarnings => isMr ? 'आजची एकूण कमाई' : "Today's Earnings";
  String get verificationPending => isMr ? 'खाते पडताळणी प्रलंबित' : 'Account Verification Pending';
  String get verificationPendingDesc => isMr ? 'तुमचे ड्रायव्हर खाते DharRide ॲडमिन टीमद्वारे तपासले जात आहे. मंजूर झाल्यावर तुम्ही राइड्स स्वीकारू शकाल.' : 'Your driver account is being reviewed by the DharRide team. You can accept rides once approved.';

  // Admin
  String get adminDashboard => isMr ? 'ॲडमिन डॅशबोर्ड' : 'Admin Dashboard';
  String get totalUsers => isMr ? 'एकूण वापरकर्ते' : 'Total Users';
  String get totalDrivers => isMr ? 'एकूण चालक' : 'Total Drivers';
  String get pendingDrivers => isMr ? 'प्रलंबित चालक' : 'Pending Drivers';
  String get approvedDrivers => isMr ? 'मंजूर चालक' : 'Approved Drivers';
  String get activeRides => isMr ? 'सक्रिय राइड्स' : 'Active Rides';
  String get userManagement => isMr ? 'वापरकर्ता व्यवस्थापन' : 'User Management';
  String get driverManagement => isMr ? 'चालक व्यवस्थापन' : 'Driver Management';
  String get rideManagement => isMr ? 'राइड्स व्यवस्थापन' : 'Ride Audit & Management';
  String get complaintsManagement => isMr ? 'तक्रारी व मदत' : 'Complaints & Support';
  String get announcements => isMr ? 'सूचना व घोषणा' : 'Announcements';

  // Navigation Tabs
  String get tabHome => isMr ? 'होम' : 'Home';
  String get tabRides => isMr ? 'माझ्या राइड्स' : 'My Rides';
  String get tabNotifications => isMr ? 'सूचना' : 'Notifications';
  String get tabProfile => isMr ? 'प्रोफाईल' : 'Profile';
  String get tabDashboard => isMr ? 'डॅशबोर्ड' : 'Dashboard';

  // Language settings
  String get languageSettings => isMr ? 'भाषा / Language' : 'Language / भाषा';
  String get english => 'English (इंग्रजी)';
  String get marathi => 'मराठी';
}
