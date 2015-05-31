var location = "/temp/test/";
var filename = getprop("/sim/fg-home") ~ "/Export/ga500-map.xml";

var create_animation = func() {

	for (var row = 1; row <= 31; row += 1)
	{

		for (var col = 1; col <= 41; col += 1)
		{
		
			var animation = ((row - 1) * 41) + (col - 1);

			setprop(location ~ "animation[" ~ animation ~ "]/type", "textranslate");
			setprop(location~"animation[" ~ animation ~ "]/object-name", "map_point." ~ row ~ "." ~ col);
			setprop(location~"animation[" ~ animation ~ "]/property", "aera500-GPS/map/terrain/row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft");
			setprop(location ~ "animation[" ~ animation ~ "]/factor", 0.000057917);
			setprop(location ~ "animation[" ~ animation ~ "]/axis/y", 1);

		}

	}    

	io.write_properties(filename, location);

}
