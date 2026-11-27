import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/driver_model.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/session/session_manager.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _autoNumberController = TextEditingController();
  final _upiIdController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _isPhoneOtpVerified = false;
  bool _documentConsentGiven = false;
  bool _isSubmitting = false;

  // Stored documents map
  final Map<DocumentType, DriverDocumentItem> _uploadedDocuments = {};

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initExistingSession();
    });
  }

  void _initExistingSession() {
    final existingUser = ref.read(currentUserProvider);
    if (existingUser != null) {
      setState(() {
        _nameController.text = existingUser.name;
        _phoneController.text = existingUser.phone;
        _isPhoneOtpVerified = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _autoNumberController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  int get _uploadedCount => _uploadedDocuments.length;
  double get _uploadProgress => _uploadedCount / 6.0;

  Future<void> _pickDocumentImage(DocumentType docType, ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (file == null) return;

      // 1. Format validation
      final extension = file.name.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(extension)) {
        _showErrorSnackBar(
          'Unsupported file format (.$extension). Please upload JPG, PNG, or WEBP.',
        );
        return;
      }

      // 2. Size validation
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.length > _maxFileSizeBytes) {
        final sizeMb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
        _showErrorSnackBar(
          'File size ($sizeMb MB) exceeds the 5MB limit. Please upload a smaller image.',
        );
        return;
      }

      final docItem = DriverDocumentItem(
        type: docType,
        fileName: file.name,
        fileSizeBytes: bytes.length,
        localPath: file.path,
        bytes: bytes,
        uploadedAt: DateTime.now(),
        isMasked: docType == DocumentType.aadhaarFront || docType == DocumentType.aadhaarBack,
        secureStorageKey: 'secure_storage://drivers/${_phoneController.text.trim()}/${docType.name}_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );

      setState(() {
        _uploadedDocuments[docType] = docItem;
      });

      _showSuccessSnackBar('${docType.titleEn} uploaded successfully! (${docItem.formattedSize})');
    } catch (e) {
      debugPrint('Error picking document: $e');
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  void _removeDocument(DocumentType docType) {
    setState(() {
      _uploadedDocuments.remove(docType);
    });
    _showFeedbackSnackBar('${docType.titleEn} removed.');
  }

  void _showEnlargedPreview(DriverDocumentItem doc) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: BrandConfig.textPrimaryBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandConfig.accentYellow, width: 2),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc.type.titleEn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (doc.bytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                      maxWidth: double.infinity,
                    ),
                    child: Image.memory(doc.bytes!, fit: BoxFit.contain),
                  ),
                )
              else
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const Text('Preview Unavailable', style: TextStyle(color: Colors.white70)),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Size: ${doc.formattedSize}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Uploaded: ${doc.uploadedAt.hour.toString().padLeft(2, '0')}:${doc.uploadedAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOtpVerificationDialog() {
    final phone = _phoneController.text.trim();
    final strings = ref.read(stringsProvider);
    if (phone.isEmpty || phone.length < 10) {
      _showErrorSnackBar(
        strings.isMr
            ? 'कृपया आधी १०-अंकी मोबाईल नंबर प्रविष्ट करा'
            : 'Please enter a valid 10-digit mobile number first',
      );
      return;
    }

    final otpCtrl = TextEditingController(text: '1234');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BrandConfig.accentYellow.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined, color: BrandConfig.textPrimaryBlack, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.verifyOtp,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'OTP sent to +91 ${_phoneController.text.trim()}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '1234',
                  hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 8),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: strings.confirmOtp,
                onClick: () {
                  if (otpCtrl.text.trim().length >= 4) {
                    setState(() {
                      _isPhoneOtpVerified = true;
                    });
                    Navigator.pop(ctx);
                    _showSuccessSnackBar('Mobile Number +91 ${_phoneController.text.trim()} Verified via OTP!');
                  } else {
                    _showErrorSnackBar('Please enter a valid 4-digit OTP code');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    final strings = ref.read(stringsProvider);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final autoNumber = _autoNumberController.text.trim().toUpperCase();
    final upiId = _upiIdController.text.trim();
    final existingUser = ref.read(currentUserProvider);

    // 1. Name and Phone Validations
    if (name.isEmpty) {
      _showErrorSnackBar('Please enter your full name as per official documents');
      return;
    }

    if (phone.length < 10) {
      _showErrorSnackBar('Please enter a valid 10-digit mobile number');
      return;
    }

    if (!_isPhoneOtpVerified) {
      _showErrorSnackBar('Please verify your mobile number via OTP before submitting');
      _showOtpVerificationDialog();
      return;
    }

    // Driver Registration Flow
    // Vehicle Number Validation
    if (autoNumber.isEmpty || autoNumber.length < 6) {
      _showErrorSnackBar('Please enter a complete vehicle registration number (e.g. MH-25-AB-1234)');
      return;
    }

    // 6 Required Documents Validation
    if (_uploadedDocuments.length < 6) {
      final missing = DocumentType.values.where((t) => !_uploadedDocuments.containsKey(t)).map((t) => t.titleEn).join(', ');
      _showErrorSnackBar('Missing required documents ($missing). All 6 documents must be uploaded.');
      return;
    }

    // Mandatory Document Submission Consent Validation
    if (!_documentConsentGiven) {
      _showErrorSnackBar(strings.pleaseAcceptDocumentConsent);
      return;
    }

    setState(() => _isSubmitting = true);

    // Build complete DriverDocuments object
    final documents = DriverDocuments(
      aadhaarFront: _uploadedDocuments[DocumentType.aadhaarFront],
      aadhaarBack: _uploadedDocuments[DocumentType.aadhaarBack],
      drivingLicenceFront: _uploadedDocuments[DocumentType.drivingLicenceFront],
      drivingLicenceBack: _uploadedDocuments[DocumentType.drivingLicenceBack],
      rcBook: _uploadedDocuments[DocumentType.rcBook],
      driverPhoto: _uploadedDocuments[DocumentType.driverProfilePhoto],
      documentConsentGiven: true,
      consentTimestamp: DateTime.now(),
    );

    // Prevent duplicate accounts by reusing existing authenticated user if available
    final user = existingUser != null
        ? existingUser.copyWith(role: UserRole.driver, name: name, phone: phone)
        : ref.read(userRepositoryProvider.notifier).register(
              name: name,
              phone: phone,
              role: UserRole.driver,
            );

    ref.read(currentUserProvider.notifier).login(user);

    // Register driver in repository
    final driver = ref.read(driverRepositoryProvider.notifier).registerDriver(
          userId: user.id,
          name: user.name,
          phone: user.phone,
          autoNumber: autoNumber,
          upiId: upiId.isNotEmpty ? upiId : 'driver@upi',
          documents: documents,
        );

    ref.read(currentDriverProvider.notifier).setDriver(driver);

    setState(() => _isSubmitting = false);

    _showSuccessSnackBar(strings.submissionSuccess);

    // Navigate to Pending Approval Status Screen
    context.go('/driver/pending');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: BrandConfig.textPrimaryBlack)),
        backgroundColor: BrandConfig.accentYellow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFeedbackSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandConfig.textPrimaryBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final existingUser = ref.watch(currentUserProvider);

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: BrandConfig.backgroundWhite,
        appBar: AppBar(
          backgroundColor: BrandConfig.backgroundWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BrandConfig.textPrimaryBlack),
            onPressed: () {
              if (existingUser != null) {
                context.go('/customer/profile');
              } else {
                context.go('/login');
              }
            },
          ),
          title: Text(
            strings.driverRegistrationTitle,
            style: const TextStyle(
              color: BrandConfig.textPrimaryBlack,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Branding Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BrandConfig.accentYellowLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BrandConfig.accentYellowDark.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const AutoRickshawIcon(size: 44, badgeColor: BrandConfig.accentYellow),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.driverRegistrationTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: BrandConfig.textPrimaryBlack,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              strings.driverRegistrationSub,
                              style: const TextStyle(fontSize: 12, color: BrandConfig.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Existing User Connected Notice
                if (existingUser != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle, color: BrandConfig.textPrimaryBlack, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMr
                                ? 'ग्राहक खाते जोडले: ${existingUser.name} (+91 ${existingUser.phone})'
                                : 'Customer Account Connected: ${existingUser.name} (+91 ${existingUser.phone})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Full Name Field
                _buildFieldLabel(strings.fullName, isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    hintText: isMr ? 'पूर्ण नाव' : 'Full Name',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted.withOpacity(0.7),
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Mobile Phone Number Field with Verify Button
                _buildFieldLabel(strings.mobileNumber, isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  onChanged: (val) {
                    if (_isPhoneOtpVerified) {
                      setState(() => _isPhoneOtpVerified = false);
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_android, size: 20),
                    suffixIcon: _isPhoneOtpVerified
                        ? Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  strings.otpVerified,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BrandConfig.accentYellow,
                                foregroundColor: BrandConfig.textPrimaryBlack,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _showOtpVerificationDialog,
                              child: Text(
                                strings.verify,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                    hintText: isMr ? 'मोबाईल नंबर' : 'Mobile Number',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted.withOpacity(0.7),
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Vehicle Registration Number (Manual Entry, No MH-25 hardcoded prefix)
                  _buildFieldLabel(strings.vehicleNumberManual, isRequired: true),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _autoNumberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.electric_rickshaw_outlined, size: 20),
                      hintText: 'MH-25-AB-1234',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textMuted.withOpacity(0.7),
                        fontWeight: FontWeight.normal,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. UPI ID (Optional)
                  _buildFieldLabel(strings.upiIdOptional, isRequired: false),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _upiIdController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                      hintText: isMr ? 'UPI ID टाका' : 'Enter UPI ID',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textMuted.withOpacity(0.7),
                        fontWeight: FontWeight.normal,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Required Document Uploads Section (6 Cards)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          strings.requiredDocumentsTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BrandConfig.textPrimaryBlack),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _uploadedCount == 6 ? AppColors.success.withOpacity(0.15) : BrandConfig.accentYellowLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _uploadedCount == 6 ? AppColors.success : BrandConfig.accentYellowDark),
                        ),
                        child: Text(
                          '$_uploadedCount / 6 ${strings.uploaded}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _uploadedCount == 6 ? AppColors.success : BrandConfig.textPrimaryBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _uploadedCount == 6 ? AppColors.success : BrandConfig.accentYellowDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6 Document Cards
                  _buildDocumentCard(DocumentType.aadhaarFront, Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _buildDocumentCard(DocumentType.aadhaarBack, Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _buildDocumentCard(DocumentType.drivingLicenceFront, Icons.drive_eta_outlined),
                  const SizedBox(height: 12),
                  _buildDocumentCard(DocumentType.drivingLicenceBack, Icons.drive_eta_outlined),
                  const SizedBox(height: 12),
                  _buildDocumentCard(DocumentType.rcBook, Icons.description_outlined),
                  const SizedBox(height: 12),
                  _buildDocumentCard(DocumentType.driverProfilePhoto, Icons.account_box_outlined),
                  const SizedBox(height: 20),

                  // 7. General Document Submission & Verification Consent Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _documentConsentGiven ? BrandConfig.accentYellowDark : AppColors.border,
                        width: _documentConsentGiven ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                              color: BrandConfig.textPrimaryBlack,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                strings.documentConsentTitle,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: BrandConfig.textPrimaryBlack,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border.withOpacity(0.6)),
                          ),
                          child: Text(
                            strings.documentConsentBody,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: BrandConfig.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _documentConsentGiven,
                                activeColor: BrandConfig.textPrimaryBlack,
                                checkColor: BrandConfig.accentYellow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) => setState(() => _documentConsentGiven = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _documentConsentGiven = !_documentConsentGiven),
                                child: Text(
                                  strings.documentConsentCheckbox,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    color: BrandConfig.textPrimaryBlack,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Final Submission Button
                PrimaryButton(
                  text: strings.submitForVerification,
                  onClick: _isSubmitting ? () {} : _handleSubmit,
                ),
                const SizedBox(height: 16),

                // Login Link if not authenticated
                if (existingUser == null)
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        "Already have an account? ${strings.login}",
                        style: const TextStyle(color: BrandConfig.textPrimaryBlack, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BrandConfig.textPrimaryBlack),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  Widget _buildDocumentCard(DocumentType docType, IconData defaultIcon) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final uploadedDoc = _uploadedDocuments[docType];
    final isUploaded = uploadedDoc != null;

    final title = isMr ? docType.titleMr : docType.titleEn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUploaded ? AppColors.success.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? AppColors.success : AppColors.border,
          width: isUploaded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isUploaded ? AppColors.success.withOpacity(0.12) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isUploaded ? Icons.check_circle_outline : defaultIcon,
                  color: isUploaded ? AppColors.success : BrandConfig.textPrimaryBlack,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isUploaded ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isUploaded ? strings.uploaded : strings.requiredField,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUploaded ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),

          if (isUploaded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  if (uploadedDoc.bytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        uploadedDoc.bytes!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uploadedDoc.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          uploadedDoc.formattedSize,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showEnlargedPreview(uploadedDoc),
                    icon: const Icon(Icons.visibility_outlined, size: 15, color: BrandConfig.textPrimaryBlack),
                    label: Text(
                      strings.preview,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: BrandConfig.textPrimaryBlack),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: const BorderSide(color: BrandConfig.accentYellowDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showSourcePickerModal(docType),
                    icon: const Icon(Icons.sync, size: 15, color: BrandConfig.textPrimaryBlack),
                    label: Text(
                      strings.replace,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: BrandConfig.textPrimaryBlack),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _removeDocument(docType),
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  tooltip: strings.remove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandConfig.accentYellow,
                      foregroundColor: BrandConfig.textPrimaryBlack,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _pickDocumentImage(docType, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: Text(strings.camera, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _pickDocumentImage(docType, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 16, color: BrandConfig.textPrimaryBlack),
                    label: Text(
                      strings.gallery,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: BrandConfig.textPrimaryBlack),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showSourcePickerModal(DocumentType docType) {
    final strings = ref.read(stringsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            Text(
              'Select Image Source • ${docType.titleEn}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandConfig.accentYellow,
                      foregroundColor: BrandConfig.textPrimaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickDocumentImage(docType, ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(strings.camera, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickDocumentImage(docType, ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library, color: BrandConfig.textPrimaryBlack),
                    label: Text(strings.gallery, style: const TextStyle(fontWeight: FontWeight.bold, color: BrandConfig.textPrimaryBlack)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
