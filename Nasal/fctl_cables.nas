var surface = {
	surface_name : "",
	damping_coeff : 1,
	serviceable : 1,
	cable_input : 0,
	last_pos : 0,
	cable_damp : func {
			return (math.abs(me.cable_input - me.last_pos)) * me.damping_coeff;
	},
	surface_pos : func {
		return me.last_pos + ((me.cable_input - me.last_pos) * me.cable_damp());	
	},
	set_last : func {
	
		var pos = me.final_output();
		
		var airspeed = getprop("/velocities/airspeed-kt");
		
	
		if ((typeof(pos) == "scalar") and (math.abs(pos) <= 1))
			me.last_pos = me.surface_pos();
		else
			me.last_pos = me.cable_input * ((450 - airspeed) / 450);
	},
	final_output : func {
		# This small script is to calculate for the tension created by the airspeed
		var airspeed = getprop("/velocities/airspeed-kt");
		return me.surface_pos() * ((450 - airspeed) / 450);	
	},
	damage_cable : func {
		me.serviceable = 0;
	}
};

var fctl_cables = {
	init : func {
        me.UPDATE_INTERVAL = 0.01;
        me.loopid = 0;
        
        me.fctl_tree = "/fdm/jsbsim/fcs/";
        me.fctl_out = "-pos-output";
        me.fctl_in = "/controls/flight/";
        
        # Initialize JSBSim FCTL Properties
        
        setprop(me.fctl_tree~ "aileron" ~me.fctl_out, 0);
        setprop(me.fctl_tree~ "elevator" ~me.fctl_out, 0);
        setprop(me.fctl_tree~ "rudder" ~me.fctl_out, 0);
        
        # Initialize Surface control hashes

		me.surface_vect = [new(surface), new(surface), new(surface)];
		
		me.surface_vect[0].surface_name = "aileron";
		me.surface_vect[1].surface_name = "elevator";
		me.surface_vect[2].surface_name = "rudder";
		
		me.surface_vect[0].damping_coeff = 0.26;
		me.surface_vect[1].damping_coeff = 0.62;
		me.surface_vect[2].damping_coeff = 0.54;
        
        me.reset();
},
	update : func {
	
		var airspeed = getprop("/velocities/airspeed-kt");

		foreach(var ctl_surface; me.surface_vect) {
			
			if (ctl_surface.serviceable == 1) {
			
				ctl_surface.cable_input = getprop(me.fctl_in ~ ctl_surface.surface_name);
				
				var output = ctl_surface.final_output();
				
				if((typeof(output) == "scalar") and (math.abs(output) <= 1))
					setprop(me.fctl_tree ~ ctl_surface.surface_name ~ me.fctl_out, output);
				else
					ctl_surface.cable_input * ((450 - airspeed) / 450);
					
				# There seems to be some sort of error with the cable damp calculation, so the else here is to still be abe to control the plane (but without cable damping, as it faulted) in case of an error.
				
				ctl_surface.set_last();
			
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

fctl_cables.init();
print("Flight Control System ............ Initialized");
