#pragma strict

var skinny : GUISkin;
var guiEnabled = true;

var buttonWidth = 80;
var buttonheight = 20;
private var buttonbetween = buttonheight + 5;

private var screenwidth = Screen.width;
private var screenheight = Screen.height;

private var RsliderVal = 0.0;
private var GsliderVal = 0.0;
private var BsliderVal = 0.0;

private var faceM : GameObject;
private var eyeM : GameObject;
private var otherM : GameObject;
private var other2M : GameObject;

private var facemoof:SkinnedMeshRenderer;
private var eyemoof:SkinnedMeshRenderer;
private var othermoof:SkinnedMeshRenderer;
private var other2moof:SkinnedMeshRenderer;

var mouth_a : float = 0;
var mouth_i : float = 0;
var mouth_u : float = 0;
var mouth_e : float = 0;
var mouth_o : float = 0;
var mouth_a2 : float = 0;
var mouth_n : float = 0;
var mouth_triangle : float = 0;
var mouth_lambda : float = 0;
var mouth_square : float = 0;
var mouth_wa : float = 0;
var mouth_wa2 : float = 0;
var mouth_shock : float = 0;
var mouth_angry : float = 0;
var mouth_smile : float = 0;
var mouth_spear : float = 0;
var mouth_spear2 : float = 0;
var mouth_cornerUP : float = 0;
var mouth_cornerDown : float = 0;
var mouth_cornerSpear : float = 0;
var mouth_noTeethUP : float = 0;
var mouth_noTeethDown : float = 0;
var mouth_Tu : float = 0;
var mouth_be : float = 0;
var eye_blink : float = 0;
var eye_smile : float = 0;
var eye_winkL : float = 0;
var eye_winkR : float = 0;
var eye_winkL2 : float = 0;
var eye_winkR2 : float = 0;
var eye_Calm : float = 0;
var eye_shock : float = 0;
var eye_surprised : float = 0;
var eye_TT : float = 0;
var eye_serious : float = 0;
var eye_hacyu : float = 0;
var eyeblow_serious : float = 0;
var eyeblow_trouble : float = 0;
var eyeblow_smile : float = 0;
var eyeblow_angry : float = 0;
var eyeblow_up : float = 0;
var eyeblow_down : float = 0;
var eyeblow_gather : float = 0;
var face_view : float = 0;
var face_rignt : float = 0;
var face_left : float = 0;
var tongue : float = 0;
var mouth_mortifying : float = 0;
var eye_up : float = 0;
//other
var other_shy : float = 0;
var eye_h2 : float = 0;
var eye_h3 : float = 0;
var other_shocked : float = 0;
var other_tear: float = 0;
//other02
var other_shy2 : float = 0;

private var mouth_Button :boolean[] = new boolean[25];
private var eye_Button :boolean[] = new boolean[15];
private var eyeblow_Button :boolean[] = new boolean[7];
private var face_Button :boolean[] = new boolean[4];
private var other_Button :boolean[] = new boolean[4];

function Start () {
	faceM = GameObject.Find("face");
	facemoof = faceM.GetComponent(SkinnedMeshRenderer);
	eyeM = GameObject.Find("eye");
	eyemoof = eyeM.GetComponent(SkinnedMeshRenderer);
	otherM = GameObject.Find("other");
	othermoof = otherM.GetComponent(SkinnedMeshRenderer);
	other2M = GameObject.Find("other02");
	other2moof = other2M.GetComponent(SkinnedMeshRenderer);
}

function OnGUI () {
	if (guiEnabled){
		GUI.skin = skinny;
		GUI.contentColor = Color.black;
		
		//mouth
		mouth_Button[0] = GUI.Toggle (new Rect(20,buttonbetween,buttonWidth,buttonheight),mouth_Button[0], "あ");
		mouth_Button[1] = GUI.Toggle (new Rect(20,buttonbetween*2,buttonWidth,buttonheight),mouth_Button[1], "い");
		mouth_Button[2] = GUI.Toggle (new Rect(20,buttonbetween*3,buttonWidth,buttonheight),mouth_Button[2], "う");
		mouth_Button[3] = GUI.Toggle (new Rect(20,buttonbetween*4,buttonWidth,buttonheight),mouth_Button[3], "え");
		mouth_Button[4] = GUI.Toggle (new Rect(20,buttonbetween*5,buttonWidth,buttonheight),mouth_Button[4], "お");
		mouth_Button[5] = GUI.Toggle (new Rect(20,buttonbetween*6,buttonWidth,buttonheight),mouth_Button[5], "あ２");
		mouth_Button[6] = GUI.Toggle (new Rect(20,buttonbetween*10,buttonWidth,buttonheight),mouth_Button[6], "ん");
		mouth_Button[7] = GUI.Toggle (new Rect(20,buttonbetween*7,buttonWidth,buttonheight),mouth_Button[7], "▲");
		mouth_Button[8] = GUI.Toggle (new Rect(20,buttonbetween*8,buttonWidth,buttonheight),mouth_Button[8], "Λ");
		mouth_Button[9] = GUI.Toggle (new Rect(20,buttonbetween*9,buttonWidth,buttonheight),mouth_Button[9], "■");
		mouth_Button[10] = GUI.Toggle (new Rect(20,buttonbetween*11,buttonWidth,buttonheight),mouth_Button[10], "ワ");
		mouth_Button[11] = GUI.Toggle (new Rect(20,buttonbetween*12,buttonWidth,buttonheight),mouth_Button[11], "ワ２");
		mouth_Button[12] = GUI.Toggle (new Rect(20,buttonbetween*13,buttonWidth,buttonheight),mouth_Button[12], "驚");
		mouth_Button[13] = GUI.Toggle (new Rect(20,buttonbetween*14,buttonWidth,buttonheight),mouth_Button[13], "怒");
		mouth_Button[14] = GUI.Toggle (new Rect(20,buttonbetween*15,buttonWidth,buttonheight),mouth_Button[14], "にっこり");
		mouth_Button[15] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween,buttonWidth,buttonheight),mouth_Button[15], "にやり");
		mouth_Button[16] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*2,buttonWidth,buttonheight),mouth_Button[16], "にやり２");
		mouth_Button[17] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*3,buttonWidth,buttonheight),mouth_Button[17], "口角上げ");
		mouth_Button[18] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*4,buttonWidth,buttonheight),mouth_Button[18], "口角下げ");
		mouth_Button[19] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*5,buttonWidth,buttonheight),mouth_Button[19], "口角広げ");
		mouth_Button[20] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*6,buttonWidth,buttonheight),mouth_Button[20], "歯無し上");
		mouth_Button[21] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*7,buttonWidth,buttonheight),mouth_Button[21], "歯無し下");
		mouth_Button[22] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*8,buttonWidth,buttonheight),mouth_Button[22], "つ");
		mouth_Button[23] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*9,buttonWidth,buttonheight),mouth_Button[23], "べ");
		mouth_Button[24] = GUI.Toggle (new Rect(buttonWidth+10,buttonbetween*10,buttonWidth,buttonheight),mouth_Button[24], "悔");
		
		//eye
		eye_Button[0] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween,buttonWidth,buttonheight),eye_Button[0], "まばたき");
		eye_Button[1] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*2,buttonWidth,buttonheight),eye_Button[1], "にっこり");
		eye_Button[2] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*3,buttonWidth,buttonheight),eye_Button[2], "ウインク左");
		eye_Button[3] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*4,buttonWidth,buttonheight),eye_Button[3], "ウインク右");
		eye_Button[4] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*5,buttonWidth,buttonheight),eye_Button[4], "ウインク左２");
		eye_Button[5] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*6,buttonWidth,buttonheight),eye_Button[5], "ウインク右２");
		eye_Button[6] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*7,buttonWidth,buttonheight),eye_Button[6], "なごみ");
		eye_Button[7] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*8,buttonWidth,buttonheight),eye_Button[7], "＞＜");
		eye_Button[8] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*9,buttonWidth,buttonheight),eye_Button[8], "驚き");
		eye_Button[9] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*10,buttonWidth,buttonheight),eye_Button[9], "TT");
		eye_Button[10] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*11,buttonWidth,buttonheight),eye_Button[10], "まじめ");
		eye_Button[11] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*12,buttonWidth,buttonheight),eye_Button[11], "はちゅ目");
		eye_Button[12] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*13,buttonWidth,buttonheight),eye_Button[12], "はちゅ目縦");
		eye_Button[13] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*14,buttonWidth,buttonheight),eye_Button[13], "はちゅ目横");
		eye_Button[14] = GUI.Toggle (new Rect(buttonWidth*2+10,buttonbetween*15,buttonWidth,buttonheight),eye_Button[14], "下まぶた上げ");
		
		//eyeblow
		eyeblow_Button[0] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween,buttonWidth,buttonheight),eyeblow_Button[0], "まじめ");
		eyeblow_Button[1] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*2,buttonWidth,buttonheight),eyeblow_Button[1], "こまる");
		eyeblow_Button[2] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*3,buttonWidth,buttonheight),eyeblow_Button[2], "にっこり");
		eyeblow_Button[3] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*4,buttonWidth,buttonheight),eyeblow_Button[3], "おこる");
		eyeblow_Button[4] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*5,buttonWidth,buttonheight),eyeblow_Button[4], "上");
		eyeblow_Button[5] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*6,buttonWidth,buttonheight),eyeblow_Button[5], "下");
		eyeblow_Button[6] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*7,buttonWidth,buttonheight),eyeblow_Button[6], "寄");
		
		//輪郭 
		face_Button[0] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*8,buttonWidth,buttonheight),face_Button[0], "俯瞰煽り");
		face_Button[1] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*9,buttonWidth,buttonheight),face_Button[1], "輪郭右");
		face_Button[2] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*10,buttonWidth,buttonheight),face_Button[2], "輪郭左");
		face_Button[3] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*11,buttonWidth,buttonheight),face_Button[3], "舌");
		
		//他
		other_Button[0] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*12,buttonWidth,buttonheight),other_Button[0], "照れ");
		other_Button[1] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*13,buttonWidth,buttonheight),other_Button[1], "照れ2");
		other_Button[2] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*14,buttonWidth,buttonheight),other_Button[2], "がーん");
		other_Button[3] = GUI.Toggle (new Rect(screenwidth-(buttonWidth),buttonbetween*15,buttonWidth,buttonheight),other_Button[3], "涙");
	}
}

function Update () {
	
	//blink
	eye_blink = (eye_blink > 200) ? Random.Range(-7000,-3000) : eye_blink + 10;
	
	//mouth
	if (mouth_Button[0])	mouth_a = Mathf.Min(mouth_a + 10,100);
	else 					mouth_a = Mathf.Max(0,mouth_a - 10);
	if (mouth_Button[1])	mouth_i = Mathf.Min(mouth_i + 10,100);
	else 					mouth_i = Mathf.Max(0,mouth_i - 10);
	if (mouth_Button[2])	mouth_u = Mathf.Min(mouth_u + 10,100);
	else 					mouth_u = Mathf.Max(0,mouth_u - 10);
	if (mouth_Button[3])	mouth_e = Mathf.Min(mouth_e + 10,100);
	else 					mouth_e = Mathf.Max(0,mouth_e - 10);
	if (mouth_Button[4])	mouth_o = Mathf.Min(mouth_o + 10,100);
	else 					mouth_o = Mathf.Max(0,mouth_o - 10);
	if (mouth_Button[5])	mouth_a2 = Mathf.Min(mouth_a2 + 10,100);
	else 					mouth_a2 = Mathf.Max(0,mouth_a2 - 10);
	if (mouth_Button[6])	mouth_n = Mathf.Min(mouth_n + 10,100);
	else 					mouth_n = Mathf.Max(0,mouth_n - 10);
	if (mouth_Button[7])	mouth_triangle = Mathf.Min(mouth_triangle + 10,100);
	else 					mouth_triangle = Mathf.Max(0,mouth_triangle - 10);
	if (mouth_Button[8])	mouth_lambda = Mathf.Min(mouth_lambda + 10,100);
	else 					mouth_lambda = Mathf.Max(0,mouth_lambda - 10);
	if (mouth_Button[9])	mouth_square = Mathf.Min(mouth_square + 10,100);
	else 					mouth_square = Mathf.Max(0,mouth_square - 10);
	if (mouth_Button[10])	mouth_wa = Mathf.Min(mouth_wa + 10,100);
	else 					mouth_wa = Mathf.Max(0,mouth_wa - 10);
	if (mouth_Button[11])	mouth_wa2 = Mathf.Min(mouth_wa2 + 10,100);
	else 					mouth_wa2 = Mathf.Max(0,mouth_wa2 - 10);
	if (mouth_Button[12])	mouth_shock = Mathf.Min(mouth_shock + 10,100);
	else 					mouth_shock = Mathf.Max(0,mouth_shock - 10);
	if (mouth_Button[13])	mouth_angry = Mathf.Min(mouth_angry + 10,100);
	else 					mouth_angry = Mathf.Max(0,mouth_angry - 10);
	if (mouth_Button[14])	mouth_smile = Mathf.Min(mouth_smile + 10,100);
	else 					mouth_smile = Mathf.Max(0,mouth_smile - 10);
	if (mouth_Button[15])	mouth_spear = Mathf.Min(mouth_spear + 10,100);
	else 					mouth_spear = Mathf.Max(0,mouth_spear - 10);
	if (mouth_Button[16])	mouth_spear2 = Mathf.Min(mouth_spear2 + 10,100);
	else 					mouth_spear2 = Mathf.Max(0,mouth_spear2 - 10);
	if (mouth_Button[17])	mouth_cornerUP = Mathf.Min(mouth_cornerUP + 10,100);
	else 					mouth_cornerUP = Mathf.Max(0,mouth_cornerUP - 10);
	if (mouth_Button[18])	mouth_cornerDown = Mathf.Min(mouth_cornerDown + 10,100);
	else 					mouth_cornerDown = Mathf.Max(0,mouth_cornerDown - 10);
	if (mouth_Button[19])	mouth_cornerSpear = Mathf.Min(mouth_cornerSpear + 10,100);
	else 					mouth_cornerSpear = Mathf.Max(0,mouth_cornerSpear - 10);
	if (mouth_Button[20])	mouth_noTeethUP = Mathf.Min(mouth_noTeethUP + 10,100);
	else 					mouth_noTeethUP = Mathf.Max(0,mouth_noTeethUP - 10);
	if (mouth_Button[21])	mouth_noTeethDown = Mathf.Min(mouth_noTeethDown + 10,100);
	else 					mouth_noTeethDown = Mathf.Max(0,mouth_noTeethDown - 10);
	if (mouth_Button[22])	mouth_Tu = Mathf.Min(mouth_Tu + 10,100);
	else 					mouth_Tu = Mathf.Max(0,mouth_Tu - 10);
	if (mouth_Button[23])	mouth_be = Mathf.Min(mouth_be + 10,100);
	else 					mouth_be = Mathf.Max(0,mouth_be - 10);
	//eye
	if (eye_Button[0]){
		eye_blink = (eye_blink < 0) ? 0 : Mathf.Min(eye_blink + 10,100);
	}
	if (eye_Button[1]){
		eye_smile = Mathf.Min(eye_smile + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_smile = Mathf.Max(0,eye_smile - 10);
	}
	if (eye_Button[2]){
		eye_winkL = Mathf.Min(eye_winkL + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_winkL = Mathf.Max(0,eye_winkL - 10);
	}
	if (eye_Button[3]){
		eye_winkR = Mathf.Min(eye_winkR + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_winkR = Mathf.Max(0,eye_winkR - 10);
	}
	if (eye_Button[4]){
		eye_winkL2 = Mathf.Min(eye_winkL2 + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_winkL2 = Mathf.Max(0,eye_winkL2 - 10);
	}
	if (eye_Button[5]){
		eye_winkR2 = Mathf.Min(eye_winkR2 + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_winkR2 = Mathf.Max(0,eye_winkR2 - 10);
	}
	if (eye_Button[6]){
		eye_Calm = Mathf.Min(eye_Calm + 10,100);
		eye_blink = Random.Range(-7000,-3000);
		
	}else{
		eye_Calm = Mathf.Max(0,eye_Calm - 10);
	}
	if (eye_Button[7]){
		eye_shock = Mathf.Min(eye_shock + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_shock = Mathf.Max(0,eye_shock - 10);
	}
	if (eye_Button[8]){
		eye_surprised = Mathf.Min(eye_surprised + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_surprised = Mathf.Max(0,eye_surprised - 10);
	}
	if (eye_Button[9]){
		eye_TT = Mathf.Min(eye_TT + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_TT = Mathf.Max(0,eye_TT - 10);
	}
	if (eye_Button[10]){
		eye_serious = Mathf.Min(eye_serious + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_serious = Mathf.Max(0,eye_serious - 10);
	}
	if (eye_Button[11]){
		eye_hacyu = Mathf.Min(eye_hacyu + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_hacyu = Mathf.Max(0,eye_hacyu - 10);
	}
	//eyeblow
	if (eyeblow_Button[0])	eyeblow_serious = Mathf.Min(eyeblow_serious + 10,100);
	else 					eyeblow_serious = Mathf.Max(0,eyeblow_serious - 10);
	if (eyeblow_Button[1])	eyeblow_trouble = Mathf.Min(eyeblow_trouble + 10,100);
	else 					eyeblow_trouble = Mathf.Max(0,eyeblow_trouble - 10);
	if (eyeblow_Button[2])	eyeblow_smile = Mathf.Min(eyeblow_smile + 10,100);
	else 					eyeblow_smile = Mathf.Max(0,eyeblow_smile - 10);
	if (eyeblow_Button[3])	eyeblow_angry = Mathf.Min(eyeblow_angry + 10,100);
	else 					eyeblow_angry = Mathf.Max(0,eyeblow_angry - 10);
	if (eyeblow_Button[4])	eyeblow_up = Mathf.Min(eyeblow_up + 10,100);
	else 					eyeblow_up = Mathf.Max(0,eyeblow_up - 10);
	if (eyeblow_Button[5])	eyeblow_down = Mathf.Min(eyeblow_down + 10,100);
	else 					eyeblow_down = Mathf.Max(0,eyeblow_down - 10);
	if (eyeblow_Button[6])	eyeblow_gather = Mathf.Min(eyeblow_gather + 10,100);
	else 					eyeblow_gather = Mathf.Max(0,eyeblow_gather - 10);
	
	if (face_Button[0])	face_view = Mathf.Min(face_view + 10,100);
	else 					face_view = Mathf.Max(0,face_view - 10);
	if (face_Button[1])	face_rignt = Mathf.Min(face_rignt + 10,100);
	else 					face_rignt = Mathf.Max(0,face_rignt - 10);
	if (face_Button[2])	face_left = Mathf.Min(face_left + 10,100);
	else 					face_left = Mathf.Max(0,face_left - 10);
	if (face_Button[3])	tongue = Mathf.Min(tongue + 10,100);
	else 					tongue = Mathf.Max(0,tongue - 10);
	if (mouth_Button[24])	mouth_mortifying = Mathf.Min(mouth_mortifying + 10,100);
	else 					mouth_mortifying = Mathf.Max(0,mouth_mortifying - 10);
	
	if (eye_Button[14]){
		eye_up = Mathf.Min(eye_up + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_up = Mathf.Max(0,eye_up - 10);
	}
	if (other_Button[0])	other_shy = Mathf.Min(other_shy + 10,100);
	else 					other_shy = Mathf.Max(0,other_shy - 10);
	if (eye_Button[12]){
		eye_h2 = Mathf.Min(eye_h2 + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_h2 = Mathf.Max(0,eye_h2 - 10);
	}
	if (eye_Button[13]){
		eye_h3 = Mathf.Min(eye_h3 + 10,100);
		eye_blink = Random.Range(-7000,-3000);
	}else{
		eye_h3 = Mathf.Max(0,eye_h3 - 10);
	}
	if (other_Button[2])	other_shocked = Mathf.Min(other_shocked + 10,100);
	else 					other_shocked = Mathf.Max(0,other_shocked - 10);
	if (other_Button[3])	other_tear = Mathf.Min(other_tear + 10,100);
	else 					other_tear = Mathf.Max(0,other_tear - 10);
	if (other_Button[1])	other_shy2 = Mathf.Min(other_shy2 + 10,100);
	else 					other_shy2 = Mathf.Max(0,other_shy2 - 10);
	
	facemoof.SetBlendShapeWeight(0,mouth_a);
	facemoof.SetBlendShapeWeight(1,mouth_i);
	facemoof.SetBlendShapeWeight(2,mouth_u);
	facemoof.SetBlendShapeWeight(3,mouth_e);
	facemoof.SetBlendShapeWeight(4,mouth_o);
	facemoof.SetBlendShapeWeight(5,mouth_a2);
	facemoof.SetBlendShapeWeight(6,mouth_n);
	facemoof.SetBlendShapeWeight(7,mouth_triangle);
	facemoof.SetBlendShapeWeight(8,mouth_lambda);
	facemoof.SetBlendShapeWeight(9,mouth_square);
	facemoof.SetBlendShapeWeight(10,mouth_wa);
	facemoof.SetBlendShapeWeight(11,mouth_wa2);
	facemoof.SetBlendShapeWeight(12,mouth_shock);
	facemoof.SetBlendShapeWeight(13,mouth_angry);
	facemoof.SetBlendShapeWeight(14,mouth_smile);
	facemoof.SetBlendShapeWeight(15,mouth_spear);
	facemoof.SetBlendShapeWeight(16,mouth_spear2);
	facemoof.SetBlendShapeWeight(17,mouth_cornerUP);
	facemoof.SetBlendShapeWeight(18,mouth_cornerDown);
	facemoof.SetBlendShapeWeight(19,mouth_cornerSpear);
	facemoof.SetBlendShapeWeight(20,mouth_noTeethUP);
	facemoof.SetBlendShapeWeight(21,mouth_noTeethDown);
	facemoof.SetBlendShapeWeight(22,mouth_Tu);
	facemoof.SetBlendShapeWeight(23,mouth_be);
	facemoof.SetBlendShapeWeight(24,eye_blink);
	facemoof.SetBlendShapeWeight(25,eye_smile);
	facemoof.SetBlendShapeWeight(26,eye_winkL);
	facemoof.SetBlendShapeWeight(27,eye_winkR);
	facemoof.SetBlendShapeWeight(28,eye_winkL2);
	facemoof.SetBlendShapeWeight(29,eye_winkR2);
	facemoof.SetBlendShapeWeight(30,eye_Calm);
	facemoof.SetBlendShapeWeight(31,eye_shock);
	facemoof.SetBlendShapeWeight(32,eye_surprised);
	facemoof.SetBlendShapeWeight(33,eye_TT);
	facemoof.SetBlendShapeWeight(34,eye_serious);
	facemoof.SetBlendShapeWeight(35,eye_hacyu);
	facemoof.SetBlendShapeWeight(36,eyeblow_serious);
	facemoof.SetBlendShapeWeight(37,eyeblow_trouble);
	facemoof.SetBlendShapeWeight(38,eyeblow_smile);
	facemoof.SetBlendShapeWeight(39,eyeblow_angry);
	facemoof.SetBlendShapeWeight(40,eyeblow_up);
	facemoof.SetBlendShapeWeight(41,eyeblow_down);
	facemoof.SetBlendShapeWeight(42,eyeblow_gather);
	facemoof.SetBlendShapeWeight(43,face_view);
	facemoof.SetBlendShapeWeight(44,face_rignt);
	facemoof.SetBlendShapeWeight(45,face_left);
	facemoof.SetBlendShapeWeight(46,tongue);
	facemoof.SetBlendShapeWeight(47,mouth_mortifying);
	facemoof.SetBlendShapeWeight(48,eye_up);
	
	//other
	othermoof.SetBlendShapeWeight(0,other_shy);	
	othermoof.SetBlendShapeWeight(1,eye_shock);
	othermoof.SetBlendShapeWeight(2,eye_hacyu);
	othermoof.SetBlendShapeWeight(3,eye_h2);
	othermoof.SetBlendShapeWeight(4,eye_h3);
	othermoof.SetBlendShapeWeight(5,other_shocked);
	othermoof.SetBlendShapeWeight(6,other_tear);

	//other2
	other2moof.SetBlendShapeWeight(0,other_shy2);
	
	
}
