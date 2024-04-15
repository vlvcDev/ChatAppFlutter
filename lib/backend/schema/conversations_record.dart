import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ConversationsRecord extends FirestoreRecord {
  ConversationsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "post_user" field.
  DocumentReference? _postUser;
  DocumentReference? get postUser => _postUser;
  bool hasPostUser() => _postUser != null;

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "last_messaged" field.
  DateTime? _lastMessaged;
  DateTime? get lastMessaged => _lastMessaged;
  bool hasLastMessaged() => _lastMessaged != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _postUser = snapshotData['post_user'] as DocumentReference?;
    _id = castToType<int>(snapshotData['id']);
    _title = snapshotData['title'] as String?;
    _lastMessaged = snapshotData['last_messaged'] as DateTime?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('Conversations')
          : FirebaseFirestore.instance.collectionGroup('Conversations');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('Conversations').doc(id);

  static Stream<ConversationsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ConversationsRecord.fromSnapshot(s));

  static Future<ConversationsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ConversationsRecord.fromSnapshot(s));

  static ConversationsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ConversationsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ConversationsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ConversationsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ConversationsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ConversationsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createConversationsRecordData({
  DocumentReference? postUser,
  int? id,
  String? title,
  DateTime? lastMessaged,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'post_user': postUser,
      'id': id,
      'title': title,
      'last_messaged': lastMessaged,
    }.withoutNulls,
  );

  return firestoreData;
}

class ConversationsRecordDocumentEquality
    implements Equality<ConversationsRecord> {
  const ConversationsRecordDocumentEquality();

  @override
  bool equals(ConversationsRecord? e1, ConversationsRecord? e2) {
    return e1?.postUser == e2?.postUser &&
        e1?.id == e2?.id &&
        e1?.title == e2?.title &&
        e1?.lastMessaged == e2?.lastMessaged;
  }

  @override
  int hash(ConversationsRecord? e) => const ListEquality()
      .hash([e?.postUser, e?.id, e?.title, e?.lastMessaged]);

  @override
  bool isValidKey(Object? o) => o is ConversationsRecord;
}
