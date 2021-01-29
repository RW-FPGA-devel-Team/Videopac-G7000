#include <stdio.h>
#include <string.h>


#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c\n"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0')
  
int main (int argc, char *argv[])
{
	FILE *f;
	unsigned char *scr;
	char nombre[256];
	int i,leido;
	
	if (argc<2)
		return 1;
	
	scr = malloc(65536);
	f = fopen (argv[1],"rb");
	if (!f)
		return 1;
		
	leido = fread (scr, 1, 65536, f);
	fclose (f);
	
	strcpy (nombre, argv[1]);
	nombre[strlen(nombre)-3]=0;
	strcat (nombre, "mif");
	
	f = fopen (nombre, "wt");
	for (i=0;i<leido;i++)
		//fprintf (f, "%.2X\n", scr[i]);
		fprintf(f,BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(scr[i]));
	fclose(f);
	
	return 0;
}

