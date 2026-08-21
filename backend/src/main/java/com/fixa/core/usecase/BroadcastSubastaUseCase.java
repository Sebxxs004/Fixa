package com.fixa.core.usecase;

import com.fixa.infrastructure.persistence.entity.PerfilTrabajadorEntity;
import com.fixa.infrastructure.persistence.repository.PerfilTrabajadorRepository;
import com.fixa.presentation.dto.BroadcastRequest;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
public class BroadcastSubastaUseCase {

    private final PerfilTrabajadorRepository perfilTrabajadorRepository;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public BroadcastSubastaUseCase(PerfilTrabajadorRepository perfilTrabajadorRepository) {
        this.perfilTrabajadorRepository = perfilTrabajadorRepository;
    }

    public void ejecutarBroadcast(BroadcastRequest request) {
        // Generar un ID único para la subasta efímera
        String subastaId = "subasta_" + UUID.randomUUID().toString();

        // Crear el punto geográfico del cliente en SRID 4326 (x = longitud, y = latitud)
        Point origenCliente = geometryFactory.createPoint(new Coordinate(request.longitud(), request.latitud()));

        // Buscar trabajadores a la redonda de 5000 metros (5 km)
        List<PerfilTrabajadorEntity> trabajadoresCercanos = perfilTrabajadorRepository.findNearbyWorkers(origenCliente, 5000.0);

        System.out.println("Broadcast iniciado para subasta " + subastaId + ". Trabajadores aptos encontrados: " + trabajadoresCercanos.size());

        // Difusión masiva via FCM Data Messages (Notificaciones silenciosas de alta prioridad)
        for (PerfilTrabajadorEntity perfil : trabajadoresCercanos) {
            String deviceToken = perfil.getUsuario().getDeviceToken();

            if (deviceToken != null && !deviceToken.isBlank()) {
                try {
                    // Estructura del Data Message
                    Message message = Message.builder()
                            .setToken(deviceToken)
                            .putData("subasta_id", subastaId)
                            .putData("tipo_urgency", "ALTA")
                            .putData("categoria_id", String.valueOf(request.categoriaId()))
                            .build();

                    // Envío asíncrono
                    FirebaseMessaging.getInstance().sendAsync(message);
                    System.out.println("Notificación FCM de subasta enviada a trabajador: " + perfil.getUsuario().getNombreCompleto());
                } catch (Exception e) {
                    // Captura cualquier excepción de Firebase (ej. token expirado o inválido) 
                    // para asegurar que el fallo de un dispositivo no rompa el bucle de notificaciones
                    System.err.println("Fallo al enviar notificación FCM a " 
                            + perfil.getUsuario().getNombreCompleto() + ": " + e.getMessage());
                }
            }
        }
    }
}
