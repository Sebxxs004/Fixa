package com.fixa.infrastructure.persistence.repository;

import com.fixa.infrastructure.persistence.entity.OrdenServicioEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrdenServicioRepository extends JpaRepository<OrdenServicioEntity, UUID> {
    Optional<OrdenServicioEntity> findBySubastaFirebaseId(String subastaFirebaseId);
    List<OrdenServicioEntity> findByClienteId(UUID clienteId);
    List<OrdenServicioEntity> findByTrabajadorId(UUID trabajadorId);
}
