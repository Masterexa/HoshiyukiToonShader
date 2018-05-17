#pragma strict
//カメラの角度によって顔の輪郭モーフを変えるスクリプト;
//3D感をへらせる気がする;
//自由につかっていいよby雨刻憩;
private var facemoof:SkinnedMeshRenderer;


var camObj : Transform;
var faceObj : GameObject;
var constObj : Transform;

var moofVal = 20;

private var hAngleR = 0.0;
private var hAngleL = 0.0;
private var vAngleU = 0.0;
private var vAngleD = 0.0;
private var camPos = Vector3(0.0,0.0,0.0);
private var constangles = Vector3(0.0,0.0,0.0);
private var hangles = Vector3(0.0,0.0,180);

private var hAngle = 0.0;
private var vAngle = 0.0;

private var constPos = Vector3(0.0,0.0,0.0);
private var constRot = Quaternion(0.0, 0.0, 0.0,0.0);

@script AddComponentMenu("Script/camAngles")

function Start(){
	facemoof = faceObj.GetComponent(SkinnedMeshRenderer);
}
function Update () {
	
	//ターゲットから角度を算出する;
	camPos = constObj.transform.InverseTransformPoint(camObj.transform.position);
	var hangle = Mathf.Atan2(Mathf.Abs(camPos.x),Mathf.Max(Mathf.Abs(camPos.z),0.2))* Mathf.Rad2Deg;
	var vangle = Mathf.Atan2(Mathf.Abs(camPos.y),Mathf.Max(Mathf.Abs(camPos.z),0.2))* Mathf.Rad2Deg;

	hAngleR = Mathf.Max(hangle - vangle,0.0);
	vAngleU = Mathf.Max(vangle - hangle,0.0);

	hAngleR = (hAngleR * hAngleR + 5) / moofVal;
	vAngleU = (vAngleU * vAngleU + 5) / moofVal;
	
	hAngleL = hAngleR;
	vAngleD = vAngleU;
	
	if(camPos.x < 0){
		hAngleR *= -1;
	}
	else{
		hAngleL *= -1;
	}
	
	//顔モーフ番号;
	facemoof.SetBlendShapeWeight(45,hAngleR);
	facemoof.SetBlendShapeWeight(44,hAngleL);
	facemoof.SetBlendShapeWeight(43,vAngleU);
	facemoof.SetBlendShapeWeight(43,vAngleD);
}
