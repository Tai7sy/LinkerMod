#pragma once

#pragma comment(lib, "../shared/detours/Detours.lib")
#include "../shared/detours/Typedef.h"
#include "../shared/detours/Detours.h"

#include "../shared/assert.h"

#include <Windows.h>
#include <string>

static void PatchMemory(ULONG_PTR Address, PBYTE Data, SIZE_T Size)
{
	DWORD d = 0;
	VirtualProtect((LPVOID)Address, Size, PAGE_EXECUTE_READWRITE, &d);

	for (SIZE_T i = 0; i < Size; i++)
		*(volatile BYTE *)(Address + i) = *Data++;

	VirtualProtect((LPVOID)Address, Size, d, &d);

	FlushInstructionCache(GetCurrentProcess(), (LPVOID)Address, Size);
}

static void PatchMemory_WithNOP(ULONG_PTR Address, SIZE_T Size)
{
	DWORD d = 0;
	VirtualProtect((LPVOID)Address, Size, PAGE_EXECUTE_READWRITE, &d);

	for (SIZE_T i = 0; i < Size; i++)
		*(volatile BYTE *)(Address + i) = 0x90; //0x90 == opcode for NOP

	VirtualProtect((LPVOID)Address, Size, d, &d);

	FlushInstructionCache(GetCurrentProcess(), (LPVOID)Address, Size);
}

static void FixupFunction(ULONG_PTR Address, ULONG_PTR DestAddress)
{
	DWORD data = (DestAddress - Address - 5);

	PatchMemory(Address + 0, (PBYTE)"\xE9", 1);
	PatchMemory(Address + 1, (PBYTE)&data, 4);
}

static bool StrEndsWith (std::string str, std::string substr)
{
    if (str.length() >= substr.length())
        return (0 == str.compare (str.length() - substr.length(), substr.length(), substr));
	else
        return false;
}

namespace Detours
{
	namespace X86
	{
		class LogHook
		{
		private:
			void* rtn;
			BYTE* op;
			void* fnc;
			char* msg;

		public:
			LogHook(const char* message)
			{
				op = new BYTE[23];
				PatchMemory((ULONG_PTR)op + 0,	(PBYTE)"\x60", 1);						//pusha
				PatchMemory((ULONG_PTR)op + 1,	(PBYTE)"\xFF\x35\x00\x00\x00\x00", 6);	//push str
				PatchMemory((ULONG_PTR)op + 7,	(PBYTE)"\xFF\x15\x00\x00\x00\x00", 6);	//call printf
				PatchMemory((ULONG_PTR)op + 13,	(PBYTE)"\x83\xC4\x04", 3);				//add esp, 4
				PatchMemory((ULONG_PTR)op + 16,	(PBYTE)"\x61", 1);						//popa
				PatchMemory((ULONG_PTR)op + 17,	(PBYTE)"\xFF\x25\x00\x00\x00\x00", 6);	//jmp rtn

				this->msg = (char*)message;
				this->fnc = (void*)&PrintMessage;
				void** str = (void**)&msg;
				
				void** prnt = &fnc;
				void** retn = &rtn;

				PatchMemory((ULONG_PTR)op + 3,	(PBYTE)&str, 4);	//fix str
				PatchMemory((ULONG_PTR)op + 9,	(PBYTE)&prnt, 4);	//fix printf
				PatchMemory((ULONG_PTR)op + 19,	(PBYTE)&retn, 4);	//fix rtn
			}

			~LogHook()
			{
				delete[] op;
			}

			static void __cdecl PrintMessage(const char* str)
			{
				printf("%s\n", str);
			}

			friend void AddLogHook(uint8_t * target, const char* msg);
			friend static void RemoveLogHook(uint8_t * target);
		};

		// Print a message when the code at the target address is executed
		static void AddLogHook(uint8_t * target, const char* msg)
		{
			LogHook* hk = new LogHook(msg);
			hk->rtn = DetourFunction(target, hk->op, Detours::X86Option::USE_JUMP);
		}

		static void* GetDest_JmpRel32(BYTE* instr)
		{
			ASSERT(*instr == 0xE9);
			int* target_rel32 = (int*)(instr + 1); 
			return instr + 5 + *target_rel32; // jmp instruction offset + the relative offset that it would jump to + size of jmp instruction
		}

		// Remove a log hook and restore the original code, where target matches the target argument used in AddLogHook
		static void RemoveLogHook(uint8_t * target)
		{
			void* trampoline = GetDest_JmpRel32(target);
			BYTE* op = (BYTE*)GetDest_JmpRel32((BYTE*)trampoline);

			LogHook* hk = *(LogHook**)(op + 19);

			DetourRemove((PBYTE)hk->rtn);
			delete[] hk;
		}
	}
}
