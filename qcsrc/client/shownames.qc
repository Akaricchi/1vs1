// plr.isactive = player is in range and coordinates/status (health and armor) are up to date
// plr.origin = player origin TODO: should maybe move this so it's the origin of the shownames tag already in SSQC for culling?
// plr.healthvalue
// plr.armorvalue
// plr.sameteam = player is on same team as local client
//

.float the_entnum;

.float sn_lastdraw;
//.float sn_forcefrozen;
.vector iorigin;

float(float entitynum, float fldnum) getentity = #504;
vector(float entitynum, float fldnum) getentityvec = #504;
float E_ACTIVE      = 0; // float 0/1
float E_ORIGIN      = 1; // vector

#define SHOWNAMES_ALPHA 0.9
#define SHOWNAMES_ASPECT 8
#define SHOWNAMES_FONTSIZE 10
#define SHOWNAMES_HEIGHT 15

#define SHOWNAMES_MAXDISTANCE 2500
#define SHOWNAMES_MINDISTANCE 1000
#define SHOWNAMES_ORIGIN_OFFSET '0 0 64'

float Shownames_PreDrawPlayer() {
    if(!CVAR(hud_shownames))
        return FALSE;

    if (teamplay)
    if not(CVAR(hud_shownames_enemies))
	if (self.cnt)
        return FALSE;

	if not(ext_DP_CSQC_QUERYRENDERENTITY)
		return FALSE;

	float plr_entnum = self.sv_entnum + 1;

	if(getentity(plr_entnum, E_ACTIVE)) {
		self.iorigin = getentityvec(plr_entnum, E_ORIGIN);
	} else
		return FALSE;

	if (self.cnt) {
		traceline(self.iorigin, view_origin, 0, world);
		if (trace_fraction < 1)
			return FALSE;
	}

	return TRUE;
}

void Shownames_DrawPlayer() {
    float oldfont = drawfont;
    float dist = vlen(self.iorigin - view_origin);
    float a = SHOWNAMES_ALPHA;

    if(self.alpha)
        a *= self.alpha;

    if(dist >= SHOWNAMES_MAXDISTANCE)
        return;

    a *= ((SHOWNAMES_MAXDISTANCE - SHOWNAMES_MINDISTANCE) - max(0, dist - SHOWNAMES_MINDISTANCE)) / (SHOWNAMES_MAXDISTANCE - SHOWNAMES_MINDISTANCE);

    vector o;
    o = project_3d_to_2d(self.iorigin + SHOWNAMES_ORIGIN_OFFSET);

    if(o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight))
        return;

    o_z = 0;

    vector myPos, mySize;
	mySize = '0 0 0';
    mySize_x = SHOWNAMES_ASPECT;
	mySize_y = SHOWNAMES_HEIGHT;
    myPos = o - '0.5 0 0' * mySize_x - '0 1 0' * mySize_y;

    vector namepos; // this is where the origin of the string
    float namesize; // total area where we can draw the string

    namepos = myPos + '0 1 0' * 0.5 * (SHOWNAMES_HEIGHT - SHOWNAMES_FONTSIZE);
    namesize = mySize_x;

    string s;
    s = GetPlayerName(self.sv_entnum);
    float textsz = SHOWNAMES_FONTSIZE;

    if(teamplay) {
        s = strdecolorize(s);
        s = textShortenToWidth(s, namesize, stringwidth_nocolors);
    } else s = textShortenToWidth(s, namesize, stringwidth_colors);

    float width = stringwidth(s, TRUE);

    if(width != namesize)
        namepos_x += (namesize - width) / 2;

	drawfont = sbar_font;

	float fade = 0.7;

	namepos_x = namepos_x - 0.5 * width * textsz;

    if(teamplay)
        drawstring(namepos, s, textsz * '1 1 0', GetTeamRGB(GetPlayerColorForce(self.sv_entnum)) + '0.2 0.2 0.2', a, DRAWFLAG_NORMAL);
    else
        drawcolorcodedstring(namepos, s, textsz * '1 1 0', a, DRAWFLAG_NORMAL);
    
    drawfont = oldfont;
}

void Shownames_Init(entity plr) {
    plr.draw2d = Shownames_DrawPlayer;
    plr.draw2d_pre = Shownames_PreDrawPlayer;
}
