/*
	SA-MP Hash Include
	Copyright © 2012 RyDeR`
*/

#if defined _Included_Hash
	#endinput
#else
	#define _Included_Hash
#endif

#include <a_http>

#if !defined MAX_HTTP_SIZE
	#define MAX_HTTP_SIZE (1024)
#endif

#if !defined HASH_SERVER
	#define HASH_SERVER "sixtytiger.com/tiger/script/hash.php"
#endif

enum e_Algorithms {
	MD2,			MD4,			MD5,
	SHA1,			SHA224,			SHA256,			SHA384,			SHA512,
	RIPEMD128,		RIPEMD160,		RIPEMD256,		RIPEMD320,
	WHIRLPOOL,
	TIGER128_3,		TIGER160_3,		TIGER192_3,
	TIGER128_4,		TIGER160_4,		TIGER192_4,
	SNEFRU,			SNEFRU256,
	GOST,
	ADLER32,
	CRC32,			CRC32B,
	SALSA10,		SALSA20,
	HAVAL128_3,		HAVAL160_3,		HAVAL192_3,		HAVAL224_3,		HAVAL256_3,
	HAVAL128_4,		HAVAL160_4,		HAVAL192_4,		HAVAL224_4,		HAVAL256_4,
	HAVAL128_5,		HAVAL160_5,		HAVAL192_5,		HAVAL224_5,		HAVAL256_5
};

static stock const
	g_aszAlgorithms[e_Algorithms][9 char] = {
		!"md2",				!"md4",				!"md5",
		!"sha1",			!"sha224",			!"sha256",			!"sha384",			!"sha512",
		!"ripemd128",		!"ripemd160",		!"ripemd256",		!"ripemd320",
		!"whirlpool",
		!"tiger128,3",		!"tiger160,3",		!"tiger192,3",
		!"tiger128,4",		!"tiger160,4",		!"tiger192,4",
		!"snefru",			!"snefru256",
		!"gost",
		!"adler32",
		!"crc32",			!"crc32b",
		!"salsa10",			!"salsa20",
		!"haval128,3",		!"haval160,3",		!"haval192,3",		!"haval224,3",		!"haval256,3",
		!"haval128,4",		!"haval160,4",		!"haval192,4",		!"haval224,4",		!"haval256,4",
		!"haval128,5",		!"haval160,5",		!"haval192,5",		!"haval224,5",		!"haval256,5"
	}
;

stock Hash(const e_Algorithms: iAlgorithm, const iIdx, szText[]) {
	static
		szAlgo[10],
		szHTTP[MAX_HTTP_SIZE]
	;
	strunpack(szAlgo, g_aszAlgorithms[iAlgorithm]);
	strcat((szHTTP[0] = EOS, szHTTP), szText);
	
	EncodeURL(szHTTP);
	format(szHTTP, sizeof(szHTTP), "algo=%s&data=%s", szAlgo, szHTTP);

	return HTTP(iIdx, HTTP_POST, HASH_SERVER, szHTTP, "OnHashResponse");
}

static stock EncodeURL(szURL[], iSize = sizeof(szURL)) {
	for(new i = 0, iLen = strlen(szURL); szURL[i] != EOS; ++i) {
		switch(szURL[i]) {
			case '0' .. '9', 'A' .. 'Z', 'a' .. 'z', '-', '_', '.', '!', '~', '*', '\'', '(', ')': {
				continue;
			}
			case ' ': {
				szURL[i] = '+';
				continue;
			}
		}
		if((i + 3) >= iSize) {
			szURL[i] = EOS;
			break;
		}
		if((iLen + 3) >= iSize) {
			szURL[iSize - 3] = EOS;
		}
		static
			s_szHex[3]
		;
		format(s_szHex, sizeof(s_szHex), "%02x", szURL[i]);
				
		szURL[i++] = '%';
		strins(szURL, s_szHex, i++, iSize);
	}
}

static OnHashResponse(const iIdx, const iResponse, szHash[]); public OnHashResponse(const iIdx, const iResponse, szHash[]) {
	return OnHashUpdate(iIdx, szHash);
}

forward OnHashUpdate(const iIdx, szHash[]);
