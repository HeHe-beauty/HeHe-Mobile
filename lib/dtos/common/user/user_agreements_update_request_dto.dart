class UserAgreementsUpdateRequestDto {
  final bool? pushAgreed;
  final bool? nightAgreed;
  final bool? mktAgreed;

  const UserAgreementsUpdateRequestDto({
    this.pushAgreed,
    this.nightAgreed,
    this.mktAgreed,
  });

  Map<String, dynamic> toJson() {
    return {
      if (pushAgreed != null) 'pushAgreed': pushAgreed,
      if (nightAgreed != null) 'nightAgreed': nightAgreed,
      if (mktAgreed != null) 'mktAgreed': mktAgreed,
    };
  }
}
