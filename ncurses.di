module ncurses;

extern(C) struct WINDOW {
	short cury, curx;
	short maxy, maxx;
	short begy, begx;
	short flags;
}
extern(C) __gshared WINDOW* stdscr;

extern(C) int initscr();
extern(C) int getch();
extern(C) int raw();
extern(C) int noecho();
extern(C) int endwin();
extern(C) int delch();
extern(C) int mvdelch(int, int);
extern(C) int keypad(WINDOW*, bool);
extern(C) int refresh();
extern(C) int printw(const(char*));
extern(C) int addch(char);
void getyx(WINDOW* w, int* y, int* x) {
	*x = w ? w.curx : -1;
	*y = w ? w.cury : -1;
}

void getmaxyx(WINDOW* w, int* y, int* x) {
	*x = w ? w.maxx : -1;
	*y = w ? w.maxy : -1;
}
