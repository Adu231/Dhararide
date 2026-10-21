import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../models/location_model.dart';
import '../models/ride_model.dart';
import '../models/complaint_model.dart';
import '../models/announcement_model.dart';
import '../models/notification_model.dart';

class DemoData {
  // Demo Users
  static const UserModel demoCustomer = UserModel(
    id: 'usr_cust_01',
    name: 'Aditya Patil',
    phone: '9822012345',
    email: 'customer@dharride.demo',
    role: UserRole.customer,
    language: AppLanguage.english,
  );

  static const UserModel demoDriverUser = UserModel(
    id: 'usr_driv_01',
    name: 'Ramesh Shinde',
    phone: '9422054321',
    email: 'driver@dharride.demo',
    role: UserRole.driver,
    language: AppLanguage.marathi,
  );

  static const UserModel demoAdmin = UserModel(
    id: 'usr_adm_01',
    name: 'System Admin',
    phone: '9999900000',
    email: 'admin@dharride.demo',
    role: UserRole.admin,
    language: AppLanguage.english,
  );

  // Demo Drivers
  static final DriverModel demoDriver = DriverModel(
    id: 'drv_01',
    userId: 'usr_driv_01',
    name: 'Ramesh Shinde',
    phone: '9422054321',
    autoNumber: 'MH-25-AZ-4589',
    upiId: 'ramesh.shinde@ybl',
    verificationStatus: DriverVerificationStatus.approved,
    availability: DriverAvailability.online,
    rating: 4.9,
    totalRides: 142,
    totalEarnings: 3840.0,
    currentLatitude: 18.1870,
    currentLongitude: 76.0415,
    lastLocationUpdate: DateTime.now(),
  );

  static final DriverModel demoDriver2 = DriverModel(
    id: 'drv_03',
    userId: 'usr_driv_03',
    name: 'Santosh Gaikwad',
    phone: '9822345678',
    autoNumber: 'MH-25-BK-1102',
    upiId: 'santosh.auto@upi',
    verificationStatus: DriverVerificationStatus.approved,
    availability: DriverAvailability.online,
    rating: 4.8,
    totalRides: 98,
    totalEarnings: 2450.0,
    currentLatitude: 18.1885,
    currentLongitude: 76.0445,
    lastLocationUpdate: DateTime.now(),
  );

  static final DriverModel demoDriver3 = DriverModel(
    id: 'drv_04',
    userId: 'usr_driv_04',
    name: 'Sachin More',
    phone: '9765432109',
    autoNumber: 'MH-25-CY-7788',
    upiId: 'sachin.more@oksbi',
    verificationStatus: DriverVerificationStatus.approved,
    availability: DriverAvailability.online,
    rating: 4.7,
    totalRides: 64,
    totalEarnings: 1820.0,
    currentLatitude: 18.1815,
    currentLongitude: 76.0375,
    lastLocationUpdate: DateTime.now(),
  );

  static const DriverModel demoPendingDriver = DriverModel(
    id: 'drv_02',
    userId: 'usr_driv_02',
    name: 'Vikas Jadhav',
    phone: '9850123456',
    autoNumber: 'MH-25-BX-8812',
    upiId: 'vikas.jadhav@okaxis',
    verificationStatus: DriverVerificationStatus.pending,
    availability: DriverAvailability.offline,
    rating: 4.5,
    totalRides: 0,
    totalEarnings: 0.0,
    currentLatitude: 18.1925,
    currentLongitude: 76.0515,
  );

  // Popular Places in Dharashiv
  static const List<PopularPlaceModel> popularPlaces = [
    PopularPlaceModel(
      id: 'plc_1',
      nameEn: 'Dharashiv Central Bus Stand',
      nameMr: 'धाराशिव मध्यवर्ती बस स्थानक',
      address: 'State Highway 67, Bus Stand Area, Dharashiv',
      latitude: 18.1865,
      longitude: 76.0410,
      category: 'Bus Stand',
    ),
    PopularPlaceModel(
      id: 'plc_2',
      nameEn: 'Dharashiv Railway Station',
      nameMr: 'धाराशिव रेल्वे स्टेशन',
      address: 'Station Road, Railway Colony, Dharashiv',
      latitude: 18.1920,
      longitude: 76.0520,
      category: 'Railway Station',
    ),
    PopularPlaceModel(
      id: 'plc_3',
      nameEn: 'Government Civil Hospital & College',
      nameMr: 'शासकीय जिल्हा रुग्णालय व वैद्यकीय महाविद्यालय',
      address: 'Hospital Road, Civil Lines, Dharashiv',
      latitude: 18.1810,
      longitude: 76.0380,
      category: 'Hospital',
    ),
    PopularPlaceModel(
      id: 'plc_4',
      nameEn: 'Main Kapad Market & Shivaji Chowk',
      nameMr: 'मुख्य कापड बाजार आणि छत्रपती शिवाजी महाराज चौक',
      address: 'Main Market Road, Dharashiv City',
      latitude: 18.1880,
      longitude: 76.0450,
      category: 'Market',
    ),
    PopularPlaceModel(
      id: 'plc_5',
      nameEn: 'Dr. Babasaheb Ambedkar Marathwada Univ Sub-Center',
      nameMr: 'डॉ. बाबासाहेब आंबेडकर मराठवाडा विद्यापीठ उपकेंद्र',
      address: 'MIDC Area, Solapur Road, Dharashiv',
      latitude: 18.1750,
      longitude: 76.0310,
      category: 'College',
    ),
    PopularPlaceModel(
      id: 'plc_6',
      nameEn: 'Shri Tulja Bhavani Temple Road',
      nameMr: 'श्री तुळजाभवानी मंदिर मार्ग (तुळजापूर नाका)',
      address: 'Tuljapur Naka, Dharashiv Bypass',
      latitude: 18.1950,
      longitude: 76.0490,
      category: 'Temple',
    ),
  ];

  // Initial Rides
  static final List<RideModel> initialRides = [
    const RideModel(
      id: 'RIDE-9021',
      customerId: 'usr_cust_01',
      customerName: 'Aditya Patil',
      customerPhone: '9822012345',
      driverId: 'drv_01',
      driverName: 'Ramesh Shinde',
      driverPhone: '9422054321',
      autoNumber: 'MH-25-AZ-4589',
      driverRating: 4.9,
      driverUpiId: 'ramesh.shinde@ybl',
      pickup: LocationPointModel(
        address: 'State Highway 67, Bus Stand Area, Dharashiv',
        placeName: 'Dharashiv Central Bus Stand',
        latitude: 18.1865,
        longitude: 76.0410,
      ),
      destination: LocationPointModel(
        address: 'Hospital Road, Civil Lines, Dharashiv',
        placeName: 'Government Civil Hospital',
        latitude: 18.1810,
        longitude: 76.0380,
      ),
      suggestedFare: 20.0,
      finalFare: 20.0,
      status: RideStatus.rideCompleted,
      paymentMethod: PaymentMethod.onlineUpi,
      paymentStatus: PaymentStatus.confirmed,
      createdAt: 'Today, 09:15 AM',
      completedAt: 'Today, 09:30 AM',
    ),
    const RideModel(
      id: 'RIDE-9018',
      customerId: 'usr_cust_01',
      customerName: 'Aditya Patil',
      customerPhone: '9822012345',
      driverId: 'drv_01',
      driverName: 'Ramesh Shinde',
      driverPhone: '9422054321',
      autoNumber: 'MH-25-AZ-4589',
      driverRating: 4.9,
      driverUpiId: 'ramesh.shinde@ybl',
      pickup: LocationPointModel(
        address: 'Main Market Road, Dharashiv City',
        placeName: 'Main Kapad Market',
        latitude: 18.1880,
        longitude: 76.0450,
      ),
      destination: LocationPointModel(
        address: 'Station Road, Railway Colony, Dharashiv',
        placeName: 'Dharashiv Railway Station',
        latitude: 18.1920,
        longitude: 76.0520,
      ),
      suggestedFare: 30.0,
      finalFare: 30.0,
      status: RideStatus.rideCompleted,
      paymentMethod: PaymentMethod.cash,
      paymentStatus: PaymentStatus.confirmed,
      createdAt: 'Yesterday, 04:30 PM',
      completedAt: 'Yesterday, 04:50 PM',
    ),
  ];

  // Announcements
  static const List<AnnouncementModel> demoAnnouncements = [
    AnnouncementModel(
      id: 'anc_1',
      title: 'Welcome to DharRide!',
      messageEn: 'Connecting Dharashiv customers directly with nearby auto drivers. 0% commission fees!',
      messageMr: 'धाराशिव शहरवासीयांसाठी थेट ऑटो बुकिंग प्लॅटफॉर्म. शून्य टक्के कमिशन!',
      targetAudience: 'ALL',
    ),
    AnnouncementModel(
      id: 'anc_2',
      title: 'Driver Registration Camp',
      messageEn: 'Auto drivers can complete verification at Central Bus Stand office.',
      messageMr: 'ऑटो चालकांसाठी मोफत पडताळणी शिबीर बस स्थानकाजवळ सुरू आहे.',
      targetAudience: 'DRIVER',
    ),
  ];

  // Complaints
  static const List<ComplaintModel> demoComplaints = [
    ComplaintModel(
      id: 'cmp_101',
      userId: 'usr_cust_01',
      userName: 'Aditya Patil',
      userRole: UserRole.customer,
      rideId: 'RIDE-9018',
      category: 'Driver Delay',
      description: 'Driver arrived 5 minutes late due to traffic at Shivaji Chowk.',
      status: ComplaintStatus.resolved,
      adminNotes: 'Resolved via customer follow up.',
    ),
  ];

  // Notifications
  static const List<NotificationModel> demoNotifications = [
    NotificationModel(
      id: 'notif_1',
      titleEn: 'Ride Completed',
      titleMr: 'प्रवास पूर्ण झाला',
      bodyEn: 'Your ride to Dharashiv Central Bus Stand was completed.',
      bodyMr: 'तुमचा धाराशिव मध्यवर्ती बस स्थानकाचा प्रवास पूर्ण झाला आहे.',
      timestamp: '10 mins ago',
    ),
    NotificationModel(
      id: 'notif_2',
      titleEn: 'System Announcement',
      titleMr: 'सिस्टम सूचना',
      bodyEn: 'DharRide 0% commission active across all routes in Dharashiv.',
      bodyMr: 'DharRide वर सर्व मार्गांसाठी ०% कमिशन लागू आहे.',
      timestamp: '1 hour ago',
    ),
  ];
}
