package com.fixa.infrastructure.persistence.entity;

import jakarta.persistence.*;
import org.locationtech.jts.geom.Point;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "perfiles_trabajador")
public class PerfilTrabajadorEntity {

    @Id
    @Column(name = "usuario_id")
    private UUID usuarioId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "usuario_id")
    private UsuarioEntity usuario;

    @Column(name = "documento_identidad", length = 50, unique = true)
    private String documentoIdentidad;

    @Column(name = "estado_verificacion", length = 30)
    private String estadoVerificacion = "PENDIENTE";

    @Column(name = "calificacion_promedio", precision = 3, scale = 2)
    private BigDecimal calificacionPromedio = BigDecimal.valueOf(5.00);

    @Column(name = "total_trabajos_completados")
    private Integer totalTrabajosCompletados = 0;

    // Telemetría Geoespacial con Hibernate Spatial y JTS Point
    @Column(name = "ubicacion_actual", columnDefinition = "geometry(Point, 4326)")
    private Point ubicacionActual;

    @Column(name = "ultima_actualizacion_gps")
    private OffsetDateTime ultimaActualizacionGps;

    // Getters y Setters
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }

    public UsuarioEntity getUsuario() { return usuario; }
    public void setUsuario(UsuarioEntity usuario) { this.usuario = usuario; }

    public String getDocumentoIdentidad() { return documentoIdentidad; }
    public void setDocumentoIdentidad(String documentoIdentidad) { this.documentoIdentidad = documentoIdentidad; }

    public String getEstadoVerificacion() { return estadoVerificacion; }
    public void setEstadoVerificacion(String estadoVerificacion) { this.estadoVerificacion = estadoVerificacion; }

    public BigDecimal getCalificacionPromedio() { return calificacionPromedio; }
    public void setCalificacionPromedio(BigDecimal calificacionPromedio) { this.calificacionPromedio = calificacionPromedio; }

    public Integer getTotalTrabajosCompletados() { return totalTrabajosCompletados; }
    public void setTotalTrabajosCompletados(Integer totalTrabajosCompletados) { this.totalTrabajosCompletados = totalTrabajosCompletados; }

    public Point getUbicacionActual() { return ubicacionActual; }
    public void setUbicacionActual(Point ubicacionActual) { this.ubicacionActual = ubicacionActual; }

    public OffsetDateTime getUltimaActualizacionGps() { return ultimaActualizacionGps; }
    public void setUltimaActualizacionGps(OffsetDateTime ultimaActualizacionGps) { this.ultimaActualizacionGps = ultimaActualizacionGps; }
}
