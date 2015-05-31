var ga500_vsd = {
	init : func {
        me.UPDATE_INTERVAL = 0.05;
        me.loopid = 0;
        
        me.reset();
        
        me.time = 1;
	},
	update : func {
	
		# Run only when you have power in avionics
		
		if ((getprop("/systems/electric/devices/avionics/serviceable") or getprop("/dualcontrol/props/serviceable/avionics")) and (getprop("aera500-GPS/page") == "Terrain")) {
		
			var range = getprop("aera500-GPS/range");
		
			var pos_lat = getprop("/position/latitude-deg");
			
			var pos_lon = getprop("/position/longitude-deg");
			
			var distance_deg = ((me.time / 35) * range) / 60;
			
			var heading = getprop("/orientation/heading-deg");
			
			var altitude = getprop("/position/altitude-ft");
			
			var point_lat = pos_lat + (distance_deg * math.cos(DEG2RAD * heading));
			
			var point_lon = pos_lon + (distance_deg * math.sin(DEG2RAD * heading));
		
			var elevation = get_elevation(point_lat, point_lon);
			
			var point_tree = "aera500-GPS/vsd/point[" ~ me.time ~ "]/";
			
			setprop(point_tree~ "elevation-ft", elevation);
			
			var red_limit = altitude - 100;
			
			var yellow_limit = altitude - 1000;
			
			if (elevation > red_limit) {
				setprop(point_tree~ "danger", "red");
				
				setprop(point_tree~ "red-height", elevation - red_limit);
				setprop(point_tree~ "yellow-height", 1000);
				setprop(point_tree~ "green-height", elevation - (1000 + (elevation - red_limit)));
				
			} elsif (elevation > yellow_limit) {
				setprop(point_tree~ "danger", "yellow");
				
				setprop(point_tree~ "red-height", 0);
				setprop(point_tree~ "yellow-height", elevation - yellow_limit);
				setprop(point_tree~ "green-height", elevation - (elevation - red_limit));	
				
			} else {
				setprop(point_tree~ "danger", "green");
				
				setprop(point_tree~ "red-height", 0);
				setprop(point_tree~ "yellow-height", 0);
				setprop(point_tree~ "green-height", elevation);
				
			}
			
			# Now, the whole thing has to be scaled to be able to show only 400 ft in a section. If the aircraft is under 2000 ft, the sprite moves freely in the lower half of the Vertical Profile. From 2000 and up, it stays in the center and the scale will change instead. And this makes it kinda complicated for me to have multiple colors on it. >.<
			
			
			
				
			me.timer();	
		
		} else
			me.time = 0;
		
	},
	timer : func {
		me.time += 1;
		if (me.time == 36)
			me.time = 1;
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
	ga500_vsd.init();
} );
