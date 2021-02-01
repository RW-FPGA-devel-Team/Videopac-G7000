#include "host.h"

#include "osd.h"
#include "keyboard.h"
#include "menu.h"
#include "ps2.h"
#include "minfat.h"
#include "spi.h"
#include "fileselector.h"

fileTYPE file;


int OSD_Puts(char *str)
{
	int c;
	while((c=*str++))
		OSD_Putchar(c);
	return(1);
}

void Delay()
{
	int c=16384; // delay some cycles
	while(c)
	{
		c--;
	}
}
void SuperDelay()
{	int i=1;
	for (i=1;i<=576;i++)
	{
		Delay();
	}
}

void Reset(int row)
{
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_RESET|HOST_CONTROL_DIVERT_KEYBOARD; // Reset host core
	Delay();
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_KEYBOARD;
	Menu_Hide();
}

void Video(int row)
{
	
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_VIDEO|HOST_CONTROL_DIVERT_KEYBOARD; // Send start
	Delay();
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_KEYBOARD;
}

void NMI(int row)
{
	
	Menu_Hide();
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_NMI|HOST_CONTROL_DIVERT_KEYBOARD; // Send start
	Delay();
	HW_HOST(REG_HOST_CONTROL)=0;
}

static struct menu_entry topmenu[]; // Forward declaration.

static char *st_scanlines[]=
{
	"Scanlines None",
	"Scanlines CRT 25%",
	"Scanlines CRT 50%",
	"Scanlines CRT 75%"
};

static char *st_system[]=
{
	"Odyssey2",
	"Videopac"
};

static char *st_pal[]=
{
	"Composite",
	"RGB"
};


static char *st_tv[]=
{
	"TV Color",
	"TV B/W"
};

static char *st_voice[]=
{
	"The Voice Off",
	"The Voice On"
};

static char *st_swap[]=
{
	"Swap Joy Off",
	"Swap joy On"
};

// Our toplevel menu
static struct menu_entry topmenu[]=
{
//      NUMERO MAXIMO DE LINEAS EN MENU SON 16 (PARA MAS HACER SUBMENUS)
	{MENU_ENTRY_CALLBACK,"   =Rampa Videopac=    ",0},
	{MENU_ENTRY_CALLBACK,"                       ",0},
	{MENU_ENTRY_CALLBACK,"Reset",MENU_ACTION(&Reset)},
	{MENU_ENTRY_CYCLE,(char *)st_scanlines,MENU_ACTION(4)}, 
	{MENU_ENTRY_CYCLE,(char *)st_swap,MENU_ACTION(2)}, 
	{MENU_ENTRY_CYCLE,(char *)st_voice,MENU_ACTION(2)},
	{MENU_ENTRY_CYCLE,(char *)st_pal,MENU_ACTION(2)},
	{MENU_ENTRY_CYCLE,(char *)st_system,MENU_ACTION(2)},
	{MENU_ENTRY_CYCLE,(char *)st_tv,MENU_ACTION(2)},
	{MENU_ENTRY_CALLBACK,"Cargar Cartucho/Font \x10",MENU_ACTION(&FileSelector_Show)},
	{MENU_ENTRY_CALLBACK,"Exit",MENU_ACTION(&Menu_Hide)},
	{MENU_ENTRY_NULL,0,0}
};


// An error message
static struct menu_entry loadfailed[]=
{
	{MENU_ENTRY_SUBMENU,"Carga Fallida",MENU_ACTION(loadfailed)},
	{MENU_ENTRY_SUBMENU,"OK",MENU_ACTION(&topmenu)},
	{MENU_ENTRY_NULL,0,0}
};


static int LoadMED(const char *filename)
{
	int result=0;
	int opened;

	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_LOADMED | HOST_CONTROL_DIVERT_SDCARD;

	if((opened=FileOpen(&file,filename)))
	{
		int filesize=file.size;
		unsigned int c=0;
		int bits;

		HW_HOST(REG_HOST_ROMSIZE) = file.size;
		HW_HOST(REG_HOST_ROMEXT) = ((char)filename[10])+((char)filename[9]<<8)+((char)filename[8]<<16); //Pasa 24 Bits las 3 letras de la Extension en el registro de 31 bits (la primera en los bits 23:16 la segunda  en 15:7 y la tercera en 7:0	
		
		bits=0;
		c=filesize-1;
		while(c)
		{
			++bits;
			c>>=1;
		}
		bits-=9;

		result=1;

		while(filesize>0)
		{
			OSD_ProgressBar(c,bits);
			if(FileRead(&file,sector_buffer))
			{
				int i;
				int *p=(int *)&sector_buffer;
				for(i=0;i<512;i+=4)
				{
					unsigned int t=*p++;
					unsigned char t1=t;
					unsigned char t2=t>>8;
					unsigned char t3=t>>16;
					unsigned char t4=t>>24;
					HW_HOST(REG_HOST_BOOTDATA)=t4;
					HW_HOST(REG_HOST_BOOTDATA)=t3;
					HW_HOST(REG_HOST_BOOTDATA)=t2;
					HW_HOST(REG_HOST_BOOTDATA)=t1;
				}
			}
			else
			{
				result=0;
				filesize=512;
			}
			FileNextSector(&file);
			filesize-=512;
			++c;
		}
	}

	SuperDelay();
	HW_HOST(REG_HOST_CONTROL)=0;

	if(result)
		{
		Menu_Set(topmenu);
		Menu_Hide();
		}
	else
		Menu_Set(loadfailed);

	return(result);
}


static int LoadROM(const char *filename)
{
	int result=0;
	int opened;

	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_LOADROM | HOST_CONTROL_DIVERT_SDCARD;

	if((opened=FileOpen(&file,filename)))
	{
		int filesize=file.size;
		unsigned int c=0;
		int bits;

		bits=0;
		c=filesize-1;
		while(c)
		{
			++bits;
			c>>=1;
		}
		bits-=9;

		result=1;

		while(filesize>0)
		{
			OSD_ProgressBar(c,bits);
			if(FileRead(&file,sector_buffer))
			{
				int i;
				int *p=(int *)&sector_buffer;
				for(i=0;i<512;i+=4)
				{
					unsigned int t=*p++;
					unsigned char t1=t;
					unsigned char t2=t>>8;
					unsigned char t3=t>>16;
					unsigned char t4=t>>24;
					HW_HOST(REG_HOST_BOOTDATA)=t4;
					HW_HOST(REG_HOST_BOOTDATA)=t3;
					HW_HOST(REG_HOST_BOOTDATA)=t2;
					HW_HOST(REG_HOST_BOOTDATA)=t1;
				}
			}
			else
			{
				result=0;
				filesize=512;
			}
			FileNextSector(&file);
			filesize-=512;
			++c;
		}
	}
	HW_HOST(REG_HOST_ROMSIZE) = file.size;
	SuperDelay();
	HW_HOST(REG_HOST_CONTROL)=0;
	return(result);
}


int main(int argc,char **argv)
{
	int i;
	int dipsw=0;

	// Put the host core in reset while we initialise...
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_RESET|HOST_CONTROL_DIVERT_SDCARD;

	PS2Init();
	EnableInterrupts();

	OSD_Clear();

	if(!FindDrive())
		return(0);

	//OSD_Puts("Loading initial ROM...\n");
	//LoadROM("SPECTRUMDAT");
	FileSelector_SetLoadFunction(LoadMED);
	Menu_Set(topmenu);

	Menu_Hide();//oculta el menu por defecto al cargar el core.
	//Menu_Show(); //muestra el menu por defecto al cargar el core.

	while(1)
	{
		struct menu_entry *m;
		int visible;
		HandlePS2RawCodes();
		visible=Menu_Run();
		dipsw = 0;
		//Posicion 3 del menu, 0x3 = 2 bits max, <<9 = dips[1:0]	
		dipsw |= (MENU_CYCLE_VALUE(&topmenu[3])  & 0x3) << 9; //[11:9] 
		dipsw |= (MENU_CYCLE_VALUE(&topmenu[4])  & 0x1) << 7; //[7]
		dipsw |= (MENU_CYCLE_VALUE(&topmenu[5])  & 0x1) << 1; //[1]
		dipsw |= (MENU_CYCLE_VALUE(&topmenu[6])  & 0x1) << 5; //[5]
		dipsw |= (MENU_CYCLE_VALUE(&topmenu[7])  & 0x1) << 14; //[14]
		dipsw |= (MENU_CYCLE_VALUE(&topmenu[8])  & 0x1) << 6; //[6]
		HW_HOST(REG_HOST_SW)=dipsw;	// Send the new values to the hardware.
		// If the menu's visible, prevent keystrokes reaching the host core.
		HW_HOST(REG_HOST_CONTROL)=(visible ?
									HOST_CONTROL_DIVERT_KEYBOARD|HOST_CONTROL_DIVERT_SDCARD : 0); // Maintain control of the SD card so the file selector can work.
																 // If the host needs SD card access then we would release the SD
																 // card here, and not attempt to load any further files.
	}
	return(0);
}
