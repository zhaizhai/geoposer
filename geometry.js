const AREA_EPSILON = 0.0000001;
const DIST_EPSILON = 0.00001;

class Point {
  constructor(x, y) {
    this.x = x; this.y = y;
  }

  equals(o) {
    return this.dist(o) < DIST_EPSILON;
  }

  scale(r) {
    return new Point(this.x * r, this.y * r)
  }

  dot(o) {
    return this.x * o.x + this.y * o.y;
  }

  length() {
    return Math.sqrt(this.x * this.x + this.y * this.y);
  }

  minus(o) {
    return new Point(this.x - o.x, this.y - o.y);
  }

  plus(o) {
    return new Point(this.x + o.x, this.y + o.y);
  }

  dist(o) {
    return this.minus(o).length();
  }
}

class Line {
  constructor(s, e) {
    this.s = s; this.e = e;
  }
}

class Circle {
  constructor(c, r) {
    this.c = c; this.r = r;
  }
}


// counterclockwise is positive
const area2 = (p1, p2, p3) => {
  const dx1 = p2.x - p1.x, dx2 = p3.x - p1.x;
  const dy1 = p2.y - p1.y, dy2 = p3.y - p1.y;
  return dx1 * dy2 - dx2 * dy1;
};

const midpt = (p1, p2) => {
  return new Point((p1.x + p2.x)/2, (p1.y + p2.y)/2);
};

const perp_bisector = (p1, p2) => {
  const m = midpt(p1, p2);
  const v = p2.minus(p1);
  const w = new Point(v.y, -v.x);
  return new Line(m, m.plus(w));
};

const tangent_PC = (p, c) => {
  // TODO: verify that p actually lies on c
};

const tangent_circ_PPL = (p1, p2, l) => {
  // TODO: figure out which solution to use...
};

// projection of a point onto a line
const project_PL = (p, l) => {
  const v = l.e.minus(l.s);
  const vlen = v.length();
  const w = p.minus(l.s);
  return l.s.plus(v.scale(w.dot(v) / vlen / vlen));
};

// intersection of two lines
const intersect_LL = (l1, l2) => { // TODO: handle corner cases
  const r1 = area2(l1.s, l2.e, l2.s);
  const r2 = area2(l2.s, l2.e, l1.e);
  const ret = l1.s.scale(r2).plus(l1.e.scale(r1));
  return ret.scale(1/(r1 + r2));
};

const angle_bisector = (p1, p2, p3) => {
  const u = p1.minus(p2), v = p3.minus(p2);
  const a = u.length(), b = v.length();
  const w = u.scale(b).plus(v.scale(a));
  const z = p2.plus(w.scale(1 / (a + b)));
  return new Line(p2, z);
};

// second intersection of two circles with a point in common
const intersect_PCC = (p, c1, c2) => { // TODO: handle corner cases
  const mid = project_PL(p, new Line(c1.c, c2.c));
  return p.plus(mid.minus(p).scale(2));
};

// second intersection of a line with a circle
const intersect_PLC = (p, l, c) => {
  const halfway = project_PL(c.c, l);
  return p.plus(halfway.minus(p).scale(2));
};

// intersection of two circles (throws if they don't intersect)
const intersect_CC = (c1, c2) => {
  // TODO
};

const circumcircle = (p1, p2, p3) => {
  // TODO: handle collinear
  const l1 = perp_bisector(p2, p3);
  const l2 = perp_bisector(p1, p3);
  const c = intersect_LL(l1, l2);
  return new Circle(c, c.dist(p1));
};

/*********** Coincidence tests ***********/
const are_collinear = (p1, p2, p3) => {
  return Math.abs(area2(p1, p2, p3)) <= AREA_EPSILON;
};

const are_concurrent = (p1, p2, p3) => {
  let x1 = intersect_LL(p2, p3);
  let x2 = intersect_LL(p1, p3);
  let x3 = intersect_LL(p1, p2);
  return (x1.dist(x2) < DIST_EPSILON && x1.dist(x3) < DIST_EPSILON);
};


// TODO: workaround until updated ecma6 compatible coffeescript
exports.Point = (...args) => new Point(...args);
exports.Line = (...args) => new Line(...args);
exports.Circle = Circle;

exports.project_PL = project_PL;
exports.intersect_LL = intersect_LL;
exports.midpt = midpt;
exports.angle_bisector = angle_bisector;

exports.circumcircle = circumcircle;
exports.intersect_PCC = intersect_PCC;
exports.intersect_PLC = intersect_PLC;

exports.are_collinear = are_collinear;
exports.are_concurrent = are_concurrent;