// ConsoleApplication5.cpp: определяет точку входа для консольного приложения.
//

#define _CRT_SECURE_NO_WARNINGS  1

#include "stdafx.h"

#include <stdio.h>
#include <stdlib.h>
#include "string.h"
#include "ctype.h"

#define WIN32 1

#ifdef WIN32
typedef signed char   int8_t;
typedef short int   int16_t;
typedef int       int32_t;
typedef long int  int64_t;

typedef unsigned char     uint8_t;
typedef unsigned short int    uint16_t;
typedef unsigned int      uint32_t;
/* typedef unsigned short   uint16_t; */
typedef unsigned long int uint64_t;
#endif // WIN32

#define IRT_1730U_CNS   4
#define IRT_1730D_CNS   5
#define RMT_49D3_CNS    7
#define TM_5101_CNS     8
#define RMT_39D6_CNS    11
#define TM_5131_2_3_CNS 16
#define TM_5102_3_CNS   17
#define IRT_1730UA_CNS  18
#define IRT_1730DA_CNS  19
#define RMT_39DA6_CNS   20
#define RMT_49DA3_CNS   22
#define RMT_49DA1_CNS   23

#define IRT_MSG_BUF                    ((uint32_t)1048)
#define IRT_RECEIVE_SEGMENT_SIZE       1024
#define IRT_WAIT_BYTE                  ((uint16_t)10)

#define IRT_CN          0x3A /* :    */
#define IRT_SN          0x3B /* ;    */
#define IRT_EM          0x21 /* !    */
#define IRT_DH          0x2D /* -    */
#define IRT_PT          0x2E /* .    */
#define IRT_DL          0x24 /* $    */
#define IRT_CR          0x0D /* <CR> */

#define IRT_CMD_TYPE    0
#define IRT_CMD_READ    1



uint16_t
 IRT_check_sum(char *msg, int32_t len) {
  int i, l;
  uint16_t
	 sum;

  printf("\nIRT_check_sum len=%d\n",len);

  sum = 65535;
  for (i = 1; i < len; i++) {
	  sum ^= msg[i];
	  for(l = 0; l < 8; l++) {
		  if (((sum / 2) * 2) != sum) {
			  sum = (sum / 2) ^ 40961;
		  }
		  else
			  sum /= 2;
	  }
  }

  printf("\nIRT_check_sum sum=%d\n",sum);

  printf("\nIRT_check_sum msg=%s\n",msg);

  return sum;
}



char* IRT_check_buf1(char * dest,  const char *buf) {
    while (*buf) { //Пробегаем указателем по строке
      if (isalnum(*buf)) { //Если символ является буквой или цифрой
        *dest++ = *buf; //Накапливаем строку в новом указателе
      } else {
	    if (*buf==IRT_CN ||
		    *buf==IRT_SN ||
		    *buf==IRT_EM ||
		    *buf==IRT_DH ||
		    *buf==IRT_PT ||
		    *buf==IRT_DL ||
		    *buf==IRT_CR ) *dest++ = *buf; //Накапливаем строку в новом указателе
	  }

      ++buf;
    }
    *dest = '\0';
	return (dest);
}


char* IRT_check_buf2(char *buf) {
   char *p ;
   for (p = buf; *p; p++) {
    if (*p==IRT_CN ||
	    *p==IRT_SN ||
	    *p==IRT_EM ||
	    *p==IRT_PT ||
	    *p==IRT_DL ||
		*p==IRT_CR ) { ; }
		 else if (!isalnum(*p)) *p = ' ';
   }
   return buf;
}


int IRT_get_value(char * msg, char * buf,  int size, char * value) {
	char            * buf_PTR = buf;
	char            * buf_NEW = buf;
	int          addr, chk;
	uint16_t          check;
	double fval ;

	int32_t p=0; // указатель

	if (buf == NULL)
		return -1;


	buf_PTR=&buf[0];

	for (; *buf_PTR != IRT_EM; buf_PTR++,p++) {
		if ((buf_PTR - buf) >= size) return -2; // если IRT_EM - нет
	}

	buf_PTR++;
	if ((buf_PTR - buf) >= size) return -2; // если IRT_EM - нет


	printf("\n buf_PTR=%s \n",buf_PTR);

	sscanf_s(buf_PTR, "%d;%lf;%d", &addr, &fval, &chk);

	printf( "=%d=%lf=%d=", addr, fval, chk);


	for (buf_PTR = buf; *buf_PTR != IRT_CR; buf_PTR++) {
		if ((buf + size) == buf_PTR)  return -3; // если IRT_CR - нет
	}

	for (; *buf_PTR != IRT_SN; buf_PTR--) {
		if ((buf + size) == buf_PTR) return -4; // если IRT_SN - нет
	}

	int ls2 = strlen(buf + p);
	printf("\n p=%d ls2=%d s2=%s \n",p, ls2, buf + p);

	check = IRT_check_sum(buf + p, (int32_t)(buf_PTR - (buf+p-1) ) );

	return 0;
}





int IRT_get_value2(char * msg, char * buf,  int size, char * value) {
	char            * buf_PTR = buf;
	char            * p_IRT_EM;
	char            * buf_NEW;

	int          addr, chk;
	uint16_t          check;
	double fval ;

	buf_NEW = new char[size+1]();

//	buf_NEW = new (std::nothrow) char[size+1]();
//if (!buf_NEW) // обрабатываем случай, когда new возвращает null (т.е. память не выделяется)
//{
    // Обработка этого случая
//    std::cout << "Could not allocate memory";
//}


	int32_t p=0; // указатель

	if (buf == NULL)
		return -1;


	int i = 0 ;
    while (*buf_PTR) { //Пробегаем указателем по строке
      if (isalnum(*buf_PTR)) { //Если символ является буквой или цифрой
        buf_NEW[i++] = *buf_PTR; //Накапливаем строку в новом указателе
      } else {
	    if (*buf_PTR==IRT_CN ||
		    *buf_PTR==IRT_SN ||
		    *buf_PTR==IRT_EM ||
		    *buf_PTR==IRT_DH ||
		    *buf_PTR==IRT_PT ||
		    *buf_PTR==IRT_DL ||
		    *buf_PTR==IRT_CR ) buf_NEW[i++] = *buf_PTR; //Накапливаем строку в новом указателе
	  }

      ++buf_PTR;
    }
    buf_NEW[i++] = '\0';

	printf("\n buf_NEW=%s \n",buf_NEW);


	buf_PTR=&buf[0];

	for (; *buf_PTR != IRT_EM; buf_PTR++,p++) {
		if ((buf_PTR - buf) >= size) return -2; // если IRT_EM - нет
	}


    p_IRT_EM = buf_PTR;

	buf_PTR++;
	if ((buf_PTR - buf) >= size) return -2; // если IRT_EM - нет

	printf("\n p_IRT_EM=%s \n",p_IRT_EM);

	sscanf(buf_PTR, "%d;%lf;%d", &addr, &fval, &chk);

	printf( "\n=%d=%lf=%d=\n", addr, fval, chk);

	for (buf_PTR = buf; *buf_PTR != IRT_CR; buf_PTR++) {
		if ((buf + size) == buf_PTR)  return -3; // если IRT_CR - нет
	}

	for (; *buf_PTR != IRT_SN; buf_PTR--) {
		if ((buf + size) == buf_PTR) return -4; // если IRT_SN - нет
	}

	int ls2 = strlen(buf + p);
	printf("\n p=%d ls2=%d s2=%s \n",p, ls2, buf + p);

	printf("\n  s3=%s\n", p_IRT_EM);

	check = IRT_check_sum(p_IRT_EM, (int32_t)(buf_PTR - p_IRT_EM + 1));

	printf("\ncheck=%d\n",check);

	return 0;
}


int _tmain(int argc, _TCHAR* argv[])
{
	//char * buf1 = "\xff\xff\xff\x21\x30\x33\x3b\x33\x30\x34\x2e\x34\x30\x3b\x34\x34\x32\x34\x38\x0d" ;
	//char * buf1 = "\xff\xff\x21\x30\x34\x3b\x2d\x33\x2e\x39\x34\x31\x3b\x31\x38\x35\x32\x35\x0d";
	//char * buf1 = "\xff\x21\x30\x34\x3b\x2d\x33\x2e\x38\x39\x37\x3b\x35\x35\x32\x34\x36\x0d";
	char * buf1 = "\xff\xff\x21\x30\x34\x3b\x2d\x34\x2e\x30\x35\x37\x3b\x37\x38\x31\x0d";

	char * value = NULL;
	int size1 = 0 ;

	size1 = strlen(buf1);
	printf("\n ls1=%d s1=%s \n",size1, buf1);

	int ret = IRT_get_value2(NULL, buf1,  size1, value) ;
	printf("\n ret=%d \n",ret);

	return 0;
}

