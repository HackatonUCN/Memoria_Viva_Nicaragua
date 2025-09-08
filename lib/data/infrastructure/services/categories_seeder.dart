import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

class CategoriesSeeder {
  final FirebaseFirestore firestore;
  CategoriesSeeder(this.firestore);

  Future<int> seedMerge() async {
    final col = firestore.collection('categorias');

    final jsonStr = await rootBundle.loadString('assets/config/categories_seed.json');
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    int count = 0;

    final batch = firestore.batch();
    for (final item in data) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      // timestamps del lado del servidor
      map['fechaCreacion'] = FieldValue.serverTimestamp();
      map['fechaActualizacion'] = FieldValue.serverTimestamp();
      final doc = col.doc(id);
      batch.set(doc, map, SetOptions(merge: true));
      count++;
    }
    await batch.commit();
    return count;
  }
}


