package com.fixa.presentation.controller;

import com.fixa.core.usecase.BroadcastSubastaUseCase;
import com.fixa.presentation.dto.BroadcastRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auctions")
public class AuctionController {

    private final BroadcastSubastaUseCase broadcastSubastaUseCase;

    public AuctionController(BroadcastSubastaUseCase broadcastSubastaUseCase) {
        this.broadcastSubastaUseCase = broadcastSubastaUseCase;
    }

    @PostMapping("/broadcast")
    public ResponseEntity<Void> iniciarBroadcast(@RequestBody BroadcastRequest request) {
        broadcastSubastaUseCase.ejecutarBroadcast(request);
        // Retornamos 202 Accepted de inmediato sin exponer datos internos o listados de trabajadores
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }
}
