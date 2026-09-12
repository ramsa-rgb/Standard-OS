#ifndef EFI_H
#define EFI_H

typedef unsigned char _BOOL;

#define bool _BOOL
#define true 1
#define false 0

#define EFI_STATUS unsigned int
#define EFI_HANDLE void*
#define EFI_EVENT void*
#define EFIAPI __cdecl

#define CHAR16 unsigned short
#define UINT16 unsigned short
#define UINT32 unsigned int
#define UINT64 unsigned long long
#define UINTN unsigned int

typedef struct {
    UINT64 Signature;
    UINT32 Revision;
    UINT32 HeaderSize;
    UINT32 CRC32;
    UINT32 Reserved;
} EFI_TABLE_HEADER;

typedef EFI_STATUS (EFIAPI* EFI_WAIT_FOR_EVENT) (
    UINTN NumberOfEvents, EFI_EVENT* Event, UINTN *Index
);

// EFI_SIMPLE_TEXT_INPUT_PROTOCOL
typedef struct {
    UINT16 ScanCode;
    CHAR16 UnicodeChar;
} EFI_INPUT_KEY;

typedef EFI_STATUS (EFIAPI* EFI_INPUT_RESET) (
    void* This, bool ExtendedVerification
);

typedef EFI_STATUS (EFIAPI* EFI_INPUT_READ_KEY) (
    void* This,
    EFI_INPUT_KEY* Key
);

typedef struct {
    EFI_INPUT_RESET Reset;
    EFI_INPUT_READ_KEY ReadKeyStroke;
    EFI_EVENT WaitForKey;
} EFI_SIMPLE_TEXT_INPUT_PROTOCOL;

// EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL
typedef struct {
    int MaxMode;
    int Mode;
    int Attribute;
    int CursorColumn;
    int CursorRow;
    bool CursorVisible;
} SIMPLE_TEXT_OUTPUT_MODE;

typedef EFI_STATUS (EFIAPI* EFI_TEXT_RESET) (
    void* This,
    bool ExtendedVerification
);

typedef EFI_STATUS (EFIAPI* EFI_TEXT_STRING) (
    void* This,
    CHAR16* String
);

typedef EFI_STATUS (EFIAPI* EFI_TEXT_TEST_STRING) (
    void* This,
    CHAR16* String
);

typedef EFI_STATUS (EFIAPI* EFI_TEXT_QUERY_MODE) (
    void* This,
    UINTN ModeNumber,
    UINTN* Columns,
    UINTN* Rows
);

typedef EFI_STATUS (EFIAPI* EFI_TEXT_SET_MODE) (
    void* This,
    UINTN ModeNumber
);

typedef EFI_STATUS (EFIAPI* EFI_TEXT_SET_ATTRIBUTE) (
    void* This,
    UINTN Attribute
);

typedef EFI_STATUS (EFIAPI* EFI_TEXT_CLEAR_SCREEN) (
    void* This
);

typedef EFI_STATUS (EFIAPI* EFI_TEXT_SET_CURSOR_POSITION) (
    void* This,
    UINTN Column,
    UINTN Row
);

typedef EFI_STATUS (EFIAPI* EFI_TEXT_ENABLE_CURSOR) (
    void* This,
    bool Visible
);

typedef struct {
    EFI_TEXT_RESET Reset;
    EFI_TEXT_STRING OutputString;
    EFI_TEXT_TEST_STRING TestString;
    EFI_TEXT_QUERY_MODE QueryMode;
    EFI_TEXT_SET_MODE SetMode;
    EFI_TEXT_SET_ATTRIBUTE SetAttribute;
    EFI_TEXT_CLEAR_SCREEN ClearScreen;
    EFI_TEXT_SET_CURSOR_POSITION SetCursorPosition;
    EFI_TEXT_ENABLE_CURSOR EnableCursor;
    SIMPLE_TEXT_OUTPUT_MODE *Mode;
} EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;

typedef struct {
    EFI_TABLE_HEADER Hdr;
    CHAR16 *FirmwareVendor;
    UINT32 FirmwareRevision;
    EFI_HANDLE ConsoleInHandle;
    EFI_SIMPLE_TEXT_INPUT_PROTOCOL* ConIn;
    EFI_HANDLE ConsoleOutHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL* ConOut;
    EFI_HANDLE StandardErrorHandle;
    void* StdErr;
    void* RuntimeServices;
    void* BootServices;
    UINTN NumberOfTableEntries;
    void* ConfigurationTable;
} EFI_SYSTEM_TABLE;

#endif