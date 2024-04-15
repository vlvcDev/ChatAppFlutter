import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';

class MessagesRecord extends FirestoreRecord {
  MessagesRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "conversation_id" field.
  DocumentReference? _conversationId;
  DocumentReference? get conversationId => _conversationId;
  bool hasConversationId() => _conversationId != null;

  // "content" field.
  String? _content;
  String get content => _content ?? '';
  bool hasContent() => _content != null;

  // "date_time" field.
  DateTime? _dateTime;
  DateTime? get dateTime => _dateTime;
  bool hasDateTime() => _dateTime != null;

  // "uid" field.
  DocumentReference? _uid;
  DocumentReference? get uid => _uid;
  bool hasUid() => _uid != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _conversationId = snapshotData['conversation_id'] as DocumentReference?;
    _content = snapshotData['content'] as String?;
    _dateTime = snapshotData['date_time'] as DateTime?;
    _uid = snapshotData['uid'] as DocumentReference?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('messages')
          : FirebaseFirestore.instance.collectionGroup('messages');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('messages').doc(id);

  static Stream<MessagesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MessagesRecord.fromSnapshot(s));

  static Future<MessagesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MessagesRecord.fromSnapshot(s));

  static MessagesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MessagesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MessagesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MessagesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MessagesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MessagesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMessagesRecordData({
  DocumentReference? conversationId,
  String? content,
  DateTime? dateTime,
  DocumentReference? uid,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'conversation_id': conversationId,
      'content': content,
      'date_time': dateTime,
      'uid': uid,
    }.withoutNulls,
  );

  return firestoreData;
}

class MessagesRecordDocumentEquality implements Equality<MessagesRecord> {
  const MessagesRecordDocumentEquality();

  @override
  bool equals(MessagesRecord? e1, MessagesRecord? e2) {
    return e1?.conversationId == e2?.conversationId &&
        e1?.content == e2?.content &&
        e1?.dateTime == e2?.dateTime &&
        e1?.uid == e2?.uid;
  }

  @override
  int hash(MessagesRecord? e) => const ListEquality()
      .hash([e?.conversationId, e?.content, e?.dateTime, e?.uid]);

  @override
  bool isValidKey(Object? o) => o is MessagesRecord;
}
