#include <a_samp>
#include <YSF>
#include <zcmd>

CMD:ws(playerid, params[]) {
	TogglePlayerWidescreen(playerid, !!strval(params));
}
