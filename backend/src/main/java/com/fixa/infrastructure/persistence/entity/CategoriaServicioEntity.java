package com.fixa.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "categorias_servicio")
public class CategoriaServicioEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "nombre", length = 100, unique = true, nullable = false)
    private String nombre;

    @Column(name = "tarifa_base_diagnostico", precision = 10, scale = 2, nullable = false)
    private BigDecimal tarifaBaseDiagnostico;

    @Column(name = "activo")
    private Boolean activo = true;

    // Getters y Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public BigDecimal getTarifaBaseDiagnostico() { return tarifaBaseDiagnostico; }
    public void setTarifaBaseDiagnostico(BigDecimal tarifaBaseDiagnostico) { this.tarifaBaseDiagnostico = tarifaBaseDiagnostico; }

    public Boolean getActivo() { return activo; }
    public void setActivo(Boolean activo) { this.activo = activo; }
}
