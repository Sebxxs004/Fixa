package com.fixa.core.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record OrdenServicio(
    UUID id,
    String subastaFirebaseId,
    UUID clienteId,
    UUID trabajadorId,
    Integer categoriaId,
    String estado,
    Boolean esVisitaDiagnostico,
    BigDecimal precioDiagnostico,
    BigDecimal precioFinal,
    BigDecimal comisionPlataforma,
    Coordenadas origenUbicacion,
    Boolean puntoNoRetornoCruzado,
    Integer tiempoEstimadoLlegadaMinutos,
    OffsetDateTime creadoEn,
    OffsetDateTime actualizadoEn
) {}
