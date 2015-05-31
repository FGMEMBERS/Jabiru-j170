var alternator = {

	volt : 28,
	max_amp : 70,
	rpm_prop : "/engines/engine/rpm",
	min_rpm : 400,
	max_rpm : 3300,
	serviceable : 1,
	supplying : func {
		if (getprop(me.rpm_prop) > me.min_rpm)
			return 1;
		else
			return 0;
	},
	sup_amp : func {
		return (getprop(me.rpm_prop) / (me.max_rpm - me.min_rpm)) * me.max_amp;	
	}

};

var battery = {

	volt : 28,
	max_amp : 35,
	charge_norm : 0.75,
	charge_rate : 0.000277778,
	drain_rate : 0.000092593,
	serviceable : 1,
	sup_amp : func {
		if (me.charge_norm > 0.3)
			return me.max_amp;
		else
			return me.max_amp * (me.charge_norm + 0.7);
	},
	# This should only be used every second to make sure that the charge and drain rates apply properly.
	charge : func {
		if (me.charge_norm < 1)
			me.charge_norm += me.charge_rate;
	},
	drain : func {
		if (me.charge_norm > 0)
			me.charge_norm -= me.drain_rate;
	}

};

var electric_bus = {

	volt : func {
	
		var voltage = 0;
	
		if (getprop("/switches/electric/master") and (battery.serviceable) and (battery.charge_norm >= 0.05))
			voltage += 28;
			
		if (getprop("/switches/electric/master") and (alternator.serviceable) and (alternator.supplying()))
			voltage += 28;

		return voltage;
			
	},
	
	amps : func {
	
		var ampere = 0;
		
		if (getprop("/switches/electric/master") and (battery.serviceable) and (battery.charge_norm >= 0.05))
			ampere += battery.sup_amp();
		
		if (getprop("/switches/electric/master") and (alternator.serviceable) and (alternator.supplying()))
			ampere += alternator.sup_amp();
				
		return ampere;
		
	},
	
	pwr : func {
	
		return me.volt() * me.amps();
	
	}
	
};

var output = {

	name : "",
	power_rating : 0,
	servicable : 1,
	breaker : func {
		return "/switches/circuit-breakers/" ~ me.name;
	},
	out_prop : func {
		return "/systems/electric/output/" ~ me.name;
	},
	switch : func {
		return "/switches/" ~ me.name;
	}

};

var electric = {
	init : func {
        me.UPDATE_INTERVAL = 1;
        me.loopid = 0;
        
       	# Electrical Property Trees
       	
       	me.elec_tree = "/systems/electric/";
       	me.sw_tree = "/switches/electric/";

       	# Initialize Electrical Devices
       	
       	me.outputs = [new(output), new(output), new(output), new(output), new(output)];
       	
       	me.outputs[0].name = "avionics";
       	me.outputs[0].power_rating = 48;
       	me.outputs[0].serviceable = 0;
       	
       	me.outputs[1].name = "strobe";
       	me.outputs[1].power_rating = 24;
       	me.outputs[1].serviceable = 0;
       	
       	me.outputs[2].name = "landing";
       	me.outputs[2].power_rating = 72;
       	me.outputs[2].serviceable = 0;
       	
       	me.outputs[3].name = "fuel-pump";
       	me.outputs[3].power_rating = 384;
       	me.outputs[3].serviceable = 0;
       	
       	me.outputs[4].name = "elec-flaps";
       	me.outputs[4].power_rating = 360; 
       	me.outputs[4].serviceable = 0;    	
        
        me.reset();
	},
	update : func {
	
	var master = getprop(me.sw_tree~ "master");
	
	# electric_bus Functions to Property
	
	if (electric_bus.volt() != nil)
		setprop(me.elec_tree~ "electric_bus-volt", electric_bus.volt());
		
	if (electric_bus.amps() != nil)
		setprop(me.elec_tree~ "electric_bus-amps", electric_bus.amps());
		
	if (electric_bus.pwr() != nil)
		setprop(me.elec_tree~ "electric_bus-power", electric_bus.pwr());
	
	# Charge Battery
	
	if (master and alternator.serviceable and alternator.supplying() and (getprop("/engines/engine/rpm") > 750))
		battery.charge();
		
	# Drain Battery	
	
	if (master)
		battery.drain();
	
	# Power Consumption
	
	var total_avail_power = electric_bus.pwr();
	
	if (master) {
	
		foreach(var device; me.outputs) {
	
			if ((getprop(device.breaker) != 1) and (getprop(device.switch) != 0) and (total_avail_power > device.power_rating)) {
			
				device.serviceable = 1;
				
				setprop("/systems/electric/devices/" ~ device.name ~ "/serviceable", 1);
				
				total_avail_power -= device.power_rating;
			
			} else {
			
				device.serviceable = 0;
				setprop("/systems/electric/devices/" ~ device.name ~ "/serviceable", 0);
				
			}
	
		}
	
	} else {
	
		foreach(var device; me.outputs) {
			setprop("/systems/electric/devices/" ~ device.name ~ "/serviceable", 0);
			device.serviceable = 0;
		}
	
	}
	
	setprop(me.elec_tree~ "power_remain", total_avail_power);
	
	# Fuel Pump
	
	var pump = getprop("/switches/fuel-pump");
	var pump_cb = getprop("/switches/circuit-breakers/fuel-pump");
	
	if ((pump == 1) and (pump_cb != 1))
		setprop("/sim/failure-manager/engines/engine/serviceable", 1);
	else
		setprop("/sim/failure-manager/engines/engine/serviceable", 0);
		
	# Electric Flaps
	
	var flaps_cb = getprop("/switches/circuit-breakers/elec-flaps");
	
	if (flaps_cb != 1)
		setprop("/sim/failure-manager/controls/flight/flaps/serviceable", 1);
	else
		setprop("/sim/failure-manager/controls/flight/flaps/serviceable", 0);
		
	# Battery Charge
	
	setprop("/systems/electric/battery-charge", battery.charge_norm);

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
	electric.init();
	print("Electrical System ................ Initialized");
} );
