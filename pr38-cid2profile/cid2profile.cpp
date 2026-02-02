#include "pugixml.hpp"
#include <stdint.h>
#include <iostream>
#include <fstream>

#include <cstring>

std::ofstream out;

//обязательны name и id_type
void json(const char *name, uint32_t id_type, int32_t cvalif, int32_t id_gtopt, int32_t id_proto_point, const char *attr_name = NULL) {

	std::string buf = "], \"data\": {\"attr_name\": ";
	buf += attr_name ? (std::string)"\"" + attr_name + "\", " : "null, ";

	buf += "\"color\": null, ";

	buf += "\"cvalif\": ";
	buf += cvalif >= 0 ? "\"" + std::to_string(cvalif) + "\", " : "null, ";

	buf += "\"id\": null, \"id_dev\": null, \"id_gtopt\": ";
	buf += id_gtopt >= 0 ? "\"" + std::to_string(id_gtopt) + "\", " : "null, ";

	buf += "\"id_parent\": null, \"id_proto_point\": ";
	buf += id_proto_point >= 0 ? "\"" + std::to_string(id_proto_point) + "\", " : "null, ";


	buf += "\"id_type\": \"";
	buf += std::to_string(id_type);

	buf += "\", \"name\": \"";
	buf += name;

	buf += "\", \"scale\": \"1.0000000\"}}";

	out << buf << std::endl;
}

void child(bool first = true) {
	if (!first)
		out << ", " << std::endl;

	out << "{\"childs\": [";
}

void head(const char *name) {

	char depends[] ="\"depends\": { \"da_proto_desc\": [ \"150\", \"151\", \"152\", \"154\", \"156\", \"153\", \"155\", \"157\", \"158\", \"159\" ], \"sys_dtyp\": [ \"252\", \"456\", \"457\", \"405\", \"406\"], \"sys_gtopt\": [\"1\", \"8\", \"38\"]}";

	std::string buf = "{";
	buf+= depends;
	buf += ", \"hash\": null, \"info\": { \"creation_time\": null, \"device_name\": \"";
	buf += name;
	buf += "\", \"host\": null, \"is_route\": 0}, \"tree\": [";
	out << buf;
}

void tail() {
	out << "]}" << std::endl;
}

int main(int argc, char* argv[]){

	if (argc < 3) {
		std::cout << "example usage: cid2profile input.iid output.profile" << std::endl;
		return 0;
	}

	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_file(argv[1]);

	if (result.status != pugi::status_ok) {
		std::cout << "Error open " << argv[1] << ": " << result.description() << std::endl;
		return 0;
	}

	std::cout << "IP:";
	pugi::xpath_node_set Addresse = doc.select_nodes("/SCL/Communication//Address/P[@type=\"IP\"]");
	for (pugi::xpath_node_set::const_iterator Address = Addresse.begin(); Address != Addresse.end(); ++Address) {
		std::cout << " " << Address->node().child_value() << ":";
		pugi::xpath_query port_query("P[@type=\"MMS-Port\"]");
		pugi::xml_node port = port_query.evaluate_node(Address->parent()).node();

		if (!port.empty()) {
			std::cout << port.child_value() << ";";
		} else {
			std::cout << "102;";
		}
	}
	std::cout << std::endl;

	out.open(argv[2]);

	pugi::xpath_node IED = doc.select_node("/SCL/IED");

	const char *ied_name = IED.node().attribute("name").value();

	pugi::xpath_node_set LDevices = doc.select_nodes("/SCL/IED//LDevice");

	head(ied_name);

	child();
	child();

	pugi::xpath_variable_set vars;
	vars.add("datSet", pugi::xpath_type_string);
	vars.add("lnType", pugi::xpath_type_string);

	vars.add("prefix", pugi::xpath_type_string);
	vars.add("lnClass", pugi::xpath_type_string);
	vars.add("lnInst", pugi::xpath_type_string);
	vars.add("doName", pugi::xpath_type_string);
	vars.add("daName", pugi::xpath_type_string);

	for (pugi::xpath_node_set::const_iterator LDevice = LDevices.begin(); LDevice != LDevices.end(); ++LDevice) {

		std::cout << "Found Logical Device " << (*LDevice).node().attribute("inst").value() << std::endl;

    	pugi::xpath_query query_reports("LN0/ReportControl", &vars);

    	child(LDevice == LDevices.begin());
    	child();

    	pugi::xpath_node_set Reports = query_reports.evaluate_node_set(*LDevice);

    	std::cout << "Found Report" << std::endl;

    	bool first = true;
    	for (pugi::xpath_node_set::const_iterator b = Reports.begin(); b != Reports.end(); ++b) {
    		pugi::xpath_node Report = *b;
    		std::cout << Report.node().attribute("name").value() << std::endl;

    		int index = Report.node().child("RptEnabled").attribute("max").as_uint(0);

    		vars.set("datSet", Report.node().attribute("datSet").value());
	    	pugi::xpath_query query_dataset("LN0/DataSet[@name=$datSet]/*", &vars);
	    	pugi::xpath_node_set Params = query_dataset.evaluate_node_set(*LDevice);

    		do {
    			std::string name = Report.node().attribute("name").value();

    			if (index > 0) {
    				if (index<10)
    				name += '0';
 					name += std::to_string(index);
    			}

    			std::string attr_name = Report.node().attribute("buffered").as_bool() ? "LLN0.BR." : "LLN0.RP.";
    			attr_name += name;

	    		child(first);
	    		first = false;

	    		int cvalif = 0;
	    		for (pugi::xpath_node_set::const_iterator c = Params.begin(); c != Params.end(); ++c) {
	    			pugi::xpath_node Param = *c;
	    			std::string str = ied_name;
	    			str += Param.node().attribute("ldInst").value();
	    			str += Report.node().attribute("buffered").as_bool() ? "/BR." : "/RP.";
	    			str += name;
	    			str += "/";
	    			str += Param.node().attribute("prefix").value();
	    			str += Param.node().attribute("lnClass").value();
	    			str += Param.node().attribute("lnInst").value();

	    			vars.set("prefix", Param.node().attribute("prefix").value());
	    			vars.set("lnClass", Param.node().attribute("lnClass").value());
	    			vars.set("lnInst", Param.node().attribute("lnInst").value());

	    			pugi::xpath_query query_desc("LN[@lnClass=$lnClass and @prefix=$prefix and @inst=$lnInst]/@desc", &vars);
	    			std::string desc = query_desc.evaluate_string(*LDevice);

	    			//если не нашли описание в основной модели поищем в шаблонах
	    			if (desc.empty()) {
	    				pugi::xpath_query query_desc("/SCL/DataTypeTemplates/LNodeType[@lnClass=$lnClass]/@desc", &vars);
	    				desc = query_desc.evaluate_string(doc);
	    			}
	    			
	    			if (!Param.node().attribute("doName").empty()) {

	    				//если daName указан в doName
	    				if (const char *ptr = strchr(Param.node().attribute("doName").value(), '.')) {

	    					if (Param.node().attribute("daName").empty()) {
	    						Param.node().append_attribute("daName");
	    					}
	    					Param.node().attribute("daName").set_value(ptr+1);

	    					std::string doName = Param.node().attribute("doName").value();
	    					doName.resize(doName.find('.'));
	    					Param.node().attribute("doName").set_value(doName.c_str());
	    				}

	    				str += ".";
	    				str += Param.node().attribute("doName").value();
	    				vars.set("doName", Param.node().attribute("doName").value());

	    				pugi::xpath_query query_desc("LN[@lnClass=$lnClass and @prefix=$prefix and @inst=$lnInst]/DOI[@name=$doName]/@desc", &vars);
	    				std::string desc_do = query_desc.evaluate_string(*LDevice);

	    				//если не нашли описание в основной модели поищем в шаблонах
	    				if (desc_do.empty()) {
	    					pugi::xpath_query query_desc("/SCL/DataTypeTemplates/LNodeType[@lnClass=$lnClass]/DO[@name=$doName]/@desc", &vars);
	    					desc_do = query_desc.evaluate_string(doc);
	    				}

	    				if (!desc_do.empty()) {
	    					if (!desc.empty()) {
	    						desc += " / ";
	    					}
	    					desc += desc_do;
	    				}

	    				if (!Param.node().attribute("daName").empty()) {
	    					str += ".";
	    					str += Param.node().attribute("daName").value();
	    					vars.set("daName", Param.node().attribute("daName").value());
	    					pugi::xpath_query query_desc("LN[@lnClass=$lnClass and @prefix=$prefix and @inst=$lnInst]/DOI[@name=$doName]/DAI[@name=$daName]/@desc", &vars);
	    					std::string desc_da = query_desc.evaluate_string(*LDevice);

	    					//если не нашли описание в основной модели поищем в шаблонах
	    					if (desc_da.empty()) {
	    						pugi::xpath_query query_desc("/SCL/DataTypeTemplates/DOType[@id=/SCL/DataTypeTemplates/LNodeType[@lnClass=$lnClass]/DO[@name=$doName]/@type]/@desc", &vars);
	    						desc_da = query_desc.evaluate_string(doc);
	    					}

	    					if (!desc_da.empty()) {
	    						if (!desc.empty()) {
	    							desc += " / ";
	    						}
	    						desc += desc_da;
	    					}
	    				}
	    			}

	    			str += "[";
	    			str += Param.node().attribute("fc").value();
	    			str += "]";

	    			if (!desc.empty()) {
	    				str += " (";
	    				str += desc;
	    				str += ")";
	    			}

	    			//pugi::xpath_query query_cdc("/SCL/DataTypeTemplates/DOType[@id=/SCL/DataTypeTemplates/LNodeType[@lnClass=$lnClass]/DO[@name=$doName]/@type]/@cdc", &vars);
	    			//std::string cdc = query_cdc.evaluate_string(doc);
		   			//std::cout << str << " CDC: " << cdc << std::endl;

	    			child(c == Params.begin());
	    			if ((std::string) "MX" == Param.node().attribute("fc").value()) {
	    				//ТИ
	    				json(str.c_str(), 405, cvalif++, 1, 157);
	    			} else {
	    				//ТС
	    				json(str.c_str(), 406, cvalif++, 8, 157);
	    			}
	    		}

	    		json(name.c_str(), 457, -1, -1, 155, attr_name.c_str());
	    	} while (--index > 0);
    	}
    	json("Фиксированная конфигурация", 457, -1, -1, 153);
    	
    	child(false);

    	std::cout << "Found Telecontrol objects" << std::endl;
    	pugi::xpath_query query_DPC("LN[@lnType=/SCL/DataTypeTemplates/LNodeType/DO[@type=/SCL/DataTypeTemplates/DOType[@cdc=\"DPC\"]/@id]/../@id]");
    	pugi::xpath_query query_name("concat(@prefix, @lnClass, @inst, '.', /SCL/DataTypeTemplates/LNodeType[@id=$lnType]/DO[@type=/SCL/DataTypeTemplates/DOType[@cdc=\"DPC\"]/@id]/@name)", &vars);

    	pugi::xpath_node_set DPC = query_DPC.evaluate_node_set(*LDevice);

    	for (pugi::xpath_node_set::const_iterator a = DPC.begin(); a != DPC.end(); ++a) {
    		vars.set("lnType", (*a).node().attribute("lnType").value());
    		std::string ctrl = query_name.evaluate_string(*a);
		   	std::cout << ctrl << std::endl;

		   	child(a == DPC.begin());
		   	//GLT_BOOL_OPT_TELECONTROL_DOUBLE
		   	json(ctrl.c_str(), 406, -1, 28, 159, ctrl.c_str());
    	}

    	json("Телеуправление", 457, -1, -1, 158);
    	
    	json((*LDevice).node().attribute("inst").value(), 457, -1, -1, 151, ((std::string)ied_name + (*LDevice).node().attribute("inst").value()).c_str());
    }

   json("IEC61850 MMS", 456, -1, -1, 150);
   json(ied_name, 252, -1, -1, -1);

   tail();

   out.close();
   return 0;
}
