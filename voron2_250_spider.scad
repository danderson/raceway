$fa=1;
$fs=0.4;

use <libtray.scad>;

module r(length, width, height) {
  rotate([90, 0, 0]) raceway(length=length,
                             width=width,
                             height=height,
                             tongue_length=8,
                             slot_length=4,
                             keyhole_diameter=7,
                             thickness=2,
                             screw_slot_width=3);
}

module c(length, width) {
  translate([width, 0, 8]) rotate([-90, 0, 180]) lid(length=length, width=width, thickness=2);
}

module t(length, width) {
  translate([length/2 - width/2, -length, 0])
    tee_joint(width=width,
              length=length,
              hole_size=4.6,
              thickness=4);
}

module l(length, width) {
  translate([0, -length, 0])
    ell_joint(width=width,
              length=length,
              hole_size=4.6,
              thickness=4);
}

module at(x, y) {
  translate([x, -y, 0]) children();
}

r(260, 20, 30);
at(30, 0) c(130, 20);
at(30, 140) c(130, 20);

at(60, 0) r(220, 20, 30);
at(90, 0) c(220, 20);

at(120, 0) r(100, 20, 30);
at(150, 0) c(100, 20);

color("orange") at(120, 110) t(width=10, length=40);
color("orange") at(120, 160) l(width=10, length=40);
