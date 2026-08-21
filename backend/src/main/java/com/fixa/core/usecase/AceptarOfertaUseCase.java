package com.fixa.core.usecase;

import com.fixa.core.model.Coordenadas;
import com.fixa.core.model.OrdenServicio;
import com.fixa.core.repository.OrdenRepository;
import com.fixa.infrastructure.persistence.entity.UsuarioEntity;
import com.fixa.infrastructure.persistence.repository.UsuarioRepository;
import com.fixa.presentation.dto.AceptarOfertaRequest;
import com.fixa.presentation.dto.OrdenResponse;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class AceptarOfertaUseCase {

    private final OrdenRepository ordenRepository;
    private final UsuarioRepository usuarioRepository;

    public AceptarOfertaUseCase(OrdenRepository ordenRepository, UsuarioRepository usuarioRepository) {
        this.ordenRepository = ordenRepository;
        this.usuarioRepository = usuarioRepository;
    }

    @Transactional
    public OrdenResponse ejecutarAceptarOferta(AceptarOfertaRequest request, String authenticatedFirebaseUid) {
        try {
            // 1. Obtener los datos de la subasta directamente de Firestore
            Firestore db = FirestoreClient.getFirestore();
            DocumentSnapshot doc = db.collection("subastas").document(request.subastaId()).get().get();

            if (!doc.exists()) {
                throw new IllegalArgumentException("La subasta con ID " + request.subastaId() + " no existe en Firestore.");
            }

            String clienteFirebaseUid = doc.getString("cliente_id");
            
            // 2. Validar que quien ejecuta la acción sea el dueño de la subasta
            if (clienteFirebaseUid == null || !clienteFirebaseUid.equals(authenticatedFirebaseUid)) {
                throw new AccessDeniedException("No tienes permisos para aceptar ofertas en esta subasta.");
            }

            // 3. Extraer detalles geográficos y de negocio de la subasta en Firestore
            Long categoriaIdLong = doc.getLong("categoria_id");
            Integer categoriaId = (categoriaIdLong != null) ? categoriaIdLong.intValue() : 1;
            Double lat = doc.getDouble("latitud");
            Double lon = doc.getDouble("longitud");

            UsuarioEntity cliente = usuarioRepository.findByFirebaseUid(clienteFirebaseUid)
                    .orElseThrow(() -> new IllegalArgumentException("Cliente no registrado en PostgreSQL."));

            // 4. Crear la orden transaccional en PostgreSQL con estado inicial ACEPTADA_EN_CAMINO
            OrdenServicio nuevaOrden = new OrdenServicio(
                    null,
                    request.subastaId(),
                    cliente.getId(),
                    request.trabajadorId(),
                    categoriaId,
                    "ACEPTADA_EN_CAMINO",
                    true, // esVisitaDiagnostico por defecto para MVP
                    request.montoAcordado(), // Precio acordado para el diagnóstico
                    null,
                    null,
                    new Coordenadas(lat, lon),
                    false,
                    null,
                    OffsetDateTime.now(),
                    OffsetDateTime.now()
            );

            // Generamos un hash de idempotencia basado en el subastaId y trabajadorId para evitar duplicaciones
            String idempotencyKey = "accept_" + request.subastaId() + "_" + request.trabajadorId();
            OrdenServicio guardada = ordenRepository.save(nuevaOrden, idempotencyKey);

            // Registrar historial del cambio de estado inicial
            ordenRepository.registrarCambioEstado(
                    guardada.id(), 
                    null, 
                    "ACEPTADA_EN_CAMINO", 
                    cliente.getId(), 
                    "Oferta aceptada del trabajador " + request.trabajadorId()
            );

            // 5. Eliminar el documento temporal de la subasta en Firestore para cerrar la sala de subastas
            db.collection("subastas").document(request.subastaId()).delete().get();
            System.out.println("Sala de subasta " + request.subastaId() + " eliminada de Firestore exitosamente.");

            return mapToResponse(guardada);

        } catch (Exception e) {
            throw new RuntimeException("Error al procesar la aceptación de la oferta: " + e.getMessage(), e);
        }
    }

    private OrdenResponse mapToResponse(OrdenServicio orden) {
        return new OrdenResponse(
                orden.id(),
                orden.subastaFirebaseId(),
                orden.clienteId(),
                orden.trabajadorId(),
                orden.categoriaId(),
                orden.estado(),
                orden.esVisitaDiagnostico(),
                orden.precioDiagnostico(),
                orden.precioFinal(),
                orden.comisionPlataforma(),
                orden.origenUbicacion() != null ? orden.origenUbicacion().latitud() : null,
                orden.origenUbicacion() != null ? orden.origenUbicacion().longitud() : null,
                orden.puntoNoRetornoCruzado(),
                orden.tiempoEstimadoLlegadaMinutos(),
                orden.creadoEn(),
                orden.actualizadoEn()
        );
    }
}
