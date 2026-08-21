package com.fixa.infrastructure.persistence.repository;

import com.fixa.infrastructure.persistence.entity.PerfilTrabajadorEntity;
import org.locationtech.jts.geom.Point;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface PerfilTrabajadorRepository extends JpaRepository<PerfilTrabajadorEntity, UUID> {

    /**
     * Busca trabajadores activos y verificados que se encuentren dentro del radio de distancia especificado (en metros)
     * usando la función espacial ST_DWithin de PostGIS con cast a geografía para precisión métrica.
     */
    @Query(value = "SELECT p.* FROM perfiles_trabajador p " +
                   "JOIN usuarios u ON p.usuario_id = u.id " +
                   "WHERE u.activo = true " +
                   "AND p.estado_verificacion = 'APROBADO_KYC' " +
                   "AND ST_DWithin(p.ubicacion_actual::geography, :point::geography, :distanceInMeters)", 
           nativeQuery = true)
    List<PerfilTrabajadorEntity> findNearbyWorkers(
            @Param("point") Point point, 
            @Param("distanceInMeters") double distanceInMeters
    );
}
