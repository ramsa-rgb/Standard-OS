#include "efi.h"

unsigned int EFI_MAIN(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE* SystemTable) {
    SystemTable->ConOut->ClearScreen(SystemTable->ConOut);
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"Standard OS is Booting...");

    while (true)
    {
        /* code */
    }
    

    return 0;
}