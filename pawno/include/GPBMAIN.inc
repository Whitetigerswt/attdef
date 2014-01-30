
#if defined GPB_libGLOBAL_included

#else

//
#if defined UPDATE_FILE
	#undef UPDATE_FILE
#endif
#define UPDATE_FILE "GPB_updater.check"
//
#if defined UPDATE_URL
	#undef UPDATE_URL
#endif
#define UPDATE_URL "gz.pxf24.pl/gpb_update.php"
//

#define GPB_libGLOBAL_included
#define GPB_libGLOBAL_new
new
	___PRIV_gpb_updates[2] = {0,0}
	//,___PRIV_update_str[2048]
	;

stock privGPB_AddUpdatecheck(name[],amount,v1,v2=0,v3=0,v4=0,v5=0,v6=0,v7=0,v8=0)
{
	new towrite[128];
	format(towrite,256,"%s|%s|%d",name,UPDATE_URL,amount);
    if(amount >= 1)format(towrite,256,"%s|%d",towrite,v1);
    if(amount >= 2)format(towrite,256,"%s|%d",towrite,v2);
    if(amount >= 3)format(towrite,256,"%s|%d",towrite,v3);
    if(amount >= 4)format(towrite,256,"%s|%d",towrite,v4);
    if(amount >= 5)format(towrite,256,"%s|%d",towrite,v5);
    if(amount >= 6)format(towrite,256,"%s|%d",towrite,v6);
    if(amount >= 7)format(towrite,256,"%s|%d",towrite,v7);
    if(amount == 8)format(towrite,256,"%s|%d",towrite,v8);
	format(towrite,256,"%s\r\n",towrite);
    new File:updater;
	if(fexist(UPDATE_FILE))
	{
		updater = fopen(UPDATE_FILE,io_append);
	}
	else
	{
	    updater = fopen(UPDATE_FILE,io_readwrite);
	}
	fwrite(updater,towrite);
	fclose(updater);

	SetTimer("gpb_execute_updater",0,0);
	return 1;
}

stock privGPB_strtok(const string99[], &index,seperator='.')
{
	new length = strlen(string99);
	new offset = index;
	new result[128];
	while ((index < length) && (string99[index] != seperator) && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string99[index];
		index++;
	}

	result[index - offset] = EOS;
	if ((index < length) && (string99[index] == seperator))
	{
		index++;
	}
	return result;
}

forward gpb_execute_updater();
public gpb_execute_updater()
{
    new File:updater;
	if(fexist(UPDATE_FILE))
	{
	    print("GPB: executing updater...");
		updater = fopen(UPDATE_FILE,io_read);
		
		new readstr_gpb[128];
		new gpb_name[32];
		new gpb_url[256];
		new gpb_idx;
		
		while(fread(updater,readstr_gpb))
		{
			gpb_idx = 0;
			format(gpb_name,32,"%s",privGPB_strtok(readstr_gpb,gpb_idx,'|'));
			format(gpb_url,128,"%s",privGPB_strtok(readstr_gpb,gpb_idx,'|'));
			if(strlen(gpb_name) >= 1)
			{
  				++___PRIV_gpb_updates[0];
  				new gpb_loop;
	  			gpb_loop = strval(privGPB_strtok(readstr_gpb,gpb_idx,'|'));
  				new versions[8];
  				format(gpb_url,256,"%s?name=%s",gpb_url,gpb_name);
  				for(new i = 0; i < gpb_loop; ++i)
  				{
  				    versions[i] = strval(privGPB_strtok(readstr_gpb,gpb_idx,'|'));
  				    format(gpb_url,256,"%s&version[%d]=%d",gpb_url,i,versions[i]);
  				}
  				format(gpb_url,256,"%s&port=%d",gpb_url,GetServerVarAsInt("port"));
				HTTP(0,HTTP_GET,gpb_url,"","GPB_UpdateCheck");
   			}
		}
		fclose(updater);
		fremove(UPDATE_FILE);
		printf("GPB: Updater done, looking for %d updates...",___PRIV_gpb_updates[0]);
		return 1;
	}
	return 0;
}

forward GPB_UpdateCheck(index, response_code, data[]);
public GPB_UpdateCheck(index, response_code, data[])
{
	if(___PRIV_gpb_updates[0] != 0)
	{
		if(___PRIV_gpb_updates[1] == 0)
  		print("\r\n--------------------------------\r\nGamer_Z's Project Bundle Update Report\r\nPlease update the following things:");
		print(data);
	    ++___PRIV_gpb_updates[1];
		if(___PRIV_gpb_updates[1] >= ___PRIV_gpb_updates[0])
  		print("\r\n--------------------------------\r\n");
	}
	return 1;
}

#endif

