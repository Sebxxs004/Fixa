package com.fixa.core.model;

import java.math.BigDecimal;

public record CategoriaServicio(
    Integer id,
    String nombre,
    BigDecimal tarifaBaseDiagnostico,
    Boolean activo
) {}
