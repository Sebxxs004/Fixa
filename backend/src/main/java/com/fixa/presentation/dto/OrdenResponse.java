package com.fixa.presentation.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record OrdenResponse(
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
    Double origenLatitud,
    Double origenLongitud,
    Boolean puntoNoRetornoCruzado,
    Integer tiempoEstimadoLlegadaMinutos,
    OffsetDateTime creadoEn,
    OffsetDateTime actualizadoEn
) {}
