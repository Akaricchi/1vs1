// --------------------------------------------------------------------------
// BEGIN REQUIRED CSQC FUNCTIONS
//include "main.qh"

#define DP_CSQC_ENTITY_REMOVE_IS_B0RKED

var void(float) ent_parsers[ENT_CLIENT_COUNT];

void cvar_clientsettemp(string cv, string val)
{
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
		if(e.netname == cv)
			goto saved;
	e = spawn();
	e.classname = "saved_cvar_value";
	e.netname = strzone(cv);
	e.message = strzone(cvar_string(cv));
:saved
	cvar_set(cv, val);
}

void cvar_clientsettemp_restore()
{
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
			cvar_set(e.netname, e.message);
}

#ifdef USE_FTE
float __engine_check;
#endif

void Ent_Error(float ignore) {
	error(strcat("unknown entity type in CSQC_Ent_Update: ", ftos(self.enttype), "\n"));
}

void ClientUpdateMessage_Draw() {
	string msg;
	vector pos;
	pos_z = 0;
	float _alpha = 0.5 + mod(time, 2) * 0.5;

	msg = "^1WARNING: ^3Your client is not recommended!";
	pos_y = 10;
	pos_x = 10;
	drawcolorcodedstring(pos, msg, '12 24 0', _alpha, DRAWFLAG_NORMAL);

	pos_y += 32;
	drawcolorcodedstring(pos, self.bgmscript, '12 24 0', _alpha, DRAWFLAG_NORMAL);

	msg = "^3Please download and install Rexuiz from ^2http://rexuiz.top^7";
	pos_y += 32;
	drawcolorcodedstring(pos, msg, '12 24 0', _alpha, DRAWFLAG_NORMAL);
}

void ClientUpdateMessage_SetNextThink() {
	self.nextthink = time + 10;
	self.think = SUB_Remove;
}

void ClientUpdateMessage(string msg) {
	entity e = spawn();
	e.draw2d = ClientUpdateMessage_Draw;
	e.nextthink = 1;
	e.think = ClientUpdateMessage_SetNextThink;
	e.bgmscript = msg;
}

string forcefog;
void Ent_ReadEntCS(float bIsNewEntity);
void Ent_ReadEntCSEnemy(float bIsNewEntity);
void Ent_ScoresInfo(float ignore);
void Ent_ReadPlayerScore(float ignore);
void Ent_ReadTeamScore(float ignore);
void Ent_Nagger(float ignore);
void Ent_ClientData(float ignore);
void Ent_RandomSeed(float ignore);
void Ent_Init(float ignore);

// CSQC_Init : Called every time the CSQC code is initialized (essentially at map load)
// Useful for precaching things
void CSQC_Init(void)
{
#ifdef USE_FTE
#pragma target ID
	__engine_check = checkextension("DP_SV_WRITEPICTURE");
	if(!__engine_check)
	{
		print("^3Your engine build is outdated\n^3This Server uses a newer QC VM. Please update!\n");
		localcmd("\ndisconnect\n");
		return;
	}
#pragma target FTE
#endif
	float xonotic_client;
	xonotic_client = FALSE;
	if (cvar_string("g_xonoticversion") != "")
	{
		print("Xonotic client detected\n");
		registercvar("_supports_weaponpriority", "0");

		cvar_set("sbar_alpha_bg", cvar_string("hud_panel_bg_alpha"));
		cvar_set("sbar_alpha_fg", cvar_string("hud_panel_fg_alpha"));
		cvar_set("sbar_hud_accuracy", cvar_string("hud_panel_weapons_accuracy"));
		cvar_set("sbar_showcurrentammo", cvar_string("hud_panel_ammo_onlycurrent"));
		cvar_set("sbar_increment_maptime", cvar_string("hud_panel_timer_increment"));
		cvar_set("sbar_showbinds", cvar_string("hud_showbinds"));
		cvar_set("sbar_showbinds_limit", cvar_string("hud_showbinds_limit"));
		cvar_set("sbar_width", cvar_string("hud_width"));
		cvar_set("sbar_border_thickness", cvar_string("scoreboard_border_thickness"));
		cvar_set("sbar_fontsize", cvar_string("hud_fontsize"));
		cvar_set("sbar_fontsize_spec", cvar_string("hud_fontsize"));
		cvar_set("sbar_hudselector", ftos(!cvar("hud_panel_healtharmor_flip")));
		cvar_set("sbar_scoreboard_alpha_bg", cvar_string("scoreboard_alpha_bg"));
		vector v = stov(cvar_string("hud_panel_bg_color"));
		cvar_set("sbar_color_bg_r", ftos(v_x));
		cvar_set("sbar_color_bg_g", ftos(v_y));
		cvar_set("sbar_color_bg_b", ftos(v_z));
		cvar_set("sbar_color_bg_team", cvar_string("hud_panel_bg_color_team"));
		cvar_set("cl_teamradar", cvar_string("hud_panel_radar"));
		cvar_set("sbar_scoreboard_highlight", cvar_string("scoreboard_highlight"));

		registercvar("crosshair_laser", "", CVAR_SAVE);
		registercvar("crosshair_laser_color_red", "1", CVAR_SAVE);
		registercvar("crosshair_laser_color_green", "0.35", CVAR_SAVE);
		registercvar("crosshair_laser_color_blue", "0.2", CVAR_SAVE);
		registercvar("crosshair_laser_color_alpha", "0.75", CVAR_SAVE);
		registercvar("crosshair_laser_size", "0.4", CVAR_SAVE);
		registercvar("crosshair_shotgun", "", CVAR_SAVE);
		registercvar("crosshair_shotgun_color_red", "0.7", CVAR_SAVE);
		registercvar("crosshair_shotgun_color_green", "0.7", CVAR_SAVE);
		registercvar("crosshair_shotgun_color_blue", "0.7", CVAR_SAVE);
		registercvar("crosshair_shotgun_color_alpha", "1.1", CVAR_SAVE);
		registercvar("crosshair_shotgun_size", "0.65", CVAR_SAVE);
		registercvar("crosshair_uzi", "", CVAR_SAVE);
		registercvar("crosshair_uzi_color_red", "0.4", CVAR_SAVE);
		registercvar("crosshair_uzi_color_green", "0.9", CVAR_SAVE);
		registercvar("crosshair_uzi_color_blue", "0.35", CVAR_SAVE);
		registercvar("crosshair_uzi_color_alpha", "0.9", CVAR_SAVE);
		registercvar("crosshair_uzi_size", "0.6", CVAR_SAVE);
		registercvar("crosshair_grenadelauncher", "", CVAR_SAVE);
		registercvar("crosshair_grenadelauncher_color_red", "1", CVAR_SAVE);
		registercvar("crosshair_grenadelauncher_color_green", "0.15", CVAR_SAVE);
		registercvar("crosshair_grenadelauncher_color_blue", "0", CVAR_SAVE);
		registercvar("crosshair_grenadelauncher_color_alpha", "1.15", CVAR_SAVE);
		registercvar("crosshair_grenadelauncher_size", "0.7", CVAR_SAVE);
		registercvar("crosshair_electro", "", CVAR_SAVE);
		registercvar("crosshair_electro_color_red", "0.35", CVAR_SAVE);
		registercvar("crosshair_electro_color_green", "0.5", CVAR_SAVE);
		registercvar("crosshair_electro_color_blue", "1", CVAR_SAVE);
		registercvar("crosshair_electro_color_alpha", "1", CVAR_SAVE);
		registercvar("crosshair_electro_size", "0.5", CVAR_SAVE);
		registercvar("crosshair_crylink", "", CVAR_SAVE);
		registercvar("crosshair_crylink_color_red", "0.85", CVAR_SAVE);
		registercvar("crosshair_crylink_color_green", "0.25", CVAR_SAVE);
		registercvar("crosshair_crylink_color_blue", "1", CVAR_SAVE);
		registercvar("crosshair_crylink_color_alpha", "0.85", CVAR_SAVE);
		registercvar("crosshair_crylink_size", "0.4", CVAR_SAVE);
		registercvar("crosshair_nex", "", CVAR_SAVE);
		registercvar("crosshair_nex_color_red", "0", CVAR_SAVE);
		registercvar("crosshair_nex_color_green", "0.9", CVAR_SAVE);
		registercvar("crosshair_nex_color_blue", "1", CVAR_SAVE);
		registercvar("crosshair_nex_color_alpha", "0.85", CVAR_SAVE);
		registercvar("crosshair_nex_size", "0.65", CVAR_SAVE);
		registercvar("crosshair_hagar", "", CVAR_SAVE);
		registercvar("crosshair_hagar_color_red", "0.85", CVAR_SAVE);
		registercvar("crosshair_hagar_color_green", "0.5", CVAR_SAVE);
		registercvar("crosshair_hagar_color_blue", "0.35", CVAR_SAVE);
		registercvar("crosshair_hagar_color_alpha", "1", CVAR_SAVE);
		registercvar("crosshair_hagar_size", "0.8", CVAR_SAVE);
		registercvar("crosshair_rocketlauncher", "", CVAR_SAVE);
		registercvar("crosshair_rocketlauncher_color_red", "1", CVAR_SAVE);
		registercvar("crosshair_rocketlauncher_color_green", "0.75", CVAR_SAVE);
		registercvar("crosshair_rocketlauncher_color_blue", "0.2", CVAR_SAVE);
		registercvar("crosshair_rocketlauncher_color_alpha", "1", CVAR_SAVE);
		registercvar("crosshair_rocketlauncher_size", "0.5875", CVAR_SAVE);
		registercvar("crosshair_porto", "", CVAR_SAVE);
		registercvar("crosshair_porto_color_red", "0.5", CVAR_SAVE);
		registercvar("crosshair_porto_color_green", "1", CVAR_SAVE);
		registercvar("crosshair_porto_color_blue", "0.5", CVAR_SAVE);
		registercvar("crosshair_porto_color_alpha", "0.85", CVAR_SAVE);
		registercvar("crosshair_porto_size", "0.6", CVAR_SAVE);
		registercvar("crosshair_minstanex", "", CVAR_SAVE);
		registercvar("crosshair_minstanex_color_red", "0.65", CVAR_SAVE);
		registercvar("crosshair_minstanex_color_green", "0.65", CVAR_SAVE);
		registercvar("crosshair_minstanex_color_blue", "1", CVAR_SAVE);
		registercvar("crosshair_minstanex_color_alpha", "1", CVAR_SAVE);
		registercvar("crosshair_minstanex_size", "0.4", CVAR_SAVE);
		registercvar("crosshair_hook", "", CVAR_SAVE);
		registercvar("crosshair_hook_color_red", "0.65", CVAR_SAVE);
		registercvar("crosshair_hook_color_green", "1", CVAR_SAVE);
		registercvar("crosshair_hook_color_blue", "0.85", CVAR_SAVE);
		registercvar("crosshair_hook_color_alpha", "0.85", CVAR_SAVE);
		registercvar("crosshair_hook_size", "0.5", CVAR_SAVE);
		registercvar("crosshair_hlac", "", CVAR_SAVE);
		registercvar("crosshair_hlac_color_red", "1", CVAR_SAVE);
		registercvar("crosshair_hlac_color_green", "0.65", CVAR_SAVE);
		registercvar("crosshair_hlac_color_blue", "0.2", CVAR_SAVE);
		registercvar("crosshair_hlac_color_alpha", "1", CVAR_SAVE);
		registercvar("crosshair_hlac_size", "0.6", CVAR_SAVE);
		registercvar("crosshair_campingrifle", "rifle", CVAR_SAVE);
		registercvar("crosshair_campingrifle_color_red", "0.85", CVAR_SAVE);
		registercvar("crosshair_campingrifle_color_green", "0.5", CVAR_SAVE);
		registercvar("crosshair_campingrifle_color_blue", "0.25", CVAR_SAVE);
		registercvar("crosshair_campingrifle_color_alpha", "1", CVAR_SAVE);
		registercvar("crosshair_campingrifle_size", "0.65", CVAR_SAVE);
		registercvar("crosshair_campingrifle_ring_size", "1.5", CVAR_SAVE);
		registercvar("crosshair_tuba", "", CVAR_SAVE);
		registercvar("crosshair_tuba_color_red", "0.85", CVAR_SAVE);
		registercvar("crosshair_tuba_color_green", "0.5", CVAR_SAVE);
		registercvar("crosshair_tuba_color_blue", "0.25", CVAR_SAVE);
		registercvar("crosshair_tuba_color_alpha", "1", CVAR_SAVE);
		registercvar("crosshair_tuba_size", "1", CVAR_SAVE);
		registercvar("crosshair_fireball", "", CVAR_SAVE);
		registercvar("crosshair_fireball_color_red", "0.2", CVAR_SAVE);
		registercvar("crosshair_fireball_color_green", "1.0", CVAR_SAVE);
		registercvar("crosshair_fireball_color_blue", "0.2", CVAR_SAVE);
		registercvar("crosshair_fireball_color_alpha", "1", CVAR_SAVE);
		registercvar("crosshair_fireball_size", "1", CVAR_SAVE);

		localcmd("\nseta menu_updatecheck 0\n");
		xonotic_client = TRUE;
	}
	read_cvars_init();
	if (xonotic_client) {
		localcmd("\ncmd gameclient xonotic\n");
		ClientUpdateMessage("^3You play with Xonotic client on Rexuiz server.");
	} else if (fexists("rexuiz.cfg"))
		localcmd("\ncmd gameclient rexuiz\n");
	else if (autocvar_autocvar_check)
		localcmd("\ncmd gameclient nexuiz\n");
	else {
		localcmd("\ncmd gameclient oldnexuiz\n");
		ClientUpdateMessage("^3You play with really old Nexuiz client");
	}

	if (cvar_string("sv_master2") == "")
	if (cvar_string("sv_masterextra1") == "") {
		localcmd("\nseta sv_master2 107.161.23.68\n");
	}

	check_unacceptable_compiler_bugs();

	float i;
	CSQC_CheckEngine();
	dprint_load();

	binddb = db_create();
	tempdb = db_create();
	compressShortVector_init();

	drawfont = 0;

	for(i = 0; i < 255; ++i)
		if(getplayerkey(i, "viewentity") == "")
			break;
	maxclients = i;

	registercmd("ons_map");
	//registercmd("menu_action");

	registercmd("+button3");
	registercmd("-button3");
	registercmd("+button4");
	registercmd("-button4");
	registercmd("+showaccuracy");registercmd("-showaccuracy");

	registercvar("crosshair_supershotgun", "shotgun", CVAR_SAVE);
	registercvar("crosshair_supershotgun_size", "1", CVAR_SAVE);
	registercvar("crosshair_supershotgun_color_blue", "0", CVAR_SAVE);
	registercvar("crosshair_supershotgun_color_red", "1", CVAR_SAVE);
	registercvar("crosshair_supershotgun_color_green", "0.5", CVAR_SAVE);
	registercvar("crosshair_supershotgun_color_alpha", "1", CVAR_SAVE);

#ifndef CAMERATEST
	if(isdemo())
	{
#endif
		registercmd("+forward");registercmd("-forward");
		registercmd("+back");registercmd("-back");
		registercmd("+moveup");registercmd("-moveup");
		registercmd("+movedown");registercmd("-movedown");
		registercmd("+moveright");registercmd("-moveright");
		registercmd("+moveleft");registercmd("-moveleft");
		registercmd("+roll_right");registercmd("-roll_right");
		registercmd("+roll_left");registercmd("-roll_left");
#ifndef CAMERATEST
	}
#endif
	registercvar("sbar_usecsqc", "1");
	registercvar("sbar_columns", "default", CVAR_SAVE);

	gametype = 0;

	// sbar_fields uses strunzone on the titles!
	for(i = 0; i < MAX_SBAR_FIELDS; ++i)
		sbar_title[i] = strzone("(null)");

	postinit = false;

	calledhooks = 0;

	teams = Sort_Spawn();
	players = Sort_Spawn();

	GetTeam(COLOR_SPECTATOR, true); // add specs first

	cvar_clientsettemp("_supports_weaponpriority", "1");

	RegisterWeapons();

	WaypointSprite_Load();

	Projectile_Precache();
	GibSplash_Precache();
	Casings_Precache();
	DamageInfo_Precache();
	Announcer_Precache();

	get_mi_min_max_texcoords(1); // try the CLEVER way first
	minimapname = strcat("gfx/", mi_shortname, "_radar.tga");
	shortmapname = mi_shortname;

	if(precache_pic(minimapname) == "")
	{
		// but maybe we have a non-clever minimap
		minimapname = strcat("gfx/", mi_shortname, "_mini.tga");
		if(precache_pic(minimapname) == "")
			minimapname = ""; // FAIL
		else
			get_mi_min_max_texcoords(0); // load new texcoords
	}

	mi_center = (mi_min + mi_max) * 0.5;
	mi_scale = mi_max - mi_min;
	minimapname = strzone(minimapname);
	ext_DP_CSQC_QUERYRENDERENTITY = checkextension("DP_CSQC_QUERYRENDERENTITY");

	for (i = 0; i < ENT_CLIENT_COUNT; i++) {
		ent_parsers[i] = Ent_Error;
	}
	ent_parsers[ENT_CLIENT_ENTCS] = Ent_ReadEntCS;
	ent_parsers[ENT_CLIENT_SCORES_INFO] = Ent_ScoresInfo;
	ent_parsers[ENT_CLIENT_SCORES] = Ent_ReadPlayerScore;
	ent_parsers[ENT_CLIENT_TEAMSCORES] = Ent_ReadTeamScore;
	ent_parsers[ENT_CLIENT_POINTPARTICLES] = Ent_PointParticles;
	ent_parsers[ENT_CLIENT_RAINSNOW] = Ent_RainOrSnow;
	ent_parsers[ENT_CLIENT_LASER] = Ent_Laser;
	ent_parsers[ENT_CLIENT_NAGGER] = Ent_Nagger;
	ent_parsers[ENT_CLIENT_WAYPOINT] = Ent_WaypointSprite;
	ent_parsers[ENT_CLIENT_RADARLINK] = Ent_RadarLink;
	ent_parsers[ENT_CLIENT_PROJECTILE] = Ent_Projectile;
	ent_parsers[ENT_CLIENT_GIBSPLASH] = Ent_GibSplash;
	ent_parsers[ENT_CLIENT_DAMAGEINFO] = Ent_DamageInfo;
	ent_parsers[ENT_CLIENT_CASING] = Ent_Casing;
	ent_parsers[ENT_CLIENT_INIT] = Ent_Init;
	ent_parsers[ENT_CLIENT_MAPVOTE] = Ent_MapVote;
	ent_parsers[ENT_CLIENT_CLIENTDATA] = Ent_ClientData;
	ent_parsers[ENT_CLIENT_RANDOMSEED] = Ent_RandomSeed;
	ent_parsers[ENT_CLIENT_WALL] = Ent_Wall;
	ent_parsers[ENT_CLIENT_MODELEFFECT] = Ent_ModelEffect;
	ent_parsers[ENT_CLIENT_LIGHTNING] = Ent_Lightning;
	ent_parsers[ENT_CLIENT_PHYSIC] = Ent_Physic;
	ent_parsers[ENT_CLIENT_PHYSIC_SPIDERBOT] = Ent_PhysicSpiderbot;
	ent_parsers[ENT_CLIENT_PHYSIC_AIRCRAFT] = Ent_PhysicAircraft;
	ent_parsers[ENT_CLIENT_MENU] = Ent_Menu;
	ent_parsers[ENT_CLIENT_PROGRESSBAR] = Ent_ProgressBar;
	ent_parsers[ENT_CLIENT_ENTCS_ENEMY] = Ent_ReadEntCSEnemy;
	ent_parsers[ENT_CLIENT_LOCATION_REQUEST] = Ent_LocationRequest;
	ent_parsers[ENT_CLIENT_DLC_LIST] = Ent_DLCList;
	ent_parsers[ENT_CLIENT_ZAPPER] = Zapper_Read_Beam;
	ent_parsers[ENT_CLIENT_ZAPPER_SHIELD] = Zapper_Read_Shield;
	ent_parsers[ENT_CLIENT_INIT_IP2C] = inline void(void) { sv_ip2country = TRUE; };
}

// CSQC_Shutdown : Called every time the CSQC code is shutdown (changing maps, quitting, etc)
void CSQC_Shutdown(void)
{
#ifdef USE_FTE
#pragma TARGET id
	if(!__engine_check)
		return 0;
#pragma TARGET fte
#endif

	remove(teams);
	remove(players);
	db_close(binddb);
	db_close(tempdb);

	cvar_clientsettemp_restore();

	if(camera_active)
		cvar_set("chase_active",ftos(chase_active_backup));

	if not(isdemo())
	{
		if not(calledhooks & HOOK_START)
			localcmd("\n_cl_hook_gamestart nop;");
		if not(calledhooks & HOOK_END)
			localcmd("\ncl_hook_gameend;");
	}
}

.float has_team;
float SetTeam(entity o, float Team)
{
	entity tm;
	if(teamplay)
	{
		switch(Team)
		{
			case -1:
			case COLOR_TEAM1:
			case COLOR_TEAM2:
			case COLOR_TEAM3:
			case COLOR_TEAM4:
				break;
			default:
				if(GetTeam(Team, false) == NULL)
				{
					print("trying to switch to unsupported team ", ftos(Team), "\n");
					Team = COLOR_SPECTATOR;
				}
				break;
		}
	}
	else
	{
		switch(Team)
		{
			case -1:
			case 0:
				break;
			default:
				if(GetTeam(Team, false) == NULL)
				{
					print("trying to switch to unsupported team ", ftos(Team), "\n");
					Team = COLOR_SPECTATOR;
				}
				break;
		}
	}
	if(Team == -1) // leave
	{
		if(o.has_team)
		{
			//print("(DISCONNECT) leave team ", ftos(o.team), "\n");
			tm = GetTeam(o.team, false);
			tm.team_size -= 1;
			o.has_team = 0;
			return TRUE;
		}
	}
	else
	{
		if not(o.has_team)
		{
			//print("(CONNECT) enter team ", ftos(o.team), "\n");
			o.team = Team;
			tm = GetTeam(Team, true);
			tm.team_size += 1;
			o.has_team = 1;
			return TRUE;
		}
		else if(Team != o.team)
		{
			//print("(CHANGE) leave team ", ftos(o.team), "\n");
			tm = GetTeam(o.team, false);
			tm.team_size -= 1;
			o.team = Team;
			//print("(CHANGE) enter team ", ftos(o.team), "\n");
			tm = GetTeam(Team, true);
			tm.team_size += 1;
			return TRUE;
		}
	}
	return FALSE;
}

void Playerchecker_Think()
{
	float i;
	entity e;
	for(i = 0; i < maxclients; ++i)
	{
		e = playerslots[i];
		if(GetPlayerName(i) == "")
		{
			if(e.sort_prev)
			{
				//print("playerchecker: KILL KILL KILL\n");
				// player disconnected
				SetTeam(e, -1);
				RemovePlayer(e);
				e.sort_prev = world;
				//e.gotscores = 0;
			}
		}
		else
		{
			if not(e.sort_prev)
			{
				//print("playerchecker: SPAWN SPAWN SPAWN\n");
				// player connected
				if not(e)
					playerslots[i] = e = spawn();
				e.sv_entnum = i;
				//e.gotscores = 0; // we might already have the scores...
				SetTeam(e, GetPlayerColor(i)); // will not hurt; later updates come with Sbar_UpdatePlayerTeams
				RegisterPlayer(e);
				Sbar_UpdatePlayerPos(e);
			}
		}
	}
	self.nextthink = time + 0.2;
}

void TrueAim_Init();
void PostInit(void)
{
	print(strcat("PostInit\n    maxclients = ", ftos(maxclients), "\n"));
	localcmd(strcat("\ncl_cmd sbar_columns_set ", cvar_string("sbar_columns"), ";\n"));

	entity playerchecker;
	playerchecker = spawn();
	playerchecker.think = Playerchecker_Think;
	playerchecker.nextthink = time + 0.2;

	TrueAim_Init();

	postinit = true;
}

// CSQC_ConsoleCommand : Used to parse commands in the console that have been registered with the "registercmd" function
// Return value should be 1 if CSQC handled the command, otherwise return 0 to have the engine handle it.
float button_zoom;
void Cmd_Sbar_SetFields(float);
void Cmd_Sbar_Help(float);
float CSQC_ConsoleCommand(string strMessage)
{
	float argc;
	// Tokenize String
	//argc = tokenize(strMessage);
	argc = tokenize_console(strMessage);

	// Acquire Command
	local string strCmd;
	strCmd = argv(0);

	if(strCmd == "+button4") { // zoom
		// return false, because the message shall be sent to the server anyway (for demos/speccing)
		if(ignore_plus_zoom)
		{
			--ignore_plus_zoom;
			return false;
		}
		button_zoom = 1;
		return true;
	} else if(strCmd == "-button4") { // zoom
		if(ignore_minus_zoom)
		{
			--ignore_minus_zoom;
			return false;
		}
		button_zoom = 0;
		return true;
	} else if(strCmd == "+button3") { // secondary
		button_attack2 = 1;
		return false;
	} else if(strCmd == "-button3") { // secondary
		button_attack2 = 0;
		return false;
	} else if(strCmd == "+showscores") {
		sb_showscores = true;
		return true;
	} else if(strCmd == "-showscores") {
		sb_showscores = false;
		return true;
	} else if(strCmd == "+showaccuracy") {
		sb_showaccuracy = true;
		return true;
	} else if(strCmd == "-showaccuracy") {
		sb_showaccuracy = false;
		return true;
	}

	if(camera_active)
	if(strCmd == "+forward" || strCmd == "-back") {
		++camera_direction_x;
		return true;
	} else if(strCmd == "-forward" || strCmd == "+back") {
		--camera_direction_x;
		return true;
	} else if(strCmd == "+moveright" || strCmd == "-moveleft") {
		--camera_direction_y;
		return true;
	} else if(strCmd == "-moveright" || strCmd == "+moveleft") {
		++camera_direction_y;
		return true;
	} else if(strCmd == "+moveup" || strCmd == "-movedown") {
		++camera_direction_z;
		return true;
	} else if(strCmd == "-moveup" || strCmd == "+movedown") {
		--camera_direction_z;
		return true;
	} else if(strCmd == "+roll_right" || strCmd == "-roll_left") {
		++camera_roll;
		return true;
	} else if(strCmd == "+roll_left" || strCmd == "-roll_right") {
		--camera_roll;
		return true;
	}

	return false;
}

.vector view_ofs;
entity debug_shotorg;
void ShotOrg_Draw()
{
	self.origin = view_origin + view_forward * self.view_ofs_x + view_right * self.view_ofs_y + view_up * self.view_ofs_z;
	self.angles = view_angles;
	self.angles_x = -self.angles_x;
	if not(self.cnt)
		R_AddEntity(self);
}
void ShotOrg_Draw2D()
{
	vector coord2d_topleft, coord2d_topright, coord2d;
	string s;
	vector fs;

	s = vtos(self.view_ofs);
	s = substring(s, 1, strlen(s) - 2);
	if(tokenize_console(s) == 3)
		s = strcat(argv(0), " ", argv(1), " ", argv(2));

	coord2d_topleft = project_3d_to_2d(self.origin + view_up * 4 - view_right * 4);
	coord2d_topright = project_3d_to_2d(self.origin + view_up * 4 + view_right * 4);

	fs = '1 1 0' * ((coord2d_topright_x - coord2d_topleft_x) / stringwidth(s, FALSE));

	coord2d = coord2d_topleft;
	if(fs_x < 8)
	{
		coord2d_x += (coord2d_topright_x - coord2d_topleft_x) * (1 - 8 / fs_x) * 0.5;
		fs = '8 8 0';
	}
	coord2d_y -= fs_y;
	coord2d_z = 0;
	drawstring(coord2d, s, fs, '1 1 1', 1, 0);
}

void ShotOrg_Spawn()
{
	debug_shotorg = spawn();
	debug_shotorg.draw = ShotOrg_Draw;
	debug_shotorg.draw2d = ShotOrg_Draw2D;
	debug_shotorg.renderflags = RF_VIEWMODEL;
	debug_shotorg.effects = EF_FULLBRIGHT;
	precache_model("models/shotorg_adjuster.md3");
	setmodel(debug_shotorg, "models/shotorg_adjuster.md3");
	debug_shotorg.scale = 2;
	debug_shotorg.view_ofs = '25 8 -8';
}

void GameCommand(string msg)
{
	float argc;
	argc = tokenize_console(msg);

	if(argv(0) == "help" || argc == 0)
	{
		print("Usage: cl_cmd COMMAND..., where possible commands are:\n");
		print("  settemp cvar value\n");
		print("  radar\n");
		print("  sbar_columns_set ...\n");
		print("  sbar_columns_help\n");
		GameCommand_Generic("help");
		return;
	}

	if(GameCommand_Generic(msg))
		return;

	string cmd;
	cmd = argv(0);
	if(cmd == "mv_download") {
		Cmd_MapVote_MapDownload(argc);
	}
	else if(cmd == "settemp") {
		cvar_clientsettemp(argv(1), argv(2));
	}
	else if(cmd == "radar") {
		ons_showmap = !ons_showmap;
	}
	else if(cmd == "sbar_columns_set") {
		Cmd_Sbar_SetFields(argc);
	}
	else if(cmd == "sbar_columns_help") {
		Cmd_Sbar_Help(argc);
	}
#ifdef BLURTEST
	else if(cmd == "blurtest") {
		blurtest_time0 = time;
		blurtest_time1 = time + stof(argv(1));
		blurtest_radius = stof(argv(2));
		blurtest_power = stof(argv(3));
	}
#endif
	else if(cmd == "shotorg_move") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs + stov(argv(1));
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_movez") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs + stof(argv(1)) * (debug_shotorg.view_ofs * (1 / debug_shotorg.view_ofs_x)); // closer/farther, same xy pos
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_set") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = stov(argv(1));
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_setz") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs * (stof(argv(1)) / debug_shotorg.view_ofs_x); // closer/farther, same xy pos
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_toggle_hide") {
		if(debug_shotorg)
		{
			debug_shotorg.cnt = !debug_shotorg.cnt;
		}
	}
	else if(cmd == "shotorg_end") {
		if(debug_shotorg)
		{
			print(vtos(debug_shotorg.view_ofs), "\n");
			remove(debug_shotorg);
			debug_shotorg = world;
		}
		localcmd("sv_cmd debug_shotorg\n");
	}
	else if(cmd == "sendcvar") {
	}
	else if(cmd == "handlevote") {
		localcmd(strcat("cmd vote ", argv(1), "\n"));
	} else if(cmd == "modelprecache") {
		precache_model(argv(1));
	}
	else
	{
		print("Invalid command '", cmd, "'. For a list of supported commands, try cl_cmd help.\n");
	}

	return;
}

// CSQC_InputEvent : Used to perform actions based on any key pressed, key released and mouse on the client.
// Return value should be 1 if CSQC handled the input, otherwise return 0 to have the input passed to the engine.
// All keys are in ascii.
// bInputType = 0 is key pressed, 1 is key released, 2 is mouse input.
// In the case of keyboard input, nPrimary is the ascii code, and nSecondary is 0.
// In the case of mouse input, nPrimary is xdelta, nSecondary is ydelta.
float gamemenu;
var float(float bInputType, float nPrimary, float nSecondary) CSQC_InputEvent_Callback_null;
float CSQC_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	local float bSkipKey;
	bSkipKey = false;

	if (CSQC_InputEvent_Callback) {
		bSkipKey = CSQC_InputEvent_Callback(bInputType, nPrimary, nSecondary);
		CSQC_InputEvent_Callback = CSQC_InputEvent_Callback_null;
		return bSkipKey;
	}

	if (bInputType == 0)
	if (nPrimary == K_ESCAPE)
	if not(intermission)
	if not(isdemo())
	if (gamemenu)
	{
		GameMenu_Holder();
		localcmd("\ncmd gamemenu\n");
		return true;
	}

	return bSkipKey;
}

// END REQUIRED CSQC FUNCTIONS
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// BEGIN OPTIONAL CSQC FUNCTIONS
void Ent_ReadEntCS(float bIsNewEntity)
{
	InterpolateOrigin_Undo();

	self.sv_entnum = ReadByte() - 1;
	self.origin_x = ReadShort();
	self.origin_y = ReadShort();
	self.origin_z = ReadShort();
	self.angles_y = ReadByte() * 360.0 / 256;
	self.origin_z = self.angles_x = self.angles_z = 0;
	self.classname = "entcs_receiver";
	self.cnt = 0;
	if (bIsNewEntity)
		Shownames_Init(self);

	InterpolateOrigin_Note();
}

void Ent_ReadEntCSEnemy(float bIsNewEntity)
{
	self.sv_entnum = ReadByte() - 1;
	self.classname = "entcs_receiver_enemy";
	self.cnt = 1;
	if (bIsNewEntity)
		Shownames_Init(self);
}

void Ent_Remove();

void Ent_RemovePlayerScore(float ignore)
{
	float i;

	if(self.owner)
	{
		SetTeam(self.owner, -1);
		self.owner.gotscores = 0;
		for(i = 0; i < MAX_SCORE; ++i)
			self.owner.(scores[i]) = 0; // clear all scores
	}
}

void Ent_ReadPlayerScore(float ignore)
{
	float i, n;
	float isNew;
	entity o;

	// damnit -.- don't want to go change every single .sv_entnum in sbar.qc AGAIN
	// (no I've never heard of M-x replace-string, sed, or anything like that)
	isNew = !self.owner; // workaround for DP bug
	n = ReadByte()-1;

#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if(!isNew && n != self.sv_entnum)
	{
		print("A CSQC entity changed its owner!\n");
		isNew = true;
		Ent_Remove();
		self.enttype = ENT_CLIENT_SCORES;
	}
#endif

	self.sv_entnum = n;

	if not(playerslots[self.sv_entnum])
		playerslots[self.sv_entnum] = spawn();
	o = self.owner = playerslots[self.sv_entnum];
	o.sv_entnum = self.sv_entnum;
	o.gotscores = 1;

	//if not(o.sort_prev)
	//	RegisterPlayer(o);
	//playerchecker will do this for us later, if it has not already done so

	float sf, lf;
#if MAX_SCORE <= 8
	sf = ReadByte();
	lf = ReadByte();
#else
	sf = ReadShort();
	lf = ReadShort();
#endif
	float p;
	for(i = 0, p = 1; i < MAX_SCORE; ++i, p *= 2)
		if(sf & p)
		{
			if(lf & p)
				o.(scores[i]) = ReadInt24_t();
			else
				o.(scores[i]) = ReadChar();
		}

	if(o.sort_prev)
		Sbar_UpdatePlayerPos(o); // if not registered, we cannot do this yet!

	self.entremove = Ent_RemovePlayerScore;
}

void Ent_ReadTeamScore(float ignore)
{
	float i;
	entity o;

	self.team = ReadByte();
	o = self.owner = GetTeam(self.team, true); // these team numbers can always be trusted

	float sf, lf;
#if MAX_TEAMSCORE <= 8
	sf = ReadByte();
	lf = ReadByte();
#else
	sf = ReadShort();
	lf = ReadShort();
#endif
	float p;
	for(i = 0, p = 1; i < MAX_TEAMSCORE; ++i, p *= 2)
		if(sf & p)
		{
			if(lf & p)
				o.(teamscores[i]) = ReadInt24_t();
			else
				o.(teamscores[i]) = ReadChar();
		}

	Sbar_UpdateTeamPos(o);
}

void Net_Reset()
{
}

void Ent_ClientData(float ignore)
{
	float f;
	float newspectatee_status;

	f = ReadByte();

	//sb_showscores_force = (f & 1);

	if(f & 2)
	{
		newspectatee_status = ReadByte();
		if(newspectatee_status == player_localentnum)
			newspectatee_status = -1; // observing
	}
	else
		newspectatee_status = 0;

	spectatorbutton_zoom = (f & 4);

	if(f & 8)
	{
		angles_held_status = 1;
		angles_held_x = ReadAngle();
		angles_held_y = ReadAngle();
		angles_held_z = 0;
	}
	else
		angles_held_status = 0;

	if(newspectatee_status != spectatee_status)
	{
		// clear race stuff
		race_laptime = 0;
		race_checkpointtime = 0;
	}
	spectatee_status = newspectatee_status;
}

void Ent_Nagger(float ignore)
{
	float nags, i, j, b, f;

	nags = ReadByte();

	if(nags & 128)
	{
		if(vote_called_vote)
			strunzone(vote_called_vote);
		vote_called_vote = strzone(ColorTranslateRGB(ReadString()));
	}

	if(nags & 1)
	{
		for(j = 0; j < maxclients; ++j)
			if(playerslots[j])
				playerslots[j].ready = 1;
		for(i = 1; i <= maxclients; i += 8)
		{
			f = ReadByte();
			for(j = i-1, b = 1; b < 256; b *= 2, ++j)
				if not(f & b)
					if(playerslots[j])
						playerslots[j].ready = 0;
		}
	}

	ready_waiting = (nags & 1);
	ready_waiting_for_me = (nags & 2);
	vote_waiting = (nags & 4);
	vote_waiting_for_me = (nags & 8);
	warmup_stage = (nags & 16);
}

void Ent_RandomSeed(float ignore)
{
	float s;
	prandom_debug();
	s = ReadShort();
	psrandom(s);
}

// CSQC_Ent_Update : Called every frame that the server has indicated an update to the SSQC / CSQC entity has occured.
// The only parameter reflects if the entity is "new" to the client, meaning it just came into the client's PVS.
void(float bIsNewEntity) CSQC_Ent_Update =
{
	float t;
	float savetime;
	t = ReadByte();

	// set up the "time" global for received entities to be correct for interpolation purposes
	savetime = time;
	if(servertime)
	{
		time = servertime;
	}
	else
	{
		serverprevtime = time;
		serverdeltatime = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);
		time = serverprevtime + serverdeltatime;
	}
	clienttime = time;
#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if(self.enttype)
		if(t != self.enttype)
		{
			print("A CSQC entity changed its type!\n");
			Ent_Remove();
			bIsNewEntity = 1;
		}
#endif
	if (t >= ENT_CLIENT_COUNT)
		Ent_Error(0);

	self.enttype = t;
	ent_parsers[t](bIsNewEntity);
	time = savetime;
};
// Destructor, but does NOT deallocate the entity by calling remove(). Also
// used when an entity changes its type. For an entity that someone interacts
// with others, make sure it can no longer do so.
void Ent_Remove()
{
	if(self.entremove)
		self.entremove();

	self.enttype = 0;
	self.classname = "";
	self.draw = world.draw;
	self.entremove = world.entremove;
	// TODO possibly set more stuff to defaults
}
// CSQC_Ent_Remove : Called when the server requests a SSQC / CSQC entity to be removed.  Essentially call remove(self) as well.
void CSQC_Ent_Remove()
{
	if(self.enttype)
		Ent_Remove();
	remove(self);
}

void Gamemode_Init()
{
	if(gametype == GAME_ONSLAUGHT) {
		print(strcat("Using ", minimapname, " as minimap.\n"));
		precache_pic("gfx/ons-cp-neutral.tga");
		precache_pic("gfx/ons-cp-red.tga");
		precache_pic("gfx/ons-cp-blue.tga");
		precache_pic("gfx/ons-frame.tga");
		precache_pic("gfx/ons-frame-team.tga");
	} else if(gametype == GAME_KEYHUNT) {
		precache_pic("gfx/sb_key_carrying");
		precache_pic("gfx/sb_key_carrying_outline");
	}

	if not(isdemo())
	{
		localcmd("\n_cl_hook_gamestart ", GametypeNameFromType(gametype), ";");
		calledhooks |= HOOK_START;
	}
}
// CSQC_Parse_StuffCmd : Provides the stuffcmd string in the first parameter that the server provided.  To execute standard behavior, simply execute localcmd with the string.
void CSQC_Parse_StuffCmd(string strMessage)
{
	localcmd(strMessage);
}
// CSQC_Parse_Print : Provides the print string in the first parameter that the server provided.  To execute standard behavior, simply execute print with the string.
void CSQC_Parse_Print(string strMessage)
{
	print(ColorTranslateRGB(strMessage));
}

// CSQC_Parse_CenterPrint : Provides the centerprint string in the first parameter that the server provided.
void CSQC_Parse_CenterPrint(string strMessage)
{
	centerprint(strMessage);
}

void Fog_Force()
{
	// TODO somehow thwart prvm_globalset client ...

	if(forcefog != "")
		localcmd(strcat("\nfog ", forcefog, "\nr_fog_exp2 0\nr_drawfog 1\n"));
}

void Gamemode_Init();
void Ent_ScoresInfo(float ignore)
{
	float i;
	self.classname = "ent_client_scores_info";
	gametype = ReadByte();
	for(i = 0; i < MAX_SCORE; ++i)
	{
		scores_label[i] = strzone(ReadString());
		scores_flags[i] = ReadByte();
	}
	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		teamscores_label[i] = strzone(ReadString());
		teamscores_flags[i] = ReadByte();
	}
	Sbar_InitScores();
	Gamemode_Init();
}

void Ent_Init(float ignore)
{
	float i;
	self.classname = "ent_client_init";
	float sf = ReadByte();

	if (sf & 1) {
		for(i = 0; i < 24; ++i)
			weaponimpulse[i] = ReadByte() - 1;
	}
	if (sf & 2) {
		hook_shotorigin_x = ReadCoord();
		hook_shotorigin_y = ReadCoord();
		hook_shotorigin_z = ReadCoord();
	}

	if (sf & 4) {
		unzone_ifneeded(forcefog);
		forcefog = zone_ifneeded(ReadString());
	}

	if (sf & 8)
		armorblockpercent = ReadByte() / 255.0;

	if (sf & 16)
		gamemenu = ReadByte();

	if (sf & 32) {
		teamplay = ReadByte();
		registercvar("_teams_available", "0");
		cvar_set("_teams_available", ftos(ReadByte()));
		Sbar_InitScores();
	}

	if (sf & 64) {
		ProjInfo_Read();
	}

	if(!postinit)
		PostInit();
}

void Net_ReadRace()
{
	float b;

	b = ReadByte();

	switch(b)
	{
		case RACE_NET_CHECKPOINT_HIT_QUALIFYING:
			race_checkpoint = ReadByte();
			race_time = ReadInt24_t();
			race_previousbesttime = ReadInt24_t();
			if(race_previousbestname)
				strunzone(race_previousbestname);
			race_previousbestname = strzone(ColorTranslateRGB(ReadString()));

			race_checkpointtime = time;

			if(race_checkpoint == 0 || race_checkpoint == 254)
			{
				race_penaltyaccumulator = 0;
				race_laptime = time; // valid
			}

			break;

		case RACE_NET_CHECKPOINT_CLEAR:
			race_laptime = 0;
			race_checkpointtime = 0;
			break;

		case RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING:
			race_laptime = ReadCoord();
			race_checkpointtime = -99999;
			// fall through
		case RACE_NET_CHECKPOINT_NEXT_QUALIFYING:
			race_nextcheckpoint = ReadByte();

			race_nextbesttime = ReadInt24_t();
			if(race_nextbestname)
				strunzone(race_nextbestname);
			race_nextbestname = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE:
			race_mycheckpoint = ReadByte();
			race_mycheckpointtime = time;
			race_mycheckpointdelta = ReadInt24_t();
			race_mycheckpointlapsdelta = ReadByte();
			if(race_mycheckpointlapsdelta >= 128)
				race_mycheckpointlapsdelta -= 256;
			if(race_mycheckpointenemy)
				strunzone(race_mycheckpointenemy);
			race_mycheckpointenemy = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT:
			race_othercheckpoint = ReadByte();
			race_othercheckpointtime = time;
			race_othercheckpointdelta = ReadInt24_t();
			race_othercheckpointlapsdelta = ReadByte();
			if(race_othercheckpointlapsdelta >= 128)
				race_othercheckpointlapsdelta -= 256;
			if(race_othercheckpointenemy)
				strunzone(race_othercheckpointenemy);
			race_othercheckpointenemy = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_PENALTY_RACE:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			//race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);
			race_penaltyreason = strzone(ReadString());
			break;

		case RACE_NET_PENALTY_QUALIFYING:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);
			race_penaltyreason = strzone(ReadString());
			break;
	}
}

void Net_ReadSpawn()
{
	zoomin_effect = 1;
	current_viewzoom = 0.6;
}

// CSQC_Parse_TempEntity : Handles all temporary entity network data in the CSQC layer.
// You must ALWAYS first acquire the temporary ID, which is sent as a byte.
// Return value should be 1 if CSQC handled the temporary entity, otherwise return 0 to have the engine process the event.
float CSQC_Parse_TempEntity()
{
	local float bHandled;
		bHandled  = true;
	// Acquire TE ID
	local float nTEID;
		nTEID = ReadByte();

		// NOTE: Could just do return instead of break...
	switch(nTEID)
	{
		case TE_CSQC_PICTURE:
			Net_MapVote_Picture();
			bHandled = true;
			break;
		case TE_CSQC_RACE:
			Net_ReadRace();
			bHandled = true;
			break;
		case 13: // TE_BEAM
			Net_GrapplingHook();
			bHandled = true;
			break;
		case TE_CSQC_SPAWN:
			Net_ReadSpawn();
			bHandled = true;
			break;
		case TE_CSQC_ZCURVEPARTICLES:
			Net_ReadZCurveParticles();
			bHandled = true;
			break;
		case TE_CSQC_NEXGUNBEAMPARTICLE:
			Net_ReadNexgunBeamParticle();
			bHandled = true;
			break;
        case TE_CSQC_LIGHTNINGARC:
            Net_ReadLightningarc();
            bHandled = true;
            break;
        case TE_CSQC_ZAPPERLIGHTNING:
            Zapper_ReadLightning();
            bHandled = true;
            break;
        case TE_CSQC_NADGETSELECT:
			Net_ReadNadgetSelect();
            bHandled = true;
            break;
		case TE_CSQC_BLAST:
			Net_ReadBlast();
			bHandled = true;
			break;
		default:
			// No special logic for this temporary entity; return 0 so the engine can handle it
			bHandled = false;
			break;
	}

	return bHandled;
}

string getcommandkey(string text, string command)
{
	string keys;
	float n, j, k, l;

	if (!CVAR(sbar_showbinds))
		return text;

	keys = db_get(binddb, command);
	if (!keys)
	{
		n = tokenize(findkeysforcommand(command)); // uses '...' strings
		for(j = 0; j < n; ++j)
		{
			k = stof(argv(j));
			if(k != -1)
			{
				if ("" == keys)
					keys = keynumtostring(k);
				else
					keys = strcat(keys, ", ", keynumtostring(k));

				++l;
				if (CVAR(sbar_showbinds_limit) > 0 && CVAR(sbar_showbinds_limit) >= l) break;
			}

		}
		db_put(binddb, command, keys);
	}

	if ("" == keys) {
		if (CVAR(sbar_showbinds) > 1)
			return strcat(text, " (not bound)");
		else
			return text;
	}
	else if (CVAR(sbar_showbinds) > 1)
		return strcat(text, " (", keys, ")");
	else
		return keys;
}
