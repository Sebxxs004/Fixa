package com.fixa.presentation.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record CrearOrdenRequest(
    String subastaFirebaseId,
    UUID trabajadorId,
    Integer categoriaId,
    Boolean esVisitaDiagnostico,
    BigDecimal precioDiagnostico,
    Double origenLatitud,
    Double origenLongitud,
    String idempotencyKey
) {}
