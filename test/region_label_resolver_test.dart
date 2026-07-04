import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hehe/utils/region_label_resolver.dart';

void main() {
  test('formats Korean district and neighborhood', () {
    const placemark = Placemark(
      administrativeArea: '서울특별시',
      locality: '강남구',
      subLocality: '역삼동',
    );

    expect(RegionLabelResolver.formatPlacemark(placemark), '강남구 역삼동');
  });

  test('removes duplicated region parts', () {
    const placemark = Placemark(
      subAdministrativeArea: '강남구',
      locality: '강남구',
      subLocality: '역삼동',
    );

    expect(RegionLabelResolver.formatPlacemark(placemark), '강남구 역삼동');
  });

  test('uses available administrative fields as fallback', () {
    const placemark = Placemark(administrativeArea: '서울특별시', locality: '서울특별시');

    expect(RegionLabelResolver.formatPlacemark(placemark), '서울특별시');
  });

  test('returns null when the placemark has no region information', () {
    expect(RegionLabelResolver.formatPlacemark(const Placemark()), isNull);
  });
}
