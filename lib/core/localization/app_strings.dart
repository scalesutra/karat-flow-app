import 'package:get/get.dart';

abstract final class AppStrings {
  // ═══════════════════════════════════════════════════════════
  // 1. GENERAL / COMMON ACTIONS & LABELS
  // ═══════════════════════════════════════════════════════════
  static const String appName = 'appName';
  static const String appTagline = 'appTagline';
  static const String online = 'online';
  static const String offline = 'offline';
  static const String active = 'active';
  static const String pending = 'pending';
  static const String inProgress = 'inProgress';
  static const String completed = 'completed';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String onHold = 'onHold';
  static const String urgent = 'urgent';
  static const String normal = 'normal';
  static const String save = 'save';
  static const String cancel = 'cancel';
  static const String close = 'close';
  static const String confirm = 'confirm';
  static const String delete = 'delete';
  static const String edit = 'edit';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String refresh = 'refresh';
  static const String acknowledge = 'acknowledge';
  static const String acknowledged = 'acknowledged';
  static const String submit = 'submit';
  static const String resume = 'resume';
  static const String clear = 'clear';
  static const String viewAll = 'viewAll';
  static const String details = 'details';
  static const String status = 'status';
  static const String date = 'date';
  static const String time = 'time';
  static const String actions = 'actions';
  static const String back = 'back';
  static const String next = 'next';
  static const String previous = 'previous';
  static const String loading = 'loading';
  static const String noData = 'noData';
  static const String comingSoon = 'comingSoon';

  // ═══════════════════════════════════════════════════════════
  // 2. NETWORK & CONNECTIVITY NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════
  static const String noInternetTitle = 'noInternetTitle';
  static const String noInternetMessage = 'noInternetMessage';
  static const String backOnlineTitle = 'backOnlineTitle';
  static const String backOnlineMessage = 'backOnlineMessage';

  // ═══════════════════════════════════════════════════════════
  // 3. NAVIGATION & ROLES
  // ═══════════════════════════════════════════════════════════
  static const String roleAdmin = 'roleAdmin';
  static const String roleWorkshop = 'roleWorkshop';
  static const String roleCad = 'roleCad';
  static const String roleFrontOffice = 'roleFrontOffice';
  static const String navOrders = 'navOrders';
  static const String navDesigns = 'navDesigns';
  static const String navCart = 'navCart';
  static const String navClients = 'navClients';
  static const String navMore = 'navMore';
  static const String navTasks = 'navTasks';
  static const String navStock = 'navStock';
  static const String navManage = 'navManage';
  static const String navOverview = 'navOverview';
  static const String navLibrary = 'navLibrary';
  static const String navCalculator = 'navCalculator';

  // ═══════════════════════════════════════════════════════════
  // 4. FRONT OFFICE (CATALOGUE, ORDERS, CART, CLIENTS)
  // ═══════════════════════════════════════════════════════════
  static const String frontOffice = 'frontOffice';
  static const String frontOfficeSubtitle = 'frontOfficeSubtitle';
  static const String newOrder = 'newOrder';
  static const String wholesaleOrders = 'wholesaleOrders';
  static const String customOrders = 'customOrders';
  static const String clientAccounts = 'clientAccounts';
  static const String wholesaleClients = 'wholesaleClients';
  static const String orderCart = 'orderCart';
  static const String addToCart = 'addToCart';
  static const String cartEmpty = 'cartEmpty';
  static const String clearCart = 'clearCart';
  static const String placeOrder = 'placeOrder';
  static const String totalEstimate = 'totalEstimate';
  static const String mcxSpot = 'mcxSpot';
  static const String creditLimit = 'creditLimit';
  static const String outstandingBalance = 'outstandingBalance';
  static const String registerClient = 'registerClient';
  static const String firmName = 'firmName';
  static const String contactPerson = 'contactPerson';
  static const String phoneNumber = 'phoneNumber';
  static const String city = 'city';
  static const String purityKarat = 'purityKarat';
  static const String grossWeight = 'grossWeight';
  static const String netGoldWeight = 'netGoldWeight';
  static const String makingCharge = 'makingCharge';
  static const String wastagePercent = 'wastagePercent';
  static const String diamondStoneWeight = 'diamondStoneWeight';

  // ═══════════════════════════════════════════════════════════
  // 5. WORKSHOP & MANUFACTURING FLOOR
  // ═══════════════════════════════════════════════════════════
  static const String workshop = 'workshop';
  static const String workshopHardware = 'workshopHardware';
  static const String workshopSubtitle = 'workshopSubtitle';
  static const String currentShift = 'currentShift';
  static const String shiftMorning = 'shiftMorning';
  static const String shiftEvening = 'shiftEvening';
  static const String activeArtisans = 'activeArtisans';
  static const String activeBenches = 'activeBenches';
  static const String endShift = 'endShift';
  static const String shiftHandover = 'shiftHandover';
  static const String connectedHardware = 'connectedHardware';
  static const String zebraPrinter = 'zebraPrinter';
  static const String printLabel = 'printLabel';
  static const String scaleTare = 'scaleTare';
  static const String precisionScale = 'precisionScale';
  static const String honeywellScanner = 'honeywellScanner';
  static const String barcodeScanner = 'barcodeScanner';
  static const String floorGovernance = 'floorGovernance';
  static const String floorDirectives = 'floorDirectives';
  static const String dailyReconciliation = 'dailyReconciliation';
  static const String vaultLockdown = 'vaultLockdown';
  static const String productManager = 'productManager';
  static const String stageOverview = 'stageOverview';
  static const String lotId = 'lotId';
  static const String artisanAssignment = 'artisanAssignment';
  static const String advanceStage = 'advanceStage';

  // ═══════════════════════════════════════════════════════════
  // 6. CAD 3D DESIGN & WEIGHT ESTIMATOR
  // ═══════════════════════════════════════════════════════════
  static const String cadDesigner = 'cadDesigner';
  static const String cadDashboard = 'cadDashboard';
  static const String cadSubtitle = 'cadSubtitle';
  static const String cadDesignLibrary = 'cadDesignLibrary';
  static const String uploadStl = 'uploadStl';
  static const String uploadBlock = 'uploadBlock';
  static const String view3d = 'view3d';
  static const String calculateWeight = 'calculateWeight';
  static const String weightCalculator = 'weightCalculator';
  static const String volumeCubicMm = 'volumeCubicMm';
  static const String densityGmCc = 'densityGmCc';
  static const String estimatedGoldWeight = 'estimatedGoldWeight';
  static const String directives = 'directives';
  static const String adminDirectives = 'adminDirectives';
  static const String signOffModel = 'signOffModel';

  // ═══════════════════════════════════════════════════════════
  // 7. ADMIN DASHBOARD & MASTER MANAGEMENT
  // ═══════════════════════════════════════════════════════════
  static const String adminDashboard = 'adminDashboard';
  static const String manageWorkshop = 'manageWorkshop';
  static const String stockManagement = 'stockManagement';
  static const String vaultCustody = 'vaultCustody';
  static const String goldVault = 'goldVault';
  static const String employeesArtisans = 'employeesArtisans';
  static const String craftMatrices = 'craftMatrices';
  static const String ratebooks = 'ratebooks';
  static const String productionRouting = 'productionRouting';
  static const String hallmarkingRules = 'hallmarkingRules';
  static const String sendDirective = 'sendDirective';
  static const String directiveRecipient = 'directiveRecipient';
  static const String directiveContent = 'directiveContent';

  // ═══════════════════════════════════════════════════════════
  // 8. LANGUAGE & LOCALIZATION
  // ═══════════════════════════════════════════════════════════
  static const String selectLanguage = 'selectLanguage';
  static const String english = 'english';
  static const String hindi = 'hindi';
  static const String gujarati = 'gujarati';
}

/// Quick helper extension on String to get translated text with fallback
extension AppStringTr on String {
  String get trClean {
    final res = tr;
    return (res.isEmpty || res == this) ? this : res;
  }
}
