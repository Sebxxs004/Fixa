import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Crea un documento de subasta en Firestore y retorna su ID auto-generado
  Future<String> crearSubasta({
    required double latitud,
    required double longitud,
    required int categoriaId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('No hay un usuario autenticado para crear la subasta.');
    }

    final docRef = await _firestore.collection('subastas').add({
      'cliente_id': currentUser.uid,
      'categoria_id': categoriaId,
      'latitud': latitud,
      'longitud': longitud,
      'estado': 'ABIERTA',
      'creado_en': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Escucha en tiempo real la subcolección de ofertas asociadas a una subasta específica
  Stream<List<Map<String, dynamic>>> escucharOfertas(String subastaId) {
    return _firestore
        .collection('subastas')
        .doc(subastaId)
        .collection('ofertas')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Agregamos el ID del documento al mapa
        return data;
      }).toList();
    });
  }
}
