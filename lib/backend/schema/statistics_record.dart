import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class StatisticsRecord extends FirestoreRecord {
  StatisticsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "demeanor" field.
  int? _demeanor;
  int get demeanor => _demeanor ?? 0;
  bool hasDemeanor() => _demeanor != null;

  // "most_active_time" field.
  String? _mostActiveTime;
  String get mostActiveTime => _mostActiveTime ?? '';
  bool hasMostActiveTime() => _mostActiveTime != null;

  // "unique_words" field.
  int? _uniqueWords;
  int get uniqueWords => _uniqueWords ?? 0;
  bool hasUniqueWords() => _uniqueWords != null;

  // "most_frequent_topic" field.
  String? _mostFrequentTopic;
  String get mostFrequentTopic => _mostFrequentTopic ?? '';
  bool hasMostFrequentTopic() => _mostFrequentTopic != null;

  // "most_active_day" field.
  String? _mostActiveDay;
  String get mostActiveDay => _mostActiveDay ?? '';
  bool hasMostActiveDay() => _mostActiveDay != null;

  // "uid" field.
  DocumentReference? _uid;
  DocumentReference? get uid => _uid;
  bool hasUid() => _uid != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _demeanor = castToType<int>(snapshotData['demeanor']);
    _mostActiveTime = snapshotData['most_active_time'] as String?;
    _uniqueWords = castToType<int>(snapshotData['unique_words']);
    _mostFrequentTopic = snapshotData['most_frequent_topic'] as String?;
    _mostActiveDay = snapshotData['most_active_day'] as String?;
    _uid = snapshotData['uid'] as DocumentReference?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('statistics')
          : FirebaseFirestore.instance.collectionGroup('statistics');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('statistics').doc(id);

  static Stream<StatisticsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => StatisticsRecord.fromSnapshot(s));

  static Future<StatisticsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => StatisticsRecord.fromSnapshot(s));

  static StatisticsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      StatisticsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static StatisticsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      StatisticsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'StatisticsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is StatisticsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createStatisticsRecordData({
  int? demeanor,
  String? mostActiveTime,
  int? uniqueWords,
  String? mostFrequentTopic,
  String? mostActiveDay,
  DocumentReference? uid,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'demeanor': demeanor,
      'most_active_time': mostActiveTime,
      'unique_words': uniqueWords,
      'most_frequent_topic': mostFrequentTopic,
      'most_active_day': mostActiveDay,
      'uid': uid,
    }.withoutNulls,
  );

  return firestoreData;
}

class StatisticsRecordDocumentEquality implements Equality<StatisticsRecord> {
  const StatisticsRecordDocumentEquality();

  @override
  bool equals(StatisticsRecord? e1, StatisticsRecord? e2) {
    return e1?.demeanor == e2?.demeanor &&
        e1?.mostActiveTime == e2?.mostActiveTime &&
        e1?.uniqueWords == e2?.uniqueWords &&
        e1?.mostFrequentTopic == e2?.mostFrequentTopic &&
        e1?.mostActiveDay == e2?.mostActiveDay &&
        e1?.uid == e2?.uid;
  }

  @override
  int hash(StatisticsRecord? e) => const ListEquality().hash([
        e?.demeanor,
        e?.mostActiveTime,
        e?.uniqueWords,
        e?.mostFrequentTopic,
        e?.mostActiveDay,
        e?.uid
      ]);

  @override
  bool isValidKey(Object? o) => o is StatisticsRecord;
}
