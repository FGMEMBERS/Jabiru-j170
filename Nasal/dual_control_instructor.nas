var autoupdate_props = ["/position/altitude-ft", "/position/latitude-deg", "/position/longitude-deg", "/orientation/pitch-deg", "/orientation/roll-deg"];

var cockpit_props = [["/dualcontrol/props/master", "/sim/multiplay/generic/int[6]"],
["/dualcontrol/props/ind-airspeed", "/sim/multiplay/generic/float"],
["/dualcontrol/props/ind-altitude", "/sim/multiplay/generic/float[1]"],
["/dualcontrol/props/setting-inhg", "/sim/multiplay/generic/float[2]"],
["/dualcontrol/props/turn-rate", "/sim/multiplay/generic/float[3]"],
["/dualcontrol/props/slip-skid", "/sim/multiplay/generic/float[4]"],
["/dualcontrol/props/serviceable/avionics", "/sim/multiplay/generic/float[5]"],
["/dualcontrol/props/starter", "/sim/multiplay/generic/float[6]"],
["/dualcontrol/props/charge", "/sim/multiplay/generic/float[7]"],
["/dualcontrol/props/bat-charge", "/sim/multiplay/generic/float[8]"],
["/dualcontrol/props/fuel-pressure", "/sim/multiplay/generic/float[9]"],
["/dualcontrol/props/fuel-press", "/sim/multiplay/generic/float[10]"],
["/dualcontrol/props/flaps", "/sim/multiplay/generic/float[11]"],
["/dualcontrol/props/engine-starter", "/sim/multiplay/generic/int[7]"],
["/dualcontrol/props/carb-choke", "/sim/multiplay/generic/int[8]"],
["/dualcontrol/props/carb-heat", "/sim/multiplay/generic/int[9]"],
["/dualcontrol/props/mag0", "/sim/multiplay/generic/int[10]"],
["/dualcontrol/props/mag1", "/sim/multiplay/generic/int[11]"],
["/dualcontrol/props/fuel-pump", "/sim/multiplay/generic/int[12]"],
["/dualcontrol/props/avionics", "/sim/multiplay/generic/int[13]"],
["/dualcontrol/props/landing", "/sim/multiplay/generic/int[14]"],
["/dualcontrol/props/strobe", "/sim/multiplay/generic/int[15]"]
];

var transmit_props = [
"/dualcontrol/transmit/engine-starter",
"/dualcontrol/transmit/master",
"/dualcontrol/transmit/carb-choke",
"/dualcontrol/transmit/carb-heat",
"/dualcontrol/transmit/mag0",
"/dualcontrol/transmit/mag1",
"/dualcontrol/transmit/fuel-pump",
"/dualcontrol/transmit/avionics",
"/dualcontrol/transmit/landing",
"/dualcontrol/transmit/strobe",
"/dualcontrol/transmit/flaps"
];


var dual_ctrl = {
	init : func {
        me.UPDATE_INTERVAL = 0.01;
        me.loopid = 0;
        
        setprop("/dualcontrol/pilot", 0);
        setprop("/dualcontrol/active", 0);
        setprop("/dualcontrol/controls/throttle", 0);
        setprop("/dualcontrol/transmit/setting-inhg", 29.92);
        
        foreach(var prop; transmit_props) {
        	setprop(prop, 0);
        }
        
	#    for(var n=0; n<11; n+=1) {
    #    	setprop("/sim/multiplay/generic/int["~n~"]", 0);
    #    }
        
        foreach(var prop; transmit_props) {
        	setprop("/DCmodval"~prop, 0);
        }
        
        me.throttle = 0;
        me.reset();
        
        me.inhg = 29.92;
},
	update : func {
	
		if (getprop("/dualcontrol/active")) {
	
			var pilot = getprop("/dualcontrol/pilot");
			var mp_tree = "/ai/models/multiplayer["~pilot~"]";
			
			foreach(var prop; autoupdate_props) {
				setprop(prop, getprop(mp_tree~prop));
			}
			setprop("/orientation/heading-deg", getprop(mp_tree~"/orientation/true-heading-deg"));
			
			var throttle = getprop("/controls/engines/engine/throttle");
			
			if (throttle != me.throttle) {
				setprop("/dualcontrol/controls/throttle", throttle);
				me.throttle = throttle;
			}
			
			foreach(var prop; cockpit_props) {
				setprop(prop[0], getprop(mp_tree~prop[1]));
			}
			
		#	n=0;
		#	foreach(var prop; transmit_props) {
		#		var value = getprop(prop);
		#		var modval = getprop("/DCmodval"~prop);
		#		if (value != modval) {
		#			setprop("/sim/multiplay/generic/int["~n~"]", value);
		#			setprop("/DCmodval"~prop, value);
		#		}
		#		n+=1;
		#	}
			
			var inhg = getprop("/dualcontrol/transmit/setting-inhg");
			if (inhg != me.inhg) {
				setprop("/sim/multiplay/generic/float[4]", inhg);
				me.inhg = inhg;
			}
		
		}

},
	reset : func {
        me.loopid += 1;
        me._loop_(me.loopid);
    },
	_loop_ : func(id) {
        id == me.loopid or return;
        me.update();
        settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
    }

};

dual_ctrl.init();
print("Dual Control System .............. Initialized");
