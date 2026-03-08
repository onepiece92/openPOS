import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/services/audit_service.dart';
import 'package:pos_app/core/providers/database_provider.dart';

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(ref.watch(databaseProvider));
});
