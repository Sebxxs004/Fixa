package com.fixa.core.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record TransaccionPago(
    UUID id,
    UUID ordenId,
    String idempotencyKey,
    String tokenTransaccionPasarela,
    BigDecimal montoTotal,
    String tipoMovimiento,
    String estadoPago,
    OffsetDateTime fechaTransaccion
) {}
