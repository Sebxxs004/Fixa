package com.fixa.infrastructure.persistence.repository;

import com.fixa.infrastructure.persistence.entity.HistorialEstadosOrdenEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface HistorialEstadosOrdenRepository extends JpaRepository<HistorialEstadosOrdenEntity, UUID> {
    List<HistorialEstadosOrdenEntity> findByOrdenIdOrderByFechaCambioDesc(UUID ordenId);
}
