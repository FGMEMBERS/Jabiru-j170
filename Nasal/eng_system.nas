# This engine systems nasal file includes basic engine control, fuel control, 2 magnetos and a carburator

var jab2200 = {
	init : func {
        me.UPDATE_INTERVAL = 0.1;
        me.loopid = 0;
        
       	# Electrical Properties
       	
		setprop("/engine/model", "Jabiru 2200 85HP"); # lol
		
		setprop("/engine/carb-temp", getprop("/environment/temperature-degc"));
		
		setprop("/engines/engine/fuel-pressure", 0);
		
		# The rest are initialized in the -set.xml
        
        me.reset();
	},
	update : func {
	
	var master = getprop("/switches/electric/master");
	
	# Magnetos convert from 2 masters to FG's Off/L/R/Both Mode

	var mag1 = getprop("/switches/magneto/master");
	var mag2 = getprop("/switches/magneto[1]/master");
	var mag = "/controls/engines/engine/magnetos";
	
	if ((mag1 != 1) and (mag2 != 1)) {
		setprop(mag, 0);
	} elsif ((mag1 == 1) and (mag2 != 1)) {
		setprop(mag, 1);
	} elsif ((mag1 != 1) and (mag2 == 1)) {
		setprop(mag, 2);
	} else
		setprop(mag, 3);
	
		# GRR, JSBSim doesn't let me play with too many engine props...	so I'm using JSBSim for the Engines... Atleast for now.
		
		# Carburator Temp and Choke
		
		var temp_prop = "/environment/temperature-degc";
		var carb_temp = "/engine/carb-temp";
		var carb_heat = getprop("/switches/carb-heat");
		var carb_choke = getprop("/switches/carb-choke");
		
		# Unless Carb heat is turned on, bring carb temp to outside temp
		
		if (getprop(temp_prop) > getprop(carb_temp))
			setprop(carb_temp, getprop(carb_temp) + 0.01);
		elsif (getprop(temp_prop) < getprop(carb_temp))
			setprop(carb_temp, getprop(carb_temp) - 0.01);
			
		# Carburator Heat
		
		if (carb_heat and master and (getprop(carb_temp) < 35))
			setprop(carb_temp, getprop(carb_temp) + 0.1);
			
		var efficiency = 1;
			
		# Reduce Engine Efficiency if carburator temperature is low
		
		if (getprop(carb_temp) <= -10)
			efficiency = 1 - (math.abs(getprop(carb_temp) + 10) * 0.0125);
			
		
		# Carburator Choke
		
		if ((getprop(temp_prop) <= 0) and (carb_choke != 1))
			efficiency -= math.abs(getprop(temp_prop)) / 143.64;
		elsif ((getprop(temp_prop) > 0) and (carb_choke == 1))
			efficiency = efficiency / 2;
		
		# Else, it doesn't affect efficiency :)
		
		setprop("/engines/engine/efficiency", efficiency);	
		
		# Fuel Pressure
		
		var pressure = getprop("/engines/engine/fuel-pressure");
		var rpm = getprop("/engines/engine/rpm");
		
		if ((rpm > 200) and (pressure < 1))
			setprop("/engines/engine/fuel-pressure", pressure + (rpm / 33000));
		elsif ((rpm <= 200) and (rpm > 0) and (pressure > 0.16))
			setprop("/engines/engine/fuel-pressure", (pressure - 0.02));
		elsif ((rpm == 0) and (pressure > 0))
			setprop("/engines/engine/fuel-pressure", (pressure - 0.1));
			
		if (getprop("/switches/fuel-pump") and master)
			setprop("/controls/engines/engine/fuel-pump", 1);
		else
			setprop("/controls/engines/engine/fuel-pump", 0);

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
	jab2200.init();
	print("Jabiru 2200 Engine ............... Initialized");
} );
