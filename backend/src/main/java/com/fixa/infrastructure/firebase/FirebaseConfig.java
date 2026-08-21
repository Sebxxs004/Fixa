package com.fixa.infrastructure.firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;

@Configuration
public class FirebaseConfig {
    @PostConstruct
    public void init() {
        if (FirebaseApp.getApps().isEmpty()) {
            try {
                // Configuración ficticia para inicializar el SDK en local sin requerir un archivo real en disco.
                // En producción esto se cargará desde las variables de entorno de GCP / Secret Manager.
                String dummyCredentialsJson = """
                {
                  "type": "service_account",
                  "project_id": "fixa-dev",
                  "private_key_id": "dummy_key_id",
                  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDh3kPz7HnU6XvK\\n-----END PRIVATE KEY-----\\n",
                  "client_email": "firebase-adminsdk@fixa-dev.iam.gserviceaccount.com",
                  "client_id": "dummy_client_id"
                }
                """;

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(new ByteArrayInputStream(dummyCredentialsJson.getBytes())))
                        .build();

                FirebaseApp.initializeApp(options);
                System.out.println("Firebase App inicializada exitosamente con credenciales de desarrollo.");
            } catch (Exception e) {
                System.err.println("Error al inicializar Firebase App: " + e.getMessage());
            }
        }
    }
}
