// ConsoleApplication1.cpp: определяет точку входа для консольного приложения.
//

#include "stdafx.h"

#include <iostream>
#include <fstream>
#include <cstring>


std::ifstream in;
std::ofstream out;

std::string FormatJson(std::string str, std::string indentString = "\t")
{
	int indent = 0;
	bool quoted = false;
	std::string sb = "";
	for (int i = 0; i < str.length()  ; i++)
	{

	}
	return(sb);
}

int _tmain(int argc, _TCHAR* argv[])
{
	bool fe = false;
	char ch ;
	std::string buf = "";
	std::string rbuf = "";
	std::cout << "exe file.profile file.format";

	in.open(argv[1]);
	out.open(argv[2]);

	std::cout << "Read file ";
    
    while((ch = in.get()) != EOF) {
        if (char(ch)!='\n') ;   //Считываем символ из файла и сразу проверяем его на признак переноса строки.
		out<<ch;
		switch (ch)
		{
		  case '{':  case '[':
			  out<< '\t' << std::endl;
  		  break;
		  case '}':  case ']':
          break;
		  case '"':
 		  break;
		  case ',':
			  out<< std::endl;
		  break;
		  case ':':
		  break;
		  default:
					break;
		}
		

		fe=in.eof();
        if (fe) break;
		if (in.fail()) in.clear();


    } 

	out.flush();
	out.close();
	in.close();

	return 0;
}

