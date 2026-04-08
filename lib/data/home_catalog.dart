import 'package:flutter/material.dart';
import '../models/content_item.dart';

class HomeCatalog {
  const HomeCatalog._();

  static const List<ContentItem> contents = [
    ContentItem(
      title: '생활 루틴 체크리스트',
      body:
          '시술이나 관리 전후에는 거창한 준비보다 기본 루틴을 점검하는 게 더 중요할 때가 많아요.\n\n수면, 수분, 염분, 면도 여부처럼 사소해 보이는 요소들이 실제 컨디션과 만족도에 영향을 줄 수 있어요.\n\n방문 전에는 내 상태를 짧게라도 체크해두면 훨씬 덜 흔들리고, 상담도 더 또렷하게 받을 수 있어요.',
      icon: Icons.checklist_rounded,
      author: '서비스명',
    ),
    ContentItem(
      title: '증상 기록으로 패턴 찾기',
      body:
          '한 번의 느낌만으로는 내 피부 반응이나 회복 패턴을 알기 어려워요.\n\n간단한 기록이라도 쌓이면 어떤 시점에 예민해지는지, 어떤 관리 후에 상태가 괜찮았는지를 보게 돼요.\n\n결국 기록은 정보를 모으는 게 아니라 다음 선택을 덜 불안하게 만드는 도구예요.',
      icon: Icons.insights_rounded,
      author: '서비스명',
    ),
    ContentItem(
      title: '병원 방문 전 준비',
      body:
          '병원을 방문할 때는 막연히 가기보다 내가 궁금한 점을 먼저 정리해두는 게 좋아요.\n\n가격, 주기, 통증, 사후관리처럼 꼭 확인해야 할 질문을 미리 적어두면 상담을 더 효율적으로 받을 수 있어요.\n\n짧게라도 기준을 정해두면 방문 이후 비교도 쉬워져요.',
      icon: Icons.local_hospital_rounded,
      author: '서비스명',
    ),
  ];
}
