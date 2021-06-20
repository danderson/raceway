$fa=1;
$fs=0.4;

module tongue(height=15,
			  length=4,
			  thickness=1.2,
			  foot_angle=20,
			  foot_height=5) {
  // The following math only works correctly for 45-degree angles, if
  // you change it you're on your own.
  angle = 45;
  // When going around the angle, we want the diagonal piece to stay
  // at the desired thickness. Do do that, the two sides of the piece
  // need to start the diagonal at different points, offset by this
  // amount.
  angle_offset = thickness - (cos(angle) * thickness);
  foot_width = tan(foot_angle) * foot_height;

  h = height;
  t = thickness;
  oh = angle_offset;
  fw = foot_width;
  fh = foot_height;

  points = [[0, 0],
			[0, h-4*t],
			[2*t, h-2*t],
			[t, h-t],
			[t, h-t+oh],
			[2*t-oh, h],
			[3*t, h-t-oh],
			[3*t, h-3*t+oh],
			[t, h-4*t-t+oh],
			[t, fh],
			[t+fw, 0],
			[t, 0],
			];
  render(convexity=10) linear_extrude(height=length) polygon(points);
}

module tongue_and_slot(height=10,
					   length=6,
					   slot_length=2,
					   thickness=1.2,
					   keyhole_diameter=3) {
  tongue_length = length - slot_length;
  half_tongue = tongue_length/2;
  keyhole_radius = keyhole_diameter/2;
  keyhole_center_height = thickness+keyhole_radius;
  keyhole_center_length = half_tongue+(slot_length/2);

  difference() {
	union() {
	  tongue(height=height,
			 length=half_tongue,
			 thickness=thickness,
			 foot_height=keyhole_diameter);
	  translate([0,0, half_tongue+slot_length])
		tongue(height=height,
			   length=half_tongue,
			   thickness=thickness,
			   foot_height=keyhole_diameter);
	}
	translate([-0.001, keyhole_center_height, keyhole_center_length])
	  rotate([0,90,0])
	  cylinder(r=keyhole_radius, h=thickness+keyhole_diameter+0.002);
  }
}

module raceway_side(height=10,
					length=200,
					tongue_length=4,
					slot_length=2,
					thickness=1.2,
					keyhole_diameter=3) {
  tongue_and_slot_length = tongue_length + slot_length;
  module_length = length - tongue_length; // One unmodified half tongue on either end.
  tongue_and_slot_count = floor(module_length / tongue_and_slot_length);
  module_real_length = tongue_and_slot_count * tongue_and_slot_length;
  removed_length = module_length - module_real_length;
  endcap_length = (tongue_length+removed_length)/2;

  tongue(height=height,
		 length=endcap_length,
		 thickness=thickness,
		 foot_height=keyhole_diameter);
  for(off = [endcap_length: tongue_and_slot_length: module_real_length+endcap_length-0.001])
	translate([0,0,off])
	tongue_and_slot(height=height,
					length=tongue_and_slot_length,
					slot_length=slot_length,
					thickness=thickness,
					keyhole_diameter=keyhole_diameter);
  translate([0,0, module_real_length + endcap_length])
	tongue(height=height,
		   length=endcap_length,
		   thickness=thickness,
		   foot_height=keyhole_diameter);
}

module mirrored_sides(width=20) {
  translate([-width/2,0,0]) children();
  translate([width/2,0,0]) mirror([1,0,0]) children();
}

module raceway_bottom(width=20,
					  length=100,
					  thickness=1.2,
					  screw_slot_width=3) {
  render(convexity=10)
  difference() {
	translate([-width/2, 0, 0]) cube([width, thickness, length]);
	translate([-screw_slot_width/2,-0.001,thickness])
	  cube([screw_slot_width, thickness+0.002, length-(2*thickness)]);
  };
}

module raceway(height=20,
			   width=20,
			   length=200,
			   thickness=1.2,
			   tongue_length=4,
			   slot_length=2,
			   keyhole_diameter=3,
			   screw_slot_width=3) {
  translate([width/2,0,0]) union() {
	mirrored_sides(width=width) {
	  raceway_side(height=height,
				   length=length,
				   tongue_length=tongue_length,
				   slot_length=slot_length,
				   thickness=thickness,
				   keyhole_diameter=keyhole_diameter);
	}
	raceway_bottom(width=width,
				   length=length,
				   thickness=thickness,
				   screw_slot_width=screw_slot_width);
  };
}

module lid(width=20,
		   length=40,
		   thickness=1.2) {
  module halflid() {
	t = thickness;
	points = [[t,0],
			  [2*t, t],
			  [t, 2*t],
			  [t, 3*t],
			  [width/2+0.002, 3*t],
			  [width/2+0.002, 4*t],
			  [0, 4*t],
			  [0, 0],
			  ];
	color("blue") render(convexity=10) linear_extrude(height=length) polygon(points);
  };

  translate([width/2, 0, 0]) union() {
	translate([-width/2, 0, 0]) halflid();
	mirror([1,0,0]) translate([-width/2, 0, 0]) halflid();
  };
}

module butt_joint(width=20,
				  length=40,
				  hole_size=4.6,
				  thickness=2) {
  sep = length/4;
  margin = sep/2;

  render(convexity=10) difference() {
	cube([width, length, thickness]);
	for (y = [margin: sep: length])
	  translate([width/2, y, -0.001])
		cylinder(r=hole_size/2, h=thickness+0.002);
  }
}

module tee_joint(width=20,
				 length=40,
				 hole_size=4.6,
				 thickness=2) {
  sep = length/3;
  margin = sep/2;

  render(convexity=10) union() {
	difference() {
	  cube([width, length, thickness]);
	  translate([width/2, margin, -0.001]) cylinder(r=hole_size/2, h=thickness+0.002);
	  translate([width/2, margin+sep, -0.001]) cylinder(r=hole_size/2, h=thickness+0.002);
	};

	translate([length/2 + width/2, length - width, 0])
	rotate([0,0,90])
	difference() {
	  cube([width, length, thickness]);
	  translate([width/2, margin, -0.001]) cylinder(r=hole_size/2, h=thickness+0.002);
	  translate([width/2, margin+sep+sep, -0.001]) cylinder(r=hole_size/2, h=thickness+0.002);
	}
  };
}

module ell_joint(width=20,
				 length=40,
				 hole_size=4.6,
				 thickness=2) {
  sep = length/3;
  margin = sep/2;

  module arm() {
	render(convexity=10) difference() {
	  cube([width, length, thickness]);
	  translate([width/2, margin, -0.001]) cylinder(r=hole_size/2, h=thickness+0.002);
	  translate([width/2, margin+sep, -0.001]) cylinder(r=hole_size/2, h=thickness+0.002);
	};
  };

  union() {
	arm();
	translate([length, length-width, 0]) rotate([0,0,90]) arm();
  };
}
