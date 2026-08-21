package com.fixa.infrastructure.persistence.repository;

import com.fixa.infrastructure.persistence.entity.TransaccionPagoEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransaccionPagoRepository extends JpaRepository<TransaccionPagoEntity, UUID> {
    Optional<TransaccionPagoEntity> findByIdempotencyKey(String idempotencyKey);
    List<TransaccionPagoEntity> findByOrdenId(UUID ordenId);
}
