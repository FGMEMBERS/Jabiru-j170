var ctrl_props = ["/controls/flight/aileron", "/controls/flight/elevator", "/controls/flight/rudder"];

var receive_props = [
["/dualcontrol/transmit/engine-starter", "/controls/engines/engine/starter"],
["/dualcontrol/transmit/master", "/switches/electric/master"],
["/dualcontrol/transmit/carb-choke", "/switches/carb-choke"],
["/dualcontrol/transmit/carb-heat", "/switches/carb-heat"],
["/dualcontrol/transmit/mag0", "/switches/magneto/master"],
["/dualcontrol/transmit/mag1", "/switches/magneto[1]/master"],
["/dualcontrol/transmit/fuel-pump", "/switches/fuel-pump"],
["/dualcontrol/transmit/avionics", "/switches/avionics"],
["/dualcontrol/transmit/landing", "/switches/landing"],
["/dualcontrol/transmit/strobe", "/switches/strobe"],
["/dualcontrol/transmit/flaps", "/controls/flight/flaps"]
];

var dual_ctrl = {
	init : func {
        me.UPDATE_INTERVAL = 0.01;
        me.loopid = 0;
        
        setprop("/dualcontrol/co-pilot", 0);
        setprop("/dualcontrol/active", 0);
        
        foreach(var prop; receive_props) {
        	setprop("/DCmodval"~prop[0], 0);
        }
        
        me.cpthrottle = 0;
        me.inhg = 0;
        me.reset();
},
	update : func {
	
	if (getprop("/dualcontrol/active")) {
	
		var copilot = getprop("/dualcontrol/co-pilot");
		var mp_tree = "/ai/models/multiplayer["~copilot~"]";
		
		for(var n=0; n<3; n+=1) {
			var myprop = ctrl_props[n];
			var mpprop = "/sim/multiplay/generic/float["~n~"]";
			if ((getprop(mp_tree~mpprop) < -0.02) or (getprop(mp_tree~mpprop) > 0.02)) { 
				setprop(myprop, getprop(mp_tree~mpprop));
			}
		}
		
		var cpthrottle = getprop(mp_tree~"/sim/multiplay/generic/float[3]");
		if (cpthrottle != me.cpthrottle) {
			setprop("/controls/engines/engine/throttle", cpthrottle);
			me.cpthrottle = cpthrottle;
		}
		
		for(var n=0; n<11; n+=1) {
			var value = getprop(mp_tree~"/sim/multiplay/generic/int["~n~"]");
			if (value > 1) {
				value = 1;
			}
			var modval = getprop("/DCmodval"~receive_props[n][0]);
			if (value != modval) {
				setprop(receive_props[n][1], value);
				setprop("/DCmodval"~receive_props[n][0], value);
			}
		}
		
		var inhg = getprop(mp_tree~"/sim/multiplay/generic/float[4]");
		if (inhg != me.inhg) {
			setprop("instrumentation/altimeter/setting-inhg", inhg);
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
