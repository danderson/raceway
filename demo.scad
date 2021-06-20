$fa=1;
$fs=0.4;

use <raceway.scad>;

module r(length, width, height) {
  rotate([90, 0, 0]) raceway(length=length,
							 width=width,
							 height=height,
							 finger_length=8,
							 slot_length=4,
							 keyhole_diameter=7,
							 thickness=2,
							 screw_slot_width=3);
}

module c(length, width) {
  color("blue")
	translate([width, 0, 8])
	rotate([-90, 0, 180])
	lid(length=length, width=width, thickness=2);
}

module t(length, width) {
  color("orange")
	translate([length/2 - width/2, -length, 0])
	tee_joint(width=width,
			  length=length,
			  hole_size=4.6,
			  thickness=4);
}

module l(length, width) {
  color("orange")
	translate([0, -length, 0])
	ell_joint(width=width,
			  length=length,
			  hole_size=4.6,
			  thickness=4);
}

module b(length, width) {
  color("orange")
	translate([width, 0, 0])
	rotate([0, 0, 180])
	butt_joint(width=width,
			   length=length,
			   hole_size=4.6,
			   thickness=4);
}

module at(x, y) {
  translate([x, -y, 0]) children();
}

at(0, 0) r(150, 50, 30);
at(60, 0) c(150, 50);

at(120, 0) r(100, 20, 40);
at(150, 0) c(100, 20);

at(0, 160) t(width=10, length=40);
at(50, 160) l(width=10, length=40);
at(100, 160) b(width=10, length=40);
