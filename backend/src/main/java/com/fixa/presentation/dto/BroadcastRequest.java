package com.fixa.presentation.dto;

public record BroadcastRequest(
    Integer categoriaId,
    Double latitud,
    Double longitud
) {}
