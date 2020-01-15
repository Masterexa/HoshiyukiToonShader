using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace NowhereUnity.Utility{

	///<summary>EnvironmentChange</summary>
	///<remarks>
	///Use this for control objects in a scene.
	///</remarks>
	public class EnvironmentChange : MonoBehaviour {
        #region Instance
            #region Fields
                public ReflectionProbe reflectionProbe;
                public Material[]       materials = new Material[0];

                Rect    m_rect;
                Vector2 m_scroll;
                int     m_index=-1;
			#endregion

			#region Properties
			#endregion

			#region Events
				///<summary>
				///Use this for initialization.
				///</summary>
				void Start () {
					m_rect = new Rect(Screen.width-410, 10, 250, 400);
				}

                private void OnGUI() {
            
                    m_rect.x = Mathf.Clamp(m_rect.x, 30f-m_rect.width, (float)Screen.width-30f);
                    m_rect.y = Mathf.Clamp(m_rect.y, 30f-m_rect.height, (float)Screen.height-30f);

                    m_rect = GUI.Window(0, m_rect, (id) =>
                    {
                        var     sun         = RenderSettings.sun;
                        bool    sunEnabled  = (sun!=null) ? sun.enabled : false;
                        int     index       = m_index;

                        GUI.enabled = sun!=null;
                        sunEnabled  = GUILayout.Toggle(sunEnabled,"Sun");

                        GUI.enabled = true;
                        m_scroll = GUILayout.BeginScrollView(m_scroll, GUI.skin.textArea);
                        {
                            for(int i=0; i<materials.Length; i++)
                            {
                                var     it          = materials[i];
                                bool    isActived   = i==index;
                                bool    choosen     = GUILayout.Toggle(isActived, it.name);

                                if( !isActived && choosen )
                                {
                                    index = i;
                                }
                            }
                        }
                        GUILayout.EndScrollView();
                        GUI.DragWindow();

                        // Ref
                        if(sun!=null)
                        {
                            sun.enabled = sunEnabled;
                        }
                        if( m_index!=index )
                        {
                            m_index = index;
                            RenderSettings.skybox = materials[m_index];
                            DynamicGI.UpdateEnvironment();
                            if( reflectionProbe )
                            {
                                reflectionProbe.RenderProbe();
                            }
                        }
                    }, "Environment");
                }
            #endregion

            #region Pipeline
            #endregion

            #region Methods
            #endregion
        #endregion
    }
}