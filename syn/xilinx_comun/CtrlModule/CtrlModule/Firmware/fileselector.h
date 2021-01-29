#ifndef FILESELECTOR_H
#define FILESELECTOR_H

void FileSelector_Show(int row);
void FileSelectorCHAR_Show(int row);
void FileSelectorROM_Show(int row);
void FileSelector_SetLoadFunction(int (*func)(const char *filename, const char *extension));

#endif
