#pragma once

struct msg_t
{
	char wtf[1];
};

void SV_DropClient(client_t *drop, const char *reason, bool tellThem, bool writeStats);
void SV_ExecuteClientCommand(client_t *cl, const char *s, int clientOK, int fromOldServer);
int SV_ClientCommand(client_t *cl, msg_t *msg, int fromOldServer);

void hk_SV_ClientCommand();