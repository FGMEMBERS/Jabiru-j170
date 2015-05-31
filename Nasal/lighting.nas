var lights = {
	init : func {
        me.UPDATE_INTERVAL = 0.05;
        me.loopid = 0;
		
		setprop("/lighting/cockpit/fuel-pressure", 0);
		setprop("/lighting/cockpit/charge", 0);
		
		setprop("/lighting/landing", 0);
		setprop("/lighting/strobe", 0);
		setprop("/lighting/strobe-state", 0);
		
		me.time = 0;
        
        me.reset();
	},
	update : func {
	
		# Landing Lights
		
		if (electric.outputs[2].serviceable and getprop("/switches/landing") and (getprop("/switches/circuit-breakers/landing") != 1))
			setprop("/lighting/landing", 1);
		else
			setprop("/lighting/landing", 0);
			
		# Strobe Light
		
		if (electric.outputs[1].serviceable and getprop("/switches/strobe") and (getprop("/switches/circuit-breakers/strobe") != 1))
			setprop("/lighting/strobe", 1);
		else
			setprop("/lighting/strobe", 0);
			
		# Cockpit Indicators
		
		if (getprop("/switches/electric/master") and (getprop("/systems/electric/battery-charge") > 0.1))
			setprop("/lighting/cockpit/charge", 1);
		else
			setprop("/lighting/cockpit/charge", 0);
			
		if (getprop("/switches/electric/master") and (getprop("/engines/engine/fuel-pressure") != 0))
			setprop("/lighting/cockpit/fuel-pressure", 1);
		else
			setprop("/lighting/cockpit/fuel-pressure", 0);
			
		# Strobe Lighting Flash
		
		if (getprop("/lighting/strobe")) {
		
		if (me.time == 1)
			setprop("/lighting/strobe-state", 1);
			
		if (me.time == 2)
			setprop("/lighting/strobe-state", 0);
			
		if (me.time == 5)
			setprop("/lighting/strobe-state", 1);
			
		if (me.time == 6)
			setprop("/lighting/strobe-state", 0);
		
		me.timer();
		
		} else
			me.time = 0;

	},
	timer : func {
		me.time += 1;
		
		if (me.time == 20)
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
	lights.init();
} );
