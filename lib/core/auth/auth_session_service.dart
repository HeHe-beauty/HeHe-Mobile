import '../../data/article/article_repository.dart';
import '../../data/equipment/equip_repository.dart';
import '../../data/hospital/hospital_repository.dart';
import '../../data/schedule/schedule_repository.dart';
import '../common/app_settings_state.dart';
import '../common/favorite_store.dart';
import 'auth_session_store.dart';
import 'auth_state.dart';

class AuthSessionService {
  const AuthSessionService._();

  static Future<void> clearLocalSession() async {
    FavoriteStore.instance.clear();
    ArticleRepository.clearCache();
    EquipRepository.clearCache();
    HospitalRepository.clearCache();
    ScheduleRepository.invalidateReadCaches();
    AppSettingsState.setPushEnabled(false);
    await AuthSessionStore.clear();
    AuthState.logOut();
  }
}
