import { Fragment } from "react";
import { faFile } from "@fortawesome/free-solid-svg-icons";

import {
  Button,
  EmptyState,
  Table,
  TableContainer,
  TableSkeleton,
  TBody,
  Td,
  Th,
  THead,
  Tr
} from "@app/components/v2";
import { useGetAuditLogs } from "@app/hooks/api";
import { TGetAuditLogsFilter } from "@app/hooks/api/auditLogs/types";

import { LogsTableRow } from "./LogsTableRow";

type Props = {
  filter?: TGetAuditLogsFilter;
  refetchInterval?: number;
};

const AUDIT_LOG_LIMIT = 15;

export const LogsTable = ({ filter, refetchInterval }: Props) => {
  // Determine the project ID for filtering
  const filterProjectId =
    // Use the projectId from the filter if it exists
    filter?.projectId || null;

  const { data, isPending, isFetchingNextPage, hasNextPage, fetchNextPage } = useGetAuditLogs(
    {
      ...filter,
      limit: AUDIT_LOG_LIMIT
    },
    filterProjectId,
    {
      refetchInterval
    }
  );

  const isEmpty = !isPending && !data?.pages?.[0].length;

  return (
    <div>
      <TableContainer>
        <Table>
          <THead>
            <Tr>
              <Th className="w-8" />
              <Th className="w-64">Timestamp</Th>
              <Th>Event</Th>
            </Tr>
          </THead>
          <TBody>
            {!isPending &&
              data?.pages?.map((group, i) => (
                <Fragment key={`audit-log-fragment-${i + 1}`}>
                  {group.map((auditLog) => (
                    <LogsTableRow auditLog={auditLog} key={`audit-log-${auditLog.id}`} />
                  ))}
                </Fragment>
              ))}
            {isPending && <TableSkeleton innerKey="logs-table" columns={5} key="logs" />}
            {isEmpty && (
              <Tr>
                <Td colSpan={3}>
                  <EmptyState title="No audit logs on file" icon={faFile} />
                </Td>
              </Tr>
            )}
          </TBody>
        </Table>
      </TableContainer>
      {!isEmpty && (
        <Button
          className="mb-20 mt-4 px-4 py-3 text-sm"
          isFullWidth
          variant="star"
          isLoading={isFetchingNextPage}
          isDisabled={isFetchingNextPage || !hasNextPage}
          onClick={() => fetchNextPage()}
        >
          {hasNextPage ? "Load More" : "End of logs"}
        </Button>
      )}
    </div>
  );
};
