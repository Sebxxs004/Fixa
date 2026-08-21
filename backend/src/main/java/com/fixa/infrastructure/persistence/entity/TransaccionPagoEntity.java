package com.fixa.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "transacciones_pago")
public class TransaccionPagoEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orden_id", nullable = false)
    private OrdenServicioEntity orden;

    @Column(name = "idempotency_key", length = 100, unique = true, nullable = false)
    private String idempotencyKey;

    @Column(name = "token_transaccion_pasarela", length = 255)
    private String tokenTransaccionPasarela;

    @Column(name = "monto_total", precision = 10, scale = 2, nullable = false)
    private BigDecimal montoTotal;

    @Column(name = "tipo_movimiento", length = 30, nullable = false)
    private String tipoMovimiento;

    @Column(name = "estado_pago", length = 30, nullable = false)
    private String estadoPago;

    @Column(name = "fecha_transaccion")
    private OffsetDateTime fechaTransaccion = OffsetDateTime.now();

    // Getters y Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public OrdenServicioEntity getOrden() { return orden; }
    public void setOrden(OrdenServicioEntity orden) { this.orden = orden; }

    public String getIdempotencyKey() { return idempotencyKey; }
    public void setIdempotencyKey(String idempotencyKey) { this.idempotencyKey = idempotencyKey; }

    public String getTokenTransaccionPasarela() { return tokenTransaccionPasarela; }
    public void setTokenTransaccionPasarela(String tokenTransaccionPasarela) { this.tokenTransaccionPasarela = tokenTransaccionPasarela; }

    public BigDecimal getMontoTotal() { return montoTotal; }
    public void setMontoTotal(BigDecimal montoTotal) { this.montoTotal = montoTotal; }

    public String getTipoMovimiento() { return tipoMovimiento; }
    public void setTipoMovimiento(String tipoMovimiento) { this.tipoMovimiento = tipoMovimiento; }

    public String getEstadoPago() { return estadoPago; }
    public void setEstadoPago(String estadoPago) { this.estadoPago = estadoPago; }

    public OffsetDateTime getFechaTransaccion() { return fechaTransaccion; }
    public void setFechaTransaccion(OffsetDateTime fechaTransaccion) { this.fechaTransaccion = fechaTransaccion; }
}
