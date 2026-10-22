"""Report desktop resolution and the current console font cell dimensions."""

import ctypes
from ctypes import wintypes


GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
FILE_SHARE_READ = 0x00000001
FILE_SHARE_WRITE = 0x00000002
OPEN_EXISTING = 3
INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value
SM_CXSCREEN = 0
SM_CYSCREEN = 1


class COORD(ctypes.Structure):
    _fields_ = [("X", ctypes.c_short), ("Y", ctypes.c_short)]


class CONSOLE_FONT_INFOEX(ctypes.Structure):
    _fields_ = [
        ("cbSize", wintypes.ULONG),
        ("nFont", wintypes.DWORD),
        ("dwFontSize", COORD),
        ("FontFamily", wintypes.UINT),
        ("FontWeight", wintypes.UINT),
        ("FaceName", wintypes.WCHAR * 32),
    ]


def main() -> None:
    user32 = ctypes.WinDLL("user32", use_last_error=True)
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    user32.GetSystemMetrics.restype = ctypes.c_int
    screen_width = user32.GetSystemMetrics(SM_CXSCREEN)
    screen_height = user32.GetSystemMetrics(SM_CYSCREEN)

    # stdout may be a pipe when terminal.bat captures this output. Open the
    # console device directly so font information is still available.
    kernel32.CreateFileW.argtypes = [
        wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
        wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE
    ]
    kernel32.CreateFileW.restype = wintypes.HANDLE
    handle = kernel32.CreateFileW(
        "CONOUT$", GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE, None, OPEN_EXISTING, 0, None
    )
    cell_width = cell_height = 0
    if handle and handle != INVALID_HANDLE_VALUE:
        font = CONSOLE_FONT_INFOEX()
        font.cbSize = ctypes.sizeof(font)
        kernel32.GetCurrentConsoleFontEx.argtypes = [
            wintypes.HANDLE, wintypes.BOOL, ctypes.POINTER(CONSOLE_FONT_INFOEX)
        ]
        kernel32.GetCurrentConsoleFontEx.restype = wintypes.BOOL
        if kernel32.GetCurrentConsoleFontEx(handle, False, ctypes.byref(font)):
            cell_width = font.dwFontSize.X
            cell_height = font.dwFontSize.Y
        kernel32.CloseHandle(handle)

    print(f"Reported screen size: {screen_width}x{screen_height}")
    if cell_width > 0 and cell_height > 0:
        print(f"Console cell size: {cell_width}x{cell_height}")
    else:
        print("Console cell size: unavailable")


if __name__ == "__main__":
    main()
