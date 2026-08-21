package com.fixa.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "historial_estados_orden")
public class HistorialEstadosOrdenEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orden_id", nullable = false)
    private OrdenServicioEntity orden;

    @Column(name = "estado_anterior", length = 50)
    private String estadoAnterior;

    @Column(name = "estado_nuevo", length = 50, nullable = false)
    private String estadoNuevo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "modificado_por")
    private UsuarioEntity modificadoPor;

    @Column(name = "notas", columnDefinition = "text")
    private String notas;

    @Column(name = "fecha_cambio")
    private OffsetDateTime fechaCambio = OffsetDateTime.now();

    // Getters y Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public OrdenServicioEntity getOrden() { return orden; }
    public void setOrden(OrdenServicioEntity orden) { this.orden = orden; }

    public String getEstadoAnterior() { return estadoAnterior; }
    public void setEstadoAnterior(String estadoAnterior) { this.estadoAnterior = estadoAnterior; }

    public String getEstadoNuevo() { return estadoNuevo; }
    public void setEstadoNuevo(String estadoNuevo) { this.estadoNuevo = estadoNuevo; }

    public UsuarioEntity getModificadoPor() { return modificadoPor; }
    public void setModificadoPor(UsuarioEntity modificadoPor) { this.modificadoPor = modificadoPor; }

    public String getNotas() { return notas; }
    public void setNotas(String notas) { this.notas = notas; } // Note: spelling notes/notas
    public void setNotes(String notes) { this.notas = notes; }

    public OffsetDateTime getFechaCambio() { return fechaCambio; }
    public void setFechaCambio(OffsetDateTime fechaCambio) { this.fechaCambio = fechaCambio; }
}
