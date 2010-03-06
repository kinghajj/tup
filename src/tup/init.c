#include "init.h"
#include "config.h"
#include "db.h"
#include "lock.h"
#include <unistd.h>

int tup_init(void)
{
	if(find_tup_dir() != 0) {
		fprintf(stderr, "No .tup directory found. Run 'tup init' at the top of your project to create the dependency filesystem.\n");
		return -1;
	}
#ifndef TUP_NO_MONITOR
	if(tup_lock_init() < 0) {
		return -1;
	}
#endif
	if(tup_db_open() != 0) {
#ifndef TUP_NO_MONITOR
		tup_lock_exit();
#endif
		return -1;
	}
	return 0;
}

void tup_cleanup(void)
{
	tup_db_close();
#ifndef TUP_NO_MONITOR
	tup_lock_exit();
#endif
	close(tup_top_fd());
}
