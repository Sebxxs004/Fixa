package com.fixa.presentation.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record BroadcastRequest(
    Integer categoriaId,
    Double latitud,
    Double longitud,
    @JsonProperty("subastaId") String subastaId
) {}
