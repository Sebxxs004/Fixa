package com.fixa.core.usecase;

import com.fixa.core.model.Coordenadas;
import com.fixa.core.model.OrdenServicio;
import com.fixa.core.repository.OrdenRepository;
import com.fixa.presentation.dto.CrearOrdenRequest;
import com.fixa.presentation.dto.OrdenResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class GestionarOrdenUseCase {

    private final OrdenRepository ordenRepository;

    public GestionarOrdenUseCase(OrdenRepository ordenRepository) {
        this.ordenRepository = ordenRepository;
    }

    @Transactional
    public OrdenResponse crearOrden(CrearOrdenRequest request, UUID clienteId) {
        // Validación de idempotencia
        if (ordenRepository.existsTransaccionByIdempotencyKey(request.idempotencyKey())) {
            OrdenServicio existente = ordenRepository.findBySubastaFirebaseId(request.subastaFirebaseId())
                    .orElseThrow(() -> new IllegalStateException("Transacción idempotente ya registrada pero orden no encontrada"));
            return mapToResponse(existente);
        }

        OrdenServicio nuevaOrden = new OrdenServicio(
                null,
                request.subastaFirebaseId(),
                clienteId,
                request.trabajadorId(),
                request.categoriaId(),
                "ACEPTADA_EN_CAMINO", // Estado inicial de la orden transaccional
                request.esVisitaDiagnostico(),
                request.precioDiagnostico(),
                null, // Precio final nulo hasta visita en sitio
                null, // Comisión nula inicialmente
                new Coordenadas(request.origenLatitud(), request.origenLongitud()),
                false,
                null,
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        OrdenServicio guardada = ordenRepository.save(nuevaOrden, request.idempotencyKey());
        ordenRepository.registrarCambioEstado(guardada.id(), null, "ACEPTADA_EN_CAMINO", clienteId, "Creación de orden aceptada desde subasta");

        return mapToResponse(guardada);
    }

    @Transactional
    public OrdenResponse cambiarEstado(UUID id, String nuevoEstado, double lat, double lon, UUID modificadoPor) {
        OrdenServicio orden = ordenRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Orden no encontrada: " + id));

        String estadoAnterior = orden.estado();
        
        // Validación básica de transiciones permitidas
        validarTransicion(estadoAnterior, nuevoEstado);

        // Si cambia a EN_SITIO, verificamos si está cerca (ej. < 150 metros) o simplemente actualizamos el estado
        boolean puntoNoRetorno = orden.puntoNoRetornoCruzado();
        if ("EN_SITIO".equals(nuevoEstado)) {
            puntoNoRetorno = true; // Si llegó al sitio, por definición ya cruzó el punto de no retorno
        }

        OrdenServicio actualizada = new OrdenServicio(
                orden.id(),
                orden.subastaFirebaseId(),
                orden.clienteId(),
                orden.trabajadorId(),
                orden.categoriaId(),
                nuevoEstado,
                orden.esVisitaDiagnostico(),
                orden.precioDiagnostico(),
                orden.precioFinal(),
                orden.comisionPlataforma(),
                orden.origenUbicacion(),
                puntoNoRetorno,
                orden.tiempoEstimadoLlegadaMinutos(),
                orden.creadoEn(),
                OffsetDateTime.now()
        );

        OrdenServicio guardada = ordenRepository.save(actualizada, null);
        ordenRepository.registrarCambioEstado(id, estadoAnterior, nuevoEstado, modificadoPor, "Cambio de estado manual");

        return mapToResponse(guardada);
    }

    @Transactional
    public OrdenResponse cancelarOrden(UUID id, double lat, double lon, UUID modificadoPor, String notas) {
        OrdenServicio orden = ordenRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Orden no encontrada: " + id));

        String estadoAnterior = orden.estado();
        
        // Solo se pueden cancelar órdenes que están en camino
        if (!"ACEPTADA_EN_CAMINO".equals(estadoAnterior)) {
            throw new IllegalStateException("No se puede cancelar una orden en el estado: " + estadoAnterior);
        }

        String nuevoEstado;
        boolean esCliente = modificadoPor.equals(orden.clienteId());

        if (esCliente) {
            // Calcular distancia al cliente para evaluar Punto de No Retorno
            double distanciaMeters = ordenRepository.calculateDistanceInMeters(id, lat, lon);
            
            // Regla: Punto de no retorno cruzado si está a menos de 1000 metros (1km)
            boolean puntoNoRetornoCruzado = distanciaMeters <= 1000;

            if (puntoNoRetornoCruzado) {
                nuevoEstado = "CANCELADA_CON_PENALIZACION_CLIENTE";
                notas = "[Punto de No Retorno Cruzado - Distancia: " + (int)distanciaMeters + "m] " + notas;
            } else {
                nuevoEstado = "CANCELADA_GRATIS_CLIENTE";
                notas = "[Cancelación Gracia - Distancia: " + (int)distanciaMeters + "m] " + notas;
            }
        } else {
            // Cancelado por el Trabajador
            nuevoEstado = "CANCELADA_TRABAJADOR";
        }

        OrdenServicio actualizada = new OrdenServicio(
                orden.id(),
                orden.subastaFirebaseId(),
                orden.clienteId(),
                orden.trabajadorId(),
                orden.categoriaId(),
                nuevoEstado,
                orden.esVisitaDiagnostico(),
                orden.precioDiagnostico(),
                orden.precioFinal(),
                orden.comisionPlataforma(),
                orden.origenUbicacion(),
                orden.puntoNoRetornoCruzado(),
                orden.tiempoEstimadoLlegadaMinutos(),
                orden.creadoEn(),
                OffsetDateTime.now()
        );

        OrdenServicio guardada = ordenRepository.save(actualizada, null);
        ordenRepository.registrarCambioEstado(id, estadoAnterior, nuevoEstado, modificadoPor, notas);

        return mapToResponse(guardada);
    }

    private void validarTransicion(String estadoAnterior, String nuevoEstado) {
        if ("ACEPTADA_EN_CAMINO".equals(estadoAnterior) && !"EN_SITIO".equals(nuevoEstado)) {
            throw new IllegalStateException("Tránsito inválido de camino a: " + nuevoEstado);
        }
        if ("EN_SITIO".equals(estadoAnterior) && 
            !"FINALIZADA_EXITOSA".equals(nuevoEstado) && 
            !"FINALIZADA_SOLO_DIAGNOSTICO".equals(nuevoEstado)) {
            throw new IllegalStateException("Tránsito inválido de en sitio a: " + nuevoEstado);
        }
        if (estadoAnterior.startsWith("CANCELADA") || estadoAnterior.startsWith("FINALIZADA")) {
            throw new IllegalStateException("No se puede mutar una orden terminada.");
        }
    }

    private OrdenResponse mapToResponse(OrdenServicio orden) {
        return new OrdenResponse(
                orden.id(),
                orden.subastaFirebaseId(),
                orden.clienteId(),
                orden.trabajadorId(),
                orden.categoriaId(),
                orden.estado(),
                orden.esVisitaDiagnostico(),
                orden.precioDiagnostico(),
                orden.precioFinal(),
                orden.comisionPlataforma(),
                orden.origenUbicacion() != null ? orden.origenUbicacion().latitud() : null,
                orden.origenUbicacion() != null ? orden.origenUbicacion().longitud() : null,
                orden.puntoNoRetornoCruzado(),
                orden.tiempoEstimadoLlegadaMinutos(),
                orden.creadoEn(),
                orden.actualizadoEn()
        );
    }
}
