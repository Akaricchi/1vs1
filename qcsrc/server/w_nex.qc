float g_balance_nex_ammo;
float g_balance_nex_animtime;
float g_balance_nex_damage;
float g_balance_nex_damagefalloff_forcehalflife;
float g_balance_nex_damagefalloff_halflife;
float g_balance_nex_damagefalloff_maxdist;
float g_balance_nex_damagefalloff_mindist;
float g_balance_nex_force;
float g_balance_nex_refire;

.float nex_lasthit;

void SendCSQCNexBeamParticle() {
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_NEXGUNBEAMPARTICLE);
	
	WriteCoord(MSG_BROADCAST, w_shotorg_visual_x);
	WriteCoord(MSG_BROADCAST, w_shotorg_visual_y);
	WriteCoord(MSG_BROADCAST, w_shotorg_visual_z);
	WriteCoord(MSG_BROADCAST, trace_endpos_x);
	WriteCoord(MSG_BROADCAST, trace_endpos_y);
	WriteCoord(MSG_BROADCAST, trace_endpos_z);
}

void W_Nex_Attack (void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	W_SetupShot (self, TRUE, 5, "weapons/nexfire.wav", g_balance_nex_damage);

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, g_balance_nex_damage, g_balance_nex_force, g_balance_nex_damagefalloff_mindist, g_balance_nex_damagefalloff_maxdist, g_balance_nex_damagefalloff_halflife, g_balance_nex_damagefalloff_forcehalflife, WEP_NEX);

	if(yoda && flying)
		announce(self, "announcer/male/yoda.wav");
	else if (damage_goodhits && self.nex_lasthit && sv_announcer_extra_twohits != "")
	{
		if(announce(self, sv_announcer_extra_twohits))
			damage_goodhits = 0; // only every second time
	}
	self.nex_lasthit = damage_goodhits;

	//beam and muzzle flash done on client
	SendCSQCNexBeamParticle();
	
	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		Damage_DamageInfo(trace_endpos, g_balance_nex_damage, 0, 0, g_balance_nex_force * w_shotdir, WEP_NEX, self);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_nex_ammo;
}

void spawnfunc_weapon_nex (void); // defined in t_items.qc

float w_nex(float req)
{
	if (req == WR_AIM)
		self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, g_balance_nex_refire))
			{
				W_Nex_Attack();
				weapon_thinkf(WFRAME_FIRE1, g_balance_nex_animtime, w_ready);
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/nexflash.md3");
		precache_sound ("weapons/nexfire.wav");
		precache_sound ("weapons/nexwhoosh1.wav");
		precache_sound ("weapons/nexwhoosh2.wav");
		precache_sound ("weapons/nexwhoosh3.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_NEX);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= g_balance_nex_ammo;
	else if (req == WR_CHECKAMMO2)
		return FALSE;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "has been vaporized by";
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_nex_ammo);
		CACHE_CVAR(g_balance_nex_animtime);
		CACHE_CVAR(g_balance_nex_damage);
		CACHE_CVAR(g_balance_nex_damagefalloff_forcehalflife);
		CACHE_CVAR(g_balance_nex_damagefalloff_halflife);
		CACHE_CVAR(g_balance_nex_damagefalloff_maxdist);
		CACHE_CVAR(g_balance_nex_damagefalloff_mindist);
		CACHE_CVAR(g_balance_nex_force);
		CACHE_CVAR(g_balance_nex_refire);
	}
	return TRUE;
};
