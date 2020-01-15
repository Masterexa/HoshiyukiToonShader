using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using NowhereUnity.Utility;

namespace ProjectNameEditor{


    /* --- WARNING ---

    Create this only in under the 'Editor' directory.

    */

	///<summary>ScreenShotWindow</summary>
	///<remarks>
	///A Editor Window class.
	///</remarks>
	public class ScreenShotWindow : EditorWindow{

        enum ImageFormat {
            JPG,
            PNG,
            DXR
        }

        [MenuItem("Window/ScreenShotWindow")]
        static void Init(){
            var wnd = EditorWindow.GetWindow(typeof(ScreenShotWindow));
            wnd.Show();
        }


		#region Instance
			#region Fields
                [SerializeField]ImageFormat m_format;
                [SerializeField]bool    m_customResolution  = false;
                [SerializeField]int     m_imageWidth        = 1920;
                [SerializeField]int     m_imageHeight       = 1080;
			#endregion

			#region Properties
			#endregion

			#region Events
				///<summary>
				///Use this for initialization.
				///</summary>
				void OnEnable() {
					
				}

                ///<summary>
                ///Use this for draw window.
                ///</summary>
                void OnGUI(){

                    m_format = (ImageFormat)EditorGUILayout.EnumPopup("Format",m_format);

                    m_customResolution = EditorGUILayout.ToggleLeft("Custom Resolution", m_customResolution);
                    using(var hz = new GUILayout.HorizontalScope())
                    {
                        EditorGUI.indentLevel++;

                        m_imageWidth = EditorGUILayout.IntField(m_imageWidth);
                        GUILayout.Label("x", GUILayout.ExpandWidth(false));
                        m_imageHeight = EditorGUILayout.IntField(m_imageHeight);

                        EditorGUI.indentLevel--;
                    }


                    if(GUILayout.Button("Take"))
                    {
                        string path = ChooseSavePath();

                        if( !string.IsNullOrEmpty(path) )
                        {
                            var tex = CreateTexture();
                            
                            ScreenShot.TakeCameraImage(Camera.main, tex);

                            var bytes = EncodeImage(tex);
                            SafeDestroy(tex);
                            System.IO.File.WriteAllBytes(path, bytes);
                        }
                    }
                }
			#endregion

			#region Pipeline
                void SafeDestroy(UnityEngine.Object obj) {

                    if( Application.isPlaying )
                    {
                        UnityEngine.Object.Destroy(obj);
                    }
                    else
                    {
                        UnityEngine.Object.DestroyImmediate(obj);
                    }
                }

                string ChooseSavePath() {
                    var ext = (m_format==ImageFormat.JPG) ? "jpg" : (m_format==ImageFormat.PNG) ? "png" : "exr";

                    return EditorUtility.SaveFilePanel("Save Screenshot", EditorApplication.applicationPath, "", ext);
                }

                Texture2D CreateTexture() {

                    int w = Camera.main.pixelWidth, h=Camera.main.pixelHeight;
                    if( m_customResolution )
                    {
                        w = m_imageWidth;
                        h = m_imageHeight;
                    }
                    return new Texture2D(w, h, (m_format==ImageFormat.DXR) ? TextureFormat.RGBAHalf : TextureFormat.ARGB32, false );
                }

                byte[] EncodeImage(Texture2D tex) {

                    byte[] bytes = null;

                    switch(m_format)
                    {
                        case ImageFormat.JPG:
                            bytes = tex.EncodeToJPG();
                            break;
                        case ImageFormat.PNG:
                            bytes = tex.EncodeToPNG();
                            break;
                        case ImageFormat.DXR:
                            bytes = tex.EncodeToEXR();
                            break;
                        default:
                            break;
                    }
                    return bytes;
                }
			#endregion
		#endregion
	}
}