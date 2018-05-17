var target : Transform;

private var zoomSpeed = 0.5;
private var panSpeed = 1;
private var distance = 0.7;

private var orbitX = 17.0;
private var orbitY = 17.0;

private var x = 0.0;
private var y = 0.0;

private var firstdistance = 0.0;
private var firsttagetPos;
private var firstanglex = 0.0;
private var firstangley = 0.0;

var rotationDamping : float = 3.0;

function Start () {
	
	firstdistance = distance;
	firsttagetPos = target.transform.position;
	
    var angles = transform.eulerAngles;
    x = angles.y;
	firstanglex = angles.y;
    y = angles.x;
    firstangley = angles.x;
	
}

function LateUpdate (){
	
	//zoom
	if (Input.GetMouseButton(1)) {
		distance += Input.GetAxis("Mouse Y") * zoomSpeed;
		distance = Mathf.Clamp(distance, 0.5, 2);
    }else
   		distance -= (distance - firstdistance) * Time.deltaTime;
    
	//orbit
    if (Input.GetMouseButton(0)) {
    
        x += Input.GetAxis("Mouse X") * orbitX;
        y -= Input.GetAxis("Mouse Y") * orbitY;
        
    }else{
    	x -= (x - firstanglex) * Time.deltaTime;
    	y -= (y - firstangley) * Time.deltaTime;
    }
    
        //pan
    target.transform.rotation = transform.rotation;
	
	if( Input.GetMouseButton(2)){
		var panVal = panSpeed * (distance / 20);
		if(Input.GetAxis("Mouse Y") != 0){
			target.transform.Translate(-Vector3.up * Input.GetAxis("Mouse Y") * panVal);
			transform.Translate(-Vector3.up * Input.GetAxis("Mouse Y") * panVal);
		}
		if(Input.GetAxis("Mouse X") != 0){
			target.transform.Translate(-Vector3.right * Input.GetAxis("Mouse X") * panVal);
			transform.Translate(-Vector3.right * Input.GetAxis("Mouse X") * panVal);
		}
	}else{
    	target.transform.position -= (target.transform.position - firsttagetPos) * Time.deltaTime;
    }
 		       
    var rotation = Quaternion.Euler(y, x, 0);
    var position = rotation * Vector3(0.0, 0.0, -distance) + target.position;
   	
   	target.transform.rotation = rotation;
   	transform.position = position;
   	
}
