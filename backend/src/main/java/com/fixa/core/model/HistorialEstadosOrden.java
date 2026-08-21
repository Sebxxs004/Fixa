package com.fixa.core.model;

import java.time.OffsetDateTime;
import java.util.UUID;

public record HistorialEstadosOrden(
    UUID id,
    UUID ordenId,
    String estadoAnterior,
    String estadoNuevo,
    UUID modificadoPor,
    String notas,
    OffsetDateTime fechaCambio
) {}
