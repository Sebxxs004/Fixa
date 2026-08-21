package com.fixa.presentation.controller;

import com.fixa.core.usecase.GestionarOrdenUseCase;
import com.fixa.infrastructure.persistence.entity.UsuarioEntity;
import com.fixa.infrastructure.persistence.repository.UsuarioRepository;
import com.fixa.presentation.dto.CambiarEstadoRequest;
import com.fixa.presentation.dto.CrearOrdenRequest;
import com.fixa.presentation.dto.OrdenResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/orders")
public class OrdenController {

    private final GestionarOrdenUseCase gestionarOrdenUseCase;
    private final UsuarioRepository usuarioRepository;

    public OrdenController(GestionarOrdenUseCase gestionarOrdenUseCase, UsuarioRepository usuarioRepository) {
        this.gestionarOrdenUseCase = gestionarOrdenUseCase;
        this.usuarioRepository = usuarioRepository;
    }

    @PostMapping
    public ResponseEntity<OrdenResponse> crearOrden(@RequestBody CrearOrdenRequest request) {
        UUID clienteId = obtenerUsuarioIdAutenticado();
        OrdenResponse response = gestionarOrdenUseCase.crearOrden(request, clienteId);
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<OrdenResponse> cambiarEstado(
            @PathVariable("id") UUID id,
            @RequestBody CambiarEstadoRequest request) {
        UUID usuarioId = obtenerUsuarioIdAutenticado();
        OrdenResponse response = gestionarOrdenUseCase.cambiarEstado(
                id, 
                request.nuevoEstado(), 
                request.latitud(), 
                request.longitud(), 
                usuarioId
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<OrdenResponse> cancelarOrden(
            @PathVariable("id") UUID id,
            @RequestBody CambiarEstadoRequest request) { // Reusamos CambiarEstadoRequest para lat/lon de la cancelación
        UUID usuarioId = obtenerUsuarioIdAutenticado();
        OrdenResponse response = gestionarOrdenUseCase.cancelarOrden(
                id, 
                request.latitud(), 
                request.longitud(), 
                usuarioId, 
                "Cancelado a través de la API móvil por usuario"
        );
        return ResponseEntity.ok(response);
    }

    private UUID obtenerUsuarioIdAutenticado() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            throw new IllegalStateException("Usuario no autenticado en el contexto de seguridad");
        }
        
        String principal = authentication.getName(); // Contiene el email o UID de Firebase Auth
        
        // En producción el UID vendrá en el token. Mapeamos contra nuestra base de datos relacional
        UsuarioEntity usuario = usuarioRepository.findByFirebaseUid(principal)
                .or(() -> usuarioRepository.findByEmail(principal)) // Fallback por desarrollo local
                .orElseThrow(() -> new IllegalArgumentException("Usuario no registrado en la base de datos local: " + principal));
        
        return usuario.getId();
    }
}
