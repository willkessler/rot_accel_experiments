// Actuator style control of arm segments
// Author: Will Kessler 12/1/2020

// todo: allow for "coast" at end where dampener weakens
// allow for callback after we pass the targetPoint, so we can immediately "coast" to next target

ArmSegment shoulder, forearm;
PVector shoulderEndpoint;
StringList statuses;

 
// https://forum.processing.org/two/discussion/3811/what-is-the-alternative-in-processing
int sign(float f) {
  if (f==0) return(0);
  return(int(f/abs(f)));
}

// see: https://www.euclideanspace.com/maths/algebra/vectors/angleBetween/
FloatDict angleBetweenVectors(PVector v1, PVector v2) {        
  FloatDict result = new FloatDict();
  result.set("angle", 0);
  result.set("sign", 1);
  result.set("signedAngle", 0);
  PVector v1Norm = new PVector(v1.x, v1.y);
  PVector v2Norm = new PVector(v2.x, v2.y);
  v1Norm.normalize();
  v2Norm.normalize();
  
  PVector zeroCheck = PVector.sub(v1Norm, v2Norm);
  if (zeroCheck.mag() < 0.01) {
    return result;
  }
  float dp = v1Norm.dot(v2Norm);
  result.set("angle", degrees(acos(dp)));
  // cross prod of 2 2d vecs, cf source of https://chipmunk-physics.net/
  // also see https://stackoverflow.com/questions/243945/calculating-a-2d-vectors-cross-product#:~:text=You%20can't%20do%20a,vectors%20on%20the%20xy%2Dplane.
  result.set("sign", sign(v1.x * v2.y - v1.y * v2.x));
  result.set("signedAngle", result.get("angle") * result.get("sign"));
  return result;
}

void setup() {
  size(640,360);
  // We make a new Pendulum object with an origin location and arm length.
  shoulder = new ArmSegment("shoulder", null, new PVector(width/2,height/2),  75,  1);
  forearm =  new ArmSegment("forearm",  shoulder, new PVector(-width/4,-height/4), 100, 3);
  shoulder.setAngle(-45);
  forearm.setAngle(-45);
  shoulderEndpoint = new PVector(0,0);
  textSize(14);
  statuses = new StringList();
}
 
void renderStatuses() {
  String [] statusArray = statuses.array();
  int i;
  for (i = 0; i < statuses.size(); ++i) {
    text(statusArray[i], 10, 10 + i * 15);
  }
  statuses.clear();
}


void draw() {
  background(0);
  shoulder.update();
  if (shoulder.isStable()) {
    if (shoulder.nearAngle(45)) {
      shoulder.gotoAngle(-45, 90);
    } else {
      shoulder.gotoAngle(45, 90);
    }
  }

  float shoulderAngle = shoulder.getAngle();
  statuses.append("<:" + round(shoulderAngle) + " US:" + shoulder.inUpStroke());

  if (shoulder.inUpStroke()) {
    if ((shoulderAngle < -10) && forearm.isStable()) { 
      statuses.append("Going to -40, upstroke");
      forearm.gotoAngle(-40,50); // swing farther up
    } else if ((shoulderAngle > 10) && forearm.isStable()) {
      statuses.append("Going to neutral, upstroke");
      forearm.gotoAngle(30,25); // neutral
    }
  } else {
    if ((shoulderAngle < -30) && forearm.isStable()) {
      statuses.append("Going to neutral, downstroke");
      //println("going to neutral downstroke");
      forearm.gotoAngle(30,40); // neutral, downstroke
    } else if ((shoulderAngle > 15) && forearm.isStable()) {
      statuses.append("Going to 60, downstroke");
      forearm.gotoAngle(60,30); // swing farther down
    }
  }

  forearm.update();
  shoulderEndpoint = shoulder.getEndpoint();
  forearm.setOrigin(shoulderEndpoint);

  fill(255);
  renderStatuses();

  shoulder.render();
  forearm.render();
  delay(200);
}
 
class ArmSegment  {
  String segmentName;      // Name (convenience) of arm segment for debugging
  ArmSegment parent;       // null if root, otherwise, parent of this arm segment
  PVector origin;          // Location of arm origin
  PVector segmentEndpoint; // Location of arm segment end
  float segmentLength;     // Length of arm segment
  float angle;             // Arm segment angle (degrees) from parent or horizon (if root)
  float angle_r;           // Arm segment angle (radians)
  float velocity;          // Angular velocity
  float acceleration;      // Angular acceleration
  float dampener, dampenerUpticking, dampenerUptickAmount;
  boolean reachedTargetAngle;
  float targetAngle;
  float accelerationDenom = 75;
  float stabilityTolerance;
  
  ArmSegment(String _segmentName, ArmSegment _parent, PVector _origin, float _segmentLength, float tolerance) {
    segmentName = _segmentName;
    parent = _parent;
    origin = _origin.get();
    segmentEndpoint = new PVector();
    segmentLength = _segmentLength;
    stabilityTolerance = tolerance;
 
    velocity = 0.0;
    acceleration = 0.0;
    dampener = 0.85;
    dampenerUpticking = .01;
    dampenerUptickAmount = 0.3; // four frames will increase dampener to full strength
    reachedTargetAngle = false;
  }
 
  boolean nearAngle(float nearbyAngle) {
    return (abs(angle - nearbyAngle) < stabilityTolerance);
  }
  
  float getAngle() {
    return angle;
  }
  
  void setAngle(float _angle) {
    angle = _angle;
    targetAngle = _angle;
  }

  void gotoAngle(float _angle, float _accelDenom) {
    targetAngle = _angle;
    accelerationDenom = _accelDenom;
    dampenerUpticking = .015;
    reachedTargetAngle = false;
  }
  
  boolean isStable() {
    return reachedTargetAngle;
  }

  boolean inUpStroke() {
    return velocity < 0;
  }

  boolean inDownStroke() {
    return velocity > 0;
  }

  void setOrigin(PVector _origin) {
    origin.set(_origin.x, _origin.y);
  }

  PVector getEndpoint() {
    PVector _origin;
    _origin = new PVector(segmentEndpoint.x, segmentEndpoint.y);
    return(_origin);
  }
  
  void update() {
    float angleDiff = targetAngle - angle;
    if (abs(angleDiff) > stabilityTolerance) {
      acceleration = angleDiff / accelerationDenom;
    } else {
      //acceleration = 0;
      reachedTargetAngle = true;
      statuses.append(segmentName + ": Reached target angle (" + targetAngle + ")");
    }

    velocity += acceleration;
    velocity *= dampenerUpticking;
    angle += velocity;
    angle_r = radians(angle);
    // additionally rotate by the sum of the angles of the parent and grandparent
    float totalRot = angle_r;
    if (parent != null) {
      totalRot += radians(parent.getAngle());
    }
    segmentEndpoint.set(segmentLength * cos(totalRot), segmentLength * sin(totalRot));

    dampenerUpticking = (dampenerUpticking + dampenerUptickAmount > dampener ? 
                         dampener :
                         dampenerUpticking + dampenerUptickAmount);

  }
 
  void render() {
    // Where is the bob relative to the origin? Polar to Cartesian coordinates will tell us!
    translate(origin.x, origin.y);
    stroke(255,0,0);
    strokeWeight(5);
    // The arm
    line(0,0, segmentEndpoint.x, segmentEndpoint.y);
    // The bob
    stroke(255,255,255);
    fill(255,255,255);
    strokeWeight(1);
    ellipse(segmentEndpoint.x,segmentEndpoint.y,12,12);
    rect(-4,-4, 8,8);
  }
}
