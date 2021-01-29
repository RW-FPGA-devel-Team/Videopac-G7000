#include "osd.h"
#include "menu.h"
#include "keyboard.h"
#include "host.h"

int joykeys; // (VM)(HR) xxxBRLDU (P2) xxxBRLDU (P1)
int keys_p1[5] = { 0x1d, 0x1b, 0x1c, 0x23, 0x2b}; // WSAD -> F (Default)
int keys_p2[5] = { 0x43, 0x42, 0x3b, 0x4b, 0x33}; // IKJL -> H (Default)

//joystick input
extern int joy_pins; //(ZXUNO/ZXDOS)SACBRLDU

static struct menu_entry *menu;
static int menu_visible=0;
int menu_toggle_bits=6;
static int menurows;
//static int currentrow;
int currentrow;
static struct hotkey *hotkeys;

void DelayJoystick()
{
	int k;

	for (k=0; k<2000; k++)//wait to release the joystick
	{
			Delay();
	}
}

struct menu_entry *Menu_Get()
{
	return(menu);
}

void Menu_Show()
{
	OSD_Show(menu_visible=1);
}

void Menu_Hide()
{
	// Wait for key releases before hiding the menu, to avoid stray keyup messages reaching the host core.
	while(TestKey(KEY_ESC) || TestKey(KEY_ENTER) || TestKey(keys_p1[4]))
		HandlePS2RawCodes();
	OSD_Show(menu_visible=0);
}


static void DrawSlider(struct menu_entry *m)
{
	int i;
	for(i=0;i<=MENU_SLIDER_MAX(m);++i) // One extra character to leave a space before the label
	{
		OSD_Putchar(i<MENU_SLIDER_VALUE(m) ? 0x07 : 0x20);
	}
}


void Menu_Draw()
{
	struct menu_entry *m=menu;
	OSD_Clear();
	menurows=0;
	while(m->type!=MENU_ENTRY_NULL)
	{
		int i;
		char **labels;
		OSD_SetX(2);
		OSD_SetY(menurows);
		switch(m->type)
		{
			case MENU_ENTRY_CYCLE:
				i=MENU_CYCLE_VALUE(m);	// Access the first byte
				labels=(char**)m->label;
				OSD_Puts("\x16 ");
				OSD_Puts(labels[i]);
				break;
			case MENU_ENTRY_SLIDER:
				DrawSlider(m);
				OSD_Puts(m->label);
				break;
			case MENU_ENTRY_TOGGLE:
				if((menu_toggle_bits>>MENU_ACTION_TOGGLE(m->action))&1)
					OSD_Puts("\x14 ");
				else
					OSD_Puts("\x15 ");
				// Fall through
			default:
				OSD_Puts(m->label);
				break;
		}
		++menurows;
		m++;
	}
}


void Menu_Set(struct menu_entry *head)
{
	menu=head;
	Menu_Draw();
	currentrow=menurows-1;
}


void Menu_SetHotKeys(struct hotkey *head)
{
	hotkeys=head;
}

int Menu_Run()
{
	int i;
	struct menu_entry *m=menu;
	struct hotkey *hk=hotkeys;

	if(TestKey(KEY_ESC)&2)
	{
		while(TestKey(KEY_ESC))
			HandlePS2RawCodes(); // Wait for KeyUp message before opening OSD, since this disables the keyboard for the MSX core.
		OSD_Show(menu_visible^=1);
	}

	joykeys=0;

	int auxkey;

	if(TestKey(KEY_F4)&2) // Swapping players keys...
	{
		auxkey = keys_p2[0]; keys_p2[0] = keys_p1[0]; keys_p1[0] = auxkey;
		auxkey = keys_p2[1]; keys_p2[1] = keys_p1[1]; keys_p1[1] = auxkey;
		auxkey = keys_p2[2]; keys_p2[2] = keys_p1[2]; keys_p1[2] = auxkey;
		auxkey = keys_p2[3]; keys_p2[3] = keys_p1[3]; keys_p1[3] = auxkey;
		auxkey = keys_p2[4]; keys_p2[4] = keys_p1[4]; keys_p1[4] = auxkey;
	}

	if (( joy_pins & 0x20 ) > 0 ) //Fire 2 (C) //(ZXUNO/ZXDOS)SACBRLDU
	{
		if (( joy_pins & 0x20 ) > 0 ) DelayJoystick(); //wait to release the joystick

		HandlePS2RawCodes();
		OSD_Show(menu_visible^=1);
	}

	if(!menu_visible)	// Swallow any keystrokes that occur while the OSD is hidden...
	{

		// Player 1
		if(TestKey(keys_p1[0]))
			joykeys|=0x01;
		if(TestKey(keys_p1[1]))
			joykeys|=0x02;
		if(TestKey(keys_p1[2]))
			joykeys|=0x04;
		if(TestKey(keys_p1[3]))
			joykeys|=0x08;
		if(TestKey(keys_p1[4]))
			joykeys|=0x10;

		// Player 2
		if(TestKey(keys_p2[0]))
			joykeys|=0x100;
		if(TestKey(keys_p2[1]))
			joykeys|=0x200;
		if(TestKey(keys_p2[2]))
			joykeys|=0x400;
		if(TestKey(keys_p2[3]))
			joykeys|=0x800;
		if(TestKey(keys_p2[4]))
			joykeys|=0x1000;

		//Ctrl keys
		if(TestKey(KEY_LCTRL) & TestKey(KEY_ALT) & TestKey(KEY_BCKSPC) )
			joykeys|=0x10000; //Hard reset
		if(TestKey(KEY_SCROLLLOCK) | TestKey(KEY_F12) )
			joykeys|=0x20000; //Video mode

		HW_HOST(REG_HOST_JOYKEY) = joykeys;

		return(menu_visible);;
	}
	if(menu_visible)	// Swallow any keystrokes that occur while the OSD is visible...
	{
		//Ctrl keys
		if(TestKey(KEY_LCTRL) & TestKey(KEY_ALT) & TestKey(KEY_BCKSPC) )
			joykeys|=0x10000; //Hard reset
		if(TestKey(KEY_SCROLLLOCK) | TestKey(KEY_F12) )
			joykeys|=0x20000; //Video mode

		HW_HOST(REG_HOST_JOYKEY) = joykeys;
	}

	// UP  //(ZXUNO/ZXDOS)SACB RLDU
	if((TestKey(KEY_UPARROW)&2) || (TestKey(keys_p1[0])&2) || ((joy_pins & 0x01 )>0))
	{
		if (( joy_pins & 0x01 ) > 0 ) DelayJoystick(); //wait to release the joystick

		if(currentrow)
			--currentrow;
		else if((m+menurows)->action)
			MENU_ACTION_CALLBACK((m+menurows)->action)(ROW_LINEUP);
	}
	// DOWN //(ZXUNO/ZXDOS)SACB RLDU
	if((TestKey(KEY_DOWNARROW)&2) || (TestKey(keys_p1[1])&2) || ((joy_pins & 0x02 )>0))
	{
		if (( joy_pins & 0x02 ) > 0) DelayJoystick(); //wait to release the joystick

		if(currentrow<(menurows-1))
			++currentrow;
		else if((m+menurows)->action)
			MENU_ACTION_CALLBACK((m+menurows)->action)(ROW_LINEDOWN);
	}
  // LEFT == PAGEUP //(ZXUNO/ZXDOS)SACB RLDU
	if((TestKey(KEY_PAGEUP)&2) || (TestKey(keys_p1[2])&2) || ((joy_pins & 0x04 )>0))
	{
		if (( joy_pins & 0x04 ) > 0) DelayJoystick(); //wait to release the joystick

		if(currentrow)
			currentrow=0;
		else if((m+menurows)->action)
			MENU_ACTION_CALLBACK((m+menurows)->action)(ROW_PAGEUP);
	}
  // RIGHT == PAGEDOWN //(ZXUNO/ZXDOS)SACB RLDU
	if((TestKey(KEY_PAGEDOWN)&2) || (TestKey(keys_p1[3])&2) || ((joy_pins & 0x08 )>0))
	{
		if (( joy_pins & 0x08 ) > 0) DelayJoystick(); //wait to release the joystick

		if(currentrow<(menurows-1))
			currentrow=menurows-1;
		else if((m+menurows)->action)
			MENU_ACTION_CALLBACK((m+menurows)->action)(ROW_PAGEDOWN);
	}

	// Find the currently highlighted menu item
	i=currentrow;
	while(i)
	{
		++m;
		--i;
	}

	OSD_SetX(2);
	OSD_SetY(currentrow);

	if(TestKey(KEY_LEFTARROW)&2) // Decrease slider value
	{
		switch(m->type)
		{
			case MENU_ENTRY_SLIDER:
				if((--MENU_SLIDER_VALUE(m))&0x80) // <0?
					MENU_SLIDER_VALUE(m)=0;
				DrawSlider(m);
				break;
			default:
				break;
		}
	}

	if(TestKey(KEY_RIGHTARROW)&2) // Increase slider value
	{
		switch(m->type)
		{
			case MENU_ENTRY_SLIDER:
				if((++MENU_SLIDER_VALUE(m))>MENU_SLIDER_MAX(m))
					MENU_SLIDER_VALUE(m)=MENU_SLIDER_MAX(m);
				DrawSlider(m);
				break;
			default:
				break;
		}
	}

  //F1 (B) //(ZXUNO/ZXDOS)SACB RLDU
	//if((TestKey(KEY_ENTER)&2) || (TestKey(keys_p1[4])&2) || ((joy_pins & 0x01 )>0))
	if((TestKey(KEY_ENTER)&2) || ((joy_pins & 0x10 )>0)) //F1 (B)
	{
		struct menu_entry *m=menu;

		if (( joy_pins & 0x10 ) > 0 ) DelayJoystick(); //wait to release the joystick

		i=currentrow;
		while(i)
		{
			++m;
			--i;
		}
		switch(m->type)
		{
			case MENU_ENTRY_SUBMENU:
				Menu_Set(MENU_ACTION_SUBMENU(m->action));
				break;
			case MENU_ENTRY_CALLBACK:
				MENU_ACTION_CALLBACK(m->action)(currentrow);
				break;
			case MENU_ENTRY_TOGGLE:
				i=1<<MENU_ACTION_TOGGLE(m->action);
				menu_toggle_bits^=i;
				Menu_Draw();
				break;
			case MENU_ENTRY_CYCLE:
				i=MENU_CYCLE_VALUE(m)+1;
				if(i>=MENU_CYCLE_COUNT(m))
					i=0;
				MENU_CYCLE_VALUE(m)=i;
				Menu_Draw();
				break;
			default:
				break;

		}
	}

	while(hk && hk->key)
	{
		if(TestKey(hk->key)&1)	// Currently pressed?
			hk->callback(currentrow);
		++hk;
	}

	for(i=0;i<OSD_ROWS-1;++i)
	{
		OSD_SetX(0);
		OSD_SetY(i);
		OSD_Putchar(i==currentrow ? (i==menurows-1 ? 17 : 16) : 32);
	}

	return(menu_visible);
}
