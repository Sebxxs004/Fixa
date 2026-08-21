package com.fixa.core.model;

import java.time.OffsetDateTime;
import java.util.UUID;

public record Usuario(
    UUID id,
    String firebaseUid,
    String nombreCompleto,
    String telefono,
    String email,
    String rol,
    OffsetDateTime fechaCreacion,
    Boolean activo,
    String deviceToken
) {}
