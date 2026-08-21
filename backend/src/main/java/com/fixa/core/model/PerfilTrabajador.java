package com.fixa.core.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record PerfilTrabajador(
    UUID usuarioId,
    String documentoIdentidad,
    String estadoVerificacion,
    BigDecimal calificacionPromedio,
    Integer totalTrabajosCompletados,
    Coordenadas ubicacionActual,
    OffsetDateTime ultimaActualizacionGps
) {}
