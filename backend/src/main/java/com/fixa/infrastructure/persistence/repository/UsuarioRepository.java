package com.fixa.infrastructure.persistence.repository;

import com.fixa.infrastructure.persistence.entity.UsuarioEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UsuarioRepository extends JpaRepository<UsuarioEntity, UUID> {
    Optional<UsuarioEntity> findByFirebaseUid(String firebaseUid);
    Optional<UsuarioEntity> findByEmail(String email);
}
