var RAD2DEG = 57.2957795;
var DEG2RAD = 0.016774532925;

var gps_terrain = {
	init : func {
        me.UPDATE_INTERVAL = 0.05;
        me.loopid = 0;

		# Initialize Properties
		
		setprop("aera500-GPS/range", 10);
		
		me.time = 0;
        
        me.reset();
	},
	update : func {
	
		# Run only when you have power in avionics
		
		if (getprop("/dualcontrol/props/serviceable/avionics") or getprop("/systems/electric/devices/avionics/serviceable")) {
		
			var altitude = getprop("/position/altitude-ft");
		
			var gps_range = getprop("aera500-GPS/range");
		
			var gps_page = getprop("aera500-GPS/page");
			
			var heading = getprop("/orientation/heading-deg");
			
			var pos_lat = getprop("/position/latitude-deg");
			
			var pos_lon = getprop("/position/longitude-deg");
		
			if ((gps_page == "Map") or (gps_page == "Terrain")) {
			
			var distance = 0;
			
				if (gps_page == "Map")
					distance = (gps_range / 1860) * me.time;
				else
					distance = (gps_range / 1260) * me.time;
 			
				for (var col = 1; col <= 41; col += 2) {
				
					var x_offset = (1 / 60) * (gps_range / 20.5) * (col - 20.5);
					
					var proj_lat = pos_lat + (x_offset * math.sin(heading * DEG2RAD));
					
					var proj_lon = pos_lon + (x_offset * math.cos(heading * DEG2RAD));
					
					var point_lat = proj_lat + (distance * math.cos(heading * DEG2RAD));
					
					var point_lon = proj_lon + (distance * math.sin(heading * DEG2RAD));
					
					var elevation = get_elevation(point_lat, point_lon);
					
					setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/elevation-ft", elevation);
					
					var alt_diff = altitude - elevation;
					
					if (alt_diff < 0)
						setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/altitude-difference", 0);
					
					if ((elevation > 5) and (alt_diff < 2500) and (alt_diff > 0))
						setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/altitude-difference", alt_diff);
						
					if (alt_diff >= 2500)
						setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/altitude-difference", 2500);
						
					if (elevation <= 5)
						setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/altitude-difference", 3000);
				
				}
				
				for (var col = 2; col <= 40; col += 2) {
				
					var elev_prev = getprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ (col - 1) ~ "]/elevation-ft");
					
					var elev_next = getprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ (col + 1) ~ "]/elevation-ft");
					
					setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/elevation-ft", (elev_prev + elev_next) / 2);
					
					var elevation = (elev_prev + elev_next) / 2;
					
					var alt_diff = altitude - elevation;
					
					if (alt_diff < 0)
						setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/altitude-difference", 0);
						
					if ((elevation > 5) and (alt_diff < 2500) and (alt_diff > 0))
						setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/altitude-difference", alt_diff);
						
					if (alt_diff >= 2500)
						setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/altitude-difference", 2500);
						
					if (elevation <= 5)
						setprop("aera500-GPS/map/terrain/row[" ~ me.time ~ "]/col[" ~ col ~ "]/altitude-difference", 3000);
				
				}
				
				if (gps_page == "Map")				
					me.timer(31);
				else
					me.timer(21);
			
			}
		
		}

	},
	timer : func(reset_time) {
		me.time += 1;
		
		if (me.time >= (reset_time + 1)) {
			me.time = 0;
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

# Function to get Elevation at latitude and longitude

var get_elevation = func (lat, lon) {

var info = geodinfo(lat, lon);
   if (info != nil) {var elevation = info[0] * 3.2808399;}
   else {var elevation = -1.0; }

return elevation;
}

setlistener("sim/signals/fdm-initialized", func {
	gps_terrain.init();
	print("GPS Terrain Database ............. Initialized");
} );
