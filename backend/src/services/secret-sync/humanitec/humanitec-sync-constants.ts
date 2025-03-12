import { AppConnection } from "@app/services/app-connection/app-connection-enums";
import { SecretSync } from "@app/services/secret-sync/secret-sync-enums";
import { TSecretSyncListItem } from "@app/services/secret-sync/secret-sync-types";

export const HUMANITEC_SYNC_LIST_OPTION: TSecretSyncListItem = {
  name: "Humanitec",
  destination: SecretSync.Humanitec,
  connection: AppConnection.Humanitec,
  canImportSecrets: false
};
