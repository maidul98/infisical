import { Knex } from "knex";

import { TableName } from "../schemas";

export async function up(knex: Knex): Promise<void> {
  if (await knex.schema.hasTable(TableName.Organization)) {
    const hasSecretShareToAnyoneCol = await knex.schema.hasColumn(TableName.Organization, "secretShareSendToAnyone");

    if (!hasSecretShareToAnyoneCol) {
      await knex.schema.alterTable(TableName.Organization, (t) => {
        t.boolean("secretShareSendToAnyone").defaultTo(true);
      });
    }
  }
}

export async function down(knex: Knex): Promise<void> {
  if (await knex.schema.hasTable(TableName.Organization)) {
    const hasSecretShareToAnyoneCol = await knex.schema.hasColumn(TableName.Organization, "secretShareSendToAnyone");
    if (hasSecretShareToAnyoneCol) {
      await knex.schema.alterTable(TableName.Organization, (t) => {
        t.dropColumn("secretShareSendToAnyone");
      });
    }
  }
}
