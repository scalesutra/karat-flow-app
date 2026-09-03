/// Centralized API Endpoint routes for KaratFlow Backend & ERP Services
/// Matches the live API server specifications (Host: 134.195.138.153:5080)
abstract final class ApiEndpoints {
  // ── Base Configurations ───────────────────────────────────────────
  static const String baseUrl = 'https://ka.scalesutra.com/api/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── SECTION 1: Authentication & Token Management (/auth) ──────────
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String authMe = '/auth/me';

  // ── SECTION 2: Employee & User Management (/employees) ───────────
  static const String employees = '/employees';
  static String employeeDetails(String id) => '/employees/$id';
  static String updateEmployee(String id) => '/employees/$id';
  static String employeeAssignments(String id) => '/employees/$id/assignments';

  // ── SECTION 3: Client Accounts / Customers (/customers) ──────────
  static const String customers = '/customers';
  static String customerDetails(String id) => '/customers/$id';
  static String updateCustomer(String id) => '/customers/$id';

  // ── SECTION 4: Dynamic Production Stages (/stages) ───────────────
  static const String stages = '/stages';
  static String stageDetails(String id) => '/stages/$id';

  // ── SECTION 5: Raw Pencil Sketches (/sketches) ────────────────────
  static const String sketches = '/sketches';
  static String sketchDetails(String id) => '/sketches/$id';
  static const String uploadSketch = '/sketches/upload';
  static String reuploadSketch(String id) => '/sketches/$id/reupload';
  static String reviewSketch(String id) => '/sketches/$id/review';

  // ── SECTION 6: 3D CAD / CAM Designs (/three-d-designs) ───────────
  static const String threeDDesigns = '/three-d-designs';
  static String threeDDesignDetails(String id) => '/three-d-designs/$id';
  static const String uploadThreeD = '/three-d-designs/upload';
  static String reuploadThreeD(String id) => '/three-d-designs/$id/reupload';
  static String reviewThreeD(String id) => '/three-d-designs/$id/review';
  static String updateThreeDProduct(String designId) =>
      '/three-d-designs/$designId/product';

  // ── SECTION 7: Orders & Multi-Design Tracking (/orders) ──────────
  static const String orders = '/orders';
  static String orderDetails(String id) => '/orders/$id';
  static String orderTrack(String orderNumber) => '/orders/track/$orderNumber';
  static String addOrderParts(String orderId) => '/orders/$orderId/parts';
  static String checkoutOrder(String orderId) => '/orders/$orderId/checkout';

  // ── SECTION 8: Production Floor & Assignments (/production) ───────
  static const String productionPending = '/production/pending';
  static const String productionAssign = '/production/assign';
  static String productionTransition(String partId) =>
      '/production/parts/$partId/transition';
  static String productionRollback(String partId) =>
      '/production/parts/$partId/rollback';
  static String productionBlock(String partId) =>
      '/production/parts/$partId/block';
  static String productionUnblock(String partId) =>
      '/production/parts/$partId/unblock';

  // ── SECTION 9: Workshop Worker Tasks (/worker-tasks) ─────────────
  static const String workerTasks = '/worker-tasks';
  static String startWorkerTask(String id) => '/worker-tasks/$id/start';
  static String completeWorkerTask(String id) => '/worker-tasks/$id/complete';
  static String reportWorkerTaskFailure(String id) =>
      '/worker-tasks/$id/report-failure';

  // ── SECTION 10: AWS S3 Cloud Storage (/storage) ──────────────────
  static const String storageUploadUrl = '/storage/upload-url';
  static const String storagePresignedUrl = '/storage/presigned-url';
  static const String storageDownloadUrl = '/storage/download-url';

  // ── SECTION 10B: PaddleOCR Spec Extraction (/ocr) ───────────────
  static const String ocrExtractCad = '/ocr/extract-cad';

  // ── SECTION 11: Master Raw Materials & Pricing (/materials) ─────
  static const String materials = '/materials';
  static String materialDetails(String id) => '/materials/$id';
  static String updateMaterialRate(String id) => '/materials/$id/rate';

  // ── SECTION 12: Vault & Safe Inventory Stock (/inventory) ─────────
  static const String inventory = '/inventory';
  static String inventoryDetails(String id) => '/inventory/$id';

  // ── SECTION 13: Floor Directives & Voice Notes (/directives) ──────
  static const String directives = '/directives';
  static String acknowledgeDirective(String id) =>
      '/directives/$id/acknowledge';

  // ── SECTION 14: System & Database Health (/health) ───────────────
  static const String health = '/health';

  // ── SECTION 15: Stockist Material Allocation & Issuances (/issuances)
  static const String issuancesPendingQueue = '/issuances/pending-queue';
  static String issueOrderPartMaterials(String orderPartId) =>
      '/issuances/order-part/$orderPartId/issue';
  static String getIssuanceByOrderPart(String orderPartId) =>
      '/issuances/order-part/$orderPartId';
  static String reconcileIssuance(String id) => '/issuances/$id/reconcile';
  static const String issuances = '/issuances';
}
