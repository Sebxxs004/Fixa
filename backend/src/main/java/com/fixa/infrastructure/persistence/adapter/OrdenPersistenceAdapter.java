package com.fixa.infrastructure.persistence.adapter;

import com.fixa.core.model.Coordenadas;
import com.fixa.core.model.OrdenServicio;
import com.fixa.core.repository.OrdenRepository;
import com.fixa.infrastructure.persistence.entity.HistorialEstadosOrdenEntity;
import com.fixa.infrastructure.persistence.entity.OrdenServicioEntity;
import com.fixa.infrastructure.persistence.entity.TransaccionPagoEntity;
import com.fixa.infrastructure.persistence.repository.*;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

@Component
public class OrdenPersistenceAdapter implements OrdenRepository {

    private final OrdenServicioRepository ordenRepository;
    private final TransaccionPagoRepository transaccionRepository;
    private final HistorialEstadosOrdenRepository historialRepository;
    private final UsuarioRepository usuarioRepository;
    private final CategoriaServicioRepository categoriaRepository;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public OrdenPersistenceAdapter(
            OrdenServicioRepository ordenRepository,
            TransaccionPagoRepository transaccionRepository,
            HistorialEstadosOrdenRepository historialRepository,
            UsuarioRepository usuarioRepository,
            CategoriaServicioRepository categoriaRepository) {
        this.ordenRepository = ordenRepository;
        this.transaccionRepository = transaccionRepository;
        this.historialRepository = historialRepository;
        this.usuarioRepository = usuarioRepository;
        this.categoriaRepository = categoriaRepository;
    }

    @Override
    public Optional<OrdenServicio> findById(UUID id) {
        return ordenRepository.findById(id).map(this::mapToDomain);
    }

    @Override
    public Optional<OrdenServicio> findBySubastaFirebaseId(String subastaFirebaseId) {
        return ordenRepository.findBySubastaFirebaseId(subastaFirebaseId).map(this::mapToDomain);
    }

    @Override
    @Transactional
    public OrdenServicio save(OrdenServicio orden, String idempotencyKey) {
        OrdenServicioEntity entity = ordenRepository.findById(orden.id() != null ? orden.id() : UUID.randomUUID())
                .orElse(new OrdenServicioEntity());

        if (orden.id() != null) {
            entity.setId(orden.id());
        }
        entity.setSubastaFirebaseId(orden.subastaFirebaseId());
        entity.setCliente(usuarioRepository.findById(orden.clienteId()).orElseThrow());
        entity.setTrabajador(orden.trabajadorId() != null ? usuarioRepository.findById(orden.trabajadorId()).orElse(null) : null);
        entity.setCategoria(categoriaRepository.findById(orden.categoriaId()).orElseThrow());
        entity.setEstado(orden.estado());
        entity.setEsVisitaDiagnostico(orden.esVisitaDiagnostico());
        entity.setPrecioDiagnostico(orden.precioDiagnostico());
        entity.setPrecioFinal(orden.precioFinal());
        entity.setComisionPlataforma(orden.comisionPlataforma());

        if (orden.origenUbicacion() != null) {
            Point origin = geometryFactory.createPoint(new Coordinate(
                    orden.origenUbicacion().longitud(), 
                    orden.origenUbicacion().latitud()
            ));
            entity.setOrigenUbicacion(origin);
        }
        entity.setPuntoNoRetornoCruzado(orden.puntoNoRetornoCruzado());
        entity.setTiempoEstimadoLlegadaMinutos(orden.tiempoEstimadoLlegadaMinutos());
        entity.setActualizadoEn(orden.actualizadoEn());

        // Si se provee una clave de idempotencia, persistir la transacción asociada
        if (idempotencyKey != null && !existsTransaccionByIdempotencyKey(idempotencyKey)) {
            OrdenServicioEntity savedEntity = ordenRepository.save(entity);
            
            TransaccionPagoEntity transaccion = new TransaccionPagoEntity();
            transaccion.setOrden(savedEntity);
            transaccion.setIdempotencyKey(idempotencyKey);
            transaccion.setMontoTotal(orden.precioDiagnostico());
            transaccion.setTipoMovimiento("RETENCION");
            transaccion.setEstadoPago("APROBADO");
            
            transaccionRepository.save(transaccion);
            return mapToDomain(savedEntity);
        }

        return mapToDomain(ordenRepository.save(entity));
    }

    @Override
    public boolean existsTransaccionByIdempotencyKey(String idempotencyKey) {
        return transaccionRepository.findByIdempotencyKey(idempotencyKey).isPresent();
    }

    @Override
    public double calculateDistanceInMeters(UUID ordenId, double lat, double lon) {
        OrdenServicioEntity orden = ordenRepository.findById(ordenId).orElseThrow();
        Point p2 = geometryFactory.createPoint(new Coordinate(lon, lat));
        return ordenRepository.calculateDistanceInMeters(orden.getOrigenUbicacion(), p2);
    }

    @Override
    @Transactional
    public void registrarCambioEstado(UUID ordenId, String estadoAnterior, String estadoNuevo, UUID modificadoPor, String notas) {
        HistorialEstadosOrdenEntity historial = new HistorialEstadosOrdenEntity();
        historial.setOrden(ordenRepository.findById(ordenId).orElseThrow());
        historial.setEstadoAnterior(estadoAnterior);
        historial.setEstadoNuevo(estadoNuevo);
        historial.setModificadoPor(modificadoPor != null ? usuarioRepository.findById(modificadoPor).orElse(null) : null);
        historial.setNotas(notas);

        historialRepository.save(historial);
    }

    private OrdenServicio mapToDomain(OrdenServicioEntity entity) {
        Coordenadas coordenadas = null;
        if (entity.getOrigenUbicacion() != null) {
            coordenadas = new Coordenadas(
                    entity.getOrigenUbicacion().getY(), 
                    entity.getOrigenUbicacion().getX()
            );
        }

        return new OrdenServicio(
                entity.getId(),
                entity.getSubastaFirebaseId(),
                entity.getCliente().getId(),
                entity.getTrabajador() != null ? entity.getTrabajador().getId() : null,
                entity.getCategoria().getId(),
                entity.getEstado(),
                entity.getEsVisitaDiagnostico(),
                entity.getPrecioDiagnostico(),
                entity.getPrecioFinal(),
                entity.getComisionPlataforma(),
                coordenadas,
                entity.getPuntoNoRetornoCruzado(),
                entity.getTiempoEstimadoLlegadaMinutos(),
                entity.getCreadoEn(),
                entity.getActualizadoEn()
        );
    }
}
