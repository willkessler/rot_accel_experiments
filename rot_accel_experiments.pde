ArmSegment shoulder, forearm;
PVector shoulderEndpoint;
 
void setup() {
  size(640,360);
  // We make a new Pendulum object with an origin location and arm length.
  shoulder = new ArmSegment("shoulder", new PVector(width/2,height/2),  75,  1);
  forearm =  new ArmSegment("forearm", new PVector(-width/4,-height/4), 100, 3);
  shoulder.setAngle(-45);
  forearm.setAngle(-45);
  shoulderEndpoint = new PVector(0,0);
  textSize(24);
}
 
void draw() {
  background(0);
  shoulder.update();
  if (shoulder.isStable()) {
    if (shoulder.nearAngle(45)) {
      shoulder.gotoAngle(-45, 90);
    } else {
      shoulder.gotoAngle(45, 90);
      forearm.gotoAngle(-45,20);
    }
  }
  shoulder.render();

  float shoulderAngle = shoulder.getAngle();
  if (shoulder.inUpStroke()) {
    if ((shoulderAngle < -10) && forearm.isStable()) { 
      println("Going to -55, upstroke");
      forearm.gotoAngle(-55,50); // swing farther up
    } else if ((shoulderAngle > 10) && forearm.isStable()) {
      println("Going to neutral, upstroke");
      forearm.gotoAngle(30,25); // neutral
    }
  } else {
    if ((shoulderAngle < -40) && forearm.isStable()) {
      println("Going to neutral, downstroke");
      forearm.gotoAngle(30,50); // neutral, downstroke
    } else if ((shoulderAngle > 25) && forearm.isStable()) {
      println("Going to 85, downstroke");
      forearm.gotoAngle(85,25); // swing farther down
    }
  }

  forearm.update();
  shoulderEndpoint = shoulder.getEndpoint();
  forearm.setOrigin(shoulderEndpoint);
  forearm.render();

  fill(255);
  text("<:" + round(shoulderAngle) + " US:" + shoulder.inUpStroke(), 10, 10);

  delay(200);
}
 
class ArmSegment  {
  String segmentName;
  PVector origin;          // Location of arm origin
  PVector segmentEndpoint; // Location of arm segment end
  float segmentLength;     // Length of arm segment
  float angle;             // Arm segment angle (degrees)
  float angle_r;       // Arm segment angle (radians)
  float velocity;      // Angular velocity
  float acceleration;  // Angular acceleration
  float dampener, dampenerUpticking, dampenerUptickAmount;
  boolean reachedTargetAngle;
  float targetAngle;
  float accelerationDenom = 75;
  float stabilityTolerance;
  
  ArmSegment(String _segmentName, PVector _origin, float _segmentLength, float tolerance) {
    segmentName = _segmentName;
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
      acceleration = 0;
      reachedTargetAngle = true;
      println(segmentName + ": Reached target angle (" + targetAngle + ")");
    }

    velocity += acceleration;
    velocity *= dampenerUpticking;
    angle += velocity;
    angle_r = radians(angle);
    segmentEndpoint.set(segmentLength * cos(angle_r), segmentLength * sin(angle_r));
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
