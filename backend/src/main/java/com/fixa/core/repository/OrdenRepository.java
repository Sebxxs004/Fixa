package com.fixa.core.repository;

import com.fixa.core.model.OrdenServicio;
import java.util.Optional;
import java.util.UUID;

public interface OrdenRepository {
    Optional<OrdenServicio> findById(UUID id);
    Optional<OrdenServicio> findBySubastaFirebaseId(String subastaFirebaseId);
    OrdenServicio save(OrdenServicio orden, String idempotencyKey);
    boolean existsTransaccionByIdempotencyKey(String idempotencyKey);
    double calculateDistanceInMeters(UUID ordenId, double lat, double lon);
    void registrarCambioEstado(UUID ordenId, String estadoAnterior, String estadoNuevo, UUID modificadoPor, String notas);
}
