ArmSegment shoulder, forearm;
PVector shoulderEndpoint;
 
void setup() {
  size(640,360);
  // We make a new Pendulum object with an origin location and arm length.
  shoulder = new ArmSegment(new PVector(width/2,height/2),100,1);
  forearm =  new ArmSegment(new PVector(width/2,height/2),75,3);
  shoulder.setAngle(-45);
  forearm.setAngle(-65);
  shoulderEndpoint = new PVector(0,0);
}
 
void draw() {
  background(0);
  shoulder.update();
  if (shoulder.isStable()) {
    if (shoulder.nearAngle(45)) {
      shoulder.gotoAngle(-45, 50);
    } else {
      shoulder.gotoAngle(45, 75);
    }
  }
  shoulder.render();

  forearm.update();
  if (forearm.getAngle() < -60) {
    println("forearm angle:", forearm.getAngle());
  }
  if (forearm.isStable()) {
    if (forearm.nearAngle(-65)) {
      println("forearm going to 65");
      forearm.gotoAngle(65, 50);
    } else {
      println("forearm going to -65");
      forearm.gotoAngle(-65, 75);
    }
  }
  shoulderEndpoint = shoulder.getEndpoint();
  forearm.setOrigin(shoulderEndpoint);
  forearm.render();
  delay(100);
}
 
class ArmSegment  {
  PVector origin;          // Location of arm origin
  PVector segmentEndpoint; // Location of arm segment end
  float segmentLength;     // Length of arm segment
  float angle;             // Arm segment angle (degrees)
  float angle_r;       // Arm segment angle (radians)
  float velocity;      // Angular velocity
  float acceleration;  // Angular acceleration
  float dampener;
  boolean reachedTargetAngle;
  float targetAngle;
  float accelerationDenom = 75;
  float stabilityTolerance;
  
  ArmSegment(PVector _origin, float _segmentLength, float tolerance) {
    origin = _origin.get();
    angle = PI/2;
    segmentEndpoint = new PVector();
    segmentLength = _segmentLength;
    stabilityTolerance = tolerance;
 
    velocity = 0.0;
    acceleration = 0.0;
    dampener = 0.85;
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
    reachedTargetAngle = false;
  }
  
  boolean isStable() {
    return reachedTargetAngle;
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
    }

    velocity += acceleration;
    velocity *= dampener;
    angle += velocity;
    angle_r = radians(angle);
    segmentEndpoint.set(segmentLength * cos(angle_r), segmentLength * sin(angle_r));

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
