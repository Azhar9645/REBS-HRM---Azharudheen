import '../models/employee_dto.dart';
import 'local_store.dart';

class EmployeeLocalDataSource {
  static const _key = 'employee';

  EmployeeDto? read() {
    final raw = LocalStore.employeeBox.get(_key);
    if (raw == null) return null;
    return EmployeeDto.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> save(EmployeeDto employee) =>
      LocalStore.employeeBox.put(_key, employee.toJson());
}
