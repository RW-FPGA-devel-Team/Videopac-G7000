#include "host.h"

#include "osd.h"
#include "keyboard.h"
#include "menu.h"
#include "ps2.h"
#include "minfat.h"
#include "spi.h"
#include "fileselector.h"

fileTYPE file;

extern int keys_p1[];
extern int keys_p2[];
extern int joy_pins;  //(SACUDLRB) => SACBRLDU
extern int currentrow;
int dipsw=16; //traspaso de opciones a core
int vdcload=0; //carga de charset de VDC activada

int OSD_Puts(char *str)
{
	int c;
	while((c=*str++))
		OSD_Putchar(c);
	return(1);
}

/*
void TriggerEffect(int row)
{
	int i,v;
	Menu_Hide();
	for(v=0;v<=16;++v)
	{
		for(i=0;i<4;++i)
			PS2Wait();

		HW_HOST(REG_HOST_SCALERED)=v;
		HW_HOST(REG_HOST_SCALEGREEN)=v;
		HW_HOST(REG_HOST_SCALEBLUE)=v;
	}
	Menu_Show();
}
*/
void Delay()
{
	int c=16384; // delay some cycles
	while(c)
	{
		c--;
	}
}
void Reset(int row)
{
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_RESET|HOST_CONTROL_DIVERT_KEYBOARD; // Reset host core
	Delay();
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_KEYBOARD;
}

void MegaDelay()
{	int i=1;
	for (i=1;i<=576;i++)
	{
		Delay();
	}
}

void ResetLoader()
{
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_LOADER_RESET;
	MegaDelay();
}

void NoSelection(int row)
{
}


void Select(int row)
{

	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_SELECT|HOST_CONTROL_DIVERT_KEYBOARD; // Send select
	MegaDelay();
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_KEYBOARD;
}

void Start(int row)
{

	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_START|HOST_CONTROL_DIVERT_KEYBOARD; // Send start
	MegaDelay();
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_KEYBOARD;
}



static struct menu_entry topmenu[]; // Forward declaration.

// joystick type
static char *consolemode_labels[]=
{
	"Mode: Odyssey2 (NTSC)",
	"Mode: Videopac (PAL)"
};


//Color mode:
// bit 5-6 - Color (0)- Monochrome (1) - Green phosphor (2) - Amber monochrome(3)
static char *colormode_labels[]=
{
	"Color mode: Color",
	"Color mode: Monochrome",
	"Color mode: Green phosphor",
	"Color mode: Amber monochrome"
};

// ZXUNO board type
static char *board_labels[]=
{
	"ZXUNO: single joystick",
	"ZXUNO: 2 joystick splitter",
	"ZXUNO: 2 joystick VGA2M",
};

// Our toplevel menu for ZX2
static struct menu_entry topmenu[]=
{
	{MENU_ENTRY_CALLBACK,"== Videopac for ZXDOS ==",MENU_ACTION(&NoSelection)},
	{MENU_ENTRY_CALLBACK,"========================",MENU_ACTION(&NoSelection)},
	{MENU_ENTRY_CALLBACK,"Reset",MENU_ACTION(&Reset)},
	{MENU_ENTRY_TOGGLE,"Scanlines",MENU_ACTION(0)},
	{MENU_ENTRY_TOGGLE,"Swap joysticks",MENU_ACTION(1)},
	{MENU_ENTRY_TOGGLE,"Join joysticks",MENU_ACTION(2)},
	{MENU_ENTRY_CALLBACK,"Load catridge ROM \x10",MENU_ACTION(&FileSelectorROM_Show)},
	{MENU_ENTRY_CALLBACK,"Load VDC font \x10",MENU_ACTION(&FileSelectorCHAR_Show)},
	{MENU_ENTRY_CYCLE,(char *)consolemode_labels,MENU_ACTION(2)},
	{MENU_ENTRY_CYCLE,(char *)colormode_labels,MENU_ACTION(4)},
	{MENU_ENTRY_CALLBACK,"Exit",MENU_ACTION(&Menu_Hide)},
	{MENU_ENTRY_NULL,0,0}
};

// Our toplevel menu for ZX1
static struct menu_entry topmenu1[]=
{
	{MENU_ENTRY_CALLBACK,"== Videopac for ZXUNO ==",MENU_ACTION(&NoSelection)},
	{MENU_ENTRY_CALLBACK,"========================",MENU_ACTION(&NoSelection)},
	{MENU_ENTRY_CALLBACK,"Reset",MENU_ACTION(&Reset)},
	{MENU_ENTRY_TOGGLE,"Scanlines",MENU_ACTION(0)},
	{MENU_ENTRY_TOGGLE,"Swap joysticks",MENU_ACTION(1)},
	{MENU_ENTRY_TOGGLE,"Join joysticks",MENU_ACTION(2)},
	{MENU_ENTRY_CALLBACK,"Load catridge ROM \x10",MENU_ACTION(&FileSelectorROM_Show)},
	{MENU_ENTRY_CALLBACK,"Load VDC font \x10",MENU_ACTION(&FileSelectorCHAR_Show)},
	{MENU_ENTRY_CYCLE,(char *)consolemode_labels,MENU_ACTION(2)},
	{MENU_ENTRY_CYCLE,(char *)colormode_labels,MENU_ACTION(4)},
	{MENU_ENTRY_CYCLE,(char *)board_labels,MENU_ACTION(3)},
	{MENU_ENTRY_CALLBACK,"Exit",MENU_ACTION(&Menu_Hide)},
	{MENU_ENTRY_NULL,0,0}
};

// An error message
static struct menu_entry loadfailed[]=
{
	{MENU_ENTRY_SUBMENU,"ROM loading failed",MENU_ACTION(loadfailed)},
	{MENU_ENTRY_SUBMENU,"OK",MENU_ACTION(&topmenu)},
	{MENU_ENTRY_NULL,0,0}
};

static int LoadKeys()
{
	int opened;

	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_RESET;
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_SDCARD; // Release reset but take control of the SD card

	if((opened=FileOpen(&file,"KEYSP1     \0")))
	{
		if(FileRead(&file,sector_buffer))
		{

			keys_p1[0] = (int)sector_buffer[0];
			keys_p1[1] = (int)sector_buffer[1];
			keys_p1[2] = (int)sector_buffer[2];
			keys_p1[3] = (int)sector_buffer[3];
			keys_p1[4] = (int)sector_buffer[4];
		}
	}

	if((opened=FileOpen(&file,"KEYSP2     \0")))
	{
		if(FileRead(&file,sector_buffer))
		{
			keys_p2[0] = (int)sector_buffer[0];
			keys_p2[1] = (int)sector_buffer[1];
			keys_p2[2] = (int)sector_buffer[2];
			keys_p2[3] = (int)sector_buffer[3];
			keys_p2[4] = (int)sector_buffer[4];
		}
	}

}


static int LoadROM(const char *filename, const char *extension)
{
	int result=0;
	int opened;
	//HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_RESET;

  //HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_LOADER_RESET;
	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_SDCARD; // Release reset but take control of the SD card

	if (vdcload==1) {
		dipsw=(dipsw|256); //load Charset
	}
	else{
		dipsw=((dipsw|256)^256); //load ROM
	}
	HW_HOST(REG_HOST_SW)=dipsw;	// Send the new values to the hardware.
	Delay();

	if((opened=FileOpen(&file,filename)))
	{
		int filesize=file.size;
		unsigned int c=0;
		int bits;

		if (filesize == 5)
		{

			OSD_Puts(filename);
			MegaDelay();
			MegaDelay();
			MegaDelay();
			MegaDelay();
			MegaDelay();
			MegaDelay();
			//Menu_Set(topmenu);
			if(joy_pins & 0x100) //(ZXUNO/ZXDOS)(SACUDLRB) => (ZXUNO/ZXDOS)SACBRLDU
				Menu_Set(topmenu1); //ZXUNO menu
			else
				Menu_Set(topmenu); //ZXDOS menu
			return 1;

		}

		HW_HOST(REG_HOST_ROMSIZE) = file.size;
		HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_LOADER_RESET|HOST_CONTROL_RESET|HOST_CONTROL_DIVERT_SDCARD;
		MegaDelay();
		HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_SDCARD; // Release reset but take control of the SD card

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
				//unsigned char *p=&sector_buffer;
				//for(i=0;i<512;i+=1)
				{
					unsigned int t=*p++;
					HW_HOST(REG_HOST_BOOTDATA)=t;
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

	if (vdcload==0) {
		Reset(0);
  }
	else{
	  vdcload=0;
		dipsw=((dipsw|256)^256); //load ROM
	  HW_HOST(REG_HOST_SW)=dipsw;	// Send the new values to the hardware.
	}

	if(result) {
	//	OSD_Show(0);
	//	Menu_Set(topmenu);
		if(joy_pins & 0x100)
			Menu_Set(topmenu1); //ZXUNO menu
		else
			Menu_Set(topmenu); //ZXDOS menu
	}
	else
		Menu_Set(loadfailed);
	return(result);
}


int main(int argc,char **argv)
{
	int i;
	//int dipsw=16;
	// bit 0 - Scanlines
	// bit 1 - Swap joysticks
	// bit 2-3 - UNO board
	// bit 4 - NTSC-Odyssey2/PAL-Videopac
	// bit 5-6 - Color (0)- Monochrome (1) - Green phosphor (2) - Amber monochrome(3)
	// bit 7 - Join joysticks

	// Put the host core in reset while we initialise...
//	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_RESET;
	Reset(0);

	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_SDCARD;

	PS2Init();
	EnableInterrupts();

	OSD_Clear();
	for(i=0;i<4;++i)
	{
		PS2Wait();	// Wait for an interrupt - most likely VBlank, but could be PS/2 keyboard
		OSD_Show(1);	// Call this over a few frames to let the OSD figure out where to place the window.
	}

	HW_HOST(REG_HOST_CONTROL)=HOST_CONTROL_DIVERT_SDCARD; // Release reset but take control of the SD card
	OSD_Puts("Initializing SD card\n");

	if(!FindDrive())
		return(0);

//	OSD_Puts("Loading initial ROM...\n");

//	LoadROM("PIC1    RAW");

	LoadKeys();

	FileSelector_SetLoadFunction(LoadROM);


// Valores iniciales menu
	MENU_TOGGLE_VALUES = dipsw;
	HW_HOST(REG_HOST_SW)=dipsw;

	if(joy_pins & 0x100)
		Menu_Set(topmenu1); //ZXUNO menu
	else
		Menu_Set(topmenu); //ZXDOS menu

	currentrow=6; //Load ROM as default option
	Menu_Show();

	//OSD_Show(0);	// Hide OSD menu
	//Menu_Hide();

	while(1)
	{
		struct menu_entry *m;
		int visible;
		HandlePS2RawCodes();
		visible=Menu_Run();

		// bit 0 - Scanlines
		// bit 1 - Swap joysticks
		// bit 2-3 - UNO board
		// bit 4 - NTSC-Odyssey2/PAL-Videopac
		// bit 5-6 - Color (0)- Monochrome (1) - Green phosphor (2) - Amber monochrome(3)
		// bit 7 - Join joysticks

		if(joy_pins & 0x100) { //ZXUNO
			dipsw=(MENU_CYCLE_VALUE(&topmenu1[8])<<4);	// (1bit: 4)Take the value of NTSC/PAL mode
			dipsw|=(MENU_CYCLE_VALUE(&topmenu1[9])<<5);	// (2bit: 5:6)Take the value of the color mode
			dipsw|=(MENU_CYCLE_VALUE(&topmenu1[10])<<2);	// (2bit: 2:3)Take the value of the board model
	  }
		else { //ZXDOS
			dipsw=(MENU_CYCLE_VALUE(&topmenu[8])<<4);	// (1bit: 1)Take the value of NTSC/PAL mode
			dipsw|=(MENU_CYCLE_VALUE(&topmenu[9])<<5);	// (2bit: 5:6)Take the value of the color mode
			//dipsw|=(MENU_CYCLE_VALUE(&topmenu1[6])<<2);	// (2bit: 2:3)Take the value of the board model
		}

		//dipsw=MENU_CYCLE_VALUE(&topmenu[1]);	// Take the value of the TestPattern cycle menu entry.
		if(MENU_TOGGLE_VALUES&1)
			dipsw|=1;	// Add in the scanlines bit.
	  if(MENU_TOGGLE_VALUES&2)
	  	dipsw|=2;	// Add in the swap joystick option
		if(MENU_TOGGLE_VALUES&4)
			dipsw|=128;	// Add in the join joystick option
		//if(MENU_TOGGLE_VALUES&8)
		//	dipsw|=8;	// Add in the Diff A bit
		//if(MENU_TOGGLE_VALUES&16)
		//	dipsw|=16;	// Add in the Diff B bit
		//if(MENU_TOGGLE_VALUES&32)
		//	dipsw|=32;	// Add in the double OSD window
		HW_HOST(REG_HOST_SW)=dipsw;	// Send the new values to the hardware.

		// If the menu's visible, prevent keystrokes reaching the host core.
		HW_HOST(REG_HOST_CONTROL)=(visible ?
				HOST_CONTROL_DIVERT_KEYBOARD|HOST_CONTROL_DIVERT_SDCARD :
				HOST_CONTROL_DIVERT_SDCARD); // Maintain control of the SD card so the file selector can work.
																 // If the host needs SD card access then we would release the SD
																 // card here, and not attempt to load any further files.
	}
	return(0);
}
