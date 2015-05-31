var ga500_loop = {
	init : func {
        me.UPDATE_INTERVAL = 0.05;
        me.loopid = 0;

		# Initialize Properties
		
		setprop("aera500-GPS/page", "Intro");
		
		setprop("aera500-GPS/numbers/top-left", "empty");
		setprop("aera500-GPS/numbers/top-right", "empty");
		setprop("aera500-GPS/numbers/bottom-left", "gs");
		setprop("aera500-GPS/numbers/bottom-right", "hdg");
		
		me.time = 0;
        
        me.reset();
	},
	update : func {
	
		# Run only when you have power in avionics
		
		if (getprop("/dualcontrol/props/serviceable/avionics") or getprop("/systems/electric/devices/avionics/serviceable")) {
		
			setprop("aera500-GPS/numbers/gs-int", int(getprop("/velocities/groundspeed-kt")));

		}
		
	},
	timer : func {
		me.time += 1;
		
		if (me.time == 32)
			me.time = 0;
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
	ga500_loop.init();
	print("Garmin Aera 500 GPS .............. Initialized");
} );
