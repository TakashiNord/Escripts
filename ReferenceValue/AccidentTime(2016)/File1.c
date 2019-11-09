//---------------------------------------------------------------------------

#include <stdio.h>
#pragma hdrstop

#include <tchar.h>
//---------------------------------------------------------------------------

#define uint32_t int

typedef struct REG_SET
{
    uint32_t    id;
    uint32_t    id_param;
    uint32_t    id_level;
    uint32_t    id_src;
    uint32_t    id_srci;
    uint32_t    notify_period;
    uint32_t    hyst_period;    /* Âðåìåííîé ãèñòåðåçèñ äëÿ ñðàáàòûâàíèÿ óñòàâêè*/
    uint32_t    firstbegintime; /* Âðåìÿ ïåðâîíà÷àëüíîãî îáíàðóæåíèÿ âûõîäà çà óñòàâêè */
    uint32_t    priority;
    uint32_t    start_signal_id;
    uint32_t    cont_signal_id;
    uint32_t    sets_type;
    /*    double              m_min_val;*/      /* Çíà÷åíèå óñòàâêè ïî ðó÷íîìó ââîäó */
    /*    double              m_max_val;  */
    double      min_val;        /* Çíà÷åíèå óñòàâêè, ïîëó÷åííîå îò èñòî÷íèêà */
    double      max_val;
    double      min_val_final;  /* Îêîí÷àòåëüíî âû÷èñëåííîå çíà÷åíèå óñòàâêè, èñïîëüçóåìîå äëÿ êîíòðîëÿ (íàïðèìåð, äëÿ êîñâåííûõ óñòàâîê) */
    double      max_val_final;
    uint32_t    val_is_get;     /* Çíà÷åíèå óñòàâêè áûëî ïîëó÷åíî îò èñòî÷íèêà (è)*/
    uint32_t    begintime;      /* Âðåìÿ îáíàðóæåíèÿ âûõîäà çà óñòàâêè  */
    double      extrem;         /* Ýêñòðåìàëüíîå çíà÷åíèå ïàðàìåòðà ïðè âûõîäå åãî çà óñòàâêè */
    uint32_t    user_id;
    uint32_t    time1970;
} REG_SET;

typedef struct REG_BASE
{
    uint32_t    id;
    uint32_t    id_node;
    uint32_t    cur_src;        /* Òåêóùèé èñòî÷íèê çíà÷åíèé */
    uint32_t    cur_srci;       /* Òåêóùèé êàíàë èñòî÷íèêà çíà÷åíèé */
    uint32_t    c_ft;           /* Current parameter state and feature */
    uint32_t    c_state;        /* Calculate state */
    uint32_t    state;          /* Parameter main feature */
    uint32_t    novalid;        /* 0 - çíà÷åíèå ïàðàìåòðà êîððåêòíî, 1 - íåêîððåêòíî (èçìåíåíî íà íîëü â ñèëó âîçíèêøåãî ìàòåìàòè÷åñêîãî èñêëþ÷åíèÿ) */
    uint32_t    set_level_number;   /* Number of set level */
    uint32_t    last_change_time;   /* Last value change time */
    uint32_t    last_valid_value_time;
    double      last_valid_value;   /* No comment */
    double      c_disper;       /* Calculate accuracy */
    double      disper;         /* Current parameter accuracy */
//    EXTREME_VALUE   extreme_value[RETRO_EXTREME_WIDTH]; /* Ýêñòðåìàëüíûå çíà÷åíèÿ ïàðàìåòðîâ */
//    REG_VAL     rv[RETRO_WIDTH];
//    ListType    ivl;   /* Ñïèñîê ListType ðàññ÷èòûâàåìûõ èíòåãðàëüíûõ çíà÷åíèé REG_INT, îòñîðòèðîâàíî ïî èíòåðâàëó */
//    ListType    avr;   /* Ñïèñîê ListType ðàññ÷èòûâàåìûõ ñðåäíèõ çíà÷åíèé REG_AVR, îòñîðòèðîâàíî ïî èíòåðâàëó */
//    REG_MVL     mvl;
    REG_SET   (*set)[];
//    struct ELRSRV_ENV *pEnv;
}REG_BASE;

REG_BASE s ;
REG_SET ss ;
struct REG_SET set, *pset;

#pragma argsused
int _tmain(int argc, _TCHAR* argv[])
{
 	s.id=2000 ;
	s.last_change_time=98878868;
	s.set_level_number = 1 ;

	ss.begintime=9087768 ;
	ss.id=32455;
	ss.max_val=768;
	ss.min_val=654;

	pset=&set;

	pset->begintime=23333 ;
	pset->id=32455;
	pset->max_val=768;
	pset->min_val=654;

	//s.(*set)[0]=*pset;
	s.(*set)[0]=ss;



	printf("Hello World!\n");
	return 0;
}
//---------------------------------------------------------------------------
