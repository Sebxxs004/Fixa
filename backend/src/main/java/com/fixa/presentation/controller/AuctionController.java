package com.fixa.presentation.controller;

import com.fixa.core.usecase.AceptarOfertaUseCase;
import com.fixa.core.usecase.BroadcastSubastaUseCase;
import com.fixa.presentation.dto.AceptarOfertaRequest;
import com.fixa.presentation.dto.BroadcastRequest;
import com.fixa.presentation.dto.OrdenResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auctions")
public class AuctionController {

    private final BroadcastSubastaUseCase broadcastSubastaUseCase;
    private final AceptarOfertaUseCase aceptarOfertaUseCase;

    public AuctionController(BroadcastSubastaUseCase broadcastSubastaUseCase, AceptarOfertaUseCase aceptarOfertaUseCase) {
        this.broadcastSubastaUseCase = broadcastSubastaUseCase;
        this.aceptarOfertaUseCase = aceptarOfertaUseCase;
    }

    @PostMapping("/broadcast")
    public ResponseEntity<Void> iniciarBroadcast(@RequestBody BroadcastRequest request) {
        broadcastSubastaUseCase.ejecutarBroadcast(request);
        // Retornamos 202 Accepted de inmediato sin exponer datos internos o listados de trabajadores
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }

    @PostMapping("/accept")
    public ResponseEntity<OrdenResponse> aceptarOferta(@RequestBody AceptarOfertaRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            throw new IllegalStateException("Usuario no autenticado");
        }
        
        String authenticatedFirebaseUid = authentication.getName();
        OrdenResponse response = aceptarOfertaUseCase.ejecutarAceptarOferta(request, authenticatedFirebaseUid);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
