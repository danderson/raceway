// This is a library to create parametric cable raceways. It's mainly
// designed for the electronics enclosure of Voron printers.

// Finger generates an extruded raceway "finger", with a profile that
// includes a lid clip at the top and optionally an angled "foot" that
// extends into the inside of the raceway, to reinforce the bottom of
// the finger (useful when weakening the finger with e.g. drilled out
// keyholes).
module finger(height=15,
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
  //
  // Formulas obtained by drawing out the profile on paper and doing
  // trigonometry.
  angle_offset = thickness - (cos(angle) * thickness);
  foot_width = tan(foot_angle) * foot_height;

  // Shorthands for variables above, so that the polygon is easier to
  // read.
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

// finger_and_slot generates a raceway slot, with a half-finger on
// either side of it. It's designed to be tileable by other functions
// to generate longer raceways.
//
// Optionally, the slot can have a keyhole cutout at the bottom, to
// help the cables exit more cleanly. Set keyhole_diameter lower than
// slot_length to remove the keyhole.
module finger_and_slot(height=10,
                       finger_length=6,
                       slot_length=2,
                       thickness=1.2,
                       keyhole_diameter=3) {
  half_finger = finger_length/2;
  keyhole_radius = keyhole_diameter/2;
  keyhole_center_height = thickness+keyhole_radius;
  keyhole_center_length = half_finger+(slot_length/2);

  difference() {
    // Two half-fingers around the slot gap...
    union() {
      finger(height=height,
             length=half_finger,
             thickness=thickness,
             foot_height=keyhole_diameter);
      translate([0,0, half_finger+slot_length])
        finger(height=height,
               length=half_finger,
               thickness=thickness,
               foot_height=keyhole_diameter);
    }
    // With the keyhole punched out.
    translate([-0.001, keyhole_center_height, keyhole_center_length])
      rotate([0,90,0])
      cylinder(r=keyhole_radius, h=thickness+keyhole_diameter+0.002);
  }
}

// raceway_side generates one complete side of a raceway, with
// equally-sized slots all the way down.
//
// To accommodate lengths that don't divide exactly into the
// slot+finger dimensions, the fingers on either end of the raceway
// might be a little larger than specified, to take up the unused
// slack.
module raceway_side(height=10,
                    length=200,
                    finger_length=4,
                    slot_length=2,
                    thickness=1.2,
                    keyhole_diameter=3) {
  // The length of one "module" of finger + slot (in reality slot + 2 half-fingers).
  finger_and_slot_length = finger_length + slot_length;
  // The final half-finger on either end isn't drilled out or
  // connected to a slot, so we'll generate those separately. Remove
  // one finger from the overall length.
  modules_length = length - finger_length;
  // How many modules fit in the available space?
  finger_and_slot_count = floor(modules_length / finger_and_slot_length);
  // We had to round down, so we might have lost some length.
  modules_real_length = finger_and_slot_count * finger_and_slot_length;
  removed_length = modules_length - modules_real_length;
  // The "end caps" consist of an undrilled half-finger, plus half of
  // the "leftover" length.
  endcap_length = (finger_length+removed_length)/2;

  // First half-finger at the start of the raceway.
  finger(height=height,
         length=endcap_length,
         thickness=thickness,
         foot_height=keyhole_diameter);
  // A bunch of half-finger + slot modules for the bulk of the raceway.
  for(off = [endcap_length: finger_and_slot_length: modules_real_length+endcap_length-0.001])
    translate([0,0,off])
    finger_and_slot(height=height,
                    finger_length=finger_length,
                    slot_length=slot_length,
                    thickness=thickness,
                    keyhole_diameter=keyhole_diameter);
  // Final half-finger to finish off.
  translate([0,0, modules_real_length + endcap_length])
    finger(height=height,
           length=endcap_length,
           thickness=thickness,
           foot_height=keyhole_diameter);
}

// mirrored_sides takes its children, creates two mirrored copies
// across the YZ plane, and places them <width> apart. Basically, if
// you have one side of a raceway, plug the raceway width into this
// and you'll get two raceway sides separated by the right amount.
module mirrored_sides(width=20) {
  translate([-width/2,0,0]) children();
  translate([width/2,0,0]) mirror([1,0,0]) children();
}

// raceway_bottom generates the bottom panel of the raceway. The
// bottom panel is solid plastic, with the exception of a slot drilled
// out of the middle for screws and other mounting hardware. The slot
// defaults to M3 width.
module raceway_bottom(width=20,
                      length=100,
                      thickness=1.2,
                      screw_slot_width=3) {
  // One cube for the bottom, then remove another cube for the slot.
  render(convexity=10)
  difference() {
    translate([-width/2, 0, 0]) cube([width, thickness, length]);
    translate([-screw_slot_width/2,-0.001,thickness])
      cube([screw_slot_width, thickness+0.002, length-(2*thickness)]);
  };
}

// raceway generates a cable raceway, consisting of a bottom panel
// with screw mounts and fingers attached.
module raceway(height=20,
               width=20,
               length=200,
               thickness=1.2,
               finger_length=4,
               slot_length=2,
               keyhole_diameter=3,
               screw_slot_width=3) {
  // This just combines two raceway sides and a bottom module.
  translate([width/2,0,0]) union() {
    mirrored_sides(width=width) {
      raceway_side(height=height,
                   length=length,
                   finger_length=finger_length,
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

// lid generates a raceway lid, with a profile that snaps into the
// clips at the top of the raceway fingers.
module lid(width=20,
           length=40,
           thickness=1.2) {
  // One half of the lid profile, which basically mirrors the clip on
  // the raceway fingers.
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
    render(convexity=10) linear_extrude(height=length) polygon(points);
  };

  // Weld two half-lids together to get a full lid.
  translate([width/2, 0, 0]) union() {
    translate([-width/2, 0, 0]) halflid();
    mirror([1,0,0]) translate([-width/2, 0, 0]) halflid();
  };
}

// butt_joint generates a straight linking piece to join two
// raceways. It attaches to both raceways' screw slots.
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

// tee_joint generates a T-shaped linking piece to join two
// raceways. It attaches to both raceways' screw slots.
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

// ell_joint generates an L-shaped linking piece to join two
// raceways. It attaches to both raceways' screw slots.
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
