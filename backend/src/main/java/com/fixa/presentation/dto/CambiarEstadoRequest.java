package com.fixa.presentation.dto;

public record CambiarEstadoRequest(
    String nuevoEstado,
    Double latitud,
    Double longitud
) {}
