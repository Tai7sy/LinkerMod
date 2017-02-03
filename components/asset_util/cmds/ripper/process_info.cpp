#pragma once
#include "process_info.h"

ProcessInfo g_process = { 0 };

int ProcessInfo_Init(processId_t pid)
{
	g_process.handle = OpenProcess(PROCESS_VM_READ, FALSE, pid);
	g_process.pid = pid;

	switch (PROCESS_TYPE type = Process_GetProcessType(pid))
	{
	case PROCESS_BLACK_OPS:
		g_process.db_hashTable = ForeignPointer<unsigned __int16>((unsigned __int16*)0x00CD81F8);
		g_process.db_assetEntryPool = ForeignPointer<XAssetEntryPoolEntry>((XAssetEntryPoolEntry*)0x00DE85D8);
		g_process.db_zoneNames = ForeignPointer<XZoneName>((XZoneName*)0x010C6608);
		break;
	case PROCESS_BLACK_OPS_MP:
		g_process.db_hashTable = ForeignPointer<unsigned __int16>((unsigned __int16*)0x24365D8);
		g_process.db_assetEntryPool = ForeignPointer<XAssetEntryPoolEntry>((XAssetEntryPoolEntry*)0x252FC18);
		g_process.db_zoneNames = ForeignPointer<XZoneName>((XZoneName*)0x028C9B08);
		break;
	default:
		printf("%d\n", type);
		ProcessInfo_Free();
		return -1;
	}

	return 0;
}

void ProcessInfo_Free(void)
{
	CloseHandle(g_process.handle);
	g_process.handle = NULL;
	g_process.pid = NULL;

	g_process.db_hashTable = nullptr;
	g_process.db_zoneNames = nullptr;
	g_process.db_assetEntryPool = nullptr;
}