using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace NowhereUnity.Utility{

	///<summary>SpectorCamera</summary>
	///<remarks>
	///Use this for control objects in a scene.
	///</remarks>
	public class SpectatorCamera : MonoBehaviour {
		#region Instance
			#region Fields
                [SerializeField]float   m_moveSpeed     = 5f;
                [SerializeField]float   m_rotationSpeed = 360f;
                [Header("Keybind")]
                [SerializeField]string  m_moveAxisX = "Horizontal";
                [SerializeField]string  m_moveAxisY = "";
                [SerializeField]string  m_moveAxisZ = "Vertical";
                [SerializeField]string  m_aimAxisX  = "Mouse Y";
                [SerializeField]string  m_aimAxisY  = "Mouse X";
                [Header("Misc")]
                [SerializeField]bool    m_tipsEnable    = true;
                [SerializeField]Vector2 m_tipsAreaSize  = new Vector2(100,40);
                [TextArea(2,10)]
                [SerializeField]string  m_tipsText = "";
            #endregion

            #region Properties
        #endregion

            #region Events

                ///<summary>
                /// Update is called once per frame
                ///</summary>
                void Update () {
                    bool        isRotation  = Input.GetMouseButton(1);
                    bool        isMove      = Input.GetMouseButton(2);
                    float       dt          = Time.deltaTime;
                    Vector2     aim         = new Vector2(GetAxis(m_aimAxisY), GetAxis(m_aimAxisX));
                    Vector3     move        = new Vector3(GetAxis(m_moveAxisX), GetAxis(m_moveAxisY) ,GetAxis(m_moveAxisZ));

                    if( isMove )
                    {
                        move.x = -aim.x;
                        move.y = -aim.y;
                        move.z = 0f;
                    }
                    aim     *= m_rotationSpeed*dt;
                    move    *= m_moveSpeed*dt;

                    Cursor.lockState    = isRotation ? CursorLockMode.Locked : CursorLockMode.None;
                    Cursor.visible      = !isRotation;
                    if( isRotation )
                    {

                        var rot = transform.localEulerAngles;
                        if( rot.x > 180f )
                        {
                            rot.x = Mathf.Max(rot.x-aim.y,271f);
                        }
                        else
                        {
                            rot.x = Mathf.Min(rot.x-aim.y,89f);
                        }
                        transform.localEulerAngles = rot;

                        transform.Rotate(0f,aim.x,0f, Space.World);
                    }

                    transform.position += transform.right*move.x + transform.up*move.y + transform.forward*move.z;
                }

                private void OnGUI()
                {
                    if( m_tipsEnable )
                    {
                        var rc  = new Rect(10,Screen.height-10,m_tipsAreaSize.x,0);
                        rc.yMin -= m_tipsAreaSize.y;

                        GUI.Label(rc, m_tipsText, GUI.skin.box);
                    }
                }
            #endregion

            #region Pipeline
                static float GetAxis(string axis)
                {
                    return string.IsNullOrEmpty(axis) ? 0f : Input.GetAxis(axis);
                }
            #endregion

            #region Methods
            #endregion
        #endregion
    }
}