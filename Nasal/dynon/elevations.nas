var elevations = {
	init : func {
        me.UPDATE_INTERVAL = 0.05;
        me.loopid = 0;
		
		me.time = 0;
        
        me.reset();
	},
	update : func {
	
		# Run only when you have power in avionics
		
		if (jabiru.electric.outputs[0].serviceable) {
		
			# Atm, the Garmin Aera500 GPS already gets terrain using geodinfo (this causes a slight fps loss) so I won't  be doing this again. Atleast for now, I'm jusing going to convert the GPS terrain data to the PFD terrain data
			
			for (var row = 1; row < 41; row += 1)
			
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
	elevations.init();
	print("Dynon SkyView Database ........... Initialized");
} );
