import '../dtos/common/hospital/hospital_detail_dto.dart';
import '../dtos/common/hospital/hospital_dto.dart';
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
    isBookmarked: false,
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
    isBookmarked: fallbackPlace.isBookmarked,
    latitude: hospital.lat,
    longitude: hospital.lng,
  );
}
