// lib/models/quran_test_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class QuranTest {
  final String? id; // مُعرّف الوثيقة في Firestore
  final String studentId;
  final String studentName; // يجب جلبها من UsersProvider
  final String teacherId; // يجب جلبها
  final String testedBy; // مُعرّف الأستاذ المُختبِر
  final String testType;
  final int partNumber;
  final double score;
  final String date; // يفضل استخدام DateTime
  final String? notes;
  final String createdBy;
  final DateTime? createdAt; // FieldValue.serverTimestamp()

  QuranTest({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.testedBy,
    required this.testType,
    required this.partNumber,
    required this.score,
    required this.date,
    this.notes,
    required this.createdBy,
    this.createdAt,
  });

  // 1. دالة التحويل من الكلاس إلى الخريطة (لإرسالها إلى Firestore)
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'testedBy': testedBy,
      'testType': testType,
      'partNumber': partNumber,
      'score': score,
      'date': date,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  // 2. دالة التحويل من الخريطة إلى الكلاس (لجلبها من Firestore)
  factory QuranTest.fromMap(Map<String, dynamic> map, String id) {
    return QuranTest(
      id: id,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      teacherId: map['teacherId'] as String,
      testedBy: map['testedBy'] as String,
      testType: map['testType'] as String,
      partNumber: (map['partNumber'] as num).toInt(),
      score: (map['score'] as num).toDouble(),
      date: map['date'] as String,
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}