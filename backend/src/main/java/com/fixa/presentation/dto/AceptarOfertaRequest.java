package com.fixa.presentation.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record AceptarOfertaRequest(
    String subastaId,
    UUID trabajadorId,
    BigDecimal montoAcordado
) {}
