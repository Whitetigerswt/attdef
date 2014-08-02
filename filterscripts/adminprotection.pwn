#include <a_samp>
#include <zcmd>

public OnPlayerCommandReceived(playerid, cmdtext[])
{

	if(!strcmp("/code", cmdtext, true))
	{
	    return 1;
	}
	return 0;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
    if(!strcmp("/code", cmdtext, true))
	{
	    return 1;
	}
	return 0;
}
