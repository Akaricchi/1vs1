void monster_set_route() {
	float f1, f2;
	entity p;
	if (self.items & IT_JETPACK) {
		f1 = bot_ai_navigation_jetpack;
		f2 = bot_ai_navigation_jetpack_mindistance;
		bot_ai_navigation_jetpack = TRUE;
		bot_ai_navigation_jetpack_mindistance = 100;
	}
	bot_navigation_movemode = MOVE_NORMAL;
	navigation_clearroute();
	navigation_goalrating_start();
	if (self.enemy)
		navigation_routerating(self.enemy, 10000, 10000);
	else
		FOR_EACH_PLAYER(p)
			if (p.health >= 1)
				navigation_routerating(p, 10000, 10000);

	navigation_goalrating_end();
	if (self.items & IT_JETPACK) {
		bot_ai_navigation_jetpack = f1;
		bot_ai_navigation_jetpack_mindistance = f2;
	}
}

entity monster_look_for_player(float distance, float heardistance, float fov_factor, float attack_delay, float attack_delay_jitter) {
	entity e;
	vector v;
	float f;
	entity p = world;
	if not(gameover)
	FOR_EACH_PLAYER(e)
	if (e.health >= 1) {
		if (teamplay) {
			if not(self.team)
				continue;

			if (self.team == e.team)
				continue;
		}
		f = vlen(e.origin - self.origin);
		if (f <= heardistance) {
			traceline(self.origin, e.origin, MOVE_WORLDONLY, self);
			if (trace_fraction == 1) {
				p = e;
				break;
			}
		} else if (f <= distance) {
			v = normalize(e.origin - self.origin);
			makevectors(self.angles);
			if (v * normalize(v_forward) >= fov_factor) {
				traceline(self.origin, e.origin, MOVE_WORLDONLY, self);
				if (trace_fraction == 1) {
					distance = f;
					p = e;
				}
			}
		}
	}
	if (p) {
		if (self.enemy)
		if (self.enemy.classname == "monster_walk_path")
			self.message2 = self.enemy.targetname;

		self.think = self.weapon_think;
		self.enemy = p;
		self.attack_finished_single = time + random() * attack_delay_jitter + attack_delay;
		self.think();
	}
	return p;
}

void monster_die() {
	Violence_GibSplash(self, 1, 1, self.enemy);
	self.solid = SOLID_NOT;
	self.alpha = -1;
	self.nextthink = time;
	self.think = SUB_Remove;
}

void monster_corpse_event_damage() {
	if (self.health < -200)
		monster_die();
}

void monster_die_animated() {
	setanim(self, self.anim_die1, FALSE, TRUE, TRUE);
	self.movetype = MOVETYPE_TOSS;
	self.solid = SOLID_TRIGGER;
	self.nextthink = time + 5;
	self.think = monster_die;
	self.event_damage = monster_corpse_event_damage;
}

void monster_event_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
	if (attacker.classname != "monster")
		self.health = self.health - damage;

	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);
	self.velocity = self.velocity + force * self.damageforcescale;
	if (self.health < 1) {
		GameHook_MonsterKilled(attacker);
		entity o = self.owner;
		if (o.spawnflags & 1) {
			o.nextthink = time + o.respawntime;
			o.dmg = o.dmg + GameHook_MonsterQuant();
		}
		self.enemy = attacker;
		if (self.anim_die1 != '0 0 0')
			monster_die_animated();
		else
			monster_die();
	} else if (attacker.classname == "player") {
		if (self.enemy) {
			if (self.enemy.classname == "monster_walk_path")
				self.message2 = self.enemy.targetname;
			else
				return;
		}

		self.enemy = attacker;
		self.think = self.weapon_think;
	}
}

vector monster_get_direction() {
	if (self.goalcurrent)
		navigation_poptouchedgoals();

	vector v;
	if (self.goalcurrent) {
		//print("self.goalcurrent=", self.goalcurrent.classname, "\n");
		if (self.navigation_jetpack_goal == self.goalcurrent) {
			v = self.navigation_jetpack_point - self.origin;
			//print("Trying fly\n");
		} else
			v = self.goalcurrent.origin - self.origin;
	} else
		v = self.enemy.origin - self.origin;

	return normalize(v);
}

vector monster_move_walk(float _speed, float blend_factor, float rushdistance) {
	float dir_z_save;
	float vel_z_save;
	vector v;
	if (rushdistance)
	if (self.enemy)
	if (rushdistance > vlen(self.origin - self.enemy.origin)) {
		v = normalize(self.enemy.origin - self.origin);
		dir_z_save = v_z;
		vel_z_save = self.velocity_z;
		movelib_move_simple(v, _speed, blend_factor * frametime);
		v_z = dir_z_save;
		self.velocity_z = vel_z_save;
		return v;
	}
	if (self.bot_strategytime < time) {
		self.bot_strategytime = time + 1 + random() * 1;
		monster_set_route();
	}
	v = monster_get_direction();
	v_z = 0;
	dir_z_save = v_z;
	vel_z_save = self.velocity_z;
	movelib_move_simple(v, _speed, blend_factor * frametime);
	v_z = dir_z_save;
	self.velocity_z = vel_z_save;
	return v;
}

vector monster_move_fly(float _speed, float blend_factor) {
	if (self.bot_strategytime < time) {
		self.bot_strategytime = time + 1 + random() * 1;
		monster_set_route();
	}
	vector v;
	v = monster_get_direction();
	v_z = v_z + 0.5 * vlen(v);
	movelib_move_simple(normalize(v), _speed, blend_factor * frametime);
	return v;
}

void monster_spawn_think() {
	float quant = GameHook_MonsterQuant();
	if (teamplay)
	if not(self.team)
		return;

	if (self.dmg < quant)
		return;

	entity oldself = self;
	self = spawn();
	self.angles = oldself.angles;
	setorigin(self, oldself.origin);
	sound (self, CHAN_TRIGGER, "misc/teleport.wav", VOL_BASE, ATTN_NORM);
	pointparticles(particleeffectnum("teleport"), self.origin, '0 0 0', 1);
	self.owner = oldself;
	self.reset = monster_die;
	oldself.weapon_think();

	self = oldself;
	self.dmg = self.dmg - quant;
	self.nextthink = time + self.respawntime;
}

void monster_spawn_use() {
	if not(self.spawnflags & 1)
		self.reset();

	if (activator)
		self.team = activator.team;

	self.think();
}

void monster_prepare(void() hunt, void() walk, void() idle) {
	self.classname = "monster";
	self.health = self.owner.health;
	self.iscreature = TRUE;
	self.bot_attack = TRUE;
	self.team = self.owner.team;
	self.weapon_think = hunt;
	self.nextthink = time;
	string t = self.owner.target;
	if (t == "")
		t = self.target;

	if (t != "")
		self.enemy = find(world, targetname, t);

	if (self.enemy || self.owner.spawnflags & 2) {
		self.think = walk;
		//print("Prepare route\n");
	} else
		self.think = idle;

	self.event_damage = monster_event_damage;
	if (self.team > 0)
		self.colormod = TeamColorMod(self.team);
}

void monster_set_fly() {
	self.items = IT_JETPACK | IT_UNLIMITED_WEAPON_AMMO;
}

float monster_walk_finished(void() idle, float dist) {
	if not(self.enemy) //Free walk
		return FALSE;

	vector v = self.enemy.origin - self.origin;
	v_z = 0;
	if (self.owner.spawnflags & 2 && vlen(v) < dist) {
		if (self.enemy.target != "")
			self.enemy = find(world, targetname, self.enemy.target);
		else
			self.enemy = world;

		if not(self.enemy) {
			self.think = idle;
			idle();
			return TRUE;
		} else
			monster_set_route();
	} else if not(self.goalcurrent) {
		if (self.bot_strategytime < time) {
			self.bot_strategytime = time + 1 + random();
			monster_set_route();
		}
	}
	return FALSE;
}

float monster_check_target(void() walk, void() guard) {
	if (self.enemy.health < 1) {
		self.enemy = world;
		if (self.message2 != "")
			self.enemy = find(world, targetname, self.message2);

		if (self.enemy || self.owner.spawnflags & 2) {
			self.think = walk;
			monster_set_route();
		} else
			self.think = guard;

		self.think();
		return TRUE;
	} else if (self.bot_strategytime < time) {
		self.bot_strategytime = time + 1 + random() * 1;
		monster_set_route();
	}
	return FALSE;
}

float monster_common_init_done;
void monster_common_init() {
	precache_sound("misc/teleport.wav");
}

void monster_init(void() init_func) {
	if not(monster_common_init_done) {
		monster_common_init();
		monster_common_init_done = TRUE;
	}
	if (find(world, classname, self.classname) != self)
		return;

	init_func();
}

string monster_classname() {
	float spawn_suffix = strstrofs(self.classname, "_spawn", 0);
	if (spawn_suffix >= 0) {
		return substring(self.classname, 0, spawn_suffix);
	}
	return self.classname;
}

void monster_prepare_spawn(void() spawnfunc, void() resetfunc) {
	self.weapon_think = spawnfunc;
	self.think = monster_spawn_think;
	self.use = monster_spawn_use;
	self.nextthink = 0;
	self.dmg = max(self.cnt, 1);
	self.reset = resetfunc;
	self.health = cvar(strcat("g_monster_", monster_classname(), "_health"));
	if (teamplay)
	if not(self.team)
		self.team = -1;

	if (self.targetname == "") {
		self.nextthink = time;
	}
}

void spawnfunc_monster_walk_path() {
#if 0
	setmodel(self, "models/ebomb.mdl");
	self.scale = 4;
	self.solid = SOLID_NOT;
#endif
}
