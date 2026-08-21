package com.fixa.infrastructure.persistence.entity;

import jakarta.persistence.*;
import org.locationtech.jts.geom.Point;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "ordenes_servicio")
public class OrdenServicioEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "subasta_firebase_id", length = 100, unique = true)
    private String subastaFirebaseId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cliente_id", nullable = false)
    private UsuarioEntity cliente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trabajador_id")
    private UsuarioEntity trabajador;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "categoria_id", nullable = false)
    private CategoriaServicioEntity categoria;

    @Column(name = "estado", length = 50, nullable = false)
    private String estado;

    @Column(name = "es_visita_diagnostico", nullable = false)
    private Boolean esVisitaDiagnostico;

    @Column(name = "precio_diagnostico", precision = 10, scale = 2, nullable = false)
    private BigDecimal precioDiagnostico;

    @Column(name = "precio_final", precision = 10, scale = 2)
    private BigDecimal precioFinal;

    @Column(name = "comision_plataforma", precision = 10, scale = 2)
    private BigDecimal comisionPlataforma;

    // Geolocalización JTS Point
    @Column(name = "origen_ubicacion", columnDefinition = "geometry(Point, 4326)", nullable = false)
    private Point origenUbicacion;

    @Column(name = "punto_no_retorno_cruzado")
    private Boolean puntoNoRetornoCruzado = false;

    @Column(name = "tiempo_estimado_llegada_minutos")
    private Integer tiempoEstimadoLlegadaMinutos;

    @Column(name = "creado_en")
    private OffsetDateTime creadoEn = OffsetDateTime.now();

    @Column(name = "actualizado_en")
    private OffsetDateTime actualizadoEn = OffsetDateTime.now();

    // Getters y Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getSubastaFirebaseId() { return subastaFirebaseId; }
    public void setSubastaFirebaseId(String subastaFirebaseId) { this.subastaFirebaseId = subastaFirebaseId; }

    public UsuarioEntity getCliente() { return cliente; }
    public void setCliente(UsuarioEntity cliente) { this.cliente = cliente; }

    public UsuarioEntity getTrabajador() { return trabajador; }
    public void setTrabajador(UsuarioEntity trabajador) { this.trabajador = trabajador; }

    public CategoriaServicioEntity getCategoria() { return categoria; }
    public void setCategoria(CategoriaServicioEntity categoria) { this.categoria = categoria; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public Boolean getEsVisitaDiagnostico() { return esVisitaDiagnostico; }
    public void setEsVisitaDiagnostico(Boolean esVisitaDiagnostico) { this.esVisitaDiagnostico = esVisitaDiagnostico; }

    public BigDecimal getPrecioDiagnostico() { return precioDiagnostico; }
    public void setPrecioDiagnostico(BigDecimal precioDiagnostico) { this.precioDiagnostico = precioDiagnostico; }

    public BigDecimal getPrecioFinal() { return precioFinal; }
    public void setPrecioFinal(BigDecimal precioFinal) { this.precioFinal = precioFinal; }

    public BigDecimal getComisionPlataforma() { return comisionPlataforma; }
    public void setComisionPlataforma(BigDecimal comisionPlataforma) { this.comisionPlataforma = comisionPlataforma; }

    public Point getOrigenUbicacion() { return origenUbicacion; }
    public void setOrigenUbicacion(Point origenUbicacion) { this.origenUbicacion = origenUbicacion; }

    public Boolean getPuntoNoRetornoCruzado() { return puntoNoRetornoCruzado; }
    public void setPuntoNoRetornoCruzado(Boolean puntoNoRetornoCruzado) { this.puntoNoRetornoCruzado = puntoNoRetornoCruzado; }

    public Integer getTiempoEstimadoLlegadaMinutos() { return tiempoEstimadoLlegadaMinutos; }
    public void setTiempoEstimadoLlegadaMinutos(Integer tiempoEstimadoLlegadaMinutos) { this.tiempoEstimadoLlegadaMinutos = tiempoEstimadoLlegadaMinutos; }

    public OffsetDateTime getCreadoEn() { return creadoEn; }
    public void setCreadoEn(OffsetDateTime creadoEn) { this.creadoEn = creadoEn; }

    public OffsetDateTime getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(OffsetDateTime actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
