import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {
  DEFAULT_FILE_VERSION_LIMIT,
  versionsToRotateOut,
} from "../../domain/entities/file-version-rotation.js";
import {getDefaultStorageBucket} from "./firebase-storage.js";

// Auch Client-Uploads schreiben Versionen direkt nach Firestore, daher
// rotiert ein Trigger statt des Runner-Stores.
export const rotateFileVersions = onDocumentCreated(
  "teams/{teamId}/files/{fileId}/versions/{versionId}",
  async (event) => {
    const {teamId, fileId} = event.params;
    const fileReference = getDatabase().collection("teams").doc(teamId)
      .collection("files").doc(fileId);
    const file = await fileReference.get();
    const currentVersionId = file.data()?.currentVersionId;
    if (typeof currentVersionId !== "string") return;
    const snapshot = await fileReference.collection("versions").get();
    const stale = versionsToRotateOut(
      snapshot.docs.map((document) => ({
        id: document.id,
        createdAt: document.createTime.toMillis(),
        storagePath: document.data().storagePath as unknown,
      })),
      DEFAULT_FILE_VERSION_LIMIT,
      currentVersionId,
    );
    for (const version of stale) {
      if (typeof version.storagePath === "string" && version.storagePath) {
        await getDefaultStorageBucket().file(version.storagePath)
          .delete({ignoreNotFound: true});
      }
      await fileReference.collection("versions").doc(version.id).delete();
    }
    if (stale.length > 0) {
      logger.info("file_versions.rotated", {teamId, fileId, removed: stale.length});
    }
  },
);
