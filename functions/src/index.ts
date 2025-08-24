import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as crypto from "crypto";

initializeApp();
const db = getFirestore();

// ⬇️ Remplace par TON email Firebase (celui avec lequel tu te connectes)
const ADMIN_EMAILS = new Set<string>(["ton.email@gmail.com"]);

/** Helpers (⚠️ bien typer en CallableRequest) */
function requireAuth(req: CallableRequest<any>) {
  if (!req.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
}

function requireAdmin(req: CallableRequest<any>) {
  requireAuth(req);
  const email = (req.auth!.token.email as string) || "";
  if (!ADMIN_EMAILS.has(email)) {
    throw new HttpsError("permission-denied", "Réservé à l’admin.");
  }
}

function makeCode(): string {
  const a = crypto.randomBytes(2).toString("hex").toUpperCase().slice(0, 4);
  const b = Math.floor(Math.random() * 10000).toString().padStart(4, "0");
  return `${a}-${b}`;
}

/** 1) generateCodes (admin) */
export const generateCodes = onCall(async (req) => {
  requireAdmin(req);

  const { count = 10, maxDevices = 2, edition = "2025" } = (req.data || {}) as {
    count?: number; maxDevices?: number; edition?: string;
  };

  const batch = db.batch();
  const now = FieldValue.serverTimestamp();

  for (let i = 0; i < count; i++) {
    let code = makeCode();
    let ref = db.collection("cards").doc(code);
    const snap = await ref.get();
    if (snap.exists) {
      code = makeCode();
      ref = db.collection("cards").doc(code);
    }

    batch.set(
      ref,
      {
        maxDevices,
        boundUserIds: [],
        boundDeviceIds: [],
        createdAt: now,
        edition,
        disabled: false,
      },
      { merge: true }
    );
  }

  await batch.commit();
  return { ok: true, created: count };
});

/** 2) activateWithCode (user connecté) */
export const activateWithCode = onCall(async (req) => {
  requireAuth(req);

  const uid = req.auth!.uid;
  const code = String(req.data?.code ?? "").toUpperCase().trim();
  const deviceId = String(req.data?.deviceId ?? "").trim();

  if (!code || !deviceId) {
    throw new HttpsError("invalid-argument", "code et deviceId requis.");
  }

  const cardRef = db.collection("cards").doc(code);
  const userRef = db.collection("users").doc(uid);
  const actRef = userRef.collection("activations").doc(code);

  return await db.runTransaction(async (tx) => {
    const [cardSnap, userSnap, actSnap] = await Promise.all([
      tx.get(cardRef),
      tx.get(userRef),
      tx.get(actRef),
    ]);

    if (!cardSnap.exists) {
      throw new HttpsError("not-found", "Code invalide.");
    }

    const card = cardSnap.data() as {
      disabled?: boolean;
      boundUserIds?: string[];
      boundDeviceIds?: string[];
      maxDevices?: number;
      edition?: string;
    };

    if (card.disabled) {
      throw new HttpsError("failed-precondition", "Code désactivé.");
    }

    const boundUserIds = card.boundUserIds ?? [];
    const boundDeviceIds = card.boundDeviceIds ?? [];
    const maxDevices = card.maxDevices ?? 1;

    if (boundDeviceIds.includes(deviceId)) {
      return { ok: true, already: true, edition: card.edition };
    }

    if (boundDeviceIds.length >= maxDevices) {
      throw new HttpsError("resource-exhausted", "Limite d’appareils atteinte.");
    }

    if (actSnap.exists) {
      if (!boundDeviceIds.includes(deviceId)) {
        boundDeviceIds.push(deviceId);
        if (!boundUserIds.includes(uid)) boundUserIds.push(uid);
        tx.update(cardRef, { boundDeviceIds, boundUserIds });
      }
      return { ok: true, already: true, edition: card.edition };
    }

    const userData = (userSnap.exists ? userSnap.data() : {}) as { devices?: string[] };
    const userDevices = userData.devices ?? [];
    if (!userDevices.includes(deviceId)) userDevices.push(deviceId);
    tx.set(userRef, { devices: userDevices }, { merge: true });

    tx.set(
      actRef,
      {
        deviceId,
        activatedAt: FieldValue.serverTimestamp(),
        edition: card.edition ?? null,
      },
      { merge: true }
    );

    if (!boundUserIds.includes(uid)) boundUserIds.push(uid);
    boundDeviceIds.push(deviceId);
    tx.update(cardRef, { boundUserIds, boundDeviceIds });

    return { ok: true, edition: card.edition };
  });
});
