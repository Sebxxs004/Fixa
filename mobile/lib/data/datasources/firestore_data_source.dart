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

  /// Crea un documento de subasta en Firestore y retorna su ID auto-generado de forma instantánea
  Future<String> crearSubasta({
    required double latitud,
    required double longitud,
    required int categoriaId,
    String? categoriaNombre,
    String? descripcion,
    List<String> fotos = const [],
  }) async {
    final currentUser = _auth.currentUser;
    final String clienteId = currentUser?.uid ?? 'cliente_anonimo_dev';

    final docRef = _firestore.collection('subastas').doc();
    final String subastaId = docRef.id;

    try {
      await docRef.set({
        'cliente_id': clienteId,
        'categoria_id': categoriaId,
        'categoria_nombre': categoriaNombre ?? 'General',
        'descripcion': descripcion ?? '',
        'fotos': fotos,
        'latitud': latitud,
        'longitud': longitud,
        'estado': 'ABIERTA',
        'creado_en': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Si el canal web tarda en responder online, el documento ya tiene su ID y se procesará en Firestore
    }

    return subastaId;
  }

  /// Envía una oferta de un trabajador a una subasta específica en Firestore de forma instantánea
  Future<void> crearOferta({
    required String subastaId,
    required String trabajadorId,
    required String nombreTrabajador,
    required double precio,
  }) async {
    final docRef = _firestore
        .collection('subastas')
        .doc(subastaId)
        .collection('ofertas')
        .doc();

    try {
      await docRef.set({
        'trabajador_id': trabajadorId,
        'nombre_trabajador': nombreTrabajador,
        'precio': precio,
        'creado_en': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 3));
    } catch (_) {
      // En caso de latencia de red, la oferta se registra en la cola offline de Firestore
    }
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
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Escucha en tiempo real todas las subastas en Firestore y filtra las abiertas
  Stream<List<Map<String, dynamic>>> escucharSubastasAbiertas() {
    return _firestore.collection('subastas').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((subasta) =>
              subasta['estado'] == null || subasta['estado'] == 'ABIERTA')
          .toList();
    });
  }
}
