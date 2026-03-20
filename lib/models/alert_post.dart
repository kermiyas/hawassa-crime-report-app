// lib/models/alert_post.dart

class AlertMedia {
  final String url;
  final String type;
  AlertMedia({required this.url, required this.type});
  factory AlertMedia.fromJson(Map<String, dynamic> j) =>
      AlertMedia(url: j['url'] ?? '', type: j['type'] ?? 'image');
}

class AlertPost {
  final int id;
  final String category;
  final String title;
  final String content;
  final String? publishedAt;
  final List<AlertMedia> mediaFiles;
  final int sightingsCount;
  final String? caseStatus; // active | arrested | found

  final String? subjectName;
  final String? nickname;
  final String? dateOfBirth;
  final String? height;
  final String? weight;
  final String? riskLevel;
  final String? committedCrime;
  final String? rewardInfo;
  final String? lastSeenLocation;
  final String? lastSeenDate;
  final String? clothingDescription;
  final int? age;
  final String? contactNumber;
  final String? itemDescription;
  final String? locationLost;

  AlertPost({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    this.publishedAt,
    required this.mediaFiles,
    required this.sightingsCount,
    this.caseStatus,
    this.subjectName,
    this.nickname,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.riskLevel,
    this.committedCrime,
    this.rewardInfo,
    this.lastSeenLocation,
    this.lastSeenDate,
    this.clothingDescription,
    this.age,
    this.contactNumber,
    this.itemDescription,
    this.locationLost,
  });

  factory AlertPost.fromJson(Map<String, dynamic> j) {
    List<AlertMedia> media = [];
    if (j['media_files'] != null) {
      media = (j['media_files'] as List)
          .map((m) => AlertMedia.fromJson(m))
          .toList();
    }
    return AlertPost(
      id:                   j['id'],
      category:             j['category'] ?? '',
      title:                j['title'] ?? '',
      content:              j['content'] ?? '',
      publishedAt:          j['published_at'],
      mediaFiles:           media,
      sightingsCount:       j['sightings_count'] ?? 0,
      caseStatus:           j['case_status'],
      subjectName:          j['subject_name'],
      nickname:             j['nickname'],
      dateOfBirth:          j['date_of_birth'],
      height:               j['height'],
      weight:               j['weight'],
      riskLevel:            j['risk_level'],
      committedCrime:       j['committed_crime'],
      rewardInfo:           j['reward_info'],
      lastSeenLocation:     j['last_seen_location'],
      lastSeenDate:         j['last_seen_date'],
      clothingDescription:  j['clothing_description'],
      age:                  j['age'],
      contactNumber:        j['contact_number'],
      itemDescription:      j['item_description'],
      locationLost:         j['location_lost'],
    );
  }

  String get displayName {
    if (category == 'Missing Item') return itemDescription ?? title;
    return subjectName ?? title;
  }
}