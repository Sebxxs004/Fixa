package com.fixa.infrastructure.persistence.repository;

import com.fixa.infrastructure.persistence.entity.OrdenServicioEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.locationtech.jts.geom.Point;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrdenServicioRepository extends JpaRepository<OrdenServicioEntity, UUID> {
    Optional<OrdenServicioEntity> findBySubastaFirebaseId(String subastaFirebaseId);
    List<OrdenServicioEntity> findByClienteId(UUID clienteId);
    List<OrdenServicioEntity> findByTrabajadorId(UUID trabajadorId);

    @Query(value = "SELECT ST_Distance(CAST(:p1 AS geography), CAST(:p2 AS geography))", nativeQuery = true)
    double calculateDistanceInMeters(@Param("p1") Point p1, @Param("p2") Point p2);
}
