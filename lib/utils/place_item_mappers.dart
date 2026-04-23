import '../dtos/common/bookmark/bookmark_dto.dart';
import '../dtos/common/contact/contact_dto.dart';
import '../dtos/common/hospital/hospital_detail_dto.dart';
import '../dtos/common/hospital/hospital_dto.dart';
import '../dtos/common/recent_view/recent_view_dto.dart';
import '../models/place_item.dart';

PlaceItem placeItemFromHospital(
  HospitalDto hospital, {
  required double latitude,
  required double longitude,
}) {
  return PlaceItem(
    hospitalId: hospital.hospitalId,
    id: 'hospital_${hospital.hospitalId}',
    name: hospital.name,
    tags: hospital.tags,
    description: '',
    address: hospital.address,
    isBookmarked: hospital.isBookmarked,
    latitude: latitude,
    longitude: longitude,
  );
}

PlaceItem placeItemFromHospitalDetail(
  HospitalDetailDto hospital, {
  required PlaceItem fallbackPlace,
}) {
  return PlaceItem(
    hospitalId: hospital.hospitalId,
    id: fallbackPlace.id,
    name: hospital.name,
    tags: hospital.tags,
    description: fallbackPlace.description,
    address: hospital.address,
    isBookmarked: hospital.isBookmarked,
    latitude: hospital.lat,
    longitude: hospital.lng,
  );
}

PlaceItem placeItemFromBookmark(BookmarkDto bookmark) {
  return PlaceItem(
    hospitalId: bookmark.hospitalId,
    id: 'hospital_${bookmark.hospitalId}',
    name: bookmark.name,
    tags: bookmark.tags,
    description: '',
    address: bookmark.address,
    isBookmarked: bookmark.isBookmarked,
    latitude: 0,
    longitude: 0,
  );
}

PlaceItem placeItemFromContact(ContactDto contact) {
  return PlaceItem(
    hospitalId: contact.hospitalId,
    id: 'hospital_${contact.hospitalId}',
    name: contact.hospitalName,
    tags: contact.tags,
    description: '',
    address: contact.address,
    isBookmarked: contact.isBookmarked,
    latitude: 0,
    longitude: 0,
  );
}

PlaceItem placeItemFromRecentView(RecentViewDto recentView) {
  return PlaceItem(
    hospitalId: recentView.hospitalId,
    id: 'hospital_${recentView.hospitalId}',
    name: recentView.name,
    tags: recentView.tags,
    description: '',
    address: recentView.address,
    isBookmarked: recentView.isBookmarked,
    latitude: 0,
    longitude: 0,
  );
}
