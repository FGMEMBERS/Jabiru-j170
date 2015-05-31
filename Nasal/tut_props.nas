#	Set some special tutorial properties
var tut_props = {
	init: func{
		me.UPDATE_INTERVAL = 0.001; 
        me.loopid = 0;
		# Initialize state variables
		me.max_alt = 0;
		me.min_alt = 0;
		me.landing_rate = 0;
		
		me.reset();
	},
	update: func{
		var alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
		
		if (me.max_alt < alt){
			me.max_alt = alt;
			setprop("/tutorial-props/max-altitude", me.max_alt);
			me.min_alt = me.max_alt - 100;
			setprop("/tutorial-props/min-altitude", me.min_alt);
		}
		
		var agl = getprop("/position/altitude-agl-ft");
		var vs = getprop("velocities/vertical-speed-fps");
		var rollspeed1 = getprop("/gear/gear[1]/rollspeed-ms");
		var rollspeed2 = getprop("/gear/gear[2]/rollspeed-ms");
		if ((rollspeed1 == 0) and (rollspeed2 == 0) and (vs < 0) and (agl < 1000)){
			me.landing_rate = vs;
			setprop("/tutorial-props/landing-rate", me.landing_rate);
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

setlistener("sim/signals/fdm-initialized", func {
	tut_props.init();
	print("J-170 Tutorial Properties ........ Initialized");
} );
