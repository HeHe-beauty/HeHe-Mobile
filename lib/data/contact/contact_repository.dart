import '../../dtos/common/contact/contact_api.dart';
import '../../dtos/common/contact/contact_create_request_dto.dart';
import '../../dtos/common/contact/contact_dto.dart';

class ContactRepository {
  static const callContactType = 'CALL';

  static Future<List<ContactDto>> getContacts({required String accessToken}) {
    return ContactApi.fetchContacts(accessToken: accessToken);
  }

  static Future<void> addCallContact({
    required String accessToken,
    required int hospitalId,
  }) {
    return ContactApi.createContact(
      accessToken: accessToken,
      request: ContactCreateRequestDto(
        hospitalId: hospitalId,
        contactType: callContactType,
      ),
    );
  }

  static Future<void> deleteContact({
    required String accessToken,
    required int contactId,
  }) {
    return ContactApi.deleteContact(
      accessToken: accessToken,
      contactId: contactId,
    );
  }
}
