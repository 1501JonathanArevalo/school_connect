const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createUser = functions.https.onCall(async (data, context) => {
  // 1. Verificar autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión"
    );
  }

  // 2. Verificar rol de admin
  const adminUser = await admin.firestore()
    .collection("users")
    .doc(context.auth.uid)
    .get();

  if (!adminUser.exists || adminUser.data().role !== "admin") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "No tienes permisos de administrador"
    );
  }

  // 3. Validar datos de entrada
  if (!data.email || !data.password || !data.role) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Datos incompletos"
    );
  }

  // 4. Crear usuario en Authentication
  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email: data.email,
      password: data.password,
      emailVerified: false, // Opcional: forzar verificación
    });
  } catch (error) {
    throw new functions.https.HttpsError(
        "internal",
        error.message
    );
  }

  // 5. Guardar datos adicionales en Firestore
  await admin.firestore().collection("users").doc(userRecord.uid).set({
    uid: userRecord.uid,
    email: data.email,
    role: data.role,
    createdBy: context.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 6. Opcional: Enviar email de verificación
  // await admin.auth().generateEmailVerificationLink(data.email);

  return {
    success: true,
    userId: userRecord.uid,
    message: "Usuario creado exitosamente"
  };
});