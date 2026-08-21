package com.fixa.infrastructure.persistence.repository;

import com.fixa.infrastructure.persistence.entity.CategoriaServicioEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface CategoriaServicioRepository extends JpaRepository<CategoriaServicioEntity, Integer> {
    List<CategoriaServicioEntity> findByActivoTrue();
    Optional<CategoriaServicioEntity> findByNombreIgnoreCase(String nombre);
}
